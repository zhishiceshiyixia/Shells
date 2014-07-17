#!/bin/bash
#this program record gbase database gcluster processes per 10 seconds
while [ 1 ]
do
echo "	`date +%F.%T`########################################################################################################" >> always_result.txt
sh gcluster_process.sh | grep -v Sleep | grep -v "show full processlist"  > tmp.gcluster_p.log

cat tmp.gcluster_p.log| grep -v Info |sed s/"checking permissions"/" "/g | awk '{print $1,$2,$3,$8,$9,$10,$11,$12,$13,$14,$15}' |sort -k 4,4nr >> always_result.txt

echo non-load process number: `grep -v 'processlist' tmp.gcluster_p.log |grep -v 'load data infile' | grep -v Host | grep -i 129.33| wc -l`  >> always_result.txt
echo load process number: `grep 'load data infile' tmp.gcluster_p.log| wc -l`  >> always_result.txt

sleep 30
if [ `cat always_result.txt|wc -l` -gt 500000 ];then
tar cvfz history/always_result_`date +%F.%H%M%S`.tar.gz always_result.txt
echo >always_result.txt
fi
done
