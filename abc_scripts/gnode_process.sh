#!/bin/bash

while read node_ip
        do
         /DWGD2/gcluster/server/bin/gbase -ugbase -pgbase20110531 -h $node_ip -P5050 -e "show full processlist" |sed 's/\\n/ /g'|sed 's/\\t/ /g'| while read line  
                                do
				 dtime=`date +%Y-%m-%d' '%H:%M:%S`
                                echo "#$dtime#HOST:$node_ip---------" "$line"
                                done
        done<node_ip.list
