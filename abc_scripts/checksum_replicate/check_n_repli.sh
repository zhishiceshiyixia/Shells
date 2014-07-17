#!/bin/bash

local_node_name=`gccli -uroot -N -e "show local node"|awk '{print $4}'`
local_node_number=`echo ${local_node_name}|awk -F 'n' '{print $2}'`
if [ `expr ${local_node_number} % 2` -eq 0 ];then
	other_node_number=`expr ${local_node_number} - 1`
else
	other_node_number=`expr ${local_node_number} + 1`
fi


cat tables.txt |while read table_name
do

mkdir -p /tmp/abc/chk/checksum_replicate/${table_name}
local_table_name=${table_name}_n${local_node_number}
other_table_name=${table_name}_n${other_node_number}
checksum dwgd ${local_table_name} -v  >/tmp/abc/chk/checksum_replicate/${table_name}/`hostname -i`_n${local_node_number}_checkout
checksum dwgd ${other_table_name} -v  >/tmp/abc/chk/checksum_replicate/${table_name}/`hostname -i`_n${other_node_number}_checkout

done
