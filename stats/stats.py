import os
import json
import argparse
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

###############################################################################
#                            Data Extraction Functions                         #
###############################################################################

def extract_rtt_metrics(qlog_data):
    """
    Extract RTT data from qlog_data.

    Returns:
        times_rtt (list of float): Time in milliseconds for RTT updates
        latest_rtts (list of float)
        min_rtts (list of float)
        smoothed_rtts (list of float)
    """
    times_rtt = []
    latest_rtts = []
    min_rtts = []
    smoothed_rtts = []

    events = qlog_data['traces'][0]['events']
    for event in events:
        # event = [time, category, event_type, data...]
        if event[1] == 'recovery' and event[2] == 'metric_update':
            event_time_ms = float(event[0])
            times_rtt.append(event_time_ms / 1000.0)  # convert to ms
            latest_rtts.append(event[3].get('latest_rtt', None))
            min_rtts.append(event[3].get('min_rtt', None))
            smoothed_rtts.append(event[3].get('smoothed_rtt', None))

    return times_rtt, latest_rtts, min_rtts, smoothed_rtts


def extract_congestion_metrics(qlog_data):
    """
    Extract congestion-related data (data sent, data acknowledged, data lost,
    cwnd, bytes_in_flight, ssthresh, timeouts) from qlog_data.

    Returns:
        times_cc (list of float): Times for congestion metrics
        data_sent (list of int)
        data_acked (list of int)
        data_lost (list of int)
        cwnd_values (list of int)
        bif_values (list of int)
        ssthresh_list (list of tuples) -> (time, value)
        timeouts (list of float): Times at which timeouts occurred
        timeout_counts (dict): Mapping of timeout type -> count
    """
    times_cc = []
    data_sent = []
    data_acked = []
    data_lost = []
    cwnd_values = []
    bif_values = []
    ssthresh_list = []
    timeouts = []
    timeout_counts = {}

    cumulative_data_sent = 0
    cumulative_data_acked = 0
    cumulative_data_lost = 0

    events = qlog_data['traces'][0]['events']
    for event in events:
        # event structure = [time, category, event_type, event_data]
        event_time = float(event[0]) / 1000.0  # convert to ms
        category = event[1]
        event_type = event[2]
        event_data = event[3] if len(event) > 3 else {}

        # Check for timeouts
        if category == 'recovery' and 'timeout' in event_type:
            timeouts.append(event_time)
            timeout_counts[event_type] = timeout_counts.get(event_type, 0) + 1

        # ssthresh updates
        ssthresh = event_data.get('ssthresh', None)
        if ssthresh is not None:
            ssthresh_list.append((event_time, ssthresh))

        # Packet events
        if event_type == 'packet_sent':
            packet_size = event_data.get('header', {}).get('packet_size', 0)
            cumulative_data_sent += packet_size

        elif event_type == 'packet_received':
            # acked_ranges is typically a list of (start, end) pairs
            acked_ranges = event_data.get('acked_ranges', [])
            acked_size = sum((end - start + 1) for start, end in acked_ranges)
            cumulative_data_acked += acked_size

        elif event_type == 'packet_lost':
            lost_size = event_data.get('header', {}).get('packet_size', 0)
            cumulative_data_lost += lost_size

        # Congestion metric updates
        if event_type in ['metric_update', 'congestion_metric_update']:
            cwnd = event_data.get('current_cwnd', None)
            bytes_in_flight = event_data.get('bytes_in_flight', None)
            if cwnd is not None and bytes_in_flight is not None:
                times_cc.append(event_time)
                data_sent.append(cumulative_data_sent)
                data_acked.append(cumulative_data_acked)
                data_lost.append(cumulative_data_lost)
                cwnd_values.append(cwnd)
                bif_values.append(bytes_in_flight)

    return (times_cc,
            data_sent,
            data_acked,
            data_lost,
            cwnd_values,
            bif_values,
            ssthresh_list,
            timeouts,
            timeout_counts)


def extract_bandwidth_metrics(qlog_data):
    """
    Extract bandwidth estimation data from qlog_data.

    Returns:
        times_bw (list of float): Time in milliseconds
        bw_estimates (list of float): Bandwidth estimates in bytes/s
    """
    times_bw = []
    bw_estimates = []

    events = qlog_data['traces'][0]['events']
    for event in events:
        if event[1] == 'recovery' and event[2] == 'bandwidth_est_update':
            event_time_ms = float(event[0])
            times_bw.append(event_time_ms / 1000.0)  # convert to ms
            bw_estimates.append(event[3].get('bandwidth_estimate', None))

    return times_bw, bw_estimates


###############################################################################
#                            Plotting Function                                #
###############################################################################

def plot_all_subplots(
    rtt_data,
    cc_data,
    bw_data,
    plot_bytes_in_flight=False
):
    """
    Plot all data in one figure with 4 subplots:

    Subplot 1: RTT metrics
    Subplot 2: Data sent / Data acked / Data lost
    Subplot 3: cwnd / bytes_in_flight / ssthresh / timeouts
    Subplot 4: Bandwidth estimate

    Note: We are no longer checking flags for timeouts or bandwidth; 
    these are plotted unconditionally if data exists.
    """

    # Unpack the RTT data
    times_rtt, latest_rtts, min_rtts, smoothed_rtts = rtt_data

    # Unpack the congestion-control data
    (times_cc,
     data_sent,
     data_acked,
     data_lost,
     cwnd_values,
     bif_values,
     ssthresh_list,
     timeout_times,
     timeout_counts) = cc_data

    # Unpack the bandwidth data
    times_bw, bw_estimates = bw_data

    # Create figure and subplots
    fig, axs = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle("QUIC Metrics Overview", fontsize=16)

    ############################################################################
    # Subplot 1: RTT metrics
    ############################################################################
    ax_rtt = axs[0, 0]
    if times_rtt:
        ax_rtt.plot(times_rtt, latest_rtts, label='Latest RTT', linestyle='-', marker='o')
        ax_rtt.plot(times_rtt, min_rtts, label='Min RTT', linestyle='--', marker='x')
        ax_rtt.plot(times_rtt, smoothed_rtts, label='Smoothed RTT', linestyle='-.', marker='s')
        ax_rtt.set_xlabel("Time (ms)")
        ax_rtt.set_ylabel("RTT (ms)")
        ax_rtt.set_title("RTT Metrics Over Time")
        ax_rtt.legend()
        ax_rtt.grid(True)
    else:
        ax_rtt.text(0.5, 0.5, "No RTT data found", ha='center', va='center', fontsize=12)
        ax_rtt.set_title("RTT Metrics Over Time")
        ax_rtt.set_xlabel("Time (ms)")
        ax_rtt.set_ylabel("RTT (ms)")
        ax_rtt.grid(True)

    ############################################################################
    # Subplot 2: Data Sent / Data Acknowledged / Data Lost
    ############################################################################
    ax_data = axs[0, 1]
    if times_cc:
        ax_data.plot(times_cc, data_sent, label="Data Sent (bytes)", color='blue')
        ax_data.plot(times_cc, data_acked, label="Data Acked (bytes)", color='green')
        ax_data.plot(times_cc, data_lost, label="Data Lost (bytes)", color='red')

        # Mark timeouts as vertical lines if present
        if timeout_times:
            for t in timeout_times:
                ax_data.axvline(t, color='orange', linestyle='--')
            # Show at least one label for the timeouts
            ax_data.axvline(timeout_times[0], color='orange', linestyle='--', 
                            label='Timeout Event')

        ax_data.set_xlabel("Time (ms)")
        ax_data.set_ylabel("Data (bytes)")
        ax_data.set_title("Data Transfer Metrics Over Time")
        ax_data.legend()
        ax_data.grid(True)
    else:
        ax_data.text(0.5, 0.5, "No Data Transfer events found", ha='center', va='center', fontsize=12)
        ax_data.set_title("Data Transfer Metrics Over Time")
        ax_data.set_xlabel("Time (ms)")
        ax_data.set_ylabel("Data (bytes)")
        ax_data.grid(True)

    ############################################################################
    # Subplot 3: Congestion Control Metrics
    ############################################################################
    ax_cc = axs[1, 0]
    if times_cc:
        # Plot cwnd
        ax_cc.plot(times_cc, cwnd_values, label='Congestion Window (cwnd)',
                   color='purple', marker='o')

        # Plot bytes in flight if requested
        if plot_bytes_in_flight:
            ax_cc.plot(times_cc, bif_values, label='Bytes in Flight',
                       color='brown', marker='x')

        # Mark timeouts if present
        if timeout_times:
            for t in timeout_times:
                ax_cc.axvline(t, color='orange', linestyle='--')
            ax_cc.axvline(timeout_times[0], color='orange', linestyle='--', 
                          label='Timeout Event')

        # Plot ssthresh if available
        if ssthresh_list:
            ssthresh_times, ssthresh_vals = zip(*ssthresh_list)
            ax_cc.step(ssthresh_times, ssthresh_vals, label='SSThresh', 
                       color='red', linestyle='--')

        ax_cc.set_xlabel("Time (ms)")
        ax_cc.set_ylabel("Bytes")
        ax_cc.set_title("Congestion Control Metrics Over Time")
        ax_cc.legend()
        ax_cc.grid(True)
    else:
        ax_cc.text(0.5, 0.5, "No Congestion Control data found", 
                   ha='center', va='center', fontsize=12)
        ax_cc.set_title("Congestion Control Metrics Over Time")
        ax_cc.set_xlabel("Time (ms)")
        ax_cc.set_ylabel("Bytes")
        ax_cc.grid(True)

    ############################################################################
    # Subplot 4: Bandwidth Estimate
    ############################################################################
    ax_bw = axs[1, 1]
    if times_bw:
        ax_bw.plot(times_bw, bw_estimates, label='Bandwidth Estimate', 
                   linestyle='-', marker='o')
        ax_bw.set_xlabel("Time (ms)")
        ax_bw.set_ylabel("Bandwidth (bytes/s)")
        ax_bw.set_title("Bandwidth Estimation Over Time")
        ax_bw.legend()
        ax_bw.grid(True)
    else:
        ax_bw.text(0.5, 0.5, "No Bandwidth Estimation data found", 
                   ha='center', va='center', fontsize=12)
        ax_bw.set_title("Bandwidth Estimation Over Time")
        ax_bw.set_xlabel("Time (ms)")
        ax_bw.set_ylabel("Bandwidth (bytes/s)")
        ax_bw.grid(True)

    plt.tight_layout()
    plt.show()

    # Print a timeout summary if we found any
    if timeout_counts:
        total_timeouts = sum(timeout_counts.values())
        print("\nTimeout Summary:")
        for timeout_type, count in timeout_counts.items():
            print(f" - {timeout_type}: {count}")
        print(f"Total Timeouts: {total_timeouts}")


###############################################################################
#                                Main Script                                  #
###############################################################################

parser = argparse.ArgumentParser(description='Process a qlog file.')
parser.add_argument('qlog_path', type=str, help='Path to the qlog file')
parser.add_argument('--plot-bytes-in-flight', action='store_true', default=False, 
                    help='Enable plotting of bytes in flight (default: disabled)')

args = parser.parse_args()

qlog_path = args.qlog_path

if not os.path.isfile(qlog_path):
    print(f'Error: The file {qlog_path} does not exist.')
    exit(1)

with open(qlog_path, 'r') as file:
    qlog_data = json.load(file)

# Extract all data
rtt_data = extract_rtt_metrics(qlog_data)
cc_data = extract_congestion_metrics(qlog_data)
bw_data = extract_bandwidth_metrics(qlog_data)

# Plot everything in a single figure with 4 subplots
plot_all_subplots(
    rtt_data,
    cc_data,
    bw_data,
    plot_bytes_in_flight=args.plot_bytes_in_flight
)
