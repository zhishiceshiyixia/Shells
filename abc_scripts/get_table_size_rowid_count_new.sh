#!/bin/bash

if [ $# -ne 3 ];then
    echo "Usage:$0 db_name table_name node_number"
    exit 1
fi

db_name=$1
table_name=$2
node_number=$3

###########config
gbase_cmd=/DWGD2/gcluster/server/bin/gbase
gb_user=gbase
gb_password=gbase20110531
host_ip=10.229.129.41


#######init values
total_max_rowid=0
total_row_count=0
total_size=0
process_id=$$
exec_time=`date +%s`



#####get table type#########
replicate_flag=`${gbase_cmd} -u${gb_user} -p${gb_password} -h${host_ip} -N<<EOF
select isReplicate from gbase.table_distribution where dbname='${db_name}' and tbname='${table_name}';
EOF`

if [ -z ${replicate_flag} ];then
    echo "Table ${db_name}.${table_name} does not exist! Please check the table name!"
    exit 1
fi


#####column size
col_size1_tmp1=`echo ${table_name}|wc -L`
col_size1_tmp2=`expr $col_size1_tmp1 + 7`

if [ ${col_size1_tmp2} -lt 16 ];then
    col_size1=16
else
    col_size1=${col_size1_tmp2}
fi

col_size=`expr $col_size1 + 68`

${gbase_cmd} -u${gb_user} -p${gb_password} -h${host_ip} -N -e "show nodes" > /tmp/node_list_${table_name}_${process_id}.${exec_time}.tmp

trap "rm -f /tmp/*${table_name}*${process_id}.${exec_time}.tmp && exit 1" SIGINT


print_head()
{
		for ((i=1;i<=${col_size};i++));do  printf "%c" "-"; done;printf "%s\n" ""
    printf "%-${col_size1}s|" "   Table Name"
    printf "%-20s|" "   Data Size(Bytes)"
   	printf "%-15s|" "  Max Rowid"
    printf "%-15s|" "  Row Count"
    printf "%13s|\n" " Del_Percent"

}


print_body()
{
		for ((i=1;i<=${col_size};i++));do  printf "%c" "-"; done;printf "%s\n" ""
    printf "%-${col_size1}s|" " ${1}"
    printf "%20d|" ${2}
    printf "%15d|" ${3}
    printf "%15d|" ${4}
    printf %12.2f%%'|\n' ${5}
}


###
get_del_percent()
{
    if [ ${2} -eq 0 ] && [ ${1} -ne 0 ];then
					curr_del_percent=100
		elif [ ${2} -eq 0 ] && [ ${1} -eq 0 ];then
					curr_del_percent=0
		else
					curr_del_percent=`echo "(${2}-${3})*100/${2}"|bc -l`
		fi
		echo ${curr_del_percent}
}

#########query  and putout
if [ ${node_number} -eq 0 ] && [ ${replicate_flag} == 'NO' ];then #####all nodes of non_replicated_table
		print_head
    while read line
    do
        query_ip=`echo $line|awk '{print $2}'`
        query_number=`echo $line|awk '{print $4}'|awk -F 'n' '{print $2}'`
        ${gbase_cmd} -u${gb_user} -p${gb_password} -h${query_ip} -P5050 -N <<EOF >/tmp/query_size.${query_number}.${table_name}_n${query_number}.${process_id}.${exec_time}.tmp 2>/dev/null &
        select table_data_size from information_schema.tables where table_schema='${db_name}' and table_name='${table_name}_n${query_number}';
EOF
				${gbase_cmd} -u${gb_user} -p${gb_password} -h${query_ip} -P5050 -N <<EOF >/tmp/query_rowid_count.${query_number}.${table_name}_n${query_number}.${process_id}.${exec_time}.tmp 2>/dev/null&
        select ifnull(max(rowid+1),0),count(1) from ${db_name}.${table_name}_n${query_number};
EOF
		done </tmp/node_list_${table_name}_${process_id}.${exec_time}.tmp
		wait
		
		ls /tmp/query_size.*.${process_id}.${exec_time}.tmp 2>/dev/null|sort -t '.' -k 2,2n >/tmp/query_size_file_list_${process_id}.${exec_time}.tmp 
		while read query_size_file
		do
				query_rowid_count_file=`echo ${query_size_file}|sed s/query_size./query_rowid_count./g`
				node_table_name=`echo ${query_size_file}|awk -F '.' '{print $3}'`
				query_size=`cat ${query_size_file}`
				query_maxrowid=`cat ${query_rowid_count_file}|awk '{print $1}'`
				query_count=`cat ${query_rowid_count_file}|awk '{print $2}'`
				del_percent=`get_del_percent ${query_size} ${query_maxrowid} ${query_count}`
				print_body ${node_table_name} ${query_size} ${query_maxrowid} ${query_count} ${del_percent}
    		total_max_rowid=`expr ${total_max_rowid} + ${query_maxrowid}`
				total_row_count=`expr ${total_row_count} + ${query_count}`
        total_size=`expr ${total_size} + ${query_size}`
    done </tmp/query_size_file_list_${process_id}.${exec_time}.tmp
    rm -f /tmp/query_size_file_list_${process_id}.${exec_time}.tmp
		total_del_percent=`get_del_percent ${total_size} ${total_max_rowid} ${total_row_count}`
		print_body "  Total" ${total_size} ${total_max_rowid} ${total_row_count} ${total_del_percent}
    for ((i=1;i<=${col_size};i++));do  printf "%c" "-"; done;printf "%s\n" ""
    rm -f /tmp/*.${table_name}*.${process_id}.${exec_time}.tmp
elif [ ${node_number} -eq 0 ] && [ ${replicate_flag} != 'NO' ];then  #####all nodes of replicated_table
		first_ip=`cat /tmp/node_list_${table_name}_${process_id}.${exec_time}.tmp |head -1 |awk '{print $2}'`
		nodes_count=`cat /tmp/node_list_${table_name}_${process_id}.${exec_time}.tmp |wc -l`
		print_head
    query_size=`${gbase_cmd} -u${gb_user} -p${gb_password} -h${first_ip} -P5050 -N <<EOF
    select table_data_size from information_schema.tables where table_schema='${db_name}' and table_name='${table_name}';
EOF`
	query_rowid_count=`${gbase_cmd} -u${gb_user} -p${gb_password} -h${first_ip} -P5050 -N <<EOF
    select ifnull(max(rowid+1),0),count(1) from ${db_name}.${table_name};
EOF`
		query_maxrowid=`echo ${query_rowid_count}|awk '{print $1}'`
		query_count=`echo ${query_rowid_count}|awk '{print $2}'`
		del_percent=`get_del_percent ${query_size} ${query_maxrowid} ${query_count}`	
    print_body ${table_name} ${query_size} ${query_maxrowid} ${query_count} ${del_percent}
    total_size=`expr ${nodes_count} \* ${query_size}`
    total_max_rowid=`expr ${nodes_count} \* ${query_maxrowid}`
		total_row_count=`expr ${nodes_count} \* ${query_count}`
    print_body "  Total" ${total_size} ${total_max_rowid} ${total_row_count} ${del_percent}
    for ((i=1;i<=${col_size};i++));do  printf "%c" "-"; done;printf "%s\n" ""
elif [ ${node_number} -ne 0 ] && [ ${replicate_flag} != 'NO' ];then #####one node of replicated_table
				    node_line=`cat /tmp/node_list_${table_name}_${process_id}.${exec_time}.tmp|awk '{if($4=="n'$node_number'") print $0}'`
    		if [ -z "${node_line}" ];then
       	 	echo "Wrong node number!"
       	 	rm -f /tmp/node_list_${table_name}_${process_id}.${exec_time}.tmp
        	exit 1
    		fi
				print_head
				query_ip=`echo $node_line|awk '{print $2}'`
        query_size=`${gbase_cmd} -u${gb_user} -p${gb_password} -h${query_ip} -P5050 -N <<EOF
        select table_data_size from information_schema.tables where table_schema='${db_name}' and table_name='${table_name}';
EOF`
        query_rowid_count=`${gbase_cmd} -u${gb_user} -p${gb_password} -h${query_ip} -P5050 -N <<EOF
        select ifnull(max(rowid+1),0),count(1) from ${db_name}.${table_name};
EOF`
        query_maxrowid=`echo ${query_rowid_count}|awk '{print $1}'`
        query_count=`echo ${query_rowid_count}|awk '{print $2}'`
       	del_percent=`get_del_percent ${query_size} ${query_maxrowid} ${query_count}`	 
       	print_body ${table_name} ${query_size} ${query_maxrowid} ${query_count} ${del_percent} 
        for ((i=1;i<=${col_size};i++));do  printf "%c" "-"; done;printf "%s\n" ""
else  #####one node of non_replicated_table
    node_line=`cat /tmp/node_list_${table_name}_${process_id}.${exec_time}.tmp|awk '{if($4=="n'$node_number'") print $0}'`
    if [ -z "${node_line}" ];then
        echo "Wrong node number!"
        rm -f /tmp/node_list_${table_name}_${process_id}.${exec_time}.tmp
        exit 1
    fi
		print_head
    query_ip=`echo $node_line|awk '{print $2}'`
    query_number=`echo $node_line|awk '{print $4}'`
    query_size=`${gbase_cmd} -u${gb_user} -p${gb_password} -h${query_ip} -P5050 -N <<EOF
    select table_data_size from information_schema.tables where table_schema='${db_name}' and table_name='${table_name}_${query_number}';
EOF`
		query_rowid_count=`${gbase_cmd} -u${gb_user} -p${gb_password} -h${query_ip} -P5050 -N <<EOF
   	select ifnull(max(rowid+1),0),count(1) from ${db_name}.${table_name}_${query_number};
EOF`
		query_maxrowid=`echo ${query_rowid_count}|awk '{print $1}'`
		query_count=`echo ${query_rowid_count}|awk '{print $2}'`
		del_percent=`get_del_percent ${query_size} ${query_maxrowid} ${query_count}`
  	print_body ${table_name}_${query_number} ${query_size} ${query_maxrowid} ${query_count} ${del_percent} 
    for ((i=1;i<=${col_size};i++));do  printf "%c" "-"; done;printf "%s\n" ""
fi
rm -f /tmp/node_list_${table_name}_${process_id}.${exec_time}.tmp
