#!/bin/bash
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Author: Gaetano Carlucci
# Modified by: [Your Name] - Added option for fixed queue and packet length

tc="sudo /sbin/tc"
modprobe="sudo /sbin/modprobe"
ip="sudo /sbin/ip"

# This function disables the NIC optimizations that interfere with the experiment
# INPUT PARAMETER:
# 1 : Device interface that receives the traffic: example eth0
function disabe_nic_opt()
{
   DEV=$1
   echo "Optimization on $DEV disabled"
   sudo ethtool -K $DEV gro off
   sudo ethtool -K $DEV tso off
   sudo ethtool -K $DEV gso off
}

# This function applies egress bandwidth control, delay, and optional loss
# INPUT PARAMETERS:
# 1 - Bottleneck buffer size in KB (e.g., 30 for 30KB)
# 2 - Device interface (e.g., eno1)
# 3 - Bandwidth limit in KBps (e.g., 1250 for ~10MBps)
# 4 - Delay in ms (e.g., 50 for 50ms)
# 5 - Netem queue limit in packets (e.g., 1000)
# 6 - Packet loss percentage (e.g., 0.5 for 0.5%)
# 7 - BDP in bytes (calculated from KBPS and delay)
function tc_egress_with_delay() {
   QUEUE=$1
   DEV=$2
   KBPS=$3
   DELAY=$4
   LIMIT_PACKETS=$5
   LOSS=$6
   BDP_BYTES=$7
   BRATE=$((KBPS * 8)) # Convert KBps to kbit/s
   MTU=1000
   LIMIT=$((MTU * QUEUE)) # Queue length in bytes

   echo "Applying egress bandwidth, delay, and loss on $DEV"
   echo "* Bandwidth: ${BRATE}kbit (${KBPS} KBps)"
   echo "* Delay: ${DELAY}ms"
   echo "* Loss: ${LOSS}%"
   echo "* Netem Queue Limit: ${LIMIT_PACKETS} packets"

   # Add TBF as root qdisc for bandwidth control
   $tc qdisc add dev $DEV root handle 1: tbf rate ${BRATE}kbit \
       minburst $MTU burst $((BDP_BYTES * 5)) limit $LIMIT

   # Add NetEm as a child qdisc for delay, loss, with packet limit
   $tc qdisc add dev $DEV parent 1:1 handle 10: netem \
       delay ${DELAY}ms loss ${LOSS}% limit ${LIMIT_PACKETS}
}

# This function removes both egress bandwidth control and delay
# INPUT PARAMETER: 1 - Device interface (e.g., eno1)
function tc_del_egress_with_delay() {
   DEV=$1
   echo "Removing egress bandwidth, delay, and loss on $DEV"
   $tc qdisc del dev $DEV root
}

# This function introduces link capacity constraints on incoming traffic from a specific IP
# INPUT PARAMETERS:
# 1 : IP address of the sender machine: example 192.168.0.10
# 2 : Bottleneck buffer size in KB (e.g., 30 for 30KB)
# 3 : Device interface (e.g., eth0)
# 4 : Capacity constraint in KBps (e.g., 250 for 250KBps)
function tc_ingress()
{
   SRC=$1
   QUEUE=$2
   DEV=$3
   KBPS=$4 # kilobytes per second
   BRATE=$((KBPS * 8)) # BRATE should be in kbit/s
   MTU=1000
   LIMIT=$((MTU * QUEUE)) # Queue length in bytes

   echo "TC SHAPER INGRESS ON $HOSTNAME"
   echo "* rate ${BRATE}kbit ($KBPS kbyte/s)"
   echo "* ip src: $SRC"
   echo "* dev $DEV"

   $modprobe ifb
   $ip link set dev ifb1 up
   $tc qdisc add dev $DEV ingress

   $tc filter add dev $DEV parent ffff: protocol ip u32 match ip src $SRC flowid 1:1 action mirred egress redirect dev ifb1
   $tc qdisc add dev ifb1 root handle 1: tbf rate ${BRATE}kbit \
       minburst $MTU burst $((MTU * 10)) limit $LIMIT
}

# This function introduces link capacity constraints on all incoming traffic
# INPUT PARAMETERS:
# 1 : Bottleneck buffer size in KB (e.g., 30 for 30KB)
# 2 : Device interface (e.g., eth0)
# 3 : Capacity constraint in KBps (e.g., 250 for 250KBps)
function tc_ingress_all()
{
   QUEUE=$1
   DEV=$2
   KBPS=$3 # kilobytes per second
   BRATE=$((KBPS * 8)) # BRATE should be in kbit/s
   MTU=1000
   LIMIT=$((MTU * QUEUE)) # Queue length in bytes

   echo "TC SHAPER INGRESS ON $HOSTNAME"
   echo "* rate ${BRATE}kbit ($KBPS KB/s)"
   echo "* dev $DEV"

   $modprobe ifb
   $ip link set dev ifb1 up
   $tc qdisc add dev $DEV ingress

   $tc filter add dev $DEV parent ffff: protocol ip u32 match u32 0 0 flowid 1:1 \
       action mirred egress redirect dev ifb1
   $tc qdisc add dev ifb1 root handle 1: tbf rate ${BRATE}kbit \
       minburst $MTU burst $((MTU * 10)) limit $LIMIT
}

# This function removes the capacity constraint on incoming traffic
# INPUT PARAMETER:
# 1 : Device interface (e.g., eth0)
function tc_del_ingress() {
   DEV=$1
   $tc qdisc del dev $DEV ingress 2>/dev/null
   $tc qdisc del dev ifb1 root 2>/dev/null
   $ip link set dev ifb1 down
   echo "Bandwidth constraint ingress turned off on $DEV"
}

# This function introduces link capacity constraints on outgoing traffic
# INPUT PARAMETERS:
# 1 : Bottleneck buffer size in KB (e.g., 30 for 30KB)
# 2 : Device interface (e.g., eth0)
# 3 : Capacity constraint in KBps (e.g., 250 for 250KBps)
function tc_egress() {
   QUEUE=$1
   DEV=$2
   KBPS=$3 # kilobytes per second
   BRATE=$((KBPS * 8)) # BRATE should be in kbit/s
   MTU=1000
   LIMIT=$((MTU * QUEUE)) # Queue length in bytes

   echo "TC SHAPER EGRESS ON $HOSTNAME"
   echo "* rate ${BRATE}kbit ($KBPS KB/s)"
   echo "* dev $DEV"

   $tc qdisc add dev $DEV root handle 1: tbf rate ${BRATE}kbit \
       minburst $MTU burst $((MTU * 10)) limit $LIMIT
}

# This function removes the capacity constraint on outgoing traffic
# INPUT PARAMETER:
# 1 : Device interface (e.g., eth0)
function tc_del_egress() {
   DEV=$1
   $tc qdisc del dev $DEV root 2>/dev/null
   echo "Bandwidth constraint egress turned off on $DEV"
}

# This function introduces propagation delay on the traffic over the specified interface
# INPUT PARAMETERS:
# 1 : Device interface (e.g., eth0)
# 2 : Delay in ms (e.g., 50 for 50ms)
function tc_delay() {
   DEV=$1
   DELAY=$2
   echo "tc_delay: dev: $DEV delay: $DELAY ms"
   $tc qdisc add dev $DEV root netem delay ${DELAY}ms
}

# This function removes propagation delay
# INPUT PARAMETER:
# 1 : Device interface (e.g., eth0)
function tc_del_delay()
{
   DEV=$1
   $tc qdisc del dev $DEV root 2>/dev/null
   echo "Delay turned off on $DEV"
}

# This function adds fair queuing policy on incoming traffic 
# Must be executed after tc_ingress or tc_ingress_all
function add_sfq_ingress()
{
   $tc qdisc add dev ifb1 parent 1:1 handle 10: sfq perturb 10  
}

# This function adds fair queuing policy on outgoing traffic 
# Must be executed after tc_egress
# INPUT PARAMETER:
# 1 : Device interface 
function add_sfq_egress()
{
   DEV=$1
   $tc qdisc add dev $DEV parent 1:1 handle 10: sfq perturb 10
}

# This function applies INGRESS bandwidth control, delay, and optional loss,
# similarly to tc_egress_with_delay, but via an ifb device.
# INPUT PARAMETERS:
# 1 - Bottleneck buffer size in KB (e.g., 30 for 30KB)
# 2 - Device interface (e.g., eth0)
# 3 - Bandwidth limit in KBps (e.g., 1250 for ~10MBps)
# 4 - Delay in ms (e.g., 50 for 50ms)
# 5 - Netem queue limit in packets (e.g., 1000)
# 6 - Packet loss percentage (e.g., 0.5 for 0.5%)
# 7 - BDP in bytes (calculated from KBPS and delay)
function tc_ingress_with_delay() {
   QUEUE=$1
   DEV=$2
   KBPS=$3
   DELAY=$4
   LIMIT_PACKETS=$5
   LOSS=$6
   BDP_BYTES=$7
   BRATE=$((KBPS * 8)) # Convert KBps to kbit/s
   MTU=1000
   LIMIT=$((MTU * QUEUE)) # Queue length in bytes

   echo "Applying ingress bandwidth + delay + loss on $DEV using ifb1"
   echo "* Bandwidth: ${BRATE}kbit (${KBPS} KBps)"
   echo "* Delay: ${DELAY}ms"
   echo "* Loss: ${LOSS}%"
   echo "* Netem Queue Limit: ${LIMIT_PACKETS} packets"

   # 1) Load the ifb module and bring up the ifb1 interface
   $modprobe ifb
   $ip link set dev ifb1 up

   # 2) Attach ingress qdisc on $DEV, and redirect all traffic to ifb1
   $tc qdisc add dev $DEV ingress
   $tc filter add dev $DEV parent ffff: protocol ip u32 match u32 0 0 \
       flowid 1:1 action mirred egress redirect dev ifb1

   # 3) On ifb1, install TBF as root for bandwidth limiting
   $tc qdisc add dev ifb1 root handle 1: tbf rate ${BRATE}kbit \
       minburst $MTU burst $((BDP_BYTES * 5)) limit $LIMIT

   # 4) Attach netem as a child for delay + loss + queue limit
   $tc qdisc add dev ifb1 parent 1:1 handle 10: netem \
       delay ${DELAY}ms loss ${LOSS}% limit ${LIMIT_PACKETS}
}

# This function removes both ingress bandwidth control, delay, and loss
# INPUT PARAMETER:
# 1 - Device interface (e.g., eth0)
function tc_del_ingress_with_delay() {
   DEV=$1
   echo "Removing ingress bandwidth + delay + loss on $DEV (ifb1)"

   # 1) Delete root qdisc on ifb1, then bring ifb1 down
   $tc qdisc del dev ifb1 root 2>/dev/null
   $ip link set dev ifb1 down

   # 2) Delete the ingress qdisc on $DEV (which removes the redirect)
   $tc qdisc del dev $DEV ingress 2>/dev/null
}

#-----------------------------------------------------------------------
# Modified function: tc_bw_delay_both
#
# Usage:
#   tc_bw_delay_both <DEV> <KBPS> <DELAY_MS> <LOSS_PERCENT> [QUEUE_KB] [LIMIT_PKTS]
#
# Where:
#   DEV        = network interface (e.g., eno1)
#   KBPS       = bandwidth in kilobytes per second (1 KB = 1024 bytes)
#   DELAY_MS   = one-way delay in milliseconds
#   LOSS       = percentage of packet loss (e.g., 0.5)
#   QUEUE_KB   = (optional) fixed queue size in KB. If not set or zero, it auto-calculates as n*BDP.
#   LIMIT_PKTS = (optional) fixed packet limit. If not set or zero, it auto-calculates as n*BDP.
#
# Example usage:
#   tc_bw_delay_both eno1 10000 50 0.5
#       -> Uses auto-calculated queue & limit based on BDP.
#
#   tc_bw_delay_both eno1 10000 50 0.5 10 200
#       -> Uses a fixed 10KB queue and a fixed packet limit of 200 packets.
#-----------------------------------------------------------------------
function tc_bw_delay_both() {
    local DEV=$1
    local KBPS=$2       # kilobytes per second
    local DELAY_MS=$3
    local LOSS=$4
    local FIXED_QUEUE_KB=$5
    local FIXED_LIMIT_PKTS=$6

    echo ">>> Applying BOTH ingress + egress shaping on $DEV"
    echo "    * target rate=${KBPS}KBps, delay=${DELAY_MS}ms, loss=${LOSS}%"

    # 1) Convert KBPS (kilobytes/s) to bytes/s
    local BYTES_PER_SEC=$(( KBPS * 1024 ))

    # 2) Calculate Bandwidth-Delay Product (BDP) in bytes (one-way delay)
    local BDP_BYTES=$(( BYTES_PER_SEC * DELAY_MS / 1000 ))

    local FACTOR=4
    local QUEUE_KB
    local LIMIT_PKTS

    # Check if a fixed queue size was provided
    if [ -n "$FIXED_QUEUE_KB" ] && [ "$FIXED_QUEUE_KB" -gt 0 ]; then
         QUEUE_KB=$FIXED_QUEUE_KB
         echo "    * Using fixed queue size: ${QUEUE_KB}KB"
    else
         QUEUE_KB=$(( (BDP_BYTES * FACTOR) / 1024 ))
         if [ "$QUEUE_KB" -lt 1 ]; then QUEUE_KB=1; fi
         echo "    * Auto-calculated queue size: ~${QUEUE_KB}KB"
    fi

    # Check if a fixed packet limit was provided
    if [ -n "$FIXED_LIMIT_PKTS" ] && [ "$FIXED_LIMIT_PKTS" -gt 0 ]; then
         LIMIT_PKTS=$FIXED_LIMIT_PKTS
         echo "    * Using fixed packet limit: ${LIMIT_PKTS} packets"
    else
         local AVG_PKT=1250
         LIMIT_PKTS=$(( (BDP_BYTES * FACTOR) / AVG_PKT ))
         if [ "$LIMIT_PKTS" -lt 10 ]; then LIMIT_PKTS=10; fi
         echo "    * Auto-calculated packet limit: ~${LIMIT_PKTS} packets"
    fi

    echo "    * BDP: ${BDP_BYTES} bytes"

    # Apply egress shaping
    tc_egress_with_delay "$QUEUE_KB" "$DEV" "$KBPS" "$DELAY_MS" "$LIMIT_PKTS" "$LOSS" "$BDP_BYTES"

    # Apply ingress shaping
    tc_ingress_with_delay "$QUEUE_KB" "$DEV" "$KBPS" "$DELAY_MS" "$LIMIT_PKTS" "$LOSS" "$BDP_BYTES"
}

#-----------------------------------------------------------------------
# Usage:
#   tc_del_bw_delay_both <DEV>
#
# Example:
#   tc_del_bw_delay_both eno1
#
# This removes egress + ingress shaping on the same interface.
#-----------------------------------------------------------------------
function tc_del_bw_delay_both() {
    DEV=$1
    echo ">>> Removing BOTH ingress + egress shaping on $DEV"

    # Remove egress shaping
    tc_del_egress_with_delay "$DEV"

    # Remove ingress shaping
    tc_del_ingress_with_delay "$DEV"
}

# Finally, run the passed command.
$@


# #!/bin/bash
# #
# # This program is free software: you can redistribute it and/or modify
# # it under the terms of the GNU General Public License as published by
# # the Free Software Foundation, either version 3 of the License, or
# # (at your option) any later version.

# # This program is distributed in the hope that it will be useful,
# # but WITHOUT ANY WARRANTY; without even the implied warranty of
# # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# # GNU General Public License for more details.
# #
# # Author: Gaetano Carlucci

# tc="sudo /sbin/tc"
# modprobe="sudo /sbin/modprobe"
# ip="sudo /sbin/ip"

# # This function disabled the NIC optimizations that interfere with the experiment
# # INPUT PARAMETER
# # 1 : Device interface that receives the traffic: example eth0
# function disabe_nic_opt()
# {
#    DEV=$1
#    echo "Optimization on $DEV disabled"
#    sudo ethtool -K $DEV gro off
#    sudo ethtool -K $DEV tso off
#    sudo ethtool -K $DEV gso off
# }

# # This function applies egress bandwidth control, delay, and optional loss
# # INPUT PARAMETERS:
# # 1 - Bottleneck buffer size in KB (e.g., 30 for 30KB)
# # 2 - Device interface (e.g., eno1)
# # 3 - Bandwidth limit in KBps (e.g., 1250 for ~10MBps)
# # 4 - Delay in ms (e.g., 50 for 50ms)
# # 5 - Netem queue limit in packets (e.g., 1000)
# # 6 - Packet loss percentage (e.g., 0.5 for 0.5%)
# function tc_egress_with_delay() {
#    QUEUE=$1
#    DEV=$2
#    KBPS=$3
#    DELAY=$4
#    LIMIT_PACKETS=$5
#    LOSS=$6
#    BDP_BYTES=$7
#    BRATE=$((KBPS * 8)) # Convert KBps to kbps
#    MTU=1000
#    LIMIT=$((MTU * QUEUE)) # Queue length in bytes

#    echo "Applying egress bandwidth, delay, and loss on $DEV"
#    echo "* Bandwidth: ${BRATE}kbit (${KBPS} KBps)"
#    echo "* Delay: ${DELAY}ms"
#    echo "* Loss: ${LOSS}%"
#    echo "* Netem Queue Limit: ${LIMIT_PACKETS} packets"

#    # Add TBF as root qdisc for bandwidth control
#    $tc qdisc add dev $DEV root handle 1: tbf rate ${BRATE}kbit \
#        minburst $MTU burst $((BDP_BYTES * 10)) limit $LIMIT

#    # Add NetEm as a child qdisc for delay, loss, with packet limit
#    $tc qdisc add dev $DEV parent 1:1 handle 10: netem \
#        delay ${DELAY}ms loss ${LOSS}% limit ${LIMIT_PACKETS}
# }

# # This function removes both egress bandwidth control and delay
# # INPUT PARAMETER: 1 - Device interface (e.g., eno1)
# function tc_del_egress_with_delay() {
#    DEV=$1
#    echo "Removing egress bandwidth, delay, and loss on $DEV"
#    $tc qdisc del dev $DEV root
# }

# # This function introduces link capacity constraints on incoming traffic that comes from an IP address
# # INPUT PARAMETER
# # 1 : IP address of the sender machine: example 192.168.0.10
# # 2 : Bottleneck buffer size in KB (1000 byte): example 30 (30KB)
# # 3 : Device interface that receives the traffic: example eth0
# # 4 : Capacity constraint: example 250 KBps (equivalent to 2Mbps)
# function tc_ingress()
# {
#    SRC=$1
#    QUEUE=$2
#    DEV=$3
#    KBPS=$4 # kilo bytes per seconds
#    BRATE=$((KBPS*8)) #BRATE should be in kbps
#    MTU=1000
#    LIMIT=$((MTU*QUEUE)) #Queue length in bytes

#    echo "TC SHAPER INGRESS ON $HOSTNAME"
#    echo "* rate ${BRATE}kbit ($KBPS kbyte/s)"
#    echo "* ip src: $SRC"
#    echo "* dev $DEV"

#    $modprobe ifb
#    $ip link set  dev ifb1 up
#    $tc qdisc add dev $DEV ingress

#    $tc filter add dev $DEV parent ffff: protocol ip u32 match ip src $SRC flowid 1:1 action mirred egress redirect dev ifb1
#    $tc qdisc add dev ifb1 root handle 1: tbf rate ${BRATE}kbit \
#        minburst $MTU burst $((MTU*10)) limit $LIMIT
# }

# # This function introduces link capacity constraints on incoming traffic
# # INPUT PARAMETER
# # 1 : Bottleneck buffer size in KB (1000 byte): example 30 (30KB)
# # 2 : Device interface that receives the traffic: example eth0
# # 3 : Capacity constraint: example 250 KBps (equivalent to 2Mbps)
# function tc_ingress_all()
# {
#    QUEUE=$1
#    DEV=$2
#    KBPS=$3 # kilo bytes per seconds
#    BRATE=$((KBPS*8)) #BRATE should be in kbps
#    MTU=1000
#    LIMIT=$((MTU*QUEUE)) #Queue length in bytes

#    echo "TC SHAPER INGRESS ON $HOSTNAME"
#    echo "* rate ${BRATE}kbit ($KBPS KB/s)"
#    echo "* dev $DEV"

#    $modprobe ifb
#    $ip link set  dev ifb1 up
#    $tc qdisc add dev $DEV ingress

#    $tc filter add dev $DEV parent ffff: protocol ip u32 match u32 0 0 flowid 1:1 \
#        action mirred egress redirect dev ifb1
#    $tc qdisc add dev ifb1 root handle 1: tbf rate ${BRATE}kbit \
#        minburst $MTU burst $((MTU*10)) limit $LIMIT
# }

# # This function removes the capacity constraint on the incoming traffic
# # INPUT PARAMETER
# # 1 : Device interface that receives the traffic: example eth0
# function tc_del_ingress() {
#    DEV=$1
#    $tc qdisc del dev $DEV ingress 2>/dev/null
#    $tc qdisc del dev ifb1 root 2>/dev/null
#    $ip link set dev ifb1 down
#    echo "Bandwidth constraint ingress turned off on $DEV"
# }

# # This function introduces link capacity constraints on outgoing traffic
# # INPUT PARAMETER
# # 1 : Bottleneck buffer size in KB (1000 byte): example 30 (30KB)
# # 2 : Device interface that sends the traffic: example eth0
# # 3 : Capacity constraint: example 250 KBps (equivalent to 2Mbps)
# function tc_egress() {
#    QUEUE=$1
#    DEV=$2
#    KBPS=$3 # kilo bytes per seconds
#    BRATE=$((KBPS*8)) #BRATE should be in kbps
#    MTU=1000
#    LIMIT=$((MTU*QUEUE)) #Queue length in bytes

#    echo "TC SHAPER EGRESS ON $HOSTNAME"
#    echo "* rate ${BRATE}kbit ($KBPS KB/s)"
#    echo "* dev $DEV"

#    $tc qdisc add dev $DEV root handle 1: tbf rate ${BRATE}kbit \
#        minburst $MTU burst $((MTU*10)) limit $LIMIT
# }

# # This function removes the capacity constraint on the outgoing traffic
# # INPUT PARAMETER
# # 1 : Device interface that sends the traffic: example eth0
# function tc_del_egress() {
#    DEV=$1
#    $tc qdisc del dev $DEV root 2>/dev/null
#    echo "Bandwidth constraint egress turned off on $DEV"
# }

# # This function introduces propagation delay on the traffic over the specified interface
# # INPUT PARAMETER
# # 1 : Device interface that introduces the delay on the traffic: example eth0
# # 2 : Delay we want to set in ms: example 50 ms
# function tc_delay() {
#    DEV=$1
#    DELAY=$2
#    echo "tc_delay: dev: $DEV delay: $DELAY ms"
#    $tc qdisc add dev $DEV root netem delay ${DELAY}ms
# }

# # This function removes propagation delay 
# # INPUT PARAMETER
# # 1 : Device interface that introduces the delay on the traffic: example eth0
# function tc_del_delay()
# {
#    DEV=$1
#    $tc qdisc del dev $DEV root 2>/dev/null
#    echo "Delay turned off on $DEV"
# }

# # This function adds fair queuing policy on incoming traffic 
# # Must be executed after tc_ingress or tc_ingress_all
# function add_sfq_ingress()
# {
#    $tc qdisc add dev ifb1 parent 1:1 handle 10: sfq perturb 10  
# }

# # This function adds fair queuing policy on outgoing traffic 
# # Must be execute after tc_egress
# # INPUT PARAMETER
# # 1 : Device interface 
# function add_sfq_egress()
# {
#    DEV=$1
#    $tc qdisc add dev $DEV parent 1:1 handle 10: sfq perturb 10
# }

# # This function applies INGRESS bandwidth control, delay, and optional loss,
# # similarly to tc_egress_with_delay, but via an ifb device.
# # INPUT PARAMETERS:
# # 1 - Bottleneck buffer size in KB (e.g., 30 for 30KB)
# # 2 - Device interface (e.g., eth0)
# # 3 - Bandwidth limit in KBps (e.g., 1250 for ~10Mb/s)
# # 4 - Delay in ms (e.g., 50 for 50ms)
# # 5 - Netem queue limit in packets (e.g., 1000)
# # 6 - Packet loss percentage (e.g., 0.5 for 0.5%)
# function tc_ingress_with_delay() {
#    QUEUE=$1
#    DEV=$2
#    KBPS=$3
#    DELAY=$4
#    LIMIT_PACKETS=$5
#    LOSS=$6
#    BDP_BYTES=$7
#    BRATE=$((KBPS * 8)) # Convert KBps to kbps
#    MTU=1000
#    LIMIT=$((MTU * QUEUE)) # Queue length in bytes

#    echo "Applying ingress bandwidth + delay + loss on $DEV using ifb1"
#    echo "* Bandwidth: ${BRATE}kbit (${KBPS} KBps)"
#    echo "* Delay: ${DELAY}ms"
#    echo "* Loss: ${LOSS}%"
#    echo "* Netem Queue Limit: ${LIMIT_PACKETS} packets"

#    # 1) Load the ifb module and bring up the ifb1 interface
#    $modprobe ifb
#    $ip link set dev ifb1 up

#    # 2) Attach ingress qdisc on $DEV, and redirect all traffic to ifb1
#    $tc qdisc add dev $DEV ingress
#    $tc filter add dev $DEV parent ffff: protocol ip u32 match u32 0 0 \
#        flowid 1:1 action mirred egress redirect dev ifb1

#    # 3) On ifb1, install TBF as root for bandwidth limiting
#    $tc qdisc add dev ifb1 root handle 1: tbf rate ${BRATE}kbit \
#        minburst $MTU burst $((BDP_BYTES * 10)) limit $LIMIT

#    # 4) Attach netem as a child for delay + loss + queue limit
#    $tc qdisc add dev ifb1 parent 1:1 handle 10: netem \
#        delay ${DELAY}ms loss ${LOSS}% limit ${LIMIT_PACKETS}
# }

# # This function removes both ingress bandwidth control, delay, and loss
# # INPUT PARAMETER:
# # 1 - Device interface (e.g., eth0)
# function tc_del_ingress_with_delay() {
#    DEV=$1
#    echo "Removing ingress bandwidth + delay + loss on $DEV (ifb1)"

#    # 1) Delete root qdisc on ifb1, then bring ifb1 down
#    $tc qdisc del dev ifb1 root 2>/dev/null
#    $ip link set dev ifb1 down

#    # 2) Delete the ingress qdisc on $DEV (which removes the redirect)
#    $tc qdisc del dev $DEV ingress 2>/dev/null
# }


# # Usage:
# #   tc_bw_delay_both <DEV> <KBPS> <DELAY_MS> <LOSS_PERCENT>
# #
# # Where:
# #   DEV       = network interface (e.g., eno1)
# #   KBPS      = bandwidth in kilobytes per second (1 KB = 1024 bytes)
# #   DELAY_MS  = one-way delay in milliseconds
# #   LOSS      = percentage of packet loss (e.g., 0.5)
# #
# # Example usage:
# #   tc_bw_delay_both eno1 10000 50 0.5
# #    -> egress + ingress shaping
# #       - ~10,000 KBps limit (≈ 10 MB/s)
# #       - 50 ms one-way delay
# #       - 0.5% packet loss
# #       - auto-calculated queue & limit
# function tc_bw_delay_both() {
#     local DEV=$1
#     local KBPS=$2       # kilobytes per second
#     local DELAY_MS=$3
#     local LOSS=$4

#     echo ">>> Applying BOTH ingress + egress shaping on $DEV"
#     echo "    * target rate=${KBPS}KBps, delay=${DELAY_MS}ms, loss=${LOSS}%"

#     # 1) Convert KBPS (kilobytes/s) to bytes/s
#     #    For 1 KB = 1024 bytes:
#     local BYTES_PER_SEC=$(( KBPS * 1024 ))

#     # 2) Calculate Bandwidth-Delay Product (BDP) in bytes
#     #    BDP = throughput (bytes/s) * delay (seconds)
#     #    Here we assume one-way delay, not round-trip.
#     local BDP_BYTES=$(( BYTES_PER_SEC * DELAY_MS / 1000 ))

#     # 3) Decide a queue size in KB (multiply BDP by a safety factor)
#     local FACTOR=4
#     local QUEUE_KB=$(( (BDP_BYTES * FACTOR) / 1024 ))
#     if [ "$QUEUE_KB" -lt 1 ]; then
#         QUEUE_KB=1
#     fi

#     # 4) Decide limit in packets by dividing BDP by average packet size (1252 bytes)
#     local AVG_PKT=1250
#     local LIMIT_PKTS=$(( (BDP_BYTES * FACTOR) / AVG_PKT ))
#     if [ "$LIMIT_PKTS" -lt 10 ]; then
#         LIMIT_PKTS=10
#     fi

#     echo "    * auto-calculated queue ~${QUEUE_KB}KB, limit ~${LIMIT_PKTS} pkts"

#     # Apply egress shaping
#     tc_egress_with_delay "$QUEUE_KB" "$DEV" "$KBPS" "$DELAY_MS" "$LIMIT_PKTS" "$LOSS" "$BDP_BYTES"

#     # Apply ingress shaping
#     tc_ingress_with_delay "$QUEUE_KB" "$DEV" "$KBPS" "$DELAY_MS" "$LIMIT_PKTS" "$LOSS" "$BDP_BYTES"
# }


# # Usage:
# #    tc_del_bw_delay_both  <DEV>
# #
# # Example:
# #    tc_del_bw_delay_both eno1
# #
# # This removes egress shaping + ingress shaping on the same interface.
# function tc_del_bw_delay_both() {
#     DEV=$1
#     echo ">>> Removing BOTH ingress + egress shaping on $DEV"

#     # Remove egress shaping
#     tc_del_egress_with_delay "$DEV"

#     # Remove ingress shaping
#     tc_del_ingress_with_delay "$DEV"
# }

# # Finally, run the passed command.
# $@
