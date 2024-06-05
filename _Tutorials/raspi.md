# Raspi

## 常用指令

* **一键升级删掉不需要依赖（除了初始化系统慎用）**  
   `sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y`
* **安装bpytop（bashtop）**  
   `sudo apt install bpytop`  
   or  
   `sudo apt install bashtop`
* **设置raspi脚本（系统一般自带了）**  
   `sudo raspi-config`
* **查看端口开放（lsof）**  
   `lsof -i tcp:<port>`
* **路由追踪（traceroute）**  
   `traceroute <ip>`

## - 3.5inch display

安装3.5寸显示器 *一定* 要去GitHub上选择相应的系统版本

> GitHub 主仓库地址 :  
> <https://github.com/goodtft/LCD-show>  
> GitHub Ubuntu仓库地址 ：  
> <https://github.com/lcdwiki/LCD-show-ubuntu>  
> GitHub Kali仓库地址 :  
> <https://github.com/lcdwiki/LCD-show-kali>

* 安装命令行

    ```bash
    # 以安装 kali 版本为例
    # 安装其他发行版需要把kali替换为发行版名称
    # 或者删除
    sudo rm -rf LCD-show
    git clone https://github.com/goodtft/LCD-show-kali.git
    sudo chmod -R 755 LCD-show-kali
    cd LCD-show-kali/
    # 这里默认是不需要旋转屏幕
    # 但是我这边的屏幕需要旋转180度
    # 所以这里添加参数180
    sudo ./LCD35-show 180
    ```

* 旋转屏幕指令  
`sudo ./rotate.sh <角度>`

## - Argon ONE M.2 外壳

用以下的链接来安装Argon外壳控制脚本  

```bash
curl https://download.argon40.com/argon1.sh | bash
sudo reboot
```

* 进入控制台  
    `argonone-config`

* 风扇转速控制

    默认为：

    >55C - 10%  
    >60C - 55%  
    >65C - 100%

    我的推荐是：

    >55C - 50% <- 注意这里  
    >60C - 55%  
    >65C - 100%

* 卸载脚本指令  
    `argonone-uninstall`

## - 安装conda环境（Mambaforge）

直接去下载以下仓库中的aarch64版本的最新发行

> GitHub 仓库地址 :  
> <https://github.com/conda-forge/miniforge>  
> GitHub 发行版地址 ：  
> <https://github.com/conda-forge/miniforge/releases>

```bash
# 以24.3.0-0为例
# pwd = ~
export URL="https://github.com/conda-forge/miniforge/releases/download/24.3.0-0/Mambaforge-24.3.0-0-Linux-aarch64.sh"
wget $URL
bash Mambaforge-24.3.0-0-Linux-aarch64.sh
```

## - 为有桌面环境的发行版开启VNC（无桌面环境的没有尝试）

1. 首先先安装 `tightvncserver`
2. 如果是kali的发行版，在`~/.vnc/xstartup` 中插入`/usr/bin/startlxde`  
   以下是完整的文件  

    ```bash
    #!/bin/sh

    xrdb "$HOME/.Xresources"
    xsetroot -solid grey
    #x-terminal-emulator -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
    #x-window-manager &
    # Fix to make GNOME work
    export XKL_XMODMAP_DISABLE=1
    /etc/X11/Xsession
    /usr/bin/startlxde
    ```

3. 设置分辨率（该步骤可能不需要）：  
   `vncserver -geometry 1920x1080 :1`

4. 启动vnc服务:  
   `tightvncserver`
5. 在`.zshrc`文件中添加自启动  
   `tightvncserver 1>&2 2>/dev/null`
