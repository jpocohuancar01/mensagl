# =================================================================================================================================================================================
# necesita haber hecho wordpress.sh y despues estos comandos antes de ejecutarse pero para ello necesitas el endpoint del RDS  esta automatizado para ello en el script de terraform
#      "sudo -u www-data wp-cli core config --dbname=wordpress --dbuser=wordpress --dbpass=_Admin123 --dbhost=${aws_db_instance.MySQL_Wordpress.endpoint} --dbprefix=wp --path=/var/www/html",
#      "sudo -u www-data wp-cli core install --url='http://224wordpress	.duckdns.org' --title='Wordpress equipo 4' --admin_user='admin' --admin_password='_Admin123' --admin_email='admin@example.com' --path=/var/www/html",
#      "sudo -u www-data wp-cli plugin install supportcandy --activate --path='/var/www/html'",
#      "sudo -u www-data wp-cli plugin install user-registration --activate --path=/var/www/html",
#      "sudo -u www-data wp-cli plugin install wps-hide-login --activate",
#      "sudo -u www-data wp-cli option update wps_hide_login_url equipo4-admin",
# =================================================================================================================================================================================

sudo -u www-data wp-cli cap add "subscriber" "read" --path=/var/www/html
sudo -u www-data wp-cli cap add "subscriber" "create_ticket" --path=/var/www/html
sudo -u www-data wp-cli cap add "subscriber" "view_own_ticket" --path=/var/www/html
sudo -u www-data wp-cli option update default_role "subscriber" --path=/var/www/html


sudo -u www-data wp-cli option update users_can_register 1 --path=/var/www/html



sudo sed -i '1d' /var/www/html/wp-config.php
sudo sed -i '1i\
<?php if (isset($_SERVER["HTTP_X_FORWARDED_FOR"])) {\
    $list = explode(",", $_SERVER["HTTP_X_FORWARDED_FOR"]);\
    $_SERVER["REMOTE_ADDR"] = $list[0];\
}\
$_SERVER["HTTP_HOST"] = "224wordpress.duckdns.org";\
$_SERVER["REMOTE_ADDR"] = "224wordpress.duckdns.org";\
$_SERVER["SERVER_ADDR"] = "224wordpress.duckdns.org";\
' /var/www/html/wp-config.php


sudo scp -i clave.pem -o StrictHostKeyChecking=no ubuntu@10.224.1.10:/home/ubuntu/certwordpress/* /home/ubuntu/
sudo cp /home/ubuntu/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
sudo a2enmod ssl
sudo a2enmod headers
sudo a2ensite default-ssl.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
