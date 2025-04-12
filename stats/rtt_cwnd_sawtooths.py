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

def extract_congestion_metrics(qlog_data):
    """
    Extract congestion-related data from qlog_data.
    
    Returns a tuple with:
        - times_cc (list of float): Timestamps (microseconds) for congestion control events
        - data_sent (list of int): Cumulative data sent (bytes)
        - data_acked (list of int): Cumulative data acked (bytes)
        - data_lost (list of int): Cumulative data lost (bytes)
        - cwnd_values (list of int): Congestion window (bytes)
        - bif_values (list of int): Bytes in flight (bytes)
        - ssthresh_list (list of (time, ssthresh))
        - timeouts (list of float): Times (microseconds) when loss timeout expired
        - timeout_counts (dict)
        - lost_event_count (int): Number of `packet_lost` events
    """
    times_cc = []
    data_sent = []
    data_acked = []
    data_lost = []
    cwnd_values = []
    bif_values = []
    ssthresh_list = []
    timeouts = []
    timeout_counts = {}

    cumulative_data_sent = 0
    cumulative_data_acked = 0
    cumulative_data_lost = 0
    lost_event_count = 0

    # Dictionary to track packet_number -> packet_size
    sent_packet_sizes = {}

    events = qlog_data['traces'][0]['events']
    for event in events:
        if len(event) < 4:
            continue

        event_time_us = float(event[0])
        category = event[1]
        event_type = event[2]
        event_data = event[3]

        # Capture timeouts
        if category == 'transport' and event_type == 'transport_state_update':
            if event_data.get('update') == 'loss timeout expired':
                timeouts.append(event_time_us)
                timeout_counts['loss_timeout_expired'] = timeout_counts.get('loss_timeout_expired', 0) + 1

        # ssthresh
        ssthresh = event_data.get('ssthresh', None)
        if ssthresh is not None and ssthresh < 1e5:
            ssthresh_list.append((event_time_us, ssthresh))

        # Packet sent: store packet size by packet number
        if category == 'transport' and event_type == 'packet_sent':
            packet_size = event_data.get('header', {}).get('packet_size', 0)
            packet_num = event_data.get('header', {}).get('packet_number', None)
            cumulative_data_sent += packet_size
            if packet_num is not None:
                sent_packet_sizes[packet_num] = packet_size

        # Packet received: update cumulative data acked for each acked packet
        elif category == 'transport' and event_type == 'packet_received':
            frames = event_data.get('frames', [])
            for frame in frames:
                if frame.get('frame_type') in ('ack', 'ack_receive_timestamps'):
                    acked_ranges = frame.get('acked_ranges', [])
                    for (start_pn, end_pn) in acked_ranges:
                        for pn in range(start_pn, end_pn + 1):
                            if pn in sent_packet_sizes:
                                cumulative_data_acked += sent_packet_sizes[pn]
                                del sent_packet_sizes[pn]

        # Data lost events
        elif category == 'loss' and event_type == 'packets_lost':
            lost_size = event_data.get('lost_bytes', 0)
            lost_packets = event_data.get('lost_packets', 0)
            cumulative_data_lost += lost_size
            lost_event_count += lost_packets

        # Congestion control updates
        if event_type in ['metric_update', 'congestion_metric_update']:
            cwnd = event_data.get('current_cwnd', None)
            bif = event_data.get('bytes_in_flight', None)
            if cwnd is not None and bif is not None:
                times_cc.append(event_time_us)
                data_sent.append(cumulative_data_sent)
                data_acked.append(cumulative_data_acked)
                data_lost.append(cumulative_data_lost)
                cwnd_values.append(cwnd)
                bif_values.append(bif)

    return (times_cc, data_sent, data_acked, data_lost,
            cwnd_values, bif_values, ssthresh_list,
            timeouts, timeout_counts, lost_event_count)

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
        description='Process two qlog files and plot RTT and congestion metrics.'
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

    # Extract congestion metrics from both files using the provided extractor.
    (times_cc1, data_sent1, data_acked1, data_lost1,
     cwnd1, bif1, ssthresh_list1,
     timeouts1, timeout_counts1, lost_event_count1) = extract_congestion_metrics(qlog_data1)

    (times_cc2, data_sent2, data_acked2, data_lost2,
     cwnd2, bif2, ssthresh_list2,
     timeouts2, timeout_counts2, lost_event_count2) = extract_congestion_metrics(qlog_data2)

    # Ensure that there is at least one timestamp in each file
    if not times1 or not times2:
        print("Insufficient RTT data in one or both files.")
        exit(1)

    # Normalize timestamps for RTT using the first RTT timestamp in each file as the base
    base1 = times1[0]
    base2 = times2[0]
    norm_times1 = normalize_times(times1, base1)
    norm_times2 = normalize_times(times2, base2)

    # Convert RTT values from microseconds to milliseconds (ignoring None values)
    latest1_ms = [r / 1000.0 if r is not None else None for r in latest1]
    min1_ms = [r / 1000.0 if r is not None else None for r in min1]
    latest2_ms = [r / 1000.0 if r is not None else None for r in latest2]

    # Normalize congestion metric times using the corresponding base
    norm_times_cc1 = normalize_times(times_cc1, base1) if times_cc1 else []
    norm_times_cc2 = normalize_times(times_cc2, base2) if times_cc2 else []

    # For ssthresh, extract times and values then normalize the times
    norm_times_ssthresh1 = []
    ssthresh_values1 = []
    if ssthresh_list1:
        norm_times_ssthresh1 = normalize_times([t for (t, s) in ssthresh_list1], base1)
        ssthresh_values1 = [s for (t, s) in ssthresh_list1]
    
    norm_times_ssthresh2 = []
    ssthresh_values2 = []
    if ssthresh_list2:
        norm_times_ssthresh2 = normalize_times([t for (t, s) in ssthresh_list2], base2)
        ssthresh_values2 = [s for (t, s) in ssthresh_list2]

    # Create a figure with two subplots: top for RTT, bottom for congestion control
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 12), sharex=True)
    lw = 3  # Standard line width

    ##########################
    # Top: RTT Plot
    ##########################
    # Westwood+ RTT from file 1 (blue)
    if norm_times1 and latest1_ms:
        ax1.plot(norm_times1, latest1_ms, color='blue', linestyle='-',
                 label="Westwood+", linewidth=2)
    # QUIC-DC RTT from file 2 (red)
    if norm_times2 and latest2_ms:
        ax1.plot(norm_times2, latest2_ms, color='red', linestyle='-',
                 label="QUIC-DC(80%)", linewidth=2)
        # Plot Delay Control threshold (purple dash-dot)
        ax1.axhline(y=95, color='purple', linestyle='-.', label="Delay Control threshold", linewidth=lw)
    # RTT min threshold (brown dashed)
    ax1.axhline(y=50, color='brown', linestyle='--', label="RTT min", linewidth=lw)
    # RTT Max threshold (green dashed)
    ax1.axhline(y=105, color='green', linestyle='--', label="RTT Max", linewidth=lw)
    
    ax1.set_ylabel("RTT (ms)", fontsize=22)
    ax1.legend(fontsize=16)
    ax1.tick_params(axis='both', labelsize=18)
    ax1.grid(True)

    ##########################
    # Bottom: Congestion Control Plot (cwnd and ssthresh)
    ##########################
    # Convert congestion metrics from bytes to kilobytes (1 KB = 1024 Bytes)
    cwnd1_kb = [x / 1024.0 for x in cwnd1] if cwnd1 else []
    cwnd2_kb = [x / 1024.0 for x in cwnd2] if cwnd2 else []
    ssthresh1_kb = [x / 1024.0 for x in ssthresh_values1] if ssthresh_values1 else []
    ssthresh2_kb = [x / 1024.0 for x in ssthresh_values2] if ssthresh_values2 else []

    # Westwood+ cwnd (blue solid)
    if norm_times_cc1 and cwnd1_kb:
        ax2.plot(norm_times_cc1, cwnd1_kb, color='blue', linestyle='-',
                 label="Westwood+", linewidth=2)
    # Westwood+ ssthresh (blue dashed)
    if norm_times_ssthresh1 and ssthresh1_kb:
        ax2.plot(norm_times_ssthresh1, ssthresh1_kb, color='blue', linestyle='--', linewidth=2)
    # QUIC-DC cwnd (red solid)
    if norm_times_cc2 and cwnd2_kb:
        ax2.plot(norm_times_cc2, cwnd2_kb, color='red', linestyle='-',
                 label="QUIC-DC(80%)", linewidth=2)
    # QUIC-DC ssthresh (red dashed)
    if norm_times_ssthresh2 and ssthresh2_kb:
        ax2.plot(norm_times_ssthresh2, ssthresh2_kb, color='red', linestyle='--', linewidth=2)
    
    ax2.set_xlabel("Time (s)", fontsize=22)
    ax2.set_ylabel("cwnd / ssthresh (KB)", fontsize=22)
    ax2.legend(fontsize=16)
    ax2.tick_params(axis='both', labelsize=18)
    ax2.grid(True)

    plt.tight_layout()
    plt.savefig('/tmp/sawtooth.pdf', bbox_inches="tight")
    plt.show()

if __name__ == "__main__":
    main()
