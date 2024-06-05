#################################################################################################################
##USER Define
code-server-stop(){
    SCREEN_PID="`screen -ls | grep code-server | sed 's:\.:\ :g' | awk '{print $1}'`"
    screen -S $SCREEN_PID -X quit
    echo -e "[\e[91mWARN-\e[0m] CODE-SERVER STOP."
}
alias server-stop="code-server-stop"
code-server-start(){
    port="`grep bind-addr:\  $HOME/.config/code-server/config.yaml | awk '{print $2}' | sed 's/0.0.0.0://g'`"
	nowip="`ip addr | grep eth0 | grep inet | awk '{print $2}' | sed 's/\/.*//g'`:$port"
	if [ "`ps -ef | grep [/]usr/lib/code-server`" == "" ];then
		screen -dmS code-server && screen -S code-server -X stuff 'code-server '`echo -ne '\015'`
		if [ "`ps -ef | grep [/]usr/lib/code-server`" == "" ];then
			echo -e "[\e[91mERROR\e[0m] : CODE-SERVER START EROOR."
            echo -e "[\e[91mERROR\e[0m] : You can start it manually by copying the following command."
			echo "screen -dmS code-server && screen -S code-server -X stuff 'code-server '`echo -ne '\015'`"
		else
			echo -e "[\e[92mSTATUS\e[0m] : CODE-SERVER RUNNING"
            SCREEN_PID="`screen -ls | grep code-server | sed 's:\.:\ :g' | awk '{print $1}'`"
            echo -e "[\e[92mSTATUS\e[0m] : SCREEN_PID - $SCREEN_PID"
            echo -e "[\e[92mSTATUS\e[0m] : $nowip"
		fi
	else
        echo -e "[\e[91mERROR\e[0m] : CODE-SERVER EXSIT."
	fi
}
alias server-start="code-server-start"
code-server-status(){
    if [ "`ps -ef | grep [/]usr/lib/code-server`" != "" ];then
        port="`grep bind-addr:\  $HOME/.config/code-server/config.yaml | awk '{print $2}' | sed 's/0.0.0.0://g'`"
	    nowip="`ip addr | grep eth0 | grep inet | awk '{print $2}' | sed 's/\/.*//g'`:$port"
        SCREEN_PID="`screen -ls | grep code-server | sed 's:\.:\ :g' | awk '{print $1}'`"
        echo -e "[\e[92mSTATUS\e[0m] : CODE-SERVER RUNNING"
        echo -e "[\e[92mSTATUS\e[0m] : SCREEN_PID - $SCREEN_PID"
        echo -e "[\e[92mSTATUS\e[0m] : $nowip"
    else
        echo -e "[\e[91mSTATUS\e[0m] : CODE-SERVER ERROR"
        echo -e "[\e[91mSTATUS\e[0m] : USE COMMAND [server-start]"
    fi
}
alias server-status="code-server-status"
code-server-restart(){
    server-stop
    server-start
}
alias server-restart="code-server-restart"
code-server-newpass(){
    echo -e "[\e[92mINFO-\e[0m] Input now password: "
    read -s nowpass
    relnopass="`grep password: $HOME/.config/code-server/config.yaml | awk '{print $2}'`"
    if [ "$nowpass" = "$relnopass" ];then
        while :;do
            echo -e "[\e[92mINFO-\e[0m] Input new password: "
            read -s newpass
            echo -e "[\e[92mINFO-\e[0m] Input new password again: "
            read -s subnewpass
            if [ "$newpass" = "$subnewpass" ];then
                sed -i "s/password: .*/password: $newpass/g" $HOME/.config/code-server/config.yaml
                echo -e "[\e[92mSUCCS\e[0m] Password changed."
                break
            else
                echo -e "[\e[91mERROR\e[0m] The password entered twice does not match.\nPlz try again.\n"
            fi
        done
    else
        echo -e "[\e[91mERROR\e[0m] Incorrect password."
    fi
}
alias server-pw="code-server-newpass"
code-server-newport(){
    port="`grep bind-addr:\  $HOME/.config/code-server/config.yaml | awk '{print $2}' | sed 's/0.0.0.0://g'`"
    echo -e "[\e[92mINFO-\e[0m] Input new port(1~65535): "
    read newport
    if [ "`lsof -i:$newport`" == "" ];then
        if [ "$newport" != "$port" ];then
            sed -i "s/bind-addr:\ 0.0.0.0:.*/bind-addr:\ 0.0.0.0:$newport/g" $HOME/.config/code-server/config.yaml
            echo -e "[\e[92mINFO-\e[0m] Port changed."
            port="`grep bind-addr:\  $HOME/.config/code-server/config.yaml | awk '{print $2}' | sed 's/0.0.0.0://g'`"
            nowip="`ip addr | grep eth0 | grep inet | awk '{print $2}' | sed 's/\/.*//g'`:$port"
            echo -e "[\e[92mINFO-\e[0m] next time port : \e[92m$port\e[0m"
            echo -e "[\e[92mINFO-\e[0m] next time IP   : \e[92m$nowip\e[0m"
        else
            echo -e "[\e[93mWARN-\e[0m] Same as existing Port, no manipulation"
        fi
    else
        echo -e "[\e[91mERROR\e[0m] Input Port is occupied."
    fi
}
alias server-port="code-server-newport"
server(){
    echo -e "\e[93mCODE-SERVER CONTROL COMMAND LINE\e[0m"
    echo -e "\e[93mPowered by SHO Belonging to KanagawaUniversity MoritaLab\e[0m"
    echo "##############################################################"
    echo "Usage:"
    echo -e "\e[92mserver-start\e[0m   - start code-server manual."
    echo -e "\e[92mserver-stop\e[0m    - stop code-server manual."
    echo -e "\e[92mserver-restart\e[0m - restart code-server manual."
    echo -e "\e[92mserver-status\e[0m  - code-server status."
    echo -e "\e[92mserver-pw\e[0m      - change code-server password."
    echo -e "\e[92mserver-port\e[0m    - change code-server port"
}
code-server-status
