# author：橘陽 (kurehava) ちずる
# Based Kali ZSH Theme.
# Minimal twoline prompt (with dynamic IP/host + container tag)

THEME_NAME="sysinfo"
THEME_VERSION="2026.01.15.1"
THEME_GITHUB_RAW_URL="https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/refs/heads/main/1.SystemScripts/LinuxScripts/ZSH/sysinfo.zsh-theme"
typeset -g THEME_SELF_FILE="${(%):-%x}"

force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

cp_fn() {
    cp_fn_floder_path="`pwd | sed 's:/: :g' | awk '{print $NF}'`"
}

setopt prompt_subst

__prompt_ipv4_up() {
  ip -br -4 addr 2>/dev/null \
  | awk '
      $2=="UP"{
        for(i=3;i<=NF;i++){
          # only accept IPv4/mask like 1.2.3.4/24 (ignore metric, etc.)
          if($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+$/){
            a[++n]=$i
          }
        }
      }
      END{
        for(i=1;i<=n;i++){
          printf "%s%s", a[i], (i<n?", ":"")
        }
      }'
}

__prompt_host_tag() {
  local h=""
  h="$(hostname -s 2>/dev/null)"
  [[ -z "$h" ]] && h="$(hostname 2>/dev/null)"
  [[ -z "$h" ]] && h="SYSINFO"
  print -r -- "$h"
}

typeset -g ip_addr=""
typeset -g host_tag="SYSINFO"
typeset -g container_line=""
typeset -g __ip_addr_last=""
typeset -g __host_tag_last=""

__detect_container_line() {
  # Priority:
  # 1) Real container => [Container]
  # 2) WSL (not in container) => [Windows Subsystem Linux Ver.1]/[Windows Subsystem Linux Ver.2]
  # 3) else => empty

  local is_container=0
  local virt=""

  if command -v systemd-detect-virt >/dev/null 2>&1; then
    virt="$(systemd-detect-virt -c 2>/dev/null)"
    # On WSL it may return "wsl" => do NOT treat that as container
    if [[ -n "$virt" && "$virt" != "none" && "$virt" != "wsl" ]]; then
      is_container=1
    fi
  fi

  if (( ! is_container )); then
    [[ -f "/.dockerenv" || -f "/run/.containerenv" ]] && is_container=1
  fi

  if (( ! is_container )); then
    if [[ -r /proc/1/cgroup ]] && grep -Eq '(docker|containerd|kubepods|libpod|lxc)' /proc/1/cgroup 2>/dev/null; then
      is_container=1
    fi
  fi

  if (( is_container )); then
    container_line="%F{#75C8FF}[Container]%f"$'\n'
    return
  fi

  local is_wsl=0
  local wsl_ver=""
  local osrel=""

  if [[ -n "$WSL_INTEROP" || -n "$WSL_DISTRO_NAME" || -n "$WSLENV" ]]; then
    is_wsl=1
  fi

  osrel="$(cat /proc/sys/kernel/osrelease 2>/dev/null)"
  [[ -z "$osrel" ]] && osrel="$(uname -r 2>/dev/null)"

  if (( ! is_wsl )); then
    echo "$osrel" | grep -qi microsoft && is_wsl=1
    if (( ! is_wsl )); then
      grep -qi microsoft /proc/version 2>/dev/null && is_wsl=1
    fi
  fi

  if (( is_wsl )); then
    # WSL2: WSL_INTEROP present OR osrelease matches common WSL2 patterns
    if [[ -n "$WSL_INTEROP" ]] || echo "$osrel" | grep -qiE '(wsl2|microsoft-standard)'; then
      wsl_ver="Windows Subsystem Linux Ver.2"
    else
      wsl_ver="Windows Subsystem Linux Ver.1"
    fi
    container_line="%F{#75C8FF}[${wsl_ver}]%f"$'\n'
  else
    container_line=""
  fi
}
__detect_container_line

__refresh_prompt_vars() {
  local now_ip="$(__prompt_ipv4_up)"
  local now_host="$(__prompt_host_tag)"

  host_tag="$now_host"

  if [[ -z "$now_ip" ]]; then
    now_ip="$(ifconfig ens160 2>/dev/null | grep -o '[0-9]\+\(\.[0-9]\+\)\{3\}' | head -1)"
  fi
  ip_addr="$now_ip"
}

__refresh_prompt_vars
__ip_addr_last="$ip_addr"
__host_tag_last="$host_tag"

TMOUT=3
TRAPALRM() {
  __refresh_prompt_vars
  if [[ "$ip_addr" != "$__ip_addr_last" || "$host_tag" != "$__host_tag_last" ]]; then
    __ip_addr_last="$ip_addr"
    __host_tag_last="$host_tag"
    zle && zle reset-prompt
  fi
}

configure_prompt() {
    if [ "`whoami`" = "root" ];then
        use_color="%F{red}"
    else
        use_color="%F{green}"
    fi

    yellow_c="%F{yellow}"
    cyan_c="%F{cyan}"
    write_c="%F{white}"
    green_c="%F{green}"
    cp_fn

    PROMPT=$'${container_line}${green_c}[${host_tag}]${yellow_c}[%D{%H:%M:%S}]\n[IP: ${ip_addr}]\n${use_color}|-%d\n${use_color}|-%n${yellow_c}::${cyan_c}%C${yellow_c}::${use_color}# ${write_c}'
}

NEWLINE_BEFORE_PROMPT=yes

# ---------------------------
# Theme self-update (check EVERY login; no-network => ignore)
# - Compare numeric dotted versions properly (e.g. 2026.01.15.10 > 2026.01.15.2)
# - Strong guardrails against bad remote content / human mistakes
# ---------------------------

__theme_version_is_valid() {
  # Accept only dotted numeric versions: 1.2.3 / 2026.01.15.1 etc.
  [[ "$1" =~ '^[0-9]+(\.[0-9]+)*$' ]]
}

__theme_version_cmp() {
  # returns:
  #   0 => equal
  #   1 => a > b
  # 255 => a < b  (use 255 to represent -1)
  local a="$1" b="$2"
  local -a A B
  local i max

  A=("${(@s:.:)a}")
  B=("${(@s:.:)b}")

  (( ${#A} > ${#B} )) && max=${#A} || max=${#B}

  for (( i=1; i<=max; i++ )); do
    local ai="${A[i]:-0}"
    local bi="${B[i]:-0}"

    ai="${ai##0}"; [[ -z "$ai" ]] && ai=0
    bi="${bi##0}"; [[ -z "$bi" ]] && bi=0

    if (( 10#$ai > 10#$bi )); then
      return 1
    elif (( 10#$ai < 10#$bi )); then
      return 255
    fi
  done
  return 0
}

__theme_get_remote_version() {
  command -v curl >/dev/null 2>&1 || return 1

  local content
  content="$(curl -fsSL --max-time 2 "$THEME_GITHUB_RAW_URL" 2>/dev/null)" || return 1

  # Sanity checks: remote must look like our theme (avoid HTML/404/other file)
  echo "$content" | grep -q '^THEME_VERSION=' || return 1
  echo "$content" | grep -q '^THEME_GITHUB_RAW_URL=' || return 1

  local v
  v="$(echo "$content" | head -n 80 | awk -F'"' '/^THEME_VERSION=/{print $2; exit}')" || return 1
  [[ -n "$v" ]] || return 1
  print -r -- "$v"
}

theme-update() {
  command -v curl >/dev/null 2>&1 || { echo "curl not found"; return 1; }

  local self_file="${THEME_SELF_FILE:-}"

  # Make absolute if possible (zsh feature)
  [[ -n "$self_file" ]] && self_file="${self_file:A}"

  # If still empty, fallback to funcfiletrace (last resort)
  if [[ -z "$self_file" && -n "${funcfiletrace[1]-}" ]]; then
    self_file="${funcfiletrace[1]%%:*}"
    [[ -n "$self_file" ]] && self_file="${self_file:A}"
  fi

  [[ -z "$self_file" || ! -w "$self_file" ]] && { echo "Cannot write theme file: $self_file"; return 1; }

  local tmp="${self_file}.tmp.$$"
  if ! curl -fsSL --max-time 10 "$THEME_GITHUB_RAW_URL" -o "$tmp"; then
    echo "Download failed"
    rm -f "$tmp" 2>/dev/null
    return 1
  fi

  # Guardrails: downloaded file must include these key lines
  if ! grep -q '^THEME_VERSION=' "$tmp" 2>/dev/null; then
    echo "Downloaded file looks invalid (missing THEME_VERSION=). Abort."
    rm -f "$tmp" 2>/dev/null
    return 1
  fi
  if ! grep -q '^THEME_GITHUB_RAW_URL=' "$tmp" 2>/dev/null; then
    echo "Downloaded file looks invalid (missing THEME_GITHUB_RAW_URL=). Abort."
    rm -f "$tmp" 2>/dev/null
    return 1
  fi

  local remote_ver
  remote_ver="$(awk -F'"' '/^THEME_VERSION=/{print $2; exit}' "$tmp" 2>/dev/null)"

  if ! __theme_version_is_valid "$remote_ver"; then
    echo "Remote THEME_VERSION is invalid: '$remote_ver'. Abort."
    rm -f "$tmp" 2>/dev/null
    return 1
  fi
  if ! __theme_version_is_valid "$THEME_VERSION"; then
    echo "Local THEME_VERSION is invalid: '$THEME_VERSION'. Abort."
    rm -f "$tmp" 2>/dev/null
    return 1
  fi

  __theme_version_cmp "$remote_ver" "$THEME_VERSION"
  local cmp_rc=$?

  if [[ $cmp_rc -eq 0 ]]; then
    echo "Already up to date."
    rm -f "$tmp" 2>/dev/null
    return 0
  elif [[ $cmp_rc -eq 255 ]]; then
    echo "Remote version ($remote_ver) is older than local ($THEME_VERSION). Abort (no downgrade)."
    rm -f "$tmp" 2>/dev/null
    return 1
  fi

  cp -a "$self_file" "${self_file}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null
  mv -f "$tmp" "$self_file"

  # Auto reload
  typeset -g __THEME_RELOADING=1
  if [[ -r "$HOME/.zshrc" ]]; then
    source "$HOME/.zshrc"
  else
    source "$self_file"
  fi
  unset __THEME_RELOADING

  echo "Theme updated to $remote_ver and reloaded."
}

__theme_check_update_on_login() {
  [[ -o interactive ]] || return 0
  [[ -n "${__THEME_RELOADING-}" ]] && return 0

  if ! __theme_version_is_valid "$THEME_VERSION"; then
    print -P "%F{red}[Theme]%f Local THEME_VERSION invalid: %F{yellow}${THEME_VERSION}%f. Skip update check."
    return 0
  fi

  local remote_ver
  remote_ver="$(__theme_get_remote_version)" || return 0   # no network => ignore
  [[ -n "$remote_ver" ]] || return 0

  if ! __theme_version_is_valid "$remote_ver"; then
    print -P "%F{yellow}[Theme]%f Remote THEME_VERSION invalid (%F{red}${remote_ver}%f). Skip."
    return 0
  fi

  __theme_version_cmp "$remote_ver" "$THEME_VERSION"
  local cmp_rc=$?

  if [[ $cmp_rc -eq 0 ]]; then
    return 0
  elif [[ $cmp_rc -eq 255 ]]; then
    # remote < local => do nothing (avoid accidental downgrade)
    return 0
  fi

  # remote > local => ask Y/N
  local ans=""
  print -P "%F{yellow}[Theme]%f Update available: %F{cyan}${remote_ver}%f (local: ${THEME_VERSION}). Update now? [Y/n] \c"
  if read -r -k 1 ans </dev/tty 2>/dev/null; then
    print ""
  else
    read -r ans
  fi

  if [[ -z "$ans" || "$ans" == [Yy] ]]; then
    theme-update
  else
    print -P "%F{yellow}[Theme]%f Skipped."
  fi
}
# ---------------------------

if [ "$color_prompt" = yes ]; then
    VIRTUAL_ENV_DISABLE_PROMPT=1
    configure_prompt

    # Check update every login (no network => silently ignore)
    __theme_check_update_on_login

    if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
        ZSH_HIGHLIGHT_STYLES[default]=none
        ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=white,underline
        ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
        ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[global-alias]=fg=green,bold
        ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[autodirectory]=fg=green,underline
        ZSH_HIGHLIGHT_STYLES[path]=bold
        ZSH_HIGHLIGHT_STYLES[path_pathseparator]=
        ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]=
        ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[command-substitution]=none
        ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[process-substitution]=none
        ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=green
        ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=green
        ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
        ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]=fg=yellow
        ZSH_HIGHLIGHT_STYLES[rc-quote]=fg=magenta
        ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[assign]=none
        ZSH_HIGHLIGHT_STYLES[redirection]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
        ZSH_HIGHLIGHT_STYLES[named-fd]=none
        ZSH_HIGHLIGHT_STYLES[numeric-fd]=none
        ZSH_HIGHLIGHT_STYLES[arg0]=fg=cyan
        ZSH_HIGHLIGHT_STYLES[bracket-error]=fg=red,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-1]=fg=blue,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-2]=fg=green,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-3]=fg=magenta,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-4]=fg=yellow,bold
        ZSH_HIGHLIGHT_STYLES[bracket-level-5]=fg=cyan,bold
        ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
    fi
else
    PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%(#.#.$) '
fi
unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty)
    TERM_TITLE=$'\e]0;${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%n@%m: %~\a'
    ;;
*)
    ;;
esac

precmd() {
    __refresh_prompt_vars
    print -Pnr -- "$TERM_TITLE"
    if [ "$NEWLINE_BEFORE_PROMPT" = yes ]; then
        if [ -z "$_NEW_LINE_BEFORE_PROMPT" ]; then
            _NEW_LINE_BEFORE_PROMPT=1
        else
            print ""
        fi
    fi
}

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    export LS_COLORS="$LS_COLORS:ow=30;44:"

    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
fi
