#!/usr/bin/env python3
import os
import json
import argparse
import math
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import numpy as np

# Set PDF and PS font type to 42 (TrueType) for better compatibility
matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42


def extract_rtt_metrics(qlog_data):
    """
    Extract RTT data from qlog_data.
    Returns:
        times_rtt (list of float): Timestamps (microseconds) for RTT updates
        latest_rtts (list of float): Latest RTT in microseconds
        min_rtts (list of float): Minimum RTT in microseconds
        smoothed_rtts (list of float): Smoothed RTT in microseconds
    """
    times_rtt, latest_rtts, min_rtts, smoothed_rtts = [], [], [], []
    events = qlog_data['traces'][0]['events']
    for event in events:
        # Look for RTT metric updates from the recovery module
        if event[1] == 'recovery' and event[2] == 'metric_update':
            event_time_us = float(event[0])
            times_rtt.append(event_time_us)
            latest_rtts.append(event[3].get('latest_rtt', None))
            min_rtts.append(event[3].get('min_rtt', None))
            smoothed_rtts.append(event[3].get('smoothed_rtt', None))
    return times_rtt, latest_rtts, min_rtts, smoothed_rtts


def plot_cdf(connections, labels, save_path=None):
    """
    Plot the CDF of latest RTTs for each connection.

    Parameters:
        connections: a list of dictionaries; each must include a key 'rtt_data'.
        labels: a list of labels corresponding to each connection.
        save_path: if provided, the plot is saved to this file.
    """
    plt.figure(figsize=(10, 7))

    # Custom color list.
    custom_colors = [
        "#e41a1c",  # QUIC-DC (10%) : red
        "#377eb8",  # QUIC-DC (20%) : blue
        "#4daf4a",  # QUIC-DC (50%) : green
        "#984ea3",  # QUIC-DC (80%) : purple
        "#ff7f00",  # westwood+     : orange
        "#a65628",  # bbr2          : brown
        "#f781bf",  # cubic         : pink
        "#17becf"   # new reno      : turquoise
    ]

    line_width = 2.5

    # ↘ ADDED/CHANGED: prepare a horizontal line at the 90-th percentile
    plt.axhline(0.9, color="grey", linestyle="--", linewidth=1, zorder=1)

    for i, conn in enumerate(connections):
        rtt_data = conn['rtt_data']
        latest_rtts = [r for r in rtt_data[1] if r is not None]
        if not latest_rtts:
            continue

        latest_rtts_ms = np.array(latest_rtts) / 1000.0
        sorted_rtts = np.sort(latest_rtts_ms)
        cdf = np.arange(1, len(sorted_rtts) + 1) / len(sorted_rtts)

        plt.step(sorted_rtts, cdf,
                 label=labels[i],
                 color=custom_colors[i % len(custom_colors)],
                 linewidth=line_width,
                 zorder=2)

        # ↘ ADDED/CHANGED: compute and highlight the 90-th percentile
        p90 = np.percentile(sorted_rtts, 90)
        plt.scatter(p90, 0.9,
                    color=custom_colors[i % len(custom_colors)],
                    edgecolors='black',
                    s=70,
                    zorder=3)
        plt.text(p90, 0.9 + 0.025,
                 f"{p90:.2f} ms",
                 rotation=45,
                 ha='center',
                 va='bottom',
                 fontsize=11,
                 color=custom_colors[i % len(custom_colors)],
                 zorder=3)

    plt.xlabel("RTT (ms)", fontsize=22)
    plt.ylabel("CDF", fontsize=22)
    plt.grid(True, zorder=0)
    plt.legend(fontsize=16, loc='lower right')

    # ↘ ADDED/CHANGED: y-axis ticks every 0.1
    plt.gca().set_yticks(np.arange(0.0, 1.01, 0.1))
    plt.gca().tick_params(axis='both', labelsize=14)

    if save_path:
        plt.savefig(save_path, bbox_inches="tight")
    else:
        # Fallback path keeps original behaviour
        plt.savefig('/tmp/cdf.pdf', bbox_inches="tight")

    plt.show()


def main():
    parser = argparse.ArgumentParser(description='Plot CDF of RTT from 8 qlog files.')
    parser.add_argument('--qlog-paths', nargs=8, type=str, required=True,
                        help=("Paths to the 8 qlog files in order: "
                              "QUIC-DC(10%), QUIC-DC(20%), QUIC-DC(50%), QUIC-DC(80%), "
                              "westwood+, bbr2, cubic, new reno"))
    parser.add_argument('--output', type=str, required=False,
                        help='Path to save the plot (e.g., output.png)')
    args = parser.parse_args()

    labels = [
        "QUIC-DC (10%)", "QUIC-DC (20%)", "QUIC-DC (50%)", "QUIC-DC (80%)",
        "Westwood+", "BBRv2", "Cubic", "New Reno"
    ]

    connections = []
    for qlog_path in args.qlog_paths:
        with open(qlog_path, 'r') as f:
            qlog_data = json.load(f)
        rtt_data = extract_rtt_metrics(qlog_data)
        connections.append({'qlog_path': qlog_path, 'rtt_data': rtt_data})

    plot_cdf(connections, labels, save_path=args.output)


if __name__ == "__main__":
    main()


# import os
# import json
# import argparse
# import math
# import matplotlib
# matplotlib.use('TkAgg')
# import matplotlib.pyplot as plt

# # Set PDF and PS font type to 42 (TrueType) for better compatibility
# matplotlib.rcParams['pdf.fonttype'] = 42
# matplotlib.rcParams['ps.fonttype'] = 42

# import matplotlib.pyplot as plt
# import numpy as np

# def extract_rtt_metrics(qlog_data):
#     """
#     Extract RTT data from qlog_data.
#     Returns:
#         times_rtt (list of float): Timestamps (microseconds) for RTT updates
#         latest_rtts (list of float): Latest RTT in microseconds
#         min_rtts (list of float): Minimum RTT in microseconds
#         smoothed_rtts (list of float): Smoothed RTT in microseconds
#     """
#     times_rtt = []
#     latest_rtts = []
#     min_rtts = []
#     smoothed_rtts = []
#     events = qlog_data['traces'][0]['events']
#     for event in events:
#         # Look for RTT metric updates from the recovery module
#         if event[1] == 'recovery' and event[2] == 'metric_update':
#             event_time_us = float(event[0])
#             times_rtt.append(event_time_us)
#             latest_rtts.append(event[3].get('latest_rtt', None))
#             min_rtts.append(event[3].get('min_rtt', None))
#             smoothed_rtts.append(event[3].get('smoothed_rtt', None))
#     return (times_rtt, latest_rtts, min_rtts, smoothed_rtts)

# def plot_cdf(connections, labels, save_path=None):
#     """
#     Plot the CDF of latest RTTs for each connection.
    
#     Parameters:
#         connections: a list of dictionaries; each must include a key 'rtt_data'.
#         labels: a list of labels corresponding to each connection.
#         save_path: if provided, the plot is saved to this file.
#     """
#     plt.figure(figsize=(10, 7))
    
#     # Custom color list.
#     custom_colors = [
#         "#e41a1c",  # QUIC-DC (10%) : red
#         "#377eb8",  # QUIC-DC (20%) : blue
#         "#4daf4a",  # QUIC-DC (50%) : green
#         "#984ea3",  # QUIC-DC (80%) : purple
#         "#ff7f00",  # westwood+     : orange
#         "#a65628",  # bbr2          : brown
#         "#f781bf",  # cubic         : pink
#         "#17becf"   # new reno      : turquoise
#     ]
    
#     # Increase line width
#     line_width = 2.5

#     for i, conn in enumerate(connections):
#         rtt_data = conn['rtt_data']
#         # Extract the latest RTTs (in microseconds) and filter out None values.
#         latest_rtts = [r for r in rtt_data[1] if r is not None]
#         if not latest_rtts:
#             continue
#         # Convert RTT values from microseconds to milliseconds.
#         latest_rtts_ms = [r / 1000.0 for r in latest_rtts]
#         sorted_rtts = np.sort(latest_rtts_ms)
#         cdf = np.arange(1, len(sorted_rtts) + 1) / len(sorted_rtts)
#         plt.step(sorted_rtts, cdf,
#                  label=labels[i],
#                  color=custom_colors[i % len(custom_colors)],
#                  linewidth=line_width)
    
#     plt.xlabel("RTT (ms)", fontsize=22)
#     plt.ylabel("CDF", fontsize=22)
#     plt.grid(True)
#     plt.legend(fontsize=18)
#     plt.gca().tick_params(axis='both', labelsize=16)
#     plt.savefig('/tmp/cdf.pdf',  bbox_inches="tight")
#     plt.show()

# def main():
#     parser = argparse.ArgumentParser(description='Plot CDF of RTT from 8 qlog files.')
#     parser.add_argument('--qlog-paths', nargs=8, type=str, required=True,
#                         help=("Paths to the 8 qlog files in order: "
#                               "QUIC-DC(10%), QUIC-DC(20%), QUIC-DC(50%), QUIC-DC(80%), "
#                               "westwood+, bbr2, cubic, new reno"))
#     parser.add_argument('--output', type=str, required=False,
#                         help='Path to save the plot (e.g., output.png)')
#     args = parser.parse_args()
    
#     # Define the labels in the required order.
#     labels = [
#         "QUIC-DC (10%)",
#         "QUIC-DC (20%)",
#         "QUIC-DC (50%)",
#         "QUIC-DC (80%)",
#         "Westwood+",
#         "BBRv2",
#         "Cubic",
#         "New Reno"
#     ]
    
#     connections = []
#     for qlog_path in args.qlog_paths:
#         # Load each qlog file as JSON.
#         with open(qlog_path, 'r') as f:
#             qlog_data = json.load(f)
#         rtt_data = extract_rtt_metrics(qlog_data)
#         connections.append({
#             'qlog_path': qlog_path,
#             'rtt_data': rtt_data,
#         })
    
#     plot_cdf(connections, labels, save_path=args.output)

# if __name__ == "__main__":
#     main()
