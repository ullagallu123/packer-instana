#!/bin/bash

LOG_FILE="/tmp/$(basename "${0%.*}")_$(date +%Y-%m-%d_%H-%M).log"
APP_DIR="/app"
SERVICE_FILE="/etc/systemd/system/user.service"
REPO_URL="https://github.com/ullagallu123/instana-user.git"
BRANCH="dev/user"
MONGOSH_TAR="mongosh-2.2.15-linux-x64.tgz"
MONGOSH_URL="https://downloads.mongodb.com/compass/${MONGOSH_TAR}"

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


apt update -y &>>"LOG_FILE"
LOG "Updating System Packages" $?

# Installing Redis-Tools
sudo apt install redis-tools -y &>>"LOG_FILE"
LOG "Installing Redis Tools" $?
# Install MongoDB Compass (mongosh)
wget "$MONGOSH_URL" -O /tmp/$MONGOSH_TAR &>>"$LOG_FILE"
LOG "Downloading MongoDB Compass (mongosh)" $?

tar -xzf /tmp/$MONGOSH_TAR -C /tmp &>>"$LOG_FILE"
LOG "Extracting MongoDB Compass (mongosh)" $?

mv /tmp/mongosh-2.2.15-linux-x64/bin/mongosh /usr/local/bin &>>"$LOG_FILE"
LOG "Moving MongoDB Compass (mongosh) to /usr/local/bin" $?

# Add Node.js repository and install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - &>>"$LOG_FILE"
LOG "Adding Node.js 20 repository" $?

sudo apt install -y nodejs &>>"$LOG_FILE"
LOG "Installing Node.js" $?

# Create user roboshop if it doesn't exist
id -u roboshop &>/dev/null || useradd roboshop &>>"$LOG_FILE"
LOG "Creating user roboshop" $?

# Create /app directory if it doesn't exist
[ ! -d "$APP_DIR" ] && mkdir -p "$APP_DIR" &>>"$LOG_FILE"
LOG "Creating /app directory" $?

# Clone the Git repository for the User service
if [ ! -d "$APP_DIR/.git" ]; then
  git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$APP_DIR" &>>"$LOG_FILE"
  LOG "Cloning Git repository (branch: $BRANCH)" $?
fi

# Change directory to /app and install npm dependencies
cd "$APP_DIR" && npm install &>>"$LOG_FILE"
LOG "Installing npm dependencies" $?

# Create systemd service file for the User service
if [ ! -f "$SERVICE_FILE" ]; then
  cat <<EOF > "$SERVICE_FILE"
[Unit]
Description = User Service
[Service]
User=roboshop
Environment=MONGO=true
Environment=REDIS_HOST=rb-redis.test.ullagallu.cloud
Environment=MONGO_URL="mongodb://rb-mongo.test.ullagallu.cloud:27017/users"
ExecStart=/bin/node /app/server.js
SyslogIdentifier=user

[Install]
WantedBy=multi-user.target
EOF
  LOG "Creating systemd service file for User service" $?
fi

# Reload systemd, enable, and start the User service
systemctl daemon-reload &>>"$LOG_FILE"
LOG "Reloading systemd" $?

systemctl enable user &>>"$LOG_FILE"
LOG "Enabling User service" $?

systemctl start user &>>"$LOG_FILE"
LOG "Starting User service" $?

# ubuntu24