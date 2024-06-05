erro="[\033[91mERRO\033[0m]"
info="[\033[92mINFO\033[0m]"
warn="[\033[93mWARN\033[0m]"

echo -e "$info Start kurehava zhenxun_bot install script"
echo -e "$info Set paths vars..."
work_path="$(echo ~)"
temp_path="$work_path/temp_zhenxun"
mkdir -p "$temp_path"

official_script='https://raw.githubusercontent.com/zhenxun-org/zhenxun_bot-deploy/master/install.sh'
template_sctipt='https://raw.githubusercontent.com/Kurehava/SHELL_Script/main/_Template/zhenxun_bot/install_template.sh'

# chk download tools
chk_curl="$(which curl)"
chk_wget="$(which wget)"
if [[ ! $chk_curl =~ "not found" ]];then
    download_command="curl"
    download_option="-o"
elif [[ ! $chk_wget =~ "not found" ]];then
    download_command="wget"
    download_option="-O"
else
    while :;do
        echo -e "$warn can not find download tools, do you want install?[Y/N]"
        read selects
        case $select in
            Y|y) $(sudo $pkg_manage install -y curl wget);download_command="wget";download_option="-O";break;;
            N|n) echo -e "$erro can not download oh-my-zsh, exit." && exit 1;;
            *) echo -e "$warn input $select is illegal, plz reinput.";;
        esac
    done
fi
echo -e "$info Set download tool : $download_command"

# download zhenxun_install_script
echo -e "$info download official zhenxun_isntall script.."
check_download_version="official"
zhenxun_script_path="$temp_path/zhenxun_install_script.sh"
`$download_command "$official_script" $download_option "$zhenxun_script_path" > /dev/null`
if [ "$?" != "0" ] || [ ! -e "$zhenxun_script_path" ];then
    echo -e "$erro official install script download failed."
    echo -e "$info try download kurehava template ... "
    `$download_command "$template_sctipt" $download_option "$zhenxun_script_path"`
    if [ "$?" != "0" ] || [ ! -e "$zhenxun_script_path" ];then
        echo -e "$erro template install script download failed."
        echo -e "$erro plz check internet status or permissions."
        echo -e "$erro exit."
        exit 127
    else
        echo -e "$info download kurehava template script success."
        check_download_version="template"
    fi
else
    echo -e "$info download official script success."
fi

if [ "$check_download_version" = "official" ];then
    echo -e "$info Change official script Statements..."
    `sed -i 's:WORK_DIR="/home":WORK_DIR="$(echo ~)/BOT":g' "$zhenxun_script_path"`
    `sed -i 's:TMP_DIR="$(mktemp -d)":TMP_DIR="$(mkdir -p $WORK_DIR/TEMP_DIR_NOT_DEL)":g' "$zhenxun_script_path"`
    `sed -i 's:check_root():cr():g' "$zhenxun_script_path"`
    `sed -i 's:check_root:#check_root:g' "$zhenxun_script_path"`
    `sed -i 's:apt-get:sudo apt-get:g' "$zhenxun_script_path"`
fi

# run script
echo -e "$info Start install zhenxun_bot"
bash "$zhenxun_script_path"

rm -rf $temp_path

