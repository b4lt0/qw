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
#                     Utility: Get Latest Qlog File in a Directory            #
###############################################################################

def get_latest_qlog_file(directory, extensions=('.json', '.qlog')):
    """
    Returns the path to the most recent file in the given directory that has one of the specified extensions.
    """
    if not os.path.isdir(directory):
        raise ValueError(f"{directory} is not a valid directory.")
    files = [os.path.join(directory, f) for f in os.listdir(directory)
             if os.path.isfile(os.path.join(directory, f)) and f.lower().endswith(extensions)]
    if not files:
        raise ValueError(f"No qlog file with extensions {extensions} found in {directory}")
    latest_file = max(files, key=os.path.getmtime)
    return latest_file

def get_last_n_qlog_files(directory, n=4, extensions=('.qlog')):
    """
    Returns the last n qlog files (sorted by modification time) in the given directory.
    """
    if not os.path.isdir(directory):
        raise ValueError(f"{directory} is not a valid directory.")
    files = [os.path.join(directory, f) for f in os.listdir(directory)
             if os.path.isfile(os.path.join(directory, f)) and f.lower().endswith(extensions)]
    if len(files) < n:
        raise ValueError(f"Less than {n} qlog files found in {directory}")
    files = sorted(files, key=os.path.getmtime)
    return files[-n:]

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
    sent_packet_sizes = {}
    events = qlog_data['traces'][0]['events']
    for event in events:
        if len(event) < 4:
            continue
        event_time_us = float(event[0])
        category = event[1]
        event_type = event[2]
        event_data = event[3]
        if category == 'transport' and event_type == 'transport_state_update':
            if event_data.get('update') == 'loss timeout expired':
                timeouts.append(event_time_us)
                timeout_counts['loss_timeout_expired'] = timeout_counts.get('loss_timeout_expired', 0) + 1
        ssthresh = event_data.get('ssthresh', None)
        if ssthresh is not None and ssthresh < 1e5:
            ssthresh_list.append((event_time_us, ssthresh))
        if category == 'transport' and event_type == 'packet_sent':
            packet_size = event_data.get('header', {}).get('packet_size', 0)
            packet_num = event_data.get('header', {}).get('packet_number', None)
            cumulative_data_sent += packet_size
            if packet_num is not None:
                sent_packet_sizes[packet_num] = packet_size
        elif category == 'transport' and event_type == 'packet_received':
            frames = event_data.get('frames', [])
            for frame in frames:
                if frame.get('frame_type') in ('ack', 'ack_receive_timestamps'):
                    acked_ranges = frame.get('acked_ranges', [])
                    for (start_pn, end_pn) in acked_ranges:
                        for pn in range(start_pn, end_pn + 1):
                            if pn in sent_packet_sizes:
                                cumulative_data_acked += sent_packet_sizes[pn]
                                del sent_packet_sizes[pn]
        elif category == 'loss' and event_type == 'packets_lost':
            lost_size = event_data.get('lost_bytes', 0)
            lost_packets = event_data.get('lost_packets', 0)
            cumulative_data_lost += lost_size
            lost_event_count += lost_packets
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

def compute_sampled_bw(rtt_data, cc_data, start_time):
    """
    For each RTT event, compute the "real bandwidth" sample as:
      BW = (data_acked at time t+RTT - data_acked at time t) / RTT
    where t is the RTT event time (in microseconds) and RTT is converted to seconds.
    The sample timestamp is set to the end of the RTT interval and then converted to seconds.
    The start_time parameter is used only for plotting adjustments.
    Returns:
        sampled_bw_times (list of float): Sample times in seconds (absolute)
        bw_samples (list of float): Real bandwidth samples (in Mb/s)
    """
    times_rtt, latest_rtts, _, _ = rtt_data
    times_cc, data_sent, data_acked, data_lost, _, _, _, _, _, _ = cc_data
    times_cc_arr = np.array(times_cc)
    data_acked_arr = np.array(data_acked)
    bw_samples = []
    sampled_bw_times = []
    for i, t_rtt in enumerate(times_rtt):
        if latest_rtts[i] is None:
            continue
        rtt_val = latest_rtts[i]
        RTT_sec = rtt_val / 1e6
        t_start = t_rtt
        t_end = t_rtt + RTT_sec * 1e6
        if t_end > times_cc_arr[-1]:
            continue
        acked_start = np.interp(t_start, times_cc_arr, data_acked_arr)
        acked_end = np.interp(t_end, times_cc_arr, data_acked_arr)
        delta_acked = acked_end - acked_start
        bw_bytes_per_sec = delta_acked / RTT_sec
        bw_mbs = (bw_bytes_per_sec * 8) / (1024.0 * 1024.0)
        sample_time = t_end / 1e6  # absolute time in seconds
        bw_samples.append(bw_mbs)
        sampled_bw_times.append(sample_time)
    return sampled_bw_times, bw_samples

###############################################################################
#                    Global Time Normalization Helper Function                #
###############################################################################

def convert_times(times_us, global_start):
    """
    Convert times from microseconds to seconds relative to global_start.
    """
    return [(t - global_start) / 1e6 for t in times_us]

###############################################################################
#                                Plot Functions                               #
###############################################################################

def plot_all_subplots_multi(connections, global_start, plot_bytes_in_flight=False, save_path=None):
    """
    Generates a 2x2 plot with:
      - Subplot 1: CDF of latest RTTs for the connections
      - Subplot 2: Data Over Time (Sent, Acked, Lost) in Mb
      - Subplot 3: Congestion Control (CWND, optionally Bytes in Flight) in Kb
      - Subplot 4: Bandwidth (Estimated and Sampled) in Mb/s
    For subplots 2, 3, and 4, time is shown in seconds relative to global_start (which becomes 0).
    """
    fig, axs = plt.subplots(2, 2, figsize=(16, 12))
    fig.suptitle("QUIC Overview (Multi-Connection)", fontsize=16)
    colors = list(plt.cm.Set1.colors)[:len(connections)]
    
    # --- Subplot 1: RTT CDF (time independent) ---
    threshold = [80, 50, 20, 10]
    ax_rtt = axs[0, 0]
    for i, conn in enumerate(connections):
        rtt_data = conn['rtt_data']
        cca_name = conn['cca_name']
        if cca_name == 'WESTWOOD_OWD':
            cca_name = 'Delay Control (' + str(threshold[i]) + '%)'
        latest_rtts = [r for r in rtt_data[1] if r is not None]
        if not latest_rtts:
            continue
        latest_rtts_ms = [r / 1000.0 for r in latest_rtts]
        sorted_rtts = np.sort(latest_rtts_ms)
        cdf = np.arange(1, len(sorted_rtts) + 1) / len(sorted_rtts)
        ax_rtt.step(sorted_rtts, cdf, label=cca_name, color=colors[i])
    ax_rtt.set_title("CDF of Latest RTTs")
    ax_rtt.set_xlabel("RTT (ms)")
    ax_rtt.set_ylabel("CDF")
    ax_rtt.legend()
    ax_rtt.grid(True)
    
    # --- Subplot 2: Data Over Time ---
    ax_data = axs[0, 1]
    for i, conn in enumerate(connections):
        cc_data = conn['cc_data']
        times_cc_s = convert_times(cc_data[0], global_start)
        data_sent_mbit = [s * 8 / (1024.0 * 1024.0) for s in cc_data[1]]
        data_acked_mbit = [a * 8 / (1024.0 * 1024.0) for a in cc_data[2]]
        data_lost_mbit = [l * 8 / (1024.0 * 1024.0) for l in cc_data[3]]
        label_prefix = conn['cca_name']
        ax_data.plot(times_cc_s, data_sent_mbit, label=f"{label_prefix} Sent", color=colors[i], linestyle='-')
        ax_data.plot(times_cc_s, data_acked_mbit, label=f"{label_prefix} Acked", color=colors[i], linestyle='--')
        ax_data.plot(times_cc_s, data_lost_mbit, label=f"{label_prefix} Lost", color=colors[i], linestyle='-.')
        timeout_s = convert_times(cc_data[7], global_start)
        for t in timeout_s:
            ax_data.axvline(t, color=colors[i], linestyle=':', alpha=0.5)
    ax_data.set_title("Data Over Time")
    ax_data.set_xlabel("Time (s)")
    ax_data.set_ylabel("Data (Mb)")
    ax_data.legend(fontsize='small')
    ax_data.grid(True)
    
    # --- Subplot 3: Congestion Control Over Time ---
    ax_cc = axs[1, 0]
    for i, conn in enumerate(connections):
        cc_data = conn['cc_data']
        times_cc_s = convert_times(cc_data[0], global_start)
        cwnd_kbit = [c / 128.0 for c in cc_data[4]]
        ax_cc.plot(times_cc_s, cwnd_kbit, label=f"{conn['cca_name']} CWND", color=colors[i], linestyle='-')
        if plot_bytes_in_flight:
            bif_kbit = [b / 128.0 for b in cc_data[5]]
            ax_cc.plot(times_cc_s, bif_kbit, label=f"{conn['cca_name']} BIF", color=colors[i], linestyle='--')
        ssthresh_list = cc_data[6]
        if ssthresh_list:
            ssthresh_times = [t for t, _ in ssthresh_list]
            ssthresh_values = [val / 128.0 for _, val in ssthresh_list]
            ssthresh_times_s = convert_times(ssthresh_times, global_start)
            ax_cc.step(ssthresh_times_s, ssthresh_values, label=f"{conn['cca_name']} SSThresh", color=colors[i], linestyle=':')
    ax_cc.set_title("Congestion Control Over Time")
    ax_cc.set_xlabel("Time (s)")
    ax_cc.set_ylabel("CWND (Kb)")
    ax_cc.legend(fontsize='small')
    ax_cc.grid(True)
    
    # --- Subplot 4: Bandwidth Over Time ---
    ax_bw = axs[1, 1]
    for i, conn in enumerate(connections):
        bw_data = conn['bw_data']
        times_bw_s = convert_times(bw_data[0], global_start)
        bw_estimates_mbs = [(bw * 8) / (1024.0 * 1024.0) if bw is not None else None for bw in bw_data[1]]
        ax_bw.plot(times_bw_s, bw_estimates_mbs, label=f"{conn['cca_name']} Est BW", color=colors[i], linestyle='-')
        sampled_bw_data = conn['sampled_bw_data']
        if sampled_bw_data is not None:
            sampled_bw_times, bw_samples = sampled_bw_data
            # Adjust sampled bandwidth times relative to global_start (global_start is in microseconds)
            sampled_bw_times_rel = [t - global_start/1e6 for t in sampled_bw_times]
            ax_bw.plot(sampled_bw_times_rel, bw_samples, label=f"{conn['cca_name']} Sampled BW", color=colors[i], linestyle='--')
    ax_bw.set_title("Bandwidth Over Time")
    ax_bw.set_xlabel("Time (s)")
    ax_bw.set_ylabel("Bandwidth (Mb/s)")
    ax_bw.legend(fontsize='small')
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
    Uses conversion factors from bytes to bits (×8) so that speeds are in Mb/s.
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
        bw_mbps_vals = [(bw * 8) / (1024.0 * 1024.0) for bw in valid_bw]
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
    throughput_mbps = ((final_acked * 8) / (1024.0 * 1024.0)) / total_time_s if total_time_s > 0 else math.nan
    good_bytes = final_acked - final_lost if final_acked >= final_lost else 0
    goodput_mbps = ((good_bytes * 8) / (1024.0 * 1024.0)) / total_time_s if total_time_s > 0 else 0.0
    loss_rate_percent = (final_lost / float(final_sent)) * 100.0 if final_sent > 0 else 0.0
    if cwnd_values:
        cwnd_kbit_values = [c / 128.0 for c in cwnd_values]
        avg_cwnd_kbit = statistics.mean(cwnd_kbit_values)
        std_cwnd_kbit = statistics.stdev(cwnd_kbit_values) if len(cwnd_kbit_values) > 1 else 0.0
    else:
        avg_cwnd_kbit = math.nan
        std_cwnd_kbit = math.nan
    return {
        'avg_rtt_ms': avg_rtt_ms,
        'std_rtt_ms': std_rtt_ms,
        'avg_bw_mbps': avg_bw_mbps,
        'std_bw_mbps': std_bw_mbps,
        'throughput_mbps': throughput_mbps,
        'goodput_mbps': goodput_mbps,
        'loss_rate_percent': loss_rate_percent,
        'avg_cwnd_kbit': avg_cwnd_kbit,
        'std_cwnd_kbit': std_cwnd_kbit,
        'num_retransmissions': lost_event_count,
        'total_time_s': total_time_s
    }

def format_speed(mbps_value):
    """
    Format a speed value in Mb/s as a string in Kb/s if below 1 Mb/s, otherwise in Mb/s.
    """
    if math.isnan(mbps_value):
        return "NaN"
    if mbps_value < 1.0:
        kbps = mbps_value * 1024.0
        return f"{kbps:.2f} Kb/s"
    else:
        return f"{mbps_value:.2f} Mb/s"

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
    std_cwnd_str     = f"{metrics['std_cwnd_kbit']:.2f} Kb" if not math.isnan(metrics['std_cwnd_kbit']) else "NaN"
    loss_rate_str    = f"{metrics['loss_rate_percent']:.2f} %"
    avg_cwnd_str     = f"{metrics['avg_cwnd_kbit']:.2f} Kb"
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
#             Final Aggregation of Summary Metrics Across Flows               #
###############################################################################

def compute_final_summary(metrics_list):
    """
    Given a list of per-flow summary metrics dictionaries, compute a final summary
    where each averaged metric is the mean over flows and the std is the standard 
    deviation of the per-flow averages.
    """
    final = {}
    keys = ['avg_rtt_ms', 'avg_bw_mbps', 'throughput_mbps', 'goodput_mbps', 
            'loss_rate_percent', 'avg_cwnd_kbit', 'total_time_s', 'num_retransmissions']
    for key in keys:
        values = [m[key] for m in metrics_list if not math.isnan(m[key])]
        if values:
            final[key + '_avg'] = statistics.mean(values)
            final[key + '_std'] = statistics.stdev(values) if len(values) > 1 else 0.0
        else:
            final[key + '_avg'] = math.nan
            final[key + '_std'] = math.nan
    return final

def print_final_summary(final):
    """
    Print the final aggregated summary metrics.
    """
    print("============================================================")
    print("Final Aggregated Summary Metrics (averaged over flows):")
    print(f"{'Average RTT:':30s}{final['avg_rtt_ms_avg']:.2f} ms ± {final['avg_rtt_ms_std']:.2f} ms")
    print(f"{'Average BW:':30s}{format_speed(final['avg_bw_mbps_avg'])} ± {format_speed(final['avg_bw_mbps_std'])}")
    print(f"{'Throughput:':30s}{format_speed(final['throughput_mbps_avg'])} ± {format_speed(final['throughput_mbps_std'])}")
    print(f"{'Goodput:':30s}{format_speed(final['goodput_mbps_avg'])} ± {format_speed(final['goodput_mbps_std'])}")
    print(f"{'Loss Rate:':30s}{final['loss_rate_percent_avg']:.2f} % ± {final['loss_rate_percent_std']:.2f} %")
    print(f"{'Average CWND:':30s}{final['avg_cwnd_kbit_avg']:.2f} Kb ± {final['avg_cwnd_kbit_std']:.2f} Kb")
    print(f"{'Duration:':30s}{final['total_time_s_avg']:.2f} s ± {final['total_time_s_std']:.2f} s")
    print(f"{'Retransmissions:':30s}{final['num_retransmissions_avg']:.2f} # ± {final['num_retransmissions_std']:.2f} #")
    print("============================================================")

###############################################################################
#                                Main Script                                  #
###############################################################################

def main():
    parser = argparse.ArgumentParser(description='Process qlog files and plot metrics for comparison.')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--parent-dir', type=str,
                       help="Parent directory containing subdirectories (e.g., 'westwood+', 'newreno', 'cubic', 'bbr2').\n"
                            "From each, the most recent qlog file is selected.")
    group.add_argument('--qlog-paths', nargs=4, type=str,
                       help="Paths to the 4 qlog files.")
    parser.add_argument('--cca', type=str, choices=['same', 'diff'], default='diff',
                        help="CCA mode: 'same' to use the last 4 qlog files from the same folder, 'diff' to use one from each subdirectory.")
    parser.add_argument('--plot-bytes-in-flight', action='store_true', default=False,
                        help='Enable plotting of bytes in flight')
    parser.add_argument('--output', type=str, required=False,
                        help='Path to save the plot (e.g., output.png)')
    args = parser.parse_args()
    
    connections = []
    per_flow_metrics = []  # store summary metrics for each flow
    # If --parent-dir is provided, pick the latest file from each subfolder.
    if args.parent_dir:
        if args.cca == 'same':
            try:
                qlog_paths = get_last_n_qlog_files(args.parent_dir, n=4)
            except ValueError as e:
                print(f"Error in directory {args.parent_dir}: {e}")
                exit(1)
            for qlog_path in qlog_paths:
                print(f"Using {qlog_path}")
                with open(qlog_path, 'r') as file:
                    qlog_data = json.load(file)
                rtt_data = extract_rtt_metrics(qlog_data)
                cc_data = extract_congestion_metrics(qlog_data)
                bw_data = extract_bandwidth_metrics(qlog_data)
                start_time = cc_data[0][0] if cc_data[0] else (bw_data[0][0] if bw_data[0] else 0)
                sampled_bw_data = compute_sampled_bw(rtt_data, cc_data, start_time)
                cca_name = extract_cca_name(qlog_data) or "Unknown"
                metrics = compute_summary_metrics(rtt_data, cc_data, bw_data)
                print(f"Summary Metrics for {qlog_path} ({cca_name}):")
                print_summary_metrics(metrics)
                per_flow_metrics.append(metrics)
                connections.append({
                    'qlog_path': qlog_path,
                    'rtt_data': rtt_data,
                    'cc_data': cc_data,
                    'bw_data': bw_data,
                    'sampled_bw_data': sampled_bw_data,
                    'cca_name': cca_name,
                    'start_time': start_time,
                    'metrics': metrics,
                })
        else:
            required_subdirs = ['westwood+', 'newreno', 'cubic', 'bbr2']
            for sub in required_subdirs:
                sub_path = os.path.join(args.parent_dir, sub)
                try:
                    qlog_path = get_latest_qlog_file(sub_path)
                except ValueError as e:
                    print(f"Error in subdirectory {sub_path}: {e}")
                    exit(1)
                print(f"Using {qlog_path} for {sub}")
                with open(qlog_path, 'r') as file:
                    qlog_data = json.load(file)
                rtt_data = extract_rtt_metrics(qlog_data)
                cc_data = extract_congestion_metrics(qlog_data)
                bw_data = extract_bandwidth_metrics(qlog_data)
                start_time = cc_data[0][0] if cc_data[0] else (bw_data[0][0] if bw_data[0] else 0)
                sampled_bw_data = compute_sampled_bw(rtt_data, cc_data, start_time)
                cca_name = extract_cca_name(qlog_data) or sub
                metrics = compute_summary_metrics(rtt_data, cc_data, bw_data)
                print(f"Summary Metrics for {qlog_path} ({cca_name}):")
                print_summary_metrics(metrics)
                per_flow_metrics.append(metrics)
                connections.append({
                    'qlog_path': qlog_path,
                    'rtt_data': rtt_data,
                    'cc_data': cc_data,
                    'bw_data': bw_data,
                    'sampled_bw_data': sampled_bw_data,
                    'cca_name': cca_name,
                    'start_time': start_time,
                    'metrics': metrics,
                })
    
    # Compute the global start time (minimum start_time among all flows)
    global_start = min(conn['start_time'] for conn in connections)

    # Compute and print final aggregated summary metrics across flows
    final_summary = compute_final_summary(per_flow_metrics)
    print_final_summary(final_summary)
    
    # Plot all subplots for the connections using global_start to align time axes
    plot_all_subplots_multi(connections, global_start, plot_bytes_in_flight=args.plot_bytes_in_flight, save_path=args.output)

if __name__ == "__main__":
    main()
