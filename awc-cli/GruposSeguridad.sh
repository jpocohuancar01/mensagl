# Variables
VPC_ID="vpc-xxxxxxxx"  # Reemplaza con tu VPC ID

# Crear grupo de seguridad para Nginx
SG_NGINX_ID=$(aws ec2 create-security-group --group-name sg_nginx --description "Grupo de seguridad para nginx" --vpc-id $VPC_ID --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $SG_NGINX_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_NGINX_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_NGINX_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id $SG_NGINX_ID --protocol -1 --port 0 --cidr 0.0.0.0/0

# Crear grupo de seguridad para CMS
SG_CMS_ID=$(aws ec2 create-security-group --group-name sg_cms --description "Security group for CMS cluster" --vpc-id $VPC_ID --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $SG_CMS_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_CMS_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_CMS_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id $SG_CMS_ID --protocol -1 --port 0 --cidr 0.0.0.0/0

# Crear grupo de seguridad para MySQL
SG_MYSQL_ID=$(aws ec2 create-security-group --group-name sg_mysql --description "Grupo de seguridad para MySQL" --vpc-id $VPC_ID --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $SG_MYSQL_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_MYSQL_ID --protocol tcp --port 3306 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id $SG_MYSQL_ID --protocol -1 --port 0 --cidr 0.0.0.0/0

# Crear grupo de seguridad para NAS
SG_NAS_ID=$(aws ec2 create-security-group --group-name sg_nas --description "Grupo de seguridad para NAS" --vpc-id $VPC_ID --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $SG_NAS_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id $SG_NAS_ID --protocol -1 --port 0 --cidr 0.0.0.0/0

# Crear grupo de seguridad para XMPP
SG_XMPP_ID=$(aws ec2 create-security-group --group-name sg_xmpp --description "Grupo de seguridad para XMPP Openfire" --vpc-id $VPC_ID --query 'GroupId' --output text)

PORTS_TCP=(22 80 443 5222 5223 5262 5263 5269 5270 7070 7443 7777 9090 9091 9999)
PORTS_UDP=(26001-27000 50000-55000)

for port in "${PORTS_TCP[@]}"; do
  aws ec2 authorize-security-group-ingress --group-id $SG_XMPP_ID --protocol tcp --port $port --cidr 0.0.0.0/0
done

for port_range in "${PORTS_UDP[@]}"; do
  aws ec2 authorize-security-group-ingress --group-id $SG_XMPP_ID --protocol udp --port $port_range --cidr 0.0.0.0/0
done

aws ec2 authorize-security-group-egress --group-id $SG_XMPP_ID --protocol -1 --port 0 --cidr 0.0.0.0/0

# Crear grupo de seguridad para MySQL adicional
SG_MYSQL_EXTRA_ID=$(aws ec2 create-security-group --group-name MySQL_sg --description "Trafico a mysql" --vpc-id $VPC_ID --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $SG_MYSQL_EXTRA_ID --protocol tcp --port 3306 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-egress --group-id $SG_MYSQL_EXTRA_ID --protocol -1 --port 0 --cidr 0.0.0.0/0

echo "Grupos de seguridad creados con éxito."
