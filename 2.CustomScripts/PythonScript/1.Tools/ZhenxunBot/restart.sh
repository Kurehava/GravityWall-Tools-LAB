WORK_DIR="/home"
PYTHON_V="python3.8"
python_v="/usr/bin/python3.8"
DEBUG_DIR="/home/zhenxun_bot/DEBUG.txt"

if [ -n "$(pgrep -f 'bot.py')" ];then
    kill -9 $(pgrep -f 'bot.py')
    if [ -n "$(pgrep -f 'bot.py')" ];then
        whilecount_bot=0
        while :;do
            kill -9 $(pgrep -f 'bot.py')
            if [ -z "$(pgrep -f 'bot.py')" ];then
                break
            elif [ $whilecount_bot > 10 ];then
                echo "can not kill bot.py. exit."
                exit 1
            else
                let whilecount_bot++
            fi
        done
    fi
fi

if [ -n "$(pgrep -f 'go-cqhttp')" ];then
    kill -9 $(pgrep -f 'go-cqhttp')
    if [ -n "$(pgrep -f 'go-cqhttp')" ];then
        whilecount_go=0
        while :;do
            kill -9 $(pgrep -f 'go-cqhttp')
            if [ -z "$(pgrep -f 'go-cqhttp')" ];then
                break
            elif [ $whilecount_go > 10 ];then
                echo "can not kill go-cqhttp. exit."
                exit 1
            else
                let whilecount_go++
            fi
        done
    fi
fi

#################################################################################################################################################################
echo > ${WORK_DIR}/zhenxun_bot/zhenxun_bot.log 2>&1
bot_count=0
for i in `seq 1 5`;do
    bot_pid=$(pgrep -f "bot.py")
    if [ -z "${bot_pid}" ];then
        cd ${WORK_DIR}/zhenxun_bot
        nohup ${python_v} bot.py >> zhenxun_bot.log 2>&1 &
    elif [ -n "${bot_pid}" ] && [ $bot_count != 0 ];then
        kill -9 $(pgrep -f "bot.py")
        [[ -z "$(pgrep -f "bot.py")" ]] && echo 'zhenxun_bot stopped.'
        cd ${WORK_DIR}/zhenxun_bot
	    echo > ${WORK_DIR}/zhenxun_bot/zhenxun_bot.log 2>&1
        nohup ${python_v} ${WORK_DIR}/zhenxun_bot/bot.py >> ${WORK_DIR}/zhenxun_bot/zhenxun_bot.log 2>&1 &
    fi
    [[ -n "$(pgrep -f "bot.py")" ]] && sleep 2s && break
    echo "zhenxun_bot restart failed. try again. now $bot_count."
    let bot_count++
    sleep 1s
done

# DEBUG
echo "$(date): bot_pid_ps = $(pgrep -f "bot.py")" >> $DEBUG_DIR
echo "$(date): bot_pid_pg = $(pgrep -f "bot.py")" >> $DEBUG_DIR

[[ -z "$(pgrep -f "bot.py")" ]] && echo 'zhenxun_bot restart failed. exit.' && echo 'zhenxun_bot restart failed. exit.' >> /home/zhenxun_bot/restart_LOG.txt && exit 1
[[ -n "$(pgrep -f "bot.py")" ]] && echo 'zhenxun_bot restart sucess. wait 30s...' && sleep 30

#################################################################################################################################################################
for i in `seq 1 5`;do
    [[ -n "$(/usr/bin/lsof -i tcp:14514)" ]] && break
    echo "Port 14514 can not use. wait 10s."
    sleep 10
done
if [ -z "$(/usr/bin/lsof -i tcp:14514)" ];then
    echo "port error. exit."
    echo "port error. exit." >> /home/zhenxun_bot/restart_LOG.txt
    if [ -n "$(pgrep -f 'bot.py')" ];then
	    kill -9 $(pgrep -f 'bot.py')
    fi
    exit 1
fi
    
# [[ -z "$(/usr/bin/lsof -i tcp:14514 | grep python3.9 | awk {'print $2'})" ]] && echo "port error. exit." >> /home/zhenxun_bot_BASH/LOG.txt && echo no1 && kill -9 $(pgrep -f "bot.py") && exit 1

#################################################################################################################################################################
echo > ${WORK_DIR}/go-cqhttp/go-cqhttp.log
go_count=0
for i in `seq 1 5`;do
    cqh_pid=$(ps -ef | grep [g]o-cqhttp | awk '{print $2}')
    if [ -z "${cqh_pid}" ];then
        cd ${WORK_DIR}/go-cqhttp
        nohup ./go-cqhttp -faststart >> go-cqhttp.log 2>&1 &
    elif [ -n "${cqh_pid}" ];then
        echo no2
        kill -9 $(pgrep -f "go-cqhttp")
        [[ -z "$(pgrep -f "go-cqhttp")" ]] && echo 'go-cqhttp stopped.'
        cd ${WORK_DIR}/go-cqhttp
	    echo > go-cqhttp.log 2>&1
        nohup ./go-cqhttp -faststart >> go-cqhttp.log 2>&1 &
    fi
    [[ -n "$(ps -ef | grep [g]o-cqhttp | awk '{print $2}')" ]] && sleep 2s && break
    echo "go-cqhttp restart failed. try again. now $go_count."
    let go_count++
    sleep 1s
done

# DEBUG
echo "$(date): bot_pid_ps = $(ps -ef | grep [g]o-cqhttp | awk '{print $2}')" >> $DEBUG_DIR
echo "$(date): bot_pid_pg = $(pgrep -f "go-cqhttp")" >> $DEBUG_DIR

[[ -z "$(pgrep -f "go-cqhttp")" ]] && echo 'go-cqhttp restart failed. exit.' && echo 'go-cqhttp restart failed. exit.' >> /home/zhenxun_bot/restart_LOG.txt && exit 1
[[ -n "$(pgrep -f "go-cqhttp")" ]] && echo 'go-cqhttp restart sucess.'

touch ${WORK_DIR}/zhenxun_bot/is_restart

echo "" >> $DEBUG_DIR
