#! /bin/bash
number=0
logfile=/tmp/abc/chk/old/tmp/node-monitor/data/dfmonitor/$HOSTNAME.df.txt
while true
do
date >> $logfile
du -hs /opt/gnode/tmpdata >> $logfile
df -h /opt >> $logfile
sleep 600 
number=`expr $number + 1`
if test $number -gt 1000
then
        number=0
        echo "clean file" > $logfile
fi
done
