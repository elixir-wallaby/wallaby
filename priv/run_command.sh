#!/bin/sh
"$@" &
pid=$!
while read line ; do
  :
done
kill -TERM $pid
