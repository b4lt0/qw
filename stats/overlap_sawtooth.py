import os
import json
import argparse
import math
import statistics 
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

import numpy as np

# Set PDF and PS font types for better embedding
matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

###############################################################################
#                              Data Extraction                                #
###############################################################################

def extract_rtt_metrics(qlog_data):
    """
    Extract RTT metrics from a qlog file.
    
    Returns:
        times_rtt: List of event timestamps (in microseconds)
        latest_rtts: List of latest RTT values (in microseconds)
        min_rtts: List of minimum RTT values (in microseconds)
    """
    times_rtt = []
    latest_rtts = []
    min_rtts = []
    
    events = qlog_data.get('traces', [{}])[0].get('events', [])
    for event in events:
        # Look for recovery events with metric_update to find RTT updates.
        if event[1] == 'recovery' and event[2] == 'metric_update':
            try:
                event_time_us = float(event[0])
            except (ValueError, TypeError):
                continue
            times_rtt.append(event_time_us)
            latest_rtts.append(event[3].get('latest_rtt', None))
            min_rtts.append(event[3].get('min_rtt', None))
    
    return times_rtt, latest_rtts, min_rtts

def normalize_times(times_us, base):
    """
    Normalize a list of times (in microseconds) by subtracting the common base
    time and converting the result to seconds.
    """
    return [(t - base) / 1e6 for t in times_us]

###############################################################################
#                                Main Script                                  #
###############################################################################

def main():
    parser = argparse.ArgumentParser(
        description='Process two qlog files and plot RTT metrics.'
    )
    parser.add_argument('qlog_path1', type=str, help='Path to the first qlog file')
    parser.add_argument('qlog_path2', type=str, help='Path to the second qlog file')
    args = parser.parse_args()

    # Check if files exist
    if not os.path.isfile(args.qlog_path1):
        print(f'Error: The file {args.qlog_path1} does not exist.')
        exit(1)
    if not os.path.isfile(args.qlog_path2):
        print(f'Error: The file {args.qlog_path2} does not exist.')
        exit(1)

    # Load the qlog files
    with open(args.qlog_path1, 'r') as f1:
        qlog_data1 = json.load(f1)
    with open(args.qlog_path2, 'r') as f2:
        qlog_data2 = json.load(f2)

    # Extract RTT metrics from both files
    times1, latest1, min1 = extract_rtt_metrics(qlog_data1)
    times2, latest2, _ = extract_rtt_metrics(qlog_data2)  # Only use latest RTT for file 2

    # Ensure that there is at least one timestamp in each file
    if not times1 or not times2:
        print("Insufficient RTT data in one or both files.")
        exit(1)

    # Normalize timestamps using the first RTT timestamp in each file as the base
    base1 = times1[0]
    base2 = times2[0]
    norm_times1 = normalize_times(times1, base1)
    norm_times2 = normalize_times(times2, base2)

    # Convert RTT values from microseconds to milliseconds (ignore None values)
    latest1_ms = [r / 1000.0 if r is not None else None for r in latest1]
    min1_ms = [r / 1000.0 if r is not None else None for r in min1]
    latest2_ms = [r / 1000.0 if r is not None else None for r in latest2]

    # Plot RTT metrics
    plt.figure(figsize=(10, 6))
    
    # Set the line width for all plots
    lw = 2.5
    
    # Plot file 1: Westwood+ using star marker and blue color
    if norm_times1 and latest1_ms:
        plt.plot(norm_times1, latest1_ms, color='blue', marker='*', linestyle='',
                 label="Westwood+", linewidth=2)

    if norm_times2 and latest2_ms:
        plt.plot(norm_times2, latest2_ms, color='red', marker='s', linestyle='',
                 label="QUIC-DC(80%)", linewidth=2)
        # Plot Delay Control threshold as a horizontal dotted orange line
        plt.axhline(y=95, color='purple', linestyle='-.', label="Delay Control threshold", linewidth=lw)

    # Plot RTT min as a horizontal dashed red line
    if norm_times1 and min1_ms:
        plt.axhline(y=50, color='brown', linestyle='--', label="RTT min", linewidth=lw)
    
    # Plot file 2: Delay Control (80%) using square marker and green color

    # Plot RTT Max as a horizontal dash-dot purple line
    plt.axhline(y=105, color='green', linestyle='--', label="RTT Max", linewidth=lw)

    plt.xlabel("Time (s)", fontsize=22)
    plt.ylabel("RTT (ms)", fontsize=22)
    plt.legend(fontsize=18)
    plt.gca().tick_params(axis='both', labelsize=16)
    plt.grid(True)
    plt.tight_layout()
    plt.savefig('/tmp/sawtooth.pdf',  bbox_inches="tight")
    plt.show()

if __name__ == "__main__":
    main()
