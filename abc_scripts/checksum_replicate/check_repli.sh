#!/bin/bash
cat tables.txt |while read table_name
do
mkdir -p /tmp/abc/chk/checksum_replicate/${table_name}
checksum dwgd ${table_name} -v  >/tmp/abc/chk/checksum_replicate/${table_name}/`hostname -i`_checkout
done
