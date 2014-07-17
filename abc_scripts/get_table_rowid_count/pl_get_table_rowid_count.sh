#! /bin/bash

db_name=$1
host_ip=$2

parallel_degree=5

process_id=$$

gbase_cmd=/DWGD2/gcluster/server/bin/gbase
gbase_user=gbase
gbase_passwd=gbase20110531


fifo_file=/tmp/${process_id}_`date +%s`.fifo

mkfifo ${fifo_file}

exec 6<>${fifo_file}

rm -f ${fifo_file}

for((i=1;i<=${parallel_degree};i++))
do
    echo 
done >&6

${gbase_cmd} -u${gbase_user} -p${gbase_passwd} -h${host_ip} -P5050 -N  <<EOF >${db_name}_table_name.txt 2>/dev/null
select table_name from information_schema.tables where table_schema='${db_name}' and table_name not like 'l\_%' and table_name not like 't\_%' and table_name not like 'n\_%';
EOF


while read table_name
do
    read -u6
    {
        sh get_table_rowid_count.sh ${db_name} ${table_name} ${host_ip}
        echo >&6
    }&
done<${db_name}_table_name.txt
wait

exec 6>&-


