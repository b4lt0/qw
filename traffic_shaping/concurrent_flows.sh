#!/bin/bash
# Usage: ./start_flows.sh -p <base_port> [-owd]
# If -owd is provided, the script will add --use_ack_receive_timestamps=true to each command.

# Default base port
BASE_PORT=50000
USE_ACK=""

# Parse command line arguments.
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p)
      shift
      if [[ $# -gt 0 ]]; then
        BASE_PORT=$1
      else
        echo "Error: -p requires a port number."
        exit 1
      fi
      ;;
    -owd)
      USE_ACK=" --use_ack_receive_timestamps=true"
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

# Array of file sizes (in MB) for each flow.
filesizes=(100 80 60 40)

# Number of flows to start.
NUM_FLOWS=4

for ((i=0; i<NUM_FLOWS; i++)); do
    CURRENT_PORT=$((BASE_PORT + i))
    FILESIZE=${filesizes[$i]}
    
    # Construct the full command with updated file path based on the file size.
    FULL_CMD="/qw/proxygen/proxygen/_build/proxygen/httpserver/hq \
    --mode=client \
    --host=10.73.0.20 \
    --outdir=/qw/client \
    --path=\"/largefile${FILESIZE}M.bin\" \
    -qlogger_path=/qw/client/logs/ \
    -stream_flow_control=2147483647$USE_ACK \
    -local_address=0.0.0.0:$CURRENT_PORT"
    
    echo "Starting flow $((i+1)) on local port $CURRENT_PORT with file size ${FILESIZE}M"
    echo "Running: $FULL_CMD"
    # Start the flow in the background.
    eval "$FULL_CMD" &
    # Wait 10 seconds before starting the next flow.
    sleep 10
done

echo "All flows have been started. Waiting for them to finish..."
wait
echo "All flows have finished."