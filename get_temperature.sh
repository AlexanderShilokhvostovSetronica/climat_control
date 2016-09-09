#!/bin/bash

home_dir=`dirname $0`
base_dir="/sys/bus/w1/devices"
aliases="${home_dir}/aliases.conf"
log="${home_dir}/logfile.log"
lock_file="${home_dir}/lockfile.lock"
batch_file=`mktemp`

. ${home_dir}/function

# Checking that only one instance is running
if [ -e ${lock_file} ] && kill -0 `cat ${lock_file}`; then
    echo "already running" >> ${log}
    exit
fi

echo $$ > ${lock_file}

trap "rm -f ${lock_file}; rm -f ${batch_file}; echo -e \"=== Stop $0 ===\n\" >> ${log}; exit" INT TERM EXIT

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

    while [ ${t} -eq -62 -o ${t} -eq 85000 -o ${t} -eq -125 -o ${t} -eq 1 -o ${t} -eq 1000 ]; do

        echo -e "Sensor: ${sensor}, Alias: ${alias}, Value: ${t}, count ${count}" >> ${log}

        if [ ${count} -eq ${timeout} ]; then
            break
        fi

        count=$(($count+1));

        sleep 1

        t=`cat ${base_dir}/${sensor}/w1_slave | grep "t=" | cut --delimiter== -f 2`

    done

    if [ ${t} -eq -62 -o ${t} -eq 85000 -o ${t} -eq -125 -o ${t} -eq 1 -o ${t} -eq 1000 ]; then
        echo -e "Sensor: ${sensor}, Alias: ${alias}, Value: ${t}, after count ${count}, not push to zabbix" >> ${log}
        break
    fi

    num=`wcalc -q ${t}/1000`

    if [ ${num%%.*} -le -20 -o ${num%%.*} -ge 40 ]; then
        echo -e "Sensor: ${sensor}, Alias: ${alias}, Value: ${num}, not between -20 / +40, not push to zabbix" >> ${log}
        break
    fi

    echo -e "Sensor: ${sensor}, Alias: ${alias}, Result value: ${num}" >> ${log}
    echo "Lemaker ${alias} ${num}" >> ${batch_file}
done

send_batch_data ${batch_file}
