#!/bin/bash

#Disabling SElinux

yum install wget bind-utils -y

yum install lsof -y

sudo setenforce 0

cp -arp /etc/selinux/config  /etc/selinux/config.bak

sed -i '07 s/^/#/' /etc/selinux/config

echo "SELINUX=disabled" >> /etc/selinux/config

sestatus

#Install MySQL 5.7 service

cd /home/centos/

wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm

sudo rpm -ivh mysql-community-release-el7-5.noarch.rpm

rm -f mysql-community-release-el7-5.noarch.rpm

yum install mysql-server -y

#Install PHP and HTTPD service

yum install epel-release -y

rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

yum install php72w  php72w-pdo php72w-bcmath php72w-mbstring php72w-mysqlnd php72w-curl php72w-intl php72w-cli  php72w-fpm php72w-opcache php72w-bcmath php72w-gd php72w-dom php72w-soap php72w-xsl httpd24-devel httpd-tools httpd -y

cp -arp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak

sed -i '151s/None/All/g'  /etc/httpd/conf/httpd.conf

#Make HTTPD and MySQL service to start on boot.

chkconfig httpd on

chkconfig mysqld on

#Start HTTPD and MySQL service

service httpd start

service mysqld start

#Set up MySQL root password.

newpass=`openssl rand -hex 8`

mysqladmin -u root password $newpass

echo $newpass

#Setup new database and logins for Magento site.

DBNAME=db

DBUSER=user

PASS=`openssl rand -base64 12`

NEWDBNAME=drupal$DBNAME

echo $NEWDBNAME

NEWDBUSER=drupal$DBUSER

mysql -u root -p$newpass -e "CREATE DATABASE ${NEWDBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;"

mysql -u root -p$newpass -e "CREATE USER '${NEWDBUSER}'@'localhost' IDENTIFIED BY '${PASS}';"

mysql -u root -p$newpass -e "GRANT ALL PRIVILEGES ON ${NEWDBNAME}.* TO '${NEWDBUSER}'@'localhost';"

mysql -u root -p$newpass -e "FLUSH PRIVILEGES;"

touch /home/centos/dblogin.txt

echo dbname=$NEWDBNAME > /home/centos/dblogin.txt

echo dbusername=$NEWDBUSER >> /home/centos/dblogin.txt

echo dbpassword=$PASS >> /home/centos/dblogin.txt

echo $PASS

echo [client] > /root/.my.cnf

echo user=root >> /root/.my.cnf

echo password="\"$newpass"\" >> /root/.my.cnf

#Installing Composer command

cd /tmp

sudo curl -sS https://getcomposer.org/installer | php

mv composer.phar /usr/local/bin/composer

#Install zip and unzip commands

yum install zip unzip git -y

#setting up swap space

dd if=/dev/zero of=/swapfile bs=1M count=4096

mkswap /swapfile

swapon /swapfile

cp -arp /etc/fstab /etc/fstab.bak

echo "/swapfile      swap    swap     defaults     0     0" >> /etc/fstab

swapon -a

echo "======================================================================================================================="

echo " swap creation completed "

echo "======================================================================================================================="

#Downloading Drupal files and placing it in /var/www/html Document Root

PUBIP=`dig +short myip.opendns.com @resolver1.opendns.com`

adminpass=`openssl rand -base64 12`

username=admin

echo "======================================================================================================================="

echo " Declaring variables completed "

echo "======================================================================================================================="

curl https://drupalconsole.com/installer -L -o drupal.phar

php -r "readfile('https://drupalconsole.com/installer');" > drupal.phar

mv drupal.phar /usr/local/bin/drupal

chmod +x /usr/local/bin/drupal

mv /var/www/html /var/www/html.bak

cd /var/www

drupal site:new --repository="drupal/drupal" --directory="/var/www/html"

cp -arp html/sites/default/default.settings.php html/sites/default/settings.php

cd /var/www/html

composer require drupal/console:~1.0 --prefer-dist --optimize-autoloader --sort-packages

drupal self-update

chown centos:apache /var/www/html -R

chmod 2775 /var/www/html -R

drupal site:install  standard --langcode="en" --db-type="mysql" --db-host="127.0.0.1" --db-name="$NEWDBNAME" --db-user="$NEWDBUSER" --db-pass="$PASS" --db-port="3306" --db-prefix="" --site-name="Drupal 8 Site Install" --site-mail="support@easydeploy.cloud" --account-name="$username" --account-mail="support@catchpenguins.com" --account-pass="$adminpass"  --no-interaction

# Drupal Admin Credentials

touch /home/centos/DrupalAdmin.Credentials

echo account-name=$username > /home/centos/DrupalAdmin.Credentials

echo account-pass=$adminpass >> /home/centos/DrupalAdmin.Credentials

service httpd restart

echo "======================================================================================================================="

echo " YOU  HAVE  SUCCESSFULLY INSTALLED DRUPAL ON CENTOS 7 "

echo "======================================================================================================================="
