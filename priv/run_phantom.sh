#!/bin/sh

#
# Wrapper script to start an external program and terminate it when it either
# receives a SIGINT, SIGHUP, or SIGTERM or when STDIN closes. This script also
# waits until all child processes have exited before exiting, so when the script
# ends, we can be sure all started programs have finished.
#

set -e

script_status="running"

create_pipe(){
  local pipe=$(mktemp -u)
  mkfifo -m 600 "$pipe"
  echo $pipe
}

remove_pipe(){
  rm -f $1
}

wait_for_stdin_close(){
  while read line ; do
    :
  done
}

wait_for_pids_to_exit(){
  pids="$@"

  for pid in $pids; do
    while kill -0 $pid 2>/dev/null; do
      sleep 0.1
    done
  done
}

shutdown(){
  local my_pid=$1
  local program_pid=$2

  if [ $script_status = "running" ]; then
    script_status="shutting down"

    # Kill this script's process group
    kill -TERM $(($my_pid * -1)) 2>/dev/null
  fi

  exit 0
}

# Start the program in a subshell so we can wait until it ends and then kill
# this wrapper script. In order to communicate the pid up to the parent process
# we need to use a fifo pipe.
my_pid=$$
pid_pipe=$(create_pipe)
trap 'remove_pipe "$pid_pipe"' EXIT
(
  "$@" &
  echo $! >> $pid_pipe
  wait 2>/dev/null
  kill $my_pid
) &
read program_pid < "$pid_pipe"
echo "PID: $program_pid"
trap 'shutdown $my_pid $program_pid' INT HUP TERM
remove_pipe $pid_pipe

# Start shutdown process if stdin is closed
wait_for_stdin_close
shutdown $my_pid $program_pid
