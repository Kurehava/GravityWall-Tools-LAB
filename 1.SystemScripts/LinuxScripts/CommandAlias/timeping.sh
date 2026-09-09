ping() {
    command ping -O "$@" | while IFS= read -r line; do
        printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$line"
    done
}

# if want use default ping command
# you can use Command command to use original ping.
# e.g.
# command ping -O 8.8.8.8
