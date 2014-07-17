#!/bin/bash

bakup_dir=/bak/20140224_backup
db_name=dwgd

#gccli -uroot -N ${db_name} -e "show tables">${db_name}_table.txt

cat bak_table.txt |while read table_name
do
echo "backup table ${db_name}.${table_name} start!"
#sh backup_table.sh $bakup_dir ${table_name} ${table_type}
sh backup_table.sh ${bakup_dir} ${db_name} ${table_name} 
echo "backup table ${db_name}.${table_name} end!"
done




