#!/bin/sh

# ==============================================================================
# NIC Information Viewer
# Create by ChatGPT
#
# Compatible with:
#   - sh
#   - dash
#   - bash
#   - zsh
#
# Default:
#   - Show device-backed NICs only
#   - Show NIC / STATE / MAC / ALIAS / IPv4 / IPv6
# ==============================================================================

PATH="/usr/sbin:/usr/bin:/sbin:/bin"
export PATH

MODE="physical"
IP_MODE="normal"
CUSTOM_FIELDS=0
FIELDS=""
UP_ONLY=0
SHOW_HEADER=1
IFACE_FILTER=""


# ==============================================================================
# Functions
# ==============================================================================

usage() {
    cat <<'EOF'
Usage:
  nic-info.sh [OPTIONS]

Interface selection:
  -p, --physical
      Show device-backed NICs only.
      This is the default.
      Docker bridges, veth interfaces and lo are excluded.

  -a, --all
      Show all network interfaces.

  -i, --interface NAME
      Show only the specified interface.
      Can be specified multiple times.

  -u, --up-only
      Show only interfaces whose operstate is "up".

IP display:
  -4, --ipv4-only
      Show IPv4 only.

  -6, --ipv6-only
      Show IPv6 only.

  -46, --dual-stack
      Show both IPv4 and IPv6.
      This is the default.

Column selection:
  -f, --fields LIST
      Select columns to display.

      Available fields:
        nic
        state
        mac
        alias
        ipv4
        ipv6

      Example:
        --fields nic,alias,ipv4

Other:
  --no-header
      Do not print the table header.

  -h, --help
      Show this help.

Examples:

  nic-info.sh

  nic-info.sh --all

  nic-info.sh -4

  nic-info.sh --fields nic,alias,ipv4

  nic-info.sh --all --up-only

  nic-info.sh --interface ens160

  nic-info.sh -i ens160 -i ens192

  nic-info.sh --all --fields nic,state,alias,ipv4,ipv6
EOF
}


die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}


is_valid_field() {
    case "$1" in
        nic|state|mac|alias|ipv4|ipv6)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}


validate_fields() {
    _vf_old_ifs=$IFS
    IFS=','
    set -- $FIELDS
    IFS=$_vf_old_ifs

    [ "$#" -gt 0 ] || die "No fields specified."

    for _vf_field do
        is_valid_field "$_vf_field" ||
            die "Unknown field: $_vf_field"
    done
}


is_device_nic() {
    [ -e "$1/device" ]
}


is_selected_interface() {
    _si_name=$1

    [ -z "$IFACE_FILTER" ] && return 0

    case " $IFACE_FILTER " in
        *" $_si_name "*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}


get_ipv4() {
    ip -o -4 addr show dev "$1" 2>/dev/null |
        awk '
        {
            if (out != "")
                out = out ", " $4
            else
                out = $4
        }
        END {
            print out
        }'
}


get_ipv6() {
    ip -o -6 addr show dev "$1" 2>/dev/null |
        awk '
        {
            if (out != "")
                out = out ", " $4
            else
                out = $4
        }
        END {
            print out
        }'
}


field_width() {
    case "$1" in
        nic)
            printf '%s' '8'
            ;;
        state)
            printf '%s' '8'
            ;;
        mac)
            printf '%s' '18'
            ;;
        alias)
            printf '%s' '20'
            ;;
        ipv4)
            printf '%s' '20'
            ;;
        ipv6)
            printf '%s' '48'
            ;;
    esac
}


field_header() {
    case "$1" in
        nic)   printf '%s' 'NIC' ;;
        state) printf '%s' 'STATE' ;;
        mac)   printf '%s' 'MAC' ;;
        alias) printf '%s' 'ALIAS' ;;
        ipv4)  printf '%s' 'IPv4' ;;
        ipv6)  printf '%s' 'IPv6' ;;
    esac
}


print_separator() {
    _ps_count=$1

    while [ "$_ps_count" -gt 0 ]; do
        printf '%s' '-'
        _ps_count=$((_ps_count - 1))
    done
}


print_header() {
    _ph_old_ifs=$IFS
    IFS=','
    set -- $FIELDS
    IFS=$_ph_old_ifs

    while [ "$#" -gt 0 ]; do
        _ph_field=$1
        shift

        _ph_width=$(field_width "$_ph_field")
        _ph_title=$(field_header "$_ph_field")

        if [ "$#" -eq 0 ]; then
            printf '%s\n' "$_ph_title"
        else
            printf "%-${_ph_width}s " "$_ph_title"
        fi
    done

    _ph_old_ifs=$IFS
    IFS=','
    set -- $FIELDS
    IFS=$_ph_old_ifs

    while [ "$#" -gt 0 ]; do
        _ph_field=$1
        shift

        _ph_width=$(field_width "$_ph_field")

        if [ "$#" -eq 0 ]; then
            print_separator "$_ph_width"
            printf '\n'
        else
            print_separator "$_ph_width"
            printf ' '
        fi
    done
}


field_value() {
    case "$1" in
        nic)
            printf '%s' "$NIC_NAME"
            ;;

        state)
            printf '%s' "$NIC_STATE"
            ;;

        mac)
            printf '%s' "$NIC_MAC"
            ;;

        alias)
            printf '%s' "$NIC_ALIAS"
            ;;

        ipv4)
            printf '%s' "$NIC_IPV4"
            ;;

        ipv6)
            printf '%s' "$NIC_IPV6"
            ;;
    esac
}


print_row() {
    _pr_old_ifs=$IFS
    IFS=','
    set -- $FIELDS
    IFS=$_pr_old_ifs

    while [ "$#" -gt 0 ]; do
        _pr_field=$1
        shift

        _pr_width=$(field_width "$_pr_field")
        _pr_value=$(field_value "$_pr_field")

        if [ "$#" -eq 0 ]; then
            printf '%s\n' "$_pr_value"
        else
            printf "%-${_pr_width}s " "$_pr_value"
        fi
    done
}


# ==============================================================================
# Argument Parsing
# ==============================================================================

while [ "$#" -gt 0 ]; do

    case "$1" in

        -p|--physical)
            MODE="physical"
            ;;

        -a|--all)
            MODE="all"
            ;;

        -u|--up-only)
            UP_ONLY=1
            ;;

        -4|--ipv4-only)
            IP_MODE="ipv4"
            ;;

        -6|--ipv6-only)
            IP_MODE="ipv6"
            ;;

        -46|--dual-stack)
            IP_MODE="dual"
            ;;

        -f|--fields)
            shift
            [ "$#" -gt 0 ] ||
                die "--fields requires an argument."

            FIELDS=$1
            CUSTOM_FIELDS=1
            ;;

        --fields=*)
            FIELDS=${1#*=}
            CUSTOM_FIELDS=1
            ;;

        -i|--interface)
            shift
            [ "$#" -gt 0 ] ||
                die "--interface requires an interface name."

            if [ -n "$IFACE_FILTER" ]; then
                IFACE_FILTER="$IFACE_FILTER $1"
            else
                IFACE_FILTER=$1
            fi
            ;;

        --interface=*)
            _arg_iface=${1#*=}

            [ -n "$_arg_iface" ] ||
                die "--interface requires an interface name."

            if [ -n "$IFACE_FILTER" ]; then
                IFACE_FILTER="$IFACE_FILTER $_arg_iface"
            else
                IFACE_FILTER=$_arg_iface
            fi
            ;;

        --no-header)
            SHOW_HEADER=0
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        *)
            die "Unknown option: $1"
            ;;

    esac

    shift
done


# ==============================================================================
# Field Presets
# ==============================================================================

if [ "$CUSTOM_FIELDS" -eq 0 ]; then

    case "$IP_MODE" in

        ipv4)
            FIELDS="nic,state,mac,alias,ipv4"
            ;;

        ipv6)
            FIELDS="nic,state,mac,alias,ipv6"
            ;;

        dual)
            FIELDS="nic,state,mac,alias,ipv4,ipv6"
            ;;
        normal)
            FIELDS="nic,mac,alias,ipv4"
            ;;
    esac

fi

validate_fields


# ==============================================================================
# Main
# ==============================================================================

if [ "$SHOW_HEADER" -eq 1 ]; then
    print_header
fi


for NIC_PATH in /sys/class/net/*; do

    [ -e "$NIC_PATH" ] || continue

    NIC_NAME=${NIC_PATH##*/}

    # --------------------------------------------------------------------------
    # Interface filter
    # --------------------------------------------------------------------------

    is_selected_interface "$NIC_NAME" || continue


    # --------------------------------------------------------------------------
    # Physical / Device-backed NIC filter
    # --------------------------------------------------------------------------

    if [ "$MODE" = "physical" ]; then
        is_device_nic "$NIC_PATH" || continue
    fi


    # --------------------------------------------------------------------------
    # Read interface information
    # --------------------------------------------------------------------------

    NIC_STATE=$(cat "$NIC_PATH/operstate" 2>/dev/null)
    NIC_MAC=$(cat "$NIC_PATH/address" 2>/dev/null)
    NIC_ALIAS=$(cat "$NIC_PATH/ifalias" 2>/dev/null)

    [ -n "$NIC_STATE" ] || NIC_STATE="-"
    [ -n "$NIC_MAC" ] || NIC_MAC="-"
    [ -n "$NIC_ALIAS" ] || NIC_ALIAS="-"


    # --------------------------------------------------------------------------
    # UP-only filter
    # --------------------------------------------------------------------------

    if [ "$UP_ONLY" -eq 1 ] && [ "$NIC_STATE" != "up" ]; then
        continue
    fi


    # --------------------------------------------------------------------------
    # IP addresses
    # --------------------------------------------------------------------------

    NIC_IPV4="-"
    NIC_IPV6="-"

    case "$FIELDS" in
        *ipv4*)
            NIC_IPV4=$(get_ipv4 "$NIC_NAME")
            [ -n "$NIC_IPV4" ] || NIC_IPV4="-"
            ;;
    esac

    case "$FIELDS" in
        *ipv6*)
            NIC_IPV6=$(get_ipv6 "$NIC_NAME")
            [ -n "$NIC_IPV6" ] || NIC_IPV6="-"
            ;;
    esac


    print_row

done
