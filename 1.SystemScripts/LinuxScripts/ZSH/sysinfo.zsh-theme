# author：橘陽 (kurehava) ちずる
# Minimal twoline prompt (with dynamic IP/host + container tag)

force_color_prompt=yes

# Color support check
if [[ -n "$force_color_prompt" ]]; then
  if [[ -x /usr/bin/tput ]] && tput setaf 1 >&/dev/null; then
    color_prompt=yes
  else
    color_prompt=
  fi
fi

# --- Prompt config ---
setopt prompt_subst
VIRTUAL_ENV_DISABLE_PROMPT=1

# UP IPv4 (with mask), one line, ", " separated
__prompt_ipv4_up() {
  ip -br -4 addr 2>/dev/null \
  | awk '$2=="UP"{for(i=3;i<=NF;i++) a[++n]=$i}
         END{for(i=1;i<=n;i++) printf "%s%s",a[i],(i<n?", ":"")}'
}

# Host tag: hostname -s -> hostname -> SYSINFO
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

# One-time container detect; show [Container] on its own line above [HOST]
__detect_container_line() {
  local is_container=0

  if command -v systemd-detect-virt >/dev/null 2>&1; then
    systemd-detect-virt -cq 2>/dev/null && is_container=1
  fi
  (( ! is_container )) && [[ -f "/.dockerenv" || -f "/run/.containerenv" ]] && is_container=1
  if (( ! is_container )) && [[ -r /proc/1/cgroup ]]; then
    grep -Eq '(docker|containerd|kubepods|libpod|lxc)' /proc/1/cgroup 2>/dev/null && is_container=1
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

  # Fallback if no UP IPv4
  if [[ -z "$now_ip" ]]; then
    now_ip="$(ifconfig ens160 2>/dev/null | grep -o '[0-9]\+\(\.[0-9]\+\)\{3\}' | head -1)"
  fi
  ip_addr="$now_ip"
}

__refresh_prompt_vars
__ip_addr_last="$ip_addr"
__host_tag_last="$host_tag"

# Update in idle time
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
  local use_color
  if [[ $EUID -eq 0 ]]; then
    use_color="%F{red}"
  else
    use_color="%F{green}"
  fi

  local yellow_c="%F{yellow}"
  local cyan_c="%F{cyan}"
  local write_c="%F{white}"
  local green_c="%F{green}"

  PROMPT=$'${container_line}'\
$'${green_c}[${host_tag}]${yellow_c}[%D{%H:%M:%S}]\n'\
$'[IP: ${ip_addr}]\n'\
$'${use_color}|-%d\n'\
$'${use_color}|-%n${yellow_c}::${cyan_c}%C${yellow_c}::${use_color}# ${write_c}'
}

# START KALI CONFIG VARIABLES
NEWLINE_BEFORE_PROMPT=yes
# STOP KALI CONFIG VARIABLES

if [[ "$color_prompt" = yes ]]; then
  configure_prompt
else
  PROMPT='%n@%m:%~%(#.#.$) '
fi
unset color_prompt force_color_prompt

# Terminal title
case "$TERM" in
  xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty)
    TERM_TITLE=$'\e]0;${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%n@%m: %~\a'
    ;;
  *)
    TERM_TITLE=""
    ;;
esac

precmd() {
  __refresh_prompt_vars
  [[ -n "$TERM_TITLE" ]] && print -Pnr -- "$TERM_TITLE"

  if [[ "$NEWLINE_BEFORE_PROMPT" = yes ]]; then
    if [[ -z "$_NEW_LINE_BEFORE_PROMPT" ]]; then
      _NEW_LINE_BEFORE_PROMPT=1
    else
      print ""
    fi
  fi
}

# Syntax highlighting (optional; keep if installed)
if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
fi
