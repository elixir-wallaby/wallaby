#!/usr/bin/env bash

script_status="running"

# Start the program in the background
exec "$@" &
pid1=$!

echo "PID: $pid1"

shutdown(){
    local pid1=$1
    local pid2=$1

    if [ $script_status = "running" ]; then
        script_status="shutting down"
        wait $pid1
        ret=$?
        kill -KILL $pid2
        exit $ret
    fi
}

# Silence warnings from here on
exec >/dev/null 2>&1

# Read from stdin in the background and
# kill running program when stdin closes
exec 0<&0 "$(
    while read -r; do :; done
    kill -KILL $pid1
)" &
pid2=$!

# Clean up
trap 'shutdown $pid1 $pid2' INT HUP TERM
shutdown $pid1 $pid2
