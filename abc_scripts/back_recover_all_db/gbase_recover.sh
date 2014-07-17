#!/bin/sh
if [ $# != 2 ]
then
        echo "gbase_recover.sh srcdir destdir"
        exit 1
fi

srcdir=$1
destdir=$2



if [ -d $srcdir ]
then
        echo "source diretory is :"$srcdir
else
        echo "=================failed!==$srcdir is not a directoty========="
        exit 1
fi

if [ -d $destdir ]
then
        echo "dest diretory is :"$destdir
else
        echo "=================failed!==$destdir is not a directoty========="
        exit 1
fi

ls $srcdir |while read file_name
do
	if [ -d $file_name ] && [ "$file_name" != "gcluster" ];then
		rm -rf ${destdir}/opt/gnode/userdata/gbase/$file_name/{metadata,sys_tablespace}
		mkdir -p ${destdir}/opt/gnode/userdata/gbase/$file_name/{metadata,sys_tablespace}
		cp $srcdir/metadata/db.opt ${destdir}/opt/gnode/userdata/gbase/$file_name/metadata/
	fi
done

find $srcdir -name "*.tgz" >/home/gbase/gbase_recover.tmp

echo > /home/gbase/gbase_recover.did
cat /home/gbase/gbase_recover.tmp |while read file
	do
		echo $file >>/home/gbase/gbase_recover.did
		while [ 1 ]
		do
		if [ `ps -ef | grep "tar xvf"|grep -v grep|wc -l` -lt 10 ];then
			sh -c "tar xf $file -C ${destdir} &"
			break
		else
			sleep 1
		fi
	done


done

echo "recover db end!"


