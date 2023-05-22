elements=( "GenTargets" "kp" "rls1" "rls2" "rls3" "spro" "zrdn1" "zrdn2" "zrdn3" )
elementsOnRussian=( "Генератор целей" "КП" "РЛС1" "РЛС2" "РЛС3" "СПРО" "ЗРДН1" "ЗРДН2" "ЗРДН3" )

if [ "$1" == "start" ]
then
    if [ "$2" == "all" ]
    then
        for ((i=0; i<${#elements[*]}; i++))
        do
            ./${elements[$i]}.sh & 2>/dev/null
            sleep 0.1
        done
        echo "Системы запущены"
    else
        for ((i=0; i<${#elements[*]};i++))
        do
            if [ "$2" == ${elements[$i]} ]
            then
                ./${elements[$i]}.sh & 2>/dev/null
                sleep 0.1
                echo "Система '${elementsOnRussian[$i]}' запущена"
                break
            fi
        done
    fi
elif [ "$1" == "stop" ]
then
    if [ "$2" == "all" ]
    then
        for ((i=0; i<${#elements[*]}; i++))
        do
            kill -9 $(ps aux | grep "${elements[$i]}" | grep -v "grep" | tr -s ' ' | cut -d ' ' -f 2) &>/dev/null
            sleep 0.1
        done
        echo "Системы отключены"
    else
        for ((i=0; i<${#elements[*]};i++))
        do
            if [ "$2" == ${elements[$i]} ]
            then
                kill -9 $(ps aux | grep "${elements[$i]}" | grep -v "grep" | tr -s ' ' | cut -d ' ' -f 2) &>/dev/null
                sleep 0.1
                echo "Система '${elementsOnRussian[$i]}' отключена"
                break
            fi
        done
    fi
else
    echo "Введен недопустимый параметр"
fi