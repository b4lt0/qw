#!/bin/bash
set -e

# This script now assumes that on the remote host the new functions are available:
#   tc_delay_queue_limit_both <DEV> <DELAY_MS> <LIMIT_PKTS>
#   tc_bandwidth_both <DEV> <KBPS> <QUEUE_KB>
#   tc_del_bandwidth_both <DEV>
#   tc_del_delay_queue_limit_both <DEV>
#
# In our example, we will use a 10ms delay and a queue/limit of 67 packets as the static configuration,
# and then repeatedly toggle between a low bandwidth of 1024 KBps and a high bandwidth of 2048 KBps
# (with an 80 KB queue size used for bandwidth shaping).

# Start local HTTP client (50MB file) in the background
echo -n "Starting local hq client for /largefile50M.bin... "
start=$(date +%s)
sleep 0.5 && /qw/proxygen/proxygen/_build/proxygen/httpserver/hq \
    --mode=client \
    --host=10.73.0.20 \
    --outdir=/qw/client \
    --path="/largefile50M.bin" \
    -qlogger_path=/qw/client/logs/ \
    -stream_flow_control=2147483647 > /dev/null 2>&1 &
HQ50_PID=$!
echo "done."

# -------------------------------------------------------------------
# Set static delay, queue, and limit configuration once on the remote host
# This installs a persistent netem qdisc (on both egress and ingress via ifb1)
# that provides the fixed delay and packet queue limit.
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
  "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_delay_queue_limit_both eno1 10 67"
echo "Static delay, queue and limits set."
# -------------------------------------------------------------------

# Loop toggling between low and high bandwidth shaping until the client completes
while kill -0 $HQ50_PID 2>/dev/null; do
    # --- LOW BANDWIDTH ---
    # Apply low bandwidth shaping (1024 KBps with a 80 KB queue) as a child of the static netem
    ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
      "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_bandwidth_both eno1 1024 80"
    echo "Low bandwidth shaping started"
    sleep 8
    # Remove low bandwidth shaping while leaving the static delay in place
    ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
      "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_del_bandwidth_both eno1"
    echo "Low bandwidth shaping ended"

    # Check if the client is still running before switching to high
    if ! kill -0 $HQ50_PID 2>/dev/null; then
        break
    fi

    # --- HIGH BANDWIDTH ---
    # Apply high bandwidth shaping (2048 KBps with a 80 KB queue)
    ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
      "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_bandwidth_both eno1 2048 80"
    echo "High bandwidth shaping started"
    sleep 8
    # Remove high bandwidth shaping while leaving the static delay in place
    ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
      "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_del_bandwidth_both eno1"
    echo "High bandwidth shaping ended"

    # Optionally print elapsed time
    end=$(date +%s)
    elapsed=$((end - start))
    echo "Elapsed time: $elapsed s"
done

# -------------------------------------------------------------------
# Remove the persistent (static) delay, queue, and limit configuration
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
  "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_del_delay_queue_limit_both eno1"
echo "Static delay, queue and limits removed."
# -------------------------------------------------------------------

echo -n "Waiting for local hq client to complete... "
wait $HQ50_PID
echo "Local hq client transfer completed."

exit 0
