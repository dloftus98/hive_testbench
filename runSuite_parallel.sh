#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
        echo "** Trapped CTRL-C"
        echo "kill $pids"
	kill $pids
	exit
}

prefix=$1
parallel=$2
scale=$3

echo "Logging to runSuite.log as well as console"
date >>runSuite.log
echo "prefix,filename,status,time,rows" >>runSuite.log

for i in $(eval echo {1..$parallel}); do
   echo "./runSuite_single.pl $scale $prefix$i noheader &"
   ./runSuite_single.pl $scale $prefix$i noheader | tee -a runSuite.log &
   pids="$pids  $!"
done

echo waiting on $pids

wait $pids

