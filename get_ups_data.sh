#!/bin/bash

home_dir=`dirname $0`
log="${home_dir}/$0.log"
lockfile="${home_dir}/$0.lock"
zabbix_host="Morozovo"
tmp_file=`mktemp`
batch_file=`mktemp`

upsc cyber 2>&1 > ${tmp_file} 2>&1

. ${home_dir}/function

# Checking that only one instance is running
if [ -e ${lockfile} ] && kill -0 `cat ${lockfile}`; then
    echo "already running" >> ${log}
    exit
fi

echo $$ > ${lockfile}

trap "rm -f ${lockfile} ${tmp_file} ${batch_file}; echo -e \"=== Stop $0 ===\n\" >> ${log}; exit" INT TERM EXIT

echo -e "=== Start $0 ===\n`date`" >> ${log}

for point in battery.charge battery.voltage input.voltage output.voltage ups.load; do

    value=`grep "${point}:" ${tmp_file} | sed 's/^.*: //'`
    if [ ${value} ]; then
        echo "${point}: ${value}" >> ${log}
        echo "${zabbix_host} ${point} ${value}" >> ${batch_file}
    fi

done

if [ -s ${batch_file} ]; then  
    send_batch_data ${batch_file}
else
    echo "No data to be sent" >> ${log}
fi
