#!/bin/bash

home_dir=`dirname $0`
log="${home_dir}/$0.log"
lockfile="${home_dir}/$0.lock"
zabbix_host="Morozovo"
tmp_file="${home_dir}/ups_data"
upsc cyber 2>&1 > ${tmp_file} 2>&1

. ${home_dir}/function

# Checking that only one instance is running
if [ -e ${lockfile} ] && kill -0 `cat ${lockfile}`; then
    echo "already running" >> ${log}
    exit
fi

echo $$ > ${lockfile}

trap "rm -f ${lockfile}; echo -e \"=== Stop $0 ===\n\" >> ${log}; exit" INT TERM EXIT

echo -e "=== Start $0 ===\n`date`" >> ${log}

for point in battery.charge battery.voltage input.voltage output.voltage ups.load; do

    value=`grep "${point}:" ${tmp_file} | sed 's/^.*: //'`
    echo "${point}: ${value}" >> ${log}
    send_data ${zabbix_host} ${point} ${value}

done

rm -f ${tmp_file}
