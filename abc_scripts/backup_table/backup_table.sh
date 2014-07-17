#!/bin/sh
if [ $# != 3 ]
then
        echo "backup_table.sh destdir db_name gcluster_tabname"
        exit 1
fi

destdir=$1
db_name=$2
gcluster_tabname=$3
table_type=`gccli -uroot -N<<EOF
select case when isreplicate='NO' then 1 else 0 end from gbase.table_distribution where tbname='${gcluster_tabname}' and dbname='${db_name}';
EOF`


if [ -d $destdir ]
then
        echo "destination diretory is :"$destdir
else
        echo "=================failed!==$destdir is not a directoty========="
        exit 1
fi

if [ -z ${table_type} ];then
	echo "The table ${db_name}.${gcluster_tabname} is not exists!"
	exit 1
fi

mkdir -p $destdir/${db_name}/metadata
mkdir -p $destdir/${db_name}/sys_tablespace

if [ $table_type -eq 1 ];then
	local_node_name=`gccli -uroot -N -e "show local node"|awk '{print $4}'`
	local_node_number=`echo ${local_node_name}|awk -F 'n' '{print $2}'`
	if [ `expr ${local_node_number} % 2` -eq 0 ];then
		other_node_number=`expr ${local_node_number} - 1`
	else
		other_node_number=`expr ${local_node_number} + 1`
	fi
	local_table_name=${gcluster_tabname}_n${local_node_number}
	other_table_name=${gcluster_tabname}_n${other_node_number}
	echo "tar czf $destdir/${db_name}/metadata/${local_table_name}_meta.tgz /opt/gnode/userdata/gbase/${db_name}/metadata/${local_table_name}.* "              
	sh -c "tar czf $destdir/${db_name}/metadata/${local_table_name}_meta.tgz /opt/gnode/userdata/gbase/${db_name}/metadata/${local_table_name}.* "
	echo "tar czf $destdir/${db_name}/sys_tablespace/${local_table_name}_data.tgz /opt/gnode/userdata/gbase/${db_name}/sys_tablespace/${local_table_name} "    
  	sh -c "tar czf $destdir/${db_name}/sys_tablespace/${local_table_name}_data.tgz /opt/gnode/userdata/gbase/${db_name}/sys_tablespace/${local_table_name} "
	echo "tar czf $destdir/${db_name}/metadata/${other_table_name}_meta.tgz /opt/gnode/userdata/gbase/${db_name}/metadata/${other_table_name}.* "            
	sh -c "tar czf $destdir/${db_name}/metadata/${other_table_name}_meta.tgz /opt/gnode/userdata/gbase/${db_name}/metadata/${other_table_name}.* "
	echo "tar czf $destdir/${db_name}/sys_tablespace/${other_table_name}_data.tgz /opt/gnode/userdata/gbase/${db_name}/sys_tablespace/${other_table_name} "  
  	sh -c "tar czf $destdir/${db_name}/sys_tablespace/${other_table_name}_data.tgz /opt/gnode/userdata/gbase/${db_name}/sys_tablespace/${other_table_name} "
elif [ $table_type -eq 0 ];then
	echo "tar czf $destdir/${db_name}/metadata/${gcluster_tabname}_meta.tgz /opt/gnode/userdata/gbase/${db_name}/metadata/${gcluster_tabname}.* "           
	sh -c "tar czf $destdir/${db_name}/metadata/${gcluster_tabname}_meta.tgz /opt/gnode/userdata/gbase/${db_name}/metadata/${gcluster_tabname}.* "
	echo "tar czf $destdir/${db_name}/sys_tablespace/${gcluster_tabname}_data.tgz /opt/gnode/userdata/gbase/${db_name}/sys_tablespace/${gcluster_tabname} " 
	sh -c "tar czf $destdir/${db_name}/sys_tablespace/${gcluster_tabname}_data.tgz /opt/gnode/userdata/gbase/${db_name}/sys_tablespace/${gcluster_tabname} "
fi
	
	
