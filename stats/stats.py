import os
import json
import argparse
import matplotlib.pyplot as plt

parser = argparse.ArgumentParser(description='Process a qlog file.')
parser.add_argument('qlog_path', type=str, help='Path to the qlog file')

args = parser.parse_args() 

if not os.path.isfile(qlog_path):
    print(f'Error: The file {qlog_path} does not exist.')
    exit(1)

with open(args.qlog_path, 'r') as file:
    qlog_data = json.load(file)

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
