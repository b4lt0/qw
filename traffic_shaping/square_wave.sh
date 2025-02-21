#!/bin/bash
set -e

#tc_bw_delay_both <DEV> <KBPS> <DELAY_MS> <LOSS_PERCENT> [QUEUE_KB] [LIMIT_PKTS]

# start low
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
  "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_bw_delay_both eno1 1024 10 0 80 67"
echo "Low bw started"

# Start local HTTP client (50MB file) in background
echo -n "Starting local hq client for /largefile50M.bin... "
start=$(date +%s)
/qw/proxygen/proxygen/_build/proxygen/httpserver/hq \
    --mode=client \
    --host=10.73.0.20 \
    --outdir=/qw/client \
    --path="/largefile50M.bin" \
    -qlogger_path=/qw/client/logs/ \
    -stream_flow_control=2147483647 > /dev/null 2>&1 &
HQ50_PID=$!
echo "done."

sleep 8

#kill low
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
  "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_del_bw_delay_both eno1"
echo "Low bw end"

#start high
end=$(date +%s)
elapsed=$((end - start))
echo "$elapsed s"
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
  "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_bw_delay_both eno1 2048 10 0 80 67"
echo "High bw started"

sleep 8

#kill high
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
  "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_del_bw_delay_both eno1"
echo "High bw end"


#start low
end=$(date +%s)
elapsed=$((end - start))
echo "$elapsed s"
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
  "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_bw_delay_both eno1 1024 10 0 80 67"
echo "Low bw started"

sleep 8

# kill low
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
  "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_del_bw_delay_both eno1"
echo "Low bw end"

#start high
end=$(date +%s)
elapsed=$((end - start))
echo "$elapsed s"
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
  "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_bw_delay_both eno1 2048 10 0 80 67"
echo "High bw started"


echo -n "Waiting for local hq client to complete... "
wait ${HQ50_PID}
echo "Local hq client transfer completed."


#kill high
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 \
  "sudo /home/balillus/qw/traffic_shaping/wan_emulation.sh tc_del_bw_delay_both eno1"
echo "High bw end"

exit 0
