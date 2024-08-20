#!/bin/bash

# Set log file and other variables
LOG_FILE="/tmp/$(basename "${0%.*}")_$(date +%Y-%m-%d_%H-%M).log"
NGINX_CONF="/etc/nginx/default.d/roboshop.conf"
WEB_DIR="/usr/share/nginx/html"
REPO_URL="https://github.com/ullagallu123/instana-web.git"
BRANCH="dev/web"

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

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." | tee -a "$LOG_FILE"
  exit 1
fi

# Function to install packages if not already installed
install_package() {
  local PACKAGE=$1
  if ! dnf list installed "$PACKAGE" &>/dev/null; then
    dnf install -y "$PACKAGE" &>>"$LOG_FILE"
    LOG "Installing $PACKAGE" $?
  else
    LOG "$PACKAGE is already installed" 0
  fi
}

# Install necessary packages
install_package git
install_package nginx

# Enable and start NGINX service if not already running
if ! systemctl is-enabled --quiet nginx; then
  systemctl enable nginx &>>"$LOG_FILE"
  LOG "Enabling NGINX service" $?
else
  LOG "NGINX service is already enabled" 0
fi

if ! systemctl is-active --quiet nginx; then
  systemctl start nginx &>>"$LOG_FILE"
  LOG "Starting NGINX service" $?
else
  LOG "NGINX service is already running" 0
fi

# Remove default HTML files if they exist
if [ -d "$WEB_DIR" ]; then
  rm -rf "$WEB_DIR"/* &>>"$LOG_FILE"
  LOG "Removing default NGINX HTML files" $?
else
  LOG "Web directory $WEB_DIR does not exist, creating it" 0
  mkdir -p "$WEB_DIR"
fi

# Clone the Git repository for the web service if not already cloned
if [ ! -d "$WEB_DIR/.git" ]; then
  git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$WEB_DIR" &>>"$LOG_FILE"
  LOG "Cloning Git repository (branch: $BRANCH)" $?
  
  # Verify if the clone was successful and the directory is not empty
  if [ -z "$(ls -A "$WEB_DIR")" ]; then
    LOG "Git repository cloned but directory is empty. Check if the branch $BRANCH contains any files." 1
    exit 1
  fi
  
  # Move content from web/ to $WEB_DIR if web/ directory exists
  if [ -d "$WEB_DIR/web" ]; then
    mv "$WEB_DIR/web/"* "$WEB_DIR/" &>>"$LOG_FILE"
    LOG "Moving content from web/ to $WEB_DIR" $?
    rm -rf "$WEB_DIR/web" &>>"$LOG_FILE"
    LOG "Removing web/ directory" $?
  else
    LOG "web/ directory not found in the cloned repository" 0
  fi
else
  LOG "Git repository already cloned in $WEB_DIR" 0
fi

# Remove the .git directory to clean up the deployment
if [ -d "$WEB_DIR/.git" ]; then
  rm -rf "$WEB_DIR/.git" &>>"$LOG_FILE"
  LOG "Removing .git directory" $?
fi

# Create and update NGINX configuration if it does not already exist
if [ ! -f "$NGINX_CONF" ]; then
  cat <<EOF > "$NGINX_CONF"
proxy_http_version 1.1;

location /images/ {
  expires 5s;
  root /usr/share/nginx/html;
  try_files \$uri /images/placeholder.jpg =404;
}

location /api/catalogue/ {
  proxy_pass http://rb-catalogue.test.ullagallu.cloud:8080/;
}

location /api/user/ {
  proxy_pass http://rb-user.test.ullagallu.cloud:8080/;
}

location /api/cart/ {
  proxy_pass http://rb-cart.test.ullagallu.cloud:8080/;
}

location /api/shipping/ {
  proxy_pass http://rb-shipping.test.ullagallu.cloud:8080/;
}

location /api/payment/ {
  proxy_pass http://rb-payment.test.ullagallu.cloud:8080/;
}

location /health {
  stub_status on;
  access_log off;
}
EOF
  LOG "Creating NGINX configuration file" $?
else
  LOG "NGINX configuration file already exists" 0
fi

# Test NGINX configuration and restart if valid
if nginx -t &>>"$LOG_FILE"; then
  LOG "Testing NGINX configuration" 0
  systemctl restart nginx &>>"$LOG_FILE"
  LOG "Restarting NGINX service" $?
else
  LOG "NGINX configuration test failed" 1
fi

# Troubleshooting tips
echo "If you encounter a 403 Forbidden error, ensure that the files were correctly cloned into $WEB_DIR and that the NGINX process can access them." | tee -a "$LOG_FILE"
