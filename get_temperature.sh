#!/bin/bash

home_dir=`dirname $0`
base_dir="/sys/bus/w1/devices"
aliases="${home_dir}/aliases.conf"
log="${home_dir}/$0.log"
lockfile="${home_dir}/$0.lock"
batch_file=`mktemp`
zabbix_host="Morozovo"

. ${home_dir}/function

# Checking that only one instance is running
if [ -e ${lockfile} ] && kill -0 `cat ${lockfile}`; then
    echo "already running" >> ${log}
    exit
fi

echo $$ > ${lockfile}

trap "rm -f ${lockfile}; rm -f ${batch_file}; echo -e \"=== Stop $0 ===\n\" >> ${log}; exit" INT TERM EXIT

echo -e "=== Start $0 ===\n`date`" >> ${log}

if [ ! `which wcalc` ]; then
    echo -e "Please install wcalc.\n\tapt-get install wcalc" | tee -a ${log}
    exit 2
fi

if [ ! `which zabbix_sender` ]; then
    echo -e "Please install zabbix-agent.\n\tapt-get install zabbix-agent" | tee -a ${log}
    exit 2
fi

sensors=(`cat ${base_dir}/w1_bus_master1/w1_master_slaves | grep -v "not found"`)

if [ ${#sensors[*]} -eq 0 ]; then
    echo "Sensors not found" >> ${log}
    exit 0
fi

for sensor in ${sensors[*]}; do
    alias=`grep ${sensor} ${aliases} | awk '{print $2}'`
    if [ -z ${alias} ]; then
        echo -e "${sensor}\t" >> ${aliases}
        alias=${sensor}
    fi

    count=1
    timeout=3

    t=`cat ${base_dir}/${sensor}/w1_slave | grep "t=" | cut --delimiter== -f 2`

    while [ ${t} -eq -125 -o ${t} -eq -62 -o ${t} -eq 85000 ]; do

        echo -e "Sensor: ${sensor}, Alias: ${alias}, Value: ${t}, count ${count}" >> ${log}

        if [ ${count} -eq ${timeout} ]; then
            break
        fi

        count=$(($count+1));

        sleep 1

        t=`cat ${base_dir}/${sensor}/w1_slave | grep "t=" | cut --delimiter== -f 2`

    done

    if [ ${t} -eq -125 -o ${t} -eq -62 -o ${t} -eq 85000 ]; then
        echo -e "Sensor: ${sensor}, Alias: ${alias}, Value: ${t}, after count ${count}, not push to zabbix" >> ${log}
        break
    fi

    num=`wcalc -q ${t}/1000`

    correction=`grep ${sensor} ${aliases} | awk '{print $3}'`

    if [[ -v correction ]]; then
        num=`wcalc -q ${num}${correction}`
    fi

    echo -e "Sensor: ${sensor}, Alias: ${alias}, Result value: ${num}" >> ${log}
    echo "${zabbix_host} ${alias} ${num}" >> ${batch_file}
done

send_batch_data ${batch_file}
