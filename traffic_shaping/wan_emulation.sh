#!/bin/bash
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#Author: Gaetano Carlucci

tc="sudo /sbin/tc"
modprobe="sudo /sbin/modprobe"
ip="sudo /sbin/ip"

# This function disabled the NIC optimizations that interfere with the experiment
# INPUT PARAMETER
# 1 : Device interface that receives the traffic: example eth0
function disabe_nic_opt()
{
   DEV=$1
   echo "Optimization on $DEV disabled"
   sudo ethtool -K $DEV gro off
   sudo ethtool -K $DEV tso off
   sudo ethtool -K $DEV gso off
}

# This function applies egress bandwidth control and delay
# INPUT PARAMETERS:
# 1 - Bottleneck buffer size in KB (e.g., 30 for 30KB)
# 2 - Device interface (e.g., eno1)
# 3 - Bandwidth limit in KBps (e.g., 1250 for 10MBps)
# 4 - Delay in ms (e.g., 50 for 50ms)
function tc_egress_with_delay() {
   QUEUE=$1
   DEV=$2
   KBPS=$3
   DELAY=$4
   LIMIT_PACKETS=$5  # New parameter for packet limit in netem queue
   BRATE=$((KBPS * 8)) # Convert KBps to kbps
   MTU=1000
   LIMIT=$((MTU * QUEUE)) # Queue length in bytes

   echo "Applying egress bandwidth and delay on $DEV"
   echo "* Bandwidth: ${BRATE}kbit (${KBPS} KBps)"
   echo "* Delay: ${DELAY}ms"
   echo "* Netem Queue Limit: ${LIMIT_PACKETS} packets"

   # Add TBF as root qdisc for bandwidth control
   $tc qdisc add dev $DEV root handle 1: tbf rate ${BRATE}kbit minburst $MTU burst $((MTU * 10)) limit $LIMIT

   # Add NetEm as a child qdisc for delay with packet limit
   $tc qdisc add dev $DEV parent 1:1 handle 10: netem delay ${DELAY}ms limit ${LIMIT_PACKETS}
}

# This function removes both egress bandwidth control and delay
# INPUT PARAMETER: 1 - Device interface (e.g., eno1)
function tc_del_egress_with_delay() {
   DEV=$1
   echo "Removing egress bandwidth and delay on $DEV"
   $tc qdisc del dev $DEV root
}

# This function introduces link capacity constraints on incoming traffic that comes from an IP address
# INPUT PARAMETER
# 1 : IP address of the sender machine: example 192.168.0.10
# 2 : Bottleneck buffer size in KB (1000 byte): example 30 (30KB)
# 3 : Device interface that receives the traffic: example eth0
# 4 : Capacity constraint: example 250 KBps (equivalent to 2Mbps)
function tc_ingress()
{
   SRC=$1
   QUEUE=$2
   DEV=$3
   KBPS=$4 # kilo bytes per seconds
   BRATE=$[$KBPS*8] #BRATE should be in kbps
   MTU=1000
   
   LIMIT=$[$MTU*$QUEUE] #Queue length in bytes
	
	
   echo "TC SHAPER INGRESS ON $HOSTNAME"
   echo "* rate ${BRATE}kbit ($RATE kbyte)"
   echo "* ip src: $SRC"
   echo "* dev $DEV"

   $modprobe ifb
   $ip link set  dev ifb1 up
   $tc qdisc add dev $DEV ingress
	    
   $tc filter add dev $DEV parent ffff: protocol ip u32 match ip src $SRC flowid 1:1 action mirred egress redirect dev ifb1
   $tc qdisc add dev ifb1 root handle 1: tbf rate ${BRATE}kbit minburst $MTU burst $[$MTU*10] limit $LIMIT
}

# This function introduces link capacity constraints on incoming traffic
# INPUT PARAMETER
# 1 : Bottleneck buffer size in KB (1000 byte): example 30 (30KB)
# 2 : Device interface that receives the traffic: example eth0
# 3 : Capacity constraint: example 250 KBps (equivalent to 2Mbps)
function tc_ingress_all()
{
   QUEUE=$1
   DEV=$2
   KBPS=$3 # kilo bytes per seconds
   BRATE=$[$KBPS*8] #BRATE should be in kbps
   MTU=1000
  
   LIMIT=$[$MTU*$QUEUE] #Queue length in bytes
  
  
   echo "TC SHAPER INGRESS ON $HOSTNAME"
   echo "* rate ${BRATE}kbit ($RATE kbyte)"
   echo "* dev $DEV"

   $modprobe ifb
   $ip link set  dev ifb1 up
   $tc qdisc add dev $DEV ingress
      
   $tc filter add dev $DEV parent ffff: protocol ip u32 match u32 0 0 flowid 1:1 action mirred egress redirect dev ifb1
   $tc qdisc add dev ifb1 root handle 1: tbf rate ${BRATE}kbit minburst $MTU burst $[$MTU*10] limit $LIMIT
}

# This function removes the capacity constraint on the incoming traffic
# INPUT PARAMETER
# 1 : Device interface that receives the traffic: example eth0
function tc_del_ingress() {
   DEV=$1
   $tc qdisc del dev $DEV ingress
   $tc qdisc del dev ifb1 root
   $ip link  set dev ifb1 down
   echo "Bandwidth constraint ingress turned off on $DEV"
}

# This function introduces link capacity constraints on outgoing traffic
# INPUT PARAMETER
# 1 : Bottleneck buffer size in KB (1000 byte): example 30 (30KB)
# 2 : Device interface that sends the traffic: example eth0
# 3 : Capacity constraint: example 250 KBps (equivalent to 2Mbps)
function tc_egress() {
   QUEUE=$1
   DEV=$2
   KBPS=$3 # kilo bytes per seconds
   BRATE=$[$KBPS*8] #BRATE should be in kbps
   MTU=1000
   LIMIT=$[$MTU*$QUEUE] #Queue length in bytes
  
   echo "TC SHAPER EGREES ON $HOSTNAME"
   echo "* rate ${BRATE}kbit ($RATE kbyte)"
   echo "* dev $DEV"

   $tc qdisc add dev $DEV root handle 1: tbf rate ${BRATE}kbit minburst $MTU burst $[$MTU*10] limit $LIMIT
}

# This function removes the capacity constraint on the outgoing traffic
# INPUT PARAMETER
# 1 : Device interface that sends the traffic: example eth0
function tc_del_egress() {
   DEV=$1
   $tc qdisc del dev $DEV root
   echo "Bandwidth constraint egress turned off on $DEV"
}
  
# This function introduces propagation delay on the traffic over the specified interface (this cannot be done on the same machine that sets the capacity constraint)
# INPUT PARAMETER
# 1 : Device interface that introduces the delay on the traffic: example eth0
# 2 : Delay we want to set in ms: example 50 ms
function tc_delay() {
   DEV=$1
   DELAY=$2
   echo "tc_delay: dev: $DEV delay: $DELAY ms"
   $tc qdisc add dev $DEV root netem delay ${DELAY}ms
}

# This function removes propagation delay 
# INPUT PARAMETER
# 1 : Device interface that introduces the delay on the traffic: example eth0
function tc_del_delay()
{
   DEV=$1
   $tc qdisc del dev $DEV root
   echo "Delay turned off on $DEV"
}


# This function adds fair queuing policy on incoming traffic 
# This function must be execute after function tc_ingress/tc_ingress_all
function add_sfq_ingress()
{
   $tc qdisc add dev ifb1 parent 1:1 handle 10: sfq perturb 10  
}


# This function adds fair queuing policy on outgoing traffic 
# This function must be execute after function tc_egress
# INPUT PARAMETER
# 1 : Device interface 
function add_sfq_egress()
{
   DEV=$1
   $tc qdisc add dev $DEV parent 1:1 handle 10: sfq perturb 10
}

# This function applies INGRESS bandwidth control and delay,
# similarly to tc_egress_with_delay, but uses an ifb device.
# INPUT PARAMETERS:
# 1 - Bottleneck buffer size in KB (e.g., 30 for 30KB)
# 2 - Device interface (e.g., eth0)
# 3 - Bandwidth limit in KBps (e.g., 1250 for ~10Mb/s)
# 4 - Delay in ms (e.g., 50 for 50ms)
function tc_ingress_with_delay() {
   QUEUE=$1
   DEV=$2
   KBPS=$3
   DELAY=$4
   LIMIT_PACKETS=$5  # New parameter for packet limit in netem queue
   BRATE=$((KBPS * 8)) # Convert KBps to kbps
   MTU=1000
   LIMIT=$((MTU * QUEUE)) # Queue length in bytes

   echo "Applying ingress bandwidth + delay on $DEV using ifb1"
   echo "* Bandwidth: ${BRATE}kbit (${KBPS} KBps)"
   echo "* Delay: ${DELAY}ms"
   echo "* Netem Queue Limit: ${LIMIT_PACKETS} packets"

   # 1) Load the ifb module and bring up the ifb1 interface
   $modprobe ifb
   $ip link set dev ifb1 up

   # 2) Attach ingress qdisc on $DEV, and redirect all traffic to ifb1
   $tc qdisc add dev $DEV ingress
   $tc filter add dev $DEV parent ffff: protocol ip u32 match u32 0 0 \
       flowid 1:1 action mirred egress redirect dev ifb1

   # 3) On ifb1, install TBF as root for bandwidth limiting...
   $tc qdisc add dev ifb1 root handle 1: tbf rate ${BRATE}kbit \
       minburst $MTU burst $((MTU * 10)) limit $LIMIT

   # 4) ...then attach netem as a child for delay with packet limit
   $tc qdisc add dev ifb1 parent 1:1 handle 10: netem delay ${DELAY}ms limit ${LIMIT_PACKETS}
}


# This function removes both ingress bandwidth control and delay
# INPUT PARAMETER:
# 1 - Device interface (e.g., eth0)
function tc_del_ingress_with_delay() {
   DEV=$1
   echo "Removing ingress bandwidth + delay on $DEV (ifb1)"

   # 1) Delete root qdisc on ifb1, then bring ifb1 down
   $tc qdisc del dev ifb1 root 2>/dev/null
   $ip link set dev ifb1 down

   # 2) Delete the ingress qdisc on $DEV (which removes the redirect)
   $tc qdisc del dev $DEV ingress 2>/dev/null
}

# Usage:
#    tc_bw_delay_both  <QUEUE> <DEV> <KBPS> <DELAY_MS>
#
# Example:  tc_bw_delay_both  30  eno1  1250  50
#   -> This applies:
#      - egress shaping of ~10Mb/s (1250 KBps) + 50ms on eno1
#      - ingress shaping of ~10Mb/s (1250 KBps) + 50ms on eno1
#
function tc_bw_delay_both() {
    QUEUE=$1         # Bottleneck buffer size in KB
    DEV=$2           # Network interface (e.g., eth0, eno1)
    KBPS=$3          # Bandwidth limit in KB/s
    DELAY=$4         # Delay in ms
    LIMIT_PACKETS=$5 # New parameter for netem queue limit in packets

    echo ">>> Applying BOTH ingress + egress shaping on $DEV"
    echo "    * queue=${QUEUE}KB, bw=${KBPS}KBps, delay=${DELAY}ms, limit=${LIMIT_PACKETS} packets"

    # Call modified egress function
    tc_egress_with_delay "$QUEUE" "$DEV" "$KBPS" "$DELAY" "$LIMIT_PACKETS"

    # Call modified ingress function
    tc_ingress_with_delay "$QUEUE" "$DEV" "$KBPS" "$DELAY" "$LIMIT_PACKETS"
}

# Usage:
#    tc_del_bw_delay_both  <DEV>
#
# Example:  tc_del_bw_delay_both  eno1
#
# This removes egress shaping + ingress shaping on the same interface.
#
function tc_del_bw_delay_both() {
    DEV=$1
    echo ">>> Removing BOTH ingress + egress shaping on $DEV"

    # Remove egress shaping
    tc_del_egress_with_delay "$DEV"

    # Remove ingress shaping
    tc_del_ingress_with_delay "$DEV"
}



$@
