#!/bin/sh
if [ $# != 3 ]
then
        echo "gbase_recover_scp.sh local_srcdir dest_ip dest_dir"
        exit 1
fi

local_srcdir=$1
dest_ip=$2
dest_dir=$3

echo $slice,$dest,$dist

echo "=================find the frm_file into /home/gbase/gbase_scp.tmp==============="

find ${local_srcdir}/opt/gnode/userdata/gbase -name "*.frm" | grep -v '\/gctmpdb\/' > /home/gbase/gbase_recover_scp.tmp


if [ $? -ne 0 ]
then
        echo "=================failed!========================================================="
        exit 1
fi

echo "=================done!========================================================="

echo "=================begin to scp data,process in /home/gbase/gbase_recover_scp.tmp.did=="
echo > /home/gbase/gbase_scp.tmp.did
for i in `cat /home/gbase/gbase_recover_scp.tmp`
do
        while true;
        do
                scp_counter=`ps auxww | grep "scp -r" | grep -v grep | wc -l`
                if [ $scp_counter -lt 16 ]
                then
                        echo $i >> /home/gbase/gbase_scp.tmp.did
                        tbname=`basename $i| awk -F '.' '{print $1}'`
                        dbname=`echo $i | awk -F '/' '{print $(NF-2)}'`
			if [ "$dbname" == "gbase" ];then
				break
			fi
			echo "scp ${local_srcdir}/opt/gnode/userdata/gbase/$dbname/metadata/$tbname.frm $dest_ip:${dest_dir}/opt/gnode/userdata/gbase/$dbname/metadata"
                        scp ${local_srcdir}/opt/gnode/userdata/gbase/$dbname/metadata/$tbname.frm $dest_ip:${dest_dir}/opt/gnode/userdata/gbase/$dbname/metadata
                        if [ $? -ne 0 ]
                        then
                                echo "=================failed!=============move frm==================================="
                                exit 1
                        fi
                        sh -c "scp -r -q ${local_srcdir}/opt/gnode/userdata/gbase/$dbname/metadata/$tbname.GED $dest_ip:${dest_dir}/opt/gnode/userdata/gbase/$dbname/metadata &"
                        sh -c "scp -r -q ${local_srcdir}/opt/gnode/userdata/gbase/$dbname/sys_tablespace/$tbname $dest_ip:${dest_dir}/opt/gnode/userdata/gbase/$dbname/sys_tablespace &"
                        break
                else
                        sleep 1
                fi
        done
done

echo "=================done!========================================================="
