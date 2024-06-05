function cdls(){
        \cd $1
        if [ $? -eq 0 ];then
                ls -a
        fi
        }
alias cd="cdls"
