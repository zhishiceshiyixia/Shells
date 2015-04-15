#!/bin/bash
##--------------------------------------------##
#Creater: Nie Dan
#Create Data: 2014-5-30
#Description: This script is use for compare the differences between config files
#Config:
#Version: 1.0
##-------------------------------------------_#
FILE_1=/opt/gcluster/config/gbase_8a_gcluster.cnf
FILE_2=/opt/gnode/config/gbase_8a_gbase.cnf
declare -a LIST
Comp_files(){
declare -a cnf_1
declare -a cnf_2
declare -a show_1
declare -a show_2
i=0
	for ((k=0;k<${#LIST[@]};k++)) do
		while read cnf
		do
			cnf_1[$i]=`echo ${cnf} | awk -F'=' '{print $1}'`
			cnf_2[$i]=`echo ${cnf} | awk -F'=' '{print $2}'`
			i=$[$i+1]
		done<./cnf_files/gcluster_${LIST[$k]}.cnf
		i=0
		while read show
		do
			show_1[$i]=`echo ${show} | awk -F' ' '{print $1}'`
			show_2[$i]=`echo ${show} | awk -F' ' '{print $2}'`
			i=$[$i+1]
		done<./cnf_files/show_gcluster_${LIST[$k]}.txt
		echo "============At node ${LIST[$k]} gcluster layer================="
		echo -e "In cnf file\t\t\tIn Show variables"
		for ((j=0;j<${#cnf_1[@]-1};j++)) do
			for ((l=0;l<${#show_1[@]-1};l++)) do
				if [[ ${cnf_1[$j]} == ${show_1[$l]} ]];then
					if [  ${show_2[$l]}x == "x"  ];then
					echo -e "${cnf_1[$j]}:${cnf_2[$j]}\t\t\t${show_1[$l]}:${show_2[$l]}"
					break
					fi
					if [ ${cnf_2[$j]} != ${show_2[$l]}  ];then
					echo -e "${cnf_1[$j]}:${cnf_2[$j]}\t\t\t${show_1[$l]}:${show_2[$l]}"
					#echo -e "Prameter in cnf\t\tPrameter in show variables\n${cnf_1[$j]}\t\t\t${show_1[$l]}\n${cnf_2[$j]}\t\t${show_2[$l]}"
					break
					fi
				fi
			done
		done
	done
	echo "Use the ${LIST[0]} as a moudle"
	for ((i=0;i<${#LIST[@]}-1;i++)) do
		diff ./cnf_files/gcluster_${LIST[0]}.cnf ./cnf_files/gcluster_${LIST[$i+1]}.cnf > ./reslut
		if [ $? -ne 0 ];then
			Gather_diff gcluster_${LIST[0]}.cnf gcluster_${LIST[$i+1]}.cnf
		fi
		diff ./cnf_files/gnode_${LIST[0]}.cnf ./cnf_files/gnode_${LIST[$i+1]}.cnf > ./reslut
		if [ $? -ne 0 ];then
			Gather_diff gnode_${LIST[0]}.cnf gnode_${LIST[$i+1]}.cnf
		fi
		diff ./cnf_files/show_node_${LIST[0]}.txt ./cnf_files/show_node_${LIST[$i+1]}.txt > ./reslut
		if [ $? -ne 0 ];then
			Gather_diff show_node_${LIST[0]}.txt show_node_${LIST[$i+1]}.txt
		fi
		diff ./cnf_files/show_gcluster_${LIST[0]}.txt ./cnf_files/show_gcluster_${LIST[$i+1]}.txt > ./reslut
		if [ $? -ne 0 ];then
			Gather_diff show_gcluster_${LIST[0]}.txt show_gcluster_${LIST[$i+1]}.txt
		fi
	done
}
Gather_diff()
{
if [ $# -ne 2  ];then
	echo "Bad parameter"
	exit
fi
LINE=

			echo "===========In File $1 and $2=================="
	while read diffcom
	do
		if [[ $diffcom == [0-9]*[c,a,d][0-9]* ]];then
			tmp_char=${diffcom:$[${#diffcom}/2]:1}
			LINE=${diffcom:0:$[${#diffcom}/2]}
			ip_1=`echo $1 | sed 's/\([a-z]\{1,100\}_\)\{1,100\}//' | sed 's/\.[a-z]\{1,100\}//'`
			ip_2=`echo $2 | sed 's/\([a-z]\{1,100\}_\)\{1,100\}//' | sed 's/\.[a-z]\{1,100\}//'`
			temp_str1=`cat ./cnf_files/$1 | sed -n ${LINE}p `
			temp_str2=`cat ./cnf_files/$2 | sed -n ${LINE}p `
			#echo -e "\t$ip_1\t\t\t\t$ip_2\nLINE $LINE:${temp_str1}\t\t\t ${temp_str2}  "
			echo -e "LINE $LINE:${temp_str1}\t\t\t ${temp_str2} \n"
		fi
	done<./reslut
}
Copy_files(){
rm ./iplist.lst -rf
gcadmin  | grep sg | grep -v rowid | awk -F'|' 'BEGIN {i=0} {iplist[i]=$4;print iplist[i]>>"./iplist.lst";i++}'
i=0
mkdir ./cnf_files
while read ipaddr
do
	iplist[$i]=`echo ${ipaddr} | col -bfp`
	realip=`echo ${iplist[$i]} | awk -F'31m' '{print $1}' | tr -d " "`
	LIST[$i]=$realip
	scp root@${realip}:${FILE_1} /tmp/gcluster.${realip}.cnf
	scp root@${realip}:${FILE_1} /tmp/gcluster.${realip}.cnf
	cat /tmp/gcluster.${realip}.cnf | grep -v '\[' | grep -v '\#' | grep -v ^$  | sort > ./cnf_files/gcluster_${realip}.cnf
	scp root@${realip}:${FILE_2} /tmp/gnode.${realip}.cnf
	cat /tmp/gnode.${realip}.cnf | grep -v '\[' | grep -v '\#' | grep -v ^$  | sort > ./cnf_files/gnode_${realip}.cnf
	su - gbase -c "/opt/gnode/server/bin/gbase -uroot -p1 -h${realip} -e\"show variables\" > /tmp/show_node_${realip}.txt"
	cat /tmp/show_node_${realip}.txt | sort > ./cnf_files/show_node_${realip}.txt
	su - gbase -c "/opt/gcluster/server/bin/gbase -uroot -p1 -h${realip} -e\"show variables\" > /tmp/show_gcluster_${realip}.txt"
	cat /tmp/show_gcluster_${realip}.txt | sort > ./cnf_files/show_gcluster_${realip}.txt
	i=$[${i}+1]
done<./iplist.lst
}
Copy_files
Comp_files
