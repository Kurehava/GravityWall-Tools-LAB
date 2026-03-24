function docker_view(){
    docker_containers=($(sudo docker ps -a | awk 'NR>=2 {print $1}'))
    containers_id=("Container_ID" "============")
    containers_status=("Status" "======")
    containers_name=("Container_Name" "==============")
    containers_ip=("Container_IP" "============")
    containers_image=("Container_Image" "===============")

    for container_ in ${docker_containers[@]};do
        container_network=`sudo docker inspect $container_ | jq -r '.[0].NetworkSettings.Networks | keys[]'`
        container_ip=`sudo docker inspect -f "{{ .NetworkSettings.Networks.$container_network.IPAddress }}" $container_`
        if [ "$container_ip" = "" ];then
            container_ip=" "
        else
            container_ip="$container_ip"
        fi
        container_status=`sudo docker inspect -f "{{ .State.Status }}" $container_`
        if [ "$container_status" = "exited" ];then
            container_status="exited_"
        fi
        containers_id+=(`sudo docker inspect -f "{{ .Config.Hostname }}" $container_`)
        containers_status+=($container_status)
        containers_name+=(`sudo docker inspect -f "{{ .Name }}" $container_ | tr -d "/"`)
        containers_ip+=($container_ip)
        containers_image+=(`sudo docker inspect -f "{{ .Config.Image }}" $container_`)
    done

    cid=$(printf "%s\n" "${containers_id[@]}" | awk '{ if (length > max) max = length } END { print max }')
    cst=$(printf "%s\n" "${containers_status[@]}" | awk '{ if (length > max) max = length } END { print max }')
    cip=$(printf "%s\n" "${containers_ip[@]}" | awk '{ if (length > max) max = length } END { print max }')
    cnm=$(printf "%s\n" "${containers_name[@]}" | awk '{ if (length > max) max = length } END { print max }')
    cos=12

    for ((i=0; i<=${#containers_id[@]}; i++));do
        echo -e "${containers_id[i]}$(printf ' %.0s' $(seq 0 $(($cid-${#containers_id[i]}))))\
${containers_status[i]}$(printf ' %.0s' $(seq 0 $(($cst-${#containers_status[i]}))))\
${containers_ip[i]}$(printf ' %.0s' $(seq 0 $(($cip-${#containers_ip[i]}))))\
${containers_name[i]} "
    done
}
