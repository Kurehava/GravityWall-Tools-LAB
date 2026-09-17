# 以防万一写在最前面！

  主题默认在最前面显示 host 名。你可以编辑主题文件里的 `display_name` 参数来自定义显示名：

  ```
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/Chizuru.zsh-theme
  ```

  修改完成后 `source ~/.zshrc` 一下，或者重新登录即可。

  > 主题文件的位置从 `~/.oh-my-zsh/themes/` 改到了 `~/.oh-my-zsh/custom/themes/`。
  > `custom` 目录不会被 `omz update` 覆盖，所以你的改动不会丢失。
  > 安装脚本会自动把旧位置的文件改名让开（`Chizuru.zsh-theme.replaced.<时间戳>`）。

---

# ZSH_INSTALL.sh / ZSH_INSTALL_AUTO.sh

  一键安装脚本。会安装 oh-my-zsh、Chizuru 主题、`zsh-autosuggestions`、
  `zsh-syntax-highlighting`，并帮你改好 `~/.zshrc`。

  > 手动安装（会逐步询问）-Manual

  `bash <(curl -fsSL "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/ZSH_INSTALL.sh")`

  > 自动安装（全部默认 Yes）-Auto

  `bash <(curl -fsSL "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/ZSH_INSTALL_AUTO.sh")`

## 支持的平台

| 平台 | 包管理器 |
| --- | --- |
| Debian / Ubuntu / Kali / Parrot / Raspbian | `apt-get` |
| RHEL / CentOS / Rocky / AlmaLinux / Fedora | `dnf`、`yum` |
| openSUSE | `zypper` |
| Arch | `pacman` |
| Alpine | `apk` |
| macOS | Homebrew |
| WSL1 / WSL2 | 同上（会自动识别 WSL） |

## 命令行参数

```
--auto, --yes, -y      全部默认 Yes（ZSH_INSTALL_AUTO.sh 的默认行为）
--interactive, -i      逐步询问（ZSH_INSTALL.sh 的默认行为）
--no-chsh              不修改登录 shell
--proxy <prefix>       github 镜像前缀，例如 https://example.com/
--branch <name>        从指定分支拉取主题（默认 main）
--help, -h             显示帮助
```

## 环境变量

```
GH_PROXY=https://example.com/     所有 github / raw 链接的镜像前缀
CHIZURU_BRANCH=main               拉取主题的分支
CHIZURU_ASSUME_YES=1              不询问
CHIZURU_SET_DEFAULT_SHELL=0       不修改登录 shell
CHIZURU_ZSHRC_BACKUP_KEEP=5       ~/.zshrc 备份保留几份（0 = 不限制）
CHIZURU_FORCE_SPECTRUM_FIX=1      强制安装旧版 zsh 的 spectrum.zsh 兼容文件
```

  ⚠ 国内本土的情况：原来推荐的 `https://ghproxy.com/` 已经停止服务。  
  请用 `GH_PROXY` 或 `--proxy` 指定一个你信任的镜像前缀，例如：

  `GH_PROXY="https://你的镜像/" bash <(curl -fsSL "https://raw.githubusercontent.com/.../ZSH_INSTALL_AUTO.sh")`

## 脚本会做什么

  1. 探测系统 / 包管理器 / 下载工具（curl 或 wget，两个都支持）
  2. 缺少 `git` / `zsh` / `curl` 时尝试安装
  3. 安装 oh-my-zsh（已安装则跳过）
  4. 下载 Chizuru 主题到 `$ZSH_CUSTOM/themes/`
     — 下载后会**校验文件内容**，镜像返回 404 页面时直接中止，不会把错误页装成主题
  5. 备份 `~/.zshrc`（`~/.zshrc.bak.<时间戳>`，默认保留 5 份）
  6. 设置 `ZSH_THEME="Chizuru"`，把插件合并进 `plugins=()` 数组
  7. 清理旧版脚本写进 `~/.zshrc` 的 `source .../zsh-autosuggestions.zsh` 之类的行
  8. zsh 版本低于 5.3 时自动放置 `spectrum.zsh` 兼容文件（见下）
  9. 把登录 shell 改成 zsh（失败只警告，不会中断）

  **脚本可以重复执行**。没有变化时不会重写 `~/.zshrc`，也不会产生新的备份。

  ⚠ 为多个用户安装 zsh 时，需要切换到对应用户下再次执行本脚本。

---

# 旧系统 / 旧版本 zsh 报错

  在旧版 zsh 上应用主题时可能出现：

  ```
  (anon):6: bad math expression: operand expected at `^fg'
  ```

  这是 oh-my-zsh 的 `lib/spectrum.zsh` 在旧 zsh 上的问题。
  **现在安装脚本会在 zsh < 5.3 时自动放置下面这个兼容文件**，一般不需要手动处理。

  需要手动放置时，文件路径是：

  ```
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/lib/spectrum.zsh
  ```

  ```zsh
  typeset -AHg FX FG BG

  FX=(
    reset     "%{"$'\e'"[00m%}"
    bold      "%{"$'\e'"[01m%}" no-bold      "%{"$'\e'"[22m%}"
    dim       "%{"$'\e'"[02m%}" no-dim       "%{"$'\e'"[22m%}"
    italic    "%{"$'\e'"[03m%}" no-italic    "%{"$'\e'"[23m%}"
    underline "%{"$'\e'"[04m%}" no-underline "%{"$'\e'"[24m%}"
    blink     "%{"$'\e'"[05m%}" no-blink     "%{"$'\e'"[25m%}"
    reverse   "%{"$'\e'"[07m%}" no-reverse   "%{"$'\e'"[27m%}"
  )

  for color in {000..255}; do
    FG[$color]="%{"$'\e'"[38;5;${color}m%}"
    BG[$color]="%{"$'\e'"[48;5;${color}m%}"
  done
  unset color
  ```

  想在新系统上也强制放置：`CHIZURU_FORCE_SPECTRUM_FIX=1`。

---

# Chizuru.zsh-theme

  自制的 ZSH 主题，修改自 Kali 官方主题，需要先安装好 oh-my-zsh。

  **兼容 zsh 5.0.2 ~ 最新版**。主题会在加载时探测当前 zsh 与终端的能力，
  并自动降级：

  | 功能 | 需要 | 降级方案 |
  | --- | --- | --- |
  | `%F{#RRGGBB}` 24bit 色 | zsh 5.7+ | xterm-256 色 → 基本色 → 无色 |
  | `zle reset-prompt -f nolast` | zsh 5.9+ | 输入中暂停重绘（保护 history 等 widget） |
  | 每秒刷新 IP / 时钟 | zsh/zpty + `zle -F` | TRAPALRM（需显式开启）→ 仅 precmd 刷新 |
  | `strftime` | zsh/datetime | `date(1)` |
  | `ip -br addr` | iproute2 4.x+ | `ip -o addr` → `ifconfig` → `hostname -I` |
  | `ls/grep/diff/ip --color` | GNU 工具 | 先探测再决定是否设置 alias |

## 手动安装
 curl：

  ```
  mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes"
  curl -fsSL "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/Chizuru.zsh-theme" \
    -o "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/Chizuru.zsh-theme"
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="Chizuru"/' "$HOME/.zshrc"
  ```

  wget：

  ```
  mkdir -p "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes"
  wget -q "https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/main/1.SystemScripts/LinuxScripts/ZSH/Chizuru.zsh-theme" \
    -O "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/Chizuru.zsh-theme"
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="Chizuru"/' "$HOME/.zshrc"
  ```

## 手动更新主题

  主题自带更新命令，登录时也会自动检查：

  ```
  chizuru-update
  ```

  更新成功时会自动备份成 `Chizuru.zsh-theme.bak.<时间戳>`，默认保留 5 份。
  用 `CHIZURU_BACKUP_KEEP` 调整（`0` = 不限制）。

## 主题内的命令

| 命令 | 说明 |
| --- | --- |
| `chizuru-info` | 显示本机探测结果（色彩模式 / 实时引擎 / IP 后端 等） |
| `chizuru-update` | 手动更新主题 |
| `chizuru-backups` | 列出主题备份 |
| `chizuru-backup-prune [N]` | 手动清理主题备份 |
| `chizuru-color-mode [模式]` | 强制色彩模式：`truecolor` / `256` / `basic` / `none` |
| `chizuru-show-ip` / `chizuru-disable-ip` | 显示 / 隐藏 IP 行 |
| `chizuru-show-ipv6` / `chizuru-disable-ipv6` | IPv4 only ⇄ IPv4 + IPv6 |
| `chizuru-show-virtual-nic` / `chizuru-disable-virtual-nic` | 是否包含虚拟网卡 |
| `chizuru-show-hostname` / `chizuru-disable-hostname` | 显示 / 隐藏主机名 |
| `chizuru-show-container` / `chizuru-disable-container` | 显示 / 隐藏 Container / WSL 标签 |
| `chizuru-realtime-on` / `chizuru-realtime-off` | 开关每秒刷新 |
| `chizuru-nic-list` | 显示网卡的分类结果（physical / virtual） |
| `historys` / `back` | 目录跳转历史 |

  这些开关也可以在 `source` 主题**之前**写进 `~/.zshrc`，例如：

  ```zsh
  CHIZURU_SHOW_IPV6=1
  CHIZURU_SHOW_VIRTUAL_NIC=1
  ZSH_THEME="Chizuru"
  ```

---

# 旧版安装脚本留下的 ~/.zshrc 重复行

  旧版脚本会往 `~/.zshrc` 追加 `source .../zsh-autosuggestions.zsh` 之类的行，
  重复执行就会重复追加。**新版安装脚本会自动清理这些行**并改用 `plugins=()` 数组。

  只想手动清理的话：

  ```
  cp ~/.zshrc ~/.zshrc.bak.$(date +%Y%m%d%H%M%S) && \
  sed -i -E '\#^[[:space:]]*source[[:space:]]+.*zsh-autosuggestions\.zsh[[:space:]]*$#d;\#^[[:space:]]*source[[:space:]]+.*zsh-syntax-highlighting\.zsh[[:space:]]*$#d;\#^[[:space:]]*source[[:space:]]+.*incr-0\.2\.zsh[[:space:]]*$#d' ~/.zshrc
  ```
