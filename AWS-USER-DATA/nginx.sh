#!/bin/bash
#preparar dns dinamico
# crear directorio
mkdir -p "/home/ubuntu/duckdns/"
cd "/home/ubuntu/duckdns/"

# Crear script para actualizar la ip dinamicamente
echo "echo url=\"https://www.duckdns.org/update?domains=ngixn224&token=dbf2ef8f-dabe-4213-a8b7-92ff9cc4835f=\" | curl -k -o /home/ubuntu/duckdns/duck.log -K -" > "/home/ubuntu/duckdns/duck.sh"
chmod 700 "/home/ubuntu/duckdns/duck.sh"

echo "echo url=\"https://www.duckdns.org/update?domains=openfire224&token=dbf2ef8f-dabe-4213-a8b7-92ff9cc4835f=\" | curl -k -o /home/ubuntu/duckdns/duck.log -K -" > "/home/ubuntu/duckdns/duck2.sh"
chmod 700 "/home/ubuntu/duckdns/duck2.sh"

# Añadir al crontab
(crontab -l 2>/dev/null; echo "*/1 * * * * /home/ubuntu/duckdns/duck.sh >/dev/null 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/1 * * * * /home/ubuntu/duckdns/duck2.sh >/dev/null 2>&1") | crontab -

#Instalación de Nginx
sudo apt update && sudo  DEBIAN_FRONTEND=noninteractive apt install nginx -y

#clonar git
sudo git clone https://github.com/amazona01/AWSCLI.git

#mover configuraciones
sudo mv AWSCLI/configuraciones_servicios/nginx/wordpress /etc/nginx/sites-available/
sudo mv AWSCLI/configuraciones_servicios/nginx/default /etc/nginx/sites-available/

#symlinks 
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

#Restart Nginx
sudo systemctl restart nginx

#Borrar
rm -rf AWSCLI