#!/bin/bash
#
# Multi-flow Traffic Shaping Script for Server
#
# This script sets up four flows with the same bandwidth (KBPS) but different delays.
# The flows are identified by the client's port numbers.
#
# Usage:
#   ./mf_dif_rtt.sh <interface> <starting_port> <KBPS> <delay1> <delay2> <delay3> <delay4>
#
# Example:
#   ./mf_dif_rtt.sh eno1 5001 1250 25 50 75 100
#
#   - eno1: server network interface to shape
#   - 5001: starting port number on the client; subsequent flows use 5002, 5003, 5004
#   - 1250: bandwidth limit in KBps (applied to each flow)
#   - delays: one-way delays (in ms) for each flow
#
# Make sure to run as root.

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

# Calculate the rate in kbit (KBPS * 8)
RATE=$((KBPS * 8))

echo "Configuring multi-flow shaping on interface $IFACE:"
echo " - Bandwidth per flow: ${RATE} kbit"
echo " - Flows (client ports): $START_PORT, $((START_PORT+1)), $((START_PORT+2)), $((START_PORT+3))"
echo " - Corresponding delays: ${DELAY1}ms, ${DELAY2}ms, ${DELAY3}ms, ${DELAY4}ms"

#############################
#  EGRESS SHAPING (SERVER -> CLIENT)
#############################

# Remove any existing qdisc on the interface
tc qdisc del dev $IFACE root 2>/dev/null

# Create an HTB root qdisc with default class 40
tc qdisc add dev $IFACE root handle 1: htb default 40

# Create four HTB classes under the root with identical rates
tc class add dev $IFACE parent 1: classid 1:10 htb rate ${RATE}kbit
tc class add dev $IFACE parent 1: classid 1:20 htb rate ${RATE}kbit
tc class add dev $IFACE parent 1: classid 1:30 htb rate ${RATE}kbit
tc class add dev $IFACE parent 1: classid 1:40 htb rate ${RATE}kbit

# Attach netem qdiscs to add delay to each class
tc qdisc add dev $IFACE parent 1:10 handle 10: netem delay ${DELAY1}ms
tc qdisc add dev $IFACE parent 1:20 handle 20: netem delay ${DELAY2}ms
tc qdisc add dev $IFACE parent 1:30 handle 30: netem delay ${DELAY3}ms
tc qdisc add dev $IFACE parent 1:40 handle 40: netem delay ${DELAY4}ms

# Add filters to steer outgoing traffic based on client's port (destination port)
tc filter add dev $IFACE protocol ip parent 1: prio 1 u32 match ip dport $START_PORT 0xffff flowid 1:10
tc filter add dev $IFACE protocol ip parent 1: prio 1 u32 match ip dport $((START_PORT+1)) 0xffff flowid 1:20
tc filter add dev $IFACE protocol ip parent 1: prio 1 u32 match ip dport $((START_PORT+2)) 0xffff flowid 1:30
tc filter add dev $IFACE protocol ip parent 1: prio 1 u32 match ip dport $((START_PORT+3)) 0xffff flowid 1:40

echo "Egress shaping configured on $IFACE."

#############################
#  INGRESS SHAPING (CLIENT -> SERVER)
#############################

# Load ifb module and bring up ifb1
modprobe ifb
ip link set dev ifb1 up

# Remove any existing ingress qdisc on the interface and root qdisc on ifb1
tc qdisc del dev $IFACE ingress 2>/dev/null
tc qdisc del dev ifb1 root 2>/dev/null

# Set up ingress redirection from IFACE to ifb1
tc qdisc add dev $IFACE ingress
tc filter add dev $IFACE parent ffff: protocol ip u32 match u32 0 0 \
    action mirred egress redirect dev ifb1

# Create an HTB root qdisc on ifb1 for ingress shaping
tc qdisc add dev ifb1 root handle 1: htb default 40

# Create four HTB classes on ifb1 with identical rates
tc class add dev ifb1 parent 1: classid 1:10 htb rate ${RATE}kbit
tc class add dev ifb1 parent 1: classid 1:20 htb rate ${RATE}kbit
tc class add dev ifb1 parent 1: classid 1:30 htb rate ${RATE}kbit
tc class add dev ifb1 parent 1: classid 1:40 htb rate ${RATE}kbit

# Attach netem qdiscs to add delay for ingress flows
tc qdisc add dev ifb1 parent 1:10 handle 10: netem delay ${DELAY1}ms
tc qdisc add dev ifb1 parent 1:20 handle 20: netem delay ${DELAY2}ms
tc qdisc add dev ifb1 parent 1:30 handle 30: netem delay ${DELAY3}ms
tc qdisc add dev ifb1 parent 1:40 handle 40: netem delay ${DELAY4}ms

# For ingress, match on the client's source port (since packets coming from the client carry its port as source)
tc filter add dev ifb1 protocol ip parent 1: prio 1 u32 match ip sport $START_PORT 0xffff flowid 1:10
tc filter add dev ifb1 protocol ip parent 1: prio 1 u32 match ip sport $((START_PORT+1)) 0xffff flowid 1:20
tc filter add dev ifb1 protocol ip parent 1: prio 1 u32 match ip sport $((START_PORT+2)) 0xffff flowid 1:30
tc filter add dev ifb1 protocol ip parent 1: prio 1 u32 match ip sport $((START_PORT+3)) 0xffff flowid 1:40

echo "Ingress shaping configured on $IFACE (via ifb1)."

echo "Multi-flow shaping applied successfully."
