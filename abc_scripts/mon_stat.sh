#! /bin/bash
WORKPATH="/tmp/abc/chk/old/tmp/node-monitor/data/stat"
echo "start monitor" > ${WORKPATH}/${HOSTNAME}.stat.txt
chmod 666  ${WORKPATH}/${HOSTNAME}.stat.txt
number=0 
while true
do
echo ----------------------------------------------------------------------- >>  ${WORKPATH}/${HOSTNAME}.stat.txt
sleep 60
date >>  ${WORKPATH}/${HOSTNAME}.stat.txt
iostat -N vggbase-lv_opt vgsystem-lv_tmp vgsystem-lv_root -m 1 3 >>  ${WORKPATH}/${HOSTNAME}.stat.txt
top -b -n 1 | head -20 >>  ${WORKPATH}/${HOSTNAME}.stat.txt

number=`expr $number + 1`

if test $number -gt 25000
then
        number=0
        echo "clean file" >  ${WORKPATH}/${HOSTNAME}.stat.txt
fi

done
exit
