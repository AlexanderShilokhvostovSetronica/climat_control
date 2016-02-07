#!/bin/bash

. function

log=ups.log
tmp_file="ups_data"
upsc cyber 2>&1 > ${tmp_file} 2>&1

echo `date` >> ${log}

for point in battery.charge battery.voltage input.voltage output.voltage ups.load; do

    value=`grep "${point}:" ${tmp_file} | sed 's/^.*: //'`
    echo "${point}: ${value}" >> ${log}
    send_data ${point} ${value}

done
echo >> ${log}

rm -f ${tmp_file}
