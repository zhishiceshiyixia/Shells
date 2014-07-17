#!/bin/bash

find /backup/data/20140307/${HOSTNAME}_`hostname -i`/database -name "p_*.tgz"|grep -v gcluster.tgz|while read tgz_file
 do 
 while [ 1 ]
 do
        if [ `ps -ef | grep "tar tvf"|grep -v grep|wc -l` -lt 10 ];then
                tar tvf $tgz_file|grep -v '^d'|awk '{print $1,$2,$3,$4,$5,$6}'>/home/gbase/tar_file_dir/`basename $tgz_file|awk -F '.' '{print $1}'`.txt
                break
         else
                sleep 1
         fi
        done
done
