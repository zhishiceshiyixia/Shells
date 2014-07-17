ps -ef|grep nmon_x86_64_sles11 |grep -v grep |awk '{print $2}' |xargs kill -9
/opt/nmon/nmon_x86_64_sles11 -f -N -m /opt/nmon/nmon_data -s 30 -c 2880
find /opt/nmon/nmon_data -name "*.nmon" -mtime +20 -exec rm {} \;
