#! /bin/bash
number=0
while true
do
date  >>  /tmp/abc/chk/old/tmp/node-monitor/gcadmin.txt
gcadmin >>  /tmp/abc/chk/old/tmp/node-monitor/gcadmin.txt
sleep 10
number=`expr $number + 1`
if test $number -gt 2500
then
        number=0
        echo "clean file" >  /tmp/abc/chk/old/tmp/node-monitor/gcadmin.txt
fi
done
