#!/bin/bash

home_dir=`dirname $0`
log="${home_dir}/cheching.log"
lock_file="${home_dir}/cheching.lock"

. ${home_dir}/function

# Checking that only one instance is running
if [ -e ${lock_file} ] && kill -0 `cat ${lock_file}`; then
    echo "already running" >> ${log}
    exit
fi

echo $$ > ${lock_file}

trap "rm -f ${lock_file}; rm -f ${batch_file}; echo -e \"=== Stop $0 ===\n\" >> ${log}; exit" INT TERM EXIT

echo -e "=== Start $0 ===\n`date`" >> ${log}

if [ `tail -5 ${home_dir}/logfile.log | grep -c "already running"` -gt 4 ]; then
    echo WARNING >> ${log};

    pid_file=`cat /home/ashilokhvostov/climate_control/lockfile.lock`
    to_kill=`pstree -p ${pid_file} | sed 's/(/\n(/g' | grep '(' | sed 's/(\(.*\)).*/\1/' | tail -3 | sort -r | xargs`
    echo "Processes to kill: ${to_kill}" >> ${log}
    kill ${to_kill} >> ${log}
    sleep 1
    echo "Checking processes after killing" >> ${log}
    for proc in ${to_kill}; do
        kill -0 ${proc} > /dev/null 2>&1
            if [ "$?" -eq "1" ]; then
                echo -e "\tprocess ${proc} killed" >> ${log}
            else
                echo -e "\tprocess ${proc} still alive" >> ${log}
            fi
    done
else
    echo "No sleeping processes, OK."
fi
