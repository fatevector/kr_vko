#!/bin/bash

if [ $EUID == 0 ]
then
    echo "Запуск с правами администратора запрещён"
    exit 1
fi

if [ "$(uname -s)" != "Linux" ] 
then
    echo "ОС отлична от Linux"
    exit 1
fi

if [ "$SHELL" != "/bin/bash" ]
then 
    echo "Командный интерпретатор отличен от Bash"
    exit 1
fi

name=$(echo $0 | rev | cut -d '/' -f 1 | cut -d '.' -f 2 | rev)
if [ $(ps aux | grep "$name" | grep -v "grep" | wc -l) -gt 2 ]
then
    echo "Один экземпляр $0 уже запущен"
    exit 1
fi

period=30
time=0
decodedLine=""

pingFile=( messages/pingRls1.txt messages/pingRls2.txt messages/pingRls3.txt messages/pingZrdn1.txt messages/pingZrdn2.txt messages/pingZrdn3.txt messages/pingSpro.txt)
logFile=( logs/rls1.txt logs/rls2.txt logs/rls3.txt logs/zrdn1.txt logs/zrdn2.txt logs/zrdn3.txt logs/spro.txt)
tableName=( log_rls1 log_rls2 log_rls3 log_zrdn1 log_zrdn2 log_zrdn3 log_spro )
messFile=( messages/rls1.txt messages/rls2.txt messages/rls3.txt messages/zrdn1.txt messages/zrdn2.txt messages/zrdn3.txt messages/spro.txt)
objectName=( "РЛС1" "РЛС2" "РЛС3" "ЗРДН1" "ЗРДН2" "ЗРДН3" "СПРО" )
status=( 0 0 0 0 0 0 0 )
N=( 0 0 0 0 0 0 0 )

for ((i=0; i<7; i++))
do
    : >${pingFile[$i]}
    : >${logFile[$i]}
done

pingStatus=$period
mainLog=logs/mainLog.txt
tempNewData=temp/tempNewData
: >$mainLog
: >$tempNewData

getTime() {
    time=$(date +"%d.%m %H:%M:%S")
}

printLog() {
    echo $1 >> $2
    echo $1 >> $mainLog
    sqlite3 db/log.db "INSERT INTO log_main (mess) VALUES ('$1')"
    sqlite3 db/log.db "INSERT INTO $3 (mess) VALUES ('$1')"
}

decode() {
    a="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ :абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ0123456789"
    b="pqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ#@абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ0123456789abcdefghijklmno"
    decodedLine=$(echo $1 | sed "y/$b/$a/")
}

if [ ! -f db/log.db ]; then
    sqlite3 db/log.db < db/createLogTable.sql
fi

while :
do
    for ((i=0; i<7; i++))
    do
        if [ $pingStatus -ge $period ]; then
            echo "ping" > ${pingFile[$i]}
            if [[ $i -eq 6 ]]; then
                pingStatus=0
            fi
        elif [ $pingStatus -ge 4 ]; then
            if [ "$(cat ${pingFile[$i]})" == "live" ]; then
                if [[ ${status[$i]} == 0 ]]
                then
                    getTime
                    printLog "$time ${objectName[$i]} работоспособность восстановлена" ${logFile[$i]} ${tableName[$i]} 
                fi
                status[$i]=1
                currSize=$(cat ${messFile[$i]} | wc -l)
                if [[ $currSize -gt ${N[$i]} ]]
                then
                    cat ${messFile[$i]} | tail -n $(expr $currSize - ${N[$i]}) > $tempNewData
                    while read line
                    do
                        getTime
                        decode "$line"
                        printLog "$time ${objectName[$i]} $decodedLine" ${logFile[$i]} ${tableName[$i]} 
                    done < $tempNewData
                    N[$i]=$currSize
                fi
            else
                if [[ ${status[$i]} == 1 ]]
                then
                    getTime
                    printLog "$time ${objectName[$i]} не работает" ${logFile[$i]} ${tableName[$i]} 
                fi
                status[$i]=0
            fi
        fi
    done
    ((pingStatus++))
    sleep 0.5
done