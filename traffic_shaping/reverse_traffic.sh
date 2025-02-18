#!/bin/bash
#
# File: /qw/traffic_shaping/traffic_shaping.sh
#
# This script:
#  1. Opens an SSH connection to 10.73.0.20 (binding local IP 10.73.0.160)
#  2. Changes directory to "qw" on the remote host and starts a Docker container
#     using quic-westwood.
#  3. From the local machine, runs an HTTP client (hq) connecting to 10.73.0.20 to
#     request a 50MB file (runs in background until complete).
#  4. After 5 seconds, on the remote host, it starts an hq client to request a 10MB file
#     (backgrounded) and, after 5 seconds, kills that remote process.
#  5. Sleeps 5 seconds and repeats step 4 (second run).
#  6. Finally, it waits for the local 50MB transfer to finish and then stops the remote
#     Docker container.
#
# Note: The Docker run command is modified to run in detached mode (-d) while still
#       allocating a TTY (-it) so that subsequent remote commands (steps 4-8) can be run
#       via additional SSH sessions.
#
# Make sure that SSH key-based authentication is set up for user "balillus" on 10.73.0.20.
#

set -e  # Exit immediately if a command exits with a non-zero status

#------------------------------#
# Step 1 & 2: Start Docker Container on Remote Host
#------------------------------#
echo "Starting Docker container on remote host..."
ssh -tt -b 10.73.0.160 balillus@10.73.0.20 "sudo docker run -d -it --net host --privileged -v /home/balillus/qw:/qw/ quic-westwood" \
    || { echo "ERROR: Failed to start Docker container on remote host."; exit 1; }
echo "Docker container started on remote host."

#------------------------------#
# Step 3: Start local hq client for largefile50M.bin in background
#------------------------------#
echo "Starting local hq client for /largefile50M.bin..."
/qw/proxygen/proxygen/_build/proxygen/httpserver/hq \
    --mode=client \
    --host=10.73.0.20 \
    --outdir=/qw/client \
    --path="/largefile50M.bin" \
    -qlogger_path=/qw/client/logs/ \
    -stream_flow_control=2147483647 &
HQ50_PID=$!
echo "Local hq client started (PID: $HQ50_PID)."

#------------------------------#
# Step 4: After 5 seconds, start remote hq client for largefile10M.bin (first run)
#------------------------------#
sleep 5
echo "Starting remote hq client (first run) for /largefile10M.bin..."
ssh -b 10.73.0.160 balillus@10.73.0.20 \
  "cd qw && /qw/proxygen/proxygen/_build/proxygen/httpserver/hq \
     --mode=client \
     --host=10.73.0.160 \
     --outdir=/qw/client \
     --path=\"/largefile10M.bin\" \
     -qlogger_path=/qw/client/logs/ \
     -stream_flow_control=2147483647 & echo \$! > /tmp/hq10m_pid_first" \
  || { echo "ERROR: Failed to start remote hq client (first run)."; exit 1; }
echo "Remote hq client (first run) started."

#------------------------------#
# Step 5: After 5 seconds, kill the remote hq client (first run)
#------------------------------#
sleep 5
REMOTE_PID_FIRST=$(ssh -b 10.73.0.160 balillus@10.73.0.20 "cat /tmp/hq10m_pid_first")
echo "Killing remote hq client (first run) with PID: $REMOTE_PID_FIRST..."
ssh -b 10.73.0.160 balillus@10.73.0.20 "kill $REMOTE_PID_FIRST && rm /tmp/hq10m_pid_first" \
  || { echo "ERROR: Failed to kill remote hq client (first run)."; exit 1; }
echo "Remote hq client (first run) killed."

#------------------------------#
# Step 6: Sleep 5 seconds
#------------------------------#
sleep 5

#------------------------------#
# Step 7: Start remote hq client for largefile10M.bin (second run)
#------------------------------#
echo "Starting remote hq client (second run) for /largefile10M.bin..."
ssh -b 10.73.0.160 balillus@10.73.0.20 \
  "cd qw && /qw/proxygen/proxygen/_build/proxygen/httpserver/hq \
     --mode=client \
     --host=10.73.0.160 \
     --outdir=/qw/client \
     --path=\"/largefile10M.bin\" \
     -qlogger_path=/qw/client/logs/ \
     -stream_flow_control=2147483647 & echo \$! > /tmp/hq10m_pid_second" \
  || { echo "ERROR: Failed to start remote hq client (second run)."; exit 1; }
echo "Remote hq client (second run) started."

#------------------------------#
# Step 8: After 5 seconds, kill the remote hq client (second run)
#------------------------------#
sleep 5
REMOTE_PID_SECOND=$(ssh -b 10.73.0.160 balillus@10.73.0.20 "cat /tmp/hq10m_pid_second")
echo "Killing remote hq client (second run) with PID: $REMOTE_PID_SECOND..."
ssh -b 10.73.0.160 balillus@10.73.0.20 "kill $REMOTE_PID_SECOND && rm /tmp/hq10m_pid_second" \
  || { echo "ERROR: Failed to kill remote hq client (second run)."; exit 1; }
echo "Remote hq client (second run) killed."

#------------------------------#
# Step 9: Wait for the local hq client (first connection) to finish
#------------------------------#
echo "Waiting for local hq client (/largefile50M.bin) to complete..."
wait $HQ50_PID
echo "Local hq client finished."

# # Cleanup: Stop the remote Docker container
# echo "Stopping Docker container on remote host..."
# ssh -b 10.73.0.160 balillus@10.73.0.20 \
#   "sudo docker stop \$(sudo docker ps -q --filter ancestor=quic-westwood)" \
#   || { echo "ERROR: Failed to stop Docker container on remote host."; exit 1; }
# echo "Docker container stopped on remote host."

exit 0
