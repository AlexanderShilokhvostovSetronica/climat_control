#!/bin/bash

#Turn off both pin's
#echo -e '\x11' |dd of=output bs=1 count=1
#Turn oo both pin's
#echo -e '\x00' |dd of=output bs=1 count=1


UP="/sys/bus/w1/devices/3a-00000027d55c/output"
hold="0.05"

# The temperature value to start heating
# !!! CHANGE before run this script !!!
begine_state=12
# The temperature value to stop heating
end_state=25
delta_state=`echo $((${end_state}-${begine_state}))`

now_time=`date +%s`
end_time=`date -d"2016-11-12 14:00:00" +%s`
delta_time=`echo $((${end_time}-${now_time}))`

time_sleep=$((${delta_time}/${delta_state}))

function PUSH_UP {
    echo -e '\x10' | dd of=${UP} bs=1 count=1
    sleep ${hold}
    echo -e '\x11' | dd of=${UP} bs=1 count=1
}

function MAKE_WARMER {
    for i in `seq 1 ${delta_state}`; do
        echo "[Info] Push the button 'UP'"
        PUSH_UP #wakeup
        sleep 0.2
        PUSH_UP #change state
        sleep ${time_sleep}
    done
}

function UP_ON_TWO {

    PUSH_UP #wakeup
    sleep 0.2
    PUSH_UP # up to 1 C
    sleep 0.2
    PUSH_UP # up to 1 C

}

# ============ MAIN =============

MAKE_WARMER
