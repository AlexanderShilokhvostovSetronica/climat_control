#!/bin/bash

set -x

export LANG=en_US.UTF-8
export WWW_HOME="http://lk.megafon.ru"

home_dir=`dirname $0`
log="${home_dir}/$0.log"
lockfile="${home_dir}/$0.lock"
dump_site="${home_dir}/info_site"
all_traff=70
zabbix_host="Morozovo"

. ${home_dir}/function

# Checking that only one instance is running
if [ -e ${lockfile} ] && kill -0 `cat ${lockfile}`; then
    echo "already running" >> ${log}
    exit
fi

echo $$ > ${lockfile}

trap "rm -f ${lockfile}; echo -e \"=== Stop $0 ===\n\" >> ${log}; exit" INT TERM EXIT

echo -e "=== Start $0 ===\n`date`" >> ${log}

lynx -dump ${WWW_HOME} > ${dump_site}

#rest=`grep " Остаток " ${dump_site} | sed 's/^.* Остаток \(.*\) Мб .*$/\1/'`
#used=`wcalc -q ${all_traff}-${rest}`
#total=`wcalc -q ${used}/${all_traff}*100`

#echo "Internet trafic: used ${total} %" >> ${log}
#send_data internet.trafic ${total}

balance=`grep -i -A1 "баланс" ${dump_site} | xargs | sed 's/^.*аланс \(.*\) .*$/\1/;s/,/\./'`
if [ ${#balance} -gt 0  ]; then
    echo "Balance: ${balance} rub" >> ${log}
    send_data ${zabbix_host} internet.balance ${balance}
else
    echo "No data found" >> ${log}
fi

rm -f ${dump_site}