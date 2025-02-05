#!/bin/bash

# Actualiza el sistema y asegura que los paquetes necesarios estén instalados
sudo apt update 
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
# Instalar OpenJDK 17 y MySQL
sudo DEBIAN_FRONTEND=noninteractive apt install -y openjdk-17-jre default-jre-headless mysql-server wget

# Descargar e instalar Openfire
wget https://download.igniterealtime.org/openfire/openfire_4.9.2_all.deb
sudo dpkg -i openfire_4.9.2_all.deb

# Habilitar y arrancar el servicio de Openfire
sudo systemctl enable openfire
sudo systemctl start openfire

# Crear base de datos de Openfire en MySQL
sudo mysql -e "CREATE DATABASE openfire;"

# Copiar y ejecutar el script SQL de Openfire para la configuración de la base de datos
sudo cp /usr/share/openfire/resources/database/openfire_mysql.sql /tmp/openfire_mysql.sql
sudo mysql -u root openfire < /tmp/openfire_mysql.sql

# Crear el usuario de la base de datos para Openfire
sudo mysql -u root -e "CREATE USER 'openfire'@'localhost' IDENTIFIED BY '_Admin123';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON openfire.* TO 'openfire'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"