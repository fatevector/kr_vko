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
rlsFile=temp/rls3.txt
lastTargetsFile=temp/lastTargetsRls3.txt
temp=temp/tempFileRls3.txt

messFile=messages/rls3.txt
pingFile=messages/pingRls3.txt

rlsX=7000000
rlsY=5000000
azimuth=45

maxDist=7000000
viewingAngle=45

sproX=3200000
sproY=3000000
sproR=1300000

alpha1=`echo "(450-$azimuth-$viewingAngle)%360" | bc`
alpha2=`echo "(450-$azimuth+$viewingAngle)%360" | bc`

encodedSend() {
	a="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ :абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ0123456789"
	b="pqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ#@абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ0123456789abcdefghijklmno"
	echo $1 | sed "y/$a/$b/" >> $messFile
}

get_speed() {
	speed=`echo "sqrt(($1-$3)^2+($2-$4)^2)" | bc`
}

get_to_sector() {
	in_sector=0
	get_speed $1 $2 $3 $4
	if (( $speed <= $maxDist ))
	then
		tempX=`echo "$3-$1" | bc`
		tempY=`echo "$4-$2" | bc`
		phi=`echo "scale=4; a($tempY/$tempX) * 180 / 3.141592653" | bc -l`

		if [ "$tempX" -gt 0 ] && [ "$tempY" -lt 0 ]
		then
			phi=`echo "$phi+360" | bc -l`
		elif [ "$tempX" -lt 0 ]
		then
			phi=`echo "$phi+180" | bc -l`
		fi
		
		if (( $alpha1 < $alpha2 ))
		then
			if (( `echo "$phi>$alpha1" | bc -l` )) && (( `echo "$phi<$alpha2" | bc -l` ))
			then
				in_sector=1
			fi
		else
			if (( `echo "$phi>$alpha2" | bc -l` )) || (( `echo "$phi<$alpha1" | bc -l` ))
			then
				in_sector=1
			fi
		fi
	fi
}

get_to_spro() {
	in_spro=0
	get_speed $sproX $sproY $1 $2
	d1=$speed
	get_speed $sproX $sproY $3 $4
	d2=$speed
	if (( $d2 < $d1 ))
	then
		k=`echo "($4-$2)/($3-$1)" | bc -l`
		b=`echo "$2- $k*$1" | bc -l`
		d=`echo "(- $k*$sproX+$sproY- $b)/(sqrt($k*$k+1))" | bc -l`
		d=`echo ${d#-}`
		if (( `echo "$d<$sproR" | bc -l` ))
		then
			in_spro=1
		fi
	fi
}

: >$rlsFile
: >$lastTargetsFile
: >$temp
# : >$messFile
while :
do
	sleep 0.2
	if [[ $(cat $pingFile) == "ping" ]]
	then
		echo "live" > $pingFile
	fi
	for fileName in $(ls -t $targetsDir | head -30 2>/dev/null)
	do
		foundFile=`grep $fileName $lastTargetsFile 2>/dev/null`
		if [[ $foundFile != "" ]]
		then
			continue
		fi
		echo $fileName >> $lastTargetsFile
		coords=`cat ${targetsDir}$fileName 2>/dev/null`
		targetID=${fileName:12:6}
		X_with_letter=`expr match "$coords" '\(X[0-9]*\)'`
		X=${X_with_letter:1}
		Y_with_letter=`expr match "$coords" '.*\(Y[0-9]*\)'`
		Y=${Y_with_letter:1}

		get_to_sector $rlsX $rlsY $X $Y
		if (( $in_sector == 1 ))
		then
			lastInfo=$(grep $targetID $rlsFile)
			if [[ $lastInfo == "" ]]
			then
				echo "$targetID 0 0 $X $Y" >> $rlsFile
				continue
			fi
			firstPart=$(grep "$targetID 0 0" $rlsFile)
			if [[ $firstPart == "" ]]
			then
				continue
			fi

			lastX=`echo $lastInfo | cut -f 4 -d " "`
			lastY=`echo $lastInfo | cut -f 5 -d " "`
			sed "/$targetID/d" $rlsFile > $temp
			cat $temp > $rlsFile
			echo "$targetID $lastX $lastY $X $Y " >> $rlsFile
			get_speed $lastX $lastY $X $Y
			if (( $speed >= 8000 ))
			then
				encodedSend "Обнаружена цель ID:$targetID с координатами $X $Y"
				get_to_spro $lastX $lastY $X $Y
				if (( $in_spro == 1 ))
				then
					encodedSend "Цель ID:$targetID движется в направлении СПРО"
				fi
			fi
		fi
	done
done