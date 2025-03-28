#!/bin/bash

# Check if the number of connections is provided as an argument.
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <number_of_connections>"
    exit 1
fi

num_connections="$1"

for (( i=1; i<=num_connections; i++ ))
do
    # Start the connection in the background.
    /qw/proxygen/proxygen/_build/proxygen/httpserver/hq \
        --mode=client \
        --host=10.73.0.20 \
        --outdir=/qw/client \
        --path='/largefile200M.bin' \
        -qlogger_path=/qw/client/logs/ \
        -stream_flow_control=2147483647 &
    
    echo "Started connection $i"
    
    # Sleep for 10 seconds before starting the next connection, except after the last one.
    if [ $i -lt $num_connections ]; then
        sleep 10
    fi
done

# Wait for all background processes to complete before exiting.
wait

