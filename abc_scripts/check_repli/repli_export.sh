#!/bin/bash

####config#####

gbase_cmd=${1}
conn_host=${2}
db_name=${3}
table_name=${4}
work_dir=${5}
curr_work_dir=${work_dir}/${table_name}
#####get column list####
column_list=`${gbase_cmd} -ugbase -pgbase20110531 -h${conn_host} -N<<EOF |grep -iv timestamp |sed ':t;N;s/\n/,/g;b t'
select column_name from information_schema.columns where table_name='${table_name}';
EOF`
[ -d ${curr_work_dir} ] && rm -rf ${curr_work_dir}
mkdir -p ${curr_work_dir}
#chown gbase:gbase ${curr_work_dir}
#chmod 777 ${curr_work_dir}
#####export data from all nodes#####

${gbase_cmd} -ugbase -pgbase20110531 -h${conn_host} -N -e "show nodes"|while read line
do
	host_ip=`echo $line|awk '{print $2}'`
	node_name=`echo $line|awk '{print $4}'`
	#echo "rmt:select md5($column_list),rowid from ${table_name} order by rowid into outfile '${curr_work_dir}/${node_name}.txt' fields terminated by '|';"
	${gbase_cmd} -ugbase -pgbase20110531 -h${host_ip} -D${db_name}<<EOF
rmt:select md5($column_list),rowid from ${table_name} order by rowid into outfile '${curr_work_dir}/${node_name}.txt' fields terminated by '|';
EOF
done
