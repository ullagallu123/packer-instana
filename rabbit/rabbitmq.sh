#!/bin/bash

# Generate a dynamic log file name based on the script's name and current timestamp
LOG_FILE="/tmp/$(basename "${0%.*}")_$(date +%Y-%m-%d_%H-%M).log"

# Define repository URLs and service name
REPO_RABBITMQ="https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh"
REPO_ERLANG="https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh"
SERVICE_NAME="rabbitmq-server"
RABBITMQ_USER="roboshop"
RABBITMQ_PASS="roboshop123"

# Color codes for logging
COLOR_GREEN="\e[32m"
COLOR_RED="\e[31m"
COLOR_RESET="\e[0m"

# Logging function
LOG() {
  local MESSAGE=$1
  local STATUS=$2
  if [ $STATUS -eq 0 ]; then
    echo -e "${COLOR_GREEN}${MESSAGE} - SUCCESS${COLOR_RESET}" | tee -a "$LOG_FILE"
  else
    echo -e "${COLOR_RED}${MESSAGE} - FAILED${COLOR_RESET}" | tee -a "$LOG_FILE"
  fi
}

# Helper function to log messages with timestamps
log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" >> "$LOG_FILE"
}

# Ensure the script runs with sudo privileges
if [ "$(id -u)" -ne "0" ]; then
    echo "This script requires sudo privileges. Please run as root." >&2
    exit 1
fi

log_message "Starting RabbitMQ installation..."

# Install necessary packages
if ! dpkg -l | grep -q 'curl'; then
    log_message "Installing curl..."
    apt-get install curl -y &>> "$LOG_FILE"
    LOG "Installing curl" $?
fi

if ! dpkg -l | grep -q 'gnupg'; then
    log_message "Installing gnupg..."
    apt-get install gnupg -y &>> "$LOG_FILE"
    LOG "Installing gnupg" $?
fi

if ! dpkg -l | grep -q 'apt-transport-https'; then
    log_message "Installing apt-transport-https..."
    apt-get install apt-transport-https -y &>> "$LOG_FILE"
    LOG "Installing apt-transport-https" $?
fi

# Set up RabbitMQ repositories
log_message "Setting up RabbitMQ repositories..."

REPO_FILE="/etc/apt/sources.list.d/rabbitmq.list"
if [ ! -f "$REPO_FILE" ]; then
    log_message "Adding RabbitMQ repository keys and sources..."
    
    curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | gpg --dearmor | tee /usr/share/keyrings/com.rabbitmq.team.gpg > /dev/null
    curl -1sLf https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key | gpg --dearmor | tee /usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg > /dev/null
    curl -1sLf https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key | gpg --dearmor | tee /usr/share/keyrings/rabbitmq.9F4587F226208342.gpg > /dev/null

    tee "$REPO_FILE" <<EOF
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main

deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main

deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main

deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
EOF
    LOG "Adding RabbitMQ repositories" $?
fi

# Update package list
log_message "Updating package list..."
apt-get update -y &>> "$LOG_FILE"
LOG "Updating package list" $?

# Install Erlang dependencies if not already installed
log_message "Checking and installing Erlang dependencies..."
if ! dpkg -l | grep -q 'erlang-base'; then
    apt-get install -y erlang-base \
                        erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
                        erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
                        erlang-runtime-tools erlang-snmp erlang-ssl \
                        erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl &>> "$LOG_FILE"
    LOG "Installing Erlang dependencies" $?
fi

# Install RabbitMQ server if not already installed
log_message "Checking and installing RabbitMQ server..."
if ! dpkg -l | grep -q 'rabbitmq-server'; then
    apt-get install rabbitmq-server -y --fix-missing &>> "$LOG_FILE"
    LOG "Installing RabbitMQ server" $?
fi

# Add RabbitMQ user and set permissions
log_message "Configuring RabbitMQ..."
rabbitmqctl list_users | grep -q "$RABBITMQ_USER" || {
    rabbitmqctl add_user "$RABBITMQ_USER" "$RABBITMQ_PASS" &>> "$LOG_FILE"
    LOG "Adding RabbitMQ user" $?
    rabbitmqctl set_permissions -p / "$RABBITMQ_USER" ".*" ".*" ".*" &>> "$LOG_FILE"
    LOG "Setting permissions for RabbitMQ user" $?
}

log_message "RabbitMQ installation and configuration complete."

# ubuntu24