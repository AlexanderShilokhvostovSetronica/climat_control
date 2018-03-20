#!/bin/bash

#Turn off both pin's
#echo -e '\x11' |dd of=output bs=1 count=1
#Turn oo both pin's
#echo -e '\x00' |dd of=output bs=1 count=1


up_down="/sys/bus/w1/devices/3a-00000027d55c/output"
hold="0.05"
count=0

# The temperature value to start heating
# !!! CHANGE before run this script !!!
begine_state=15
# The temperature value to stop heating
end_state=26
delta_state=`echo $((${end_state}-${begine_state}))`

now_time=`date +%s`
end_time=`date -d"2018-03-10 12:00:00" +%s`
delta_time=`echo $((${end_time}-${now_time}))`

time_sleep=$((${delta_time}/${delta_state}))

function _click {

    local _action=$1; shift
    local _device=$1

    let count+=1
    echo -e "\x${_action}"| dd of=${_device} bs=1 count=1
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
        sleep ${time_sleep}
    done
}

function UP_ON_TWO {

    UP #wakeup
    sleep 0.5
    UP # up to 1 C
    sleep 0.5
    UP # up to 1 C

}

# ============ MAIN =============

MAKE_WARMER

#UP_ON_TWO
