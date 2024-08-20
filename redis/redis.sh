#!/bin/bash
### ubuntu

# Script configuration
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="/tmp/${SCRIPT_NAME}-$(date +%Y-%m-%d_%H-%M).log"
REDIS_CONF="/etc/redis/redis.conf"

# Logging function
log() {
    local message="$1"
    local status="$2"
    local color
    if [[ $status -eq 0 ]]; then
        color="\033[0;32m" # Green for success
    else
        color="\033[0;31m" # Red for failure
    fi
    echo -e "${color}${message}\033[0m"
    echo "$(date +%Y-%m-%d_%H-%M:%S) - ${message}" >> "$LOG_FILE"
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    log "This script must be run as root." 1
    exit 1
fi

# Update package list and install Redis
log "Updating package list..." 0
sudo apt-get update -y &>> "$LOG_FILE"
log "Updating package list completed." $?

log "Installing Redis..." 0
sudo apt-get install -y redis &>> "$LOG_FILE"
log "Redis installation completed." $?

# Modify Redis configuration
if [[ -f "$REDIS_CONF" ]]; then
    log "Modifying Redis configuration file..." 0
    sed -i 's/^bind 127.0.0.1 -::1/bind 0.0.0.0 -::1/' "$REDIS_CONF" &>> "$LOG_FILE"
    sed -i 's/^protected-mode yes/protected-mode no/' "$REDIS_CONF" &>> "$LOG_FILE"
    log "Redis configuration modification completed." $?
else
    log "Redis configuration file not found at $REDIS_CONF" 1
fi

# Restart Redis to apply the changes
log "Restarting Redis service..." 0
sudo systemctl restart redis &>> "$LOG_FILE"
log "Redis service restart completed." $?

log "Script execution completed." 0
