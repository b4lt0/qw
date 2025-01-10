import os
import json
import argparse
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

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
        plot_rtt(args.qlog_path)
elif args.mode == 'metrics':
        plot_metrics(args.qlog_path)

def plot_rtt():
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

def plot_metrics():
    times = []
    data_sent = []
    data_acknowledged = []
    data_lost = []
    cwnd_values = []
    ssthresh_values = []
    bytes_in_flight_values = []

    cumulative_data_sent = 0
    cumulative_data_acknowledged = 0
    cumulative_data_lost = 0

    for event in qlog_data['traces'][0]['events']:
        event_time = float(event[0]) / 1000  # Convert to milliseconds
        event_type = event[2]
        event_data = event[3]

        if event_type == 'packet_sent':
            packet_size = event_data['header']['packet_size']
            cumulative_data_sent += packet_size
            times.append(event_time)
            data_sent.append(cumulative_data_sent)
            data_acknowledged.append(cumulative_data_acknowledged)
            data_lost.append(cumulative_data_lost)
            cwnd_values.append(None)
            ssthresh_values.append(None)
            bytes_in_flight_values.append(None)

        elif event_type == 'ack_received':
            acked_ranges = event_data['acked_ranges']
            # Calculate the total size of acknowledged data
            acked_data_size = sum(end - start + 1 for start, end in acked_ranges)
            cumulative_data_acknowledged += acked_data_size
            times.append(event_time)
            data_sent.append(cumulative_data_sent)
            data_acknowledged.append(cumulative_data_acknowledged)
            data_lost.append(cumulative_data_lost)
            cwnd_values.append(None)
            ssthresh_values.append(None)
            bytes_in_flight_values.append(None)

        elif event_type == 'packet_lost':
            lost_packet_size = event_data['header']['packet_size']
            cumulative_data_lost += lost_packet_size
            times.append(event_time)
            data_sent.append(cumulative_data_sent)
            data_acknowledged.append(cumulative_data_acknowledged)
            data_lost.append(cumulative_data_lost)
            cwnd_values.append(None)
            ssthresh_values.append(None)
            bytes_in_flight_values.append(None)

        elif event_type == 'metrics_updated':
            cwnd = event_data.get('cwnd')
            ssthresh = event_data.get('ssthresh')
            bytes_in_flight = event_data.get('bytes_in_flight')
            times.append(event_time)
            data_sent.append(cumulative_data_sent)
            data_acknowledged.append(cumulative_data_acknowledged)
            data_lost.append(cumulative_data_lost)
            cwnd_values.append(cwnd)
            ssthresh_values.append(ssthresh)
            bytes_in_flight_values.append(bytes_in_flight)

    times = [t for t, s in zip(times, data_sent) if s is not None]
    data_sent = [s for s in data_sent if s is not None]
    data_acknowledged = [a for a in data_acknowledged if a is not None]
    data_lost = [l for l in data_lost if l is not None]
    cwnd_values = [c for c in cwnd_values if c is not None]
    ssthresh_values = [s for s in ssthresh_values if s is not None]
    bytes_in_flight_values = [b for b in bytes_in_flight_values if b is not None]

    plt.figure(figsize=(12, 8))

    # Plot Data Sent, Acknowledged, and Lost
    plt.subplot(3, 1, 1)
    plt.plot(times, data_sent, label='Data Sent (bytes)', color='blue')
    plt.plot(times, data_acknowledged, label='Data Acknowledged (bytes)', color='green')
    plt.plot(times, data_lost, label='Data Lost (bytes)', color='red')
    plt.xlabel('Time (ms)')
    plt.ylabel('Data (bytes)')
    plt.title('Data Transfer Metrics Over Time')
    plt.legend()
    plt.grid(True)

    # Plot Congestion Window and ssthresh
    plt.subplot(3, 1, 2)
    plt.plot(times, cwnd_values, label='Congestion Window (cwnd)', color='purple')
    plt.plot(times, ssthresh_values, label='Slow Start Threshold (ssthresh)', color='orange')
    plt.xlabel('Time (ms)')
    plt.ylabel('Size (bytes)')
    plt.title('Congestion Control Metrics Over Time')
    plt.legend()
    plt.grid(True)

    # Plot Bytes in Flight
    plt.subplot(3, 1, 3)
    plt.plot(times, bytes_in_flight_values, label='Bytes in Flight', color='brown')
    plt.xlabel('Time (ms)')
    plt.ylabel('Bytes')
    plt.title('Bytes in Flight Over Time')
    plt.legend()
    plt.grid(True)

    plt.tight_layout()
    plt.show()

