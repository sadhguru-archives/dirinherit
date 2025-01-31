#!/bin/bash

readonly SCRIPT_NAME=$(basename "$0")
readonly WATCH_PARENT="/data/dwara/workspace"

log() {
    echo "$@" | systemd-cat -t "$SCRIPT_NAME" -p info
}

process_path() {
    local fullPath="$1"
    local parentDir="$2"

    # Skip Samba temporary files
    if [[ "$fullPath" =~ \.smb.*\.[0-9]+$ ]]; then
        log "Skipping Samba temporary file: $fullPath"
        return
    fi

    # Make sure both the path and parent still exist before processing
    if [ ! -e "$fullPath" ] || [ ! -d "$parentDir" ]; then
        log "Path no longer exists, skipping: $fullPath"
        return
    fi

    # Get ownership from parent directory
    ownerGroup=$(stat -c '%U:%G' "$parentDir")
    if [ $? -ne 0 ]; then
        log "Failed to get parent directory ownership: $parentDir"
        return
    fi

    if [ -d "$fullPath" ]; then
        # For directories:
        log "Processing directory: $fullPath"

        # Set ownership/permissions on the directory itself
        chown "$ownerGroup" "$fullPath" 2>/dev/null
        chmod 770 "$fullPath" 2>/dev/null

        # Handle immediate child files
        find "$fullPath" -maxdepth 1 -type f -exec chown "$ownerGroup" {} + -exec chmod 660 {} + 2>/dev/null
    else
        # For individual files
        log "Processing file: $fullPath"
        chown "$ownerGroup" "$fullPath" 2>/dev/null
        chmod 660 "$fullPath" 2>/dev/null
    fi
}

# Handle script termination gracefully
trap "log 'Script terminated by signal'; kill 0; exit 0" SIGTERM SIGINT

log "Starting permission inheritance watch on $WATCH_PARENT"

# Main loop
inotifywait -m -r -e moved_to,create --format '%w %f' "$WATCH_PARENT" |
while read -r dir file; do
    if [[ -z "$dir" || -z "$file" ]]; then
        log "Unexpected output from inotifywait: dir='$dir', file='$file'"
        continue
    fi
    fullPath="${dir%/}/$file"
    parentDir="$(dirname "$fullPath")"
    process_path "$fullPath" "$parentDir"
done
