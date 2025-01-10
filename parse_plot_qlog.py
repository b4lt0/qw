import json
import pandas as pd
import matplotlib.pyplot as plt

# Load the QLOG file
def parse_qlog(file_path):
    with open(file_path, 'r') as file:
        logs = json.load(file)

    events = logs.get('events', [])
    data = []
    for event in events:
        if event['name'] == 'transport:metrics_updated':  
            time = event['time']  
            metrics = event.get('data', {})
            cwnd = metrics.get('congestion_window', None)
            ssthresh = metrics.get('slow_start_threshold', None)
            if cwnd is not None and ssthresh is not None:
                data.append((time, cwnd, ssthresh))
    return pd.DataFrame(data, columns=['time', 'cwnd', 'ssthresh'])

# Plot the metrics
def plot_metrics(df, title):
    df['time'] = pd.to_datetime(df['time'], unit='ms')  
    df.set_index('time', inplace=True)
    
    plt.figure(figsize=(10, 6))
    plt.plot(df.index, df['cwnd'], label='Congestion Window (cwnd)')
    plt.plot(df.index, df['ssthresh'], label='Slow Start Threshold (ssthresh)', linestyle='--')
    plt.xlabel('Time')
    plt.ylabel('Bytes')
    plt.title(title)
    plt.legend()
    plt.grid()
    plt.show()

file_path = 'high_bandwidth.qlog'  
df = parse_qlog(file_path)
plot_metrics(df, "High Bandwidth Scenario")
