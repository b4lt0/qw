#!/bin/bash
#
# Shared Buffer Multi-flow Shaping Script (Egress & Ingress) with Software Filters
#
# Usage:
#   ./mf_dif_rtt_shared_buffer.sh <interface> <starting_port> <KBPS> <delay1> <delay2> <delay3> <delay4>
#
# Example:
#   ./mf_dif_rtt_shared_buffer.sh eno1 61300 1250 25 50 75 100
#
# This script uses a global TBF for a shared buffer and applies per-flow delays using
# clsact filters with the flower classifier. The "skip_hw" flag is used to force software
# processing.
#

if [ $# -ne 7 ]; then
    echo "Usage: $0 <interface> <starting_port> <KBPS> <delay1> <delay2> <delay3> <delay4>"
    exit 1
fi

IFACE=$1
START_PORT=$2
KBPS=$3
DELAY1=$4
DELAY2=$5
DELAY3=$6
DELAY4=$7

# Convert KBPS (kilobytes per second) to kbit
RATE_KBIT=$((KBPS * 8))
RATE_BYTES=$((KBPS * 1024))

# Use DELAY2 as the representative delay (in ms) for buffer calculation.
REP_DELAY_SEC=$(echo "scale=3; $DELAY2/1000" | bc)
BDP_BYTES=$(echo "$RATE_BYTES * $REP_DELAY_SEC" | bc | awk '{printf "%d", $0}')
SHARED_BUFFER=$((BDP_BYTES * 2))

echo "Configuring multi-flow shaping with shared buffer on interface $IFACE:"
echo " - Global rate: ${RATE_KBIT} kbit/s (${KBPS} KBps)"
echo " - Shared buffer (2×BDP with ${DELAY2}ms): ${SHARED_BUFFER} bytes"
echo " - Flows (client ports): $START_PORT, $((START_PORT+1)), $((START_PORT+2)), $((START_PORT+3))"
echo " - Delays: ${DELAY1}ms, ${DELAY2}ms, ${DELAY3}ms, ${DELAY4}ms"

#####################
# EGRESS SHAPING
#####################

# Remove any existing qdiscs on the interface.
sudo tc qdisc del dev $IFACE root 2>/dev/null
sudo tc qdisc del dev $IFACE clsact 2>/dev/null

# 1. Add a global TBF qdisc with a shared buffer.
sudo tc qdisc add dev $IFACE root handle 1: tbf rate ${RATE_KBIT}kbit burst 1600 limit ${SHARED_BUFFER}

# 2. Attach clsact to enable egress filtering.
sudo tc qdisc add dev $IFACE clsact

# 3. Add per-flow egress filters using the flower classifier.
#    We match on the destination port (client port) and use "skip_hw" to force software processing.
sudo tc filter add dev $IFACE egress protocol ip flower dst_port $START_PORT skip_hw action netem delay ${DELAY1}ms
sudo tc filter add dev $IFACE egress protocol ip flower dst_port $((START_PORT+1)) skip_hw action netem delay ${DELAY2}ms
sudo tc filter add dev $IFACE egress protocol ip flower dst_port $((START_PORT+2)) skip_hw action netem delay ${DELAY3}ms
sudo tc filter add dev $IFACE egress protocol ip flower dst_port $((START_PORT+3)) skip_hw action netem delay ${DELAY4}ms

echo "Egress shaping with shared buffer configured on $IFACE."

#####################
# INGRESS SHAPING
#####################

# Remove any existing ingress qdisc.
sudo tc qdisc del dev $IFACE ingress 2>/dev/null

# Add ingress qdisc on the physical interface and redirect to ifb1.
sudo tc qdisc add dev $IFACE ingress
sudo tc filter add dev $IFACE parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb1

# Clean and bring up ifb1.
sudo tc qdisc del dev ifb1 root 2>/dev/null
sudo tc qdisc del dev ifb1 clsact 2>/dev/null
sudo ip link set dev ifb1 up

# On ifb1, add a TBF qdisc for global rate limiting with the same shared buffer.
sudo tc qdisc add dev ifb1 root handle 1: tbf rate ${RATE_KBIT}kbit burst 1600 limit ${SHARED_BUFFER}

# Attach clsact on ifb1.
sudo tc qdisc add dev ifb1 clsact

# Add per-flow ingress filters using the flower classifier.
# For ingress, match on the source port (client port), using "skip_hw".
sudo tc filter add dev ifb1 ingress protocol ip flower src_port $START_PORT skip_hw action netem delay ${DELAY1}ms
sudo tc filter add dev ifb1 ingress protocol ip flower src_port $((START_PORT+1)) skip_hw action netem delay ${DELAY2}ms
sudo tc filter add dev ifb1 ingress protocol ip flower src_port $((START_PORT+2)) skip_hw action netem delay ${DELAY3}ms
sudo tc filter add dev ifb1 ingress protocol ip flower src_port $((START_PORT+3)) skip_hw action netem delay ${DELAY4}ms

echo "Ingress shaping with shared buffer configured on $IFACE (via ifb1)."
echo "Multi-flow shaping with shared buffer applied successfully."
