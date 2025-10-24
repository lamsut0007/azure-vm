#!/bin/bash
set -e

# Update system packages
sudo dnf -y update
sudo dnf config-manager --set-enabled crb
sudo dnf install -y epel-release
sudo dnf install -y dnf-utils https://rpms.remirepo.net/enterprise/remi-release-9.rpm

# Enable Remi repo for PHP 8.3 (8.3.26 currently)
sudo dnf module reset -y php
sudo dnf module enable -y php:remi-8.3

# Install Apache 2.4.6 + PHP 8.3 core
sudo dnf install -y httpd mod_ssl php php-cli php-common php-fpm php-pdo php-opcache unzip curl git

# Install PHP 8.3 and extensions
sudo dnf install -y \
  php-bcmath php-bz2 php-calendar php-curl php-exif php-fileinfo php-filter \
  php-ftp php-gd php-gettext php-iconv php-intl php-mbstring php-mysqli \
  php-pcntl php-pdo_mysql php-pdo_pgsql php-pdo_sqlite php-pgsql php-posix \
  php-shmop php-simplexml php-sockets php-sysvmsg php-sysvsem php-sysvshm \
  php-xml php-xmlreader php-xmlwriter php-zip

# Install Composer (globally)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
sudo rm -f composer-setup.php

# Install development libraries
sudo dnf install -y \
  bzip2-devel libxml2-devel libpng-devel libjpeg-turbo-devel freetype-devel \
  oniguruma-devel libzip-devel libicu-devel postgresql-devel libxslt-devel \
  libmemcached-devel openssl-devel zlib-devel sqlite-devel \
  libcurl-devel readline-devel gmp-devel aspell-devel libedit-devel \
  tidy-devel pkgconf-pkg-config

# Enable and start Apache
sudo systemctl enable httpd
sudo systemctl start httpd

# Set up project directory
sudo mkdir -p /var/www/html/${project_name}
sudo chown -R apache:apache /var/www/html/${project_name}

# Add Crontab entry for Apache to auto-run socket at reboot
sudo tee /usr/local/bin/socket_restart.sh > /dev/null <<EOF
#!/bin/bash
set -e
cd /var/www/html/${project_name}
php socket/run.php stop || true
php socket/run.php start -d
EOF

sudo chown apache:apache /usr/local/bin/socket_restart.sh
sudo chmod +x /usr/local/bin/socket_restart.sh

sudo bash -c 'echo "@reboot /usr/local/bin/socket_restart.sh >> /var/log/socket_restart.log 2>&1" | crontab -u apache -'

# Install PostgreSQL 17 client (17.6 currently)
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql17