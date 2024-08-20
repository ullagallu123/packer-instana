#!/bin/bash

LOG_FILE="/tmp/$(basename "${0%.*}")_$(date +%Y-%m-%d_%H-%M).log"
APP_DIR="/app"
SERVICE_FILE="/etc/systemd/system/shipping.service"
REPO_URL="https://github.com/ullagallu123/instana-shipping.git"
BRANCH="dev/shipping"
JAR_FILE="shipping.jar"

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

apt-get install -y mysql-client maven &>>"$LOG_FILE"
LOG "Installing MySQL and Maven" $?

# Create user roboshop if it doesn't exist
id -u roboshop &>/dev/null || useradd roboshop &>>"$LOG_FILE"
LOG "Creating user roboshop" $?

# Create /app directory if it doesn't exist
[ ! -d "$APP_DIR" ] && mkdir -p "$APP_DIR" &>>"$LOG_FILE"
LOG "Creating /app directory" $?

# Clone the Git repository for the Shipping service
if [ ! -d "$APP_DIR/.git" ]; then
  git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$APP_DIR" &>>"$LOG_FILE"
  LOG "Cloning Git repository (branch: $BRANCH)" $?
fi

# Change directory to /app and build the application
cd "$APP_DIR" && mvn clean package &>>"$LOG_FILE"
LOG "Building application with Maven" $?

# Move the JAR file to the desired location
[ -f "$APP_DIR/target/shipping-1.0.jar" ] && mv "$APP_DIR/target/shipping-1.0.jar" "$APP_DIR/$JAR_FILE" &>>"$LOG_FILE"
LOG "Moving JAR file to /app" $?

# Create systemd service file for the Shipping service
if [ ! -f "$SERVICE_FILE" ]; then
  cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Shipping Service

[Service]
User=roboshop
Environment=CART_ENDPOINT=rb-cart.test.ullagallu.cloud:8080
Environment=DB_HOST=rb-mysql.test.ullagallu.cloud
Environment=DB_PORT="3306"
Environment=DB_USER="shipping"
Environment=DB_PASSWD="RoboShop@1"
ExecStart=/bin/java -jar /app/shipping.jar
SyslogIdentifier=shipping

[Install]
WantedBy=multi-user.target

EOF
  LOG "Creating systemd service file for Shipping service" $?
fi

# Reload systemd, enable, and start the Shipping service
systemctl daemon-reload &>>"$LOG_FILE"
LOG "Reloading systemd" $?

systemctl enable shipping &>>"$LOG_FILE"
LOG "Enabling Shipping service" $?

systemctl start shipping &>>"$LOG_FILE"
LOG "Starting Shipping service" $?
