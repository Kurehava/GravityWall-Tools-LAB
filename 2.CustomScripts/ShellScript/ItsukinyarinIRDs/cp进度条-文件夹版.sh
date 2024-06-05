#!/bin/bash
i=0;
str=""
arr=("|" "/" "-" "\\")
dir="/home/$USER/Desktop/"
tar="/home/$USER/"
filename="123"
cp -r $dir$filename $tar 2>/dev/null&
if [ "`ps -ef | grep -w '[c]p'| awk '{print $2}'`" != "" ];then
  while [ $i -ne 100 ]
  do
    metasize="`du --max-depth=1 $dir$filename | awk '{print $1}' 2>/dev/null`"
    targsize="`du --max-depth=1 $tar$filename | awk '{print $1}' 2>/dev/null`"
    let statsize=$targsize*100/$metasize
    let chkdatas=$i+5
    let index=i%4
    sleep 0.1
    if [ $statsize -ge $chkdatas ];then
      let i+=5
      str+='='
    fi
    printf "\e[0;96;1m[%-20s][%d%%]%c\r" "$str" "$i" "${arr[$index]}"
  done
  printf "\n"
else
  echo "CP has error skipping..."
fi