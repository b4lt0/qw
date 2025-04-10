import os
import json
import argparse
import math
import statistics 
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import numpy as np

# Use these settings so that the text in the pdf is editable
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
        description='Process two qlog files and plot RTT metrics with inline labels.'
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
    times2, latest2, _ = extract_rtt_metrics(qlog_data2)  # only use latest RTT for file 2

    # Ensure that there is at least one timestamp in each file
    if not times1 or not times2:
        print("Insufficient RTT data in one or both files.")
        exit(1)

    # Normalize timestamps using the first RTT timestamp in each file as the base
    base1 = times1[0]
    base2 = times2[0]
    norm_times1 = normalize_times(times1, base1)
    norm_times2 = normalize_times(times2, base2)

    # Convert RTT values from microseconds to milliseconds (ignoring None values)
    latest1_ms = [r / 1000.0 if r is not None else None for r in latest1]
    min1_ms = [r / 1000.0 if r is not None else None for r in min1]
    latest2_ms = [r / 1000.0 if r is not None else None for r in latest2]

    # Create the plot
    plt.figure(figsize=(10, 6))
    
    # Plot file 1: both latest RTT and RTT min.
    if norm_times1 and latest1_ms:
        plt.plot(norm_times1, latest1_ms, color='green', marker='.', linestyle='',
                 label="RTT")  # This could represent the Westwood+ line.
        # Add inline label "Westwood+" on the latest RTT (green) line.
        mid_idx = len(norm_times1) // 2
        plt.text(norm_times1[mid_idx], latest1_ms[mid_idx],
                 "Westwood+", fontsize=10, color='green',
                 bbox=dict(facecolor='w', edgecolor='none', pad=1.5))
    
    if norm_times1 and min1_ms:
        plt.plot(norm_times1, min1_ms, color='red', linestyle='--', label="RTT min")
        # Add inline label "RTT min" on the RTT min (red dashed) line.
        mid_idx = len(norm_times1) // 2
        plt.text(norm_times1[mid_idx], min1_ms[mid_idx],
                 "RTT min", fontsize=10, color='red',
                 bbox=dict(facecolor='w', edgecolor='none', pad=1.5))
    
    # Plot file 2: only latest RTT as Delay Control.
    if norm_times2 and latest2_ms:
        plt.plot(norm_times2, latest2_ms, color='blue', marker='.', linestyle='',
                 label="Delay Control")
        # Add inline label "Delay Control" on the Delay Control (blue) line.
        mid_idx = len(norm_times2) // 2
        plt.text(norm_times2[mid_idx], latest2_ms[mid_idx],
                 "Delay Control", fontsize=10, color='blue',
                 bbox=dict(facecolor='w', edgecolor='none', pad=1.5))
        # Also add a horizontal line indicating a Delay Control threshold.
        plt.axhline(y=92, color='blue', linestyle='--')
        # Place the label directly on the horizontal line.
        # Here we use the last x-value of file 2 for positioning.
        plt.text(norm_times2[-1], 92, "Delay Control threshold",
                 fontsize=10, color='blue', va='bottom', ha='right',
                 bbox=dict(facecolor='w', edgecolor='none', pad=1.5))
    
    # Add horizontal line at 114ms representing RTT Max
    plt.axhline(y=114, color='red', linestyle='--')
    # Position the RTT Max label: using the last x-value from file 1.
    plt.text(norm_times1[-1], 114, "RTT Max", fontsize=10, color='red',
             va='bottom', ha='right', bbox=dict(facecolor='w', edgecolor='none', pad=1.5))

    plt.xlabel("Time (s)")
    plt.ylabel("RTT (ms)")
    plt.title("RTT Over Time")
    plt.grid(True)
    plt.tight_layout()

    # Save the figure as a PDF.
    # plt.savefig("output.pdf")
    plt.show()

if __name__ == "__main__":
    main()
