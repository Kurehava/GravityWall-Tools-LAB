# author：橘陽 (kurehava) ちずる
# Based Kali ZSH Theme.
# Minimal twoline prompt (with dynamic IP/host + container tag)
#
# ============================================================================
#  VERSION-AGNOSTIC EDITION
#
#  Target: zsh 4.3.11 ... 5.0.2 ... 5.9 ... and newer.
#
#  Design rule: NOTHING in this file may hard-depend on a zsh feature,
#  a module, or an external command that might not exist.  Every such use is
#  probed once at load time and degrades gracefully:
#
#    24bit color  %F{#RRGGBB}  (zsh >= 5.7)   -> xterm-256 index -> basic name
#    zle reset-prompt -f nolast (zsh >= 5.9)  -> guarded redraw  -> precmd only
#    zsh/zpty + zle -F ticker                 -> TRAPALRM (opt-in) -> precmd only
#    zsh/datetime strftime                    -> date(1)
#    ip -br addr  (iproute2 >= 4.x)           -> ip -o addr -> ifconfig -> hostname -I
#    GNU ls/grep/diff/ip --color options      -> probed before aliasing
#    add-zsh-hook precmd/chpwd                -> plain precmd()/chpwd()
#
#  Notable fixes vs. the original file:
#    * removed the `unset CHIZURU_*` block, which contradicted the documented
#      "you may set these in ~/.zshrc before sourcing" behaviour
#    * container/WSL + hostname detection is now cached (no fork per prompt)
#    * array element deletion no longer relies on `arr[i]=()`
#    * =~ regex matching replaced by plain zsh globs (no zsh/regex dependency)
# ============================================================================

if [[ "$(tty)" == "/dev/ttyS0" && "$TERM" == "vt220" ]]; then
    export TERM=xterm-256color
fi

THEME_NAME="Chizuru"
THEME_VERSION="2026.09.16.3"
THEME_GITHUB_RAW_URL="https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB/refs/heads/main/1.SystemScripts/LinuxScripts/ZSH/Chizuru.zsh-theme"
THEME_HOST_FALLBACK_NAME="Chizuru"
typeset -g THEME_SELF_FILE="${(%):-%x}"

setopt prompt_subst

# ===========================================================================
# 0. zsh version / capability probing
# ===========================================================================

typeset -gi __chizuru_v_major=0 __chizuru_v_minor=0 __chizuru_v_patch=0

__chizuru_parse_zsh_version() {
  local ver="${ZSH_VERSION%%-*}"
  local -a p
  local x
  p=("${(@s:.:)ver}")

  x="${p[1]:-0}"; x="${x//[^0-9]/}"; [[ -n "$x" ]] || x=0; __chizuru_v_major=$x
  x="${p[2]:-0}"; x="${x//[^0-9]/}"; [[ -n "$x" ]] || x=0; __chizuru_v_minor=$x
  x="${p[3]:-0}"; x="${x//[^0-9]/}"; [[ -n "$x" ]] || x=0; __chizuru_v_patch=$x
}
__chizuru_parse_zsh_version

# __chizuru_zsh_at_least MAJOR [MINOR] [PATCH]
__chizuru_zsh_at_least() {
  local -i M=${1:-0} m=${2:-0} p=${3:-0}
  (( __chizuru_v_major > M )) && return 0
  (( __chizuru_v_major < M )) && return 1
  (( __chizuru_v_minor > m )) && return 0
  (( __chizuru_v_minor < m )) && return 1
  (( __chizuru_v_patch >= p ))
}

# zsh/datetime gives strftime + $EPOCHSECONDS => one fewer fork per second.
typeset -gi __chizuru_have_datetime=0
if zmodload zsh/datetime 2>/dev/null; then
  __chizuru_have_datetime=1
fi

# ===========================================================================
# 1. Color capability
#
# %F{#RRGGBB} only exists from zsh 5.7 onward.  On 5.0.2 it is an unknown
# color name and the prompt silently loses its accent colors, so the accents
# are resolved once here into whatever the running zsh + terminal can do.
#
# Override with:  CHIZURU_COLOR_MODE=truecolor|256|basic|none
# ===========================================================================

typeset -gi __chizuru_term_colors=8
typeset -g  __chizuru_color_mode="basic"

typeset -g CZ_C_INFO="" CZ_C_ACCENT="" CZ_C_TIME=""
typeset -g CZ_C_RESET="" CZ_C_YELLOW="" CZ_C_GREEN="" CZ_C_CYAN="" CZ_C_WHITE=""
typeset -g CZ_C_USER=""

__chizuru_detect_term_colors() {
  local n=""

  if zmodload zsh/terminfo 2>/dev/null; then
    n="${terminfo[colors]:-}"
  fi

  if [[ -z "$n" || "$n" == *[^0-9]* ]]; then
    if command -v tput >/dev/null 2>&1; then
      n="$(command tput colors 2>/dev/null)"
    fi
  fi

  if [[ -z "$n" || "$n" == *[^0-9]* ]]; then
    # last resort: guess from $TERM
    case "${TERM:-}" in
      *-direct*)           n=16777216 ;;
      *256color*|*-256*)   n=256 ;;
      ""|dumb)             n=0 ;;
      *)                   n=8 ;;
    esac
  fi

  __chizuru_term_colors=$n
}

__chizuru_detect_color_mode() {
  if [[ -n "${CHIZURU_COLOR_MODE:-}" ]]; then
    __chizuru_color_mode="$CHIZURU_COLOR_MODE"
    return
  fi

  if [[ -z "${TERM:-}" || "${TERM}" == dumb ]]; then
    __chizuru_color_mode="none"
    return
  fi

  if (( __chizuru_term_colors < 8 )); then
    __chizuru_color_mode="none"
  elif (( __chizuru_term_colors < 256 )); then
    __chizuru_color_mode="basic"
  elif __chizuru_zsh_at_least 5 7; then
    # zsh >= 5.7 understands #RRGGBB and downsamples on its own when the
    # terminal is not 24bit capable.
    __chizuru_color_mode="truecolor"
  else
    __chizuru_color_mode="256"
  fi
}

__chizuru_build_colors() {
  __chizuru_detect_term_colors
  __chizuru_detect_color_mode

  case "$__chizuru_color_mode" in
    truecolor)
      CZ_C_INFO="%F{#75C8FF}"   # container / WSL tag
      CZ_C_ACCENT="%F{#FF8A3D}" # venv / conda tag, hnode counter
      CZ_C_TIME="%F{#C205E9}"   # clock
      ;;
    256)
      # nearest xterm-256 cube entries for the three accents above
      CZ_C_INFO="%F{117}"
      CZ_C_ACCENT="%F{209}"
      CZ_C_TIME="%F{128}"
      ;;
    basic)
      CZ_C_INFO="%F{cyan}"
      CZ_C_ACCENT="%F{yellow}"
      CZ_C_TIME="%F{magenta}"
      ;;
    *)
      __chizuru_color_mode="none"
      CZ_C_INFO=""; CZ_C_ACCENT=""; CZ_C_TIME=""
      ;;
  esac

  if [[ "$__chizuru_color_mode" == "none" ]]; then
    CZ_C_RESET=""; CZ_C_YELLOW=""; CZ_C_GREEN=""; CZ_C_CYAN=""; CZ_C_WHITE=""
    CZ_C_USER=""
  else
    CZ_C_RESET="%f"
    CZ_C_YELLOW="%F{yellow}"
    CZ_C_GREEN="%F{green}"
    CZ_C_CYAN="%F{cyan}"
    CZ_C_WHITE="%F{white}"
    # %(#.A.B) is evaluated at prompt time, so su/sudo -s recolors live
    CZ_C_USER='%(#.%F{red}.%F{green})'
  fi
}
__chizuru_build_colors

# ---------------------------
# User-configurable display name (highest priority)
# - default empty: show hostname
# - set: show this value instead of hostname
# ---------------------------
typeset -g display_name="${display_name:-}"

# ---------------------------
# Toggle switches (runtime)
#
# All switches honour a pre-set environment value, so they can be configured
# in ~/.zshrc BEFORE this theme is sourced, e.g.
#     CHIZURU_SHOW_IPV6=1
#     CHIZURU_SHOW_VIRTUAL_NIC=1
# ---------------------------
typeset -g CHIZURU_SHOW_IP="${CHIZURU_SHOW_IP:-1}"

# IP family to display
#   0 : IPv4 only            -> [IP: 192.168.0.10/24]
#   1 : IPv4 + IPv6          -> [IPv4: ...] / [IPv6: ...]  (two lines)
typeset -g CHIZURU_SHOW_IPV6="${CHIZURU_SHOW_IPV6:-0}"

# Include fe80::/10 link-local addresses (only meaningful when IPv6 is on)
typeset -g CHIZURU_SHOW_IPV6_LINKLOCAL="${CHIZURU_SHOW_IPV6_LINKLOCAL:-0}"

# NIC scope
#   0 : physical NIC only    (eth0 / ens160 / wlan0 ... )
#   1 : physical + virtual   (docker0 / br-* / veth* / tun* / wg* / bond* ...)
typeset -g CHIZURU_SHOW_VIRTUAL_NIC="${CHIZURU_SHOW_VIRTUAL_NIC:-0}"

# Safety net for "physical only" mode.
typeset -g CHIZURU_NIC_FALLBACK_ANY="${CHIZURU_NIC_FALLBACK_ANY:-1}"

typeset -g CHIZURU_SHOW_HOSTNAME="${CHIZURU_SHOW_HOSTNAME:-1}"
typeset -g CHIZURU_SHOW_CONTAINER="${CHIZURU_SHOW_CONTAINER:-1}"

# Realtime (per-second) clock/IP refresh.  0 disables it completely.
typeset -g CHIZURU_REALTIME="${CHIZURU_REALTIME:-1}"

# Opt-in TMOUT/TRAPALRM fallback, used only when zsh/zpty is unavailable.
# It works on every zsh ever built, but it hijacks TMOUT and SIGALRM, so it
# stays off unless you ask for it.
typeset -g CHIZURU_REALTIME_FALLBACK="${CHIZURU_REALTIME_FALLBACK:-0}"

# How many "<theme>.bak.<timestamp>" files theme-update keeps.
#   N > 0 : keep the N newest, delete the rest
#   0     : keep everything (the original, unbounded behaviour)
typeset -g CHIZURU_BACKUP_KEEP="${CHIZURU_BACKUP_KEEP:-5}"

force_color_prompt=yes

if [[ -n "$force_color_prompt" && "$__chizuru_color_mode" != "none" ]]; then
    color_prompt=yes
else
    color_prompt=
fi

cp_fn() {
    # kept for backwards compatibility; no longer forks pwd|sed|awk
    cp_fn_floder_path="${PWD:t}"
}

# ===========================================================================
# 2. NIC classification + IP collection
#
# CentOS/RHEL 7 is the classic "zsh 5.0.2" host, and its iproute2 has no
# `ip -br`.  The backend is therefore probed once and can be any of:
#   ip-br    : ip -br -4 addr show          (iproute2 >= 4.x)
#   ip-o     : ip -o -4 addr show           (every iproute2)
#   ifconfig : net-tools, old and new output formats
#   hostname : hostname -I                  (IPv4 only, last resort)
# ===========================================================================

typeset -g __chizuru_ip_backend=""

__chizuru_detect_ip_backend() {
  [[ -n "$__chizuru_ip_backend" ]] && return 0

  if command -v ip >/dev/null 2>&1; then
    if command ip -br link show >/dev/null 2>&1; then
      __chizuru_ip_backend="ip-br"
    else
      __chizuru_ip_backend="ip-o"
    fi
  elif command -v ifconfig >/dev/null 2>&1; then
    __chizuru_ip_backend="ifconfig"
  elif command -v hostname >/dev/null 2>&1; then
    __chizuru_ip_backend="hostname"
  else
    __chizuru_ip_backend="none"
  fi
  return 0
}

# /sys/class/net/<if> is a symlink:
#   physical : ../../devices/pci0000:00/.../net/ens160
#   virtual  : ../../devices/virtual/net/docker0
# ${p:A} resolves it with zsh's own modifier, so this costs no fork.
__prompt_nic_is_physical() {
  local ifc="${1%%@*}"
  [[ -z "$ifc" || "$ifc" == "lo" ]] && return 1

  # No sysfs at all (non-Linux, very stripped container): cannot classify,
  # so do not hide everything - treat it as physical.
  [[ -d /sys/class/net ]] || return 0

  local p="/sys/class/net/$ifc"
  [[ -e "$p" ]] || return 1

  # pure software NIC (bridge / veth / bond / tun / tap / wg / dummy ...)
  [[ "${p:A}" == */devices/virtual/net/* ]] && return 1

  # a real NIC is backed by a bus device (pci / usb / vmbus / platform ...)
  [[ -e "$p/device" ]] || return 1

  return 0
}

__chizuru_if_is_up() {
  local ifc="${1%%@*}"
  local st=""
  [[ -n "$ifc" ]] || return 1
  if [[ -r "/sys/class/net/$ifc/operstate" ]]; then
    st="$(<"/sys/class/net/$ifc/operstate")"
  fi
  case "$st" in
    up|unknown|"") return 0 ;;   # "" => no sysfs, assume usable
    *)             return 1 ;;
  esac
}

typeset -ga __chizuru_ip_acc

# Validate + de-duplicate one candidate address.
# Both "1.2.3.4" and "1.2.3.4/24" are accepted, because ifconfig output does
# not always carry a prefix length.
__chizuru_ip_accept() {
  local family="$1" a="$2" x

  [[ -n "$a" ]] || return 0
  a="${a%\%*}"            # strip IPv6 zone id (fe80::1%eth0)

  if [[ "$family" == "4" ]]; then
    if [[ "$a" != <0-255>.<0-255>.<0-255>.<0-255> && \
          "$a" != <0-255>.<0-255>.<0-255>.<0-255>/<0-32> ]]; then
      return 0
    fi
    [[ "$a" == 127.* ]] && return 0
  else
    [[ "$a" == *:* ]] || return 0
    [[ "$a" == *[^0-9a-fA-F:/]* ]] && return 0
    [[ "$a" == */* && "$a" != */<0-128> ]] && return 0
    [[ "$a" == "::1/128" || "$a" == "::1" ]] && return 0
    if [[ "${CHIZURU_SHOW_IPV6_LINKLOCAL:-0}" != "1" ]]; then
      [[ "${(L)a}" == fe80:* ]] && return 0
    fi
  fi

  for x in "${__chizuru_ip_acc[@]}"; do
    [[ "$x" == "$a" ]] && return 0
  done
  __chizuru_ip_acc+=("$a")
  return 0
}

__chizuru_collect_ip_br() {
  local family="$1" allow_virtual="$2"
  local -a lines fields
  local line ifc state a

  # `command` avoids the `ip --color=auto` alias defined later in this file
  # (aliases are expanded when a function is *defined*, so re-sourcing the
  #  theme would otherwise bake the alias into this function).
  lines=("${(@f)$(command ip -br -${family} addr show 2>/dev/null)}")

  for line in "${lines[@]}"; do
    [[ -n "$line" ]] || continue
    fields=(${=line})
    (( ${#fields} >= 2 )) || continue

    ifc="${fields[1]%%@*}"
    state="${fields[2]}"

    [[ "$ifc" == "lo" ]] && continue
    [[ "$state" == "UP" || "$state" == "UNKNOWN" ]] || continue

    if [[ "$allow_virtual" != "1" ]]; then
      __prompt_nic_is_physical "$ifc" || continue
    fi

    for a in "${(@)fields[3,-1]}"; do
      __chizuru_ip_accept "$family" "$a"
    done
  done
}

__chizuru_collect_ip_o() {
  # iproute2 without -br:  "2: ens160    inet 192.168.0.10/24 brd ... \ ..."
  local family="$1" allow_virtual="$2"
  local -a lines fields
  local line ifc
  local -i i

  lines=("${(@f)$(command ip -o -${family} addr show 2>/dev/null)}")

  for line in "${lines[@]}"; do
    [[ -n "$line" ]] || continue
    fields=(${=line})
    (( ${#fields} >= 4 )) || continue

    ifc="${fields[2]%%@*}"
    [[ -z "$ifc" || "$ifc" == "lo" ]] && continue
    __chizuru_if_is_up "$ifc" || continue

    if [[ "$allow_virtual" != "1" ]]; then
      __prompt_nic_is_physical "$ifc" || continue
    fi

    for (( i = 3; i <= ${#fields}; i++ )); do
      if [[ "${fields[i]}" == "inet" || "${fields[i]}" == "inet6" ]]; then
        __chizuru_ip_accept "$family" "${fields[i+1]}"
        break
      fi
    done
  done
}

typeset -g __chizuru_plen=""

# dotted / hex netmask -> prefix length (sets $__chizuru_plen)
__chizuru_mask2plen() {
  __chizuru_plen=""
  local m="$1"
  [[ -n "$m" ]] || return 1

  local -i v=0 n=0 i
  if [[ "$m" == 0[xX]* ]]; then
    m="${m#0[xX]}"
    [[ "$m" == *[^0-9a-fA-F]* ]] && return 1
    (( v = 16#$m ))
  elif [[ "$m" == <0-255>.<0-255>.<0-255>.<0-255> ]]; then
    local -a o
    o=("${(@s:.:)m}")
    (( v = (10#${o[1]} << 24) + (10#${o[2]} << 16) + (10#${o[3]} << 8) + 10#${o[4]} ))
  else
    return 1
  fi

  for (( i = 31; i >= 0; i-- )); do
    if (( (v >> i) & 1 )); then
      (( n++ ))
    else
      break
    fi
  done
  __chizuru_plen="$n"
  return 0
}

__chizuru_collect_ifconfig() {
  # Handles both output dialects:
  #   new: inet 192.168.0.10  netmask 255.255.255.0
  #   old: inet addr:192.168.0.10  Bcast:...  Mask:255.255.255.0
  #   new: inet6 fe80::1  prefixlen 64
  #   old: inet6 addr: fe80::1/64 Scope:Link
  local family="$1" allow_virtual="$2"
  local -a lines fields
  local line ifc addr plen tok
  local -i cur_ok=0 i j

  lines=("${(@f)$(command ifconfig -a 2>/dev/null || command ifconfig 2>/dev/null)}")

  for line in "${lines[@]}"; do
    [[ -n "$line" ]] || continue

    # a line that does not start with whitespace opens a new interface block
    if [[ "$line" != [[:space:]]* ]]; then
      fields=(${=line})
      ifc="${fields[1]%%:*}"
      cur_ok=1
      if [[ -z "$ifc" || "$ifc" == "lo" || "$ifc" == lo<-> ]]; then
        cur_ok=0
      fi
      if (( cur_ok )) && [[ "$allow_virtual" != "1" ]]; then
        __prompt_nic_is_physical "$ifc" || cur_ok=0
      fi
      if (( cur_ok )); then
        __chizuru_if_is_up "$ifc" || cur_ok=0
      fi
    fi

    (( cur_ok )) || continue

    fields=(${=line})
    for (( i = 1; i <= ${#fields}; i++ )); do
      tok="${fields[i]}"
      addr=""
      plen=""

      if [[ "$family" == "4" ]]; then
        if [[ "$tok" == "inet" ]]; then
          addr="${fields[i+1]:-}"
          [[ "$addr" == "addr:" ]] && addr="${fields[i+2]:-}"
          addr="${addr#addr:}"
        else
          continue
        fi
        [[ -n "$addr" ]] || continue
        for (( j = i; j <= ${#fields}; j++ )); do
          case "${fields[j]}" in
            netmask) __chizuru_mask2plen "${fields[j+1]:-}" && plen="$__chizuru_plen" ;;
            Mask:*)  __chizuru_mask2plen "${fields[j]#Mask:}" && plen="$__chizuru_plen" ;;
          esac
        done
        [[ -n "$plen" && "$addr" != */* ]] && addr="${addr}/${plen}"
        __chizuru_ip_accept 4 "$addr"
      else
        if [[ "$tok" == "inet6" ]]; then
          addr="${fields[i+1]}"
          [[ "$addr" == "addr:" ]] && addr="${fields[i+2]:-}"
          addr="${addr#addr:}"
        else
          continue
        fi
        [[ -n "$addr" ]] || continue
        if [[ "$addr" != */* ]]; then
          for (( j = i; j <= ${#fields}; j++ )); do
            [[ "${fields[j]}" == "prefixlen" ]] && plen="${fields[j+1]:-}"
          done
          [[ -n "$plen" && "$plen" != *[^0-9]* ]] && addr="${addr}/${plen}"
        fi
        __chizuru_ip_accept 6 "$addr"
      fi
    done
  done
}

__chizuru_collect_hostname() {
  local family="$1"
  [[ "$family" == "4" ]] || return 0
  local -a addrs
  local a
  addrs=(${=$(command hostname -I 2>/dev/null)})
  for a in "${addrs[@]}"; do
    __chizuru_ip_accept 4 "$a"
  done
}

# Result is returned through this global on purpose:
# calling the function via $(...) would add one fork per second.
typeset -g __prompt_ip_result=""

__prompt_collect_ip() {
  # $1: 4 | 6
  # $2: 1 => include virtual NICs, otherwise physical NICs only
  emulate -L zsh
  setopt prompt_subst

  local family="$1"
  local allow_virtual="${2:-0}"

  __prompt_ip_result=""
  __chizuru_ip_acc=()

  __chizuru_detect_ip_backend

  case "$__chizuru_ip_backend" in
    ip-br)    __chizuru_collect_ip_br    "$family" "$allow_virtual" ;;
    ip-o)     __chizuru_collect_ip_o     "$family" "$allow_virtual" ;;
    ifconfig) __chizuru_collect_ifconfig "$family" "$allow_virtual" ;;
    hostname) __chizuru_collect_hostname "$family" ;;
  esac

  __prompt_ip_result="${(j:, :)__chizuru_ip_acc}"
  return 0
}

# ===========================================================================
# 3. Static tags (env / host / container)
# ===========================================================================

__prompt_env_tag() {
  local env=""
  if [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
    env="$CONDA_DEFAULT_ENV"
  elif [[ -n "${VIRTUAL_ENV:-}" ]]; then
    env="${VIRTUAL_ENV:t}"
  fi
  [[ -n "$env" ]] && print -r -- "$env"
  return 0
}

# Hostname is resolved once; $HOST is a zsh builtin parameter, so no fork.
typeset -g __chizuru_hostname_cached=""

__chizuru_resolve_hostname() {
  local h="${HOST:-}"
  h="${h%%.*}"
  if [[ -z "$h" ]] && command -v hostname >/dev/null 2>&1; then
    h="$(command hostname -s 2>/dev/null)"
    [[ -z "$h" ]] && h="$(command hostname 2>/dev/null)"
    h="${h%%.*}"
  fi
  [[ -z "$h" ]] && h="${THEME_HOST_FALLBACK_NAME:-Chizuru}"
  __chizuru_hostname_cached="$h"
}
__chizuru_resolve_hostname

__prompt_host_tag() {
  # Priority:
  # 1) display_name (if set)
  # 2) hostname
  # 3) THEME_HOST_FALLBACK_NAME
  if [[ -n "${display_name:-}" ]]; then
    print -r -- "$display_name"
  else
    print -r -- "${__chizuru_hostname_cached:-${THEME_HOST_FALLBACK_NAME:-Chizuru}}"
  fi
}

typeset -g ip_addr=""
typeset -g ip6_addr=""
typeset -g ip_render=""
typeset -g host_tag="${THEME_HOST_FALLBACK_NAME:-Chizuru}"
typeset -g env_tag=""
typeset -g env_prefix=""
typeset -g container_line=""
typeset -g time_str=""
typeset -gi hnode_count=0
typeset -g __ip_addr_last=""
typeset -g __ip6_addr_last=""
typeset -g __host_tag_last=""
typeset -g __env_tag_last=""
typeset -g __time_str_last=""
typeset -gi __hnode_count_last=0

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
  [[ -n "$old" ]] || return 0
  # ignore duplicates at tail
  if (( ${#__cd_history[@]} > 0 )) && [[ "${__cd_history[-1]}" == "$old" ]]; then
    return 0
  fi
  __cd_history+=("$old")
  # trim to max 1000 (drop oldest).  `shift <array>` works on every zsh;
  # `arr[1]=()` does not.
  while (( ${#__cd_history[@]} > 1000 )); do
    shift __cd_history
  done
  hnode_count=${#__cd_history[@]}
  return 0
}

__cd_history_truncate_from() {
  # remove entries from index..end (inclusive)
  local -i n=${#__cd_history[@]} idx
  local raw="${1:-}"

  if (( n <= 0 )); then
    hnode_count=0
    return 0
  fi
  [[ -n "$raw" && "$raw" != *[^0-9]* ]] || return 1
  idx=$raw
  if (( idx < 1 || idx > n )); then
    return 1
  fi

  if (( idx == 1 )); then
    __cd_history=()
  else
    __cd_history=("${(@)__cd_history[1,idx-1]}")
  fi
  hnode_count=${#__cd_history[@]}
  return 0
}

# GNU-only ls options are probed once instead of assumed.
typeset -ga __chizuru_ls_opts
__chizuru_detect_ls_opts() {
  __chizuru_ls_opts=(-a)
  command ls --color=auto -d . >/dev/null 2>&1 && \
    __chizuru_ls_opts+=(--color=auto)
  command ls --group-directories-first -d . >/dev/null 2>&1 && \
    __chizuru_ls_opts+=(--group-directories-first)
}
__chizuru_detect_ls_opts

__chizuru_list_dir() {
  local target="$1"
  print -r -- "$target"
  print -r -- '---'
  command ls "${__chizuru_ls_opts[@]}" -- "$target" 2>/dev/null
}

historys() {
  emulate -L zsh
  setopt prompt_subst

  local -i n=${#__cd_history[@]}
  local -i i idx

  if (( n == 0 )); then
    print -r -- "no result"
    return 0
  fi

  if [[ -z "${1:-}" ]]; then
    for (( i = 1; i <= n; i++ )); do
      # align index to 4 chars (fits 1000 max), and keep paths aligned
      printf "%4d: %s\n" "$i" "${__cd_history[i]}"
    done
    return 0
  fi

  if [[ "$1" != <-> ]]; then
    print -r -- "Usage: historys [index]"
    return 1
  fi
  idx=$1
  if (( idx < 1 || idx > n )); then
    print -r -- "Index out of range (1..$n)"
    return 1
  fi

  local target="${__cd_history[idx]}"
  builtin cd -- "$target" || return 1
  __chizuru_list_dir "$target"
  __cd_history_truncate_from "$idx" >/dev/null
  zle && zle reset-prompt
  return 0
}

back() {
  emulate -L zsh
  setopt prompt_subst

  local -i n=${#__cd_history[@]}
  if (( n == 0 )); then
    print -r -- "no result"
    return 0
  fi

  local target="${__cd_history[-1]}"
  builtin cd -- "$target" || return 1
  __chizuru_list_dir "$target"
  __cd_history_truncate_from "$n" >/dev/null
  zle && zle reset-prompt
  return 0
}

# init last pwd
__cd_last_pwd="$PWD"
hnode_count=${#__cd_history[@]}

# ---------------------------
# Container / WSL detection
#
# This cannot change during the lifetime of a shell, so it is detected ONCE
# (the original ran systemd-detect-virt + grep on every single prompt).
# ---------------------------
typeset -g __chizuru_container_tag=""
typeset -gi __chizuru_container_probed=0

__chizuru_probe_container() {
  (( __chizuru_container_probed )) && [[ "${1:-}" != "force" ]] && return 0
  __chizuru_container_probed=1
  __chizuru_container_tag=""

  local -i is_container=0 is_wsl=0
  local virt="" osrel="" wsl_ver=""

  if command -v systemd-detect-virt >/dev/null 2>&1; then
    virt="$(command systemd-detect-virt -c 2>/dev/null)"
    # On WSL it may return "wsl" => do NOT treat that as container
    if [[ -n "$virt" && "$virt" != "none" && "$virt" != "wsl" ]]; then
      is_container=1
    fi
  fi

  if (( ! is_container )); then
    [[ -f "/.dockerenv" || -f "/run/.containerenv" ]] && is_container=1
  fi

  if (( ! is_container )) && [[ -r /proc/1/cgroup ]]; then
    local cg=""
    cg="$(<"/proc/1/cgroup")"
    case "$cg" in
      *docker*|*containerd*|*kubepods*|*libpod*|*lxc*) is_container=1 ;;
    esac
  fi

  if (( is_container )); then
    __chizuru_container_tag="[Container]"
    return 0
  fi

  if [[ -n "${WSL_INTEROP:-}" || -n "${WSL_DISTRO_NAME:-}" || -n "${WSLENV:-}" ]]; then
    is_wsl=1
  fi

  if [[ -r /proc/sys/kernel/osrelease ]]; then
    osrel="$(<"/proc/sys/kernel/osrelease")"
  fi
  if [[ -z "$osrel" ]] && command -v uname >/dev/null 2>&1; then
    osrel="$(command uname -r 2>/dev/null)"
  fi

  if (( ! is_wsl )); then
    [[ "${(L)osrel}" == *microsoft* ]] && is_wsl=1
    if (( ! is_wsl )) && [[ -r /proc/version ]]; then
      local pv=""
      pv="$(<"/proc/version")"
      [[ "${(L)pv}" == *microsoft* ]] && is_wsl=1
    fi
  fi

  if (( is_wsl )); then
    if [[ -n "${WSL_INTEROP:-}" || "${(L)osrel}" == *wsl2* || "${(L)osrel}" == *microsoft-standard* ]]; then
      wsl_ver="Windows Subsystem Linux Ver.2"
    else
      wsl_ver="Windows Subsystem Linux Ver.1"
    fi
    __chizuru_container_tag="[${wsl_ver}]"
  fi

  return 0
}
__chizuru_probe_container

__detect_container_line() {
  __chizuru_probe_container
  if [[ "${CHIZURU_SHOW_CONTAINER:-1}" == "1" && -n "$__chizuru_container_tag" ]]; then
    container_line="${CZ_C_INFO}${__chizuru_container_tag}${CZ_C_RESET}"$'\n'
  else
    container_line=""
  fi
}

# ===========================================================================
# 4. Prompt variable refresh model
#
# Static / event-driven : container tag, hostname, venv/conda tag, hnode count
# Dynamic / realtime    : IPv4 / IPv6 addresses, clock
#
# The realtime path intentionally NEVER refreshes the static values.
# ===========================================================================

__refresh_prompt_static_vars() {
  emulate -L zsh
  setopt prompt_subst

  __detect_container_line

  # inlined (the $(...) form used by the original cost two forks per prompt)
  if [[ -n "${display_name:-}" ]]; then
    host_tag="$display_name"
  else
    host_tag="${__chizuru_hostname_cached:-${THEME_HOST_FALLBACK_NAME:-Chizuru}}"
  fi

  if [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
    env_tag="$CONDA_DEFAULT_ENV"
  elif [[ -n "${VIRTUAL_ENV:-}" ]]; then
    env_tag="${VIRTUAL_ENV:t}"
  else
    env_tag=""
  fi

  if [[ -n "$env_tag" ]]; then
    # reddish-orange for venv/conda tag (including brackets)
    # IMPORTANT: restore green after env tag so host/hnode stays green
    env_prefix="${CZ_C_ACCENT}[${env_tag}]${CZ_C_RESET}${CZ_C_GREEN}"
  else
    env_prefix=""
  fi

  hnode_count=${#__cd_history[@]}
  return 0
}

# Build the whole IP block (including its trailing newline) as one string.
#
# It must be pre-rendered here rather than assembled inside PROMPT, because
# prompt substitution is NOT recursive: ${ip_render} is expanded once, so the
# text it yields may contain %F{...} prompt escapes but not further ${...}.
__render_ip_lines() {
  emulate -L zsh
  setopt prompt_subst

  if [[ "${CHIZURU_SHOW_IP:-1}" != "1" ]]; then
    ip_render=""
    return 0
  fi

  local out=""

  if [[ "${CHIZURU_SHOW_IPV6:-0}" == "1" ]]; then
    out+="${CZ_C_YELLOW}[IPv4: ${ip_addr}]${CZ_C_RESET}"$'\n'
    # hide the v6 line entirely when the host has no global IPv6
    [[ -n "$ip6_addr" ]] && out+="${CZ_C_YELLOW}[IPv6: ${ip6_addr}]${CZ_C_RESET}"$'\n'
  else
    out+="${CZ_C_YELLOW}[IP: ${ip_addr}]${CZ_C_RESET}"$'\n'
  fi

  ip_render="$out"
  return 0
}

__chizuru_now() {
  if (( __chizuru_have_datetime )); then
    strftime -s time_str '%H:%M:%S' $EPOCHSECONDS 2>/dev/null && return 0
  fi
  time_str="$(command date +%H:%M:%S 2>/dev/null)"
  return 0
}

__refresh_prompt_dynamic_vars() {
  emulate -L zsh
  setopt prompt_subst

  local allow_virtual="${CHIZURU_SHOW_VIRTUAL_NIC:-0}"
  local fallback="${CHIZURU_NIC_FALLBACK_ANY:-1}"

  # ---- IPv4 ----
  __prompt_collect_ip 4 "$allow_virtual"
  ip_addr="$__prompt_ip_result"

  if [[ -z "$ip_addr" && "$allow_virtual" != "1" && "$fallback" == "1" ]]; then
    __prompt_collect_ip 4 1
    ip_addr="$__prompt_ip_result"
  fi

  # ---- IPv6 ----
  if [[ "${CHIZURU_SHOW_IPV6:-0}" == "1" ]]; then
    __prompt_collect_ip 6 "$allow_virtual"
    ip6_addr="$__prompt_ip_result"

    if [[ -z "$ip6_addr" && "$allow_virtual" != "1" && "$fallback" == "1" ]]; then
      __prompt_collect_ip 6 1
      ip6_addr="$__prompt_ip_result"
    fi
  else
    ip6_addr=""
  fi

  __chizuru_now
  __render_ip_lines
  return 0
}

# Full refresh is used at normal prompt lifecycle boundaries.
__refresh_prompt_vars() {
  __refresh_prompt_static_vars
  __refresh_prompt_dynamic_vars
}

__refresh_prompt_vars
__ip_addr_last="$ip_addr"
__ip6_addr_last="$ip6_addr"
__host_tag_last="$host_tag"
__env_tag_last="$env_tag"
__time_str_last="$time_str"
__hnode_count_last=$hnode_count

# ===========================================================================
# 5. REALTIME IP + CLOCK
#
# Preferred engine (zsh >= 4.3.4 with zsh/zpty):
#   A tiny background zpty ticker writes one line per second.  ZLE watches
#   the ticker's file descriptor with `zle -F`.  The handler runs from ZLE's
#   own input-wait loop, refreshes ONLY IP/time, then calls reset-prompt.
#
# Fallback engine (opt-in, CHIZURU_REALTIME_FALLBACK=1):
#   classic TMOUT + TRAPALRM, for builds without zsh/zpty.
#
# Last resort: no ticker at all; values still refresh at every precmd.
# ===========================================================================

typeset -g  __chizuru_timer_name="chizuru_realtime_timer"
typeset -gi __chizuru_timer_fd=-1
typeset -g  __chizuru_realtime_engine="none"

# `zle <widget> -f nolast` is available starting with zsh 5.9.
# Older zsh versions need a conservative redraw policy because their
# reset-prompt changes LASTWIDGET and can break repeated history widgets.
typeset -gi __chizuru_zle_nolast_supported=0
__chizuru_zsh_at_least 5 9 && __chizuru_zle_nolast_supported=1

# ---- compatibility cleanup for older Chizuru realtime engines ----

# v2026.08.11.1 and older: SIGALRM based engine
TMOUT=0
unfunction TRAPALRM 2>/dev/null

# v2026.08.11.1: remove the old user-defined realtime widget if it exists
zle -D __chizuru_realtime_refresh_widget 2>/dev/null

# v2026.08.11.2: remove any already queued sched events.
__chizuru_cleanup_old_sched_events() {
  zmodload -F zsh/sched b:sched 2>/dev/null || zmodload zsh/sched 2>/dev/null || return 0

  local -i i
  for (( i = ${#zsh_scheduled_events}; i >= 1; i-- )); do
    if [[ "${zsh_scheduled_events[i]}" == *"__chizuru_"* ]]; then
      sched -$i 2>/dev/null
    fi
  done
  return 0
}
__chizuru_cleanup_old_sched_events

# ---- engine control ----

__chizuru_stop_realtime_timer() {
  # Remove the ZLE fd handler first so ZLE can no longer dispatch it.
  if (( __chizuru_timer_fd >= 0 )); then
    zle -F "$__chizuru_timer_fd" 2>/dev/null
  fi

  # zpty -d sends HUP to the ticker process and releases the pty.
  if zmodload -F zsh/zpty b:zpty 2>/dev/null || zmodload zsh/zpty 2>/dev/null; then
    zpty -d "$__chizuru_timer_name" 2>/dev/null
  fi

  if [[ "$__chizuru_realtime_engine" == "alrm" ]]; then
    TMOUT=0
    unfunction TRAPALRM 2>/dev/null
  fi

  __chizuru_timer_fd=-1
  __chizuru_realtime_engine="none"
  return 0
}

__chizuru_realtime_redraw() {
  # We are NOT inside a user key widget here.
  #
  # zsh >= 5.9:
  #   Use `-f nolast`.  This prevents reset-prompt from replacing LASTWIDGET,
  #   so repeated history, kill/yank and other stateful widgets keep their
  #   continuity.
  #
  # zsh <= 5.8.x:
  #   `-f nolast` does not exist and LASTWIDGET is read-only, so redraw ONLY
  #   when the edit buffer is empty and history is not being browsed.  The
  #   IP/time variables are still sampled every second; the visible prompt
  #   simply freezes while the user types.  The next idle tick or precmd
  #   shows the newest values.
  if (( __chizuru_zle_nolast_supported )); then
    zle reset-prompt -f nolast
  else
    if [[ -z "${BUFFER:-}" ]] && (( ${HISTNO:-0} == ${HISTCMD:-0} )); then
      zle reset-prompt
    fi
  fi
}

__chizuru_realtime_fd_handler() {
  local fd="$1"
  local err="${2:-}"           # 2nd arg only exists on newer zsh
  local tick=""
  local -i got_tick=0

  # poll/select reported an invalid/closed descriptor.
  if [[ -n "$err" ]]; then
    zle -F "$fd" 2>/dev/null
    __chizuru_timer_fd=-1
    return 0
  fi

  # Drain all currently queued timer lines.  This is important after a long
  # foreground command: we want ONE prompt refresh, not a burst of old ticks.
  while zpty -r -t "$__chizuru_timer_name" tick 2>/dev/null; do
    got_tick=1
  done

  (( got_tick )) || return 0

  # Realtime path: ONLY IP + time.
  __refresh_prompt_dynamic_vars
  __ip_addr_last="$ip_addr"
  __ip6_addr_last="$ip6_addr"
  __time_str_last="$time_str"

  __chizuru_realtime_redraw
  return 0
}

__chizuru_start_zpty_timer() {
  # zle -F on an arbitrary fd needs zsh >= 4.3.4
  __chizuru_zsh_at_least 4 3 4 || return 1

  zmodload -F zsh/zpty b:zpty 2>/dev/null || zmodload zsh/zpty 2>/dev/null || return 1
  command -v sleep >/dev/null 2>&1 || return 1

  # -b makes the pty non-blocking and publishes the master fd in $REPLY.
  #
  # No terminal output from this ticker reaches the user's screen: its stdout
  # goes only to the private pty read by the ZLE fd handler.
  REPLY=""
  zpty -b "$__chizuru_timer_name" \
      'while :; do command sleep 1 || exit 0; print -r -- tick; done' 2>/dev/null || return 1

  # Very old / unusual builds may not publish the fd.  Bail out cleanly.
  if [[ -z "$REPLY" || "$REPLY" == *[^0-9]* ]]; then
    zpty -d "$__chizuru_timer_name" 2>/dev/null
    return 1
  fi
  __chizuru_timer_fd=$REPLY

  # IMPORTANT:
  # This is a NORMAL fd handler, not `zle -F -w`.  The callback is therefore
  # not a ZLE widget and does not replace the user's widget state.
  if ! zle -F "$__chizuru_timer_fd" __chizuru_realtime_fd_handler 2>/dev/null; then
    zpty -d "$__chizuru_timer_name" 2>/dev/null
    __chizuru_timer_fd=-1
    return 1
  fi

  return 0
}

__chizuru_start_alrm_timer() {
  # Universal fallback: works on literally every zsh, but owns TMOUT/SIGALRM.
  TRAPALRM() {
    __refresh_prompt_dynamic_vars
    __ip_addr_last="$ip_addr"
    __ip6_addr_last="$ip6_addr"
    __time_str_last="$time_str"
    if zle; then
      if [[ -z "${BUFFER:-}" ]] && (( ${HISTNO:-0} == ${HISTCMD:-0} )); then
        zle reset-prompt
      fi
    fi
  }
  TMOUT=1
  return 0
}

__chizuru_start_realtime_timer() {
  [[ -o interactive ]] || return 0
  [[ "${CHIZURU_REALTIME:-1}" == "1" ]] || return 0

  # If ~/.zshrc / the theme is sourced again, kill the previous ticker first.
  __chizuru_stop_realtime_timer

  if __chizuru_start_zpty_timer; then
    __chizuru_realtime_engine="zpty"
    return 0
  fi

  if [[ "${CHIZURU_REALTIME_FALLBACK:-0}" == "1" ]] && __chizuru_start_alrm_timer; then
    __chizuru_realtime_engine="alrm"
    return 0
  fi

  __chizuru_realtime_engine="none"
  return 0
}

__chizuru_start_realtime_timer

# ===========================================================================
# 6. Prompt assembly
# ===========================================================================

configure_prompt() {
    emulate -L zsh
    setopt prompt_subst

    # %(#.A.B) is resolved at prompt time, so `su` inside the same shell
    # recolors immediately and no `whoami` fork is needed.
    use_color="${CZ_C_USER}"

    yellow_c="${CZ_C_YELLOW}"
    cyan_c="${CZ_C_CYAN}"
    write_c="${CZ_C_WHITE}"
    green_c="${CZ_C_GREEN}"
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

    local hnode_part='${CZ_C_ACCENT}[hnode: ${hnode_count}]${CZ_C_RESET}'
    local time_part='${CZ_C_TIME}[${time_str}]${CZ_C_RESET}'

    # The IP block (IPv4 only / IPv4 + IPv6, incl. its trailing newline) is
    # pre-rendered by __render_ip_lines and already honours CHIZURU_SHOW_IP.
    local ip_line='${ip_render}'

    PROMPT=$'${container_line}${green_c}${env_prefix}'"${host_part}${hnode_part}"$'${yellow_c}'"${time_part}"$'\n'"${ip_line}"$'${use_color}|-%d\n${use_color}|-%n${yellow_c}::${cyan_c}%C${yellow_c}::${use_color}# ${write_c}'
}

NEWLINE_BEFORE_PROMPT=yes

# ===========================================================================
# 7. Theme self-update (check EVERY login; no-network => ignore)
# - Compare numeric dotted versions properly (e.g. 2026.01.15.10 > 2026.01.15.2)
# - Strong guardrails against bad remote content / human mistakes
# - curl is preferred, wget is accepted, neither => update support disabled
# ===========================================================================

typeset -g __THEME_UPDATE_RELOADING="${__THEME_UPDATE_RELOADING:-0}"

__theme_version_is_valid() {
  # Accept only dotted numeric versions: 1.2.3 / 2026.01.15.1 etc.
  local v="${1:-}"
  [[ -n "$v" ]] || return 1
  [[ "$v" == *[^0-9.]* ]] && return 1
  [[ "$v" == .* || "$v" == *. || "$v" == *..* ]] && return 1
  return 0
}

__theme_version_cmp() {
  # returns:
  #   0 => equal
  #   1 => a > b
  # 255 => a < b  (use 255 to represent -1)
  local a="$1" b="$2"
  local -a A B
  local ai bi
  local -i i max

  A=("${(@s:.:)a}")
  B=("${(@s:.:)b}")

  (( ${#A} > ${#B} )) && max=${#A} || max=${#B}

  for (( i = 1; i <= max; i++ )); do
    ai="${A[i]:-0}"; [[ -n "$ai" ]] || ai=0
    bi="${B[i]:-0}"; [[ -n "$bi" ]] || bi=0

    if (( 10#$ai > 10#$bi )); then
      return 1
    elif (( 10#$ai < 10#$bi )); then
      return 255
    fi
  done
  return 0
}

__chizuru_have_downloader() {
  command -v curl >/dev/null 2>&1 && return 0
  command -v wget >/dev/null 2>&1 && return 0
  return 1
}

# __chizuru_fetch URL [OUTFILE] [TIMEOUT]
__chizuru_fetch() {
  local url="$1" out="${2:-}" tmo="${3:-10}"

  if command -v curl >/dev/null 2>&1; then
    if [[ -n "$out" ]]; then
      command curl -fsSL --max-time "$tmo" "$url" -o "$out"
    else
      command curl -fsSL --max-time "$tmo" "$url"
    fi
    return $?
  fi

  if command -v wget >/dev/null 2>&1; then
    if [[ -n "$out" ]]; then
      command wget -q -T "$tmo" -O "$out" "$url"
    else
      command wget -q -T "$tmo" -O - "$url"
    fi
    return $?
  fi

  return 127
}

# Parse THEME_VERSION out of theme text without awk/grep.
# Sets $REPLY to the version, returns 1 when the text is not our theme.
__theme_scan_content() {
  local content="$1"
  local -a lines
  local l v=""
  local -i has_url=0 has_ver=0

  REPLY=""
  lines=("${(@f)content}")

  for l in "${lines[@]}"; do
    [[ "$l" == THEME_GITHUB_RAW_URL=* ]] && has_url=1
    if [[ "$l" == THEME_VERSION=* ]]; then
      has_ver=1
      if [[ -z "$v" ]]; then
        v="${l#THEME_VERSION=}"
        v="${v#\"}"
        v="${v%%\"*}"
      fi
    fi
  done

  (( has_url && has_ver )) || return 1
  [[ -n "$v" ]] || return 1
  REPLY="$v"
  return 0
}

__theme_get_remote_version() {
  __chizuru_have_downloader || return 1

  local content
  content="$(__chizuru_fetch "$THEME_GITHUB_RAW_URL" "" 2)" || return 1
  [[ -n "$content" ]] || return 1

  # Sanity checks: remote must look like our theme (avoid HTML/404/other file)
  __theme_scan_content "$content" || return 1
  print -r -- "$REPLY"
  return 0
}

# Backup rotation for theme-update.
#
# Backups are named "<theme>.bak.YYYYMMDDHHMMSS", so they sort chronologically
# by NAME.  Sorting by mtime would be wrong here: `cp -p` copies the source
# file's timestamp, which makes every backup look the same age.
__chizuru_backup_files() {
  emulate -L zsh
  setopt local_options no_nomatch null_glob

  local self_file="${1:-${THEME_SELF_FILE:-}}"
  [[ -n "$self_file" ]] && self_file="${self_file:A}"
  [[ -n "$self_file" ]] || return 1

  # <-> matches only our own numeric timestamps, so a hand-renamed file such
  # as "....bak.keepme" is never listed, counted, or deleted.
  # (N) no-match is fine, (.) regular files only, (On) newest first
  reply=(${self_file}.bak.<->(N.On))
  return 0
}

# __chizuru_prune_backups [SELF_FILE] [KEEP]
__chizuru_prune_backups() {
  emulate -L zsh
  setopt local_options no_nomatch null_glob

  local self_file="${1:-${THEME_SELF_FILE:-}}"
  local raw="${2:-${CHIZURU_BACKUP_KEEP:-5}}"
  local -i keep=0
  local f

  [[ -n "$raw" && "$raw" != *[^0-9]* ]] || return 0
  keep=$raw
  (( keep > 0 )) || return 0          # 0 => unlimited, nothing to do

  local -a reply
  __chizuru_backup_files "$self_file" || return 0
  (( ${#reply} > keep )) || return 0

  for f in "${(@)reply[keep+1,-1]}"; do
    # paranoia: only ever remove files we generated ourselves
    [[ -f "$f" && "$f" == *.bak.<-> ]] || continue
    command rm -f -- "$f" 2>/dev/null
  done
  return 0
}

# List the backups currently on disk (newest first)
chizuru-backups() {
  emulate -L zsh
  local -a reply
  local f
  __chizuru_backup_files || { print -r -- "theme file unknown"; return 1 }
  if (( ${#reply} == 0 )); then
    print -r -- "no backups"
    return 0
  fi
  print -r -- "keep policy: ${CHIZURU_BACKUP_KEEP:-5} (0 = unlimited) / on disk: ${#reply}"
  for f in "${(@)reply}"; do
    print -r -- "  $f"
  done
  return 0
}

# Manual rotation:  chizuru-backup-prune [N]
chizuru-backup-prune() {
  emulate -L zsh
  local -a reply
  local -i before=0 after=0
  __chizuru_backup_files >/dev/null; before=${#reply}
  __chizuru_prune_backups "" "${1:-${CHIZURU_BACKUP_KEEP:-5}}"
  __chizuru_backup_files >/dev/null; after=${#reply}
  print -r -- "backups: ${before} -> ${after}"
  return 0
}

theme-update() {
  emulate -L zsh
  setopt prompt_subst

  __chizuru_have_downloader || { print -r -- "curl/wget not found"; return 1 }

  local self_file="${THEME_SELF_FILE:-}"

  # Make absolute if possible (zsh feature)
  [[ -n "$self_file" ]] && self_file="${self_file:A}"

  # If still empty, fallback to funcfiletrace (last resort)
  if [[ -z "$self_file" && -n "${funcfiletrace[1]-}" ]]; then
    self_file="${funcfiletrace[1]%%:*}"
    [[ -n "$self_file" ]] && self_file="${self_file:A}"
  fi

  if [[ -z "$self_file" || ! -w "$self_file" ]]; then
    print -r -- "Cannot write theme file: $self_file"
    return 1
  fi

  local tmp="${self_file}.tmp.$$"
  if ! __chizuru_fetch "$THEME_GITHUB_RAW_URL" "$tmp" 10; then
    print -r -- "Download failed"
    command rm -f "$tmp" 2>/dev/null
    return 1
  fi

  # Guardrails: downloaded file must include our key lines
  local content=""
  content="$(<"$tmp")" 2>/dev/null
  if ! __theme_scan_content "$content"; then
    print -r -- "Downloaded file looks invalid (missing THEME_VERSION= / THEME_GITHUB_RAW_URL=). Abort."
    command rm -f "$tmp" 2>/dev/null
    return 1
  fi
  local remote_ver="$REPLY"

  if ! __theme_version_is_valid "$remote_ver"; then
    print -r -- "Remote THEME_VERSION is invalid: '$remote_ver'. Abort."
    command rm -f "$tmp" 2>/dev/null
    return 1
  fi
  if ! __theme_version_is_valid "$THEME_VERSION"; then
    print -r -- "Local THEME_VERSION is invalid: '$THEME_VERSION'. Abort."
    command rm -f "$tmp" 2>/dev/null
    return 1
  fi

  __theme_version_cmp "$remote_ver" "$THEME_VERSION"
  local -i cmp_rc=$?

  if (( cmp_rc == 0 )); then
    print -r -- "Already up to date."
    command rm -f "$tmp" 2>/dev/null
    return 0
  elif (( cmp_rc == 255 )); then
    print -r -- "Remote version ($remote_ver) is older than local ($THEME_VERSION). Abort (no downgrade)."
    command rm -f "$tmp" 2>/dev/null
    return 1
  fi

  local stamp=""
  if (( __chizuru_have_datetime )); then
    strftime -s stamp '%Y%m%d%H%M%S' $EPOCHSECONDS 2>/dev/null
  fi
  [[ -n "$stamp" ]] || stamp="$(command date +%Y%m%d%H%M%S 2>/dev/null)"
  [[ -n "$stamp" ]] || stamp="$$"

  command cp -p "$self_file" "${self_file}.bak.${stamp}" 2>/dev/null || \
    command cp "$self_file" "${self_file}.bak.${stamp}" 2>/dev/null
  __chizuru_prune_backups "$self_file"
  command mv -f "$tmp" "$self_file" || { print -r -- "Install failed"; return 1 }
  print -r -- "Theme updated to $remote_ver."

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
  return 0
}

__theme_check_update_on_login() {
  [[ -o interactive ]] || return 0
  [[ "${__THEME_UPDATE_RELOADING:-0}" == "1" ]] && return 0
  [[ "${CHIZURU_AUTO_UPDATE_CHECK:-1}" == "1" ]] || return 0
  __chizuru_have_downloader || return 0

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
  local -i cmp_rc=$?

  # equal, or remote older (never auto-downgrade) => nothing to do
  (( cmp_rc == 0 || cmp_rc == 255 )) && return 0

  # remote > local => ask Y/N
  local ans=""
  print -P "%F{yellow}[Theme]%f Update available: %F{cyan}${remote_ver}%f (local: ${THEME_VERSION}). Update now? [Y/n] \c"
  if read -r -k 1 ans </dev/tty 2>/dev/null; then
    print ""
  else
    read -r ans 2>/dev/null || ans=""
  fi

  if [[ -z "$ans" || "$ans" == $'\n' || "$ans" == [Yy] ]]; then
    theme-update
  else
    print -P "%F{yellow}[Theme]%f Skipped."
  fi
  return 0
}

# Manual update command
chizuru-update() { theme-update "$@" }

# ===========================================================================
# 8. Toggle / diagnostic commands
# ===========================================================================

__chizuru_apply_toggle() {
  __refresh_prompt_dynamic_vars
  configure_prompt
  zle && zle reset-prompt
}

chizuru-show-ip() { CHIZURU_SHOW_IP=1; __chizuru_apply_toggle }
chizuru-disable-ip() { CHIZURU_SHOW_IP=0; __chizuru_apply_toggle }

# IPv4 only <-> IPv4 + IPv6
chizuru-show-ipv6() { CHIZURU_SHOW_IPV6=1; __chizuru_apply_toggle }
chizuru-disable-ipv6() { CHIZURU_SHOW_IPV6=0; __chizuru_apply_toggle }
chizuru-show-ipv6-linklocal() { CHIZURU_SHOW_IPV6_LINKLOCAL=1; __chizuru_apply_toggle }
chizuru-disable-ipv6-linklocal() { CHIZURU_SHOW_IPV6_LINKLOCAL=0; __chizuru_apply_toggle }

# physical NIC only <-> physical + virtual NIC
chizuru-show-virtual-nic() { CHIZURU_SHOW_VIRTUAL_NIC=1; __chizuru_apply_toggle }
chizuru-disable-virtual-nic() { CHIZURU_SHOW_VIRTUAL_NIC=0; __chizuru_apply_toggle }

chizuru-show-hostname() { CHIZURU_SHOW_HOSTNAME=1; configure_prompt; zle && zle reset-prompt }
chizuru-disable-hostname() { CHIZURU_SHOW_HOSTNAME=0; configure_prompt; zle && zle reset-prompt }
chizuru-show-container() { CHIZURU_SHOW_CONTAINER=1; __detect_container_line; configure_prompt; zle && zle reset-prompt }
chizuru-disable-container() { CHIZURU_SHOW_CONTAINER=0; __detect_container_line; configure_prompt; zle && zle reset-prompt }

# Realtime engine control
chizuru-realtime-on() { CHIZURU_REALTIME=1; __chizuru_start_realtime_timer; __chizuru_apply_toggle }
chizuru-realtime-off() { CHIZURU_REALTIME=0; __chizuru_stop_realtime_timer; __chizuru_apply_toggle }

# Force a color mode: truecolor | 256 | basic | none
chizuru-color-mode() {
  if [[ -n "${1:-}" ]]; then
    CHIZURU_COLOR_MODE="$1"
  else
    unset CHIZURU_COLOR_MODE
  fi
  __chizuru_build_colors
  __refresh_prompt_static_vars
  __refresh_prompt_dynamic_vars
  configure_prompt
  zle && zle reset-prompt
  print -r -- "color mode: $__chizuru_color_mode (terminal reports ${__chizuru_term_colors} colors)"
}

# What did the compatibility layer actually pick on this machine?
chizuru-info() {
  emulate -L zsh
  __chizuru_detect_ip_backend
  print -r -- "theme            : ${THEME_NAME} ${THEME_VERSION}"
  print -r -- "zsh              : ${ZSH_VERSION} (parsed ${__chizuru_v_major}.${__chizuru_v_minor}.${__chizuru_v_patch})"
  print -r -- "color mode       : ${__chizuru_color_mode} (terminfo colors: ${__chizuru_term_colors}, TERM=${TERM:-unset})"
  print -r -- "zle -f nolast    : $(( __chizuru_zle_nolast_supported )) (needs zsh >= 5.9)"
  print -r -- "realtime engine  : ${__chizuru_realtime_engine} (fd=${__chizuru_timer_fd})"
  print -r -- "clock source     : $(( __chizuru_have_datetime )) => zsh/datetime, else date(1)"
  print -r -- "ip backend       : ${__chizuru_ip_backend}"
  print -r -- "ls options       : ${__chizuru_ls_opts[*]}"
  print -r -- "hostname         : ${__chizuru_hostname_cached}"
  local -a reply
  __chizuru_backup_files >/dev/null 2>&1
  print -r -- "backups          : ${#reply} on disk, keep ${CHIZURU_BACKUP_KEEP:-5} (0 = unlimited)"
  print -r -- "container/WSL    : ${__chizuru_container_tag:-(none)}"
  print -r -- "IPv4             : ${ip_addr:-(none)}"
  print -r -- "IPv6             : ${ip6_addr:-(none)}"
}

# Debug helper: show how each NIC is classified
chizuru-nic-list() {
  emulate -L zsh
  setopt no_nomatch

  __chizuru_detect_ip_backend

  local -A addrmap
  local -a ifs lines fields
  local line ifc a kind state
  local -i i

  case "$__chizuru_ip_backend" in
    ip-br)
      lines=("${(@f)$(command ip -br addr show 2>/dev/null)}")
      for line in "${lines[@]}"; do
        [[ -n "$line" ]] || continue
        fields=(${=line})
        (( ${#fields} >= 2 )) || continue
        ifc="${fields[1]%%@*}"
        addrmap[$ifc]="${(j: :)fields[3,-1]}"
      done
      ;;
    ip-o)
      lines=("${(@f)$(command ip -o addr show 2>/dev/null)}")
      for line in "${lines[@]}"; do
        [[ -n "$line" ]] || continue
        fields=(${=line})
        (( ${#fields} >= 4 )) || continue
        ifc="${fields[2]%%@*}"
        for (( i = 3; i <= ${#fields}; i++ )); do
          if [[ "${fields[i]}" == "inet" || "${fields[i]}" == "inet6" ]]; then
            addrmap[$ifc]="${addrmap[$ifc]:+${addrmap[$ifc]} }${fields[i+1]}"
            break
          fi
        done
      done
      ;;
    ifconfig)
      lines=("${(@f)$(command ifconfig -a 2>/dev/null)}")
      ifc=""
      for line in "${lines[@]}"; do
        [[ -n "$line" ]] || continue
        if [[ "$line" != [[:space:]]* ]]; then
          fields=(${=line})
          ifc="${fields[1]%%:*}"
          continue
        fi
        [[ -n "$ifc" ]] || continue
        fields=(${=line})
        for (( i = 1; i <= ${#fields}; i++ )); do
          if [[ "${fields[i]}" == "inet" || "${fields[i]}" == "inet6" ]]; then
            a="${fields[i+1]#addr:}"
            [[ "$a" == "addr:" ]] && a="${fields[i+2]:-}"
            [[ -n "$a" ]] && addrmap[$ifc]="${addrmap[$ifc]:+${addrmap[$ifc]} }${a}"
            break
          fi
        done
      done
      ;;
  esac

  if [[ -d /sys/class/net ]]; then
    ifs=(/sys/class/net/*(N:t))
  else
    ifs=(${(k)addrmap})
  fi

  for ifc in "${(@)ifs}"; do
    [[ -n "$ifc" ]] || continue
    if __prompt_nic_is_physical "$ifc"; then
      kind="physical"
    else
      kind="virtual "
    fi
    if [[ -r "/sys/class/net/$ifc/operstate" ]]; then
      state="$(<"/sys/class/net/$ifc/operstate")"
    else
      state="?"
    fi
    printf "%-8s %-8s %-16s %s\n" "$kind" "$state" "$ifc" "${addrmap[$ifc]:-}"
  done
}

# ===========================================================================
# 9. Hook registration
#
# add-zsh-hook keeps other plugins' precmd/chpwd alive.  If it is missing
# (very old or very stripped zsh), fall back to the plain function names.
# ===========================================================================

__chizuru_precmd() {
    __refresh_prompt_vars
    print -Pnr -- "${TERM_TITLE-}"
    if [[ "${NEWLINE_BEFORE_PROMPT:-}" == yes ]]; then
        if [[ -z "${_NEW_LINE_BEFORE_PROMPT:-}" ]]; then
            _NEW_LINE_BEFORE_PROMPT=1
        else
            print ""
        fi
    fi
}

__chizuru_chpwd() {
  # record previous dir (before this cd) if known
  if [[ -n "${__cd_last_pwd:-}" && "${__cd_last_pwd}" != "$PWD" ]]; then
    __cd_history_push "$__cd_last_pwd"
  fi
  __cd_last_pwd="$PWD"
  zle && zle reset-prompt
}

typeset -gi __chizuru_have_hooks=0
autoload -Uz add-zsh-hook 2>/dev/null
if add-zsh-hook precmd __chizuru_precmd 2>/dev/null; then
  add-zsh-hook chpwd __chizuru_chpwd 2>/dev/null
  __chizuru_have_hooks=1
else
  precmd() { __chizuru_precmd "$@" }
  chpwd()  { __chizuru_chpwd  "$@" }
fi

# ===========================================================================
# 10. Prompt activation + syntax highlighting + aliases
# ===========================================================================

if [[ "$color_prompt" == yes ]]; then
    VIRTUAL_ENV_DISABLE_PROMPT=1
    configure_prompt

    # Check update every login (no network => silently ignore)
    __theme_check_update_on_login

    typeset -ga __chizuru_zsh_syntax_candidates
    __chizuru_zsh_syntax_candidates=(
      /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      "${HOME}/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    )

    __chizuru_zsh_syntax_file=""
    for __chizuru_zsh_syntax_c in "${__chizuru_zsh_syntax_candidates[@]}"; do
      if [[ -r "$__chizuru_zsh_syntax_c" ]]; then
        __chizuru_zsh_syntax_file="$__chizuru_zsh_syntax_c"
        break
      fi
    done
    unset __chizuru_zsh_syntax_c

    if [[ -n "$__chizuru_zsh_syntax_file" ]]; then
        . "$__chizuru_zsh_syntax_file"

        ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

        # Older zsh-syntax-highlighting releases do not know every key below.
        # Assigning an unknown key is harmless, so no version gate is needed.
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
    unset __chizuru_zsh_syntax_file __chizuru_zsh_syntax_candidates
else
    PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~%(#.#.$) '
fi
unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty*|konsole*|wezterm*|foot*|contour*|st-*|tmux*|screen*|vte*)
    # ${VIRTUAL_ENV:t} avoids a basename fork on every prompt
    TERM_TITLE=$'\e]0;${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+(${VIRTUAL_ENV:t})}%n@%m: %~\a'
    ;;
*)
    TERM_TITLE=""
    ;;
esac

# --- colorized coreutils: every option is probed before it is aliased ---
if command -v dircolors >/dev/null 2>&1; then
    test -r ~/.dircolors && eval "$(command dircolors -b ~/.dircolors)" || eval "$(command dircolors -b)"
    export LS_COLORS="$LS_COLORS:ow=30;44:"

    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
fi

if command ls --color=auto -d . >/dev/null 2>&1; then
    alias ls='ls --color=auto'
fi

command grep --color=auto . /dev/null >/dev/null 2>&1
if (( $? <= 1 )); then
    alias grep='grep --color=auto'
    command -v fgrep >/dev/null 2>&1 && alias fgrep='fgrep --color=auto'
    command -v egrep >/dev/null 2>&1 && alias egrep='egrep --color=auto'
fi

if command diff --color=auto /dev/null /dev/null >/dev/null 2>&1; then
    alias diff='diff --color=auto'
fi

if command -v ip >/dev/null 2>&1 && command ip --color=auto link show >/dev/null 2>&1; then
    alias ip='ip --color=auto'
fi

if command -v less >/dev/null 2>&1; then
    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline
fi
