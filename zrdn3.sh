#!/bin/bash

if [ $EUID == 0 ]
then
    echo "Запуск с правами администратора запрещён"
    exit 1
fi

if [ "$(uname -s)" != "Linux" ] 
then
    echo "ОС отлична от Linux"
    # exit 1
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

targetsDir=/tmp/GenTargets/Targets/
destroyDir=/tmp/GenTargets/Destroy/
zrdnFile=temp/zrdn3.txt
lastTargetsFile=temp/lastTargetsZrdn3.txt
temp=temp/tempFileZrdn3.txt
attack=temp/attackZrdn3.txt
destroyDirContent=temp/destroyDirContentZrdn3

messFile=messages/zrdn3.txt
pingFile=messages/pingZrdn3.txt

zrdnX=5500000
zrdnY=3700000
zrdnR=550000    

rockets=20
printNoRockets=1

get_speed() {
	speed=`echo "sqrt(($1-$3)^2+($2-$4)^2)" | bc`
}

encodedSend() {
	a="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ :абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ0123456789"
	b="pqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ#@абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ0123456789abcdefghijklmno"
	echo $1 | sed "y/$a/$b/" >> $messFile
}

: >$zrdnFile
: >$lastTargetsFile
: >$temp
: >$attack
: >$destroyDirContent
# : >$messFile
while :
do
	sleep 0.2
	if [[ $(cat $pingFile) == "ping" ]]
	then
		echo "live" > $pingFile
	fi
	ls $DestroyDir > $destroyDirContent
	for fileName in $(ls -t $targetsDir | head -30 2>/dev/null)
	do
		foundFile=`grep $fileName $lastTargetsFile 2>/dev/null`
		targetID=${fileName:12:6}

		if [[ $foundFile != "" ]]
		then
			continue
		fi
		
		echo $fileName >> $lastTargetsFile
		coords=`cat ${targetsDir}$fileName 2>/dev/null`
		X_with_letter=`expr match "$coords" '\(X[0-9]*\)'`
		X=${X_with_letter:1}
		Y_with_letter=`expr match "$coords" '.*\(Y[0-9]*\)'`
		Y=${Y_with_letter:1}

		get_speed $zrdnX $zrdnY $X $Y
		if (( $speed < $zrdnR ))
		then
			lastInfo=$(grep $targetID $zrdnFile)
			if [[ $lastInfo == "" ]]
			then
				echo "$targetID 0 0 $X $Y" >> $zrdnFile
				continue
			fi
			isSecond=$(grep "$targetID 0 0" $zrdnFile)
			lastX=`echo $lastInfo | cut -f 4 -d " "`
			lastY=`echo $lastInfo | cut -f 5 -d " "`
			sed "/$targetID/d" $zrdnFile > $temp
			cat $temp > $zrdnFile
			echo "$targetID $lastX $lastY $X $Y " >> $zrdnFile
			get_speed $lastX $lastY $X $Y
			if (( $speed < 1000 ))
			then
				if (( $speed >= 250 ))
				then
					targetName="Крылатая ракета"
				else
					targetName="Самолёт"
				fi
				alreadyAttacked=`grep $targetID $destroyDirContent 2>/dev/null`
				if [[ $alreadyAttacked == "" ]]
				then
					foundAttackedTarget=`grep $targetID $attack`
					if [[ $foundAttackedTarget == "" ]]
					then
						if [[ $isSecond != "" ]]
						then
							encodedSend "Обнаружена цель $targetName ID:$targetID с координатами $X $Y"
						fi
					else
						encodedSend "Промах по цели ID:$targetID"
					fi
					if [[ $rockets > 0 ]]
					then
						let rockets=$rockets-1
						encodedSend "Стрельба по цели ID:$targetID"
						if [[ $foundAttackedTarget == "" ]]
						then
							echo "$targetID" >> $attack
						fi
						: >$destroyDir$targetID
					elif [[ $printNoRockets == 1 ]]
					then
						encodedSend "Противоракеты закончились"
						printNoRockets=0
					fi
				fi
			fi
		fi
	done
	for targ in $(cat $attack)
	do
		ls -t $targetsDir | head -30 > $temp 2>/dev/null
		foundAttackedTarget=`grep $targ $temp 2>/dev/null`
		if [[ $foundAttackedTarget == "" ]]
		then
			encodedSend "Цель ID:$targ уничтожена"
			sed "/$targ/d" $attack > $temp
			cat $temp > $attack
		fi
	done
done