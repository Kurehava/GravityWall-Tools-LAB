function cdls(){
    builtin cd $1
    if [ $? -eq 0 ];then
        pwd
        echo '---'
        ls -a
    fi
}
alias cd="cdls"
