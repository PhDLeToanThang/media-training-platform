#!/bin/bash
# =============================================================================
# AVideo Platform 14.3+ - Automated Deployment Script for Ubuntu 20.04/24.04 LTS
# =============================================================================
# This script installs and configures AVideo Platform (Streamer + Encoder + Live)
# on Ubuntu 20.04 or 24.04 LTS server with Nginx, MariaDB, PHP 8.3, and SSL.
#
# Source: https://github.com/WWBN/AVideo
# Author: Based on work by PhDLeToanThang & WWBN/AVideo community
# Updated: 2025
# =============================================================================

set -e  # Exit on error

# ---- Color output helpers ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---- Pre-flight check ----
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root (or with sudo)."
fi

OS_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
OS_CODENAME=$(lsb_release -cs 2>/dev/null || echo "unknown")

case "$OS_VERSION" in
    20.04|24.04)
        info "Detected Ubuntu $OS_VERSION ($OS_CODENAME) - supported"
        ;;
    *)
        warn "Detected Ubuntu $OS_VERSION. Script targets 20.04/24.04. Proceed with caution."
        ;;
esac

# ---- Detect pip break-system-packages support ----
PIP_BREAK=""
if pip3 install --help 2>/dev/null | grep -q break-system-packages; then
    PIP_BREAK="--break-system-packages"
fi

# =============================================================================
# INPUT CONFIGURATION
# =============================================================================
echo ""
info "============================================="
info "  AVideo Platform 14.3 - Ubuntu Setup        "
info "============================================="
echo ""

read -p "FQDN (e.g., demo.company.vn): " FQDN
read -p "Database name (e.g., cdndata): " dbname
read -p "Database user (e.g., userdata): " dbuser
read -s -p "Database password: " dbpass
echo ""
read -p "phpMyAdmin folder name (e.g., phpmyadmin): " phpmyadmin
read -p "CDN data folder name (e.g., cdndata): " FOLDERDATA
read -p "Email for Let's Encrypt SSL (e.g., admin@company.vn): " emailcertbot

# Derived paths
WEB_ROOT="/var/www/${FQDN}"
AVIADO_DIR="${WEB_ROOT}/AVideo"
ENCODER_DIR="${WEB_ROOT}/AVideo-encoder"
PHP_VERSION="8.3"

# Auto-generate MySQL root password
MYSQL_ROOT_PASS=$(openssl rand -base64 24)

info "Proceed with installation? (y/n)"
read -e run
if [ "$run" != "y" ]; then
    info "Installation cancelled."
    exit 0
fi

# =============================================================================
# STEP 1: System update & prerequisites
# =============================================================================
info "Step 1: Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# =============================================================================
# STEP 2: Install Nginx
# =============================================================================
info "Step 2: Installing Nginx..."
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx

# =============================================================================
# STEP 3: Install MariaDB
# =============================================================================
info "Step 3: Installing MariaDB..."
apt-get install -y mariadb-server mariadb-client

systemctl enable mariadb
systemctl start mariadb

# Secure MariaDB
info "Securing MariaDB..."
mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# Save MySQL root credentials
cat > /root/.my.cnf <<EOF
[client]
user=root
password=${MYSQL_ROOT_PASS}
EOF
chmod 600 /root/.my.cnf

info "MySQL root password saved to /root/.my.cnf"

# =============================================================================
# STEP 4: Install dependencies (FFmpeg, exiftool, etc.)
# =============================================================================
info "Step 4: Installing FFmpeg and media tools..."
apt-get install -y ffmpeg libimage-exiftool-perl python3-pip python3-dev unzip zip

# Install yt-dlp (modern youtube-dl replacement)
info "Installing yt-dlp..."
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
chmod a+rx /usr/local/bin/yt-dlp

# Also install youtube-dl for compatibility
curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
chmod a+rx /usr/local/bin/youtube-dl

# =============================================================================
# STEP 5: Install PHP 8.3 and extensions
# =============================================================================
info "Step 5: Installing PHP ${PHP_VERSION}..."
apt-get install -y software-properties-common
add-apt-repository -y ppa:ondrej/php
apt-get update -y

apt-get install -y \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-readline \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-ldap \
    php-ldap

# =============================================================================
# STEP 6: Configure PHP
# =============================================================================
info "Step 6: Configuring PHP..."

# Backup original php.ini
cp /etc/php/${PHP_VERSION}/fpm/php.ini /etc/php/${PHP_VERSION}/fpm/php.ini.bak

# Apply AVideo-optimized settings using sed (safer than overwriting entire file)
sed -i \
    -e 's/^file_uploads =.*/file_uploads = On/' \
    -e 's/^allow_url_fopen =.*/allow_url_fopen = On/' \
    -e 's/^memory_limit =.*/memory_limit = 1200M/' \
    -e 's/^upload_max_filesize =.*/upload_max_filesize = 4096M/' \
    -e 's/^max_execution_time =.*/max_execution_time = 360/' \
    -e 's/^max_input_time =.*/max_input_time = 60/' \
    -e 's/^post_max_size =.*/post_max_size = 4096M/' \
    -e 's/^max_input_vars =.*/max_input_vars = 5000/' \
    -e 's/^display_errors =.*/display_errors = Off/' \
    -e 's/^display_startup_errors =.*/display_startup_errors = Off/' \
    -e 's/^;date.timezone =.*/date.timezone = Asia\/Ho_Chi_Minh/' \
    /etc/php/${PHP_VERSION}/fpm/php.ini

systemctl restart php${PHP_VERSION}-fpm

# =============================================================================
# STEP 7: Configure MariaDB for AVideo
# =============================================================================
info "Step 7: Configuring MariaDB for AVideo..."

cat > /etc/mysql/mariadb.conf.d/99-avideo.cnf <<EOF
[mysqld]
max_allowed_packet = 128M
default-time-zone = +07:00
EOF

# Ubuntu 20.04 (MariaDB 10.3) needs legacy InnoDB settings
if [ "$OS_VERSION" = "20.04" ]; then
    cat >> /etc/mysql/mariadb.conf.d/99-avideo.cnf <<EOF
innodb_file_format = Barracuda
innodb_file_format_max = Barracuda
innodb_file_per_table = 1
innodb_large_prefix = ON
innodb_default_row_format = dynamic
EOF
fi

systemctl restart mariadb

# =============================================================================
# STEP 8: Create AVideo database and user
# =============================================================================
info "Step 8: Creating AVideo database..."

mysql -u root -p"${MYSQL_ROOT_PASS}" <<EOF
DROP DATABASE IF EXISTS \`${dbname}\`;
CREATE DATABASE \`${dbname}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${dbuser}'@'localhost' IDENTIFIED BY '${dbpass}';
GRANT ALL PRIVILEGES ON \`${dbname}\`.* TO '${dbuser}'@'localhost';
GRANT SELECT ON mysql.time_zone_name TO '${dbuser}'@'localhost';
FLUSH PRIVILEGES;
EOF

# =============================================================================
# STEP 9: Download AVideo (Streamer + Encoder)
# =============================================================================
info "Step 9: Downloading AVideo Platform..."

apt-get install -y git wget

mkdir -p "${WEB_ROOT}"

# Clone AVideo Streamer
if [ ! -d "${AVIADO_DIR}" ]; then
    git clone https://github.com/WWBN/AVideo.git "${AVIADO_DIR}"
else
    info "AVideo Streamer already exists, pulling updates..."
    cd "${AVIADO_DIR}" && git pull
fi

# Clone AVideo Encoder
if [ ! -d "${ENCODER_DIR}" ]; then
    git clone https://github.com/WWBN/AVideo-Encoder.git "${ENCODER_DIR}"
else
    info "AVideo Encoder already exists, pulling updates..."
    cd "${ENCODER_DIR}" && git pull
fi

# Set permissions
chown -R www-data:www-data "${WEB_ROOT}"
find "${WEB_ROOT}" -type d -exec chmod 755 {} \;
find "${WEB_ROOT}" -type f -exec chmod 644 {} \;

# Create tmp directory
mkdir -p /var/www/tmp
chmod 777 /var/www/tmp

# Create videos directory
mkdir -p "${WEB_ROOT}/videos"
chmod 755 "${WEB_ROOT}/videos"
chown www-data:www-data "${WEB_ROOT}/videos"

# Fix HTMLPurifier cache permissions
chmod 777 "${AVIADO_DIR}/vendor/ezyang/htmlpurifier/library/HTMLPurifier/DefinitionCache/Serializer" 2>/dev/null || true

# =============================================================================
# STEP 10: Configure Nginx virtual host
# =============================================================================
info "Step 10: Configuring Nginx for ${FQDN}..."

# Remove default site
rm -f /etc/nginx/sites-enabled/default

cat > "/etc/nginx/sites-available/${FQDN}" << 'NGINXEOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    root /var/www/html;
    index index.php index.html index.htm;

    charset utf-8;
    client_max_body_size 2G;

    access_log  /var/log/nginx/avideo.access.log;
    error_log   /var/log/nginx/avideo.error.log;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINXEOF

# Create config with actual FQDN
cat > "/etc/nginx/sites-available/${FQDN}" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${FQDN};
    root ${AVIADO_DIR};
    index index.php index.html index.htm;

    charset utf-8;
    client_max_body_size 2G;

    access_log  /var/log/nginx/avideo.access.log;
    error_log   /var/log/nginx/avideo.error.log;

    # PHP processing
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    # AVideo rewrite rules
    location / {
        rewrite ^/\$ /view/ last;
    }

    location /bootstrap {
        rewrite ^/bootstrap/(.+)\$ /view/bootstrap/\$1 last;
    }

    location /js {
        rewrite ^/js/(.+)\$ /view/js/\$1 last;
    }

    location /css {
        rewrite ^/css/(.+)\$ /view/css/\$1 last;
    }

    location /img {
        rewrite ^/img/(.+)\$ /view/img/\$1 last;
    }

    location /page {
        rewrite ^/page/([0-9]+)/?\$ /view/?page=\$1 last;
    }

    location /videoOnly {
        rewrite ^/videoOnly/?\$ /view/?type=video last;
    }

    location /audioOnly {
        rewrite ^/audioOnly/?\$ /view/?type=audio last;
    }

    location = /download {
        rewrite ^(.*)\$ /view/downloadExternalVideo.php last;
    }

    location = /downloadNow {
        rewrite ^(.*)\$ /objects/downloadVideo.php last;
    }

    location = /getDownloadProgress {
        rewrite ^(.*)\$ /objects/downloadVideoProgress.php last;
    }

    location = /about {
        rewrite ^(.*)\$ /view/about.php last;
    }

    location = /contact {
        rewrite ^(.*)\$ /view/contact.php last;
    }

    location = /sendEmail {
        rewrite ^(.*)\$ /objects/sendEmail.json.php last;
    }

    location = /captcha {
        rewrite ^(.*)\$ /objects/getCaptcha.php last;
    }

    location /monitor {
        rewrite ^/monitor/(.+)\$ /objects/ServerMonitor/\$1 last;
    }

    location /cat {
        rewrite ^/cat/([A-Za-z0-9-]+)/?\$ /view/?catName=\$1 last;
    }

    location /video {
        rewrite ^/video/([A-Za-z0-9-_.]+)/?\$ /view/?videoName=\$1 last;
    }

    location /videoEmbeded {
        rewrite ^/videoEmbeded/([A-Za-z0-9-_.]+)/?\$ /view/videoEmbeded.php?videoName=\$1 last;
    }

    location = /upload {
        rewrite ^(.*)\$ /view/mini-upload-form/ last;
    }

    location = /fileUpload {
        rewrite ^(.*)\$ /view/mini-upload-form/upload.php last;
    }

    location /uploadStatu {
        rewrite ^/uploadStatus /view/mini-upload-form/videoConversionStatus.php last;
    }

    location = /user {
        rewrite ^(.*)\$ /view/user.php last;
    }

    location = /users {
        rewrite ^(.*)\$ /view/managerUsers.php last;
    }

    location = /users.json {
        rewrite ^(.*)\$ /objects/users.json.php last;
    }

    location = /updateUser {
        rewrite ^(.*)\$ /objects/userUpdate.json.php last;
    }

    location = /savePhoto {
        rewrite ^(.*)\$ /objects/userSavePhoto.php last;
    }

    location = /addNewUser {
        rewrite ^(.*)\$ /objects/userAddNew.json.php last;
    }

    location = /deleteUser {
        rewrite ^(.*)\$ /objects/userDelete.json.php last;
    }

    location = /recoverPass {
        rewrite ^(.*)\$ /objects/userRecoverPass.php last;
    }

    location = /saveRecoverPassword {
        rewrite ^(.*)\$ /objects/userRecoverPassSave.json.php last;
    }

    location = /signUp {
        rewrite ^(.*)\$ /view/signUp.php last;
    }

    location = /createUser {
        rewrite ^(.*)\$ /objects/userCreate.json.php last;
    }

    location = /usersGroups {
        rewrite ^(.*)\$ /view/managerUsersGroups.php last;
    }

    location = /usersGroups.json {
        rewrite ^(.*)\$ /objects/usersGroups.json.php last;
    }

    location = /addNewUserGroups {
        rewrite ^(.*)\$ /objects/userGroupsAddNew.json.php last;
    }

    location = /deleteUserGroups {
        rewrite ^(.*)\$ /objects/userGroupsDelete.json.php last;
    }

    location = /ads {
        rewrite ^(.*)\$ /view/managerAds.php last;
    }

    location = /addNewAd {
        rewrite ^(.*)\$ /objects/video_adsAddNew.json.php last;
    }

    location = /ads.json {
        rewrite ^(.*)\$ /objects/video_ads.json.php last;
    }

    location = /deleteVideoAd {
        rewrite ^(.*)\$ /objects/video_adDelete.json.php last;
    }

    location /adClickLo {
        rewrite ^/adClickLog /objects/video_adClickLog.php last;
    }

    location = /categories {
        rewrite ^(.*)\$ /view/managerCategories.php last;
    }

    location = /categories.json {
        rewrite ^(.*)\$ /objects/categories.json.php last;
    }

    location = /addNewCategory {
        rewrite ^(.*)\$ /objects/categoryAddNew.json.php last;
    }

    location = /deleteCategory {
        rewrite ^(.*)\$ /objects/categoryDelete.json.php last;
    }

    location = /orphanFiles {
        rewrite ^(.*)\$ /view/orphanFiles.php last;
    }

    location = /mvideos {
        rewrite ^(.*)\$ /view/managerVideos.php last;
    }

    location = /videos.json {
        rewrite ^(.*)\$ /objects/videos.json.php last;
    }

    location = /deleteVideo {
        rewrite ^(.*)\$ /objects/videoDelete.json.php last;
    }

    location = /addNewVideo {
        rewrite ^(.*)\$ /objects/videoAddNew.json.php last;
    }

    location = /refreshVideo {
        rewrite ^(.*)\$ /objects/videoRefresh.json.php last;
    }

    location = /setStatusVideo {
        rewrite ^(.*)\$ /objects/videoStatus.json.php last;
    }

    location = /reencodeVideo {
        rewrite ^(.*)\$ /objects/videoReencode.json.php last;
    }

    location = /addViewCountVideo {
        rewrite ^(.*)\$ /objects/videoAddViewCount.json.php last;
    }

    location = /saveComment {
        rewrite ^(.*)\$ /objects/commentAddNew.json.php last;
    }

    location /comments {
        rewrite ^/comments.json/([0-9]+)\$ /objects/comments.json.php?video_id=\$1 last;
    }

    location = /login {
        rewrite ^(.*)\$ /objects/login.json.php last;
    }

    location = /logoff {
        rewrite ^(.*)\$ /objects/logoff.php last;
    }

    location = /like {
        rewrite ^(.*)\$ /objects/like.json.php?like=1 last;
    }

    location = /dislike {
        rewrite ^(.*)\$ /objects/like.json.php?like=-1 last;
    }

    location /update {
        rewrite ^/update/?\$ /update/update.php last;
    }

    location = /siteConfigurations {
        rewrite ^(.*)\$ /view/configurations.php last;
    }

    location = /updateConfig {
        rewrite ^(.*)\$ /objects/configurationUpdate.json.php last;
    }

    location = /charts {
        rewrite ^(.*)\$ /view/charts.php last;
    }

    # Encoder rewrite rules
    location = /upload/index.php {
        rewrite ^(.*)\$ /upload/view/index.php last;
    }

    location = /upload/isAdmin {
        rewrite ^(.*)\$ /upload/view/isAdmin.php last;
    }

    location = /upload/removeStreamer {
        rewrite ^(.*)\$ /upload/view/removeStreamer.php last;
    }

    location = /upload/priority {
        rewrite ^(.*)\$ /upload/view/priority.php last;
    }

    location = /upload/status {
        rewrite ^(.*)\$ /upload/view/status.php last;
    }

    location = /upload/serverStatus {
        rewrite ^(.*)\$ /upload/view/status.php?serverStatus=1 last;
    }

    location = /upload/upload {
        rewrite ^(.*)\$ /upload/view/upload.php last;
    }

    location = /upload/listFiles.json {
        rewrite ^(.*)\$ /upload/view/listFiles.json.php last;
    }

    location = /upload/deleteQueue {
        rewrite ^(.*)\$ /upload/view/deleteQueue.php last;
    }

    location = /upload/saveConfig {
        rewrite ^(.*)\$ /upload/view/saveConfig.php last;
    }

    location = /upload/youtubeDl.json {
        rewrite ^(.*)\$ /upload/view/youtubeDl.json.php last;
    }

    location = /upload/send.json {
        rewrite ^(.*)\$ /upload/view/send.json.php last;
    }

    location = /upload/streamers.json {
        rewrite ^(.*)\$ /upload/view/streamers.json.php last;
    }

    location = /upload/queue.json {
        rewrite ^(.*)\$ /upload/view/queue.json.php last;
    }

    location = /upload/queue {
        rewrite ^(.*)\$ /upload/view/queue.php last;
    }

    location = /upload/login {
        rewrite ^(.*)\$ /upload/objects/login.json.php last;
    }

    location = /upload/logoff {
        rewrite ^(.*)\$ /upload/objects/logoff.json.php last;
    }

    location /upload/ {
        rewrite "^/getImage/([A-Za-z0-9=/]+)/([A-Za-z0-9]{3})\$" /upload/objects/getImage.php?base64Url=\$1&format=\$2 last;
        rewrite "^/getImageMP4/([A-Za-z0-9=/]+)/([A-Za-z0-9]{3})/([0-9.]+)\$" /upload/objects/getImageMP4.php?base64Url=\$1&format=\$2&time=\$3 last;
    }

    location /upload/getSpiritsFromVideo {
        rewrite "^/getSpiritsFromVideo/([A-Za-z0-9=/]+)/([0-9]+)/([0-9]+)\$" /upload/objects/getSpiritsFromVideo.php?base64Url=\$1&tileWidth=\$2&totalClips=\$3 last;
    }

    location /upload/getLinkInfo {
        rewrite "^/getLinkInfo/([A-Za-z0-9=/]+)\$" /upload/objects/getLinkInfo.json.php?base64Url=\$1 last;
    }

    # Deny access to sensitive files
    location ~ /\.ht {
        deny all;
    }

    location = /configuration.php {
        deny all;
    }
}
EOF

# Enable the site
ln -sf "/etc/nginx/sites-available/${FQDN}" "/etc/nginx/sites-enabled/${FQDN}"

# Test config and reload
nginx -t && systemctl reload nginx

# =============================================================================
# STEP 11: Install phpMyAdmin (optional)
# =============================================================================
info "Step 11: Installing phpMyAdmin..."

# Pre-seed phpMyAdmin answers (non-interactive)
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password ${dbpass}"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password ${MYSQL_ROOT_PASS}"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password ${dbpass}"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none"

apt-get install -y phpmyadmin

# Create a symlink in the web root
ln -sf /usr/share/phpmyadmin "${AVIADO_DIR}/${phpmyadmin}"
chown -R root:root /var/lib/phpmyadmin

# =============================================================================
# STEP 12: Install Certbot (Let's Encrypt SSL)
# =============================================================================
info "Step 12: Installing Certbot for SSL..."

apt-get install -y certbot python3-certbot-nginx

# Obtain SSL certificate
info "Obtaining SSL certificate for ${FQDN}..."
certbot --nginx -d "${FQDN}" --email "${emailcertbot}" --agree-tos --redirect --hsts --non-interactive || {
    warn "Certbot failed. You can run it manually later: sudo certbot --nginx -d ${FQDN}"
}

# =============================================================================
# STEP 13: Setup crontab for maintenance
# =============================================================================
info "Step 13: Setting up maintenance cron jobs..."

cat > /etc/cron.d/avideo <<EOF
# Update yt-dlp daily
@daily root /usr/local/bin/yt-dlp --update > /dev/null 2>&1 || true

# Update youtube-dl daily
@daily root /usr/local/bin/youtube-dl -U > /dev/null 2>&1 || true

# Certbot renewal
0 3 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
EOF

chmod 644 /etc/cron.d/avideo

# =============================================================================
# STEP 14: Build Nginx RTMP module for Live Streaming
# =============================================================================
info "Step 14: Building Nginx with RTMP module for live streaming..."

apt-get install -y build-essential libpcre3 libpcre3-dev libssl-dev

BUILD_DIR=/root/build
mkdir -p "${BUILD_DIR}"

# Clone nginx-rtmp-module
if [ ! -d "${BUILD_DIR}/nginx-rtmp-module" ]; then
    git clone https://github.com/arut/nginx-rtmp-module.git "${BUILD_DIR}/nginx-rtmp-module"
fi

# Get nginx source matching current version
NGINX_VERSION=$(nginx -v 2>&1 | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
if [ -z "${NGINX_VERSION}" ]; then
    NGINX_VERSION="1.26.0"
fi

if [ ! -d "${BUILD_DIR}/nginx-${NGINX_VERSION}" ]; then
    cd "${BUILD_DIR}"
    wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
    tar xzf "nginx-${NGINX_VERSION}.tar.gz"
fi

# Build nginx with RTMP module
cd "${BUILD_DIR}/nginx-${NGINX_VERSION}"
./configure \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --add-module=../nginx-rtmp-module \
    --with-cc-opt="-Wimplicit-fallthrough=0"

make -j$(nproc)
make install

# Download stat.xsl for RTMP statistics
mkdir -p /usr/local/nginx/html
wget -q https://raw.githubusercontent.com/WWBN/AVideo/master/plugin/Live/install/stat.xsl \
    -O /usr/local/nginx/html/stat.xsl || true

# Install systemd service for Nginx RTMP
cat > /etc/systemd/system/nginx-rtmp.service <<EOF
[Unit]
Description=Nginx RTMP (AVideo Live Streaming)
After=network.target

[Service]
Type=forking
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Configure nginx.conf for RTMP
if [ -f /usr/local/nginx/conf/nginx.conf ]; then
    mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
fi
wget -q https://raw.githubusercontent.com/WWBN/AVideo/master/plugin/Live/install/nginx.conf \
    -O /usr/local/nginx/conf/nginx.conf || true

# Create HLS directories
mkdir -p /HLS/live /HLS/low
chmod 755 /HLS /HLS/live /HLS/low

# Replace listen port 443 with 8443 to avoid conflict with Nginx from apt
sed -i 's/listen 443 ssl/listen 8443 ssl/g' /usr/local/nginx/conf/nginx.conf 2>/dev/null || true

# Create symlink for nginx binary
mv /usr/sbin/nginx /usr/sbin/nginx.apt 2>/dev/null || true
cp /usr/local/nginx/sbin/nginx /usr/sbin/nginx

systemctl daemon-reload
systemctl enable nginx-rtmp

# =============================================================================
# STEP 15: Install Python monitoring tools
# =============================================================================
info "Step 15: Installing Python monitoring tools..."
pip3 install glances ${PIP_BREAK} 2>/dev/null || true
pip3 install vosk ${PIP_BREAK} 2>/dev/null || true
pip3 install youtube-dl ${PIP_BREAK} 2>/dev/null || true
pip3 install --upgrade youtube-dl ${PIP_BREAK} 2>/dev/null || true

# =============================================================================
# STEP 16: Final configuration
# =============================================================================
info "Step 16: Finalizing..."

# Add FQDN to /etc/hosts
if ! grep -q "${FQDN}" /etc/hosts; then
    echo "127.0.0.1 ${FQDN}" >> /etc/hosts
fi

# Restart all services
systemctl restart php${PHP_VERSION}-fpm
systemctl restart mariadb
systemctl reload nginx
systemctl start nginx-rtmp 2>/dev/null || true

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
info "============================================="
info "  AVideo Platform Installation Complete!"
info "============================================="
echo ""
info "Website:      https://${FQDN}"
info "AVideo Path:  ${AVIADO_DIR}"
info "Encoder Path: ${ENCODER_DIR}"
echo ""
info "Database:"
info "  Name:       ${dbname}"
info "  User:       ${dbuser}"
info "  Password:   ${dbpass}"
info "  Root Pass:  ${MYSQL_ROOT_PASS} (saved in /root/.my.cnf)"
echo ""
info "phpMyAdmin:   https://${FQDN}/${phpmyadmin}"
echo ""
info "Next steps:"
info "  1. Open https://${FQDN} in your browser"
info "  2. Follow the AVideo web installer"
info "  3. Database server: localhost"
info "  4. Database name:   ${dbname}"
info "  5. Database user:   ${dbuser}"
info "  6. Database password: ${dbpass}"
echo ""
info "Troubleshooting:"
info "  Nginx logs:        /var/log/nginx/avideo.*.log"
info "  PHP-FPM logs:      /var/log/php${PHP_VERSION}-fpm.log"
info "  Re-run certbot:    sudo certbot --nginx -d ${FQDN}"
echo ""
info "NOTE: Your MySQL root password is stored in /root/.my.cnf"
info "      Please save these credentials securely!"
echo ""
