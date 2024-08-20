#!/bin/bash

# Define log file
LOG_FILE="/tmp/$(basename "${0%.*}")_$(date +%Y-%m-%d_%H-%M).log"
APP_DIR="/app"
SERVICE_FILE="/etc/systemd/system/payment.service"
REPO_URL="https://github.com/ullagallu123/instana-payment.git"
PYTHON_VERSION="3.12"
REQUIREMENTS_FILE="$APP_DIR/requirements.txt"
UWSGI_INI="payment.ini"

# Color codes for logging
COLOR_GREEN="\e[32m"
COLOR_RED="\e[31m"
COLOR_RESET="\e[0m"

# Logging function
LOG() {
  local MESSAGE="$1"
  local STATUS="$2"
  if [ "$STATUS" -eq 0 ]; then
    echo -e "${COLOR_GREEN}${MESSAGE} - SUCCESS${COLOR_RESET}" | tee -a "$LOG_FILE"
  else
    echo -e "${COLOR_RED}${MESSAGE} - FAILED${COLOR_RESET}" | tee -a "$LOG_FILE"
  fi
}

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root." | tee -a "$LOG_FILE"
  exit 1
fi

# Update package list and install required packages
apt-get update &>>"$LOG_FILE"
apt-get -y install python3-pip python3.12-venv &>>"$LOG_FILE"
LOG "Installing Python 3.12, pip, and virtual environment tools" $?

# Create user roboshop if it doesn't exist
id -u roboshop &>/dev/null || useradd roboshop &>>"$LOG_FILE"
LOG "Creating user roboshop" $?

# Create /app directory if it doesn't exist
[ ! -d "$APP_DIR" ] && mkdir -p "$APP_DIR" &>>"$LOG_FILE"
LOG "Creating /app directory" $?

# Clone the Git repository for the Payment service
if [ ! -d "$APP_DIR/.git" ]; then
  git clone "$REPO_URL" "$APP_DIR" &>>"$LOG_FILE"
  LOG "Cloning Git repository" $?
fi

# Change directory to /app and set up Python virtual environment
cd "$APP_DIR" || exit
python3 -m venv venv &>>"$LOG_FILE"
source venv/bin/activate
pip install -r "$REQUIREMENTS_FILE" &>>"$LOG_FILE"
pip install setuptools &>>"$LOG_FILE"
deactivate
LOG "Setting up Python virtual environment and installing dependencies" $?

# Create systemd service file for the Payment service
if [ ! -f "$SERVICE_FILE" ]; then
  cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Payment Service

[Service]
User=root
WorkingDirectory=/app
Environment=CART_HOST=rb-cart.test.ullagallu.cloud
Environment=CART_PORT=8080
Environment=USER_HOST=rb-user.test.ullagallu.cloud
Environment=USER_PORT=8080
Environment=AMQP_HOST=rb-rabbit.test.ullagallu.cloud
Environment=AMQP_USER=roboshop
Environment=AMQP_PASS=roboshop123

ExecStart=/app/venv/bin/uwsgi --ini payment.ini
ExecStop=/bin/kill -9 \$MAINPID
SyslogIdentifier=payment

[Install]
WantedBy=multi-user.target
EOF
  LOG "Creating systemd service file for Payment service" $?
fi

# Reload systemd, enable, and start the Payment service
systemctl daemon-reload &>>"$LOG_FILE"
LOG "Reloading systemd" $?

systemctl enable payment &>>"$LOG_FILE"
LOG "Enabling Payment service" $?

systemctl start payment &>>"$LOG_FILE"
LOG "Starting Payment service" $?

exit 0
