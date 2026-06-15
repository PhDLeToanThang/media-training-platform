# Deploy Guide — AVideo Platform on Ubuntu 24.04 LTS

## Table of Contents

1. [Incident Summary — Why Clean Install](#1-incident-summary--why-clean-install)
2. [Prerequisites & Preparation](#2-prerequisites--preparation)
3. [Step-by-Step: Fresh Ubuntu 24.04 + AVideo](#3-step-by-step-fresh-ubuntu-2404--avideo)
4. [Restoring Backup after Installation](#4-restoring-backup-after-installation)
5. [Verification](#5-verification)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. Incident Summary — Why Clean Install

### Original Environment

| Item | Value |
|------|-------|
| Host | Hypervisor (VM) |
| OS | Ubuntu 20.04.6 LTS (Focal Fossa) |
| Disk | LVM on `vg0/lv-0` — 315 GB |
| Filesystem | EXT4 |
| Problem | **Corrupted EXT4**: orphaned inodes, block bitmap mismatch |

### Root Cause

`fsck -n` (read-only pass) confirmed:

```
Inodes that were part of a corrupted orphan linked list found.
Deleted inode 18612228 has zero dtime.
Block bitmap differences: -44073272
Inode bitmap differences: -823430 -11010742 -(18612228--18612231)
```

The LVM logical volume itself was intact, but the EXT4 layer was corrupted. `init 1` could force a writeable remount, but any subsequent `fsck` would refuse to run on a mounted root.

### Attempted Fixes

| Attempt | Result |
|---------|--------|
| `mount -o remount,rw /` | Failed — device write-protected |
| `dmseg` | journald "Read-only file system" spam |
| `lvs` | No snapshot — corruption was native |
| `init 1 + tune2fs -c 1` | Wrong device path, could not schedule |
| `touch /forcefsck` | Rejected — ROFS |

### Decision

> **Clean-install Ubuntu 24.04 LTS on a fresh disk instead of upgrading in-place.**

Reasons:

1. EXT4 corruption makes an in-place upgrade (20.04 → 24.04) **unreliable** — apt upgrades write thousands of files and risk further corruption mid-way.
2. The LVM+EXT4 layer complexity is not worth debugging on a production path.
3. The old server had no active users yet; data was backed up externally.
4. Ubuntu 24.04 delivers newer kernels, PHP 8.3 from the PPA without workarounds, and MariaDB 10.11 with better InnoDB defaults.

---

## 2. Prerequisites & Preparation

### 2.1 Hardware Minimums (AVideo)

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 4 GB | 16 GB |
| CPU | 4 cores | 8 cores |
| Disk | 120 GB SSD | 450 GB SSD |
| Bandwidth | 100 Mbps | 1 Gbps |

### 2.2 Software Versions

| Component | Version |
|-----------|---------|
| OS | Ubuntu 24.04 LTS (Noble Numbat) |
| Web Server | Nginx 1.24+ (from apt) |
| PHP | 8.3 (ondrej/php PPA) |
| Database | MariaDB 10.11+ |
| FFmpeg | 7.0+ |
| yt-dlp | Latest (via GitHub releases) |

### 2.3 Ports to Open on Firewall

```
80/tcp    HTTP
443/tcp   HTTPS
8080/tcp  Nginx HTTP (Live)
8443/tcp  Nginx HTTPS (Live)
1935/tcp  RTMP
2053/tcp  WebSockets
```

### 2.4 DNS

Before starting, point your domain's A record to the VM's public IP address:

```
yourdomain.com  A  <VM_IP>
```

---

## 3. Step-by-Step: Fresh Ubuntu 24.04 + AVideo

### 3.1 Install Ubuntu 24.04 LTS

1. Download ISO from [ubuntu.com/download/server](https://ubuntu.com/download/server)
2. Boot VM from ISO
3. During install:
   - Choose **"Use entire disk" (ext4)** — do NOT set up LVM unless you specifically need snapshots
   - Username: `thanglt` (or your preferred name)
   - Hostname: `yourschooltube` (matching your FQDN)
   - Install OpenSSH server when prompted
4. After first reboot, log in and update:
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo reboot
   ```

### 3.2 Upload & Prepare the Script

From your local Windows machine (PowerShell):

```powershell
scp C:\media.cloud.edu.vn\setup_media_server_14.6.sh thanglt@<VM_IP>:~/
```

From the VM (after SSH):

```bash
chmod +x ~/setup_media_server_14.6.sh
```

> **Tip**: If the script is hosted on GitHub, you can download it directly:
> ```bash
> wget -O setup_media_server_14.6.sh \
>   https://raw.githubusercontent.com/PhDLeToanThang/media-training-platform/main/setup_media_server_14.6.sh
> chmod +x setup_media_server_14.6.sh
> ```

### 3.3 Run the Script

```bash
sudo ./setup_media_server_14.6.sh
```

The script will prompt for:

| Prompt | Example Value | Notes |
|--------|---------------|-------|
| FQDN | `yourschooltube.com` | Must match DNS A record |
| Database name | `cdndata` | Will be created automatically |
| Database user | `userdata` | Will be created automatically |
| Database password | `P@$$w0rd-1.22` | Use strong password |
| phpMyAdmin folder | `phpmyadmin` | Will be symlinked |
| CDN data folder | `cdndata` | Storage directory name |
| Email (SSL) | `thang@company.vn` | For Let's Encrypt |

### 3.4 What the Script Does (14 Steps)

| Step | Action |
|------|--------|
| 1 | apt update/upgrade |
| 2 | Install Nginx 1.24+ |
| 3 | Install MariaDB 10.11+ |
| 4 | Install FFmpeg, ExifTool, yt-dlp, python3 |
| 5 | Add ondrej/php PPA, install PHP 8.3 + extensions |
| 6 | Tune php.ini (memory, upload size, timeouts) |
| 7 | Configure MariaDB (max_allowed_packet, timezone) |
| 8 | Create database + user for AVideo |
| 9 | Git clone AVideo + AVideo-Encoder to `/var/www/<FQDN>/` |
| 10 | Write Nginx virtual host with all AVideo rewrite rules |
| 11 | Install phpMyAdmin (pre-seeded, non-interactive) |
| 12 | Install Certbot, obtain Let's Encrypt SSL |
| 13 | Cron jobs: update yt-dlp, renew cert |
| 14 | Build Nginx from source with RTMP module for live streaming |
| 15 | Install Python monitoring tools (glances, vosk) |
| 16 | Print summary with credentials |

### 3.5 Expected Runtime

- **Total**: ~20–40 minutes depending on network speed and CPU
- **Longest steps**: PHP PPA (ondrej/php), git clone, Nginx + RTMP compilation

### 3.6 After Script Completes

The script prints a summary. Key information to note:

```
Website:      https://yourschooltube.com
AVideo Path:  /var/www/yourschooltube.com/AVideo
Encoder Path: /var/www/yourschooltube.com/AVideo-encoder

Database:
  Name:       cdndata
  User:       userdata
  Password:   P@$$w0rd-1.22
  Root Pass:  <random>   (saved in /root/.my.cnf)

phpMyAdmin:   https://yourschooltube.com/phpmyadmin
```

---

## 4. Restoring Backup after Installation

### 4.1 Restore Database

```bash
# Copy backup from remote PC to VM (from local Windows)
scp /backup/avideo_mysql.sql thanglt@<VM_IP>:~/

# On the VM, restore
mysql -u root -p"$(grep password /root/.my.cnf | cut -d= -f2)" < ~/avideo_mysql.sql
```

### 4.2 Restore Video Files

```bash
# Copy backup tarball
scp /backup/avideo_files.tar.gz thanglt@<VM_IP>:~/

# On the VM
tar -xzf ~/avideo_files.tar.gz -C /var/www/yourschooltube.com/
chown -R www-data:www-data /var/www/yourschooltube.com/videos
chmod 755 /var/www/yourschooltube.com/videos
```

### 4.3 Restore AVideo Configuration

```bash
# If you backed up configuration.php
# cp /backup/configuration.php /var/www/yourschooltube.com/AVideo/
# chown www-data:www-data /var/www/yourschooltube.com/AVideo/configuration.php
```

Then visit `https://yourschooltube.com` and the web installer should detect existing database.

---

## 5. Verification

### 5.1 Services Running

```bash
systemctl status nginx          # Should show active (running)
systemctl status mariadb        # Should show active (running)
systemctl status php8.3-fpm     # Should show active (running)
systemctl status nginx-rtmp     # Optional, for live streaming
```

### 5.2 PHP Configuration

```bash
php -v                          # Should show PHP 8.3.x
php -m | grep -E "mbstring|gd|mysql|curl|intl|zip|xml"
# All should be present
```

### 5.3 Nginx Configuration

```bash
nginx -t                        # Should show: syntax is ok / test is successful
```

### 5.4 Database

```bash
mysql -u root -p -e "SHOW DATABASES;"
# Should show your database name (e.g., cdndata)
```

### 5.5 Web Access

```bash
curl -I https://yourschooltube.com
# Should return: HTTP/2 200 (after redirect to HTTPS)
```

### 5.6 SSL Certificate

```bash
certbot certificates
# Should show your domain with valid expiry date
```

---

## 6. Troubleshooting

### 6.1 "502 Bad Gateway"

**Cause**: PHP-FPM not running or socket wrong.

```bash
sudo systemctl restart php8.3-fpm
sudo systemctl reload nginx
```

### 6.2 "413 Request Entity Too Large"

**Cause**: Upload size exceeded.

```bash
# Already set by script, but verify:
grep -E "upload_max_filesize|post_max_size" /etc/php/8.3/fpm/php.ini
sudo systemctl restart php8.3-fpm
```

### 6.3 "Could not connect to database"

**Cause**: Credentials mismatch in AVideo web installer. Verify:

```bash
mysql -u userdata -p -e "SHOW DATABASES;"
# Enter password when prompted
```

### 6.4 Certbot SSL Failed

```bash
# Ensure port 80 is open on firewall and DNS resolves to this server
sudo ufw status
sudo certbot --nginx -d yourschooltube.com
```

### 6.5 Live Stream Not Working

```bash
# Check RTMP port
sudo netstat -tlnp | grep 1935
# Restart RTMP server
sudo systemctl restart nginx-rtmp
# Check logs
sudo tail -f /usr/local/nginx/logs/error.log
```

### 6.6 Video Encoding Stuck

- Insufficient RAM (videos need ~2× file size in free RAM)
- Check disk space: `df -h`
- Check encoder queue: `https://yourschooltube.com/upload/queue`

### 6.7 Disk Full

```bash
du -sh /var/www/yourschooltube.com/videos/
# Move old videos to external storage or S3
```

---

## Appendix A: Filesystem Differences: 20.04 vs 24.04

| Item | Ubuntu 20.04 | Ubuntu 24.04 |
|------|-------------|-------------|
| Kernel | 5.4.x | 6.8.x |
| Python | 3.8 | 3.12 |
| MariaDB | 10.3 | 10.11 |
| FFmpeg | 4.2.x | 7.0.x |
| PHP default | 7.4 | 8.3 |
| Nginx | 1.18 | 1.24 |
| OpenSSL | 1.1.1 | 3.0.x |

## Appendix B: Script Architecture

```
setup_media_server_14.6.sh
├── OS Detection (20.04 / 24.04 auto-adapt)
├── Input prompts (FQDN, DB creds, SSL email)
├── Step 1:  System updates
├── Step 2:  Nginx (apt)
├── Step 3:  MariaDB (apt + mysql_secure)
├── Step 4:  FFmpeg + yt-dlp + exiftool
├── Step 5:  PHP 8.3 (ondrej/php PPA)
├── Step 6:  PHP config tuning (sed)
├── Step 7:  MariaDB InnoDB tuning
├── Step 8:  Database + user creation
├── Step 9:  Git clone AVideo + Encoder
├── Step 10: Nginx vhost + rewrite rules
├── Step 11: phpMyAdmin (pre-seeded)
├── Step 12: Certbot SSL (Let's Encrypt)
├── Step 13: Cron: yt-dlp update + cert renew
├── Step 14: Build Nginx + RTMP from source
├── Step 15: Python monitoring (glances, vosk)
└── Step 16: Summary output
```

## Appendix C: Quick Commands Reference

```bash
# Service management
sudo systemctl restart nginx          # Web server
sudo systemctl restart php8.3-fpm     # PHP
sudo systemctl restart mariadb        # Database
sudo systemctl restart nginx-rtmp     # Live streaming

# Logs
sudo tail -f /var/log/nginx/avideo.access.log
sudo tail -f /var/log/nginx/avideo.error.log
sudo tail -f /var/log/php8.3-fpm.log

# Backup
mysqldump --all-databases > /backup/db_$(date +%Y%m%d).sql
tar -czf /backup/www_$(date +%Y%m%d).tar.gz /var/www/

# Update AVideo
cd /var/www/yourschooltube.com/AVideo && sudo git pull

# Renew SSL
sudo certbot renew
```

---

**Document version**: 1.0  
**Last updated**: 2026-06-15  
**Author**: PhDLeToanThang  
**Project**: [media-training-platform](https://github.com/PhDLeToanThang/media-training-platform)
