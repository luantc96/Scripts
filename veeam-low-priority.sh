#!/bin/bash
for pid in $(pgrep -f veeam); do
  renice -n 19 -p $pid
  ionice -c3 -p $pid
done