#!/bin/bash
tbname_file=$1

sed -n 1p ${tbname_file} && sed -i 1d ${tbname_file}
