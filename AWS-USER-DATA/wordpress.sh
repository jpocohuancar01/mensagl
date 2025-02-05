#!/bin/bash
# Actualizar el sistema
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update
# Instalar las dependencias de WordPress
sudo DEBIAN_FRONTEND=noninteractive apt install -y apache2 curl git unzip ghostscript libapache2-mod-php mysql-server php php-bcmath php-curl php-imagick php-intl php-json php-mbstring php-mysql php-xml

sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update
# Instalar las dependencias de WordPress
sudo DEBIAN_FRONTEND=noninteractive apt install -y apache2 curl git unzip ghostscript libapache2-mod-php mysql-server php php-bcmath php-curl php-imagick php-intl php-json php-mbstring php-mysql php-xml

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp-cli

#Limpiar el directorio web de nuestro servicio
sudo rm -rf /var/www/html/*
sudo chmod -R 755 /var/www/html
sudo chown -R www-data:www-data /var/www/html

#cometar /descometar
#Configuración de MySQL para WordPress
#sudo mysql -u root -e "CREATE DATABASE wordpress;"
#sudo mysql -u root -e "CREATE USER 'wordpress'@'localhost' IDENTIFIED BY '_Admin123';"
#sudo mysql -u root -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER ON wordpress.* TO 'wordpress'@'localhost';"
#sudo mysql -u root -e "FLUSH PRIVILEGES;"

#configurar wordpress


# Descargar y configurar WordPress
sudo -u www-data wp-cli core download --path=/var/www/html

sudo -u www-data wp-cli core config --dbname=wordpress --dbuser=wordpress --dbpass=_Admin123 --dbhost=127.0.0.1 --dbprefix=wp --path=/var/www/html

sudo -u www-data wp-cli core install --path="/var/www/html/" --url="http://ngixn224.duckdns.org" --title="Mi WordPress" --admin_user="admin" --admin_password="_Admin123" --admin_email="admin@example.com"

#instalar plugin
sudo -u www-data wp-cli plugin install supportcandy --activate --path="/var/www/html"

#sudo echo "define('WP_HOME','http://nginxequipo45.duckdns.org');" >> /var/www/html/wp-config.php
#sudo echo "define('WP_SITEURL','http://nginxequipo45.duckdns.org');" >> /var/www/html/wp-config.php
# Reiniciar Apache para aplicar cambios
sudo a2enmod rewrite
sudo systemctl restart apache2

echo "La instalación de WordPress se ha completado. Accede a tu sitio en http://<tu_dominio_o_IP> para completar la configuración."











