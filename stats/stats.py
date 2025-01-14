import os
import json
import argparse
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

def plot_rtt(qlog_data):
    times = []
    latest_rtts = []
    min_rtts = []
    smoothed_rtts = []

    for event in qlog_data['traces'][0]['events']:
        if event[1] == 'recovery' and event[2] == 'metric_update':
            times.append(float(event[0]))
            latest_rtts.append(event[3].get('latest_rtt'))
            min_rtts.append(event[3].get('min_rtt'))
            smoothed_rtts.append(event[3].get('smoothed_rtt'))

    times = [t / 1000 for t in times]

    plt.figure(figsize=(10, 6))

    plt.plot(times, latest_rtts, label='Latest RTT', linestyle='-', marker='o')
    plt.plot(times, min_rtts, label='Minimum RTT', linestyle='--', marker='x')
    plt.plot(times, smoothed_rtts, label='Smoothed RTT', linestyle='-.', marker='s')

    plt.xlabel('Time (ms)')
    plt.ylabel('RTT (ms)')
    plt.title('RTT Metrics Over Time')
    plt.legend()
    plt.grid(True)
    plt.show()

def plot_metrics(qlog_data,
                 plot_bytes_in_flight=False,
                 plot_timeouts=False,
                 plot_sstresh=False):
    times = []
    data_sent = []
    data_acknowledged = []
    data_lost = []
    cwnd_values = []
    bytes_in_flight_values = []
    ssthresh_values = []
    timeout_times = []
    timeout_counts = {}

    cumulative_data_sent = 0
    cumulative_data_acknowledged = 0
    cumulative_data_lost = 0

    for event in qlog_data['traces'][0]['events']:
        event_time = float(event[0]) / 1000  # Convert to milliseconds
        event_type = event[2]
        event_data = event[3]

        # Handle timeouts
        if plot_timeouts and event[1] == 'recovery' and 'timeout' in event_type:
            timeout_times.append(event_time)
            timeout_counts[event_type] = timeout_counts.get(event_type, 0) + 1

        # Collect `ssthresh` values if available
        ssthresh = event_data.get('ssthresh')
        if ssthresh is not None:
            ssthresh_values.append((event_time, ssthresh))

        # Handle packet-related events
        if event_type == 'packet_sent':
            packet_size = event_data['header'].get('packet_size', 0)
            cumulative_data_sent += packet_size
        elif event_type == 'packet_received':
            acked_ranges = event_data.get('acked_ranges', [])
            acked_data_size = sum(end - start + 1 for start, end in acked_ranges)
            cumulative_data_acknowledged += acked_data_size
        elif event_type == 'packet_lost':
            lost_packet_size = event_data.get('header', {}).get('packet_size', 0)
            cumulative_data_lost += lost_packet_size

        # Handle congestion metrics
        if event_type in ['metric_update', 'congestion_metric_update']:
            cwnd = event_data.get('current_cwnd')
            bytes_in_flight = event_data.get('bytes_in_flight')

            if cwnd is None or bytes_in_flight is None:
                continue

            times.append(event_time)
            data_sent.append(cumulative_data_sent)
            data_acknowledged.append(cumulative_data_acknowledged)
            data_lost.append(cumulative_data_lost)
            cwnd_values.append(cwnd if cwnd is not None else 0)
            if plot_bytes_in_flight:
                bytes_in_flight_values.append(bytes_in_flight if bytes_in_flight is not None else 0)

    if not times:
        print("No valid data to plot.")
        return

    plt.figure(figsize=(12, 8))

    # Data Transfer Metrics
    plt.subplot(2, 1, 1)
    plt.plot(times, data_sent, label='Data Sent (bytes)', color='blue')
    plt.plot(times, data_acknowledged, label='Data Acknowledged (bytes)', color='green')
    plt.plot(times, data_lost, label='Data Lost (bytes)', color='red')
    if plot_timeouts:
        for timeout_time in timeout_times:
            plt.axvline(timeout_time, color='orange', linestyle='--', label='Timeout Event')
    plt.xlabel('Time (ms)')
    plt.ylabel('Data (bytes)')
    plt.title('Data Transfer Metrics Over Time')
    plt.legend()
    plt.grid(True)

    # Congestion Metrics
    plt.subplot(2, 1, 2)
    if any(cwnd_values):
        plt.plot(times, cwnd_values, label='Congestion Window (cwnd)', color='purple', marker='o')
    if plot_bytes_in_flight:
        if any(bytes_in_flight_values):
            plt.plot(times, bytes_in_flight_values, label='Bytes in Flight', color='brown', marker='x')
    if plot_timeouts:
        for timeout_time in timeout_times:
            plt.axvline(timeout_time, color='orange', linestyle='--', label='Timeout Event')
    if ssthresh_values:
        ssthresh_times, ssthresh_vals = zip(*ssthresh_values)
        plt.step(ssthresh_times, ssthresh_vals, label='SSThresh', color='red', linestyle='--')

    plt.xlabel('Time (ms)')
    plt.ylabel('Bytes')
    plt.title('Congestion Control Metrics Over Time')
    plt.legend()
    plt.grid(True)

    plt.tight_layout()
    plt.show()

    if plot_timeouts:
        total_timeouts = sum(timeout_counts.values())
        print("\nTimeout Summary:")
        for timeout_type, count in timeout_counts.items():
            print(f"- {timeout_type}: {count}")
        print(f"Total Timeouts: {total_timeouts}")


parser = argparse.ArgumentParser(description='Process a qlog file.')
parser.add_argument('qlog_path', type=str, help='Path to the qlog file')
parser.add_argument('--plot-bytes-in-flight', action='store_true', default=False, 
                    help='Enable plotting of bytes in flight (default: disabled)')
parser.add_argument('--plot-timeouts', action='store_true', default=False,
                    help='Enable plotting of timeout events and SSThresh (default: disabled)')

args = parser.parse_args()

qlog_path = args.qlog_path

if not os.path.isfile(qlog_path):
    print(f'Error: The file {qlog_path} does not exist.')
    exit(1)

with open(qlog_path, 'r') as file:
    qlog_data = json.load(file)

plot_rtt(qlog_data)
plot_metrics(qlog_data, plot_bytes_in_flight=args.plot_bytes_in_flight,
                        plot_timeouts=args.plot_timeouts,
                        plot_sstresh=args.plot_sstresh)
