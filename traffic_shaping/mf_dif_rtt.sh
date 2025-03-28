#!/bin/bash
#
# Shared Buffer Multi-flow Shaping Script (Egress & Ingress)
#
# This script applies a global (shared) rate limiter using TBF with a
# buffer equal to 2×BDP (based on a representative delay) and then attaches
# per-flow netem delay actions via the clsact qdisc and flower filters.
#
# Usage:
#   ./mf_dif_rtt_shared_buffer.sh <interface> <starting_port> <KBPS> <delay1> <delay2> <delay3> <delay4>
#
# Example:
#   ./mf_dif_rtt_shared_buffer.sh eno1 50000 1250 25 50 75 100
#
#   - eno1: the server’s network interface.
#   - 50000: starting client port (subsequent flows use 50001, 50002, 50003).
#   - 1250: bandwidth limit in KBps (applied globally).
#   - delays: one-way delays (in ms) for each flow.
#
# In this example the shared buffer is calculated from the global rate and
# a representative delay (here, the second delay parameter, 50ms).
# (Shared Buffer = 2×BDP; BDP = (Rate in bytes/s) * (delay in s))
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

# Calculate rate in bytes per second
RATE_BYTES=$((KBPS * 1024))

# Use DELAY2 (e.g. 50ms) as the representative delay.
# Convert it to seconds.
REP_DELAY_SEC=$(echo "scale=3; $DELAY2/1000" | bc)

# Calculate Bandwidth-Delay Product (BDP) in bytes:
#   BDP = RATE_BYTES * REP_DELAY_SEC
BDP_BYTES=$(echo "$RATE_BYTES * $REP_DELAY_SEC" | bc | awk '{printf "%d", $0}')

# Shared buffer size = 2 × BDP
SHARED_BUFFER=$((BDP_BYTES * 2))

echo "Configuring multi-flow shaping with shared buffer on interface $IFACE:"
echo " - Global rate: ${RATE_KBIT} kbit/s ( ${KBPS} KBps )"
echo " - Shared buffer (2×BDP, with ${DELAY2}ms as representative): ${SHARED_BUFFER} bytes"
echo " - Flows (client ports): $START_PORT, $((START_PORT+1)), $((START_PORT+2)), $((START_PORT+3))"
echo " - Corresponding delays: ${DELAY1}ms, ${DELAY2}ms, ${DELAY3}ms, ${DELAY4}ms"

#####################
# EGRESS SHAPING
#####################

# Remove any existing root and clsact qdiscs on the interface.
sudo tc qdisc del dev $IFACE root 2>/dev/null
sudo tc qdisc del dev $IFACE clsact 2>/dev/null

# 1. Add a TBF qdisc as the root for global rate limiting and shared buffering.
sudo tc qdisc add dev $IFACE root handle 1: tbf rate ${RATE_KBIT}kbit burst 1600 limit ${SHARED_BUFFER}

# 2. Attach the clsact qdisc to enable egress filtering (this qdisc does not alter buffering).
sudo tc qdisc add dev $IFACE clsact

# 3. Add per-flow egress filters using the flower classifier with netem actions.
#    The filters match on the destination port (i.e. the client’s port).
sudo tc filter add dev $IFACE egress protocol ip flower dst_port $START_PORT action netem delay ${DELAY1}ms
sudo tc filter add dev $IFACE egress protocol ip flower dst_port $((START_PORT+1)) action netem delay ${DELAY2}ms
sudo tc filter add dev $IFACE egress protocol ip flower dst_port $((START_PORT+2)) action netem delay ${DELAY3}ms
sudo tc filter add dev $IFACE egress protocol ip flower dst_port $((START_PORT+3)) action netem delay ${DELAY4}ms

echo "Egress shaping with shared buffer configured on $IFACE."

#####################
# INGRESS SHAPING
#####################

# For ingress, we use an ifb device to mirror incoming packets.
# First, remove any existing ingress qdisc on $IFACE.
sudo tc qdisc del dev $IFACE ingress 2>/dev/null

# Add an ingress qdisc on $IFACE and redirect all packets to ifb1.
sudo tc qdisc add dev $IFACE ingress
sudo tc filter add dev $IFACE parent ffff: protocol ip u32 match u32 0 0 action mirred egress redirect dev ifb1

# Clean up ifb1 and bring it up.
sudo tc qdisc del dev ifb1 root 2>/dev/null
sudo tc qdisc del dev ifb1 clsact 2>/dev/null
sudo ip link set dev ifb1 up

# On ifb1, add a TBF qdisc for global ingress rate limiting with the same shared buffer.
sudo tc qdisc add dev ifb1 root handle 1: tbf rate ${RATE_KBIT}kbit burst 1600 limit ${SHARED_BUFFER}

# Attach the clsact qdisc on ifb1.
sudo tc qdisc add dev ifb1 clsact

# Add per-flow ingress filters using the flower classifier.
# For ingress the match is on the source port (client’s port).
sudo tc filter add dev ifb1 ingress protocol ip flower src_port $START_PORT action netem delay ${DELAY1}ms
sudo tc filter add dev ifb1 ingress protocol ip flower src_port $((START_PORT+1)) action netem delay ${DELAY2}ms
sudo tc filter add dev ifb1 ingress protocol ip flower src_port $((START_PORT+2)) action netem delay ${DELAY3}ms
sudo tc filter add dev ifb1 ingress protocol ip flower src_port $((START_PORT+3)) action netem delay ${DELAY4}ms

echo "Ingress shaping with shared buffer configured on $IFACE (via ifb1)."
echo "Multi-flow shaping with shared buffer applied successfully."
