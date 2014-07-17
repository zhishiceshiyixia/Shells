#! /bin/bash

cat /tmp/abc/chk/checksum_replicate/tables.txt | while read line
do
	cd /tmp/abc/chk/checksum_replicate/${line}
	for((i=1;i<=28;i++))
	do
		cmp *n_${i}_checkout >/dev/null
		if [ $? -ne 0 ];then
			echo "tbname: ${line}; slice: n${i}"
		fi
	done
done