#!/bin/bash
# ubuntu24
LOG_FILE="/tmp/$(basename "${0%.*}")_$(date +%Y-%m-%d_%H-%M).log"
SERVICE_NAME="mysql"
ROOT_PASS="RoboShop@1"
MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"

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

# Update the system packages
apt update -y &>>"$LOG_FILE"
LOG "Updating system packages" $?

# Install MySQL server
apt install mysql-server -y &>>"$LOG_FILE"
LOG "Installing MySQL server" $?

# Secure MySQL installation manually
mysql -e "DELETE FROM mysql.user WHERE User='';" &>>"$LOG_FILE"
LOG "Removed anonymous users" $?

mysql -e "DROP DATABASE IF EXISTS test;" &>>"$LOG_FILE"
LOG "Dropped test database" $?

mysql -e "FLUSH PRIVILEGES;" &>>"$LOG_FILE"
LOG "Flushed privileges" $?

# Set MySQL root password and configure user access
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASS';" &>>"$LOG_FILE"
LOG "Set MySQL root password" $?

# Create user, grant privileges, and flush privileges
mysql -e "
  CREATE USER 'root'@'%' IDENTIFIED BY 'RoboShop@1';
  GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
  FLUSH PRIVILEGES;
" &>>"$LOG_FILE"
LOG "Configured MySQL user access" $?

# Update bind address in MySQL configuration
sed -i 's/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' "$MYSQL_CONF" &>>"$LOG_FILE"
LOG "Updating bind address in MySQL configuration" $?

# Restart MySQL to apply configuration changes
systemctl restart "$SERVICE_NAME" &>>"$LOG_FILE"
LOG "Restarting MySQL service" $?

# mysql -h rb-mysql.test.ullagallu.cloud -uroot -pRoboShop@1 < mysql-shipping.sql