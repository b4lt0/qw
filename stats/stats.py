import os
import json
import argparse
import math
import statistics 
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

import numpy as np
from mpl_toolkits.axes_grid1.inset_locator import inset_axes, mark_inset


###############################################################################
#                            Data Extraction Functions                        #
###############################################################################

def extract_cca_name(qlog_data):
    """
    Scans the qlog events and returns the CCA name (in uppercase)
    if an event with "CCA set to <name>" is found.
    """
    events = qlog_data.get("traces", [{}])[0].get("events", [])
    for event in events:
        if len(event) >= 4:
            category = event[1]
            event_type = event[2]
            event_data = event[3]
            if category == "transport" and event_type == "transport_state_update":
                update_val = event_data.get("update", "")
                if "CCA set to" in update_val:
                    parts = update_val.split()
                    if len(parts) >= 4:
                        cca = parts[3]
                        return cca.upper()
    return None

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
            event_time_us = float(event[0])
            times_rtt.append(event_time_us)
            latest_rtts.append(event[3].get('latest_rtt', None))
            min_rtts.append(event[3].get('min_rtt', None))
            smoothed_rtts.append(event[3].get('smoothed_rtt', None))

    return times_rtt, latest_rtts, min_rtts, smoothed_rtts


def extract_congestion_metrics(qlog_data):
    """
    Extract congestion-related data from qlog_data.

    Returns a tuple with:
        - times_cc (list of float): Timestamps (microseconds) for congestion control events
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

    # Dictionary to track packet_number -> packet_size
    sent_packet_sizes = {}

    events = qlog_data['traces'][0]['events']
    for event in events:
        if len(event) < 4:
            continue

        event_time_us = float(event[0])
        category = event[1]
        event_type = event[2]
        event_data = event[3]

        # Capture timeouts
        if category == 'transport' and event_type == 'transport_state_update':
            if event_data.get('update') == 'loss timeout expired':
                timeouts.append(event_time_us)
                timeout_counts['loss_timeout_expired'] = timeout_counts.get('loss_timeout_expired', 0) + 1

        # ssthresh
        ssthresh = event_data.get('ssthresh', None)
        if ssthresh is not None and ssthresh < 1e5:
            ssthresh_list.append((event_time_us, ssthresh))

        # Packet sent: store packet size by packet number
        if category == 'transport' and event_type == 'packet_sent':
            packet_size = event_data.get('header', {}).get('packet_size', 0)
            packet_num = event_data.get('header', {}).get('packet_number', None)
            cumulative_data_sent += packet_size
            if packet_num is not None:
                sent_packet_sizes[packet_num] = packet_size

        # Packet received: update cumulative data acked for each acked packet
        elif category == 'transport' and event_type == 'packet_received':
            frames = event_data.get('frames', [])
            for frame in frames:
                if frame.get('frame_type') == 'ack':
                    acked_ranges = frame.get('acked_ranges', [])
                    for (start_pn, end_pn) in acked_ranges:
                        for pn in range(start_pn, end_pn + 1):
                            if pn in sent_packet_sizes:
                                cumulative_data_acked += sent_packet_sizes[pn]
                                del sent_packet_sizes[pn]

        # Data lost events
        elif category == 'loss' and event_type == 'packets_lost':
            lost_size = event_data.get('lost_bytes', 0)
            lost_packets = event_data.get('lost_packets', 0)
            cumulative_data_lost += lost_size
            lost_event_count += lost_packets

        # Congestion control updates
        if event_type in ['metric_update', 'congestion_metric_update']:
            cwnd = event_data.get('current_cwnd', None)
            bif = event_data.get('bytes_in_flight', None)
            if cwnd is not None and bif is not None:
                times_cc.append(event_time_us)
                data_sent.append(cumulative_data_sent)
                data_acked.append(cumulative_data_acked)
                data_lost.append(cumulative_data_lost)
                cwnd_values.append(cwnd)
                bif_values.append(bif)

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

        if event[1] == 'bandwidth_est_update' and event[2] == 'bandwidth_est_update':
            event_time_us = float(event[0])
            times_bw.append(event_time_us)
            bw_estimates.append(event[3].get('bandwidth_bytes', None))

    return times_bw, bw_estimates


###############################################################################
#                      New Real (Sampled) Bandwidth Computation               #
###############################################################################

def compute_sampled_bw(rtt_data, cc_data, common_base):
    """
    For each RTT event, compute the "real bandwidth" sample as:
    
      BW = (data_acked at time t+RTT - data_acked at time t) / RTT

    where t is the RTT event time (in microseconds) and RTT is taken from
    the latest RTT (if available) and converted to seconds.
    
    In this version, the sample is timestamped at the start of the RTT interval.
    Finally, the sample times are normalized using the provided common_base time.
    
    Returns:
        sampled_bw_times_norm (list of float): Normalized sample times (seconds)
        bw_samples (list of float): Real bandwidth samples (in MB/s)
    """
    times_rtt, latest_rtts, min_rtts, smoothed_rtts = rtt_data
    times_cc, data_sent, data_acked, data_lost, _, _, _, _, _, _ = cc_data

    times_cc_arr = np.array(times_cc)
    data_acked_arr = np.array(data_acked)

    bw_samples = []
    sampled_bw_times = []

    for i, t_rtt in enumerate(times_rtt):
        if latest_rtts[i] is not None:
            rtt_val = latest_rtts[i]
        else:
            continue

        RTT_sec = rtt_val / 1e6
        t_start = t_rtt
        t_end = t_rtt + RTT_sec * 1e6

        if t_end > times_cc_arr[-1]:
            continue

        acked_start = np.interp(t_start, times_cc_arr, data_acked_arr)
        acked_end = np.interp(t_end, times_cc_arr, data_acked_arr)
        delta_acked = acked_end - acked_start

        bw_bytes_per_sec = delta_acked / RTT_sec
        bw_mbs = bw_bytes_per_sec / (1024.0 * 1024.0)

        # Timestamp the sample at the start of the RTT interval
        sample_time = t_start
        bw_samples.append(bw_mbs)
        sampled_bw_times.append(sample_time)

    # Normalize using the common base time
    sampled_bw_times_norm = [(t - common_base) / 1e6 for t in sampled_bw_times]
    return sampled_bw_times_norm, bw_samples


###############################################################################
#                                Plot Functions                               #
###############################################################################

def normalize_times(times_us, common_base):
    """
    Convert times from microseconds to seconds, normalized using the provided common_base.
    """
    if not times_us:
        return []
    return [(t - common_base) / 1e6 for t in times_us]


def plot_all_subplots(rtt_data, cc_data, bw_data,
                      sampled_bw_data,
                      cca_name,
                      common_base,
                      plot_bytes_in_flight=False,
                      save_path=None):
    """
    Generates a 2x2 plot of:
      - RTT over time
      - Data (sent, acked, lost) over time
      - Congestion control (CWND, bytes in flight) over time
      - Bandwidth: estimated bandwidth and real bandwidth (sampled bandwidth)
    
    All time axes are normalized using the common_base.
    """
    times_rtt, latest_rtts, min_rtts, smoothed_rtts = rtt_data
    (times_cc, data_sent, data_acked, data_lost,
     cwnd_values, bif_values, ssthresh_list,
     timeouts, timeout_counts, lost_event_count) = cc_data
    times_bw, bw_estimates = bw_data

    # Normalize times using the common base time
    times_rtt_s = normalize_times(times_rtt, common_base)
    times_cc_s = normalize_times(times_cc, common_base)
    times_bw_s = normalize_times(times_bw, common_base)
    timeout_s = normalize_times(timeouts, common_base)

    # Convert units for plotting
    latest_rtts_ms = [r / 1000.0 for r in latest_rtts if r is not None]
    min_rtts_ms = [r / 1000.0 for r in min_rtts if r is not None]
    smoothed_rtts_ms = [r / 1000.0 for r in smoothed_rtts if r is not None]

    cwnd_kb = [c / 1024.0 for c in cwnd_values]
    bif_kb = [b / 1024.0 for b in bif_values]

    data_sent_mb = [s / (1024.0 * 1024.0) for s in data_sent]
    data_acked_mb = [a / (1024.0 * 1024.0) for a in data_acked]
    data_lost_mb = [l / (1024.0 * 1024.0) for l in data_lost]

    bw_estimates_mbs = [bw / (1024.0 * 1024.0) for bw in bw_estimates if bw is not None]

    fig, axs = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle("QUIC " + cca_name + " Overview", fontsize=16)

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
    for t_s in timeout_s:
        ax_data.axvline(t_s, color='orange', linestyle='--')
    ax_data.set_title("Data Over Time")
    ax_data.set_xlabel("Time (s)")
    ax_data.set_ylabel("Data (MB)")
    ax_data.legend()
    ax_data.grid(True)

    # Subplot 3: Congestion Control
    ax_cc = axs[1, 0]
    if times_cc_s and cwnd_kb:
        ax_cc.plot(times_cc_s, cwnd_kb, label='CWND (KB)', color='purple')
    if plot_bytes_in_flight and times_cc_s and bif_kb:
        ax_cc.plot(times_cc_s, bif_kb, label='Bytes in Flight (KB)', color='brown')
    if ssthresh_list:
        ssthresh_times_s = normalize_times([t for t, _ in ssthresh_list], common_base)
        ssthresh_values_kb = [val / 1024.0 for _, val in ssthresh_list]
        ax_cc.step(ssthresh_times_s, ssthresh_values_kb, label='SSThresh (KB)', color='red', linestyle='--')
    ax_cc.set_title("Congestion Control Over Time")
    ax_cc.set_xlabel("Time (s)")
    ax_cc.set_ylabel("CWND (KB)")
    ax_cc.legend()
    ax_cc.grid(True)

    # Subplot 4: Bandwidth
    ax_bw = axs[1, 1]
    if times_bw_s and bw_estimates_mbs:
        ax_bw.plot(times_bw_s, bw_estimates_mbs, label='Estimated BW (MB/s)', marker='.', linestyle='-', color='blue')
    
    if sampled_bw_data is not None:
        sampled_bw_times, bw_samples = sampled_bw_data
        ax_bw.plot(sampled_bw_times, bw_samples, label='Sampled BW (MB/s)', marker='.', linestyle='-', color='orange')

    # Optionally plot the filter coefficient
    if cca_name=="WESTWOOD":
        num_samples = len(bw_estimates_mbs)
        s_values = np.arange(num_samples)
        center = 20.0
        scale  = 0.5
        factor = 6.0 / 8.0
        coef_values = factor * (1.0 / (1.0 + np.exp(-((s_values - center) / scale))))
        ax_bw.plot(times_bw_s, coef_values, label='Low Pass Filter Coef', marker='.', linestyle=':', color='olive')
    
    ax_bw.set_title("Bandwidth Over Time")
    ax_bw.set_xlabel("Time (s)")
    ax_bw.set_ylabel("Bandwidth (MB/s)")
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
    """
    times_rtt, latest_rtts, min_rtts, smoothed_rtts = rtt_data
    (times_cc, data_sent, data_acked, data_lost,
     cwnd_values, bif_values, ssthresh_list,
     timeouts, timeout_counts, lost_event_count) = cc_data
    times_bw, bw_estimates = bw_data

    valid_smoothed = [r for r in smoothed_rtts if r is not None]
    if valid_smoothed:
        avg_rtt_us = statistics.mean(valid_smoothed)
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

    valid_bw = [bw for bw in bw_estimates if bw is not None]
    if valid_bw:
        bw_mbps_vals = [bw / (1024.0 * 1024.0) for bw in valid_bw]
        avg_bw_mbps = statistics.mean(bw_mbps_vals)
        std_bw_mbps = statistics.stdev(bw_mbps_vals) if len(bw_mbps_vals) > 1 else 0.0
    else:
        avg_bw_mbps = math.nan
        std_bw_mbps = math.nan

    if len(times_cc) > 1:
        total_time_s = (times_cc[-1] - times_cc[0]) / 1e6
    else:
        total_time_s = 0.0
    final_sent = data_sent[-1] if data_sent else 0
    final_acked = data_acked[-1] if data_acked else 0
    final_lost = data_lost[-1] if data_lost else 0

    throughput_mbps = (final_acked / (1024.0 * 1024.0)) / total_time_s if total_time_s > 0 else math.nan
    good_bytes = final_acked - final_lost if final_acked >= final_lost else 0
    goodput_mbps = (good_bytes / (1024.0 * 1024.0)) / total_time_s if total_time_s > 0 else 0.0

    loss_rate_percent = (final_lost / float(final_sent)) * 100.0 if final_sent > 0 else 0.0

    if cwnd_values:
        cwnd_kb_values = [c / 1024.0 for c in cwnd_values]
        avg_cwnd_kb = statistics.mean(cwnd_kb_values)
        std_cwnd_kb = statistics.stdev(cwnd_kb_values) if len(cwnd_kb_values) > 1 else 0.0
    else:
        avg_cwnd_kb = math.nan
        std_cwnd_kb = math.nan

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
        'num_retransmissions': lost_event_count,
        'total_time_s': total_time_s
    }


def format_speed(mbps_value):
    """
    Format a speed value in MB/s as a string in KB/s if below 1 MB/s, otherwise in MB/s.
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
    Pretty-print the summary metrics.
    """
    print("------------------------------------------------------------")
    print("Summary Metrics:")

    avg_bw_str       = format_speed(metrics['avg_bw_mbps'])
    throughput_str   = format_speed(metrics['throughput_mbps'])
    goodput_str      = format_speed(metrics['goodput_mbps'])
    std_bw_str       = format_speed(metrics['std_bw_mbps']) if not math.isnan(metrics['std_bw_mbps']) else "NaN"
    std_rtt_str      = f"{metrics['std_rtt_ms']:.2f} ms" if not math.isnan(metrics['std_rtt_ms']) else "NaN"
    std_cwnd_str     = f"{metrics['std_cwnd_kb']:.2f} KB" if not math.isnan(metrics['std_cwnd_kb']) else "NaN"
    loss_rate_str    = f"{metrics['loss_rate_percent']:.2f} %"
    avg_cwnd_str     = f"{metrics['avg_cwnd_kb']:.2f} KB"
    retransmissions  = f"{metrics['num_retransmissions']} #"
    avg_rtt_str      = f"{metrics['avg_rtt_ms']:.2f} ms"
    tx_time_str      = f"{metrics['total_time_s']:.2f} s"

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
    print(f"{'Duration:':30s}{tx_time_str:>15s}")
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

    # Extract data from qlog
    rtt_data = extract_rtt_metrics(qlog_data)
    cc_data = extract_congestion_metrics(qlog_data)
    bw_data = extract_bandwidth_metrics(qlog_data)

    # Determine a common base time for normalization
    base_candidates = []
    if bw_data[0]:
        base_candidates.append(bw_data[0][0])
    if cc_data[0]:
        base_candidates.append(cc_data[0][0])
    common_base = min(base_candidates) if base_candidates else 0

    # Compute sampled bandwidth using the common base
    sampled_bw_data = compute_sampled_bw(rtt_data, cc_data, common_base)

    # Compute and print summary metrics
    metrics = compute_summary_metrics(rtt_data, cc_data, bw_data)
    print_summary_metrics(metrics)

    cca_name = extract_cca_name(qlog_data) or ""

    # Plot all subplots with a common base time for normalization
    plot_all_subplots(
        rtt_data,
        cc_data,
        bw_data,
        sampled_bw_data,
        cca_name,
        common_base,
        plot_bytes_in_flight=args.plot_bytes_in_flight,
        save_path=args.output
    )

if __name__ == "__main__":
    main()
