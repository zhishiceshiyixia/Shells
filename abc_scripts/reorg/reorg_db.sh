#!/bin/bash

##配置信息#####
db_name=dwgd
paralle_digree=9
gbase_cmd=/DWGD2/gcluster/server/bin/gbase
tbname_file=/DWGD2/work/gbase/reorg/${db_name}.tbl
tb_do_file=/DWGD2/work/gbase/reorg/${db_name}_do.tbl
host_ip=10.229.129.41


echo "重组数据库${db_name}中所有表"
########判断表名文件是否存在#########
#[ -f ${tbname_file} ] && rm -f ${tbname_file}
[ -f ${tb_do_file} ] && rm -f ${tb_do_file}


#${gbase_cmd} -ugbase -pgbase20110531 -h${host_ip} -N <<EOF >${tbname_file} 2>&1
#select tbname from gbase.table_distribution where dbname='${db_name}' and tbname not like '%reorg_tmp' order by md5(tbname);
#EOF



#sed -i '/^l_/d' ${tbname_file}

cp ${tbname_file} ${tbname_file}_`date +%s`.bak


####调起并发脚本######	
i=0
while [ $i -lt ${paralle_digree} ]
do
	echo "后台执行第$i个并发进程"
	echo "sh reorg_table.sh ${tbname_file} ${tb_do_file} ${host_ip} ${db_name} ${gbase_cmd}>reorg_table_${i}.log "
	nohup sh reorg_table.sh ${tbname_file} ${tb_do_file} ${host_ip} ${db_name} ${gbase_cmd}>reorg_table_${i}.log 2>&1 &
	sleep 3
	i=`expr $i + 1`
done

