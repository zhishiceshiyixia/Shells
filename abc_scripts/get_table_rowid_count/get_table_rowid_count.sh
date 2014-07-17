#! /bin/bash

db_name=$1
table_name=$2
host_ip=$3

gbase_cmd=/DWGD2/gcluster/server/bin/gbase

gbase_user=gbase
gbase_passwd=gbase20110531

query_rowid_count=`${gbase_cmd} -u${gbase_user} -p${gbase_passwd} -h${host_ip} -P5050 -N <<EOF 2>/dev/null
select ifnull(max(rowid),0),count(1) from ${db_name}.${table_name};
EOF`

if [ -z "$query_rowid_count" ];then
    query_rowid_count="0 0"
fi
echo "${db_name}.${table_name} ${query_rowid_count}"
