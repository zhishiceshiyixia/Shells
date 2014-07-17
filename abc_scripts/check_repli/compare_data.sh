#!/bin/bash

#####config
table_name=${1}
work_dir=${2}

curr_work_dir=${work_dir}/${table_name}
echo "${curr_work_dir}"
cd ${curr_work_dir}

last_file=""
ls *.txt|sort -t 'n' -k2,2n | while read curr_file
do
	cat ${curr_file}|awk -F '|' '{print $1}' |sort >${curr_file}_md5
	if [ -z "${last_file}" ];then
		last_file=${curr_file}
		continue
	fi
	last_count=`cat ${last_file}_md5|wc -l`
	curr_count=`cat ${curr_file}_md5|wc -l`
	if [ ${last_count} -eq ${curr_count} ];then
		echo "${last_file},${curr_file}行数一致!"
	else
		echo "${last_file},${curr_file}行数不一致!"
		exit 5
	fi
	if [ `diff ${last_file}_md5 ${curr_file}_md5|wc -l` -eq 0 ];then
		if [ `diff ${last_file} ${curr_file}|wc -l` -eq 0 ];then
			echo "${last_file},${curr_file}数据一致,顺序一致"
		else
			echo "${last_file},${curr_file}数据一致,顺序不一致"
		fi
	else
		echo "${last_file},${curr_file}数据不一致"
		exit 5
	fi
	last_file=${curr_file}
done
