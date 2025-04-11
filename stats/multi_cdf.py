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

def extract_rtt_metrics(qlog_data):
    """
    Extract RTT data from qlog_data.
    
    Returns a tuple:
        times_rtt (list of float): Timestamps (microseconds) for RTT updates
        latest_rtts (list of float): Latest RTT in microseconds
        min_rtts (list of float): Min RTT in microseconds
        smoothed_rtts (list of float): Smoothed RTT in microseconds
    """
    times_rtt = []
    latest_rtts = []
    min_rtts = []
    smoothed_rtts = []
    events = qlog_data.get('traces', [{}])[0].get('events', [])
    for event in events:
        # Look for events that update metrics (ensure proper event format)
        if event[1] == 'recovery' and event[2] == 'metric_update':
            try:
                event_time_us = float(event[0])
            except Exception:
                continue
            times_rtt.append(event_time_us)
            latest_rtts.append(event[3].get('latest_rtt', None))
            min_rtts.append(event[3].get('min_rtt', None))
            smoothed_rtts.append(event[3].get('smoothed_rtt', None))
    return times_rtt, latest_rtts, min_rtts, smoothed_rtts

def main():
    parser = argparse.ArgumentParser(
        description=("Merge RTTs from 20 qlog files and plot their "
                     "CDFs (one curve per algorithm). The files must be provided "
                     "in the following order: 4 for QUIC-DC (80%), 4 for Westwood+, "
                     "4 for BBRv2, 4 for Cubic, and 4 for New Reno.")
    )
    parser.add_argument("files", nargs=20,
                        help="Paths to 20 qlog files in the specified order")
    args = parser.parse_args()

    # Define algorithm names and their corresponding custom colors
    algorithm_names = ["QUIC-DC (80%)", "Westwood+", "BBRv2", "Cubic", "New Reno"]
    custom_colors = [ 
        "#e41a1c",  # QUIC-DC (10%) : red
        "#377eb8",  # QUIC-DC (20%) : blue
        "#4daf4a",  # QUIC-DC (50%) : green
        "#984ea3",  # QUIC-DC (80%) : purple
        "#ff7f00"  # westwood+     : orange
    ]
    
    # Verify that exactly 20 files were provided
    files = args.files
    if len(files) != 20:
        print("Error: Exactly 20 file paths must be provided.")
        exit(1)
        
    # Group files by algorithm (each group consists of 4 files)
    groups = {
        "QUIC-DC (80%)": files[0:4],
        "Westwood+": files[4:8],
        "BBRv2": files[8:12],
        "Cubic": files[12:16],
        "New Reno": files[16:20]
    }
    
    # Merge RTTs for each algorithm across the provided files
    merged_rtts = {}
    for algo in algorithm_names:
        merged_rtts[algo] = []
        for file_path in groups[algo]:
            with open(file_path, 'r') as f:
                data = json.load(f)
            # Extract RTT metrics and take the "latest_rtts" list
            _, latest_rtts, _, _ = extract_rtt_metrics(data)
            # Filter out any None values
            valid_rtts = [r for r in latest_rtts if r is not None]
            merged_rtts[algo].extend(valid_rtts)
    
    # Create a plot to display the CDF of latest RTTs for each algorithm
    plt.figure(figsize=(10, 6))
    for idx, algo in enumerate(algorithm_names):
        rtts = merged_rtts[algo]
        if not rtts:
            print(f"Warning: No valid RTT data found for {algo}.")
            continue
        # Convert RTTs from microseconds to milliseconds and filter out those above 300ms
        rtts_ms = [r / 1000.0 for r in rtts if (r / 1000.0) <= 250]
        if not rtts_ms:
            print(f"Warning: No RTT values below 300ms found for {algo}.")
            continue
        # Sort and compute the CDF
        rtts_sorted = np.sort(rtts_ms)
        cdf = np.arange(1, len(rtts_sorted) + 1) / len(rtts_sorted)
        plt.step(rtts_sorted, cdf, label=algo, color=custom_colors[idx], linewidth=2.5)
    
    plt.xlabel("RTT (ms)", fontsize=22)
    plt.ylabel("CDF", fontsize=22)
    plt.grid(True)
    plt.legend(fontsize=18)
    plt.gca().tick_params(axis='both', labelsize=16)
    plt.savefig('/tmp/multi_cdf.pdf', bbox_inches="tight")
    plt.show()

if __name__ == "__main__":
    main()
