# ZSH_INSTALL.sh
  
  这个是ZSH自动安装脚本, 可以使用命令一键安装

  > 手动安装-Manual
  `bash <(curl -s -L "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/ZSH_INSTALL.sh")`
  > 自动安装-Auto
  `bash <(curl -s -L "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/ZSH_INSTALL_AUTO.sh")`
  
  国内用户可以用以下的命令
  
  `bash <(curl -s -L "https://ghproxy.com/https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/ZSH_INSTALL.sh")`
  
  可以用以下的网址获取短址
  
  `https://bitly.com/`

  为了安全起见，本脚本舍弃了原本直接进行多用户安装的功能。
  为多个用户安装zsh时，需要切换到对应用户下再次执行本脚本。

# sysinfo.zsh-theme

  这个是自制的ZSH主题, 修改自Kali官方主题, 需要先安装好oh-my-zsh
  
  国内用户请在https前加上`https://ghproxy.com/`再下载
  
 1.`wget "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/sysinfo.zsh-theme" -O "$(echo ~)/.oh-my-zsh/themes/sysinfo.zsh-theme"`
 
 or 
 
 1.`curl "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/sysinfo.zsh-theme" -o "$(echo ~)/.oh-my-zsh/themes/sysinfo.zsh-theme"`
 
 2.```sed -i 's:ZSH_THEME="robbyrussell":ZSH_THEME="sysinfo":g' "$(echo ~)/.zshrc"```

# 替换老主题文件方法
```
# User
curl https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/refs/heads/main/1.SystemScripts/LinuxScripts/ZSH/sysinfo.zsh-theme > /home/$(whoami)/.oh-my-zsh/themes/sysinfo.zsh-theme && source /home/$(whoami)/.zshrc

# Root
curl https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/refs/heads/main/1.SystemScripts/LinuxScripts/ZSH/sysinfo.zsh-theme > /root/.oh-my-zsh/themes/sysinfo.zsh-theme && source /root/.zshrc
```
