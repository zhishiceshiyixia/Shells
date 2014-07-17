#! /bin/bash
WORKPATH="/tmp/abc/chk/old/tmp/node-monitor/data/nmon"
cd ${WORKPATH}
number=0 
while true
do
echo ----------------------------------------------------------------------- >>  ${WORKPATH}/nmon.log
date >> ${WORKPATH}/nmon.log
echo start $number nmon >>  ${WORKPATH}/nmon.log
filename=$HOSTNAME.`date +%F.%T`.nmon
nmon -F"${WORKPATH}/$filename" -s40 -c1080
#nmon -F"${WORKPATH}/$filename" -s10 -c1
sleep 43250
chmod 777  ${WORKPATH}/$HOSTNAME*.nmon
#mv ${WORKPATH}/$filename ${WORKPATH}/data/history

number=`expr $number + 1`

if test $number -gt 6
then
        number=0
	#tar cvfz nmon.`date +%F`.tar HQxP*.nmon
	mv $HOSTNAME.*.nmon history
        echo "clean file" >  ${WORKPATH}/nmon.log
        #rm -f HQxP*.nmon
	echo ----------------------------------------------------------------------- >>  ${WORKPATH}/nmon.log
fi
done
exit
