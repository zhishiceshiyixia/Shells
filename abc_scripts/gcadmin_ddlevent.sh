#!/bin/bash
number=0
while [ 1 ]
	do
	echo "#######################gcadmin showddlevent###############################" >>/tmp/abc/chk/old/tmp/node-monitor/gcadmin_ddlevent.txt
	echo "#######################gcadmin showddlevent###############################" >>/tmp/abc/chk/old/tmp/node-monitor/gcadmin_ddlevent.txt
	date +%Y"-"%m"-"%d" "%H":"%M":"%S >>/tmp/abc/chk/old/tmp/node-monitor/gcadmin_ddlevent.txt
	gcadmin showddlevent >>/tmp/abc/chk/old/tmp/node-monitor/gcadmin_ddlevent.txt
	sleep 100
	if [ $number -gt 36 ];then
		number=0
		echo > /tmp/abc/chk/old/tmp/node-monitor/gcadmin_ddlevent.txt
	fi
	number=`expr $number + 1`
done
