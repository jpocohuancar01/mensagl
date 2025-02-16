# Configurar variables
AMI_ID="ami-0e001c9271cf7f3b9"  # Sustituir con la AMI correcta
INSTANCE_TYPE="t2.micro"
KEY_NAME="my-key-pair"
SECURITY_GROUP="sg-12345678"  # Sustituir con el ID correcto
SUBNET_ID="subnet-abcdef12"  # Sustituir con el ID correcto
DB_NAME="test_db"
DB_USER="admin"
DB_PASSWORD="securepassword"

# Crear una instancia EC2
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SECURITY_GROUP \
    --subnet-id $SUBNET_ID \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Instancia EC2 creada: $INSTANCE_ID"

# Crear un volumen EBS
VOLUME_ID=$(aws ec2 create-volume \
    --availability-zone us-east-1a \
    --size 10 \
    --volume-type gp2 \
    --query 'VolumeId' \
    --output text)

echo "Volumen EBS creado: $VOLUME_ID"

# Asociar el volumen a la instancia
aws ec2 attach-volume \
    --volume-id $VOLUME_ID \
    --instance-id $INSTANCE_ID \
    --device /dev/sdf

echo "Volumen EBS asociado a la instancia"

# Crear una base de datos RDS
aws rds create-db-instance \
    --db-instance-identifier mydbinstance \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --allocated-storage 20 \
    --master-username $DB_USER \
    --master-user-password $DB_PASSWORD \
    --vpc-security-group-ids $SECURITY_GROUP

echo "Base de datos RDS creada"
