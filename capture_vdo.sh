#!/bin/bash +x

now=`date +%T`
raspivid -t $1 -o "videos/tello-$now.mp4" &

echo "capturing video for $1 milliseconds at $now"
