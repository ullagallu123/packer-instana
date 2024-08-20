#!/bin/bash
# ubuntu24
LOG_FILE="/tmp/$(basename "${0%.*}")_$(date +%Y-%m-%d_%H-%M).log"
MONGO_CONF="/etc/mongod.conf"

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

# Check for sudo privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." | tee -a "$LOG_FILE"
  exit 1
fi

# Install necessary packages
apt-get update &>>"$LOG_FILE"
apt-get install -y gnupg curl &>>"$LOG_FILE"
LOG "Installing gnupg and curl" $?

# Add MongoDB repository
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor &>>"$LOG_FILE"
LOG "Adding MongoDB GPG key" $?

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list &>>"$LOG_FILE"
LOG "Adding MongoDB repository" $?

# Install MongoDB
apt-get update &>>"$LOG_FILE"
apt-get install -y mongodb-org &>>"$LOG_FILE"
LOG "Installing MongoDB" $?

# Update MongoDB configuration
if grep -q 'bindIp: 127.0.0.1' "$MONGO_CONF"; then
  sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' "$MONGO_CONF" &>>"$LOG_FILE"
  LOG "Updating MongoDB bind IP address to 0.0.0.0" $?
else
  LOG "MongoDB configuration already updated" 0
fi

# Start and enable MongoDB service
systemctl start mongod &>>"$LOG_FILE"
LOG "Starting MongoDB service" $?

systemctl enable mongod &>>"$LOG_FILE"
LOG "Enabling MongoDB service" $?

# Check MongoDB status
systemctl status mongod &>>"$LOG_FILE"
LOG "Checking MongoDB service status" $?

# ubuntu24

# mongosh --host  3.110.216.241 --port 27017 < mongo-user.js
# mongosh --host  3.110.216.241 --port 27017 < mongo-catalogue.js