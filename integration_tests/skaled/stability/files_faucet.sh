#!/bin/bash

N=1000
pack=0

while true
do
  for dir in $@
  do
    for (( i=1; i<=$N; i++ ))
    do
      echo "$i" >$dir/$((pack + i)).gfn
    done
  done
  pack=$((pack + N))
  echo $pack
  sleep 10
done
