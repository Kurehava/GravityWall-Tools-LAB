#!/usr/bin/env bash

set -uo pipefail

# ==============================================================================
# NIC Alias Configuration
#
# Format:
#   ["MAC_ADDRESS"]="ALIAS"
#
# MAC addresses are case-insensitive.
# ==============================================================================

declare -A NIC_ALIASES=(

    ["00:0c:29:fa:bf:01"]="NIC-1"
    ["00:0c:29:fa:bf:02"]="NIC-2"
    ["00:0c:29:fa:bf:03"]="NIC-3"
    ["00:0c:29:fa:bf:04"]="NIC-4"

)

# ==============================================================================
# Constants
# ==============================================================================

readonly IP="/usr/sbin/ip"
readonly TAG="nic-alias"


# ==============================================================================
# Functions
# ==============================================================================

log() {
    local message="$*"

    echo "[$TAG] $message"
    logger -t "$TAG" -- "$message"
}


find_interfaces_by_mac() {
    local target_mac="${1,,}"
    local path
    local iface
    local current_mac

    for path in /sys/class/net/*; do

        iface="${path##*/}"

        [[ "$iface" == "lo" ]] && continue
        [[ -r "$path/address" ]] || continue

        current_mac="$(<"$path/address")"
        current_mac="${current_mac,,}"

        if [[ "$current_mac" == "$target_mac" ]]; then
            printf '%s\n' "$iface"
        fi

    done
}


apply_alias() {
    local mac="${1,,}"
    local alias="$2"

    local -a interfaces=()
    local iface

    # Validate MAC
    if [[ ! "$mac" =~ ^([0-9a-f]{2}:){5}[0-9a-f]{2}$ ]]; then
        log "Invalid MAC address: $mac"
        return 1
    fi

    # Validate alias
    if [[ -z "$alias" ]]; then
        log "Alias is empty for MAC: $mac"
        return 1
    fi

    mapfile -t interfaces < <(find_interfaces_by_mac "$mac")

    case "${#interfaces[@]}" in

        0)
            log "NIC not found: MAC=$mac Alias=\"$alias\""
            return 0
            ;;

        1)
            iface="${interfaces[0]}"

            if "$IP" link set dev "$iface" alias "$alias"; then
                log "Applied: $iface [$mac] -> \"$alias\""
                return 0
            else
                log "Failed: $iface [$mac] -> \"$alias\""
                return 1
            fi
            ;;

        *)
            log "Multiple interfaces found for MAC=$mac: ${interfaces[*]}; skipping"
            return 1
            ;;

    esac
}


main() {
    local mac

    for mac in "${!NIC_ALIASES[@]}"; do
        apply_alias "$mac" "${NIC_ALIASES[$mac]}"
    done
}


# ==============================================================================
# Main
# ==============================================================================

main
