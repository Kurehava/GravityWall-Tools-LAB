# 以防万一写在最前面！
  主题默认在最前面显示host名，你可以手动编辑.oh-my-zsh/theme/Chizuru.zsh-theme文件的display_name参数来达到自定义的目的！

# ZSH_INSTALL.sh
  
  这个是ZSH自动安装脚本, 可以使用命令一键安装

  > 手动安装-Manual

  `bash <(curl -s -L "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/ZSH_INSTALL.sh")`
  > 自动安装-Auto

  `bash <(curl -s -L "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/ZSH_INSTALL_AUTO.sh")`

  > 自动安装-Auto-MacOS

  `bash <(curl -s -L "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/ZSH_INSTALL_MacOS.sh")`
  
  > 中国大陆(国内)用户可以用以下的命令
  
  `bash <(curl -s -L "https://ghproxy.com/https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/ZSH_INSTALL.sh")`
  
  > 可以用以下的网址获取短链
  
  `https://bitly.com/`

  ⚠ 为了安全起见，本脚本舍弃了原本直接进行多用户安装的功能。
  
  ⚠ 为多个用户安装zsh时，需要切换到对应用户下再次执行本脚本。

# Chizuru.zsh-theme

  这个是自制的ZSH主题, 修改自Kali官方主题, 需要先安装好oh-my-zsh
  
  中国大陆(国内)用户请在https前加上`https://ghproxy.com/`再下载

  1. 使用`curl`或者`wget`下载主题

      > wget
        
        `wget "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/Chizuru.zsh-theme" -O "$(echo ~)/.oh-my-zsh/themes/Chizuru.zsh-theme"`
    
      > curl
        
        `curl "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/Chizuru.zsh-theme" -o "$(echo ~)/.oh-my-zsh/themes/Chizuru.zsh-theme"`
  
  2. 修改`~/.zshrc`文件中主题的设置

     `sed -i 's:ZSH_THEME="robbyrussell":ZSH_THEME="Chizuru":g' "$(echo ~)/.zshrc"`

# 替换kensyo主题为Chizuru主题
  `wget "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/Chizuru.zsh-theme" -O "$(echo ~)/.oh-my-zsh/themes/Chizuru.zsh-theme" && sed -i 's:ZSH_THEME="kensyo":ZSH_THEME="Chizuru":g' "$(echo ~)/.zshrc" && rm "$(echo ~)/.oh-my-zsh/themes/kensyo.zsh-theme" && source "$(echo ~)/.zshrc"`

# 替换sysinfo主题为Chizuru主题
  `wget "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/Chizuru.zsh-theme" -O "$(echo ~)/.oh-my-zsh/themes/Chizuru.zsh-theme" && sed -i 's:ZSH_THEME="sysinfo":ZSH_THEME="Chizuru":g' "$(echo ~)/.zshrc" && rm "$(echo ~)/.oh-my-zsh/themes/sysinfo.zsh-theme" && source "$(echo ~)/.zshrc"`

# 手动更新主题文件的方法
  `wget "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/Chizuru.zsh-theme" -O "$(echo ~)/.oh-my-zsh/themes/Chizuru.zsh-theme" && source "$(echo ~)/.zshrc"`
