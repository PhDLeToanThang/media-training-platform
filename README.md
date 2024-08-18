# media-training-platform
media video/audio/talk-book/fonos/ interactive simulator from video training the platform

It is designed to make web-scaleble storage.
ie with this service you will have unlimited storage capacity and low cost.

For example when one of your storage is full, just plug in one more storage and your videos will continue to be saved to the new storage.

This service is designed to replace our current S3, BackBlaze B2 and FTP plugins, but with much more integration with our services, besides you will have no restriction on the amount of storages used.

You can install as many storage nodes as you want, without any geographical restrictions.

Benefits
Storage scales as needed
Minimal start up investment and cost
Uses the bandwidth of the storage
Facilitates your server load balancing on the amount of the used bandwidth
Can speed up delivery based on location of each video
Please check this scenario to try to make the propose of this project clear:

https://github.com/WWBN/AVideo-Storage/wiki/AVideo-Platform-Storage-Scenario-Description

Installation
You will need the folowing prerequisites.

We made a video Installing YPTStorage and configuring the YPTStorage plugin

What we use for that:
PHP 7+
Apache XSendFile
YPTStorage Plugin
AVideo 7.3+
What will you need
Root Access to the server
Admin user for AVideo

```u16.04
Ubuntu 16.04
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install nano curl apache2 php7.0 libapache2-mod-php7.0 php7.0-curl php7.0-gd php7.0-intl php-zip php-xml php-mbstring git -y && a2enmod headers && service apache2 restart && cd /var/www/html && git clone https://github.com/WWBN/AVideo-Storage.git && sudo a2enmod rewrite && sudo mkdir /var/www/html/AVideo-Storage/videos && sudo chown www-data:www-data /var/www/html/AVideo-Storage/videos
```

```u18.04
Ubuntu 18.04
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install nano curl apache2 php7.2 libapache2-mod-php7.2 php7.2-curl php7.2-gd php7.2-intl php-xml php-mbstring git -y && a2enmod headers && service apache2 restart && cd /var/www/html && sudo git clone https://github.com/WWBN/AVideo-Storage.git && sudo a2enmod rewrite && sudo mkdir /var/www/html/AVideo-Storage/videos && sudo chown www-data:www-data /var/www/html/AVideo-Storage/videos
```

```u20.04
Ubuntu 20.04
sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install nano curl apache2 php7.4 libapache2-mod-php7.4 php7.4-curl php7.4-gd php7.4-intl php-xml php-mbstring git -y && a2enmod headers && service apache2 restart && cd /var/www/html && sudo git clone https://github.com/WWBN/AVideo-Storage.git && sudo a2enmod rewrite && sudo mkdir /var/www/html/AVideo-Storage/videos && sudo chown www-data:www-data /var/www/html/AVideo-Storage/videos
```

Install apache xsendfile
sudo apt-get install libapache2-mod-xsendfile && sudo a2enmod xsendfile

Configure your apache XSendFile
sudo nano /etc/apache2/apache2.conf

<Directory /var/www/html/AVideo-Storage/>
    Options Indexes FollowSymLinks
    XSendFile on
    XSendFilePath /var/www/html/AVideo-Storage/
    AllowOverride All
    Require all granted
    Order Allow,Deny
    Allow from All
</Directory>

Enable YPTStorage Plugin
Make sure you enable it before your installation, this is necessary because the Storage installation will check your plugin during the configuration assistant

If you do not have the plugin yet, get it here

Access your storage server
On the first access you will be requested for your streamer address. the installation script will try to create your videos directory and your configuration.php file. If any of those fail you will need to create it manually.

The script will create a Storage site for you on your streamer site, but this site will be inactive, you will need to activate it (On the YPTStorage plugin) before proceed.
