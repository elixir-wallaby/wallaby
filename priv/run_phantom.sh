#!/usr/bin/env sh
$@ &
DRIVER=$!
read CMD
kill $DRIVER
