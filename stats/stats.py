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

def plot_metrics(qlog_data):
    times = []
    data_sent = []
    data_acknowledged = []
    data_lost = []
    cwnd_values = []
    bytes_in_flight_values = []

    cumulative_data_sent = 0
    cumulative_data_acknowledged = 0
    cumulative_data_lost = 0

    for event in qlog_data['traces'][0]['events']:
        event_time = float(event[0]) / 1000  # Convert to milliseconds
        event_type = event[2]
        event_data = event[3]

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

        # Handle metric updates
        if event_type == 'metric_update':
            cwnd = event_data.get('current_cwnd')
            bytes_in_flight = event_data.get('bytes_in_flight')

            # Only append if metric_update is present
            times.append(event_time)
            data_sent.append(cumulative_data_sent)
            data_acknowledged.append(cumulative_data_acknowledged)
            data_lost.append(cumulative_data_lost)
            cwnd_values.append(cwnd)
            bytes_in_flight_values.append(bytes_in_flight)

            print(f"Time: {event_time}, CWND: {cwnd}, Bytes in Flight: {bytes_in_flight}")


    # Check if data is available for plotting
    if not times:
        print("No valid data to plot.")
        return

    # Plot Data
    plt.figure(figsize=(12, 8))

    # Data Transfer Metrics
    plt.subplot(2, 1, 1)
    plt.plot(times, data_sent, label='Data Sent (bytes)', color='blue')
    plt.plot(times, data_acknowledged, label='Data Acknowledged (bytes)', color='green')
    plt.plot(times, data_lost, label='Data Lost (bytes)', color='red')
    plt.xlabel('Time (ms)')
    plt.ylabel('Data (bytes)')
    plt.title('Data Transfer Metrics Over Time')
    plt.legend()
    plt.grid(True)

    # Congestion Metrics
    plt.subplot(2, 1, 2)
    if any(cwnd_values):
        plt.plot(times, cwnd_values, label='Congestion Window (cwnd)', color='purple', marker='o')
    else:
        print("No valid cwnd data to plot.")
    if any(bytes_in_flight_values):
        plt.plot(times, bytes_in_flight_values, label='Bytes in Flight', color='brown', marker='x')
    else:
        print("No valid bytes_in_flight data to plot.")

    plt.xlabel('Time (ms)')
    plt.ylabel('Bytes')
    plt.title('Congestion Control Metrics Over Time')
    plt.legend()
    plt.grid(True)

    plt.tight_layout()
    plt.show()


parser = argparse.ArgumentParser(description='Process a qlog file.')
parser.add_argument('qlog_path', type=str, help='Path to the qlog file')
parser.add_argument('mode', type=str, help='rtt or cogestion metrics')

args = parser.parse_args() 

qlog_path=args.qlog_path

if not os.path.isfile(qlog_path):
    print(f'Error: The file {qlog_path} does not exist.')
    exit(1)

with open(qlog_path, 'r') as file:
    qlog_data = json.load(file)

if args.mode == 'rtt':
    plot_rtt(qlog_data)
elif args.mode == 'metrics':
    plot_metrics(qlog_data)

