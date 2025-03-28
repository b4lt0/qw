#!/bin/bash
set -e

# Configuration parameters
REMOTE_HOST="balillus@10.73.0.20"
DEV="eno1"
DELAY_MS=10
# (Bandwidth values remain as before – note these should be numeric, e.g. using arithmetic expansion if needed)
LOW_BW=$((1024*8))    # in kbit
HIGH_BW=$((2048*8))   # in kbit
BURST=20000
LIMIT_PACKETS=67    # netem’s packet limit (as in the snippet)
LIMIT=81920         # TBF’s queue size limit (as in the snippet)
MTU=1500            # assumed value for minburst

# --- Remote Setup: Install delay shaping on both egress and ingress ---
echo "Setting up remote delay shaping on ${DEV} and IFB..."
ssh -o StrictHostKeyChecking=no $REMOTE_HOST <<'EOF'
  set -e
  DEV="eno1"
  DELAY_MS=10
  BURST=20000
  LIMIT=81920
  LIMIT_PACKETS=67
  MTU=1250

  # EGRESS: Install TBF for bandwidth limiting with a queue limit,
  # then attach netem for delay (and its own packet limit).
  sudo tc qdisc replace dev $DEV root handle 1: tbf rate 100mbit minburst $MTU burst $BURST limit $LIMIT
  sudo tc qdisc add dev $DEV parent 1:1 handle 10: netem delay ${DELAY_MS}ms limit ${LIMIT_PACKETS}

  # INGRESS: Setup an IFB device and mirror similar shaping.
  sudo modprobe ifb
  sudo ip link set dev ifb0 up
  # Redirect all ingress traffic on $DEV to ifb0
  sudo tc qdisc replace dev $DEV ingress
  sudo tc filter replace dev $DEV parent ffff: protocol ip u32 match u32 0 0 \
      action mirred egress redirect dev ifb0

  # On ifb0, apply the same TBF+netem structure for ingress shaping.
  sudo tc qdisc replace dev ifb0 root handle 1: tbf rate 100mbit minburst $MTU burst ${BURST} limit $LIMIT
  sudo tc qdisc add dev ifb0 parent 1:1 handle 10: netem delay ${DELAY_MS}ms limit ${LIMIT_PACKETS}
EOF

# --- Start the client ---
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

# --- Inner Loop: Toggle bandwidth only ---
while kill -0 $HQ50_PID 2>/dev/null; do
    # Set low bandwidth on both egress and ingress (adjusting the TBF rate)
    ssh -o StrictHostKeyChecking=no $REMOTE_HOST "sudo tc qdisc change dev $DEV root handle 1: tbf rate ${LOW_BW}kbit minburst $MTU burst $BURST limit $LIMIT; \
                                               sudo tc qdisc change dev ifb0 root handle 1: tbf rate ${LOW_BW}kbit minburst $MTU burst $BURST limit $LIMIT"
    echo "Low bw set to ${LOW_BW} kbit"
    sleep 8

    # Check if client is still running
    if ! kill -0 $HQ50_PID 2>/dev/null; then
        break
    fi

    # Set high bandwidth on both egress and ingress
    ssh -o StrictHostKeyChecking=no $REMOTE_HOST "sudo tc qdisc change dev $DEV root handle 1: tbf rate ${HIGH_BW}kbit minburst $MTU burst $BURST limit $LIMIT; \
                                               sudo tc qdisc change dev ifb0 root handle 1: tbf rate ${HIGH_BW}kbit minburst $MTU burst $BURST limit $LIMIT"
    echo "High bw set to ${HIGH_BW} kbit"
    sleep 8

    end=$(date +%s)
    elapsed=$((end - start))
    echo "Elapsed time: $elapsed s"
done

echo -n "Waiting for local hq client to complete... "
wait $HQ50_PID
echo "Local hq client transfer completed."

# --- Remote Cleanup: Remove all shaping ---
echo "Cleaning up remote shaping..."
ssh -o StrictHostKeyChecking=no $REMOTE_HOST <<'EOF'
  DEV="eno1"
  sudo tc qdisc del dev $DEV root || true
  sudo tc qdisc del dev $DEV ingress || true
  sudo tc qdisc del dev ifb0 root || true
  sudo ip link set dev ifb0 down || true
EOF

exit 0
