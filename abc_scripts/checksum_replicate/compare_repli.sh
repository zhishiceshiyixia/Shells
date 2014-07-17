#! /bin/bash

cat /tmp/abc/chk/checksum_replicate/tables.txt | while read line
do
	cd /tmp/abc/chk/checksum_replicate/${line}
	last_chk_file=""
	for curr_chk_file in `ls`
	do
		if [ "${last_chk_file}" = "" ];then
			last_chk_file=${curr_chk_file}
		else
			cmp ${last_chk_file} ${curr_chk_file} >/dev/null
			if [ $? -ne 0 ];then
				echo "tbname: ${line}; curr_chk_file: ${curr_chk_file}; last_chk_file: ${last_chk_file}"
			fi
			last_chk_file=${curr_chk_file}
		fi
	done
done