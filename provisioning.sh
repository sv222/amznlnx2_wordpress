#!/bin/sh
########### variables
MYSQL_ROOT_PASS="123"
DB_USER="wp_user"
DB_USER_PASS="123"
WORDPRESS_DATABASE="wp_db"
WORDPRESS_DIR="/var/www/wordpress/"
WORDPRESS_URL="http://localhost:8080/"
########### variables

# Update repository's cache & upgrade
sudo yum update && sudo yum upgrade -y
# install zsh, midnight commander
sudo yum install zsh mc -y
# install micro editor
curl https://getmic.ro | bash && sudo mv micro /usr/bin
# install linux extras addons, mariadb addon, php/php addons
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install php-mbstring php-xml -y
# install apache, mariadb server
sudo yum install -y httpd mariadb-server
# add apache and mariadb to autostart and start service
sudo systemctl start httpd mariadb && sudo systemctl enable httpd mariadb
# add current user to apache group
sudo usermod -aG apache vagrant

# download wordpress
wget https://wordpress.org/latest.tar.gz
# unpacking archive
tar -xzf latest.tar.gz && sudo rm latest.tar.gz
# make wordpress working directory, replace files from source to working directory, clean artifactes
mkdir ${WORDPRESS_DIR} && cp -r wordpress/* ${WORDPRESS_DIR} && sudo rm -rf wordpress
# change owner of apache working directory for current user
sudo chown -R vagrant:apache /var/www
# change permitions for all directories in root directory
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
# change permitions for all files in root directory
find /var/www -type f -exec sudo chmod 0664 {} \;
# install exoect tool for sielent installation
sudo yum install expect -y

# configure mysql
#sudo mysql_secure_installation
expect -f - <<-EOF
  set timeout 1
  spawn mysql_secure_installation
  expect "Enter current password for root (enter for none):"
  send -- "\r"
  expect "Set root password?"
  send -- "y\r"
  expect "New password:"
  send -- "${MYSQL_ROOT_PASS}\r"
  expect "Re-enter new password:"
  send -- "${MYSQL_ROOT_PASS}\r"
  expect "Remove anonymous users?"
  send -- "y\r"
  expect "Disallow root login remotely?"
  send -- "y\r"
  expect "Remove test database and access to it?"
  send -- "y\r"
  expect "Reload privilege tables now?"
  send -- "y\r"
  expect eof
EOF

# create database, user, grant privileges
mysql -uroot -p${MYSQL_ROOT_PASS} -e "CREATE DATABASE ${WORDPRESS_DATABASE} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "CREATE USER ${DB_USER}@localhost IDENTIFIED BY '${DB_USER_PASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON ${WORDPRESS_DATABASE}.* TO '${DB_USER}'@'localhost';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "FLUSH PRIVILEGES;"


# change config directory for apache config
sudo sed -i 's/\/html/\/wordpress/g' /etc/httpd/conf/httpd.conf

# restart mariadb
sudo systemctl restart mariadb httpd

# create config file for wordpress
mv ${WORDPRESS_DIR}wp-config-sample.php ${WORDPRESS_DIR}wp-config.php

# set config variables: database, user, password
sudo sed -i "s/database_name_here/${WORDPRESS_DATABASE}/g" ${WORDPRESS_DIR}wp-config.php
sudo sed -i "s/username_here/${DB_USER}/g" ${WORDPRESS_DIR}wp-config.php
sudo sed -i "s/password_here/${DB_USER_PASS}/g" ${WORDPRESS_DIR}wp-config.php

# finish installation at

echo "finish installation at link:" $WORDPRESS_URL
