#!/bin/bash

host_name=${HOSTNAME}_`hostname -i`
bak_dir=/backup/data/20140307/$host_name/config
mkdir -p ${bak_dir}
cd ${bak_dir}/../
cp /etc/sysctl.conf  ${bak_dir}/
cp /etc/sysconfig/ulimit ${bak_dir}/
cp /boot/grub/menu.lst ${bak_dir}/
cp /etc/security/limits.conf ${bak_dir}/
cp -r /etc/corosync ${bak_dir}/
cp -r /opt/gcluster/config ${bak_dir}/gc_config
cp -r /opt/gnode/config ${bak_dir}/gn_config
cp -r /var/lib/gcware ${bak_dir}/

tar czf ${host_name}.config.tar.gz `basename ${bak_dir}`
if [ $? -eq 0 ];then
    rm -rf ${bak_dir}
fi
echo "done!"
