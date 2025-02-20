#!/bin/bash
#
# File: /qw/traffic_shaping/reverse_traffic.sh
#
# This script:
#  1. Opens an SSH connection to 10.73.0.20 and starts a Docker container.
#  2. Starts a local HTTP client to request a 50MB file.
#  3. After 5 seconds, starts a remote HTTP client (first run) inside the Docker
#     container to request a 50MB file.
#  4. After 5 seconds, terminates the first remote client.
#  5. Sleeps 5 seconds and repeats the 50MB request (second run) inside the Docker
#     container.
#  6. After 5 seconds, terminates the second remote client.
#  7. Waits for the local 50MB transfer to finish.
#
# Note: Ensure SSH key-based authentication is set up and that the local /tmp/logs
#       directory exists (or adjust the paths as needed).

set -e  # Exit immediately if a command fails

# Phase 1: Start Docker container on remote host and capture container ID
echo -n "Starting Docker container on remote host... "
container_id=$(ssh -tt -o StrictHostKeyChecking=no balillus@10.73.0.20 "sudo docker run -d -it --net host --privileged -v /home/balillus/qw:/qw/ quic-westwood" | tr -d '\r\n')
echo "done. Container ID:$container_id"

# Phase 2: Start local hq client for /largefile50M.bin (background)
echo -n "Starting local hq client for /largefile50M.bin... "
/qw/proxygen/proxygen/_build/proxygen/httpserver/hq \
    --mode=client \
    --host=10.73.0.20 \
    --outdir=/qw/client \
    --path="/largefile50M.bin" \
    -qlogger_path=/qw/client/logs/ \
    -stream_flow_control=2147483647 > /dev/null 2>&1 &
HQ50_PID=$!
echo "done."

# Phase 3: Sleep 5 seconds
echo -n "Sleeping 4s... "
sleep 4
echo "done."

# Phase 4: Start remote hq client (first run) inside the Docker container
echo -n "Requesting /largefile10M.bin from Docker container on 10.73.0.20 (first run)... "
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 "sudo docker exec ${container_id} /qw/proxygen/proxygen/_build/proxygen/httpserver/hq \
  --mode=client \
  --host=10.73.0.160 \
  --outdir=/qw/client \
  --path='/largefile10M.bin' \
  -qlogger_path=/qw/client/logs/ \
  -stream_flow_control=2147483647 > /tmp/hqclient_first.log"
echo "done."

# Phase 5: Sleep 5 seconds
echo -n "Sleeping 4s... "
sleep 4
echo "done."

# # Phase 6: Terminate first remote request inside the Docker container
# REMOTE_PID_FIRST=$(ssh -tt -o StrictHostKeyChecking=no balillus@10.73.0.20 "sudo docker exec -it $container_id cat /tmp/hq10m_pid_first" | tr -d '[:space:]')
# echo -n "Terminating first remote request (PID: ${REMOTE_PID_FIRST})... "
# ssh -tt -o StrictHostKeyChecking=no balillus@10.73.0.20 "sudo docker exec -it $container_id sh -c 'kill ${REMOTE_PID_FIRST} || true; rm /tmp/hq10m_pid_first'"
# echo "done."

# # Phase 7: Sleep 5 seconds
# echo -n "Sleeping 4s... "
# sleep 4
# echo "done."

# Phase 8: Start remote hq client (second run) inside the Docker container
echo -n "Requesting /largefile50M.bin from Docker container on 10.73.0.20 (second run)... "
ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 "sudo docker exec ${container_id} /qw/proxygen/proxygen/_build/proxygen/httpserver/hq \
  --mode=client \
  --host=10.73.0.160 \
  --outdir=/qw/client \
  --path='/largefile10M.bin' \
  -qlogger_path=/qw/client/logs/ \
  -stream_flow_control=2147483647 > /tmp/hqclient_second.log"
echo "done."

# # Phase 9: Sleep 5 seconds
# echo -n "Sleeping 5s... "
# sleep 4
# echo "done."

# # Phase 10: Terminate second remote request inside the Docker container
# REMOTE_PID_SECOND=$(ssh -tt -o StrictHostKeyChecking=no balillus@10.73.0.20 "sudo docker exec -it $container_id cat /tmp/hq10m_pid_second" | tr -d '[:space:]')
# echo -n "Terminating second remote request (PID: ${REMOTE_PID_SECOND})... "
# ssh -tt -o StrictHostKeyChecking=no balillus@10.73.0.20 "sudo docker exec -it $container_id sh -c 'kill ${REMOTE_PID_SECOND} || true; rm /tmp/hq10m_pid_second'"
# echo "done."

ssh -o StrictHostKeyChecking=no balillus@10.73.0.20 "sudo docker kill ${container_id}"

# Phase 11: Wait for local hq client to complete
echo -n "Waiting for local hq client to complete... "
wait ${HQ50_PID}
echo "done."

exit 0

