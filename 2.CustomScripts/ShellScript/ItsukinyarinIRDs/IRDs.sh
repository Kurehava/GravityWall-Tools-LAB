roomlist=("3858888" "135001")
LIVING_ROMNUM=();LIVING_STATUS=();LIVING_TARUID=();LIVING_TITLES=();LIVING_UNAMES=();LIVING_TSTAMP=();LIVING_DOWNLV=();
FILEDP_ROMNUM=();FILEDP_UNAMES=();FILEDP_TSTAMP=();RELIVE=0;liveflags=0;secflags=0;clfeflags=0;
clear
#=============Meta Root==============================
#BILI_DIR="/home/nyarin/recordserver/BiliRecorder/"
#DDTV_DIR="/home/nyarin/recordserver/DDTV2/tmp"
#RECORD_DIR="/media/nyarin/Record-DISK/RecordFiles"
#=============Meta Root==============================
BILI_DIR="/home/oriki/recordserver/BiliRecorder/"
DDTV_DIR="/home/oriki/recordserver/DDTV2/tmp"
RECORD_DIR="/media/oriki/GravityWall"
#RECORD_DIR="/home/oriki/wqe"

function header(){
    #从第5行到屏幕底端的范围滚动显示
    echo -ne "\e[5r"
    echo -ne "\e[33m===========================================\n"
    echo -ne "Itsukinyarin Recording and Dumping System >\n"
    echo -ne "Powered by oriki ver.0.9.2                >\n"
    echo -ne "===========================================\e[96m\n"
    echo -ne "\e[5H"
}

function NameConvert(){
    cd "$1"
    FLVw=`echo "$2" | sed 's:\\\::g' | tr -d " ><*+/'#$\""`
    if [ "$4" = "2" ];then
        FLVw="$FLVw/"
    fi
    if [ "$3" = "1" ] && [ "$2" != "$FLVw" ];then
        mv "$2" "$FLVw"
    fi
}

function ProgressBar(){
    i=0
    str=""
    arr=("|" "/" "-" "\\")
    targetDIR="$1"
    filename="$2"
    metasize="$3"
    if [ "`ps -ef | grep -w '[m]v'| awk '{print $2}'`" != "" ];then
        while [ $i -ne 100 ];do
            if [ -d "$targetDIR$filename" ];then
                targsize="`du --max-depth=1 $targetDIR$filename | awk '{print $1}' 2>/dev/null`"
            elif [ -f "$targetDIR$filename" ];then
                targsize="`ls -l "$targetDIR$filename" | awk '{print $5}'`"
            else
                printf "\n\e[1;40;31m[erro]\e[0;0;96m : 目标文件不为文件夹也不为文件，很奇怪，我无法开启进度条显示。\n"
                break 2
            fi
            sleep 1s
            let statsize=$targsize*100/$metasize
            let chkdatas=$i+5
            let index=i%4
            sleep 0.1
            if [ "$statsize" -ge "$chkdatas" ];then
                let i+=5
                str+='='
            fi
            printf "\e[0;96;1m[%-20s][%d%%]%c\r" "$str" "$i" "${arr[$index]}"
        done
        printf "\n"
    else
        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 没有检测到MV命令进程，无法开启进度条显示。\n"
    fi
}

function fakeinfosys(){
    while :;do
        list="`cat test.log | awk '{print $1}'`"
        STATUS="`cat test.log | awk '{print $2}'`"
        TARUID="123456"
        TITLES="AAAA"
        UNAMES="`cat test.log | awk '{print $3}'`"
        #echo status::$STATUS
        #开播状态为1 and 房间号不在开播列表
        if [ "$STATUS" = "1" ] && [[ ! ${LIVING_ROMNUM[@]} =~ $list ]];then
            #开播房间号列表
            LIVING_ROMNUM+=("$list")
            #开播状态列表
            LIVING_STATUS+=("$STATUS")
            #开播用户ID列表(非房间号，为主播UID)
            LIVING_TARUID+=("$TARUID")
            #开播标题
            LIVING_TITLES+=("\"$TITLES\"")
            #开播用户名
            LIVING_UNAMES+=("$UNAMES")
            #开播时间戳
            LIVING_TSTAMP+=("$(date "+%m-%d-%H-%M")")
            if [ $RELIVE = 0 ];then
                printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : "$list"-"$UNAMES" 已开播\n\e[1;40;32m[info]\e[0;0;96m : $TITLES\n\n"
            else
                printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : "$list"-"$UNAMES" 已复播\n\e[1;40;32m[info]\e[0;0;96m : $TITLES\n\n"
                RELIVE=0
            fi
        fi
        #开播状态为0 and 房间号在开播列表 and 房间号不在下播等待列表
        if [ "$STATUS" = "0" ] && [[ ${LIVING_ROMNUM[@]} =~ $list ]] && [[ ! ${LIVING_DOWNLV[@]} =~ $list ]];then
            printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : 检测到[ $list-$UNAMES ]已经下播\n\e[1;40;32m[info]\e[0;0;96m : 触发安全休眠系统，安全休眠10分钟后自动唤醒。\n\n"
            LIVING_DOWNLV+=("$list")
            DOWNLV_STAMPU+=("$(date +%s)")
        fi
        #下播等待列表不为空
        if [ "${#LIVING_DOWNLV[@]}" != "0" ];then
            for count in `seq 0 $((${#DOWNLV_STAMPU[@]}-1))`;do
                #现在的UNIX时间戳与列表中保存的时间戳相减等于600 and 指定房间号的开播状态为0
                if [ "`expr $(date +%s) - ${DOWNLV_STAMPU[$count]}`" -ge "5" ] && [ "`curl -s "http://api.live.bilibili.com/room/v1/Room/room_init?id=${LIVING_DOWNLV[$count]}" | sed 's:,: :g' | awk '{print $11}' | sed 's/:/ /g' | awk '{print $2}'`" = "0" ];then
                    for countro in `seq 0 $((${#LIVING_ROMNUM[@]}-1))`;do
                        #如果${LIVING_ROMNUM[$countro]}(开播列表)读到的房间号等于${LIVING_DOWNLV[$count]}(下播等待列表) and ${#LIVING_ROMNUM[@]}(开播列表总长)等于引导数+1
                        if [ "${LIVING_ROMNUM[$countro]}" = "${LIVING_DOWNLV[$count]}" ] && [ ${#LIVING_ROMNUM[@]} = $((countro+1)) ];then
                            printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : "${LIVING_ROMNUM[$countro]}"-"${LIVING_UNAMES[$countro]}" 已下播\n\e[1;40;32m[info]\e[0;0;96m : "${LIVING_TITLES[$countro]}"\n\n"
                            #待转移录播数据房间号列表
                            FILEDP_ROMNUM+=("${LIVING_ROMNUM[$countro]}")
                            LIVING_ROMNUM=("${LIVING_ROMNUM[@]:0:$countro}")
                            LIVING_STATUS=("${LIVING_STATUS[@]:0:$countro}")
                            LIVING_TARUID=("${LIVING_TARUID[@]:0:$countro}")
                            LIVING_TITLES=("${LIVING_TITLES[@]:0:$countro}")
                            #待转移录播数据开播用户名
                            FILEDP_UNAMES+=("${LIVING_UNAMES[$countro]}")
                            LIVING_UNAMES=("${LIVING_UNAMES[@]:0:$countro}")
                            #待转移录播数据开播时间戳
                            FILEDP_TSTAMP+=("${LIVING_TSTAMP[$countro]}")
                            LIVING_TSTAMP=("${LIVING_TSTAMP[@]:0:$countro}")
                            >/home/$USER/.IRDsCache.log
                            echo ${FILEDP_ROMNUM[@]} >> /home/$USER/.IRDsCache.log
                            echo ${FILEDP_UNAMES[@]} >> /home/$USER/.IRDsCache.log
                            echo ${FILEDP_TSTAMP[@]} >> /home/$USER/.IRDsCache.log
                        #如果${LIVING_ROMNUM[$countro]}(开播列表)读到的房间号等于${LIVING_DOWNLV[$count]}(下播等待列表) and ${#LIVING_ROMNUM[@]}(开播列表总长)不等于引导数+1
                        elif [ "${LIVING_ROMNUM[$countro]}" = "${LIVING_DOWNLV[$count]}" ] && [ ${#LIVING_ROMNUM[@]} != $((countro+1)) ];then
                            printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : "${LIVING_ROMNUM[$countro]}"-"${LIVING_UNAMES[$countro]}" 已下播\n\e[1;40;32m[info]\e[0;0;96m : "${LIVING_TITLES[$countro]}"\n\n"
                            #待转移录播数据房间号列表
                            FILEDP_ROMNUM+=("${LIVING_ROMNUM[$countro]}")
                            LIVING_ROMNUM=("${LIVING_ROMNUM[@]:0:$countro}" "${LIVING_ROMNUM[@]:$((countro+1))}")
                            LIVING_STATUS=("${LIVING_STATUS[@]:0:$countro}" "${LIVING_STATUS[@]:$((countro+1))}")
                            LIVING_TARUID=("${LIVING_TARUID[@]:0:$countro}" "${LIVING_TARUID[@]:$((countro+1))}")
                            LIVING_TITLES=("${LIVING_TITLES[@]:0:$countro}" "${LIVING_TITLES[@]:$((countro+1))}")
                            #待转移录播数据开播用户名
                            FILEDP_UNAMES+=("${LIVING_UNAMES[$countro]}")
                            LIVING_UNAMES=("${LIVING_UNAMES[@]:0:$countro}" "${LIVING_UNAMES[@]:$((countro+1))}")
                            #待转移录播数据开播时间戳
                            FILEDP_TSTAMP+=("${LIVING_TSTAMP[$countro]}")
                            LIVING_TSTAMP=("${LIVING_TSTAMP[@]:0:$countro}" "${LIVING_TSTAMP[@]:$((countro+1))}")
                            >/home/$USER/.IRDsCache.log
                            echo ${FILEDP_ROMNUM[@]} >> /home/$USER/.IRDsCache.log
                            echo ${FILEDP_UNAMES[@]} >> /home/$USER/.IRDsCache.log
                            echo ${FILEDP_TSTAMP[@]} >> /home/$USER/.IRDsCache.log
                        fi
                    done
                    for countdo in `seq 0 $((${#LIVING_DOWNLV[@]}-1))`;do
                        if [[ "${FILEDP_ROMNUM[@]}" =~ "${LIVING_DOWNLV[$countdo]}" ]] && [ ${#LIVING_DOWNLV[@]} = $((countdo+1)) ];then
                            LIVING_DOWNLV=("${LIVING_DOWNLV[@]:0:$countdo}")
                            DOWNLV_STAMPU=("${DOWNLV_STAMPU[@]:0:$countdo}")
                        elif [[ "${FILEDP_ROMNUM[@]}" =~ "${LIVING_DOWNLV[$countdo]}" ]] && [ ${#LIVING_ROMNUM[@]} != $((countdo+1)) ];then
                            LIVING_DOWNLV=("${LIVING_DOWNLV[@]:0:$countdo}" "${LIVING_DOWNLV[@]:$((countdo+1))}")
                            DOWNLV_STAMPU=("${LIVING_DOWNLV[@]:0:$countdo}" "${LIVING_DOWNLV[@]:$((countdo+1))}")
                        fi
                    done
                #现在的UNIX时间戳与列表中保存的时间戳相减等于600 and 指定房间号的开播状态为1
                elif [ "`expr $(date +%s) - ${DOWNLV_STAMPU[$count]}`" -ge "5" ] && [ "`curl -s "http://api.live.bilibili.com/room/v1/Room/room_init?id=${LIVING_DOWNLV[$count]}" | sed 's:,: :g' | awk '{print $11}' | sed 's/:/ /g' | awk '{print $2}'`" = "1" ];then
                    RELIVE=1
                fi
            done
        fi
        unset count countro countdo
        sleep 1s
    done
}

function infosys(){
    while :;do
        for list in ${roomlist[@]};do
            STATUS="$(echo `curl -s "http://api.live.bilibili.com/room/v1/Room/room_init?id=$list"` | sed 's:,: :g' | awk '{print $11}' | sed 's/:/ /g' | awk '{print $2}')"
            TARUID="$(echo `curl -s "http://api.live.bilibili.com/room/v1/Room/room_init?id=$list"` | sed 's:,: :g' | awk '{print $6}' | sed 's/:/ /g' | awk '{print $2}')"
            TITLES="$(curl -s https://api.live.bilibili.com/room/v1/Room/get_status_info_by_uids -H "Content-Type: application/json" -d "{\"uids\": [$TARUID]}" | sed 's:,:\n:g' | sed 's:{::g' | grep "title" | sed 's/:/ /g' | awk '{print $4}' | sed 's:"::g')"
            UNAMES="$(curl -s https://api.live.bilibili.com/room/v1/Room/get_status_info_by_uids -H "Content-Type: application/json" -d "{\"uids\": [$TARUID]}" | sed 's:,:\n:g' | sed 's:{::g' | grep "uname" | sed 's/:/ /g' | awk '{print $2}' | sed 's:"::g')"
            #开播状态为1 and 房间号不在开播列表
            if [ "$STATUS" = "1" ] && [[ ! ${LIVING_ROMNUM[@]} =~ $list ]];then
                #开播房间号列表
                LIVING_ROMNUM+=("$list")
                #开播状态列表
                LIVING_STATUS+=("$STATUS")
                #开播用户ID列表(非房间号，为主播UID)
                LIVING_TARUID+=("$TARUID")
                #开播标题
                LIVING_TITLES+=("\"$TITLES\"")
                #开播用户名
                LIVING_UNAMES+=("$UNAMES")
                #开播时间戳
                LIVING_TSTAMP+=("$(date "+%m-%d-%H-%M")")
                if [ $RELIVE = 0 ];then
                    printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : "$list"-"$UNAMES" 已开播\n\e[1;40;32m[info]\e[0;0;96m : $TITLES\n\n"
                else
                    printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : "$list"-"$UNAMES" 已复播\n\e[1;40;32m[info]\e[0;0;96m : $TITLES\n\n"
                    RELIVE=0
                fi
            fi
            #开播状态为0 and 房间号在开播列表 and 房间号不在下播等待列表
            if [ "$STATUS" = "0" ] && [[ ${LIVING_ROMNUM[@]} =~ $list ]] && [[ ! ${LIVING_DOWNLV[@]} =~ $list ]];then
                printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : 检测到[ $list-$UNAMES ]已经下播\n\e[1;40;32m[info]\e[0;0;96m : 触发安全休眠系统，安全休眠10分钟后自动唤醒。\n\n"
                LIVING_DOWNLV+=("$list")
                DOWNLV_STAMPU+=("$(date +%s)")
            fi
            #下播等待列表不为空
            if [ "${#LIVING_DOWNLV[@]}" != "0" ];then
                for count in `seq 0 $((${#DOWNLV_STAMPU[@]}-1))`;do
                    #现在的UNIX时间戳与列表中保存的时间戳相减等于600 and 指定房间号的开播状态为0
                    if [ "`expr $(date +%s) - ${DOWNLV_STAMPU[$count]}`" -ge "5" ] && [ "`curl -s "http://api.live.bilibili.com/room/v1/Room/room_init?id=${LIVING_DOWNLV[$count]}" | sed 's:,: :g' | awk '{print $11}' | sed 's/:/ /g' | awk '{print $2}'`" = "0" ];then
                        for countro in `seq 0 $((${#LIVING_ROMNUM[@]}-1))`;do
                            #如果${LIVING_ROMNUM[$countro]}(开播列表)读到的房间号等于${LIVING_DOWNLV[$count]}(下播等待列表) and ${#LIVING_ROMNUM[@]}(开播列表总长)等于引导数+1
                            if [ "${LIVING_ROMNUM[$countro]}" = "${LIVING_DOWNLV[$count]}" ] && [ ${#LIVING_ROMNUM[@]} = $((countro+1)) ];then
                                printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : "${LIVING_ROMNUM[$countro]}"-"${LIVING_UNAMES[$countro]}" 已下播\n\e[1;40;32m[info]\e[0;0;96m : "${LIVING_TITLES[$countro]}"\n\n"
                                #待转移录播数据房间号列表
                                FILEDP_ROMNUM+=("${LIVING_ROMNUM[$countro]}")
                                LIVING_ROMNUM=("${LIVING_ROMNUM[@]:0:$countro}")
                                LIVING_STATUS=("${LIVING_STATUS[@]:0:$countro}")
                                LIVING_TARUID=("${LIVING_TARUID[@]:0:$countro}")
                                LIVING_TITLES=("${LIVING_TITLES[@]:0:$countro}")
                                #待转移录播数据开播用户名
                                FILEDP_UNAMES+=("${LIVING_UNAMES[$countro]}")
                                LIVING_UNAMES=("${LIVING_UNAMES[@]:0:$countro}")
                                #待转移录播数据开播时间戳
                                FILEDP_TSTAMP+=("${LIVING_TSTAMP[$countro]}")
                                LIVING_TSTAMP=("${LIVING_TSTAMP[@]:0:$countro}")
                                >/home/$USER/.IRDsCache.log
                                echo ${FILEDP_ROMNUM[@]} >> /home/$USER/.IRDsCache.log
                                echo ${FILEDP_UNAMES[@]} >> /home/$USER/.IRDsCache.log
                                echo ${FILEDP_TSTAMP[@]} >> /home/$USER/.IRDsCache.log
                            #如果${LIVING_ROMNUM[$countro]}(开播列表)读到的房间号等于${LIVING_DOWNLV[$count]}(下播等待列表) and ${#LIVING_ROMNUM[@]}(开播列表总长)不等于引导数+1
                            elif [ "${LIVING_ROMNUM[$countro]}" = "${LIVING_DOWNLV[$count]}" ] && [ ${#LIVING_ROMNUM[@]} != $((countro+1)) ];then
                                printf "\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;32m[info]\e[0;0;96m : "${LIVING_ROMNUM[$countro]}"-"${LIVING_UNAMES[$countro]}" 已下播\n\e[1;40;32m[info]\e[0;0;96m : "${LIVING_TITLES[$countro]}"\n\n"
                                #待转移录播数据房间号列表
                                FILEDP_ROMNUM+=("${LIVING_ROMNUM[$countro]}")
                                LIVING_ROMNUM=("${LIVING_ROMNUM[@]:0:$countro}" "${LIVING_ROMNUM[@]:$((countro+1))}")
                                LIVING_STATUS=("${LIVING_STATUS[@]:0:$countro}" "${LIVING_STATUS[@]:$((countro+1))}")
                                LIVING_TARUID=("${LIVING_TARUID[@]:0:$countro}" "${LIVING_TARUID[@]:$((countro+1))}")
                                LIVING_TITLES=("${LIVING_TITLES[@]:0:$countro}" "${LIVING_TITLES[@]:$((countro+1))}")
                                #待转移录播数据开播用户名
                                FILEDP_UNAMES+=("${LIVING_UNAMES[$countro]}")
                                LIVING_UNAMES=("${LIVING_UNAMES[@]:0:$countro}" "${LIVING_UNAMES[@]:$((countro+1))}")
                                #待转移录播数据开播时间戳
                                FILEDP_TSTAMP+=("${LIVING_TSTAMP[$countro]}")
                                LIVING_TSTAMP=("${LIVING_TSTAMP[@]:0:$countro}" "${LIVING_TSTAMP[@]:$((countro+1))}")
                                >/home/$USER/.IRDsCache.log
                                echo ${FILEDP_ROMNUM[@]} >> /home/$USER/.IRDsCache.log
                                echo ${FILEDP_UNAMES[@]} >> /home/$USER/.IRDsCache.log
                                echo ${FILEDP_TSTAMP[@]} >> /home/$USER/.IRDsCache.log
                            fi
                        done
                        for countdo in `seq 0 $((${#LIVING_DOWNLV[@]}-1))`;do
                            if [[ "${FILEDP_ROMNUM[@]}" =~ "${LIVING_DOWNLV[$countdo]}" ]] && [ ${#LIVING_DOWNLV[@]} = $((countdo+1)) ];then
                                LIVING_DOWNLV=("${LIVING_DOWNLV[@]:0:$countdo}")
                                DOWNLV_STAMPU=("${DOWNLV_STAMPU[@]:0:$countdo}")
                            elif [[ "${FILEDP_ROMNUM[@]}" =~ "${LIVING_DOWNLV[$countdo]}" ]] && [ ${#LIVING_ROMNUM[@]} != $((countdo+1)) ];then
                                LIVING_DOWNLV=("${LIVING_DOWNLV[@]:0:$countdo}" "${LIVING_DOWNLV[@]:$((countdo+1))}")
                                DOWNLV_STAMPU=("${LIVING_DOWNLV[@]:0:$countdo}" "${LIVING_DOWNLV[@]:$((countdo+1))}")
                            fi
                        done
                    #现在的UNIX时间戳与列表中保存的时间戳相减等于600 and 指定房间号的开播状态为1
                    elif [ "`expr $(date +%s) - ${DOWNLV_STAMPU[$count]}`" -ge "5" ] && [ "`curl -s "http://api.live.bilibili.com/room/v1/Room/room_init?id=${LIVING_DOWNLV[$count]}" | sed 's:,: :g' | awk '{print $11}' | sed 's/:/ /g' | awk '{print $2}'`" = "1" ];then
                        RELIVE=1
                    fi
                done
            fi
            unset count countro countdo
        done
        sleep 1s
    done
}

function occupychk(){
    SLEEPWAIT=0;ddtvwaitlist=[];biliwaitlist=[];
    #if [ "`ls -l "/home/oriki/recordserver/DDTV2/tmp/bilibili_$unames"_"$list/" | grep .flv | grep "^-" | wc -l`" \> "0" ] || [ "`cd /home/oriki/recordserver/BiliRecorder/ && ls -d */ | grep "^$(date "+%Y")" | wc -l`" \> "0" ];then
    if [ "`ls -l "/home/oriki/recordserver/DDTV2/tmp/${FILEDP_ROMNUM[$count2FR]}"_"${FILEDP_UNAMES[$count2FR]}"_"bilibili/" | grep .flv | grep "^-" | wc -l`" \> "0" ] || [ "`cd /home/oriki/recordserver/BiliRecorder/${FILEDP_ROMNUM[$count2FR]}"_"${FILEDP_UNAMES[$count2FR]}"_"bilibili/ && ls -d */ | grep "^$(date "+%Y")" | wc -l`" \> "0" ];then
        if [ $(date "+%H") \< "06" ];then
            savepath="$RECORD_DIR/$(date "+%Y")/${FILEDP_UNAMES[$count2FR]}/$(date "+%Y-%m")-`expr $(date "+%d") - 1`/$(date "+%m")-`expr $(date "+%d") - 1`-DayChangeConvert/"
        else
            savepath="$RECORD_DIR/$(date "+%Y")/${FILEDP_UNAMES[$count2FR]}/$(date "+%Y-%m-%d")/${FILEDP_TSTAMP[$count2FR]}/"
        fi
        mkdir -p $savepath
    
        #DDTV
        DDTV_DL_DIR="$DDTV_DIR/${FILEDP_ROMNUM[$count2FR]}"_"${FILEDP_UNAMES[$count2FR]}"_"bilibili/";cd $DDTV_DL_DIR
        DDTV_DL_DIR_LEN=${#DDTV_DL_DIR}
        for DDTV_FLV in *.flv;do
            if [ "$DDTV_FLV" = "*.flv" ];then
                printf "\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;31m[erro]\e[0;0;96m : DDTV目录没有检测到FLV录制视频文件\n"
                printf "\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;31m[erro]\e[0;0;96m : DDTV目录没有检测到FLV录制视频文件\n" >> /home/$USER/.IRDs.log
                break
            else
                while :;do
                    if [[ "`lsof "$DDTV_FLV" 2>/dev/null | grep -v "PID" | awk '{print $2}'`" != "" ]] && [ "$SLEEPWAIT" -le "2" ];then
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件正在占用中，进入10分钟休眠等待中。\n"
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件正在占用中，进入10分钟休眠等待中。\n" >> /home/$USER/.IRDs.log
                        sleep 10m
                        let SLEEPWAIT++
                    elif [ "$SLEEPWAIT" -gt "2" ];then
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件占用时间过长，将放入文件池中。\n"
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件占用时间过长，将放入文件池中。\n" >> /home/$USER/.IRDs.log
                        ddtvwaitlist+=("$DDTV_DIR/${FILEDP_ROMNUM[$count2FR]}"_"${FILEDP_UNAMES[$count2FR]}"_"bilibili/$DDTV_FLV")
                        break
                    else
                        NameConvert "$DDTV_DL_DIR" "$DDTV_FLV" "1" "1"
                        DDTV_FLV="$FLVw"
                        printf "\n\e[1;40;32m[info]\e[0;0;96m : DDTV-正在移动文件"$DDTV_FLV".\n"
                        printf "\n\e[1;40;32m[info]\e[0;0;96m : DDTV-正在移动文件"$DDTV_FLV".\n" >> /home/$USER/.IRDs.log
                        metasize="`ls -l "$DDTV_FLV" | awk '{print $5}' 2>/dev/null`"
                        mv "$DDTV_FLV" "$savepath"&
                        ProgressBar "$savepath" "$DDTV_FLV" "$metasize"
                        break
                    fi
                done
            fi
        done
        unset SLEEPWAIT DDTV_FLV metasize DDTV_DL_DIR DDTV_DL_DIR_LEN

        #BilibiliRecord
        BILI_DL_DIR="$BILI_DIR/${FILEDP_ROMNUM[$count2FR]}"_"${FILEDP_UNAMES[$count2FR]}"_"bilibili/"
        cd $BILI_DL_DIR
        flag2bili=0
        for BILI_FOLDER in `ls -d */ | grep "^$(date "+%Y")"`;do
            NameConvert "$BILI_DL_DIR" "$BILI_FOLDER" "1" "2"
            BILI_FOLDER="$FLVw"
            cd "$BILI_DL_DIR$BILI_FOLDER"
            flag2bili=1
            for BILI_FLV in *.flv;do
                while :;do
                    if [ "`lsof "$BILI_FLV" 2>/dev/null | grep -v "PID" | awk '{print $2}'`" != "" ] && [ "$SLEEPWAIT" \<\= "2"  ];then
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件正在占用中，进入10分钟休眠等待中。\n"
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件正在占用中，进入10分钟休眠等待中。\n" >> /home/$USER/.IRDs.log
                        sleep 10m
                        let SLEEPWAIT++
                    elif [ "$SLEEPWAIT" \> "2" ];then
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件占用时间过长，将放入文件池中。\n"
                        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 文件占用时间过长，将放入文件池中。\n" >> /home/$USER/.IRDs.log
                        biliwaitlist+=("$BILI_DL_DIR$BILI_FOLDER")
                        break
                    else
                        NameConvert "$BILI_DL_DIR$BILI_FOLDER" "$BILI_FLV" "1" "1"
                        BILI_FLV="$FLVw"
                        printf "\n\e[1;40;32m[info]\e[0;0;96m : BILI-正在移动文件"$BILI_FOLDER".\n"
                        printf "\n\e[1;40;32m[info]\e[0;0;96m : BILI-正在移动文件"$BILI_FOLDER".\n" >> /home/$USER/.IRDs.log
                        metasize="`du --max-depth=1 "$BILI_DL_DIR$BILI_FOLDER" | awk '{print $1}' 2>/dev/null`"
                        mv "$BILI_DL_DIR$BILI_FOLDER" "$savepath"&
                        ProgressBar "$savepath" "$BILI_FOLDER" "$metasize"
                        break
                    fi
                done
            done
        done
        if [ $flag2bili = 0 ];then
            printf "\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;31m[erro]\e[0;0;96m : 录播姬目录没有检测到FLV录制视频文件\n"
            printf "\n\e[1;40;32m[info]\e[0;0;96m : $(date "+%Y-%m-%d %H:%M:%S")\n\e[1;40;31m[erro]\e[0;0;96m : 录播姬目录没有检测到FLV录制视频文件\n" >> /home/$USER/.IRDs.log
        fi
        unset SLEEPWAIT BILI_FOLDER BILI_FLV flag2bili metasize BILI_DL_DIR

        #DDTV等待文件池
        if [ "${#ddtvwaitlist[*]}" \> "1" ];then
            for dwf in ${ddtvwaitlist[@]};do
                PID=`lsof "$dwf" 2>/dev/null | grep -v "PID" | awk '{print $2}'`
                if [ "$PID" = "" ];then
                    dwf_DIR=${dwf:0:$DDTV_DL_DIR_LEN}
                    dwf_FILENAME=${dwf:$DDTV_DL_DIR_LEN}
                    NameConvert "$dwf_DIR" "$dwf_FILENAME" "1" "1"
                    dwf_FILENAME="$FLVw"
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : DDTV池-正在移动文件池文件"$dwf_FILENAME"\n"
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : DDTV池-正在移动文件池文件"$dwf_FILENAME"\n" >> /home/$USER/.IRDs.log
                    metasize="`ls -l "$dwf_FILENAME" | awk '{print $5}' 2>/dev/null`"
                    mv "$dwf_FILENAME" "$savepath"&
                    ProgressBar "$savepath" "$dwf_FILENAME" "$metasize"
                    ddtvwaitlist=(${ddtvwaitlist[@]/$dwf})
                else
                    PIDw=`echo $PID | sed 's:^[[:digit:]]:[&]:g'`
                    PROCESS_NAME=`ps -ef | grep -w $PIDw | awk '{print $8,$9,$10}'`
                    `echo -e "【Warning】\n出现长时间文件被占用的情况，请求人工介入：\n被占用文件路径 : $dwf\n占用程序PID   : $PID\n占用程序名称   : $PROCESS_NAME" | mail -s "Warning::文件占用警报" orikiringi@gmail.com`
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : "$dwf"出现长时间文件占用现象，已邮件通知管理者。\n"
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : "$dwf"出现长时间文件占用现象，已邮件通知管理者。\n" >> /home/$USER/.IRDs.log
                fi
            done
        fi
        unset dwf PID metasize ddtvwaitlist PIDw PROCESS_NAME dwf_DIR dwf_FILENAME

        #BILI等待文件池
        if [ "${#biliwaitlist[*]}" \> "1" ];then
            for bwf in ${biliwaitlist[@]};do
                cd $bwf
                totalflv=`ls -l *.flv | grep "^-" | wc -l`
                for bwfn in *.flv;do
                    PID=`lsof $bwfn 2>/dev/null | grep -v "PID" | awk '{print $2}'`
                    if [ "$PID" = "" ];then
                        let totalflv--
                    fi
                done
                if [ "$totalflv" = "0" ];then
                    bwf_DIR=${dwf:0:38}
                    bwf_FILENAME=${dwf:38}
                    NameConvert "$bwf_DIR" "$bwf_FILENAME" "1" "2"
                    bwf_FILENAME="$FLVw"
                    bwf="$bwf_DIR$bwf_FILENAME"
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : BILI池-正在移动文件池文件"$bwf_FILENAME"\n"
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : BILI池-正在移动文件池文件"$bwf_FILENAME"\n" >> /home/$USER/.IRDs.log
                    metasize=`du --max-depth=1 "$bwf" | awk '{print $1}' 2>/dev/null`
                    mv "$bwf" "$savepath"&
                    ProgressBar "$savepath" "$bwf_FILENAME" "$metasize"
                else
                    PIDw=`echo $PID | sed 's:^[[:digit:]]:[&]:g'`
                    PROCESS_NAME=`ps -ef | grep -w $PIDw | awk '{print $8,$9,$10}'`
                    `echo -e "【Warning】\n出现长时间文件被占用的情况，请求人工介入：\n被占用文件路径 : $bwf\n占用程序PID   : $PID\n占用程序名称   : $PROCESS_NAME" | mail -s "Warning::文件占用警报" orikiringi@gmail.com`
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : "$bwf"出现长时间文件占用现象，已邮件通知管理者。\n"
                    printf "\n\e[1;40;32m[info]\e[0;0;96m : "$bwf"出现长时间文件占用现象，已邮件通知管理者。\n" >> /home/$USER/.IRDs.log
                fi
            done
        fi
        unset bwf totalflv metasize biliwaitlist PIDw PROCESS_NAME bwf_DIR bwf_FILENAME
    else
        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 检测到直播结束但是没有检测到任何的录播文件。\n"
        printf "\n\e[1;40;31m[erro]\e[0;0;96m : 检测到直播结束但是没有检测到任何的录播文件。\n" >> /home/$USER/.IRDs.log
        `echo -e "【Warning】\n检测到直播结束但是没有检测到任何的录播文件，请求人工介入。" | mail -s "Warning::文件疑似缺失警报" orikiringi@gmail.com`
    fi
    printf "\n\e[1;40;32m[info]\e[0;0;96m : 文件移动阶段结束，返回直播间监视。\n"
    printf "\n\e[1;40;32m[info]\e[0;0;96m : 文件移动阶段结束，返回直播间监视。\n" >> /home/$USER/.IRDs.log
}

#代码实际执行区
if [ ! -f "/home/$USER/.IRDsCache.log" ];then
    touch /home/$USER/.IRDsCache.log
fi
header
#fakeinfosys&
infosys&
while :;do
    if [ "`cat /home/$USER/.IRDsCache.log`" != "" ];then
        count=0
        while read line;do
            if [ $count = 0 ];then rooms=$line
            elif [ $count = 1 ];then names=$line
            elif [ $count = 2 ];then stamp=$line
            fi
            let count++
        done < /home/$USER/.IRDsCache.log
        FILEDP_ROMNUM=(`echo $rooms | sed 's:\ :,:g' | tr ',' ' '`)
        FILEDP_UNAMES=(`echo $names | sed 's:\ :,:g' | tr ',' ' '`)
        FILEDP_TSTAMP=(`echo $stamp | sed 's:\ :,:g' | tr ',' ' '`)
        unset rooms names stamp
        >/home/$USER/.IRDsCache.log
        if [ "${#FILEDP_ROMNUM[@]}" != "0" ];then
            for count2FR in `seq 0 $((${#FILEDP_ROMNUM[@]}-1))`;do
                occupychk
            done
        fi
    fi
    sleep 5s
done
