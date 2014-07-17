#!/bin/bash

tbname_file=$1
tb_do_file=$2
host_ip=$3
db_name=$4
gbase_cmd=$5

echo "开始执行时间:`date +%F.%T`"
while [ `cat ${tbname_file}|wc -l` -gt 0 ]
	do
	cur_tbname=`flock get_tbname.sh -c "sh get_tbname.sh ${tbname_file}"`
	[ -z "${cur_tbname}" ] && continue
	####通过flock锁get_tbname.sh脚本执行防止表名文件被同时操作,这样可以随时增加或kill并发进程,同时各进程执行时间更平均##
	re_tmp_tb=${cur_tbname}_reorg_tmp
	echo ${cur_tbname} >>${tb_do_file}
	echo "重组表${cur_tbname}"
	start_time=`date +%s`
	echo "第一步:获取原表${cur_tbname}数据条数,并判断是否为0"
	old_count=`${gbase_cmd} -ugbase -pgbase20110531  -h${host_ip} -D${db_name} -N -e "select count(*) from ${cur_tbname};"`
	if [ ${old_count} -eq 0 ];then
		echo "第二步:原表${cur_tbname}数据条数为0,执行truncate表"
		${gbase_cmd} -ugbase -pgbase20110531  -h${host_ip} -D${db_name} -vvv<<EOF 
		truncate table ${cur_tbname};
EOF
		echo "表${cur_tbname}重组成功!"
	else
		
		echo "第二步:表${cur_tbname}数据条数不为0,建立临时表${re_tmp_tb},并将原表${cur_tbname}数据insert到新表${re_tmp_tb}"
		${gbase_cmd} -ugbase -pgbase20110531  -h${host_ip} -D${db_name} -vvv<<EOF 
		set _t_gcluster_optimize_use_insert_prepare_step=0;
		create table ${re_tmp_tb} like ${cur_tbname};
		insert into ${re_tmp_tb} select * from ${cur_tbname};
EOF
		if [ $? -ne 0 ];then
			echo "第二步执行错误,请检查！"
			echo "跳过表${cur_tbname},执行下个表！"
			continue
		fi
		echo "第三步:检查新表${re_tmp_tb}数据条数与原表${cur_tbname}是否一致"
		newtb_count=`${gbase_cmd} -ugbase -pgbase20110531  -h${host_ip} -D${db_name} -N -e "select count(*) from ${re_tmp_tb};"`
		echo "新表${re_tmp_tb}数据条数为${newtb_count}"
		#old_count=`${gbase_cmd} -ugbase -pgbase20110531  -h${host_ip} -D${db_name} -N -e "select count(*) from ${cur_tbname};"`
		echo "原表${cur_tbname}数据条数为${old_count}"
		if [ ${newtb_count} -eq ${old_count} ];then
			echo "新表${re_tmp_tb}数据数目与原表${cur_tbname}一致"
			echo "第四步:删除原表并将新表改名为原表"
			${gbase_cmd} -ugbase -pgbase20110531  -h${host_ip} -D${db_name} -vvv<<EOF 
			drop table ${cur_tbname};
			alter table ${re_tmp_tb} rename to ${cur_tbname};
EOF
			echo "表${cur_tbname}重组成功!"

		else
			echo "新表${re_tmp_tb}数据数目与原表${cur_tbname}不一致"
			echo "第四步：删除新表!!!!"			
			${gbase_cmd} -ugbase -pgbase20110531  -h${host_ip} -D${db_name} -vvv<<EOF
			drop table ${re_tmp_tb};
EOF
			echo "表${cur_tbname}重组失败!"
		fi
	fi
	end_time=`date +%s`
	echo "表${cur_tbname}重组耗时:$(($end_time-$start_time))秒,有效数据条数为${old_count}"
done
echo "结束时间:`date +%F.%T`"
