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


_device="/sys/bus/w1/devices/3a-0000000a7c46/output"
hold="0.05"
count=0

#_action=10
#    echo -e "\x${_action}"| dd of=${_device} bs=1 count=1 2>&1 > /dev/null
#    while [ $? -ne 0 ]; do
#        sleep ${hold}
#        if [ $count -eq 5 ]; then echo "ERROR !"; exit 1; fi
#        _click ${_action} ${_device}
#    done


#_action=11
#    echo -e "\x${_action}"| dd of=${_device} bs=1 count=1 2>&1 > /dev/null
#    while [ $? -ne 0 ]; do
#        sleep ${hold}
#        if [ $count -eq 5 ]; then echo "ERROR !"; exit 1; fi
#        _click ${_action} ${_device}
#    done





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

_click 10 ${_device}
sleep ${hold}
_click 11 ${_device}

