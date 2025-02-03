import os
import json
import argparse
import math
import statistics  # <-- ADDED FOR STD DEV
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

###############################################################################
#                            Data Extraction Functions                        #
###############################################################################

def extract_rtt_metrics(qlog_data):
    """
    Extract RTT data from qlog_data.

    Returns:
        times_rtt (list of float): Timestamps (microseconds) for RTT updates
        latest_rtts (list of float): Latest RTT in microseconds
        min_rtts (list of float): Min RTT in microseconds
        smoothed_rtts (list of float): Smoothed RTT in microseconds
    """
    times_rtt = []
    latest_rtts = []
    min_rtts = []
    smoothed_rtts = []

    events = qlog_data['traces'][0]['events']
    for event in events:
        if event[1] == 'recovery' and event[2] == 'metric_update':
            event_time_us = float(event[0])  # microseconds
            times_rtt.append(event_time_us)
            latest_rtts.append(event[3].get('latest_rtt', None))
            min_rtts.append(event[3].get('min_rtt', None))
            smoothed_rtts.append(event[3].get('smoothed_rtt', None))

    return times_rtt, latest_rtts, min_rtts, smoothed_rtts


def extract_congestion_metrics(qlog_data):
    """
    Extract congestion-related data from qlog_data.

    Returns a tuple with:
        - times_cc (list of float): Timestamps (microseconds)
        - data_sent (list of int): Cumulative data sent (bytes)
        - data_acked (list of int): Cumulative data acked (bytes)
        - data_lost (list of int): Cumulative data lost (bytes)
        - cwnd_values (list of int): Congestion window (bytes)
        - bif_values (list of int): Bytes in flight (bytes)
        - ssthresh_list (list of (time, ssthresh))
        - timeouts (list of float): Times (microseconds) when loss timeout expired
        - timeout_counts (dict)
        - lost_event_count (int): Number of `packet_lost` events
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

    lost_event_count = 0 

    events = qlog_data['traces'][0]['events']
    for event in events:
        if len(event) < 4:
            continue

        event_time_us = float(event[0])  # microseconds
        category = event[1]
        event_type = event[2]
        event_data = event[3]

        # Capture timeouts
        if category == 'transport' and event_type == 'transport_state_update':
            if event_data.get('update') == 'loss timeout expired':
                timeouts.append(event_time_us)
                timeout_counts['loss_timeout_expired'] = \
                    timeout_counts.get('loss_timeout_expired', 0) + 1

        # ssthresh
        ssthresh = event_data.get('ssthresh', None)
        if ssthresh is not None and ssthresh<1e5:
            ssthresh_list.append((event_time_us, ssthresh))

        # Data Sent
        if category == 'transport' and event_type == 'packet_sent':
            packet_size = event_data.get('header', {}).get('packet_size', 0)
            cumulative_data_sent += packet_size

            frames = event_data.get('frames', [])
            for f in frames:
                if f.get('frame_type') == 'ack':
                    acked_ranges = f.get('acked_ranges', [])
                    acked_size = sum((end - start + 1) for start, end in acked_ranges)
                    cumulative_data_acked += acked_size

        # Data Acked
        elif event_type == 'packet_received':
            frames = event_data.get('frames', [])
            for frame in frames:
                if frame.get('frame_type') == 'ack':
                    acked_ranges = frame.get('acked_ranges', [])
                    acked_size = sum((end - start + 1) for start, end in acked_ranges)
                    cumulative_data_acked += acked_size

        # Data Lost 
        elif category == 'loss' and event_type == 'packets_lost':
            lost_size = event_data.get('lost_bytes', 0)
            lost_packets = event_data.get('lost_packets', 0)
            cumulative_data_lost += lost_size
            lost_event_count += lost_packets

        # Congestion control updates
        if event_type in ['metric_update', 'congestion_metric_update']:
            cwnd = event_data.get('current_cwnd', None)
            bytes_in_flight = event_data.get('bytes_in_flight', None)
            if cwnd is not None and bytes_in_flight is not None:
                times_cc.append(event_time_us)
                data_sent.append(cumulative_data_sent)
                data_acked.append(cumulative_data_acked)
                data_lost.append(cumulative_data_lost)
                cwnd_values.append(cwnd)
                bif_values.append(bytes_in_flight)

    return (times_cc, data_sent, data_acked, data_lost,
            cwnd_values, bif_values, ssthresh_list,
            timeouts, timeout_counts, lost_event_count)


def extract_bandwidth_metrics(qlog_data):
    """
    Extract bandwidth estimation data from qlog_data.

    Returns:
        times_bw (list of float): Timestamps (microseconds)
        bw_estimates (list of float): Bandwidth estimates in bytes/s
    """
    times_bw = []
    bw_estimates = []

    events = qlog_data['traces'][0]['events']
    for event in events:
        if len(event) < 4:
            continue

        if (event[1] == 'bandwidth_est_update' and
            event[2] == 'bandwidth_est_update'):
            event_time_us = float(event[0])
            times_bw.append(event_time_us)
            bw_estimates.append(event[3].get('bandwidth_bytes', None))

    return times_bw, bw_estimates


###############################################################################
#                                Plot Functions                               #
###############################################################################

def normalize_times(times_us):
    """
    Convert times from microseconds to seconds, normalized to the first timestamp.
    """
    if not times_us:
        return []
    start_time = times_us[0]
    return [(t - start_time) / 1_000_000.0 for t in times_us]


def plot_all_subplots(rtt_data, cc_data, bw_data,
                      plot_bytes_in_flight=False,
                      save_path=None):
    """
    Generates the 2x2 plot of (RTT, Data, CC, Bandwidth).
    """
    times_rtt, latest_rtts, min_rtts, smoothed_rtts = rtt_data
    (times_cc, data_sent, data_acked, data_lost,
     cwnd_values, bif_values, ssthresh_list,
     timeouts, timeout_counts, lost_event_count) = cc_data
    times_bw, bw_estimates = bw_data

    # Normalize times to start from zero
    times_rtt_s = normalize_times(times_rtt)
    times_cc_s = normalize_times(times_cc)
    times_bw_s = normalize_times(times_bw)
    timeout_s = normalize_times(timeouts)

    # Convert units for plotting
    # RTT in microseconds -> ms
    latest_rtts_ms = [(rtt / 1000.0) for rtt in latest_rtts if rtt is not None]
    min_rtts_ms = [(rtt / 1000.0) for rtt in min_rtts if rtt is not None]
    smoothed_rtts_ms = [(rtt / 1000.0) for rtt in smoothed_rtts if rtt is not None]

    # cwnd in bytes -> KB
    cwnd_kb = [c / 1024.0 for c in cwnd_values]

    # BIF in bytes -> KB
    bif_kb = [b / 1024.0 for b in bif_values]

    # data in bytes -> MB
    data_sent_mb = [s / (1024.0*1024.0) for s in data_sent]
    data_acked_mb = [a / (1024.0*1024.0) for a in data_acked]
    data_lost_mb = [l / (1024.0*1024.0) for l in data_lost]

    # bandwidth in bytes/s -> MB/s
    bw_estimates_mbs = []
    for bw in bw_estimates:
        if bw is not None:
            bw_estimates_mbs.append(bw / (1024.0*1024.0))

    fig, axs = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle("QUIC Metrics Overview", fontsize=16)

    # Subplot 1: RTT
    ax_rtt = axs[0, 0]
    if times_rtt_s and latest_rtts_ms:
        ax_rtt.plot(times_rtt_s, latest_rtts_ms, label='Latest RTT (ms)')
    if times_rtt_s and min_rtts_ms:
        ax_rtt.plot(times_rtt_s, min_rtts_ms, label='Min RTT (ms)', linestyle='--')
    if times_rtt_s and smoothed_rtts_ms:
        ax_rtt.plot(times_rtt_s, smoothed_rtts_ms, label='Smoothed RTT (ms)', linestyle='-.')
    ax_rtt.set_title("RTT Over Time")
    ax_rtt.set_xlabel("Time (s)")
    ax_rtt.set_ylabel("RTT (ms)")
    ax_rtt.legend()
    ax_rtt.grid(True)

    # Subplot 2: Data
    ax_data = axs[0, 1]
    if times_cc_s and data_sent_mb:
        ax_data.plot(times_cc_s, data_sent_mb, label='Data Sent (MB)', color='blue')
    if times_cc_s and data_acked_mb:
        ax_data.plot(times_cc_s, data_acked_mb, label='Data Acked (MB)', color='green')
    if times_cc_s and data_lost_mb:
        ax_data.plot(times_cc_s, data_lost_mb, label='Data Lost (MB)', color='red')
    # Mark timeouts
    for t_s in timeout_s:
        ax_data.axvline(t_s, color='orange', linestyle='--')
    ax_data.set_title("Data Over Time")
    ax_data.set_xlabel("Time (s)")
    ax_data.set_ylabel("Data (MB)")
    ax_data.legend()
    ax_data.grid(True)

    # Subplot 3: CC metrics
    ax_cc = axs[1, 0]
    if times_cc_s and cwnd_kb:
        ax_cc.plot(times_cc_s, cwnd_kb, label='CWND (KB)', color='purple')
    if plot_bytes_in_flight and times_cc_s and bif_kb:
        ax_cc.plot(times_cc_s, bif_kb, label='Bytes in Flight (KB)', color='brown')
    # ssthresh
    if ssthresh_list:
        ssthresh_times_s = normalize_times([tup[0] for tup in ssthresh_list])
        ssthresh_values_kb = [(tup[1] / 1024.0) for tup in ssthresh_list]
        ax_cc.step(ssthresh_times_s, ssthresh_values_kb, label='SSThresh (KB)', color='red', linestyle='--')
    ax_cc.set_title("Congestion Control Over Time")
    ax_cc.set_xlabel("Time (s)")
    ax_cc.set_ylabel("CWND / BIF (KB)")
    ax_cc.legend()
    ax_cc.grid(True)

    # Subplot 4: Bandwidth
    ax_bw = axs[1, 1]
    if times_bw_s and bw_estimates_mbs:
        ax_bw.plot(times_bw_s, bw_estimates_mbs, label='BW Est (MB/s)', linestyle='-')
    ax_bw.set_title("Bandwidth Estimation Over Time")
    ax_bw.set_xlabel("Time (s)")
    ax_bw.set_ylabel("BW (MB/s)")
    ax_bw.legend()
    ax_bw.grid(True)

    plt.tight_layout()

    if save_path:
        plt.savefig(save_path)
        print(f"Plot saved to {save_path}")

    plt.show()


###############################################################################
#                      Computing & Printing Summary Metrics                   #
###############################################################################

def compute_summary_metrics(rtt_data, cc_data, bw_data):
    """
    Compute summary metrics (average RTT, average BW, throughput, goodput,
    loss rate, average cwnd, number of retransmissions) from the extracted data.
    
    Also compute standard deviations where applicable (RTT, BW, CWND).

    Returns a dict with keys:
       'avg_rtt_ms', 'std_rtt_ms',
       'avg_bw_mbps', 'std_bw_mbps',
       'throughput_mbps', 'goodput_mbps',
       'loss_rate_percent',
       'avg_cwnd_kb', 'std_cwnd_kb',
       'num_retransmissions'
    """
    times_rtt, latest_rtts, min_rtts, smoothed_rtts = rtt_data
    (times_cc, data_sent, data_acked, data_lost,
     cwnd_values, bif_values, ssthresh_list,
     timeouts, timeout_counts, lost_event_count) = cc_data
    times_bw, bw_estimates = bw_data

    ############################################################################
    # 1) RTT (ms)
    ############################################################################
    valid_smoothed = [r for r in smoothed_rtts if r is not None]
    if valid_smoothed:
        # Mean
        avg_rtt_us = statistics.mean(valid_smoothed)
        # Std dev
        std_rtt_us = statistics.stdev(valid_smoothed) if len(valid_smoothed) > 1 else 0.0
    else:
        valid_latest = [r for r in latest_rtts if r is not None]
        if valid_latest:
            avg_rtt_us = statistics.mean(valid_latest)
            std_rtt_us = statistics.stdev(valid_latest) if len(valid_latest) > 1 else 0.0
        else:
            avg_rtt_us = math.nan
            std_rtt_us = math.nan

    avg_rtt_ms = avg_rtt_us / 1000.0
    std_rtt_ms = std_rtt_us / 1000.0

    ############################################################################
    # 2) Bandwidth (MB/s)
    ############################################################################
    valid_bw = [bw for bw in bw_estimates if bw is not None]
    if valid_bw:
        bw_mbps_vals = [bw / (1024.0 * 1024.0) for bw in valid_bw]
        avg_bw_mbps = statistics.mean(bw_mbps_vals)
        std_bw_mbps = statistics.stdev(bw_mbps_vals) if len(bw_mbps_vals) > 1 else 0.0
    else:
        avg_bw_mbps = math.nan
        std_bw_mbps = math.nan

    ############################################################################
    # 3) Time & Data for throughput/goodput
    ############################################################################
    if len(times_cc) > 1:
        total_time_s = (times_cc[-1] - times_cc[0]) / 1_000_000.0
    else:
        total_time_s = 0.0

    final_sent = data_sent[-1] if data_sent else 0
    final_acked = data_acked[-1] if data_acked else 0
    final_lost = data_lost[-1] if data_lost else 0

    ############################################################################
    # 4) Throughput (MB/s) = acked_bytes / total_time_s
    #    (Only a single final measure => no std dev here)
    ############################################################################
    if total_time_s > 0:
        throughput_mbps = (final_acked / (1024.0 * 1024.0)) / total_time_s
    else:
        throughput_mbps = math.nan

    ############################################################################
    # 5) Goodput (MB/s), similarly only one final measure
    ############################################################################
    if total_time_s > 0:
        good_bytes = final_acked - final_lost
        if good_bytes < 0:
            good_bytes = 0
        goodput_mbps = (good_bytes / (1024.0 * 1024.0)) / total_time_s
    else:
        goodput_mbps = 0.0

    ############################################################################
    # 6) Loss Rate (%)
    ############################################################################
    if final_sent > 0:
        loss_rate_percent = (final_lost / float(final_sent)) * 100.0
    else:
        loss_rate_percent = 0.0

    ############################################################################
    # 7) Congestion Window (KB)
    ############################################################################
    if cwnd_values:
        cwnd_kb_values = [c / 1024.0 for c in cwnd_values]
        avg_cwnd_kb = statistics.mean(cwnd_kb_values)
        std_cwnd_kb = statistics.stdev(cwnd_kb_values) if len(cwnd_kb_values) > 1 else 0.0
    else:
        avg_cwnd_kb = math.nan
        std_cwnd_kb = math.nan

    num_retransmissions = lost_event_count

    return {
        'avg_rtt_ms': avg_rtt_ms,
        'std_rtt_ms': std_rtt_ms,                
        'avg_bw_mbps': avg_bw_mbps,
        'std_bw_mbps': std_bw_mbps,              
        'throughput_mbps': throughput_mbps,
        'goodput_mbps': goodput_mbps,
        'loss_rate_percent': loss_rate_percent,
        'avg_cwnd_kb': avg_cwnd_kb,
        'std_cwnd_kb': std_cwnd_kb,             
        'num_retransmissions': num_retransmissions
    }


def format_speed(mbps_value):
    """
    Given a speed in MB/s (float), return a string:
      - "<value> KB/s" if < 1 MB/s
      - "<value> MB/s" if >= 1 MB/s
    with two decimals of precision.
    """
    if math.isnan(mbps_value):
        return "NaN"
    if mbps_value < 1.0:
        kbps = mbps_value * 1024.0
        return f"{kbps:.2f} KB/s"
    else:
        return f"{mbps_value:.2f} MB/s"


def print_summary_metrics(metrics):
    """
    Pretty-print the summary metrics dictionary with bandwidth/throughput/goodput
    displayed in KB/s if < 1 MB/s, otherwise in MB/s. Also prints standard
    deviations where available.
    """
    print("------------------------------------------------------------")
    print("Summary of Key Metrics:")

    # Averages (for BW, throughput, goodput) in MB/s or KB/s
    avg_bw_str       = format_speed(metrics['avg_bw_mbps'])
    throughput_str   = format_speed(metrics['throughput_mbps'])
    goodput_str      = format_speed(metrics['goodput_mbps'])

    # Standard deviations for BW, RTT, CWND
    # We'll just keep them in the same units as the averages:
    #   BW: MB/s (or KB/s), RTT: ms, CWND: KB
    #   If there's a good reason to convert, do so accordingly.
    if not math.isnan(metrics['std_bw_mbps']):
        std_bw_str = format_speed(metrics['std_bw_mbps'])
    else:
        std_bw_str = "NaN"

    if not math.isnan(metrics['std_rtt_ms']):
        std_rtt_str = f"{metrics['std_rtt_ms']:.2f} ms"
    else:
        std_rtt_str = "NaN"

    if not math.isnan(metrics['std_cwnd_kb']):
        std_cwnd_str = f"{metrics['std_cwnd_kb']:.2f} KB"
    else:
        std_cwnd_str = "NaN"

    # Others
    loss_rate_str    = f"{metrics['loss_rate_percent']:.2f} %"
    avg_cwnd_str     = f"{metrics['avg_cwnd_kb']:.2f} KB"
    retransmissions  = f"{metrics['num_retransmissions']} #"
    avg_rtt_str      = f"{metrics['avg_rtt_ms']:.2f} ms"

    # Print them out
    print(f"{'Average BW:':30s}{avg_bw_str:>15s}")
    print(f"{'Std Dev BW:':30s}{std_bw_str:>15s}")              

    print(f"{'Throughput:':30s}{throughput_str:>15s}")
    print(f"{'Goodput:':30s}{goodput_str:>15s}")

    print(f"{'Average CWND:':30s}{avg_cwnd_str:>15s}")
    print(f"{'Std Dev CWND:':30s}{std_cwnd_str:>15s}")          

    print(f"{'Average RTT:':30s}{avg_rtt_str:>15s}")
    print(f"{'Std Dev RTT:':30s}{std_rtt_str:>15s}")            

    print(f"{'Loss Rate:':30s}{loss_rate_str:>15s}")
    print(f"{'Retransmissions:':30s}{retransmissions:>15s}")

    print("------------------------------------------------------------")


###############################################################################
#                                Main Script                                  #
###############################################################################

def main():
    parser = argparse.ArgumentParser(description='Process a qlog file and plot metrics.')
    parser.add_argument('qlog_path', type=str, help='Path to the qlog file')
    parser.add_argument('--plot-bytes-in-flight', action='store_true', default=False,
                        help='Enable plotting of bytes in flight')
    parser.add_argument('--output', type=str, required=False,
                        help='Path to save the plot (e.g., output.png)')
    args = parser.parse_args()
    qlog_path = args.qlog_path

    if not os.path.isfile(qlog_path):
        print(f'Error: The file {qlog_path} does not exist.')
        exit(1)

    with open(qlog_path, 'r') as file:
        qlog_data = json.load(file)

    # Extract data
    rtt_data = extract_rtt_metrics(qlog_data)
    cc_data = extract_congestion_metrics(qlog_data)
    bw_data = extract_bandwidth_metrics(qlog_data)

    # Compute summary stats (including std dev)
    metrics = compute_summary_metrics(rtt_data, cc_data, bw_data)

    # Print summary
    print_summary_metrics(metrics)

    # Plot everything
    plot_all_subplots(
        rtt_data,
        cc_data,
        bw_data,
        plot_bytes_in_flight=args.plot_bytes_in_flight,
        save_path=args.output
    )

if __name__ == "__main__":
    main()
