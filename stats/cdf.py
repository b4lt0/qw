#!/usr/bin/env python3
import os, json, argparse, matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import numpy as np

# Embed TrueType fonts in PDF/PS
matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype']  = 42


def extract_rtt_metrics(qlog_data):
    times_rtt, latest_rtts, min_rtts, smoothed_rtts = [], [], [], []
    for event in qlog_data['traces'][0]['events']:
        if event[1] == 'recovery' and event[2] == 'metric_update':
            times_rtt.append(float(event[0]))
            latest_rtts.append(event[3].get('latest_rtt'))
            min_rtts.append(event[3].get('min_rtt'))
            smoothed_rtts.append(event[3].get('smoothed_rtt'))
    return times_rtt, latest_rtts, min_rtts, smoothed_rtts


def plot_cdf(connections, labels, save_path=None):
    plt.figure(figsize=(10, 7))

    custom_colors = [
        "#e41a1c", "#377eb8", "#4daf4a", "#984ea3",
        "#ff7f00", "#a65628", "#f781bf", "#17becf"
    ]
    line_width = 2.5

    # ↘ ADDED/CHANGED: draw one horizontal reference line at CDF = 0.9
    plt.axhline(0.9, color='gray', linestyle='--', linewidth=1.2, zorder=1)

    for i, conn in enumerate(connections):
        latest_rtts = [r for r in conn['rtt_data'][1] if r is not None]
        if not latest_rtts:
            continue
        latest_rtts_ms = np.sort(np.array(latest_rtts) / 1000.0)
        cdf = np.arange(1, len(latest_rtts_ms) + 1) / len(latest_rtts_ms)

        plt.step(latest_rtts_ms, cdf,
                 label=labels[i],
                 color=custom_colors[i % len(custom_colors)],
                 linewidth=line_width, zorder=2)

    plt.xlabel("RTT (ms)", fontsize=22)
    plt.ylabel("CDF", fontsize=22)
    plt.grid(True, zorder=0)
    plt.legend(fontsize=16, loc='lower right')

    # ↘ ADDED/CHANGED: ticks every 0.1 on y-axis
    plt.gca().set_yticks(np.arange(0.0, 1.01, 0.1))
    plt.gca().tick_params(axis='both', labelsize=14)

    plt.savefig(save_path or '/tmp/cdf.pdf', bbox_inches="tight")
    plt.show()


def main():
    p = argparse.ArgumentParser(description="Plot RTT CDFs from 8 qlog files.")
    p.add_argument('--qlog-paths', nargs=8, required=True,
                   help="Paths to the 8 qlog files in the prescribed order.")
    p.add_argument('--output', help="Optional path to save the plot.")
    args = p.parse_args()

    labels = ["QUIC-DC (10%)","QUIC-DC (20%)","QUIC-DC (50%)","QUIC-DC (80%)",
              "Westwood+","BBRv2","Cubic","New Reno"]

    connections = []
    for path in args.qlog_paths:
        with open(path) as f:
            qlog = json.load(f)
        connections.append({'rtt_data': extract_rtt_metrics(qlog)})

    plot_cdf(connections, labels, save_path=args.output)


if __name__ == "__main__":
    main()
