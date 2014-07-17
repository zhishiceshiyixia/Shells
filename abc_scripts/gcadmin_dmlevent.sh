#!/bin/bash
number=0
while [ 1 ]
	do
	echo "#######################gcadmin showdmlevent###############################" >>/tmp/abc/chk/old/tmp/node-monitor/gcadmin_dmlevent.txt
	echo "#######################gcadmin showdmlevent###############################" >>/tmp/abc/chk/old/tmp/node-monitor/gcadmin_dmlevent.txt
	date +%Y"-"%m"-"%d" "%H":"%M":"%S >>/tmp/abc/chk/old/tmp/node-monitor/gcadmin_dmlevent.txt
	gcadmin showdmlevent>>/tmp/abc/chk/old/tmp/node-monitor/gcadmin_dmlevent.txt
	sleep 100
	if [ $number -gt 36 ];then
		number=0
		echo > /tmp/abc/chk/old/tmp/node-monitor/gcadmin_dmlevent.txt
	fi
	number=`expr $number + 1`
done
