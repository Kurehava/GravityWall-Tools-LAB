# author：橘陽 (kurehava) ちずる
# Minimal twoline prompt (with dynamic IP/host + container tag)

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
  | awk '$2=="UP"{for(i=3;i<=NF;i++) a[++n]=$i}
         END{for(i=1;i<=n;i++) printf "%s%s",a[i],(i<n?", ":"")}'
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
  local is_container=0

  if command -v systemd-detect-virt >/dev/null 2>&1; then
    if systemd-detect-virt -cq 2>/dev/null; then
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
    container_line=$'%F{#75C8FF}[Container]%f\n'
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

    path_c="`pwd`"
    yellow_c="%F{yellow}"
    red_c="%F{red}"
    cyan_c="%F{cyan}"
    write_c="%F{white}"
    green_c="%F{green}"
    cp_fn

    PROMPT=$'${container_line}${green_c}[${host_tag}]${yellow_c}[%D{%H:%M:%S}]\n[IP: ${ip_addr}]\n${use_color}|-%d\n${use_color}|-%n${yellow_c}::${cyan_c}%C${yellow_c}::${use_color}# ${write_c}'
}

NEWLINE_BEFORE_PROMPT=yes

if [ "$color_prompt" = yes ]; then
    VIRTUAL_ENV_DISABLE_PROMPT=1
    configure_prompt
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
