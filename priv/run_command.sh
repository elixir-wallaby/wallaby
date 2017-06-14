#!/bin/sh
"$@" &
pid=$!
while read line ; do
  :
done
pgid=$(ps xao pid,pgid | grep $pid | awk '{print $2}')
kill -9 -$pgid
