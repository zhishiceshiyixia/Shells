#!/bin/bash
##--------------------------------------------##
#Creater: Nie Dan
#Create Data: 2014-5-23
#Description: This script is use for testing the disk.  both random and sequence ways of the  I/O performance.
#Config:bs.lst 
#Version: 1.1
#Modify by Nie Dan 2014-6-16
#增加了目标目录，简化入参判断逻辑
##-------------------------------------------_##
usage(){
	echo "This script is use fro testing the disk, both in random and sequence R/W. 
	usage: [OPTION] [TARGET] [FILE] 
        sh Gbase_01_EnvC_DiskCheck.sh dd|fio|all target_dir bs.lst
	for example: sh Gbase_01_EnvC_DiskCheck all /opt /root/bs.lst
}

ERRTRAP(){
		echo "[LINE:$1] ERROR: Command or function extied with status $?"
		exit
}

init(){
	Current_dir=`pwd`
	if [ `whoami` != "root" ];then
		echo "Pelease run script by user root"
		exit
	fi
	if [ ! -d ${Current_dir}/fio_logs ]; then
		mkdir -p ${Current_dir}/fio_logs
 	fi
}

dd_test(){
trap 'ERRTRAP $LINENO' ERR
if [  -e ${Current_dir}/dd.log ];then
	mv ${Current_dir}/dd.log ${Current_dir}/dd.log.`date "+%Y%m%d%H%M%S"`.bak
fi
touch ${Current_dir}/dd.log
while read bs
do
	byte=`echo ${bs:${#bs}-1}`
	num=`echo ${bs:0:${#bs}-1}`
	if [ ${byte} = "k" -o ${byte} = "K" ]; then
		count=$[2*1024*1024/${num}]
	elif [ ${byte} = "m" -o ${byte} = "M" ]; then
		count=$[2*1024/${num}]
	fi
#	echo "byte is ${byte};num is ${num} count is ${count} bs is ${bs}"
        echo -e "==========begin ${bs} dd test========\n">>${Current_dir}/dd.log
        echo -e "==========begin ${bs} dd test========"
        echo -e "==========${bs} write========\n">>${Current_dir}/dd.log
        echo -e "==========${bs} write========"        
        dd oflag=direct if=/dev/zero of=${Dist_dir}/dd.dat bs=${bs} count=${count} >>${Current_dir}/dd.log 2>&1
        echo -e "==========${bs} read========\n">>${Current_dir}/dd.log
        echo -e "==========${bs} read========"
        dd iflag=direct if=${Dist_dir}/dd.dat of=/dev/null bs=${bs} count=${count} >>${Current_dir}/dd.log 2>&1
        echo -e "==========${bs} r and w========\n">>${Current_dir}/dd.log
        echo -e "==========${bs} r and w========"
        dd iflag=direct oflag=direct if=${Dist_dir}/dd.dat of=${Dist_dir}/dd2.dat bs=${bs} count=${count} >>${Current_dir}/dd.log 2>&1
        echo -e "==========end ${bs} dd test========\n">>${Current_dir}/dd.log
done<${BS_LST}
        rm -rf ${Dist_dir}/dd.dat
        rm -rf ${Dist_dir}/dd2.dat
}

fio_test(){
trap 'ERRTRAP $LINENO' ERR
	Temp_check=`which fio 2>/dev/null`
	if [ $? -eq 0 ];then
		Temp_check=`basename $Temp_check`
	else
		Temp_check="ERR"
	fi
	if [ $Temp_check != "fio" ]; then
		find *fio*.rpm
		if [ $? -eq 0 ]; then
			Temp_name=`find *fio*.rpm`
			echo $Temp_name
			yum install ${Temp_name} -y
		else
			echo "Can not find command fio, plz install fio first"
		fi
	fi
	echo "Making data, Plz wait"
	dd of=${Dist_dir}/fio.dat if=/dev/zero oflag=direct bs=1M count=2048 1>/dev/null 2>/dev/null
	echo "Done, Stat to fio test"
	for i in `seq 1 ${Gather_times}`
	do
		while read bs
		do
			fio -filename=${Dist_dir}/fio.dat -direct=1 -iodepth 8 -thread -rw=randrw -ioengine=psync -bs=${bs} -size=2G -numjobs=32 -runtime=60 -group_reporting -name=test_${i}_${bs} --output=${Current_dir}/fio_logs/test_${i}_${bs}.log
		done<${BS_LST}
	done
	echo "Done with fio test"
	rm -rf ${Dist_dir}/fio.dat
	gather_result
}

gather_result(){
trap 'ERRTRAP $LINENO' ERR
	echo "Gather FIO result"
		if [ `ls -l ${Current_dir}/fio_logs | wc -l` -gt 4  ]; then
			for filename in result.tmp.tmp result.tmp result.fio
			do
				if [  -e ${Current_dir}/${filename} ];then
				mv ${Current_dir}/${filename} ${Current_dir}/${filename}.`date "+%Y%m%d%H%M%S"`.bak
				fi
			touch ${Current_dir}/${filename}
			done
			for i in `seq 1 ${Gather_times}`
				do
				while read bs
					do
					echo ${bs} >> result.tmp.tmp
					cat ${Current_dir}/fio_logs/test_${i}_${bs}.log | grep bw | head -n 2 | tail -n 1 | awk -F, '{print $4}' | sed 's/ avg=//g' >> ${Current_dir}/result.tmp.tmp 
					cat ${Current_dir}/fio_logs/test_${i}_${bs}.log | grep bw | head -n 4 | tail -n 1 | awk -F, '{print $4}' | sed 's/ avg=//g' >> ${Current_dir}/result.tmp.tmp
					done<${BS_LST}
				done
			cat ${Current_dir}/result.tmp.tmp | sed -n -e 'N;N;s/\n/,/g;p' > ${Current_dir}/result.tmp
			rm -rf ${Current_dir}/result.tmp.tmp
			echo "Result of FIO test" > ${Current_dir}/result.fio
			while read bs
				do
				echo ${bs} >> ${Current_dir}/result.fio
				cat ${Current_dir}/result.tmp | grep ${bs} | awk -F',' '{sum1+=$2;sum2+=$3;i++} END {print "Read",sum1/i,"kb/s", "Write:",sum2/i,"kb/s" >> "result.fio"}'		
				done<${BS_LST}
			 rm -rf ${Current_dir}/result.tmp
		else
			echo "No test log file in directory ${Current_dir}/fio_logs"
		fi 

}

trap 'ERRTRAP $LINENO' ERR
Exe=0
Gather_times=3
Dist_dir="/opt"
if [ $# -eq 3 ];then
	if [ -e  $3  ];then
		BS_LST=$3
		Exe=$[${Exe}+1]
	else
		echo "file $3 not exists, exit now"
		exit
	fi
	if [ -d $2 ];then
		Dist_dir=$2
		Exe=$[${Exe}+1]
	else
		echo "$2 is not a directory or directory not exist"
		exit
	fi	
fi

if [ $Exe -eq 2 ]; then
init
	case $1 in
	fio)
		fio_test
		echo "gather FIO result done, plz see the file result.fio"
	;;
	dd)
		dd_test
		echo "DD test is Done, see the result in file dd.log" 
	;;
	all)
		dd_test
		fio_test
		cat ${Current_dir}/dd.log >> ${Current_dir}/result.txt
		cat ${Current_dir}/result.fio >> ${Current_dir}/result.txt
		echo "Plz see the result in filr ${Current_dir}/result.txt" 
	;;
	*)
		echo "$1 prameter not valid, exit now"
	esac
else
	usage
fi
