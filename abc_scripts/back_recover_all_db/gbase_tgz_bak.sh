#!/bin/sh
if [ $# != 1 ]
then
	echo "gbase_tgz.sh destdir"
	exit 1
fi

destdir=$1

if [ -d $destdir ]
then
	echo "destination diretory is :"$destdir
else
	echo "=================failed!==$destdir is not a directoty========="
	exit 1
fi

echo "=================find the $slice into /home/gbase/gbase_tgz.tmp==============="
find /opt/gnode/userdata/gbase -name "*.frm" | grep -v grep | grep -v gctmpdb > /home/gbase/gbase_tgz.tmp
if [ $? -ne 0 ]
then
	ret=$?
	echo "=================failed!========================================================="
	exit $ret
fi
echo "=================done!========================================================="

mkdir -p $destdir/gcluster
if [ $? -ne 0 ]
then
	ret=$?
	echo "=================failed!====mkdir -p $destdir/gcluster======================"
	exit $ret
fi

sh -c "tar czf $destdir/gcluster.tgz /opt/gcluster/userdata/gcluster &"

echo > /home/gbase/gbase_tgz.tmp.did

echo "=================begin to tgz data,process in /home/gbase/gbase_tgz.tmp.did=="
for i in `cat /home/gbase/gbase_tgz.tmp`
do 
	while true
	do
		cp_counter=`ps auxww | grep "tar czf" | grep -v grep | wc -l`
		if [ $cp_counter -lt 4 ]
		then
			echo $i >> /home/gbase/gbase_tgz.tmp.did
			tbname=`echo $i | awk -F '/' '{print $8}' | awk -F '.' '{print $1}'`
			dbname=`echo $i | awk -F '/' '{print $6}'`
			
			if [ $dbname = "gbase" ]
			then
				break;
			fi

			mkdir -p $destdir/$dbname/metadata
			if [ $? -ne 0 ]
			then
				ret=$?
				echo "=================failed!====mkdir -p $destdir/$dbname/metadata======================"
				exit $ret
			fi
			
			mkdir -p $destdir/$dbname/sys_tablespace
			if [ $? -ne 0 ]
			then
				echo "=================failed!====mkdir -p $destdir/$dbname/sys_tablespace================"
				exit 1
			fi

			if [ ! -e $destdir/$dbname/metadata/db.opt ] 
			then
				cp /opt/gnode/userdata/gbase/$dbname/metadata/db.opt $destdir/$dbname/metadata
				if [ $? -ne 0 ]
				then
					echo "=================failed!==========cp db.opt========================================"
					exit 1
				fi
			fi
			sh -c "tar czf $destdir/$dbname/metadata/${tbname}_meta.tgz /opt/gnode/userdata/gbase/$dbname/metadata/${tbname}.* &"
			sh -c "tar czf $destdir/$dbname/sys_tablespace/${tbname}_data.tgz /opt/gnode/userdata/gbase/$dbname/sys_tablespace/${tbname} &"

			break
		else
			sleep 1
		fi
	done
done 
echo "=================done!========================================================="
echo "=================tar gbase dir================================================"
tar czf $destdir/gbase.tgz /opt/gnode/userdata/gbase/gbase /opt/gnode/userdata/gbase/express.seq
echo "=================done!========================================================="
