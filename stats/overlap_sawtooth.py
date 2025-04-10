#!/usr/bin/env python3
import os
import json
import argparse
import math
import statistics 
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

import numpy as np

matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

def extract_rtt_metrics(qlog_data):
    """
    Extract RTT metrics from a qlog file.
    Scans through the events and returns:
      - times (list of float): Timestamps (in microseconds)
      - latest_rtts (list of float): Latest RTT values (in microseconds)
      - min_rtts (list of float): Minimum RTT values (in microseconds)
    Only events where event[1]=="recovery" and event[2]=="metric_update" are considered.
    """
    times = []
    latest_rtts = []
    min_rtts = []
    
    try:
        events = qlog_data['traces'][0]['events']
    except (KeyError, IndexError):
        print("qlog format error: unable to find 'traces' or 'events'.")
        return times, latest_rtts, min_rtts

    for event in events:
        if len(event) < 4:
            continue
        if event[1] == 'recovery' and event[2] == 'metric_update':
            t = float(event[0])
            times.append(t)
            latest_rtts.append(event[3].get('latest_rtt'))
            min_rtts.append(event[3].get('min_rtt'))
    return times, latest_rtts, min_rtts

def normalize_times(times_us, common_base):
    """
    Convert times from microseconds to seconds, normalized using the provided common_base.
    This means that the earliest timestamp (common_base) becomes 0.
    """
    if not times_us:
        return []
    return [(t - common_base) / 1e6 for t in times_us]

def main():
    parser = argparse.ArgumentParser(
        description="Plot RTT (ms) vs Time (s) from two qlog files (Westwood+ and Westwood_owd), "
                    "with normalized timestamps (both starting at 0) and horizontal lines for min RTT, "
                    "max RTT, and delay control threshold."
    )
    parser.add_argument("westwood_plus_qlog", help="Path to the Westwood+ qlog file")
    parser.add_argument("westwood_owd_qlog", help="Path to the Westwood_owd qlog file")
    args = parser.parse_args()

    # Ensure both files exist.
    for filepath in [args.westwood_plus_qlog, args.westwood_owd_qlog]:
        if not os.path.isfile(filepath):
            print(f"Error: File {filepath} does not exist.")
            exit(1)

    # Load the two qlog files.
    with open(args.westwood_plus_qlog, 'r') as f:
        qlog_data_plus = json.load(f)
    with open(args.westwood_owd_qlog, 'r') as f:
        qlog_data_owd = json.load(f)

    # Extract RTT metrics from each file.
    times_plus, latest_rtts_plus, min_rtts_plus = extract_rtt_metrics(qlog_data_plus)
    times_owd, latest_rtts_owd, min_rtts_owd = extract_rtt_metrics(qlog_data_owd)

    # Determine a common base time (the earliest timestamp among the two files).
    base_candidates = []
    if times_plus:
        base_candidates.append(min(times_plus))
    if times_owd:
        base_candidates.append(min(times_owd))
    if not base_candidates:
        print("No valid RTT timestamps found in the provided qlog files.")
        exit(1)
    common_base = min(base_candidates)

    # Normalize the timestamps using the normalize_times() function.
    times_plus_sec = normalize_times(times_plus, common_base)
    times_owd_sec  = normalize_times(times_owd, common_base)

    # Convert RTT values from microseconds to milliseconds.
    # (We filter out any None values.)
    latest_rtts_plus_ms = [r / 1000.0 for r in latest_rtts_plus if r is not None]
    latest_rtts_owd_ms  = [r / 1000.0 for r in latest_rtts_owd  if r is not None]
    min_rtts_plus_ms    = [r / 1000.0 for r in min_rtts_plus   if r is not None]
    min_rtts_owd_ms     = [r / 1000.0 for r in min_rtts_owd    if r is not None]

    # Compute overall minimum and maximum RTT using the latest RTT values from both files.
    combined_latest = [r for r in latest_rtts_plus if r is not None] + \
                      [r for r in latest_rtts_owd  if r is not None]
    if not combined_latest:
        print("No valid latest RTT values found.")
        exit(1)
    global_min_rtt_ms = min(combined_latest) / 1000.0
    global_max_rtt_ms = max(combined_latest) / 1000.0

    # Compute the delay control threshold:
    # threshold = min RTT + 0.8 * (max RTT - min RTT)
    delay_threshold_ms = global_min_rtt_ms + 0.8 * (global_max_rtt_ms - global_min_rtt_ms)

    # Plotting the results.
    plt.figure(figsize=(10, 6))
    
    # Plot Westwood+ RTT metrics.
    if times_plus_sec and latest_rtts_plus:
        plt.plot(times_plus_sec, [r / 1000.0 for r in latest_rtts_plus],
                 label="Westwood+ RTT", marker="o")
    if times_plus_sec and min_rtts_plus:
        plt.plot(times_plus_sec, [r / 1000.0 for r in min_rtts_plus],
                 label="Westwood+ Min RTT", linestyle="--")
    
    # Plot Westwood_owd RTT metrics.
    if times_owd_sec and latest_rtts_owd:
        plt.plot(times_owd_sec, [r / 1000.0 for r in latest_rtts_owd],
                 label="Westwood_owd RTT", marker="x")
    if times_owd_sec and min_rtts_owd:
        plt.plot(times_owd_sec, [r / 1000.0 for r in min_rtts_owd],
                 label="Westwood_owd Min RTT", linestyle="--")
    
    # Add horizontal lines for overall min RTT, max RTT, and delay control threshold.
    plt.axhline(global_min_rtt_ms, color="green", linestyle=":",
                label=f"Min RTT ({global_min_rtt_ms:.2f} ms)")
    plt.axhline(global_max_rtt_ms, color="red", linestyle=":",
                label=f"Max RTT ({global_max_rtt_ms:.2f} ms)")
    plt.axhline(delay_threshold_ms, color="purple", linestyle="-.",
                label=f"Delay Threshold ({delay_threshold_ms:.2f} ms)")

    plt.xlabel("Time (s)")
    plt.ylabel("RTT (ms)")
    plt.title("RTT Comparison: Westwood+ vs Westwood_owd (Normalized Time)")
    plt.grid(True)
    plt.legend()
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()
