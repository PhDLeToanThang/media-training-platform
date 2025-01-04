# D:\Documents\GitHub\media-training-platform\deploy_media_server_14.3.sh    Avideo Platform VERSION 14.3  updated: 02/1/2025
# Code Deploy Media server On-premise:
# Install Avideo 14.3 on Ubuntu 24.04.06 LTS linux server OS:
# Avideo Platform is a powerful open source Video service management (Your Tube media) software tool designed/ Upload/ LiveStreaming to help you plan and easily manage your media content or Advance or Ad operations.
# This is source code deploy for Multi-user limit time for more functionalities video fun, happy easlisy, Ad in the TV/Desk.
#!/bin/bash

############### Tham số cần thay đổi ở đây ###################
echo "FQDN: e.g: demo.company.vn"   # Đổi địa chỉ web thứ nhất Website Master for Resource code - để tạo cùng 1 Source code duy nhất 
read -e FQDN
echo "dbname: e.g: cdndata"   # Tên DBNane
read -e dbname
echo "dbuser: e.g: userdata"   # Tên User access DB lmsatcuser
read -e dbuser
echo "Database Password: e.g: P@$$w0rd-1.22"
read -s dbpass
echo "phpmyadmin folder name: e.g: phpmyadmin"   # Đổi tên thư mục phpmyadmin khi add link symbol vào Website 
read -e phpmyadmin
echo "CDN Folder Data: e.g: cdndata"   # Tên Thư mục chưa Data vs Cache
read -e FOLDERDATA
echo "dbtype name: e.g: mariadb"   # Tên kiểu Database
read -e dbtype
echo "dbhost name: e.g: localhost"   # Tên Db host connector
read -e dbhost
echo "Your Email address fro Certbot e.g: thang@company.vn" # Địa chỉ email của bạn để quản lý CA
read -e emailcertbot

AVideo="14.3"

echo "run install? (y/n)"
read -e run
if [ "$run" == n ] ; then
  exit
else

#Step 1. Install NGINX
sudo apt-get update -y
sudo apt-get install nginx -y
sudo systemctl stop nginx.service 
sudo systemctl start nginx.service 
sudo systemctl enable nginx.service

#Step 2. Install MariaDB/MySQL
#Run the following commands to install MariaDB database for Moode. You may also use MySQL instead.
sudo apt-get install mariadb-server mariadb-client -y

#Like NGINX, we will run the following commands to enable MariaDB to autostart during reboot, and also start now.
sudo systemctl stop mysql.service 
sudo systemctl start mysql.service 
sudo systemctl enable mysql.service

#Run the following command to secure MariaDB installation.
#password mysql mariadb , i'm fixed: M@tKh@uS3cr3t  --> you must changit. 

sudo mysql_secure_installation  <<EOF
n
M@tKh@uS3cr3t
M@tKh@uS3cr3t
y
n
y
y
EOF

#You will see the following prompts asking to allow/disallow different type of logins. Enter Y as shown.
# Enter current password for root (enter for none): Just press the Enter
# Set root password? [Y/n]: Y
# New password: Enter password
# Re-enter new password: Repeat password
# Remove anonymous users? [Y/n]: Y
# Disallow root login remotely? [Y/n]: N
# Remove test database and access to it? [Y/n]:  Y
# Reload privilege tables now? [Y/n]:  Y
# After you enter response for these questions, your MariaDB installation will be secured.

# Step 3. Install Dependencies
#AVideo uses FFmpeg to encode videos. We can easily install FFmpeg from the default Ubuntu repository.

sudo apt install ffmpeg -y
#To read and write meta information in multimedia files, we need to install the libimage-exiftool-perl package.
sudo apt install libimage-exiftool-perl -y

#Step 4. Install PHP-FPM & Related modules
sudo apt-get install software-properties-common -y
sudo -S add-apt-repository ppa:ondrej/php -y
sudo apt update -y
sudo apt install php8.3-fpm php8.3-common php8.3-json php8.3-opcache php8.3-readline php-ldap php8.3-mbstring php8.3-xmlrpc php8.3-soap php8.3-gd php8.3-xml php8.3-intl php8.3-mysql php8.3-cli php8.3-mcrypt php8.3-ldap php8.3-zip php8.3-curl -y

#Step 5. Open PHP-FPM config file.
#sudo nano /etc/php/8.3/fpm/php.ini
#Add/Update the values as shown. You may change it as per your requirement.
# if new php.ini configure then clear sign sharp # comment
cat > /etc/php/8.3/fpm/php.ini <<END
[PHP]
engine = On
short_open_tag = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = -1
disable_functions = 
disable_classes =
zend.enable_gc = On
zend.exception_ignore_args = On
zend.exception_string_param_max_len = 0
expose_php = Off
file_uploads = On 
allow_url_fopen = On 
memory_limit = 1200M 
upload_max_filesize = 4096M
max_execution_time = 360 
cgi.fix_pathinfo = 0 
max_input_time = 60
max_input_nesting_level = 64
max_input_vars = 5000
post_max_size = 4096M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
extension=bz2
extension=curl
;extension=ffi
;extension=ftp
extension=fileinfo
;extension=gd
;extension=gettext
;extension=gmp
extension=intl
;extension=imap
extension=php_ldap.so
extension=mbstring
;extension=exif      ; Must be after mbstring as it depends on it
;extension=mysqli
;extension=oci8_12c  ; Use with Oracle Database 12c Instant Client
;extension=oci8_19  ; Use with Oracle Database 19 Instant Client
;extension=odbc
extension=openssl
;extension=pdo_firebird
;extension=pdo_mysql
;extension=pdo_oci
;extension=pdo_odbc
;extension=pdo_pgsql
;extension=pdo_sqlite
;extension=pgsql
;extension=shmop
;extension=snmp
;extension=soap
;extension=sockets
;extension=sodium
;extension=sqlite3
;extension=tidy
;extension=xsl
;zend_extension=opcache
[CLI Server]
cli_server.color = On

[Date]
date.timezone=Asia/Ho_Chi_Minh

; https://php.net/date.default-latitude
;date.default_latitude = 31.7667

; https://php.net/date.default-longitude
;date.default_longitude = 35.2333


[filter]

[iconv]

[imap]

[intl]

[sqlite3]

[Pcre]

[Pdo]

[Pdo_mysql]
pdo_mysql.default_socket=

[Phar]

[mail function]
SMTP = localhost
; https://php.net/smtp-port
smtp_port = 25
;sendmail_from = me@example.com
;sendmail_path =
;mail.force_extra_parameters =
mail.add_x_header = Off
;mail.log = syslog

[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1

[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off

[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off

[OCI8]

[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0

[bcmath]
bcmath.scale = 0

[browscap]

[Session]
session.save_handler = files
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly = on
session.cookie_secure = on
session.cookie_samesite = Lax
session.serialize_handler = php
session.gc_probability = 0
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.sid_length = 26
session.trans_sid_tags = "a=href,area=href,frame=src,form="
session.sid_bits_per_character = 5

[Assertion]
zend.assertions = -1

[COM]

[mbstring]

[gd]

[exif]

[Tidy]
tidy.clean_output = Off

[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5

[sysvshm]

[ldap]
ldap.max_links = -1

[dba]

[opcache]

[curl]

[openssl]

[ffi]
END

systemctl restart php8.3-fpm.service

#Step 6. To fetch videos from other sites, we need to install YouTube-DL. 
#Though it’s included in the Ubuntu repository, but it’s outdated.
#We will install YouTube-DL from the Python Package Index, which always contains the latest version of YouTube-DL.
sudo apt install python3-pip -y
sudo -H pip3 install youtube-dl 
#It’s very important that you use the latest version, or you might not be able to download videos from other sites. We can create a Cron job to automatically check and install the latest version.
sudo crontab -e
#Add the following line at the end of the Crontab file to try upgrading YouTube-DL daily.
#   @daily sudo -H pip3 install --upgrade youtube-dl > /dev/null 

# Nếu đã có thì bỏ qua đoạn hàm này như thế nào ?
#Step 7. Next, edit the MariaDB default configuration file and define the innodb_file_format:
#nano /etc/mysql/mariadb.conf.d/50-server.cnf
#Add the following lines inside the [mysqld] section: 
# if new php.ini configure then clear sign sharp # comment
cat > /etc/mysql/mariadb.conf.d/50-server.cnf <<END
[mysqld]
innodb_file_format = Barracuda
innodb_file_format_max = Barracuda
innodb_file_per_table = 1
innodb_large_prefix = ON
innodb_file_per_table = ON
max_allowed_packet=128M
innodb_default_row_format = dynamic

[server]
default-time-zone=+7:00

END

#Save the file then restart the MariaDB service to apply the changes.
systemctl restart mariadb

#Step 8. Create AVideo Database
#Log into MySQL and create database for AVideo.
# install tool mysql-workbench-community from Tonin Bolzan (tonybolzan)
sudo snap install mysql-workbench-community

mysql -uroot -prootpassword -e "DROP DATABASE IF EXISTS ${dbname};"
mysql -uroot -prootpassword -e "CREATE DATABASE IF NOT EXISTS ${dbname} CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
mysql -uroot -prootpassword -e "CREATE USER IF NOT EXISTS '${dbuser}'@'${dbhost}' IDENTIFIED BY "${dbpass}";"
mysql -uroot -prootpassword -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${dbuser}'@'${dbhost}';"
mysql -uroot -prootpassword -e "GRANT SELECT ON mysql.time_zone_name TO '${dbuser}'@'${dbhost}';"
mysql -uroot -prootpassword -e "FLUSH PRIVILEGES;"
mysql -uroot -prootpassword -e "SHOW DATABASES;"
mysql -uroot -prootpassword -e "EXIT;"


#Step 9. Download & Install AVideo
#We will be using Git to install/update the AVideo Core Application 
sudo apt install git -y

cd /opt
sudo apt-get -y install wget
#Run the following command to download Avideo package.
#Download the Media Avideo Code and Index 

sudo git clone https://github.com/WWBN/AVideo.git
#Change directory into the downloaded Avideo folder
#Uncompress the downloaded the archive:

cd AVideo/
sudo git clone https://github.com/WWBN/AVideo-Encoder.git

sudo mv AVideo-Encoder upload

#Run the following command to extract package to NGINX website root folder.
sudo chown www-data:www-data /var/www/AVideo/ -R

#Step 10: Finish host config
cat > /etc/hosts <<END
127.0.0.1 $FQDN
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
END



#Step 11. Configure NGINX
#Them dong lenh xoa noi dung cau hinh trong file conf truoc khi dien thong tin chuan moi:
cat > /etc/nginx/conf.d/${FQDN}.conf <<END
END
#Next, you will need to create an Nginx virtual host configuration file to host Avideo:
#$ nano /etc/nginx/conf.d/$FQDN.conf
echo 'server {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '      80;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '      [::]:80;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    server_name '${FQDN}';'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    root /var/www/${FQDN}';'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    index index.php index.html index.htm;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    charset utf-8;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    client_max_body_size 2G;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    access_log  /var/log/nginx/avideo.access.log;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    error_log   /var/log/nginx/avideo.error.log;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location ~ \.php$ {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    fastcgi_split_path_info ^(.+\.php)(/.+)$;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    fastcgi_pass unix:/run/php/php8.3-fpm.sock;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    fastcgi_index index.php;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    include fastcgi_params;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    # translating Apache rewrite rules in the .htaccess file to Nginx rewrite rules'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location / {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/$ /view/ last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /bootstrap {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/bootstrap/(.+)$ /view/bootstrap/$1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /js {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/js/(.+)$ /view/js/$1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /css {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/css/(.+)$ /view/css/$1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /img {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/img/(.+)$ /view/img/$1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /page {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/page/([0-9]+)/?$ /view/?page=$1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /videoOnly {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/videoOnly/?$ /view/?type=video last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /audioOnly {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/audioOnly/?$ /view/?type=audio last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /download {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/downloadExternalVideo.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /downloadNow {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/downloadVideo.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /getDownloadProgress {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/downloadVideoProgress.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /about {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/about.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /contact {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/contact.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /sendEmail {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/sendEmail.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /captcha {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/getCaptcha.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /monitor {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/monitor/(.+)$ /objects/ServerMonitor/$1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /cat {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/cat/([A-Za-z0-9-]+)/?$ /view/?catName=$1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /video {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/video/([A-Za-z0-9-_.]+)/?$ /view/?videoName=$1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /videoEmbeded {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/videoEmbeded/([A-Za-z0-9-_.]+)/?$ /view/videoEmbeded.php?videoName=$1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /upload {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/mini-upload-form/ last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /fileUpload {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/mini-upload-form/upload.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /uploadStatu {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/uploadStatus /view/mini-upload-form/videoConversionStatus.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /user {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/user.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /users {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/managerUsers.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /users.json {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/users.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /updateUser {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/userUpdate.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /savePhoto {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/userSavePhoto.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /addNewUser {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/userAddNew.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /deleteUser {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/userDelete.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /recoverPass {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/userRecoverPass.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /saveRecoverPassword {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/userRecoverPassSave.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /signUp {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/signUp.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /createUser {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/userCreate.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /usersGroups {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/managerUsersGroups.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /usersGroups.json {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/usersGroups.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /addNewUserGroups {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/userGroupsAddNew.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /deleteUserGroups {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/userGroupsDelete.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /ads {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/managerAds.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /addNewAd {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/video_adsAddNew.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /ads.json {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/video_ads.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /deleteVideoAd {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/video_adDelete.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /adClickLo {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/adClickLog /objects/video_adClickLog.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /categories {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/managerCategories.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /categories.json {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/categories.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /addNewCategory {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/categoryAddNew.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /deleteCategory {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/categoryDelete.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /orphanFiles {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/orphanFiles.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /mvideos {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '     rewrite ^(.*)$ /view/managerVideos.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /videos.json {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/videos.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /deleteVideo {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/videoDelete.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /addNewVideo {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/videoAddNew.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /refreshVideo {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/videoRefresh.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /setStatusVideo {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/videoStatus.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /reencodeVideo {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/videoReencode.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /addViewCountVideo {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/videoAddViewCount.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /saveComment {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/commentAddNew.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /comments {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/comments.json/([0-9]+)$ /objects/comments.json.php?video_id=$1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /login {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/login.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /logoff {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/logoff.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /like {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/like.json.php?like=1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /dislike {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/like.json.php?like=-1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location /update {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/update/?$ /update/update.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /siteConfigurations {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/configurations.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /updateConfig {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /objects/configurationUpdate.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /charts {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /view/charts.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /upload/index.php {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '       rewrite ^(.*)$ /upload/view/index.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    location = /upload/isAdmin {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '      rewrite ^(.*)$ /upload/view/isAdmin.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '   }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '   location = /upload/removeStreamer {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '     rewrite ^(.*)$ /upload/view/removeStreamer.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '   }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/priority {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '     rewrite ^(.*)$ /upload/view/priority.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/status {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '     rewrite ^(.*)$ /upload/view/status.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/serverStatus {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /upload/view/status.php?serverStatus=1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/upload {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /upload/view/upload.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/listFiles.json {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '   rewrite ^(.*)$ /upload/view/listFiles.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/deleteQueue {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /upload/view/deleteQueue.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/saveConfig {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /upload/view/saveConfig.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/youtubeDl.json {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /upload/view/youtubeDl.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/send.json {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /upload/view/send.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/streamers.json {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /upload/view/streamers.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/queue.json {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /upload/view/queue.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/queue {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /upload/view/queue.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/login {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /upload/objects/login.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location = /upload/logoff {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^(.*)$ /upload/objects/logoff.json.php last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location /upload/ {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite "^/getImage/([A-Za-z0-9=/]+)/([A-Za-z0-9]{3})$" /upload/objects/getImage.php?base64Url=$1&format=$2 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite "^/getImageMP4/([A-Za-z0-9=/]+)/([A-Za-z0-9]{3})/([0-9.]+)$" /upload/objects/getImageMP4.php?base64Url=$1&format=$2&time=$3 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location /upload/getSpiritsFromVideo {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/getSpiritsFromVideo/([A-Za-z0-9=/]+)/([0-9]+)/([0-9]+)$ /upload/objects/getSpiritsFromVideo.php?base64Url=$1&tileWidth=$2&totalClips=$3  last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  location /upload/getLinkInfo {'  >> /etc/nginx/conf.d/$FQDN.conf
echo '    rewrite ^/getLinkInfo/([A-Za-z0-9=/]+)$ /upload/objects/getLinkInfo.json.php?base64Url=$1 last;'  >> /etc/nginx/conf.d/$FQDN.conf
echo '  }'  >> /etc/nginx/conf.d/$FQDN.conf
echo '}'  >> /etc/nginx/conf.d/$FQDN.conf

#Save and close the file then verify the Nginx for any syntax error with the following command: 
nginx -t
sudo systemctl reload nginx

#Step 12. Setup and Configure PhpMyAdmin
sudo apt update -y
sudo apt install phpmyadmin -y

#Step 13. gỡ bỏ apache:
sudo service apache2 stop
sudo apt-get purge apache2 apache2-utils apache2.2-bin apache2-common
sudo apt-get purge apache2 apache2-utils apache2-bin apache2.2-common

sudo apt-get autoremove
whereis apache2
apache2: /etc/apache2
sudo rm -rf /etc/apache2

sudo ln -s /usr/share/phpmyadmin /var/www/html/$FQDN/$phpmyadmin
sudo chown -R root:root /var/lib/phpmyadmin
sudo nginx -t

#Step 14. Nâng cấp PhpmyAdmin lên version 5.2.1:
sudo mv /usr/share/phpmyadmin/ /usr/share/phpmyadmin.bak
sudo mkdir /usr/share/phpmyadmin/
cd /usr/share/phpmyadmin/
sudo wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz
sudo tar xzf phpMyAdmin-5.2.1-all-languages.tar.gz
#Once extracted, list folder.
ls
#You should see a new folder phpMyAdmin-5.2.1-all-languages
#We want to move the contents of this folder to /usr/share/phpmyadmin
sudo mv phpMyAdmin-5.2.1-all-languages/* /usr/share/phpmyadmin
ls /usr/share/phpmyadmin
mkdir /usr/share/phpMyAdmin/tmp   # tạo thư mục cache cho phpmyadmin 

sudo systemctl restart nginx
systemctl restart php8.3-fpm.service

#Step 15. Install Certbot enabling HTTPS
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d $FQDN --email $emailcertbot --agree-tos --redirect --hsts

# You should test your configuration at:
# https://www.ssllabs.com/ssltest/analyze.html?d=$FQDN
#/etc/letsencrypt/live/$FQDN/fullchain.pem
#   Your key file has been saved at:
#   /etc/letsencrypt/live/$FQDN/privkey.pem
#   Your cert will expire on yyyy-mm-dd. To obtain a new or tweaked
#   version of this certificate in the future, simply run certbot again
#   with the "certonly" option. To non-interactively renew *all* of
#   your certificates, run "certbot renew"
fi
