#!/bin/bash

# Check if the script is being run as root, if not, run as root
if [[ "$(id -u)" -ne 0 ]]; then
    sudo -E "$0" "$@"
    exit
fi

# Update the system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
apt-get update
apt-get install apache2 -y
apt-get install mysql-server -y

# Install PHP 8.1 and necessary modules
apt-get install libapache2-mod-php8.1 php8.1 php8.1-common php8.1-xml php8.1-mysql php8.1-gd php8.1-mbstring php8.1-tokenizer php8.1-bcmath php8.1-curl php8.1-zip unzip -y

# Configure PHP
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/8.1/apache2/php.ini

# Enable and start the services
systemctl enable apache2
systemctl enable mysql
systemctl start apache2
systemctl start mysql

# Install Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configure Apache to host Laravel application
cat > /etc/apache2/sites-available/laravel.conf <<EOF
<VirtualHost *:80>
  ServerAdmin obafemitoluwanimi@gmail.com
  ServerName 192.168.56.8
  DocumentRoot /var/www/html/laravel/public

  <Directory /var/www/html/laravel>
    Options Indexes MultiViews FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>

  ErrorLog \${APACHE_LOG_DIR}/error.log
  CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Enable Apache rewrite module
a2enmod rewrite

# Activate Laravel virtual host
a2ensite laravel.conf

# Enable PHP module on Apache
a2enmod php8.1

# Reload Apache
systemctl reload apache2

# Navigate to the web directory
cd /var/www/html || exit

# Clone Laravel application to the server
git clone https://github.com/laravel/laravel.git

# Navigate into the Laravel directory
cd laravel || exit

# Run Composer
composer install --no-dev --optimize-autoloader --no-interaction

# Set permissions for Laravel directories
chown -R www-data:www-data /var/www/html/laravel
chmod -R 775 /var/www/html/laravel
chmod -R 775 /var/www/html/laravel/storage
chmod -R 775 /var/www/html/laravel/bootstrap/cache

# Finish Laravel installation
cp .env.example .env
php artisan key:generate

# MySQL database setup
# Generate a random password for MySQL
MySQL_RANDPW=$(openssl rand -base64 12)
mysql -u root -p"$MySQL_RANDPW" <<EOF
CREATE DATABASE laravel;
GRANT ALL PRIVILEGES ON laravel.* TO 'root'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Store the MySQL password securely in a variable
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD='$MySQL_RANDPW'/" .env

# Cache Configuration
php8.1 artisan config:cache

# Migrate the database
php8.1 artisan migrate --force

# Restart Apache
systemctl restart apache2
