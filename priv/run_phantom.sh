#!/usr/bin/env sh
phantomjs $@ &
DRIVER=$!
read CMD
kill $DRIVER
