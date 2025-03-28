#!/bin/bash
#
# Shared Buffer Multi-flow Shaping Script (Egress & Ingress) for UDP Traffic
#
# This script applies a global TBF qdisc with a shared buffer (2×BDP) to all traffic
# and then uses the clsact qdisc with flower filters (forced to software processing via skip_hw)
# to add per-flow netem delay actions based on UDP port numbers.
#
# Usage:
#   ./mf_dif_rtt_shared_buffer_udp.sh <interface> <starting_port> <KBPS> <delay1> <delay2> <delay3> <delay4>
#
# Example:
#   ./mf_dif_rtt_shared_buffer_udp.sh eno1 61400 1250 25 50 75 100
#
#   - eno1: the server’s network interface.
#   - 61400: starting client UDP port (subsequent flows use 61401, 61402, 61403).
#   - 1250: bandwidth limit in KBps (applied globally).
#   - delays: one-way delays (in ms) for each flow.
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

# Convert KBPS (kilobytes per second) to kbit/s
RATE_KBIT=$((KBPS * 8))
RATE_BYTES=$((KBPS * 1024))

# Use DELAY2 as the representative delay (in ms) for buffer calculation.
REP_DELAY_SEC=$(echo "scale=3; $DELAY2/1000" | bc)
BDP_BYTES=$(echo "$RATE_BYTES * $REP_DELAY_SEC" | bc | awk '{printf "%d", $0}')
SHARED_BUFFER=$((BDP_BYTES * 2))

echo "Configuring multi-flow shaping with shared buffer on interface $IFACE:"
echo " - Global rate: ${RATE_KBIT} kbit/s (${KBPS} KBps)"
echo " - Shared buffer (2×BDP with ${DELAY2}ms): ${SHARED_BUFFER} bytes"
echo " - Flows (client UDP ports): $START_PORT, $((START_PORT+1)), $((START_PORT+2)), $((START_PORT+3))"
echo " - Delays: ${DELAY1}ms, ${DELAY2}ms, ${DELAY3}ms, ${DELAY4}ms"

#####################
# EGRESS SHAPING
#####################

# Remove any existing qdiscs on the interface.
sudo tc qdisc del dev $IFACE root 2>/dev/null
sudo tc qdisc del dev $IFACE clsact 2>/dev/null

# 1. Add a global TBF qdisc with the shared buffer.
sudo tc qdisc add dev $IFACE root handle 1: tbf rate ${RATE_KBIT}kbit burst 1600 limit ${SHARED_BUFFER}

# 2. Attach the clsact qdisc to enable egress filtering.
sudo tc qdisc add dev $IFACE clsact

# 3. Add per-flow egress filters using the flower classifier.
#    Match on the UDP destination port and force software processing (skip_hw).
sudo tc filter add dev $IFACE egress protocol ip flower ip_proto udp dst_port $START_PORT skip_hw action netem delay ${DELAY1}ms
sudo tc filter add dev $IFACE egress protocol ip flower ip_proto udp dst_port $((START_PORT+1)) skip_hw action netem delay ${DELAY2}ms
sudo tc filter add dev $IFACE egress protocol ip flower ip_proto udp dst_port $((START_PORT+2)) skip_hw action netem delay ${DELAY3}ms
sudo tc filter add dev $IFACE egress protocol ip flower ip_proto udp dst_port $((START_PORT+3)) skip_hw action netem delay ${DELAY4}ms

echo "Egress shaping with shared buffer configured on $IFACE."

#####################
# INGRESS SHAPING
#####################

# Remove any existing ingress qdisc.
sudo tc qdisc del dev $IFACE ingress 2>/dev/null

# Add ingress qdisc on the physical interface and redirect all packets to ifb1.
sudo tc qdisc add dev $IFACE ingress
sudo tc filter add dev $IFACE parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb1

# Clean up ifb1 and bring it up.
sudo tc qdisc del dev ifb1 root 2>/dev/null
sudo tc qdisc del dev ifb1 clsact 2>/dev/null
sudo ip link set dev ifb1 up

# On ifb1, add a TBF qdisc for global rate limiting with the same shared buffer.
sudo tc qdisc add dev ifb1 root handle 1: tbf rate ${RATE_KBIT}kbit burst 1600 limit ${SHARED_BUFFER}

# Attach clsact on ifb1.
sudo tc qdisc add dev ifb1 clsact

# Add per-flow ingress filters using the flower classifier.
# For ingress, match on the UDP source port and force software processing.
sudo tc filter add dev ifb1 ingress protocol ip flower ip_proto udp src_port $START_PORT skip_hw action netem delay ${DELAY1}ms
sudo tc filter add dev ifb1 ingress protocol ip flower ip_proto udp src_port $((START_PORT+1)) skip_hw action netem delay ${DELAY2}ms
sudo tc filter add dev ifb1 ingress protocol ip flower ip_proto udp src_port $((START_PORT+2)) skip_hw action netem delay ${DELAY3}ms
sudo tc filter add dev ifb1 ingress protocol ip flower ip_proto udp src_port $((START_PORT+3)) skip_hw action netem delay ${DELAY4}ms

echo "Ingress shaping with shared buffer configured on $IFACE (via ifb1)."
echo "Multi-flow shaping with shared buffer applied successfully."
