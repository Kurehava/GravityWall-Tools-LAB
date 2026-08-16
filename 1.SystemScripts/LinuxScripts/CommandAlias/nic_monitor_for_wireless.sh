function nic_monitor(){
    sudo airmon-ng start wlan0

    while true;do
        read "channel?plz input channel: "
        if [[ ! $channel =~ '[0-9]{1,3}' ]];then
            echo '[erro] plz reinput channel on number.'
        else
            if [[ $channel -gt 1 ]] && [[ $channel -lt 233 ]];then
                break
            else
                echo '[erro] can not bind this channel.'
                echo '[erro] plz reinput channel on number.'
                continue
            fi
        fi
    done
    sudo ifconfig wlan0mon down
    sudo iwconfig wlan0mon mode monitor
    sudo iwconfig wlan0mon channel $channel
    sudo ifconfig wlan0mon up
    sudo ifconfig wlan0mon
    sudo iwconfig
    sudo wireshark

    echo '[info] wait for wiresharl terminal...'
    while [[ `ps -ef | grep [w]ireshark > /dev/null | echo $?` -eq 1 ]];do
        sleep 5
    done

    echo '[info] now reset NIC. Plz wait ....'
    sudo airmon-ng stop wlan0mon

    if [[ `echo $?` -eq 0 ]];then
        echo '[info] success'
    else
        echo '[erro] reset NIC failed.'
        echo '[erro] you can try manual run >'
        echo '[erro] sudo airmon-ng stop wlan0mon'
        echo '[erro] or try reboot system.'
    fi

    echo '[info] over'
}
