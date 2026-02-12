# author：橘陽 (kurehava) ちずる
# Based Kali ZSH Theme.
# Minimal twoline prompt (with dynamic IP/host + container tag)

THEME_NAME="Chizuru"
THEME_VERSION="2026.02.12.6"
THEME_GITHUB_RAW_URL="https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/refs/heads/main/1.SystemScripts/LinuxScripts/ZSH/Chizuru.zsh-theme"
THEME_HOST_FALLBACK_NAME="Chizuru"
typeset -g THEME_SELF_FILE="${(%):-%x}"

# ---------------------------
# User-configurable display name (highest priority)
# - default empty: show hostname
# - set: show this value instead of hostname
# ---------------------------
typeset -g display_name=""

# ---------------------------
# Toggle switches (runtime)
# ---------------------------
typeset -g CHIZURU_SHOW_IP="${CHIZURU_SHOW_IP:-1}"
typeset -g CHIZURU_SHOW_HOSTNAME="${CHIZURU_SHOW_HOSTNAME:-1}"
typeset -g CHIZURU_SHOW_CONTAINER="${CHIZURU_SHOW_CONTAINER:-1}"

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

__prompt_env_tag() {
  local env=""
  if [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
    env="$CONDA_DEFAULT_ENV"
  elif [[ -n "${VIRTUAL_ENV:-}" ]]; then
    env="${VIRTUAL_ENV:t}"
  fi
  [[ -n "$env" ]] && print -r -- "$env"
}

__prompt_host_tag() {
  # Priority:
  # 1) display_name (if set)
  # 2) hostname
  # 3) THEME_HOST_FALLBACK_NAME
  local h=""
  if [[ -n "${display_name:-}" ]]; then
    h="$display_name"
    print -r -- "$h"
    return
  fi
  h="$(hostname -s 2>/dev/null)"
  [[ -z "$h" ]] && h="$(hostname 2>/dev/null)"
  [[ -z "$h" ]] && h="${THEME_HOST_FALLBACK_NAME:-Chizuru}"
  print -r -- "$h"
}

typeset -g ip_addr=""
typeset -g host_tag="${THEME_HOST_FALLBACK_NAME:-Chizuru}"
typeset -g env_tag=""
typeset -g env_prefix=""
typeset -g container_line=""
typeset -g time_str=""
typeset -g hnode_count=0
typeset -g __ip_addr_last=""
typeset -g __host_tag_last=""
typeset -g __env_tag_last=""
typeset -g __time_str_last=""
typeset -g __hnode_count_last=0

# ---------------------------
# Directory jump history (in-memory)
# - record "previous directory" on each chpwd
# - historys: list or jump (truncate after jumping)
# - back: jump to last recorded previous dir (truncate)
# - max 1000
# ---------------------------
typeset -ga __cd_history
typeset -g __cd_last_pwd=""

__cd_history_push() {
  local old="$1"
  [[ -z "$old" ]] && return
  # ignore duplicates at tail
  if (( ${#__cd_history[@]} > 0 )) && [[ "${__cd_history[-1]}" == "$old" ]]; then
    return
  fi
  __cd_history+=("$old")
  # trim to max 1000 (drop oldest)
  while (( ${#__cd_history[@]} > 1000 )); do
    __cd_history[1]=()
  done
  hnode_count=${#__cd_history[@]}
}

__cd_history_truncate_from() {
  # remove entries from index..end (inclusive)
  local idx="$1"
  local n=${#__cd_history[@]}
  if (( n <= 0 )); then
    hnode_count=0
    return
  fi
  if (( idx < 1 || idx > n )); then
    return 1
  fi
  __cd_history[$idx,-1]=()
  hnode_count=${#__cd_history[@]}
}

historys() {
  local n=${#__cd_history[@]}
  if (( n == 0 )); then
    echo "no result"
    return 0
  fi

  if [[ -z "${1:-}" ]]; then
    local i=1
    for (( i=1; i<=n; i++ )); do
      # align index to 4 chars (fits 1000 max), and keep paths aligned
      printf "%4d: %s\n" "$i" "${__cd_history[i]}"
    done
    return 0
  fi

  local idx="$1"
  if ! [[ "$idx" =~ '^[0-9]+$' ]]; then
    echo "Usage: historys [index]"
    return 1
  fi
  if (( idx < 1 || idx > n )); then
    echo "Index out of range (1..$n)"
    return 1
  fi

  local target="${__cd_history[idx]}"
  # cd first, then truncate idx..end
  builtin cd -- "$target" || return 1
  __cd_history_truncate_from "$idx" >/dev/null
  zle && zle reset-prompt
}

back() {
  local n=${#__cd_history[@]}
  if (( n == 0 )); then
    echo "no result"
    return 0
  fi
  local target="${__cd_history[-1]}"
  builtin cd -- "$target" || return 1
  __cd_history_truncate_from "$n" >/dev/null
  zle && zle reset-prompt
}

chpwd() {
  # record previous dir (before this cd) if known
  if [[ -n "${__cd_last_pwd:-}" && "${__cd_last_pwd}" != "$PWD" ]]; then
    __cd_history_push "$__cd_last_pwd"
  fi
  __cd_last_pwd="$PWD"
  zle && zle reset-prompt
}

# init last pwd
__cd_last_pwd="$PWD"
hnode_count=${#__cd_history[@]}

__detect_container_line() {
  # Priority:
  # 1) Real container => [Container]
  # 2) WSL (not in container) => [WSL1]/[WSL2]
  # 3) else => empty

  local detected=""
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
    detected="%F{#75C8FF}[Container]%f"$'\n'
  else
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
      detected="%F{#75C8FF}[${wsl_ver}]%f"$'\n'
    else
      detected=""
    fi
  fi

  if [[ "${CHIZURU_SHOW_CONTAINER:-1}" == "1" ]]; then
    container_line="$detected"
  else
    container_line=""
  fi
}
__detect_container_line

__refresh_prompt_vars() {
  __detect_container_line

  local now_ip="$(__prompt_ipv4_up)"
  local now_host="$(__prompt_host_tag)"
  local now_env="$(__prompt_env_tag)"

  host_tag="$now_host"
  env_tag="$now_env"
  if [[ -n "$env_tag" ]]; then
    # reddish-orange for venv/conda tag (including brackets)
    # IMPORTANT: restore green after env tag so host/hnode stays green
    env_prefix="%F{#FF8A3D}[${env_tag}]%f%F{green}"
  else
    env_prefix=""
  fi

  if [[ -z "$now_ip" ]]; then
    now_ip="$(ifconfig ens160 2>/dev/null | grep -o '[0-9]\+\(\.[0-9]\+\)\{3\}' | head -1)"
  fi
  ip_addr="$now_ip"

  time_str="$(date +%H:%M:%S 2>/dev/null)"
  hnode_count=${#__cd_history[@]}
}

__refresh_prompt_vars
__ip_addr_last="$ip_addr"
__host_tag_last="$host_tag"
__env_tag_last="$env_tag"
__time_str_last="$time_str"
__hnode_count_last=$hnode_count

# --- REALTIME CLOCK (idle refresh) ---
# Important: enable TMOUT option in zsh, otherwise TMOUT won't generate ALRM.
TMOUT=1
TRAPALRM() {
  __refresh_prompt_vars
  __ip_addr_last="$ip_addr"
  __host_tag_last="$host_tag"
  __env_tag_last="$env_tag"
  __time_str_last="$time_str"
  __hnode_count_last=$hnode_count
  zle && zle reset-prompt
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

    # IMPORTANT:
    # These parts MUST keep ${var} as literal for prompt-time expansion.
    # Use single quotes for the pieces that contain ${...}.
    local host_part=""
    if [[ "${CHIZURU_SHOW_HOSTNAME:-1}" == "1" ]]; then
      host_part='[${host_tag}]'
    else
      host_part=''
    fi

    local hnode_part='%F{#FF8A3D}[hnode: ${hnode_count}]%f'
    local time_part='%F{#C205E9}[${time_str}]%f'

    local ip_line=''
    if [[ "${CHIZURU_SHOW_IP:-1}" == "1" ]]; then
      ip_line='${yellow_c}[IP: ${ip_addr}]%f'$'\n'
    else
      ip_line=''
    fi

    PROMPT=$'${container_line}${green_c}${env_prefix}'"${host_part}${hnode_part}"$'${yellow_c}'"${time_part}"$'\n'"${ip_line}"$'${use_color}|-%d\n${use_color}|-%n${yellow_c}::${cyan_c}%C${yellow_c}::${use_color}# ${write_c}'
}

NEWLINE_BEFORE_PROMPT=yes

# ---------------------------
# Theme self-update (check EVERY login; no-network => ignore)
# - Compare numeric dotted versions properly (e.g. 2026.01.15.10 > 2026.01.15.2)
# - Strong guardrails against bad remote content / human mistakes
# ---------------------------

typeset -g __THEME_UPDATE_RELOADING="${__THEME_UPDATE_RELOADING:-0}"

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
  echo "Theme updated to $remote_ver."

  # Auto-apply changes
  local zrc="${ZDOTDIR:-$HOME}/.zshrc"
  __THEME_UPDATE_RELOADING=1
  if [[ -r "$zrc" ]]; then
    source "$zrc"
  else
    source "$self_file"
  fi
  __THEME_UPDATE_RELOADING=0

  zle && zle reset-prompt
}

__theme_check_update_on_login() {
  [[ -o interactive ]] || return 0
  [[ "${__THEME_UPDATE_RELOADING:-0}" == "1" ]] && return 0

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

# Manual update command
chizuru-update() { theme-update "$@"; }

# Toggle commands (apply immediately)
chizuru-show-ip() { CHIZURU_SHOW_IP=1; configure_prompt; zle && zle reset-prompt }
chizuru-disable-ip() { CHIZURU_SHOW_IP=0; configure_prompt; zle && zle reset-prompt }
chizuru-show-hostname() { CHIZURU_SHOW_HOSTNAME=1; configure_prompt; zle && zle reset-prompt }
chizuru-disable-hostname() { CHIZURU_SHOW_HOSTNAME=0; configure_prompt; zle && zle reset-prompt }
chizuru-show-container() { CHIZURU_SHOW_CONTAINER=1; __detect_container_line; configure_prompt; zle && zle reset-prompt }
chizuru-disable-container() { CHIZURU_SHOW_CONTAINER=0; __detect_container_line; configure_prompt; zle && zle reset-prompt }
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
