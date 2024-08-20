#!/bin/bash

LOG_FILE="/tmp/$(basename "${0%.*}")_$(date +%Y-%m-%d_%H-%M).log"
APP_DIR="/app"
SERVICE_FILE="/etc/systemd/system/dispatch.service"
REPO_URL="https://github.com/ullagallu123/dispatch.git"
BRANCH="dev/dispatch"

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

# Install Go
dnf install -y golang &>>"$LOG_FILE"
LOG "Installing Go" $?

# Create user roboshop if it doesn't exist
id -u roboshop &>/dev/null || useradd roboshop &>>"$LOG_FILE"
LOG "Creating user roboshop" $?

# Create /app directory if it doesn't exist
[ ! -d "$APP_DIR" ] && mkdir -p "$APP_DIR" &>>"$LOG_FILE"
LOG "Creating /app directory" $?

# Clone the Git repository for the Dispatch service
if [ ! -d "$APP_DIR/.git" ]; then
  git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$APP_DIR" &>>"$LOG_FILE"
  LOG "Cloning Git repository (branch: $BRANCH)" $?
fi

# Change directory to /app and set up Go project
cd "$APP_DIR" || exit
go mod init dispatch &>>"$LOG_FILE"
LOG "Initializing Go module" $?

go get &>>"$LOG_FILE"
LOG "Fetching Go module dependencies" $?

go build &>>"$LOG_FILE"
LOG "Building Dispatch application" $?

# Create systemd service file for the Dispatch service
if [ ! -f "$SERVICE_FILE" ]; then
  cat <<EOF > "$SERVICE_FILE"
[Unit]
Description = Dispatch Service
[Service]
User=roboshop
Environment=AMQP_HOST=rb-rabbit.test.ullagallu.cloud
Environment=AMQP_USER=roboshop
Environment=AMQP_PASS=roboshop123
ExecStart=/app/dispatch
SyslogIdentifier=dispatch

[Install]
WantedBy=multi-user.target
EOF
  LOG "Creating systemd service file for Dispatch service" $?
fi

# Reload systemd, enable, and start the Dispatch service
systemctl daemon-reload &>>"$LOG_FILE"
LOG "Reloading systemd" $?

systemctl enable dispatch &>>"$LOG_FILE"
LOG "Enabling Dispatch service" $?

systemctl start dispatch &>>"$LOG_FILE"
LOG "Starting Dispatch service" $?

# Amazon23