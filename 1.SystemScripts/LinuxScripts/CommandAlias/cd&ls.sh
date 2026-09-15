function cdls(){
    builtin cd $1
    if [ $? -eq 0 ];then
        pwd
        echo '---'
        command ls --color=auto -a --group-directories-first
    fi
}
alias cd="cdls"
