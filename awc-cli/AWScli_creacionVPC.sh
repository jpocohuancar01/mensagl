#!/bin/bash

# ============================
# Variables
# ============================
NOMBRE_ALUMNO="julio224-AWCLI"
REGION="us-east-1"

# ============================
# CLAVE SSH
# ============================
KEY_NAME="ssh-mensagl-2025-${NOMBRE_ALUMNO}"

# Generar clave SSH
ssh-keygen -t rsa -b 2048 -f ${KEY_NAME}.pem -q -N ""

# Crear clave en AWS
aws ec2 import-key-pair --key-name "${KEY_NAME}" --public-key-material fileb://${KEY_NAME}.pem.pub --region $REGION

# ============================
# VPC
# ============================
VPC_ID=$(aws ec2 create-vpc --cidr-block "10.224.0.0/16" --query 'Vpc.VpcId' --output text --region $REGION)
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "{\"Value\":true}" --region $REGION
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}" --region $REGION

# ============================
# SUBNETS
# ============================
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block "10.224.1.0/24" --availability-zone "${REGION}a" --query 'Subnet.SubnetId' --output text --region $REGION)
PRIVATE_SUBNET1_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block "10.224.2.0/24" --availability-zone "${REGION}a" --query 'Subnet.SubnetId' --output text --region $REGION)
PRIVATE_SUBNET2_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block "10.224.3.0/24" --availability-zone "${REGION}b" --query 'Subnet.SubnetId' --output text --region $REGION)

# Habilitar IP pública en la subnet pública
aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch --region $REGION

# ============================
# INTERNET GATEWAY
# ============================
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text --region $REGION)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION

# ============================
# ROUTE TABLES
# ============================
RTB_PUBLIC_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text --region $REGION)
aws ec2 create-route --route-table-id $RTB_PUBLIC_ID --destination-cidr-block "0.0.0.0/0" --gateway-id $IGW_ID --region $REGION
aws ec2 associate-route-table --route-table-id $RTB_PUBLIC_ID --subnet-id $PUBLIC_SUBNET_ID --region $REGION

# ============================
# NAT GATEWAY
# ============================
EIP_ID=$(aws ec2 allocate-address --query 'AllocationId' --output text --region $REGION)
NAT_GW_ID=$(aws ec2 create-nat-gateway --subnet-id $PUBLIC_SUBNET_ID --allocation-id $EIP_ID --query 'NatGateway.NatGatewayId' --output text --region $REGION)
sleep 30  # Esperar a que el NAT Gateway esté disponible

# ============================
# ROUTE TABLES PARA SUBNETS PRIVADAS
# ============================
RTB_PRIVATE1_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text --region $REGION)
RTB_PRIVATE2_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text --region $REGION)

aws ec2 create-route --route-table-id $RTB_PRIVATE1_ID --destination-cidr-block "0.0.0.0/0" --nat-gateway-id $NAT_GW_ID --region $REGION
aws ec2 create-route --route-table-id $RTB_PRIVATE2_ID --destination-cidr-block "0.0.0.0/0" --nat-gateway-id $NAT_GW_ID --region $REGION

aws ec2 associate-route-table --route-table-id $RTB_PRIVATE1_ID --subnet-id $PRIVATE_SUBNET1_ID --region $REGION
aws ec2 associate-route-table --route-table-id $RTB_PRIVATE2_ID --subnet-id $PRIVATE_SUBNET2_ID --region $REGION

# ============================
# RESULTADOS
# ============================
echo "VPC_ID: $VPC_ID"
echo "PUBLIC_SUBNET_ID: $PUBLIC_SUBNET_ID"
echo "PRIVATE_SUBNET1_ID: $PRIVATE_SUBNET1_ID"
echo "PRIVATE_SUBNET2_ID: $PRIVATE_SUBNET2_ID"
echo "IGW_ID: $IGW_ID"
echo "RTB_PUBLIC_ID: $RTB_PUBLIC_ID"
echo "NAT_GW_ID: $NAT_GW_ID"
echo "RTB_PRIVATE1_ID: $RTB_PRIVATE1_ID"
echo "RTB_PRIVATE2_ID: $RTB_PRIVATE2_ID"
