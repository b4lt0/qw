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
        if event[1] == 'recovery' and event[2] == 'metric_update':
            event_time_ms = float(event[0])
            times_rtt.append(event_time_ms / 1000.0)  # convert to ms
            latest_rtts.append(event[3].get('latest_rtt', None))
            min_rtts.append(event[3].get('min_rtt', None))
            smoothed_rtts.append(event[3].get('smoothed_rtt', None))

    return times_rtt, latest_rtts, min_rtts, smoothed_rtts


def extract_congestion_metrics(qlog_data):
    """
    Extract congestion-related data from qlog_data.

    Returns:
        Various congestion control metrics.
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
        event_time = float(event[0]) / 1000.0  # convert to ms
        category = event[1]
        event_type = event[2]
        event_data = event[3] if len(event) > 3 else {}

        if category == 'transport' and event_type == 'transport_state_update':
            if event_data.get('update') == 'loss timeout expired':
                timeouts.append(event_time)
                timeout_counts['loss_timeout_expired'] = timeout_counts.get('loss_timeout_expired', 0) + 1

        ssthresh = event_data.get('ssthresh', None)
        if ssthresh is not None:
            ssthresh_list.append((event_time, ssthresh))

        if event_type == 'packet_sent':
            packet_size = event_data.get('header', {}).get('packet_size', 0)
            cumulative_data_sent += packet_size

        elif event_type == 'packet_received':
            acked_ranges = event_data.get('acked_ranges', [])
            acked_size = sum((end - start + 1) for start, end in acked_ranges)
            cumulative_data_acked += acked_size

        elif event_type == 'packet_lost':
            lost_size = event_data.get('header', {}).get('packet_size', 0)
            cumulative_data_lost += lost_size

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

    return (times_cc, data_sent, data_acked, data_lost, cwnd_values, bif_values, ssthresh_list, timeouts, timeout_counts)


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
        if event[1] == 'bandwidth_est_update' and event[2] == 'bandwidth_est_update':
            event_time_ms = float(event[0])
            times_bw.append(event_time_ms / 1000.0)  # convert to ms
            bw_estimates.append(event[3].get('bandwidth_bytes', None))

    return times_bw, bw_estimates

###############################################################################
#                            Plotting Function                                #
###############################################################################

def normalize_times(times):
    """
    Normalize the list of times to be relative to the first timestamp.
    """
    if not times:
        return times
    start_time = times[0]
    return [(t - start_time) / 1000.0 for t in times]  # Convert to seconds

def plot_all_subplots(rtt_data, cc_data, bw_data, plot_bytes_in_flight=False, save_path=None):
    times_rtt, latest_rtts, min_rtts, smoothed_rtts = rtt_data
    (times_cc, data_sent, data_acked, data_lost, cwnd_values, bif_values, ssthresh_list, timeout_times, timeout_counts) = cc_data
    times_bw, bw_estimates = bw_data

    # Normalize times to start from zero and convert to seconds
    times_rtt = normalize_times(times_rtt)
    times_cc = normalize_times(times_cc)
    times_bw = normalize_times(times_bw)
    timeout_times = normalize_times(timeout_times)

    # Convert units
    latest_rtts = [rtt / 1000.0 for rtt in latest_rtts]  # microseconds to milliseconds
    min_rtts = [rtt / 1000.0 for rtt in min_rtts]
    smoothed_rtts = [rtt / 1000.0 for rtt in smoothed_rtts]
    cwnd_values = [cwnd / 1024.0 for cwnd in cwnd_values]  # bytes to kilobytes
    bw_estimates = [bw / (1024.0 * 1024.0) for bw in bw_estimates]  # bytes to megabytes
    data_sent = [data / (1024.0 * 1024.0) for data in data_sent]  # bytes to megabytes
    data_acked = [data / (1024.0 * 1024.0) for data in data_acked]
    data_lost = [data / (1024.0 * 1024.0) for data in data_lost]

    fig, axs = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle("QUIC Metrics Overview", fontsize=16)

    # Subplot 1: RTT metrics
    ax_rtt = axs[0, 0]
    if times_rtt:
        ax_rtt.plot(times_rtt, latest_rtts, label='Latest RTT', linestyle='-')
        ax_rtt.plot(times_rtt, min_rtts, label='Min RTT', linestyle='--')
        ax_rtt.plot(times_rtt, smoothed_rtts, label='Smoothed RTT', linestyle='-.')
        ax_rtt.set_xlabel("Time (s)")
        ax_rtt.set_ylabel("RTT (ms)")
        ax_rtt.set_title("RTT Metrics Over Time")
        ax_rtt.legend()
        ax_rtt.grid(True)

    # Subplot 2: Data Sent / Data Acked / Data Lost
    ax_data = axs[0, 1]
    if times_cc:
        ax_data.plot(times_cc, data_sent, label="Data Sent (MB)", color='blue')
        ax_data.plot(times_cc, data_acked, label="Data Acked (MB)", color='green')
        ax_data.plot(times_cc, data_lost, label="Data Lost (MB)", color='red')
        if timeout_times:
            for t in timeout_times:
                ax_data.axvline(t, color='orange', linestyle='--')
        ax_data.set_xlabel("Time (s)")
        ax_data.set_ylabel("Data (MB)")
        ax_data.set_title("Data Transfer Metrics Over Time")
        ax_data.legend()
        ax_data.grid(True)

    # Subplot 3: Congestion Control Metrics
    ax_cc = axs[1, 0]
    if times_cc:
        ax_cc.plot(times_cc, cwnd_values, label='Congestion Window (KB)', color='purple')
        if plot_bytes_in_flight:
            bif_values = [bif / 1024.0 for bif in bif_values]  # Convert to KB
            ax_cc.plot(times_cc, bif_values, label='Bytes in Flight (KB)', color='brown')
        if ssthresh_list:
            ssthresh_times, ssthresh_vals = zip(*ssthresh_list)
            ssthresh_times = normalize_times(ssthresh_times)
            ssthresh_vals = [val / 1024.0 for val in ssthresh_vals]  # Convert to KB
            ax_cc.step(ssthresh_times, ssthresh_vals, label='SSThresh (KB)', color='red', linestyle='--')
        ax_cc.set_xlabel("Time (s)")
        ax_cc.set_ylabel("Congestion Window (KB)")
        ax_cc.set_title("Congestion Control Metrics Over Time")
        ax_cc.legend()
        ax_cc.grid(True)

    # Subplot 4: Bandwidth Estimate
    ax_bw = axs[1, 1]
    if times_bw:
        ax_bw.plot(times_bw, bw_estimates, label='Bandwidth Estimate (MB/s)', linestyle='-')
        ax_bw.set_xlabel("Time (s)")
        ax_bw.set_ylabel("Bandwidth (MB/s)")
        ax_bw.set_title("Bandwidth Estimation Over Time")
        ax_bw.legend()
        ax_bw.grid(True)

    plt.tight_layout()

    # Save plot if save_path is specified
    if save_path:
        plt.savefig(save_path)
        print(f"Plot saved to {save_path}")

    plt.show()


###############################################################################
#                                Main Script                                  #
###############################################################################

parser = argparse.ArgumentParser(description='Process a qlog file and plot metrics.')
parser.add_argument('qlog_path', type=str, help='Path to the qlog file')
parser.add_argument('--plot-bytes-in-flight', action='store_true', default=False, help='Enable plotting of bytes in flight')
parser.add_argument('--output', type=str, required=False, help='Path to save the plot (e.g., output.png)')

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

# Plot everything
plot_all_subplots(
    rtt_data,
    cc_data,
    bw_data,
    plot_bytes_in_flight=args.plot_bytes_in_flight,
    save_path=args.output
)
