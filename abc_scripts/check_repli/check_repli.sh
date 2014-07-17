#!/bin/bash

#####config

gbase_cmd=/DWGD2/gcluster/server/bin/gbase
conn_host=10.229.129.41
db_name=dwgd
work_dir=/DWGD2/work/gbase/check_repli


#####get replicated table name####
${gbase_cmd} -ugbase -pgbase20110531 -h${conn_host} -N <<EOF >rep_tab_name.txt 2>&1
select tbname from gbase.table_distribution where dbname='${db_name}' and isReplicate='YES' and (tbname like 'bd_%' or tbname like 'g_%');
EOF

######export data from all nodes,and compare data file######

cat rep_tab_name.txt |while read table_name
do
	echo "sh repli_export.sh ${gbase_cmd} ${conn_host} ${db_name} ${table_name} ${work_dir}"
	sh repli_export.sh ${gbase_cmd} ${conn_host} ${db_name} ${table_name} ${work_dir}
	echo "sh compare_data.sh ${table_name} ${work_dir}"
	sh compare_data.sh ${table_name} ${work_dir}
	if [ $? -eq 0 ];then
		echo "表${table_name}数据一致"
	else
		echo "表${table_name}数据不一致"
	fi		
done
