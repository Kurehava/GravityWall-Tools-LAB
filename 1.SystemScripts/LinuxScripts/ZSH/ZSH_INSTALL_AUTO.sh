#!/usr/bin/env bash
# ZSH_INSTALL_AUTO.sh - Chizuru theme / oh-my-zsh installer
# powered by kurehava
#
# Unattended one-shot installer. Also covers macOS (Homebrew).
#
# Supported platforms
#   Linux : Debian / Ubuntu / Kali / Parrot / Raspbian  (apt)
#           RHEL / CentOS / Rocky / AlmaLinux / Fedora  (dnf, yum)
#           openSUSE (zypper) / Arch (pacman) / Alpine (apk)
#           WSL1 / WSL2
#   macOS : Homebrew
#
# Environment overrides (all optional)
#   GH_PROXY=https://example.com/     prefix for every github.com / raw URL
#   CHIZURU_BRANCH=main               branch to pull the theme from
#   CHIZURU_ASSUME_YES=1              never prompt
#   CHIZURU_SET_DEFAULT_SHELL=0       do not touch the login shell
#   CHIZURU_ZSHRC_BACKUP_KEEP=5       how many ~/.zshrc backups to keep (0 = all)
#   CHIZURU_FORCE_SPECTRUM_FIX=1      always install the old-zsh spectrum.zsh shim
#
# Command line
#   --auto | --yes        assume yes for every question
#   --interactive         ask (default for ZSH_INSTALL.sh)
#   --proxy <prefix>      same as GH_PROXY
#   --branch <name>       same as CHIZURU_BRANCH
#   --no-chsh             do not change the login shell
#   --help                show this help

set -u

SCRIPT_NAME="ZSH_INSTALL_AUTO.sh"
SCRIPT_VERSION="2026.09.16"

REPO_RAW_BASE="https://raw.githubusercontent.com/Kurehava/GravityWall-Tools-LAB"
REPO_SUBDIR="1.SystemScripts/LinuxScripts/ZSH"
THEME_FILE="Chizuru.zsh-theme"
THEME_NAME="Chizuru"

OMZ_INSTALLER_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
PLUGIN_AUTOSUGGEST_URL="https://github.com/zsh-users/zsh-autosuggestions.git"
PLUGIN_HIGHLIGHT_URL="https://github.com/zsh-users/zsh-syntax-highlighting.git"

GH_PROXY="${GH_PROXY:-}"
BRANCH="${CHIZURU_BRANCH:-main}"
ASSUME_YES="${CHIZURU_ASSUME_YES:-1}"
SET_DEFAULT_SHELL="${CHIZURU_SET_DEFAULT_SHELL:-1}"
ZSHRC_BACKUP_KEEP="${CHIZURU_ZSHRC_BACKUP_KEEP:-5}"
FORCE_SPECTRUM_FIX="${CHIZURU_FORCE_SPECTRUM_FIX:-0}"
# ---------------------------------------------------------------------------
# output helpers
# ---------------------------------------------------------------------------

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_R=$'\033[91m'; C_G=$'\033[92m'; C_Y=$'\033[93m'; C_0=$'\033[0m'
else
    C_R=""; C_G=""; C_Y=""; C_0=""
fi
TAG_E="[${C_R}ERRO${C_0}]"
TAG_I="[${C_G}INFO${C_0}]"
TAG_W="[${C_Y}WARN${C_0}]"

log()  { printf '%s %s\n' "$TAG_I" "$*"; }
log_no_newline() { printf '%s %s' "$TAG_I" "$*"; }
warn() { printf '%s %s\n' "$TAG_W" "$*" >&2; }
err()  { printf '%s %s\n' "$TAG_E" "$*" >&2; }
die()  { err "$*"; err "exit."; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

usage() {
    cat <<USAGE
$SCRIPT_NAME $SCRIPT_VERSION - Chizuru theme / oh-my-zsh installer

Usage: $SCRIPT_NAME [options]

  --auto, --yes, -y      assume yes for every question
  --interactive, -i      ask before each step
  --no-chsh              do not change the login shell
  --proxy <prefix>       github mirror prefix (e.g. https://example.com/)
  --branch <name>        branch to pull the theme from (default: main)
  --help, -h             show this help

Environment overrides:
  GH_PROXY, CHIZURU_BRANCH, CHIZURU_ASSUME_YES, CHIZURU_SET_DEFAULT_SHELL,
  CHIZURU_ZSHRC_BACKUP_KEEP, CHIZURU_FORCE_SPECTRUM_FIX
USAGE
}

# ---------------------------------------------------------------------------
# argument parsing
# ---------------------------------------------------------------------------

while [ "$#" -gt 0 ]; do
    case "$1" in
        --auto|--yes|-y)   ASSUME_YES=1 ;;
        --interactive|-i)  ASSUME_YES=0 ;;
        --no-chsh)         SET_DEFAULT_SHELL=0 ;;
        --proxy)           shift; GH_PROXY="${1:-}" ;;
        --proxy=*)         GH_PROXY="${1#--proxy=}" ;;
        --branch)          shift; BRANCH="${1:-main}" ;;
        --branch=*)        BRANCH="${1#--branch=}" ;;
        --help|-h)         usage; exit 0 ;;
        *)                 warn "unknown option: $1" ;;
    esac
    shift
done

# ---------------------------------------------------------------------------
# prompts
#
# `bash <(curl ...)` keeps the terminal on stdin, but read from /dev/tty when
# it exists so that `curl ... | bash` degrades to the default instead of
# silently consuming the script itself.
# ---------------------------------------------------------------------------

# Reads one line into the named variable.  /dev/tty is preferred so that
# `curl ... | bash` still asks the user instead of eating the script, but the
# node can exist while having no controlling terminal, so the open is allowed
# to fail quietly and stdin is used instead.
read_answer() {
    local __var="$1" __ans=""
    if { IFS= read -r __ans < /dev/tty; } 2>/dev/null; then
        :
    elif IFS= read -r __ans; then
        :
    else
        __ans=""
    fi
    printf -v "$__var" '%s' "$__ans"
}

ask_yn() {
    # ask_yn "question" "Y|N"
    local q="$1" def="${2:-Y}" ans="" prompt
    if [ "$ASSUME_YES" = "1" ]; then
        printf '%s %s -> auto:%s\n' "$TAG_I" "$q" "$def"
        [ "$def" = "Y" ]
        return
    fi
    case "$def" in
        Y|y) prompt="[Y/n]" ;;
        *)   prompt="[y/N]" ;;
    esac
    while :; do
        printf '%s %s %s ' "$TAG_I" "$q" "$prompt"
        read_answer ans
        [ -n "$ans" ] || ans="$def"
        case "$ans" in
            Y|y|yes|YES|Yes) printf '\n'; return 0 ;;
            N|n|no|NO|No)    printf '\n'; return 1 ;;
            *) printf '\n'; warn "input '$ans' is illegal, plz reinput." ;;
        esac
    done
}

ask_str() {
    # ask_str "question" "default"   (answer on stdout, prompt on stderr)
    local q="$1" def="${2:-}" ans=""
    if [ "$ASSUME_YES" = "1" ]; then
        printf '%s' "$def"
        return 0
    fi
    printf '%s %s ' "$TAG_I" "$q" >&2
    read_answer ans
    printf '\n' >&2
    [ -n "$ans" ] || ans="$def"
    printf '%s' "$ans"
}

# ---------------------------------------------------------------------------
# platform detection
# ---------------------------------------------------------------------------

OS_KERNEL="$(uname -s 2>/dev/null || echo unknown)"
case "$OS_KERNEL" in
    Linux)  OS_FAMILY="linux" ;;
    Darwin) OS_FAMILY="macos" ;;
    *)      OS_FAMILY="unknown" ;;
esac

OS_PRETTY="$OS_KERNEL"
OS_ID=""
IS_WSL=0

if [ "$OS_FAMILY" = "macos" ]; then
    OS_PRETTY="macOS $(sw_vers -productVersion 2>/dev/null || echo '')"
    OS_ID="macos"
elif [ -r /etc/os-release ]; then
    # read in a subshell so the sourced variables do not leak in here
    OS_PRETTY="$(. /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-${NAME:-linux}}")"
    OS_ID="$(. /etc/os-release 2>/dev/null; printf '%s' "${ID:-}")"
fi

if [ "$OS_FAMILY" = "linux" ]; then
    if [ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]; then
        IS_WSL=1
    elif [ -r /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null; then
        IS_WSL=1
    fi
fi

[ "$OS_FAMILY" = "unknown" ] && die "Unsupported platform: $OS_KERNEL"

log "$SCRIPT_NAME $SCRIPT_VERSION"
log "Platform    : $OS_PRETTY${OS_ID:+ (id=$OS_ID)}"
[ "$IS_WSL" = "1" ] && log "WSL environment is detected."

# ---------------------------------------------------------------------------
# privileges
# ---------------------------------------------------------------------------

SUDO=""
AM_ROOT=0
[ "$(id -u)" -eq 0 ] && AM_ROOT=1

if [ "$AM_ROOT" -eq 0 ]; then
    if have sudo; then
        SUDO="sudo"
    elif have doas; then
        SUDO="doas"
    fi
fi

# ---------------------------------------------------------------------------
# package manager (probed, never guessed from the distro name)
# ---------------------------------------------------------------------------

PKG=""
PKG_INSTALL=""

detect_pkg() {
    if [ "$OS_FAMILY" = "macos" ]; then
        if have brew; then
            PKG="brew"; PKG_INSTALL="brew install"
        fi
        return 0
    fi
    if   have apt-get; then PKG="apt";    PKG_INSTALL="apt-get install -y"
    elif have dnf;     then PKG="dnf";    PKG_INSTALL="dnf install -y"
    elif have yum;     then PKG="yum";    PKG_INSTALL="yum install -y"
    elif have zypper;  then PKG="zypper"; PKG_INSTALL="zypper --non-interactive install"
    elif have pacman;  then PKG="pacman"; PKG_INSTALL="pacman -S --noconfirm --needed"
    elif have apk;     then PKG="apk";    PKG_INSTALL="apk add --no-cache"
    fi
    return 0
}
detect_pkg
log "Pkg_manager : ${PKG:-none}"

PKG_REFRESHED=0
pkg_refresh_once() {
    [ "$PKG_REFRESHED" = "1" ] && return 0
    PKG_REFRESHED=1
    case "$PKG" in
        apt)    $SUDO apt-get update -qq >/dev/null 2>&1 || true ;;
        pacman) $SUDO pacman -Sy --noconfirm >/dev/null 2>&1 || true ;;
        brew)   brew update >/dev/null 2>&1 || true ;;
    esac
    return 0
}

pkg_install() {
    # pkg_install <package> [package...]
    if [ -z "$PKG" ]; then
        warn "no supported package manager found; cannot install: $*"
        return 1
    fi
    pkg_refresh_once
    if [ "$PKG" = "brew" ]; then
        brew install "$@"
        return $?
    fi
    if [ "$AM_ROOT" -eq 0 ] && [ -z "$SUDO" ]; then
        warn "root privileges are required to install: $*"
        warn "neither sudo nor doas is available."
        return 1
    fi
    # shellcheck disable=SC2086
    $SUDO $PKG_INSTALL "$@"
}

ensure_command() {
    # ensure_command <command> [package name]
    local cmd="$1" pkgname="${2:-$1}"
    printf '%s check %s ...' "$TAG_I" "$cmd"
    if have "$cmd"; then
        printf ' yes\n'
        return 0
    fi
    printf '\n'
    warn "Missing dependency on $cmd."
    if ! ask_yn "Install $pkgname now?" "Y"; then
        return 1
    fi
    if pkg_install "$pkgname"; then
        hash -r 2>/dev/null || true
        have "$cmd" && { log "$cmd install success."; return 0; }
    fi
    warn "Failed to install $pkgname."
    warn "You can try it manually:"
    if [ "$PKG" = "brew" ]; then
        warn "  brew install $pkgname"
    else
        warn "  $SUDO $PKG_INSTALL $pkgname"
    fi
    return 1
}

# ---------------------------------------------------------------------------
# github mirror
# ---------------------------------------------------------------------------

if [ "$ASSUME_YES" != "1" ] && [ -z "$GH_PROXY" ]; then
    if ask_yn "Do you need a github mirror/proxy? (users in mainland China)" "N"; then
        warn "The old 'https://ghproxy.com/' service is discontinued."
        warn "Enter the prefix of a mirror you trust, e.g. https://example.com/"
        GH_PROXY="$(ask_str "mirror prefix (empty = direct):" "")"
    fi
fi

gh_url() {
    # gh_url <full github url>
    if [ -n "$GH_PROXY" ]; then
        printf '%s/%s' "${GH_PROXY%/}" "$1"
    else
        printf '%s' "$1"
    fi
}

[ -n "$GH_PROXY" ] && log "Mirror      : $GH_PROXY"

# ---------------------------------------------------------------------------
# dependencies
# ---------------------------------------------------------------------------

if [ "$OS_FAMILY" = "macos" ] && [ -z "$PKG" ]; then
    warn "Homebrew was not found."
    warn "Install it from https://brew.sh/ if a dependency turns out to be missing."
fi

if [ "$AM_ROOT" -eq 0 ] && [ -z "$SUDO" ] && [ "$OS_FAMILY" != "macos" ]; then
    warn "Running as a normal user without sudo/doas."
    warn "Package installation will be skipped; existing tools are used as-is."
fi

DL=""
have curl && DL="curl"
[ -z "$DL" ] && have wget && DL="wget"

if [ -z "$DL" ]; then
    ensure_command curl curl || ensure_command wget wget || true
    have curl && DL="curl"
    [ -z "$DL" ] && have wget && DL="wget"
fi
[ -n "$DL" ] || die "Not found download tool (curl or wget)."
log "Downloader  : $DL"

ensure_command git git || die "git is required to install the zsh plugins."

# ---------------------------------------------------------------------------
# download helpers
# ---------------------------------------------------------------------------

fetch_to() {
    # fetch_to <url> <destination>
    local url="$1" dest="$2" tmp rc
    tmp="$(mktemp "${dest}.dl.XXXXXX" 2>/dev/null)" || tmp="${dest}.dl.$$"
    case "$DL" in
        curl) curl -fsSL --retry 3 --connect-timeout 15 --max-time 300 "$url" -o "$tmp" ;;
        wget) wget -q --tries=3 --timeout=30 -O "$tmp" "$url" ;;
        *)    rm -f "$tmp"; return 127 ;;
    esac
    rc=$?
    if [ "$rc" -ne 0 ] || [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        return 1
    fi
    mv -f "$tmp" "$dest"
}

fetch_stdout() {
    # fetch_stdout <url>
    case "$DL" in
        curl) curl -fsSL --retry 3 --connect-timeout 15 --max-time 300 "$1" ;;
        wget) wget -q --tries=3 --timeout=30 -O - "$1" ;;
        *)    return 127 ;;
    esac
}

# ---------------------------------------------------------------------------
# zsh
# ---------------------------------------------------------------------------

ZSH_BIN=""
find_zsh() {
    ZSH_BIN="$(command -v zsh 2>/dev/null || true)"
    if [ -z "$ZSH_BIN" ]; then
        local c
        for c in /bin/zsh /usr/bin/zsh /usr/local/bin/zsh /opt/homebrew/bin/zsh; do
            if [ -x "$c" ]; then ZSH_BIN="$c"; break; fi
        done
    fi
    [ -n "$ZSH_BIN" ]
}

if ! find_zsh; then
    warn "can not found zsh."
    if ask_yn "Install zsh now?" "Y"; then
        pkg_install zsh || true
        hash -r 2>/dev/null || true
    fi
    find_zsh || die "zsh should already be installed, but we can't detect it."
fi

ZSH_VER="$("$ZSH_BIN" -c 'printf %s "$ZSH_VERSION"' 2>/dev/null || echo "")"
log "Zsh         : ${ZSH_BIN} (${ZSH_VER:-unknown version})"

zsh_version_lt() {
    # zsh_version_lt <major> <minor>  -> true when the running zsh is older
    local want_major="$1" want_minor="$2" v major minor
    v="${ZSH_VER%%-*}"
    major="${v%%.*}"
    minor="${v#*.}"; minor="${minor%%.*}"
    case "$major" in ''|*[!0-9]*) return 1 ;; esac
    case "$minor" in ''|*[!0-9]*) minor=0 ;; esac
    [ "$major" -lt "$want_major" ] && return 0
    [ "$major" -gt "$want_major" ] && return 1
    [ "$minor" -lt "$want_minor" ]
}

# ---------------------------------------------------------------------------
# oh-my-zsh
# ---------------------------------------------------------------------------

OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"

if [ -f "$OMZ_DIR/oh-my-zsh.sh" ]; then
    log "Detected that oh-my-zsh is already installed, skip the installation."
else
    log "Install: oh-my-zsh"
    omz_script="$(fetch_stdout "$(gh_url "$OMZ_INSTALLER_URL")")" \
        || die "Failed to download the oh-my-zsh installer."
    case "$omz_script" in
        *install_ohmyzsh*|*ohmyzsh*) : ;;
        *) die "The downloaded oh-my-zsh installer looks invalid (mirror returned an error page?)." ;;
    esac
    printf '%s' "$omz_script" | RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -s -- --unattended \
        || die "Install oh-my-zsh is failed."
    unset omz_script
    [ -f "$OMZ_DIR/oh-my-zsh.sh" ] || die "Install oh-my-zsh is failed."
fi

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}"
mkdir -p "$ZSH_CUSTOM_DIR/themes" "$ZSH_CUSTOM_DIR/plugins" "$ZSH_CUSTOM_DIR/lib"

ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
if [ ! -f "$ZSHRC" ]; then
    warn "$ZSHRC does not exist, creating a minimal one."
    {
        printf 'export ZSH="%s"\n' "$OMZ_DIR"
        printf 'ZSH_THEME="%s"\n' "$THEME_NAME"
        printf 'plugins=(git)\n'
        printf 'source "$ZSH/oh-my-zsh.sh"\n'
    } > "$ZSHRC"
fi

# ---------------------------------------------------------------------------
# ~/.zshrc editing (idempotent)
# ---------------------------------------------------------------------------

if sed --version >/dev/null 2>&1; then
    SED_INPLACE=(sed -i)          # GNU sed
else
    SED_INPLACE=(sed -i '')       # BSD / macOS sed
fi

sed_inplace() { "${SED_INPLACE[@]}" "$1" "$2"; }

mktemp_near() {
    # mktemp_near <reference file>
    mktemp "${1}.tmp.XXXXXX" 2>/dev/null || printf '%s.tmp.%s' "$1" "$$"
}

prune_backups() {
    # prune_backups <base path> <keep count>
    # Backups are named "<base>.bak.<YYYYMMDDHHMMSS>", so the glob already
    # expands oldest-first and the oldest ones are simply the first entries.
    local base="$1" keep="${2:-5}"
    local -a cands=()
    local f suffix
    local -i n del i

    case "$keep" in ''|*[!0-9]*) return 0 ;; esac
    [ "$keep" -gt 0 ] || return 0

    local had_nullglob=0
    shopt -q nullglob && had_nullglob=1
    shopt -s nullglob
    for f in "${base}".bak.*; do
        suffix="${f##*.bak.}"
        case "$suffix" in ''|*[!0-9]*) continue ;; esac
        cands+=("$f")
    done
    [ "$had_nullglob" = "1" ] || shopt -u nullglob

    n=${#cands[@]}
    del=$(( n - keep ))
    [ "$del" -gt 0 ] || return 0
    for (( i = 0; i < del; i++ )); do
        rm -f -- "${cands[i]}"
    done
    return 0
}

ZSHRC_BACKED_UP=0
backup_zshrc() {
    [ "$ZSHRC_BACKED_UP" = "1" ] && return 0
    [ -f "$ZSHRC" ] || return 0
    ZSHRC_BACKED_UP=1
    local b
    b="${ZSHRC}.bak.$(date +%Y%m%d%H%M%S)"
    cp -p "$ZSHRC" "$b" 2>/dev/null || cp "$ZSHRC" "$b" 2>/dev/null || {
        warn "could not create a backup of $ZSHRC"
        return 1
    }
    log "backup      : $b"
    prune_backups "$ZSHRC" "$ZSHRC_BACKUP_KEEP"
}

LEGACY_SOURCE_RE='^[[:space:]]*source[[:space:]]+.*(zsh-autosuggestions|zsh-syntax-highlighting|incr-0\.2)\.zsh[[:space:]]*$'

commit_zshrc() {
    # commit_zshrc <candidate file> <log message>
    # Writes the candidate over ~/.zshrc only when it actually differs, so a
    # repeated run neither rewrites the file nor piles up backups.
    local tmp="$1" msg="${2:-}"
    if have cmp && cmp -s "$tmp" "$ZSHRC"; then
        rm -f "$tmp"
        return 1
    fi
    backup_zshrc
    # write through the existing file to keep its inode, mode and ownership
    if cat "$tmp" > "$ZSHRC"; then
        rm -f "$tmp"
        [ -n "$msg" ] && log "$msg"
        return 0
    fi
    rm -f "$tmp"
    warn "could not update $ZSHRC"
    return 1
}

remove_legacy_plugin_sources() {
    grep -qE "$LEGACY_SOURCE_RE" "$ZSHRC" 2>/dev/null || return 0
    local tmp
    tmp="$(mktemp_near "$ZSHRC")" || return 1
    grep -vE "$LEGACY_SOURCE_RE" "$ZSHRC" > "$tmp"
    if [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        return 0
    fi
    commit_zshrc "$tmp" "cleanup     : removed legacy 'source ...' plugin lines (now handled by plugins=())"
    return 0
}

set_zsh_theme() {
    local theme="$1" tmp
    tmp="$(mktemp_near "$ZSHRC")" || return 1
    if grep -qE '^[[:space:]]*ZSH_THEME=' "$ZSHRC" 2>/dev/null; then
        cp "$ZSHRC" "$tmp" || { rm -f "$tmp"; return 1; }
        sed_inplace "s|^[[:space:]]*ZSH_THEME=.*|ZSH_THEME=\"${theme}\"|" "$tmp"
    else
        awk -v ins="ZSH_THEME=\"${theme}\"" '
            !done && /^[ \t]*source[ \t].*oh-my-zsh\.sh/ { print ins; done = 1 }
            { print }
            END { if (!done) print ins }
        ' "$ZSHRC" > "$tmp"
    fi
    if ! commit_zshrc "$tmp" "ZSH_THEME   : \"${theme}\""; then
        log "ZSH_THEME   : already \"${theme}\""
    fi
    return 0
}

add_omz_plugins() {
    # add_omz_plugins "plugin1 plugin2 ..."
    local want="$1" tmp
    [ -n "$want" ] || return 0
    tmp="$(mktemp_near "$ZSHRC")" || return 1

    if grep -qE '^[ \t]*plugins=\(.*\)[ \t]*$' "$ZSHRC" 2>/dev/null; then
        # single-line plugins=(...)  ->  merge the missing entries into it
        WANT="$want" awk '
            function has(list, item,   n, a, i) {
                n = split(list, a, /[ \t]+/)
                for (i = 1; i <= n; i++) if (a[i] == item) return 1
                return 0
            }
            BEGIN { nw = split(ENVIRON["WANT"], W, /[ \t]+/); merged = 0 }
            !merged && /^[ \t]*plugins=\(.*\)[ \t]*$/ {
                line = $0
                sub(/^[ \t]*plugins=\(/, "", line)
                sub(/\)[ \t]*$/, "", line)
                out = line
                for (i = 1; i <= nw; i++) if (!has(line, W[i])) out = out " " W[i]
                gsub(/^[ \t]+/, "", out); gsub(/[ \t]+$/, "", out); gsub(/[ \t]+/, " ", out)
                print "plugins=(" out ")"
                merged = 1
                next
            }
            { print }
        ' "$ZSHRC" > "$tmp"
    elif grep -qE '^[ \t]*plugins=\(' "$ZSHRC" 2>/dev/null; then
        # multi-line plugins=( ... ) block: append instead of rewriting it
        if grep -qF "plugins+=($want)" "$ZSHRC" 2>/dev/null; then
            rm -f "$tmp"
            log "plugins     : already up to date"
            return 0
        fi
        awk -v ins="plugins+=($want)" '
            !done && /^[ \t]*source[ \t].*oh-my-zsh\.sh/ { print ins; done = 1 }
            { print }
            END { if (!done) print ins }
        ' "$ZSHRC" > "$tmp"
    else
        awk -v ins="plugins=($want)" '
            !done && /^[ \t]*source[ \t].*oh-my-zsh\.sh/ { print ins; done = 1 }
            { print }
            END { if (!done) print ins }
        ' "$ZSHRC" > "$tmp"
    fi

    if ! commit_zshrc "$tmp" "plugins     : $want"; then
        log "plugins     : already up to date"
    fi
    return 0
}

# ---------------------------------------------------------------------------
# theme
# ---------------------------------------------------------------------------

install_theme() {
    local dest="$ZSH_CUSTOM_DIR/themes/$THEME_FILE"
    local stale="$OMZ_DIR/themes/$THEME_FILE"
    local url tmp
    url="$(gh_url "${REPO_RAW_BASE}/${BRANCH}/${REPO_SUBDIR}/${THEME_FILE}")"

    log "DOWNLOAD Theme: $THEME_FILE"
    tmp="$(mktemp_near "$dest")" || return 1
    if ! fetch_to "$url" "$tmp"; then
        rm -f "$tmp"
        err "Theme download failed: $url"
        return 1
    fi
    # Guardrail: a mirror or a 404 page must never be installed as the theme.
    if ! grep -q '^THEME_VERSION=' "$tmp" || ! grep -q '^THEME_GITHUB_RAW_URL=' "$tmp"; then
        rm -f "$tmp"
        err "The downloaded file is not $THEME_FILE (error page?). Abort."
        return 1
    fi
    mv -f "$tmp" "$dest"
    local ver
    ver="$(grep -m1 '^THEME_VERSION=' "$dest" 2>/dev/null)"
    ver="${ver#THEME_VERSION=}"; ver="${ver#\"}"; ver="${ver%%\"*}"
    log "Theme       : $dest"
    log "Version     : ${ver:-unknown}"

    # An old copy under $ZSH/themes shadows nothing but confuses manual edits,
    # and `omz update` can overwrite it.  Move it out of the way.
    if [ -f "$stale" ]; then
        mv -f "$stale" "${stale}.replaced.$(date +%Y%m%d%H%M%S)" 2>/dev/null \
            && warn "moved the old copy $stale aside (the active one is $dest)"
    fi
    return 0
}

# ---------------------------------------------------------------------------
# plugins
# ---------------------------------------------------------------------------

INSTALLED_PLUGINS=""

install_plugin_repo() {
    # install_plugin_repo <name> <git url>
    local name="$1" repo="$2"
    local dir="$ZSH_CUSTOM_DIR/plugins/$name"
    if [ -d "$dir/.git" ]; then
        log "Plugin      : $name (already present, updating)"
        git -C "$dir" pull --ff-only --quiet >/dev/null 2>&1 \
            || warn "$name: update skipped (local changes or no network)"
        INSTALLED_PLUGINS="$INSTALLED_PLUGINS $name"
        return 0
    fi
    if [ -e "$dir" ]; then
        warn "$name: $dir exists but is not a git checkout, skipping."
        return 1
    fi
    log "DOWNLOAD Plugin: $name"
    if git clone --depth=1 --quiet "$(gh_url "$repo")" "$dir" >/dev/null 2>&1; then
        INSTALLED_PLUGINS="$INSTALLED_PLUGINS $name"
        return 0
    fi
    rm -rf "$dir"
    warn "can not clone $name."
    warn "skip adding $name to plugins=() for safety."
    warn "You can do the manual installation later with the following command."
    warn "  git clone --depth=1 $repo \"$dir\""
    return 1
}

# ---------------------------------------------------------------------------
# old-zsh workaround
#
# On old zsh, oh-my-zsh's lib/spectrum.zsh can abort with
#   (anon):6: bad math expression: operand expected at `^fg'
# oh-my-zsh sources $ZSH_CUSTOM/lib/<name>.zsh in place of $ZSH/lib/<name>.zsh,
# so dropping a compatible spectrum.zsh there bypasses the problem.
# ---------------------------------------------------------------------------

install_spectrum_shim() {
    local dest="$ZSH_CUSTOM_DIR/lib/spectrum.zsh"
    if [ "$FORCE_SPECTRUM_FIX" != "1" ] && ! zsh_version_lt 5 3; then
        return 0
    fi
    if [ -f "$dest" ]; then
        log "spectrum.zsh: custom override already present, keeping it."
        return 0
    fi
    cat > "$dest" <<'SPECTRUM_EOF'
# Installed by the Chizuru installer.
# Compatibility override for old zsh (oh-my-zsh sources this instead of
# $ZSH/lib/spectrum.zsh).  Delete this file to go back to the stock one.
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

function spectrum_ls() {
  local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris}
  for code in {000..255}; do
    print -P -- "$code: ${FG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
  done
}

function spectrum_bls() {
  local ZSH_SPECTRUM_TEXT=${ZSH_SPECTRUM_TEXT:-Arma virumque cano Troiae qui primus ab oris}
  for code in {000..255}; do
    print -P -- "$code: ${BG[$code]}${ZSH_SPECTRUM_TEXT}%{$reset_color%}"
  done
}
SPECTRUM_EOF
    if [ "$FORCE_SPECTRUM_FIX" = "1" ]; then
        log "compat      : installed $dest (CHIZURU_FORCE_SPECTRUM_FIX=1)"
    else
        log "compat      : installed $dest (zsh ${ZSH_VER} is older than 5.3)"
    fi
    return 0
}

# ---------------------------------------------------------------------------
# login shell
# ---------------------------------------------------------------------------

set_login_shell() {
    local cur="" me
    me="$(id -un 2>/dev/null || whoami)"

    if have getent; then
        cur="$(getent passwd "$me" 2>/dev/null | cut -d: -f7)"
    fi
    [ -n "$cur" ] || cur="${SHELL:-}"

    if [ "$cur" = "$ZSH_BIN" ]; then
        log "Login shell : already $ZSH_BIN"
        return 0
    fi

    if [ -r /etc/shells ] && ! grep -qxF "$ZSH_BIN" /etc/shells 2>/dev/null; then
        warn "$ZSH_BIN is not listed in /etc/shells."
        if [ "$AM_ROOT" -eq 1 ]; then
            printf '%s\n' "$ZSH_BIN" >> /etc/shells && log "added $ZSH_BIN to /etc/shells"
        elif [ -n "$SUDO" ]; then
            printf '%s\n' "$ZSH_BIN" | $SUDO tee -a /etc/shells >/dev/null \
                && log "added $ZSH_BIN to /etc/shells"
        fi
    fi

    log "change login shell to ZSH."
    log "Plz input your passwd to change your Login SHELL: "
    log_no_newline "Passwd >> "
    if chsh -s "$ZSH_BIN" >/dev/null 2>&1; then
        echo && log "Login shell : $ZSH_BIN"
        return 0
    fi
    if [ -n "$SUDO" ] && $SUDO chsh -s "$ZSH_BIN" "$me" >/dev/null 2>&1; then
        echo && log "Login shell : $ZSH_BIN"
        return 0
    fi

    #log "Plz input your passwd to change your Login SHELL: " 
    #chsh -s "$ZSH_BIN" "$me" || $SUOD chsh -s "$ZSH_BIN" "$me"
    
    #if [ "$?" -eq "0" ]; then
    #    log "Login shell : $ZSH_BIN"
    #    return 0
    #fi

    warn "For unknown reasons, we cannot change the login shell for you."
    warn "Please change it manually later:"
    warn "  chsh -s $ZSH_BIN"
    warn "or open /etc/passwd and modify the shell of the specified user."
    return 1
}

# ---------------------------------------------------------------------------
# run
# ---------------------------------------------------------------------------

remove_legacy_plugin_sources

if ! install_theme; then
    die "theme installation failed."
fi

set_zsh_theme "$THEME_NAME"

WANT_PLUGINS="git z extract"
install_plugin_repo zsh-autosuggestions     "$PLUGIN_AUTOSUGGEST_URL" || true
install_plugin_repo zsh-syntax-highlighting "$PLUGIN_HIGHLIGHT_URL"   || true
# shellcheck disable=SC2086
WANT_PLUGINS="$WANT_PLUGINS$INSTALLED_PLUGINS"

add_omz_plugins "$WANT_PLUGINS"

install_spectrum_shim

if [ "$SET_DEFAULT_SHELL" = "1" ]; then
    if ask_yn "Set zsh as your login shell?" "Y"; then
        set_login_shell || true
    else
        log "Login shell : left unchanged."
    fi
fi

printf '\n'
log "Process done."
log "Theme file  : $ZSH_CUSTOM_DIR/themes/$THEME_FILE"
log "zshrc       : $ZSHRC"
log "Open a new terminal, or run: exec \"$ZSH_BIN\" -l"
log "Inside zsh, 'chizuru-info' shows what the theme detected on this machine."

if [ "$ASSUME_YES" != "1" ] && [ -t 1 ]; then
    if ask_yn "Start zsh now?" "Y"; then
        exec "$ZSH_BIN" -l
    fi
fi

exit 0
