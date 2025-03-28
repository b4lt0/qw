#!/bin/bash
#
# cleanup.sh: Cleans all traffic control rules on a specified interface.
#
# Usage: ./cleanup.sh <interface>
# Example: ./cleanup.sh eno1
#
# This script removes both egress (root) and ingress qdiscs from the given interface.
# It also checks for an ifb device (ifb1) and cleans its qdisc and brings it down.
#
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <interface>"
    exit 1
fi

IFACE=$1

echo "Cleaning egress (root) qdisc on interface $IFACE..."
tc qdisc del dev "$IFACE" root 2>/dev/null

echo "Cleaning ingress qdisc on interface $IFACE..."
tc qdisc del dev "$IFACE" ingress 2>/dev/null

# Check if ifb1 exists and clean its qdisc if used
if ip link show ifb1 &>/dev/null; then
    echo "Cleaning qdisc on ifb1..."
    tc qdisc del dev ifb1 root 2>/dev/null

    echo "Bringing down ifb1 interface..."
    ip link set dev ifb1 down 2>/dev/null
fi

echo "All traffic control rules have been removed from $IFACE (and ifb1 if it was used)." 
