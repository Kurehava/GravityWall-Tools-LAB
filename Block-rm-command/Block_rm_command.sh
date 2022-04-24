############################################
#POWER BY GravityWallToolsDevelopmentLAB  #
###########################################
rmt(){
    PRE_IFS=$IFS;IFS=$'\n'
    #argv="${@}"
    flags=0;chks=0
    for arg in ${@};do
        if [ "$1" = "--help" ] || [ "$1" = "-help" ] || [ "$1" = "-h" ] || [ "$1" = "--h" ];then
            echo 为了计算机与数据安全，此命令代替rm命令。
            echo Usage:直接将要删除的文件作为参数带入即可
            break
        elif [ -a "$arg" ];then
            if [ `pwd` = "/" ];then
                for blocklist in `ls /`;do
                    if [ "$arg" = "$blocklist" ] || [ "$arg" = "$blocklist/" ] || [ "$arg" = "/" ] || ([ "${arg:(-2)}" = "/*" ] && [ "${arg%/*}" = "$blocklist" ]);then
                        if [[ "$arg" =~ "*" ]];then
                            echo -e "[\033[32mInfo-\033[96m]在此目录下使用‘*’（省略符）非常危险，我们以将其禁用。"
                            flags=1
                            break
                        fi
                        #echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                        #echo 你在进行非常危险的行为，我们已将此行为阻止。
                        #echo 你在进行非常危险的行为，我们已将此行为阻止。
                        #echo 你在进行非常危险的行为，我们已将此行为阻止。
                        #echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                        echo -e "\033[33m===================================================================================\033[96m"
                        echo -e "[\033[32mInfo-\033[96m]你所要删除的文件为\033[31m$arg\033[96m".
                        echo -e "[\033[32mInfo-\033[96m]\033[31m危险！！危险！！危险！！危险！！\033[96m\\n[\033[32mInfo-\033[96m]你所要删除的文件位于根目录，此目录下的文件及其重要，我们暂时拦截了你的行为。"
                        echo -e "[\033[33mPick-\033[96m]你真的要删除文件::\033[31m$arg\033[96m::吗？(y/n):"
                        while :;do
                            read -p ">>" topchk
                            case $topchk in
                            Y|y) 
                            echo -e "[\033[32mInfo-\033[96m]已确认你确认删除位于根目录的文件：\033[31m$arg\033[96m"
                            echo -e "[\033[32mInfo-\033[96m]我们将会延期5秒执行任务，请再次进行确认。您可以\"ctrl+c\"取消任务。"
                            echo -e "\033[33m===================================================================================\033[96m"
                            sleep 5s
                            if [ -a "$trash/$arg" ];then
                                changename=$arg-$((RANDOM*7+7))
                                sudo mv "$trash/$arg" "$trash/$changename"
                            fi
                            sudo mv "$arg" $trash
                            chks=1
                            break
                            ;;
                            N|n) 
                                echo -e "[\033[32mInfo-\033[96m]确认到你取消任务，启动保护，跳过次任务。\\n[\033[32mInfo-\033[96m]skipping......"
                                echo -e "\033[33m===================================================================================\033[96m"
                                break;;
                            *) echo -e "[\033[31mError\033[96m]Illegal input.Please reinput.";;
                            esac
                        done
                        flags=1
                        break
                    fi
                done
            fi
            if [ "$flags" = "0" ];then
                if [ -a "$trash/$arg" ];then
                    echo -e "\033[33m===================================================================================\033[96m"
                    while :;do
                        echo -en "[\033[33mPick-\033[96m]"
                        read -p "$arg have same file in Trash, did you want rename file then delete?(y/n)" sr
                        echo -e "\033[33m===================================================================================\033[96m"
                        case $sr in
                        Y|y)
                        changename=$arg-$((RANDOM*7+7))
                        mv $arg $changename 2>/dev/null
                        if [ $? -eq 1 ];then
                            echo -e "\033[33m===================================================================================\033[96m"
                            echo -e "[\033[32mInfo-\033[96m]你现在进行的操作可能需要超级权限，请进行二次确认无误后继续。"
                            echo -e "[\033[32mInfo-\033[96m]你在将 \033[31m$arg\033[96m 目录进行删除操作，如果有误请直接终止命令的执行，ctrl+c。"
                            while :;do
                            echo -en "[\033[33mPick-\033[96m]"
                            read -p "Remove this file need su, do you want continue?(y/n):" suc
                                case $suc in
                                Y|y) sudo mv $arg $changename && sudo mv $changename $trash && break;;
                                N|n) break 2;;
                                *) echo -e "[\033[31mError\033[96m]Illegal input.Please reinput.";;
                                esac
                            done
                            echo -e "\033[33m===================================================================================\033[96m"
                        else
                            mv $changename $trash
                        fi
                        break
                        ;;
                        N|n) break;;
                        *) echo -e "[\033[31mError\033[96m]Illegal input.Please reinput.";;
                        esac
                    done
                else
                    mv $arg $trash 2>/dev/null
                    if [ $? -eq 1 ];then
                        echo -e "\033[33m===================================================================================\033[96m"
                        echo -e "[\033[32mInfo-\033[96m]你现在进行的操作可能需要超级权限，请进行二次确认无误后继续。"
                        echo -e "[\033[32mInfo-\033[96m]你在将 \033[31m$arg\033[96m 目录进行删除操作，如果有误请直接终止命令的执行，ctrl+c。"
                        while :;do
                            echo -en "[\033[33mPick-\033[96m]"
                            read -p "Remove this file need su, do you want continue?(y/n):" ns
                            case $ns in
                            Y|y) sudo mv $arg $trash && break;;
                            N|n) 
                                echo -e "[\033[32mInfo-\033[96m]您的操作已安全取消 \\n[\033[32mInfo-\033[96m]skipping...."
                                echo -e "\033[33m===================================================================================\033[96m"
                                break;;
                            *) echo -e "[\033[31mError\033[96m]Illegal input.Please reinput.";;
                            esac
                        done
                        echo -e "\033[33m===================================================================================\033[96m"
                    fi
                fi
            else
                flags=0
            fi
        else
            echo -e "[\033[31mError\033[96m]Path :: \033[33m$arg\033[96m :: not a file or a folder.\\n[\033[32mInfo-\033[96m]skipping..."
            echo -e "\033[33m===================================================================================\033[96m"
        fi
    done
    IFS=$PRE_IFS
}
alias rmt="rmt"
alias rm="warrm"
alias rmmmmmmmmmm="/bin/rm"
#sudo ln -s /bin/rm /bin/rmmmmmmmmmm
export trash="/home/$USER/.local/share/Trash/files"
alias cleantrash="sudo rmmmmmmmmmm -rf $trash/*"
