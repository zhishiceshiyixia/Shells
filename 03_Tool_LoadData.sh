#!/bin/bash
##--------------------------------------------##
#Creater: Nie Dan
#Create Data: 2014-5-27
#Description: This script is a template of load data
#Config: table.lst
#Version: 1.0
##-------------------------------------------_##
DISP_SERVER_DIR=./dispatch_server
DISP_SERVER_PORT=6666
DISP_SERVER_LOG_FILE=/tmp/dispserver.log
DISP_SERVER_LOADER_DIR=/tmp
DISP_CLI_DIR=./dispatch_server
DISP_CLI_HOST=
DISP_CLI_LOG_FILE=/tmp/dispcli.log
DISP_CLI_UNAME=root
DISP_CLI_PWD=1
CTL_SERVER_IP=192.168.137.132:$DISP_SERVER_PORT
CTL_FORMAT=3
CTL_DBNAME=ssbm
CTL_DELIMITER='|'
CTL_FILE_LIST_DIR=/home/gbase/load_data/SSB/data
CTL_FILE_LIST_FILE=
NOW_DIR=`pwd`
LOAD_TEMP_LOG=load_template.log
BACK_DIR_TBL=${NOW_DIR}/backup_load/tbl/
BACK_DIR_CTL=${NOW_DIR}/backup_load/ctl/
TABLE_LST=./table.lst
usage(){
        echo "This script is a temppate of load data. Plz modify the paramerters in file before run the script. Pay attention to the parameter CTL_FILE_LIST_FILE, it is  make up by CTL_FILE_LIST_DIR and table names. If your source data files are not  named by table name, plz atler the while loop. 
        usage: [FILE] 
        sh Gbase_03_Tool_LoadData.sh table.lst
        parameter [FILE] is the list of table names which will be inserted later, default is ./table.lst"
}
Create_CTL_template()
{
	echo "[test]" > ${NOW_DIR}/template.ctl
	echo "disp_server=${CTL_SERVER_IP}" >> ${NOW_DIR}/template.ctl
	echo "format=${CTL_FORMAT}" >> ${NOW_DIR}/template.ctl
	echo "db_name=${CTL_DBNAME}" >> ${NOW_DIR}/template.ctl
	echo "delimiter='${CTL_DELIMITER}'" >> ${NOW_DIR}/template.ctl
	echo "socket=/tmp/gbase_8a_5050.sock" >> ${NOW_DIR}/template.ctl
	
}

Execute_load(){
	rm ${NOW_DIR}/${LOAD_TEMP_LOG} -r 2>/dev/null
while read tbname 
do
	cat ./template.ctl > ./load_$tbname.ctl
	CTL_FILE_LIST_FILE=${CTL_FILE_LIST_DIR}/${tbname}.tbl
	echo "file_list=${CTL_FILE_LIST_FILE}">> ./load_$tbname.ctl
	echo "table_name=$tbname" >> ./load_$tbname.ctl
	if [ -z ${DISP_CLI_HOST} ]; then
		TEMP_HOST_DIR=
	else
		TEMP_HOST_DIR=-h${DISP_CLI_HOST}
	fi
	echo "[`date +%F' '%R:%S`]===============Start to load table $tbname===============" | tee -a ${NOW_DIR}/${LOAD_TEMP_LOG}
	start_time=`date +%s`
	${DISP_CLI_DIR}/dispcli -t360 -u${DISP_CLI_UNAME} -p${DISP_CLI_PWD} ${TEMP_HOST_STR}  --log-file=${DISP_CLI_LOG_FILE} load_$tbname.ctl | grep finished | grep -v SYSTEM >> ${NOW_DIR}/temp.log 
	load_status=$?
	current_num=`cat ${NOW_DIR}/temp.log | awk -F':' '{print $2}' | awk '{print $2}'`
	current_skip=`cat ${NOW_DIR}/temp.log | awk -F':' '{print $2}' | awk '{print $5}'`
	end_time=`date +%s`
	if [  $load_status -eq 0 ]; then
		echo "End of load table $tbname, using $[${end_time} - ${start_time}]s, load status is SUCCESS, ${current_num} records inserted, ${current_skip} records skiped " | tee -a ${NOW_DIR}/${LOAD_TEMP_LOG}
	else
		echo -ne "End of load table $tbname, using $[${end_time} - ${start_time}]s, load status is ERROR ${current_num} records inserted, ${current_skip} records skiped.\n See details in log ${DISP_CLI_LOG_FILE}, TBL file is at ${CTL_FILE_LIST_FILE}, ctl file is at ./load_$tbname.ctl\n" | tee -a ${NOW_DIR}/${LOAD_TEMP_LOG}
	fi
	echo "[`date +%F' '%R:%S`]===============end of load table $tbname===============" | tee -a ${NOW_DIR}/${LOAD_TEMP_LOG}
done<${TABLE_LST}
	rm ${NOW_DIR}/temp.log -r 2>/dev/null
}


if [ $# -eq 1  ]; then
	TABLE_LST=$1
	Create_CTL_template
	Execute_load
elif [ $# -eq 0 -a -e ./table.lst  ]; then
                echo " using default file ./table.lst"
                TABLE_LST=./table.lst
		Create_CTL_template
		Execute_load
	else
		usage
fi
