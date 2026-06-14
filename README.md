# AVideo Platform 14.3 - Media Server Deployment

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
┌──────────────────────────────────────────────────────┐
│               AVideo Platform Server                 │
├─────────────────┬──────────────────┬─────────────────┤
│   Streamer      │    Encoder       │   Live Server   │
│   (Nginx + PHP) │   (PHP + FFmpeg) │ (Nginx + RTMP)  │
│                 │                  │                 │
│   - Play video  │   - Encode VOD   │  - RTMP ingest  │
│   - Quản lý user│   - Convert      │  - HLS output   │
│   - Monetization│   - Thumbnail    │  - Adaptive Bit │
│   - API         │   - Metadata     │  - Record       │
└─────────────────┴──────────────────┴─────────────────┘
```

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
| OS | Ubuntu 24.04 LTS (khuyến nghị) |
| Web Server | Nginx 1.24+ |
| PHP | 8.3+ |
| Database | MariaDB 10.11+ / MySQL 8.0+ |
| FFmpeg | 6.0+ |

### Ports cần mở
| Port | Giao thức | Mục đích |
|------|-----------|----------|
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |
| 8080 | TCP | Nginx HTTP (Streamer) |
| 8443 | TCP | Nginx HTTPS (Live) |
| 1935 | TCP | RTMP (Livestream) |
| 2053 | TCP | WebSockets |

## Cài đặt tự động (Automated Install)

### 1. Chuẩn bị server Ubuntu 24.04 LTS

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
wget -O deploy_media_server_14.3.sh \
  https://raw.githubusercontent.com/PhDLeToanThang/media-training-platform/main/deploy_media_server_14.3.sh

# Phân quyền
chmod +x deploy_media_server_14.3.sh

# Chạy với quyền root
sudo ./deploy_media_server_14.3.sh
```

Script sẽ yêu cầu nhập các thông số:
- **FQDN**: Tên miền (VD: demo.company.vn) - **cần trỏ DNS trước**
- **Database name**: Tên database (VD: cdndata)
- **Database user**: Tên user database (VD: userdata)
- **Database password**: Mật khẩu database
- **phpMyAdmin folder**: Tên thư mục phpMyAdmin (VD: phpmyadmin)
- **CDN Data folder**: Thư mục dữ liệu CDN
- **Email**: Email cho Let's Encrypt SSL

### 3. Sau khi cài đặt

1. Mở trình duyệt truy cập `https://<FQDN>`
2. Làm theo hướng dẫn web installer của AVideo
3. Nhập thông tin database đã tạo
4. Hoàn tất cấu hình Admin

## Cài đặt thủ công (Manual Install)

### Step 1: Cài đặt Nginx

```bash
apt-get install -y nginx
systemctl enable nginx && systemctl start nginx
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
apt-get install -y php8.3-fpm php8.3-common php8.3-mbstring \
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

### Step 7: Cấu hình Nginx

Tham khảo file config mẫu trong thư mục `nginx/` hoặc xem hướng dẫn chi tiết tại [AVideo Wiki - Nginx Config](https://github.com/WWBN/AVideo/wiki)

### Step 8: Cài SSL Let's Encrypt

```bash
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d demo.company.vn --agree-tos --redirect --hsts
```

## Cấu hình nâng cao

### Tối ưu PHP

Các thông số PHP tối ưu cho AVideo trong `/etc/php/8.3/fpm/php.ini`:

```ini
memory_limit = 1200M
upload_max_filesize = 4096M
post_max_size = 4096M
max_execution_time = 360
max_input_vars = 5000
```

### MariaDB Optimization

File cấu hình `/etc/mysql/mariadb.conf.d/99-avideo.cnf`:

```ini
[mysqld]
innodb_file_format = Barracuda
innodb_file_per_table = 1
innodb_large_prefix = ON
max_allowed_packet = 128M
innodb_default_row_format = dynamic
default-time-zone = +07:00
```

### Nginx Optimization

- `client_max_body_size 2G;` - Cho phép upload file lớn
- `fastcgi_read_timeout 600;` - Timeout cho encode video
- Enable Gzip compression
- Cấu hình cache cho static files

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

### 1. Lỗi "502 Bad Gateway"

**Nguyên nhân**: PHP-FPM không chạy hoặc socket sai.

**Kiểm tra**:
```bash
systemctl status php8.3-fpm
# Kiểm tra socket tồn tại
ls -la /run/php/php8.3-fpm.sock
```

**Fix**:
```bash
systemctl restart php8.3-fpm
systemctl reload nginx
```

### 2. Lỗi "File upload too large"

**Fix**:
```bash
# Kiểm tra các giá trị trong php.ini
grep -E "upload_max_filesize|post_max_size|memory_limit" /etc/php/8.3/fpm/php.ini
# Sửa nếu cần
sed -i 's/upload_max_filesize =.*/upload_max_filesize = 4096M/' /etc/php/8.3/fpm/php.ini
sed -i 's/post_max_size =.*/post_max_size = 4096M/' /etc/php/8.3/fpm/php.ini
systemctl restart php8.3-fpm
```

### 3. Lỗi database connection

**Kiểm tra**:
```bash
mysql -u root -p -e "SHOW DATABASES;"
mysql -u avideouser -p -e "SHOW DATABASES;"
```

**Fix**:
```bash
# Reset quyền
mysql -u root -p
GRANT ALL PRIVILEGES ON avideo.* TO 'avideouser'@'localhost';
FLUSH PRIVILEGES;
```

### 4. Lỗi SSL / Certbot

**Kiểm tra**:
```bash
certbot certificates
```

**Fix**:
```bash
certbot renew --dry-run
# Hoặc cài mới
certbot --nginx -d yourdomain.com
```

### 5. Lỗi Livestream không hoạt động

**Kiểm tra**:
```bash
systemctl status nginx-rtmp
# Kiểm tra port RTMP
netstat -tlnp | grep 1935
```

**Fix**:
```bash
systemctl restart nginx-rtmp
# Xem log
tail -f /usr/local/nginx/logs/error.log
```

### 6. Lỗi "Allowed memory size exhausted"

**Fix**: Tăng memory_limit trong php.ini lên 2048M hoặc cao hơn.

```bash
sed -i 's/memory_limit =.*/memory_limit = 2048M/' /etc/php/8.3/fpm/php.ini
systemctl restart php8.3-fpm
```

### 7. Lỗi encode video chậm

**Nguyên nhân**: CPU yếu hoặc thiếu RAM.

**Giải pháp**:
- Nâng cấp CPU (khuyến nghị 8 cores+)
- Tăng RAM (khuyến nghị 16 GB+)
- Sử dụng Encoder riêng trên server khác
- Giới hạn số lượng resolutions encode trong plugin CustomizeAdvanced

### 8. Xem log lỗi

```bash
# Nginx access log
tail -f /var/log/nginx/avideo.access.log

# Nginx error log
tail -f /var/log/nginx/avideo.error.log

# PHP-FPM log
tail -f /var/log/php8.3-fpm.log

# AVideo system log
tail -f /var/www/html/AVideo/videos/cache/log.log

# MySQL log
tail -f /var/log/mysql/error.log
```

## Backup & Restore

### Backup database
```bash
mysqldump -u root -p avideo > /backup/avideo_$(date +%Y%m%d).sql
```

### Backup files
```bash
tar -czf /backup/avideo_files_$(date +%Y%m%d).tar.gz /var/www/html/AVideo/videos
```

### Restore
```bash
mysql -u root -p avideo < /backup/avideo_20240101.sql
tar -xzf /backup/avideo_files_20240101.tar.gz -C /
```

## Upgrade AVideo

```bash
cd /var/www/html/AVideo
git pull
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
