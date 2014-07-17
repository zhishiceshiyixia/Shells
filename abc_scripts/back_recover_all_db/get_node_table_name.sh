#! /bin/bash

cluster_table_file=/backup/work/scripts/skip_table_name_gcluster.txt
node_table_file=/home/gbase/skip_table_name_gnode.txt

if [ ! -f ${cluster_table_file} ];then
	echo "gcluster table_name file does not exist!"
	exit 1
fi
[ -f ${node_table_file} ] && rm -f ${node_table_file}

local_node_number=`hostname|awk -F '-D' '{print $3+0}'`

if [ `expr ${local_node_number} % 2 ` -eq 0 ];then
	other_node_number=`expr ${local_node_number} - 1`
else
	other_node_number=`expr ${local_node_number} + 1`
fi

while read gc_table_name
do
	repli_flag=`gccli -uroot -N -e "select trim(isreplicate) from gbase.table_distribution where dbname='dwgd' and tbname='${gc_table_name}'"`
	if [ "${repli_flag}" == "NO" ];then
		echo "${gc_table_name}_n${local_node_number}" >> ${node_table_file}
		echo "${gc_table_name}_n${other_node_number}" >> ${node_table_file}
	elif [ "${repli_flag}" == "YES" ];then
		echo "${gc_table_name}" >> ${node_table_file}
	else
		echo "Gcluster table ${gc_table_name} does not exist!"
	fi
done < ${cluster_table_file}
