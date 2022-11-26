#!/bin/bash

#Turn off both pin's
#echo -e '\x11' | dd of=output bs=1 count=1
#Turn on both pin's
#echo -e '\x00' | dd of=output bs=1 count=1
#setting PIOA pin
#echo -e '\x5A' | dd of=rw bs=1 count=1
#echo -e '\x01' | dd of=rw bs=1 count=1


#Для того что бы "зажечь" оба светодиода необходимо находясь в этой директории ввести команду 
#echo -e '\x00' |dd of=./output bs=1 count=1 
#Для того что бы оба выхода погасить - команду
#echo -e '\x03' |dd of=./output bs=1 count=1
#X03 это шестнадцатиричное число, при переводе в двоичное равное 11
#00 - в двоичное получается 00
#последняя цифра отвечает за PIO A
#предпоследняя за PIO B
#То есть для того что бы PIO A зажечь, а PIO B погасить нужно отправить число 02
#Когда выход в положении 0, светодиод горит (происходит замыкание на 0 второго контакта светодиода подключенного к ds2413) 
#http://www.avtomatika-pro.ru/articles/235483.html
#http://www.avtomatika-pro.ru/articles/214652.html

#Shell:~$ echo -e '\x00' |dd of=/sys/bus/w1/devices/3a-00000002f140/output
#Set port A=0, B=0 (b=00000000 h=00) 

#Set port A=1, B=0 (b=00000001 h=01)
#Shell:~$ echo -e '\x01' |dd of=/sys/bus/w1/devices/3a-00000002f140/output

#Shell:~$ echo -e '\x02' |dd of=/sys/bus/w1/devices/3a-00000002f140/output
#Set port A=0, B=1 (b=00000010 h=02)

#Shell:~$ echo -e '\x03' |dd of=/sys/bus/w1/devices/3a-00000002f140/output
#Set port A=1, B=1 (b=00000011 h=03)



home_dir=`dirname $0`
log="${home_dir}/state.log"
lock_file="${home_dir}/state.lock"

. ${home_dir}/function

# Checking that only one instance is running
if [ -e ${lock_file} ] && kill -0 `cat ${lock_file}`; then
    echo "already running" >> ${log}
    exit
fi

echo $$ > ${lock_file}

trap "rm -f ${lock_file}; exit" INT TERM EXIT

up_down="/sys/bus/w1/devices/3a-0000000a43eb/output"
hold="0.05"
count=0

# The temperature value to start heating
# !!! CHANGE before run this script !!!
current_state=$(get_current_temp)
# The temperature value to stop heating
end_state=$(get_end_temp)
delta_state=`echo $((${end_state}-${current_state}))`

now_time=`date +%s`
end_time=`date -d"2022-11-19 14:00:00" +%s`
delta_time=`echo $((${end_time}-${now_time}))`

if [ ${delta_time} -lt 0 ]; then echo "Error with date time, please check the 'end_time' value"; exit 1; fi

time_sleep=$((${delta_time}/${delta_state}))

function _click {

    local _action=$1; shift
    local _device=$1

    let count+=1
    echo -e "\x${_action}"| dd of=${_device} bs=1 count=1 2>&1 > /dev/null
    while [ $? -ne 0 ]; do
        sleep ${hold}
        if [ $count -eq 5 ]; then echo "ERROR !"; exit 1; fi
        _click ${_action} ${_device}
    done

}

function UP {

    _click 10 ${up_down}
    _click 11 ${up_down}

}

function DOWN {

    _click 01 ${up_down}
    _click 11 ${up_down}

}


function MAKE_WARMER {
    for i in `seq 1 ${delta_state}`; do
        echo "[Info] Push the button 'UP'"
        UP #wakeup
        sleep 0.2
        UP #change state
        increase_current_temp
        sleep ${time_sleep}
    done
}

function UP_ON_TWO {

    UP #wakeup
    sleep 0.5
    UP # up to 1 C

}

# ============ MAIN =============

MAKE_WARMER

#UP_ON 2
