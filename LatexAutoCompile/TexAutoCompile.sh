###########################################
#POWER BY GravityWallToolsDevelopmentLAB  #
###########################################
##################################################################
#TexAutoCompile LastVersion 0.9.0                                #
#Powered by orikiringi Belonging to KanagawaUniversity MoritaLab #
#Github:https://github.com/Kurehava                              #
##################################################################
#==ver.0.9.0==
#重构脚本,优化性能
#Refactor scripts to optimize performance.
#修改功能为外挂函数
#Modify the function as a plug-in function.
#新增“历史”功能
#New features : History
#=============
##############################################################################
#If your have some problems with width ,
#Linux : Please change 88 of line 32 larger.
#MacOS : Please change 643 of line 22 larger.
##############################################################################
if [ "`uname`" = "Darwin" ];then
    osascript -e 'tell application "Terminal"
    activate
    set the bounds of the first window to {140, 0, 633, 400}
    -- x - x position in pixels
    -- y - y position in pixels
    -- w - width in pixels
    -- h - height in pixels
    end tell'
    while sleep 1;do tput sc;tput cup 0 $(($(tput cols)-40));date;tput rc;done&
    echo="echo"
    banner="\033[41;30m  Latest Ver 0.9.0  Powered by oriki                                        \033[0m"
elif [ "`uname`" = "Linux" ];then
    printf '\033[8;20;88t'
    echo="echo -e"
    banner="\033[41;30m  Latest Ver 0.9.0  Powered by oriki  \033[0m"
fi
banner=$banner"\\n""\033[33m============================================================================= \033[0m"
banner=$banner"\\n""\033[33m  _____             _         _         ____                      _ _       \033[0m"
endmsg="============================="
banner=$banner"\\n""\033[33m |_   _|____  __   / \  _   _| |_ ___  / ___|___  _ __ ___  _ __ (_) | ___  \033[0m"
endmsg=$endmsg"\\n""Script Executed End"
banner=$banner"\\n""\033[33m   | |/ _ \ \/ /  / _ \| | | | __/ _ \| |   / _ \| '_ ' _ \| '_ \| | |/ _ | \033[0m"
endmsg=$endmsg"\\n""Ver.0.9.0 10/11/2021"
banner=$banner"\\n""\033[33m   | |  __/>  <  / ___ \ |_| | || (_) | |__| (_) | | | | | | |_) | | |  __/ \033[0m"
maintip="------------------------------------------"
banner=$banner"\\n""\033[33m   |_|\___/_/\_\/_/   \_\__,_|\__\___/ \____\___/|_| |_| |_| .__/|_|_|\___| \033[0m"
endmsg=$endmsg"\\n""============================="
banner=$banner"\\n""\033[33m                                                           |_|    \033[0m"
maintip=$maintip"\\n""[E]exit"
maintip=$maintip"\\n""[D]delete extras file"
maintip=$maintip"\\n""[H]history"
maintip=$maintip"\\n""------------------------------------------"
banner=$banner"\\n""\033[33m============================================================================= \033[0m"
nuser="Script User : $USER "
if [ "$(dirname $0)" = "." ];then
    nuser=$nuser"\\n""Script Path : `pwd` "
else
    nuser=$nuser"\\n""Script Path : $(dirname $0) "
fi
maintip=$maintip"\\n""Put your Tex file or Input your Tex file path in this windows.(E/D/H/Path)"
rope="------------------------------------------"
function navigation(){
    case $1 in
        1) autochkfile;;
        2) mainmenu;;
        3) compilechk;;
        4) tachistory;;
        5) compile;;
        6) submenu;;
    esac
}
function dlexit(){
    if [ "`uname`" = "Darwin" ];then
        osascript -e 'tell application "Terminal" to close first window' & exit
    elif [ "`uname`" = "Linux" ];then
        clear
        exit
    fi
}
function cleanner(){
    if [ "$1" = "" ];then
        rm "$realname".aux|rm "$realname".dvi|rm "$realname".log|rm "$realname".nav|rm "$realname".out|rm "$realname".snm|rm "$realname".toc|rm "$realname".out|rm "$realname".fls|rm "$realname".fdb_latexmk|rm "$realname".synctex.gz|rm "$realname".vrb|rm "$realname".bcf|rm "$realname".blg|rm "$realname".bbl|rm "$realname".run.xml
        clear
    else
        rm *.aux|rm *.dvi|rm *.log|rm *.nav|rm *.out|rm *.snm|rm *.toc|rm *.out|rm *.fls|rm *.fdb_latexmk|rm *.synctex.gz|rm *.vrb|rm *.bcf|rm *.run.xml
        clear
    fi
}
function compile(){
    cd "$realpath"
    platex "$realname".tex;pbibtex "$realname".aux;platex "$realname".tex;platex "$realname".tex;dvipdfmx "$realname".dvi
    if [ "`uname`" = "Darwin" ];then
        open "$realname".pdf
    elif [ "`uname`" = "Linux" ];then
        evince "$realname".pdf &
    fi
    cleanner
    navichk=6
}
function filename(){
    unset fntachis;flag2fntachis=0
    if test -e ~/.tachistory.his;then
        PRE_IFS=$IFS
        IFS=$'\n'
        for fntachis in `cat ~/.tachistory.his`;do
            if [ "$1" = "$fntachis" ];then
                flag2fntachis=1
                break
            fi
        done
        IFS=$PRE_IFS
    fi
    if [ "$flag2fntachis" = "1" ];then
        escape=`echo $1 | sed 's:/:\\\/:g' | sed 's:\ :\\\ :g' | sed 's:*:\\\*:g' | sed 's:;:\\\;:g' | sed 's://:/:g'`
        if [ "`uname`" = "Darwin" ];then
            sed -i "" "s;$escape;;g" ~/.tachistory.his && sed -i "" '/^\s*$/d' ~/.tachistory.his
        elif [ "`uname`" = "Linux" ];then
            sed -i "s;$escape;;g" ~/.tachistory.his && sed -i '/^\s*$/d' ~/.tachistory.his
        fi
        echo "$1" >> ~/.tachistory.his
        flag2fntachis=0
    else
        echo "$1" >> ~/.tachistory.his
    fi
    realpath=`dirname "$1"`
    realname="$realpath"/`basename "$1" .tex`
}
function tachistory(){
    unset invtachis;unset tacharr;unset disptach;unset tachis;cunt2tach=0
    if test -e ~/.tachistory.his;then
        PRE_IFS=$IFS
        IFS=$'\n'
        for tachis in `cat ~/.tachistory.his`;do
            let cunt2tach++
            if [ ! -f "$tachis" ];then
                invtachis[$cunt2tach]="$tachis"
            fi
            tacharr[$cunt2tach]="$tachis"
        done
        IFS=$PRE_IFS
        if [ "${#invtachis[@]}" != "0" ];then
            while :;do
                clear;$echo "$banner";$echo $nuser;$echo $rope
                if [ "$delinvhis" = "1" ];then
                    $echo "{\033[31m $invtachisnum \033[0m} is Illegal input, Please reinput."
                    delinvhis=0
                fi
                read -p "Detected invalid paths in the history records. Do you want to clear them?(Y/N)" invtachisnum
                case $invtachisnum in
                Y|y|ｙ|"")
                    for delinvhis in "${invtachis[@]}";do
                        escape=`echo $delinvhis | sed 's:/:\\\/:g' | sed 's:\ :\\\ :g' | sed 's:*:\\\*:g' | sed 's:;:\\\;:g'`
                        if [ "`uname`" = "Darwin" ];then
                            sed -i "" "s;$escape;;g" ~/.tachistory.his && sed -i "" '/^\s*$/d' ~/.tachistory.his
                        elif [ "`uname`" = "Linux" ];then
                            sed -i "s;$escape;;g" ~/.tachistory.his && sed -i '/^\s*$/d' ~/.tachistory.his
                        fi
                    done
                    break
                    ;;
                N|n|ｎ) break;;
                *) delinvhis=1;;
                esac
            done
        fi
        while :;do
            cunt2tach=0;clear;$echo "$banner";$echo $nuser;$echo $rope;unset disptach;unset determination;unset tacharr
            PRE_IFS=$IFS
            IFS=$'\n'
            for determination in `cat ~/.tachistory.his`;do
                tacharr[$cunt2tach]="$determination"
                let cunt2tach++
            done
            IFS=$PRE_IFS
            if [ "${#tacharr[@]}" = "0" ];then
                echo "No history is detected, return to the main menu after 3 seconds."
                sleep 3s
                navichk=2
                break
            fi
            cunt2tach=0
            for disptach in "${tacharr[@]}";do
                let cunt2tach++
                if [ ! -f "$disptach" ];then
                    if [ "`uname`" = "Darwin" ];then
                        echo "\033[31m$cunt2tach.$disptach\033[0m"
                    elif [ "`uname`" = "Linux" ];then
                        echo -e "\033[31m$cunt2tach.$disptach\033[0m"
                    fi
                else
                    echo $cunt2tach.$disptach
                fi
                tacharr[$cunt2tach]="$disptach"
            done
            echo $rope
            if [ "$tacherr" = "1" ];then
                $echo "{\033[31m $tachnum \033[0m} is Illegal input, Please reinput."
            elif [ "$tacherr" = "2" ];then
                $echo "\033[31mIllegal input\033[0m, Please reinput."
            fi
            tacherr=0
            read -p "Select you want to compile path number for history list or input 'E' to go mainmenu. >> " tachnum
            if [ "$tachnum" = "e" ] || [ "$tachnum" = "E" ];then
                navichk=2
                break
            elif [ "${#tachnum}" \> "${#cunt2tach}" ];then
                tacherr=2
            elif [ "`echo -e "$tachnum*1"|bc`" = "0" ] || [ "$tachnum" \> "$cunt2tach" ];then
                tacherr=1
            elif [ ! -f "${tacharr[$tachnum]}" ];then
                while :;do
                    clear;$echo "$banner";$echo $nuser;$echo $rope
                    if [ "$delinvpath" = "1" ];then
                        $echo "{\033[31m $tacinvpathdel \033[0m} is Illegal input, Please reinput."
                        delinvpath=0
                    fi
                    read -p "path \"${tacharr[$tachnum]}\" is invalid, do you want delete this path?(Y/N)" tacinvpathdel
                    case $tacinvpathdel in
                        Y|y|ｙ|"") 
                        escape=`echo "${tacharr[$tachnum]}" | sed 's:/:\\\/:g' | sed 's:\ :\\\ :g' | sed 's:*:\\\*:g' | sed 's:;:\\\;:g'`
                        if [ "`uname`" = "Darwin" ];then
                            sed -i "" "s;$escape;;g" ~/.tachistory.his && sed -i "" '/^\s*$/d' ~/.tachistory.his
                        elif [ "`uname`" = "Linux" ];then
                            sed -i "s;$escape;;g" ~/.tachistory.his && sed -i '/^\s*$/d' ~/.tachistory.his
                        fi
                        break
                        ;;
                        N|n|ｎ) break;;
                        *) delinvpath=1;;
                    esac
                done
            else
                filename "${tacharr[$tachnum]}"
                navichk=3
                break
            fi
        done
    else
        clear;$echo "$banner";$echo $nuser;$echo $rope
        echo "No history is detected, return to the main menu after 3 seconds."
        sleep 3s
        navichk=2
    fi
}
function autochkfile(){
    clear;$echo "$banner";$echo $nuser;echo $rope;cunt2acffn=0;unset acffn;unset acffnarr
    PRE_IFS=$IFS
    IFS=$'\n'
    for acffn in `find ~/Documents/ -amin 1 -name "*.tex" && find ~/Desktop/ -amin 1 -name "*.tex"`;do
        if [ "${#acffn}" -gt "2" ];then
            let cunt2acffn++
            acffnarr[$cunt2acffn]="$acffn"
            echo $cunt2acffn."$acffn"
        fi
    done
    IFS=$PRE_IFS
    echo $rope
    if [ "${#acffnarr[@]}" != "0" ];then
        while :;do
            read -p "If you want to compile list file input the file number or input 'E' to mainmenu.>> " acffnnum
            if [ "$acffnnum" = "" ];then
                acffnnum=1
            fi
            if [ "$acffnnum" = "e" ] || [ "$acffnnum" = "E" ];then
                navichk=2
                break
            elif [ "`echo -e "$acffnnum*1"|bc`" = "0" ] || [ "$acffnnum" \> "$cunt2acffn" ] || [ "${#acffnnum}" \> "${#cunt2acffn}" ];then
                clear;$echo "$banner";$echo $nuser;$echo $rope;cunt2acffn=1
                for reacffn in "${acffnarr[@]}";do
                    echo $cunt2acffn.$reacffn
                    let cunt2acffn++
                done
                echo $rope
                $echo "\033[31mIllegal input\033[0m. Please reinput.>> "
            else
                filename "${acffnarr[$acffnnum]}"
                navichk=3
                break
            fi
        done
    else
        navichk=2
    fi
    ######目标：检测到文件，flag2acf=1输出，并且使realname有值，否则，flag2acf=0输出。
}
function mainmenu(){
    while :;do
        clear;$echo "$banner";$echo "$nuser"
        if [ "$mmerr" = "1" ];then
            $echo "{\033[31m ${path##*/} \033[0m} is not a .Tex file or can\`t found."
            mmerr=0
        fi
        $echo "$maintip"
        read -p ">>" path
        if [ "`uname`" = "Linux" ];then
            path=`echo $path|sed "s/'//g"`
        fi
        case $path in
            E|e|ｅ) dlexit;;
            H|h|ｈ) navichk=4;break;;
            D|d|ｄ) cleanner *;;
            *)
            if [ ! -f "$path" ];then
                mmerr=1
            else
                filename "$path"
                navichk=3
                break
            fi
            ;;
        esac
    done
}
function compilechk(){
    while :;do
        clear;$echo "$banner";$echo $nuser;$echo $rope
        echo Filename : ${realname##*/}
        if [ "${realpath%/*}" = "." ] || [ "$realpath" = "${path%/*}" ];then
            pn="`pwd`"
            echo Pathname : $pn
        else
            echo Pathname : ${realpath%/*}
        fi
        echo ------------------------------------------
        if [ "$ccerr" = "1" ];then
            $echo "{\033[31m $ccnum \033[0m} is Illegal input. Please reinput.>> "
            ccerr=0
        fi
        read -p "Do you want compile this file or Delete extras files? [Y/N/D]: " ccnum
        case $ccnum in
            Y|y|ｙ|"") navichk=5;break;;
            N|n|ｎ) navichk=2;break;;
            D|d|d) cleanner *;;
            *) ccerr=1;;
        esac
    done
}
function submenu(){
    while :;do
        clear;$echo "$banner";$echo $nuser;$echo $rope
        echo Filename : ${realname##*/}
        if [ "${realpath%/*}" = "." ] || [ "$realpath" = "${path%/*}" ];then
            pn="`pwd`"
            echo Pathname : $pn
        else
            echo Pathname : ${realpath%/*}
        fi
        echo ------------------------------------------
        if [ "$smnum" = "1" ];then
            $echo "{\033[31m $smnum \033[0m} is Illegal input. Please reinput.>> "
            smnum=0
        fi
        read -p "Do you want Recompile or Exit? [R/E/D/B]: " smnum
        case $smnum in
            R|r|ｒ|"") navichk=5;break;;
            E|e|ｅ) dlexit;;
            D|d|ｄ) cleanner;;
            B|b|ｂ) unset acffnarr;navichk=1;break;;
            *) smnum=1;;
        esac
    done
}
while :;do
    if [ "$navichk" = "" ];then
        navichk=1
    fi
    navigation $navichk
done
