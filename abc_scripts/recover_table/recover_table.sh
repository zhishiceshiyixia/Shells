#!/bin/bash
if [ $# != 3 ]
then
        echo "recover_table.sh backup_dir db_name gcluster_tabname"
        exit 1
fi
backup_dir=$1
db_name=$2
gcluster_tabname=$3

recover_date=`date +%s`
echo $gcluster_tabname $bak_date

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

tmp_bak_dir=${backup_dir}/recover/${db_name}/${gcluster_tabname}/${recover_date}
mkdir -p ${tmp_bak_dir}

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

        echo $local_table_name" "$other_table_name

        cd /opt/gnode/userdata/gbase/${db_name}/sys_tablespace



        echo "mv ${local_table_name} ${tmp_bak_dir}/"
        mv ${local_table_name} ${tmp_bak_dir}/
        echo "mv ${other_table_name} ${tmp_bak_dir}/"
        mv ${other_table_name} ${tmp_bak_dir}
        cd /opt/gnode/userdata/gbase/${db_name}/metadata
        echo "mv ${local_table_name}.frm ${tmp_bak_dir}/"
        mv ${local_table_name}.frm ${tmp_bak_dir}/
        echo "mv ${other_table_name}.frm ${tmp_bak_dir}/"
        mv ${other_table_name}.frm ${tmp_bak_dir}
        echo "mv ${local_table_name}.GED ${tmp_bak_dir}/"
        mv ${local_table_name}.GED ${tmp_bak_dir}/
        echo "mv ${other_table_name}.GED ${tmp_bak_dir}/"
        mv ${other_table_name}.GED ${tmp_bak_dir}/
        
        
        tar xvf ${backup_dir}/${db_name}/sys_tablespace/${local_table_name}_data.tgz -C /
        tar xvf ${backup_dir}/${db_name}/sys_tablespace/${other_table_name}_data.tgz -C /
        tar xvf ${backup_dir}/${db_name}/metadata/${local_table_name}_meta.tgz -C /
        tar xvf ${backup_dir}/${db_name}/metadata/${other_table_name}_meta.tgz -C /
        /opt/gnode/server/bin/gbase -uroot ${db_name}<<EOF
        refresh table $local_table_name;
        refresh table $other_table_name;
EOF
elif [ $table_type -eq 0 ];then
        echo "$gcluster_tabname "
        cd /opt/gnode/userdata/gbase/${db_name}/sys_tablespace
        echo "mv ${gcluster_tabname} ${tmp_bak_dir}/"
        mv ${gcluster_tabname} ${tmp_bak_dir}/
        cd /opt/gnode/userdata/gbase/${db_name}/metadata
        echo "mv ${gcluster_tabname}.frm ${tmp_bak_dir}/"
        mv ${gcluster_tabname}.frm ${tmp_bak_dir}/
        echo "tar xvf ${backup_dir}/${db_name}/sys_tablespace/${gcluster_tabname}_data.tgz -C /"
        tar xvf ${backup_dir}/${db_name}/sys_tablespace/${gcluster_tabname}_data.tgz -C /
        echo "tar xvf ${backup_dir}/${db_name}/metadata/${gcluster_tabname}_meta.tgz -C /"
        tar xvf ${backup_dir}/${db_name}/metadata/${gcluster_tabname}_meta.tgz -C /

        /opt/gnode/server/bin/gbase -uroot ${db_name}<<EOF
        refresh table $gcluster_tabname;
EOF
fi
