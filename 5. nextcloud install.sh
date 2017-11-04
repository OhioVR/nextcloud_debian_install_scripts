#!/bin/sh
#install a real desktop
sudo tasksel install xfce-desktop
#install k4dirstat which works similar to treesize
sudo apt-get install k4dirstat


###############################################################################
## This script will install NextCloud on Debian 9 as follows:                ##
## php-fpm using unixsocket and own fpm pool for isolation                   ##
## Apache2 using MPM Event (should be a least as fast as nginx)              ##
## APCu for memory local cache                                               ##
## Redis on unixsocket for memory locking cache                              ##
## SSL using Lets Encrypt with secure TLS defaluts. A+ Rating                ##
## ModSecurity for real-time monitoring, logging, and access control         ##
##                                                                           ##
## By Erik Adler aka onryo erik.adler@mensa.se                               ##
## gpg --keyserver pgp.mit.edu --recv-keys 0x2B4B58FE                        ##
###############################################################################

#this script was found at https://help.nextcloud.com/t/script-100-auto-install-on-debian-9-apache-mpm-event-php-fpm-socket-redis-socket-apcu-letsencrypt-ssl-a-modsecurity/22054

#slightly modified by Scott Yannitell to enter names instead of hard coding them in the script-100
#but no biggie



clear
clear
# login user name. Change this!
read -p "enter your user name: " nc_user
#nc_user='ENTERYOURNAME'

clear
clear
# login user password. Change this!
read -p "enter your user password: " nc_pw
#nc_pw='ENTERYOURPASSWORD'

clear
clear
# Enter your domain name for nextcloud ie dingdong.com
read -p "enter your domain name: " domainname
#domainname='ENTERYOURDOMAINNAME'

clear
clear
# email for vhost and cert.
read -p "enter your email address for vhost and cert: " email
#email='email@example.com'

# Change to version of NextCloud to download if not latest.
# latest.tar.bz2 is default
nextcloudVersion='latest.tar.bz2'

# Public gpg key used to verify NextCloud
# The key can be found at https://nextcloud.com/nextcloud.asc
# D75899B9A724937A is default
gpgKey='D75899B9A724937A'

# Path to NextCloud. Feel free to change this.
nc_home='/var/www/vhosts'

# Defaut is a random 32 char pw for NextCloud db admin user.
# A backup can be found under /root/admin_pw_backup.txt if needed.
db_admin_pw="$(tr -cd '[:alnum:]' < /dev/urandom | fold -w32 | head -n1)"

###############################################################################


[ "$(id -u)" = 0 ] || { printf 'Must be root to run script\n'; exit 1; }

hostName="$(hostname)"

apt-get update -y && sudo apt-get upgrade -y

# Apache2 and php7.0-fpm stuff
apt-get install apache2 -y
apt-get install php7.0-fpm php7.0-gd php7.0-json php7.0-mysql php7.0-curl -y
apt-get install php7.0-intl php7.0-mcrypt php7.0-imagick php7.0-xml -y
apt-get install php7.0-gmp php7.0-smbclient php7.0-ldap php7.0-imap -y
apt-get install php7.0-mbstring php7.0-bz2 php7.0-zip  -y

a2enmod proxy_fcgi setenvif
a2enconf php7.0-fpm
systemctl reload apache2

# Media functions and preview.
apt-get install ffmpeg libreoffice -y

# Setup database
apt-get install mariadb-server -y

mysql -e "CREATE DATABASE nextclouddb;"
mysql -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '$db_admin_pw';"
mysql -e "GRANT ALL PRIVILEGES ON nextclouddb.* TO 'nextcloud'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"
mysql -e "quit"

# If for some reason you feel you need a NC pw backup. Only system root can read this.
echo "$db_admin_pw" > /root/admin_pw_backup.txt
chmod 400 /root/admin_pw_backup.txt

## By default starting with Debian 9 mariadb does not store a root
## password in the database. If your db gets owned there is no root user hash
## that can be cracked. root management is now via unixsocket by the system.
## A huge security increase! Renders SQLi -> hash cracking -> ownage obsolete.
## You can see here:  SELECT User, Host, password, plugin from mysql.user;
## For more info see https://goo.gl/14PsfB

# mysql_secure_installation. Keeping default unixsocket pw management.
apt-get install expect -y

secure_mysql=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$MYSQL\\r\"
expect \"Change the root password?\"
send \"n\\r\"
expect \"Remove anonymous users?\"
send \"y\\r\"
expect \"Disallow root login remotely?\"
send \"y\\r\"
expect \"Remove test database and access to it?\"
send \"y\\r\"
expect \"Reload privilege tables now?\"
send \"y\\r\"
expect eof
")

echo "$secure_mysql"
apt-get remove --purge expect -y


# Set up a php-fpm pool with a unixsocket
cat >/etc/php/7.0/fpm/pool.d/nextcloud.conf<<EOF
[Next Cloud]
user = www-data
group = www-data
listen = /run/php/php7.0-fpm.nextcloud.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 3
pm.min_spare_servers = 2
pm.max_spare_servers = 4
pm.max_requests = 200
env[HOSTNAME] = $hostName
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
security.limit_extensions = .php
php_admin_value [cgi.fix_pathinfo] = 1
EOF

# Disable the idling example pool.
mv /etc/php/7.0/fpm/pool.d/www.conf /etc/php/7.0/fpm/pool.d/www.conf.backup

# Get NextCloud and verify the gpg signature. Change to the exact nc version
cd /tmp || { printf 'There is no /tmp dir\n'; exit 1; }
apt-get install dirmngr sudo -y
gpg --recv-keys "$gpgKey" || gpg --keyserver pgp.mit.edu "$gpgKey"
wget "https://download.nextcloud.com/server/releases/$nextcloudVersion"
wget "https://download.nextcloud.com/server/releases/$nextcloudVersion.asc"

gpg --verify "$nextcloudVersion.asc" "$nextcloudVersion" 2>&1 | grep  \
    'Good signature' || { printf 'BAD GPG SIGNATURE\n'; exit 1; }

tar xjfv "$nextcloudVersion"
mkdir -p "$nc_home"
mv nextcloud "$nc_home/"
chown -R www-data:www-data "$nc_home/nextcloud"

# Sets up the vhost
cat >/etc/apache2/sites-available/nextcloud.conf<<EOF
<VirtualHost *:80>
    ServerAdmin "$email"
    DocumentRoot "$nc_home/nextcloud"
    ServerName "$domainname"
    <Directory "$nc_home/nextcloud/">
        AllowOverride All
        Options -Indexes +FollowSymlinks
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        SetEnv HOME "$nc_home/nextcloud"
        SetEnv HTTP_HOME "$nc_home/nextcloud"
    </Directory>
    <Directory "$nc_home/nextcloud/data/">
        Require all denied
    </Directory>
    <FilesMatch \\.php$>
        SetHandler "proxy:unix:/run/php/php7.0-fpm.nextcloud.sock|fcgi://localhost"
    </FilesMatch>
</virtualhost>
EOF

a2dissite 000-default
a2ensite nextcloud

systemctl reload apache2
systemctl reload php7.0-fpm.service

# Install NextCloud
cd "$nc_home/nextcloud/" || { printf 'No nextcloud dir\n'; exit 1; }

# root uses sudo -u to allow very arcain password strings.
sudo -u www-data php "$nc_home/nextcloud/occ"  maintenance:install \
    --database 'mysql' --database-name 'nextclouddb' --database-user 'nextcloud' \
    --database-pass "$db_admin_pw" --admin-user "$nc_user" --admin-pass "$nc_pw"

su -m www-data php -c "php $nc_home/nextcloud/occ config:system:set \
    trusted_domains 0 --value=$domainname"

# Enable all previews
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enable_previews --value=true --type=boolean"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 0 --value='OC\\Preview\\PNG'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 1 --value='OC\\Preview\\JPEG'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 2 --value='OC\\Preview\\GIF'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 3 --value='OC\\Preview\\BMP'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 4 --value='OC\\Preview\\XBitmap'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 5 --value='OC\\Preview\\MarkDown'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 6 --value='OC\\Preview\\MP3'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 7 --value='OC\\Preview\\TXT'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 8 --value='OC\\Preview\\Illustrator'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 9 --value='OC\\Preview\\Movie'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 10 --value='OC\\Preview\\MSOffice2003'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 11 --value='OC\\Preview\\MSOffice2007'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 12 --value='OC\\Preview\\MSOfficeDoc'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 13 --value='OC\\Preview\\OpenDocument'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 14 --value='OC\\Preview\\PDF'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 15 --value='OC\\Preview\\Photoshop'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 16 --value='OC\\Preview\\Postscript'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 17 --value='OC\\Preview\\StarOffice'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 18 --value='OC\\Preview\\SVG'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 19 --value='OC\\Preview\\TIFF'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
  enabledPreviewProviders 20 --value='OC\\Preview\\Font'"

## APCu for local  memory cache
apt-get install php7.0-apcu -y
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
    memcache.local --value='\\OC\\Memcache\\APCu'"

##  Redis for distributed caching on unixsocket
apt-get install php7.0-redis redis-server -y

## Generate pw for redis connection
redis_pw="$(tr -cd '[:alnum:]' < /dev/urandom | fold -w32 | head -n1)"

sed -i "s/# requirepass foobared/requirepass ${redis_pw}/g" /etc/redis/redis.conf
sed -i 's/port 6379/port 0/g' /etc/redis/redis.conf
sed -i 's/# unixsocket/unixsocket/g' /etc/redis/redis.conf
sed -i 's/unixsocketperm 700/unixsocketperm 770/g' /etc/redis/redis.conf

usermod -a -G redis www-data
chown -R redis:www-data /var/run/redis

systemctl reload apache2
systemctl reload php7.0-fpm.service
systemctl enable redis-server
systemctl start redis-server

su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
    memcache.locking --value='\\OC\\Memcache\\Redis'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
    filelocking.enabled --value='true' --type=boolean"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
    redis host --value='/var/run/redis/redis.sock'"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
    redis port --value='0' --type=integer"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
    redis timeout --value='0' --type=integer"
su -m www-data -c "php $nc_home/nextcloud/occ config:system:set \
    redis password --value=$redis_pw"

systemctl restart redis-server.service

# Secure with https://www.modsecurity.org/about.html
# ModSecurity is a toolkit for real-time web application monitoring, logging, and access control.
# Default is to detect only but you can enable security to be active.

apt-get install libapache2-mod-security2  modsecurity-crs -y
mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
# whitelist to get started https://paste.debian.net/989100/
cd /etc/modsecurity || { printf 'No modsecurity dir\n'; exit 1; }
wget https://paste.debian.net/plain/989100
mv 989100 whitelist.conf
# Do not enable the next line unless you know what you are doing. This will enable active defence.
# sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine on/g' /etc/modsecurity/modsecurity.conf
# You can monitor tail -f /var/log/apache2/modsec_audit.log
systemctl reload apache2


echo "type yes to activate SSL (don't type yes if you are developing and worried about burning out your certificates..)"
read activate
if [ $activate = yes ]
then
## Setup SSL using Lets Encrypt
apt-get install python-certbot-apache -y

certbot --apache --rsa-key-size 4096 --must-staple --hsts --uir --staple-ocsp \
  --strict-permissions --email "$email" --agree-tos --redirect -d "$domainname"

# Auto renew cert
crontab -l > certbot
echo '0 0 * * 0 /usr/bin/certbot renew' >> certbot
crontab certbot
rm certbot
fi
