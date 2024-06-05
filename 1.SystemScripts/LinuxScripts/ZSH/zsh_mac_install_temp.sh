#!/bin/bash
#powered by kurehava

erro="[\033[91mERRO\033[0m]"
info="[\033[92mINFO\033[0m]"
warn="[\033[93mWARN\033[0m]"
dbug="[\033[95mDBUG\033[0m]"
user_root="$(echo ~)"
download_command="curl"
boots_proxy=""

echo -e "$info Install: oh-my-zsh"
# echo -e "N\n" | sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
echo -e "N\n" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# chk install success or fail
if [ ! -e "$user_root/.oh-my-zsh" ];then
    echo -e "$erro Install oh-my-zsh is failed. exit."
    exit 1
fi

# set oh-my-zsh dir
omz_home="$user_root/.oh-my-zsh"
omz_themes="$omz_home/themes"
omz_plugins="$omz_home/plugins"

# get kurehava zsh theme
`$download_command "${boots_proxy}https://raw.githubusercontent.com/Kurehava/SHELL_Script/main/_CREATE/System_Linux/ZSH/Sizuku_double_line.zsh-theme" > "$omz_themes/kurehava_conda.zsh-theme"`

# change theme to kurehava conda theme
$(sed -i "" s:robbyrussell:kurehava_conda:g "$user_root/.zshrc")

# install plugins
$(sed -i "" 's:plugins=(git):plugins=(git z extract):g' "$user_root/.zshrc")

incr_path="$omz_plugins/incr"
mkdir "$incr_path"
case $download_command in
    "wget") echo -e "$info DOWNLOAD Plugin: zsh-autosuggestions"
            wget "http://mimosa-pudica.net/src/incr-0.2.zsh" -P "$incr_path"
            incr_install=true
            ;;
    "curl") echo -e "$info DOWNLOAD Plugin: zsh-autosuggestions"
            curl -L "http://mimosa-pudica.net/src/incr-0.2.zsh" -o "$incr_path/incr-0.2.zsh"
            incr_install=true
            ;;
    *) echo -e "$warn Unknown download tool, skip the incr installation for safety reasons."
       echo -e "$warn You can do the manual installation later with the following command."
       echo -e "$warn + wget 'http://mimosa-pudica.net/src/incr-0.2.zsh' -P \"$incr_path\""
       echo -e "$warn + curl 'http://mimosa-pudica.net/src/incr-0.2.zsh' -o \"$incr_path/incr-0.2.zsh\""
       incr_install=false
       ;;
esac
if $incr_install;then
    if [ -f "$incr_path/incr-0.2.zsh" ];then
        echo -e "source $incr_path/incr-0.2.zsh" >> "$user_root/.zshrc"
        echo -e "$info WRITE: source $incr_path/incr-0.2.zsh >> $user_root/.zshrc"
    else
        echo -e "$warn can not found $incr_path/incr-0.2.zsh"
        echo -e "$warn skip writing incr source to the .zshrc file for security."
        echo -e "$warn You can do the manual installation later with the following command."
        echo -e "$warn + wget 'http://mimosa-pudica.net/src/incr-0.2.zsh' -P \"$incr_path\""
        echo -e "$warn + curl 'http://mimosa-pudica.net/src/incr-0.2.zsh' -o \"$incr_path/incr-0.2.zsh\""
        echo -e "$warn + source $incr_path/incr-0.2.zsh >> $user_root/.zshrc"
    fi
fi

za_path="$omz_plugins/zsh-autosuggestions"
echo -e "$info DOWNLOAD Plugin: zsh-autosuggestions"
mkdir "$za_path"
git clone ${boost_proxy}https://github.com/zsh-users/zsh-autosuggestions.git "$za_path"
if [ -f "$za_path/zsh-autosuggestions.zsh" ];then
    echo "source $za_path/zsh-autosuggestions.zsh" >> "$user_root/.zshrc"
    echo -e "$info WRITE: source $za_path/zsh-autosuggestions.zsh >> \"$user_root/.zshrc\""
else
    echo -e "$warn can not found $za_path/zsh-autosuggestions.zsh."
    echo -e "$warn skip writing zsh-autosuggestions source to the .zshrc file for security."
    echo -e "$warn You can do the manual installation later with the following command."
    echo -e "$warn + git clone https://github.com/zsh-users/zsh-autosuggestions.git \"$za_path\""
    echo -e "$warn + source $za_path/zsh-autosuggestions.zsh >> \"$user_root/.zshrc\""
fi

zshl_path="$omz_plugins/zsh-syntax-highlighting"
echo -e "$info DOWNLOAD Plugin: zsh-syntax-highlighting"
mkdir "$zshl_path"
git clone ${boost_proxy}https://github.com/zsh-users/zsh-syntax-highlighting.git "$zshl_path"
# echo "source $zshl_path/zsh-syntax-highlighting.zsh" >> "$user_root/.zshrc"
if [ -f "$zshl_path/zsh-syntax-highlighting.zsh" ];then
    echo "source $zshl_path/zsh-syntax-highlighting.zsh" >> "$user_root/.zshrc"
    echo -e "$info WRITE: source $zshl_path/zsh-syntax-highlighting.zsh >> \"$user_root/.zshrc\""
else
    echo -e "$warn can not found $zshl_path/zsh-syntax-highlighting.zsh."
    echo -e "$warn skip writing zsh-syntax-highlighting source to the .zshrc file for security."
    echo -e "$warn You can do the manual installation later with the following command."
    echo -e "$warn + git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \"$zshl_path\""
    echo -e "$warn + source $zshl_path/zsh-syntax-highlighting.zsh >> \"$user_root/.zshrc\""
fi