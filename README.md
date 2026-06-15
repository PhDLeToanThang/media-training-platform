# AVideo Platform 14.6 - Media Server Deployment

> **AVideo Platform** là nền tảng video streaming mã nguồn mở mạnh mẽ, cho phép bạn tự xây dựng hệ thống quản lý video, livestream, và quảng cáo giống như YouTube trên server riêng của mình.

## Giới thiệu

AVideo Platform là giải pháp toàn diện cho phép:

- **Quản lý Video**: Upload, encode, lưu trữ và phân phối video VOD (Video on Demand)
- **Livestream**: Phát trực tiếp với hỗ trợ RTMP + HLS, Adaptive Bitrates
- **Encoder**: Chuyển đổi video tự động sang nhiều định dạng và độ phân giải
- **Kiếm tiền**: Subscription, Pay-Per-View, quảng cáo VAST/VMAP
- **Bảo mật**: Encrypted HLS streaming, bảo vệ tải xuống, phân quyền người dùng
- **Đa nền tảng**: Xem trên Web, Mobile App, TV

### Kiến trúc hệ thống

```
                           WAN (Internet)
                               │
                     ┌─────────┴─────────┐
                     │   HAProxy 2.9     │  (tùy chọn)
                     │  Load Balancer    │
                     └─────────┬─────────┘
                               │
                     ┌─────────┴─────────┐
                     │    Ubuntu Server  │
                     │  ───────────────  │
                     │  80/443: Apache   │ ← AVideo website
                     │  1935:    Nginx   │ ← RTMP ingest
                     │  8080/8443:Nginx  │ ← HLS livestream
                     └───────────────────┘

 Apache 2.4      →  AVideo Streamer (PHP) + Encoder
 Nginx + RTMP    →  Live streaming (nhận RTMP, xuất HLS)
 MariaDB         →  Database
 FFmpeg          →  Encode video VOD
```

### Lưu ý về Dual Web Server

AVideo yêu cầu **Apache** làm web server chính. Script cài Apache trên 80/443 cho website, đồng thời compile Nginx riêng với module RTMP cho livestream (1935/8080/8443):

| Service | Port | Vai trò |
|---------|------|---------|
| Apache (systemd) | 80, 443 | Phục vụ website AVideo, xử lý PHP |
| Nginx RTMP (systemd) | 1935, 8080, 8443 | Nhận RTMP, phát HLS livestream |

Hai service độc lập, không xung đột port. Không được xóa Apache vì AVideo kiểm tra server software khi cài đặt.

## Yêu cầu hệ thống

### Phần cứng tối thiểu
| Thành phần | Yêu cầu |
|------------|---------|
| RAM | 4 GB (tối thiểu) / 16 GB (khuyến nghị) |
| CPU | 4 cores (tối thiểu) / 8 cores (khuyến nghị) |
| Disk | 120 GB SSD (tối thiểu) / 450 GB SSD (khuyến nghị) |
| Băng thông | 100 Mbps trở lên |

### Phần mềm
| Thành phần | Phiên bản |
|------------|-----------|
| OS | Ubuntu 20.04 hoặc 24.04 LTS |
| Web Server | Apache 2.4+ (bắt buộc), Nginx RTMP (livestream) |
| PHP | 8.3+ (libapache2-mod-php) |
| Database | MariaDB 10.11+ / MySQL 8.0+ |
| FFmpeg | 6.0+ |

### Ports cần mở
| Port | Giao thức | Mục đích |
|------|-----------|----------|
| 80 | TCP | Apache HTTP (website) |
| 443 | TCP | Apache HTTPS (website) |
| 8080 | TCP | Nginx RTMP HTTP (livestream) |
| 8443 | TCP | Nginx RTMP HTTPS (livestream) |
| 1935 | TCP | RTMP (livestream ingest) |
| 2053 | TCP | WebSockets |

## Cài đặt tự động (Automated Install)

> **Cảnh báo quan trọng**: Script phải chạy với **bash**, không phải sh. Nếu chạy `sudo ./setup_media_server_14.6.sh` mà hệ thống mặc định dùng `sh` (dash), bạn sẽ gặp lỗi `read: Illegal option -e`. Luôn dùng `sudo bash setup_media_server_14.6.sh`.

### 1. Chuẩn bị server Ubuntu 20.04 / 24.04 LTS

```bash
# SSH vào server
ssh root@your-server-ip

# Cập nhật hệ thống
apt-get update && apt-get upgrade -y

# Đảm bảo các công cụ cơ bản
apt-get install -y wget curl git
```

### 2. Chạy script cài đặt

```bash
# Tải script
wget -O setup_media_server_14.6.sh \
  https://raw.githubusercontent.com/PhDLeToanThang/media-training-platform/main/setup_media_server_14.6.sh

# Phân quyền
chmod +x setup_media_server_14.6.sh

# Chạy với quyền root (LUÔN dùng bash, không dùng sh)
sudo bash setup_media_server_14.6.sh
```

> **Lưu ý**: Phải dùng `bash` thay vì `sh` vì script sử dụng cú pháp Bash (`read -e`, `read -s`, mảng). Chạy bằng `sh` (dash) sẽ báo lỗi `Illegal option`.

Script sẽ yêu cầu nhập các thông số:
- **FQDN**: Tên miền (VD: demo.company.vn) — **cần trỏ DNS trước**
- **Database name**: Tên database (VD: cdndata)
- **Database user**: Tên user database (VD: userdata)
- **Database password**: Mật khẩu database
- **phpMyAdmin folder**: Tên thư mục phpMyAdmin (VD: phpmyadmin)
- **Email**: Email cho Let's Encrypt SSL

### 3. Sau khi cài đặt

1. Mở trình duyệt truy cập `https://<FQDN>`
2. Làm theo hướng dẫn web installer của AVideo
3. Nhập thông tin database đã tạo
4. Hoàn tất cấu hình Admin

### 4. Kiến trúc sau cài đặt

| Service | Port | Mục đích | Quản lý |
|---------|------|----------|---------|
| Apache | 80, 443 | Website AVideo | `systemctl [start\|stop\|reload] apache2` |
| Nginx RTMP | 1935, 8080, 8443 | Livestream | `systemctl [start\|stop\|restart] nginx-rtmp` |
| MariaDB | 3306 | Database | `systemctl [start\|stop\|restart] mariadb` |

> Apache và Nginx RTMP là 2 service riêng biệt, không can thiệp lẫn nhau.
> Nếu có **HAProxy** phía trước, xem mục hướng dẫn riêng bên dưới.

## Cài đặt thủ công (Manual Install)

> AVideo yêu cầu **Apache** làm web server chính. Nginx chỉ dùng cho livestream (RTMP).

### Step 1: Cài đặt Apache2

```bash
apt-get install -y apache2 libapache2-mod-php libapache2-mod-xsendfile
a2enmod rewrite
a2enmod xsendfile
systemctl enable apache2 && systemctl start apache2
```

### Step 2: Cài đặt MariaDB

```bash
apt-get install -y mariadb-server mariadb-client
systemctl enable mariadb && systemctl start mariadb
mysql_secure_installation
```

### Step 3: Cài đặt PHP 8.3

```bash
add-apt-repository -y ppa:ondrej/php
apt-get update
apt-get install -y libapache2-mod-php8.3 php8.3-common php8.3-mbstring \
  php8.3-xml php8.3-gd php8.3-intl php8.3-mysql php8.3-cli \
  php8.3-zip php8.3-curl php8.3-bcmath php8.3-soap php8.3-ldap php-ldap
```

### Step 4: Cài đặt FFmpeg & Tools

```bash
apt-get install -y ffmpeg libimage-exiftool-perl python3-pip
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
  -o /usr/local/bin/yt-dlp
chmod a+rx /usr/local/bin/yt-dlp
```

### Step 5: Tải AVideo

```bash
mkdir -p /var/www/demo.company.vn
cd /var/www/demo.company.vn
git clone https://github.com/WWBN/AVideo.git
git clone https://github.com/WWBN/AVideo-Encoder.git
chown -R www-data:www-data /var/www/demo.company.vn
```

### Step 6: Tạo database

```bash
mysql -u root -p
CREATE DATABASE avideo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'avideouser'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON avideo.* TO 'avideouser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Step 7: Cấu hình Apache VirtualHost

```bash
cat > /etc/apache2/sites-available/demo.company.vn.conf <<'EOF'
<VirtualHost *:80>
    DocumentRoot "/var/www/demo.company.vn/AVideo"
    ServerName demo.company.vn
    ErrorLog ${APACHE_LOG_DIR}/demo_error.log
    CustomLog ${APACHE_LOG_DIR}/demo_access.log combined
    <Directory "/var/www/demo.company.vn/AVideo/">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
a2ensite demo.company.vn.conf
systemctl reload apache2
```

### Step 8: Cài SSL Let's Encrypt

```bash
apt-get install -y certbot python3-certbot-apache
certbot --apache -d demo.company.vn --agree-tos --redirect --hsts
```

## HAProxy — Load Balancer / Reverse Proxy

Nếu có HAProxy đứng trước server AVideo, cấu hình như sau:

### Frontend mapping

```
Frontend    Port    →    Backend          Port VM
─────────────────────────────────────────────────
web         80      →    apache_backend   80
web         443     →    apache_backend   443
rtmp_ingest 1935    →    nginx_rtmp       1935
hls_http    8080    →    nginx_rtmp       8080
hls_https   8443    →    nginx_rtmp       8443
```

### Cấu hình HAProxy mẫu

```haproxy
global
    log /dev/log local0
    maxconn 4096

defaults
    log global
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

# ---- Website (Apache) ----
frontend web
    bind *:80
    bind *:443
    mode tcp
    default_backend apache_servers

backend apache_servers
    mode tcp
    server vm1 <IP_AVideo_VM>:80 check

# ---- Livestream RTMP ----
frontend rtmp
    bind *:1935
    mode tcp
    default_backend rtmp_servers

backend rtmp_servers
    mode tcp
    server vm1 <IP_AVideo_VM>:1935 check

# ---- Livestream HLS ----
frontend hls
    bind *:8080
    bind *:8443
    mode tcp
    default_backend hls_servers

backend hls_servers
    mode tcp
    server vm1 <IP_AVideo_VM]:8080 check
```

### SSL với HAProxy

**Option A — SSL termination tại HAProxy (khuyến nghị)**:
```haproxy
frontend web
    bind *:80
    bind *:443 ssl crt /etc/haproxy/certs/yourdomain.pem
    mode http
    http-request redirect scheme https unless { ssl_fc }
    default_backend apache_http

backend apache_http
    mode http
    server vm1 <IP_VM>:80 check
```
Khi đó backend Apache chạy HTTP (80), HAProxy quản lý SSL. Certbot chạy trên HAProxy, không phải VM.

**Option B — SSL passthrough (xuyên suốt)**:
```haproxy
frontend web
    bind *:443
    mode tcp
    default_backend apache_443

backend apache_443
    mode tcp
    server vm1 <IP_VM>:443 check
```
Certbot chạy trên VM Apache. HAProxy chỉ forward TCP.

### Let's Encrypt với HAProxy

- **Option A (http-01)**: HAProxy cần expose port 80 và forward ACME challenge. Thêm ACL:
  ```haproxy
  frontend web
      bind *:80
      mode http
      acl acme_challenge path_beg /.well-known/acme-challenge/
      use_backend acme_backend if acme_challenge
      default_backend apache_http

  backend acme_backend
      mode http
      server vm1 <IP_VM>:80
  ```
- **Option B (dns-01)**: Dùng certbot DNS plugin, HAProxy không cần can thiệp.
- **Option C**: Cấp chứng chỉ trên VM trước, copy cert lên HAProxy.

## Cấu hình nâng cao

### Tối ưu PHP

Với Apache + mod_php, sửa file `/etc/php/8.3/apache2/php.ini` (không phải `/etc/php/8.3/fpm/php.ini` — FPM không được dùng khi Apache dùng mod_php):

```ini
memory_limit = 1200M
upload_max_filesize = 4096M
post_max_size = 4096M
max_execution_time = 360
max_input_vars = 5000
```

### MariaDB Optimization

File cấu hình `/etc/mysql/mariadb.conf.d/99-avideo.cnf` (script tự động chọn theo OS):

**Ubuntu 24.04 (MariaDB 10.11+)**:
```ini
[mysqld]
max_allowed_packet = 128M
default-time-zone = +07:00
```

**Ubuntu 20.04 (MariaDB 10.3)** — thêm legacy InnoDB:
```ini
innodb_file_format = Barracuda
innodb_file_format_max = Barracuda
innodb_file_per_table = 1
innodb_large_prefix = ON
innodb_default_row_format = dynamic
```

### Apache Optimization

- **PHP module**: Dùng `mod_php` thay vì FPM (đã cài `libapache2-mod-php`)
- **Upload**: Mặc định Apache cho phép file lớn nếu PHP cấu hình đúng
- **Gzip**: `a2enmod deflate`
- **Cache**: `a2enmod expires`, `a2enmod headers`

### Bảo mật

1. **Firewall**: Chỉ mở các port cần thiết
   ```bash
   ufw allow 80,443,8080,8443,1935/tcp
   ufw enable
   ```

2. **Fail2ban**: Bảo vệ brute force
   ```bash
   apt-get install fail2ban
   ```

3. **Regular updates**:
   ```bash
   apt-get update && apt-get upgrade -y
   ```

## Troubleshooting

### 1. AVideo báo "You must install Apache" dù đã cài

Kiểm tra Apache đang chạy và là web server chính:
```bash
systemctl status apache2
curl -I http://localhost | grep Server
# Phải trả về: Server: Apache/2.4.xx
```
Nếu đang có Nginx chiếm port 80/443, dừng Nginx:
```bash
systemctl stop nginx 2>/dev/null || true
systemctl disable nginx 2>/dev/null || true
systemctl restart apache2
```

### 2. Lỗi "Unknown error" khi Install Now

Nguyên nhân thường do:
- Database sai thông tin
- PHP extension thiếu
- Permission sai trên thư mục cache/tmp

```bash
# Kiểm tra PHP extensions cần thiết
php -m | grep -E "mbstring|gd|mysql|curl|intl|zip|xml|openssl"

# Fix permissions
chown -R www-data:www-data /var/www/<FQDN>/
chmod 777 /var/www/<FQDN>/AVideo/vendor/ezyang/htmlpurifier/library/HTMLPurifier/DefinitionCache/Serializer
chmod 777 /var/www/tmp

# Xóa cache AVideo trước khi cài lại
rm -rf /var/www/<FQDN>/AVideo/videos/cache/*

# Kiểm tra Apache error log
tail -100 /var/log/apache2/<FQDN>_error.log
```

### 3. Lỗi "File upload too large"

Fix:
```bash
# PHP dùng mod_php (không phải FPM), sửa php.ini của Apache:
grep -E "upload_max_filesize|post_max_size|memory_limit" /etc/php/8.3/apache2/php.ini
sed -i 's/upload_max_filesize =.*/upload_max_filesize = 4096M/' /etc/php/8.3/apache2/php.ini
sed -i 's/post_max_size =.*/post_max_size = 4096M/' /etc/php/8.3/apache2/php.ini
systemctl restart apache2
```

### 4. Lỗi database connection

Kiểm tra:
```bash
mysql -u root -p -e "SHOW DATABASES;"
mysql -u avideouser -p -e "SHOW DATABASES;"
```

Fix:
```bash
# Reset quyền
mysql -u root -p
GRANT ALL PRIVILEGES ON avideo.* TO 'avideouser'@'localhost';
FLUSH PRIVILEGES;
```

### 5. Lỗi SSL / Certbot với HAProxy

**Nếu HAProxy đứng trước**: certbot trên VM cần port 80/443 forward từ HAProxy.

```bash
# Kiểm tra
certbot certificates
```

Fix — tạm thời expose VM trực tiếp để cấp chứng chỉ:
```bash
# Cách 1: Forward ACME từ HAProxy (xem mục HAProxy ở trên)
# Cách 2: Tắt HAProxy tạm thời, chạy certbot trực tiếp
sudo certbot --apache -d yourdomain.com
# Cách 3: Dùng DNS challenge (không cần port)
sudo certbot --apache -d yourdomain.com --preferred-challenges dns
```

### 6. Lỗi Nginx RTMP (Livestream) không hoạt động

Kiểm tra:
```bash
systemctl status nginx-rtmp
netstat -tlnp | grep -E "1935|8080|8443"
```

Fix:
```bash
systemctl restart nginx-rtmp
tail -f /usr/local/nginx/logs/error.log
```

**Nếu port 1935 bị firewall chặn** — mở trên HAProxy và VM:
```bash
# Trên VM
sudo ufw allow 1935/tcp
# Trên HAProxy — thêm frontend rtmp (xem mục HAProxy)
```

### 7. Lỗi "Allowed memory size exhausted"

Fix:
```bash
sed -i 's/memory_limit =.*/memory_limit = 2048M/' /etc/php/8.3/apache2/php.ini
systemctl restart apache2
```

### 8. Lỗi encode video chậm

Nguyên nhân: CPU yếu hoặc thiếu RAM.

Giải pháp:
- Nâng cấp CPU (khuyến nghị 8 cores+)
- Tăng RAM (khuyến nghị 16 GB+)
- Sử dụng Encoder riêng trên server khác
- Giới hạn số lượng resolutions encode trong plugin CustomizeAdvanced

### 9. Xem log lỗi

```bash
# Apache access log
tail -f /var/log/apache2/<FQDN>_access.log

# Apache error log
tail -f /var/log/apache2/<FQDN>_error.log

# Nginx RTMP log
tail -f /usr/local/nginx/logs/error.log

# AVideo system log
tail -f /var/www/<FQDN>/AVideo/videos/cache/log.log

# MySQL log
tail -f /var/log/mysql/error.log

# HAProxy log (nếu có)
tail -f /var/log/haproxy.log
```

## Backup & Restore

### Backup database
```bash
mysqldump -u root -p avideo > /backup/avideo_$(date +%Y%m%d).sql
```

### Backup files
```bash
tar -czf /backup/avideo_files_$(date +%Y%m%d).tar.gz /var/www/<FQDN>/AVideo/videos
```

### Restore
```bash
mysql -u root -p avideo < /backup/avideo_20240101.sql
tar -xzf /backup/avideo_files_20240101.tar.gz -C /var/www/<FQDN>/AVideo/
chown -R www-data:www-data /var/www/<FQDN>/AVideo/videos
```

## Upgrade AVideo

```bash
cd /var/www/<FQDN>/AVideo
sudo git pull
# Chạy web installer để update database
# Truy cập: https://yourdomain.com/update/update.php
```

## Tham khảo

- [AVideo GitHub](https://github.com/WWBN/AVideo)
- [AVideo Wiki](https://github.com/WWBN/AVideo/wiki)
- [AVideo Hardware Requirements](https://github.com/WWBN/AVideo/wiki/AVideo-Platform-Hardware-Requirements)
- [Ubuntu 24.04 Installation Guide](https://github.com/WWBN/AVideo/wiki/How-to-install-LAMP,-FFMPEG-and-Git-on-a-fresh-Ubuntu-24.x-for-AVideo-Platform)
- [Nginx RTMP Module](https://github.com/arut/nginx-rtmp-module)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)

## License

AVideo Platform is open-sourced under the [LICENSE](https://github.com/WWBN/AVideo/blob/master/LICENSE).

---

**Author**: PhDLeToanThang & AVideo Community  
**Platform**: [AVideo](https://github.com/WWBN/AVideo)  
**Support**: Hire expert at [streamphp.com](https://streamphp.com/marketplace/)
