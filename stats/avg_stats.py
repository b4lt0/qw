#!/usr/bin/env python3
"""
Usage:
    python analyze_qlogs.py file1.qlog file2.qlog ... file20.qlog

File order must be:
    - Files 1-4: QUIC-DC (80%)
    - Files 5-8: Westwood+
    - Files 9-12: BBRv2
    - Files 13-16: Cubic
    - Files 17-20: New Reno
"""

import os
import json
import argparse
import math
import statistics
import numpy as np

########################################################################
#                       Data Extraction Functions                      #
########################################################################

def extract_cca_name(qlog_data):
    """
    Extract the congestion control algorithm name from the qlog events.
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
    return "Unknown"

def extract_rtt_metrics(qlog_data):
    """
    Extract RTT metrics data from qlog_data.
    Returns:
        times (list of float): RTT event timestamps in microseconds.
        latest (list of float): Latest RTT values in microseconds.
        min_rtts (list of float): Minimum RTT values in microseconds.
        smoothed (list of float): Smoothed RTT values in microseconds.
    """
    times_rtt = []
    latest_rtts = []
    min_rtts = []
    smoothed_rtts = []
    events = qlog_data['traces'][0]['events']
    for event in events:
        if event[1] == 'recovery' and event[2] == 'metric_update':
            t = float(event[0])
            times_rtt.append(t)
            latest_rtts.append(event[3].get('latest_rtt', None))
            min_rtts.append(event[3].get('min_rtt', None))
            smoothed_rtts.append(event[3].get('smoothed_rtt', None))
    return times_rtt, latest_rtts, min_rtts, smoothed_rtts

def extract_congestion_metrics(qlog_data):
    """
    Extract cumulative congestion control metrics from qlog_data.
    Returns a tuple with:
        times_cc: event timestamps (microseconds)
        data_sent: cumulative bytes sent
        data_acked: cumulative bytes acknowledged
        data_lost: cumulative lost bytes
        cwnd_values: congestion window (bytes)
        bif_values: bytes in flight (bytes)
    """
    times_cc = []
    data_sent = []
    data_acked = []
    data_lost = []
    cwnd_values = []
    # We follow a cumulative sum; as events arrive we update these counters.
    cumulative_sent = 0
    cumulative_acked = 0
    cumulative_lost = 0

    events = qlog_data['traces'][0]['events']
    sent_packet_sizes = {}
    for event in events:
        if len(event) < 4:
            continue
        t = float(event[0])
        category = event[1]
        event_type = event[2]
        event_data = event[3]

        if category == 'transport' and event_type == 'packet_sent':
            # Count cumulative data sent.
            packet_size = event_data.get('header', {}).get('packet_size', 0)
            cumulative_sent += packet_size
            packet_num = event_data.get('header', {}).get('packet_number', None)
            if packet_num is not None:
                sent_packet_sizes[packet_num] = packet_size
        elif category == 'transport' and event_type == 'packet_received':
            frames = event_data.get('frames', [])
            for frame in frames:
                if frame.get('frame_type') in ('ack', 'ack_receive_timestamps'):
                    acked_ranges = frame.get('acked_ranges', [])
                    for start, end in acked_ranges:
                        for pn in range(start, end + 1):
                            if pn in sent_packet_sizes:
                                cumulative_acked += sent_packet_sizes[pn]
                                del sent_packet_sizes[pn]
        elif category == 'loss' and event_type == 'packets_lost':
            lost = event_data.get('lost_bytes', 0)
            cumulative_lost += lost

        if event_type in ['metric_update', 'congestion_metric_update']:
            cwnd = event_data.get('current_cwnd', None)
            if cwnd is not None:
                times_cc.append(t)
                data_sent.append(cumulative_sent)
                data_acked.append(cumulative_acked)
                data_lost.append(cumulative_lost)
                cwnd_values.append(cwnd)
    return times_cc, data_sent, data_acked, data_lost, cwnd_values

def extract_bandwidth_metrics(qlog_data):
    """
    Extract bandwidth estimation data from qlog_data.
    Returns:
        times_bw: event timestamps (microseconds)
        bw_estimates: estimated bandwidth (bytes/s)
    """
    times_bw = []
    bw_estimates = []
    events = qlog_data['traces'][0]['events']
    for event in events:
        if len(event) < 4:
            continue
        if event[1] == 'bandwidth_est_update' and event[2] == 'bandwidth_est_update':
            t = float(event[0])
            times_bw.append(t)
            bw_estimates.append(event[3].get('bandwidth_bytes', None))
    return times_bw, bw_estimates

########################################################################
#                 Helper Functions for Time Interval                   #
########################################################################

def get_flow_time_bounds(cc_data, rtt_data):
    """
    Determine the active time interval for a flow.
    Uses the cc_data event times if available; otherwise falls back to RTT times.
    Returns (start_time, end_time) in microseconds.
    """
    if cc_data[0]:
        start = cc_data[0][0]
        end = cc_data[0][-1]
        return start, end
    elif rtt_data[0]:
        return rtt_data[0][0], rtt_data[0][-1]
    else:
        return None, None

def compute_flow_metrics_trimmed(rtt_data, cc_data, bw_data, T_start, T_end):
    """
    Compute per-flow metrics on data restricted to the time interval [T_start, T_end] (in microseconds).
    Returns a dictionary with:
      - avg_rtt_ms, std_rtt_ms: computed from RTT events
      - avg_bw_mbps: from bandwidth estimates
      - throughput_mbps: based on bytes acked over the interval
      - goodput_mbps: based on (acked - lost)
      - loss_rate_percent: percentage loss based on sent bytes
      - avg_cwnd_kbit: average congestion window (converted to Kb)
      - duration_s: duration (in seconds)
    """
    # Duration in seconds.
    duration_s = (T_end - T_start) / 1e6

    # --- RTT metrics ---
    # Use the "smoothed" RTTs if available; otherwise, use latest RTTs.
    rtt_times, latest_rtts, _, smoothed_rtts = rtt_data
    rtt_values = [val for t, val in zip(rtt_times, smoothed_rtts)
                  if val is not None and T_start <= t <= T_end]
    if not rtt_values:
        rtt_values = [val for t, val in zip(rtt_times, latest_rtts)
                      if val is not None and T_start <= t <= T_end]
    if rtt_values:
        avg_rtt_ms = statistics.mean(rtt_values) / 1000.0
        std_rtt_ms = (statistics.stdev(rtt_values) / 1000.0) if len(rtt_values) > 1 else 0.0
    else:
        avg_rtt_ms = math.nan
        std_rtt_ms = math.nan

    # --- Congestion metrics using cc_data ---
    times_cc, data_sent, data_acked, data_lost, cwnd_values = cc_data
    if times_cc:
        # Interpolate cumulative values at T_start and T_end.
        acked_start = np.interp(T_start, times_cc, data_acked)
        acked_end   = np.interp(T_end, times_cc, data_acked)
        sent_start  = np.interp(T_start, times_cc, data_sent)
        sent_end    = np.interp(T_end, times_cc, data_sent)
        lost_start  = np.interp(T_start, times_cc, data_lost)
        lost_end    = np.interp(T_end, times_cc, data_lost)
        # Throughput based on acknowledged bytes.
        throughput_mbps = ((acked_end - acked_start) * 8) / (duration_s * 1024.0 * 1024.0)
        # Goodput: excluding lost bytes.
        goodput_mbps = (((acked_end - acked_start) - (lost_end - lost_start)) * 8) / (duration_s * 1024.0 * 1024.0)
        # Loss rate: ratio of lost bytes to sent bytes (if nonzero).
        sent_diff = sent_end - sent_start
        loss_rate_percent = ((lost_end - lost_start) / sent_diff * 100.0) if sent_diff > 0 else 0.0
        # Average cwnd: first filter events within [T_start, T_end].
        cwnd_in_interval = [cwnd for t, cwnd in zip(times_cc, cwnd_values) if T_start <= t <= T_end]
        if cwnd_in_interval:
            # Convert cwnd (bytes) to Kb (as in your original script dividing by 128).
            cwnd_kb = [c / 128.0 for c in cwnd_in_interval]
            avg_cwnd_kbit = statistics.mean(cwnd_kb)
        else:
            avg_cwnd_kbit = math.nan
    else:
        throughput_mbps = math.nan
        goodput_mbps = math.nan
        loss_rate_percent = math.nan
        avg_cwnd_kbit = math.nan

    # --- Bandwidth estimates ---
    times_bw, bw_estimates = bw_data
    bw_vals = []
    for t, bw in zip(times_bw, bw_estimates):
        if bw is not None and T_start <= t <= T_end:
            # Convert bandwidth estimate from bytes/s to Mb/s.
            bw_mbps = (bw * 8) / (1024.0 * 1024.0)
            bw_vals.append(bw_mbps)
    avg_bw_mbps = statistics.mean(bw_vals) if bw_vals else math.nan

    return {
        'avg_rtt_ms': avg_rtt_ms,
        'std_rtt_ms': std_rtt_ms,
        'avg_bw_mbps': avg_bw_mbps,
        'throughput_mbps': throughput_mbps,
        'goodput_mbps': goodput_mbps,
        'loss_rate_percent': loss_rate_percent,
        'avg_cwnd_kbit': avg_cwnd_kbit,
        'duration_s': duration_s,
    }

########################################################################
#              Aggregation and Jain's Fairness Computation               #
########################################################################

def aggregate_group_metrics(flow_metrics):
    """
    Given a list of per-flow metrics dictionaries for a group,
    computes aggregated (mean and std) values for each metric.
    Also computes Jain's Fairness Index for goodput.
    Returns a dictionary with aggregated metrics.
    """
    keys = ['avg_rtt_ms', 'avg_bw_mbps', 'throughput_mbps', 'goodput_mbps',
            'loss_rate_percent', 'avg_cwnd_kbit']
    agg = {}
    for key in keys:
        values = [flow[key] for flow in flow_metrics if not math.isnan(flow[key])]
        if values:
            agg[key + '_avg'] = statistics.mean(values)
            agg[key + '_std'] = statistics.stdev(values) if len(values) > 1 else 0.0
        else:
            agg[key + '_avg'] = math.nan
            agg[key + '_std'] = math.nan

    # Jain's Fairness Index for goodput across flows.
    goodputs = [flow['goodput_mbps'] for flow in flow_metrics if not math.isnan(flow['goodput_mbps'])]
    if goodputs and sum([g**2 for g in goodputs]) > 0:
        jain_fairness = (sum(goodputs) ** 2) / (len(goodputs) * sum([g**2 for g in goodputs]))
    else:
        jain_fairness = math.nan
    agg['jain_fairness_goodput'] = jain_fairness
    return agg

########################################################################
#                               Main Script                            #
########################################################################

def main():
    parser = argparse.ArgumentParser(
        description="Process 20 qlog files (5 groups of 4 flows) and compute aggregated metrics over common intervals."
    )
    parser.add_argument('qlog_files', nargs=20,
                        help="Paths to 20 qlog files in order: 4 QUIC-DC, 4 Westwood+, 4 BBRv2, 4 Cubic, 4 New Reno")
    args = parser.parse_args()

    # Define group names (order corresponds to file order provided)
    group_labels = ["QUIC-DC", "Westwood+", "BBRv2", "Cubic", "New Reno"]
    groups = {}
    for i, label in enumerate(group_labels):
        groups[label] = args.qlog_files[i*4:(i+1)*4]

    # Process each flow: load qlog, extract data, and determine active interval
    group_flow_data = {}  # { group_label: [ {data for one flow}, ... ] }
    for label in group_labels:
        flow_list = []
        for filepath in groups[label]:
            if not os.path.isfile(filepath):
                print(f"Error: File {filepath} does not exist.")
                continue
            with open(filepath, 'r') as f:
                try:
                    qlog_data = json.load(f)
                except Exception as e:
                    print(f"Error loading {filepath}: {e}")
                    continue
            rtt_data = extract_rtt_metrics(qlog_data)
            cc_data = extract_congestion_metrics(qlog_data)
            bw_data = extract_bandwidth_metrics(qlog_data)
            cca_name = extract_cca_name(qlog_data)
            start, end = get_flow_time_bounds(cc_data, rtt_data)
            if start is None or end is None:
                print(f"Warning: Unable to determine active time for {filepath}. Skipping.")
                continue
            flow_list.append({
                'filepath': filepath,
                'rtt_data': rtt_data,
                'cc_data': cc_data,
                'bw_data': bw_data,
                'cca_name': cca_name,
                'start': start,
                'end': end
            })
        group_flow_data[label] = flow_list

    # For each group, determine the common interval where all flows are alive.
    for label in group_labels:
        flows = group_flow_data[label]
        if len(flows) < 4:
            print(f"Group {label}: Not enough valid flows. Skipping group.")
            continue
        # The common interval is from the maximum of individual start times to the minimum of individual end times.
        common_start = max(flow['start'] for flow in flows)
        common_end   = min(flow['end'] for flow in flows)
        if common_end <= common_start:
            print(f"Group {label}: No overlapping interval among flows. Skipping group.")
            continue

        print("=" * 60)
        print(f"Group: {label}")
        print(f"Common active interval: {common_start/1e6:.3f} s to {common_end/1e6:.3f} s (duration: {(common_end-common_start)/1e6:.3f} s)")
        flow_metrics = []
        for flow in flows:
            metrics = compute_flow_metrics_trimmed(flow['rtt_data'], flow['cc_data'], flow['bw_data'],
                                                     common_start, common_end)
            flow_metrics.append(metrics)
            print(f"\nFlow: {os.path.basename(flow['filepath'])} ({flow['cca_name']})")
            print(f"  Average RTT: {metrics['avg_rtt_ms']:.2f} ms ± {metrics['std_rtt_ms']:.2f} ms")
            print(f"  Throughput: {metrics['throughput_mbps']:.2f} Mb/s")
            print(f"  Goodput:   {metrics['goodput_mbps']:.2f} Mb/s")
            print(f"  Loss Rate: {metrics['loss_rate_percent']:.2f} %")
            print(f"  Avg CWND:  {metrics['avg_cwnd_kbit']:.2f} Kb")
        # Aggregate the metrics over the 4 flows.
        agg = aggregate_group_metrics(flow_metrics)
        print("\nAggregated Group Metrics:")
        print(f"  Average RTT: {agg['avg_rtt_ms_avg']:.2f} ms ± {agg['avg_rtt_ms_std']:.2f} ms")
        print(f"  Average Bandwidth: {agg['avg_bw_mbps_avg']:.2f} Mb/s ± {agg['avg_bw_mbps_std']:.2f} Mb/s")
        print(f"  Throughput: {agg['throughput_mbps_avg']:.2f} Mb/s ± {agg['throughput_mbps_std']:.2f} Mb/s")
        print(f"  Goodput:   {agg['goodput_mbps_avg']:.2f} Mb/s ± {agg['goodput_mbps_std']:.2f} Mb/s")
        print(f"  Loss Rate: {agg['loss_rate_percent_avg']:.2f} % ± {agg['loss_rate_percent_std']:.2f} %")
        print(f"  Avg CWND:  {agg['avg_cwnd_kbit_avg']:.2f} Kb ± {agg['avg_cwnd_kbit_std']:.2f} Kb")
        print(f"  Jain's Fairness Index (Goodput): {agg['jain_fairness_goodput']:.3f}")
        print("=" * 60, "\n")

if __name__ == "__main__":
    main()
