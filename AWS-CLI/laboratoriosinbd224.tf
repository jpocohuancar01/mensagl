# ============================
# Variable para nombrar los recursos
# ============================
variable "nombre_alumno" {
  description = "Nombre para nombrar los recursos"
  type        = string
  default     = "juliopocohuanca" 
}

# ============================
# CLAVE SSH
# ============================

# Generacion de la clave SSH
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Creacion de la clave SSH en AWS
resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh-mensagl-2025-${var.nombre_alumno}"
  #public_key = tls_private_key.ssh_key.public_key_openss
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Guardar la clave privada localmente
resource "local_file" "private_key_file" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "./.ssh/${path.module}/ssh-mensagl-2025-${var.nombre_alumno}.pem"
}

# Salidas para referencia
output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

output "key_name" {
  value = aws_key_pair.ssh_key.key_name
}

provider "aws" {
  region = "us-east-1"
}



# ============================
# VPC
# ============================

# Crear VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.224.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-mensagl-2025-${var.nombre_alumno}-vpc"
  }
}

# Crear Subnets públicas
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.224.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "vpc-mensagl-2025-${var.nombre_alumno}-subnet-public1-us-east-1a"
  }
}

# resource "aws_subnet" "public2" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.224.2.0/24"
#   availability_zone       = "us-east-1b"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "vpc-mensagl-2025-${var.nombre_alumno}-subnet-public2-us-east-1b"
#   }
# }


# Crear Subnets privadas
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.224.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "vpc-mensagl-2025-${var.nombre_alumno}-subnet-private1-us-east-1a"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.224.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "vpc-mensagl-2025-${var.nombre_alumno}-subnet-private2-us-east-1b"
  }
}

# Crear Gateway de Internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "vpc-mensagl-2025-${var.nombre_alumno}-igw"
  }
}

# Crear tabla de rutas públicas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "vpc-mensagl-2025-${var.nombre_alumno}-rtb-public"
  }
}

# Asociar subnets públicas a la tabla de rutas pública
resource "aws_route_table_association" "assoc_public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

# resource "aws_route_table_association" "assoc_public2" {
#   subnet_id      = aws_subnet.public2.id
#   route_table_id = aws_route_table.public.id
# }

# Crear IP elastica para NAT Gateway
resource "aws_eip" "nat" {
  tags = {
    Name = "vpc-mensagl-2025-${var.nombre_alumno}-eip"
  }
}

# Crear NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "vpc-mensagl-2025-${var.nombre_alumno}-nat"
  }
}

# Crear tablas de rutas privadas
resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "vpc-mensagl-2025-${var.nombre_alumno}-rtb-private1-us-east-1a"
  }
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "vpc-mensagl-2025-${var.nombre_alumno}-rtb-private2-us-east-1b"
  }
}

# Asociar subnets privadas a las tablas de rutas privadas
resource "aws_route_table_association" "assoc_private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table_association" "assoc_private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private2.id
}

# ============================
# Grupos de Seguridad
# ============================

# Grupo de seguridad para nginx
resource "aws_security_group" "sg_nginx" {
  name        = "sg_nginx"
  description = "Grupo de seguridad para nginx"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_nginx"
  }
}

# Grupo de seguridad para el CMS
resource "aws_security_group" "sg_cms" {
  name        = "sg_cms"
  description = "Security group for CMS cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_cms"
  }
}

# Grupo de seguridad para MySQL
resource "aws_security_group" "sg_mysql" {
  name        = "sg_mysql"
  description = "Grupo de seguridad para MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_mysql"
  }
}

# Grupo de seguridad para Mensajería (XMPP Openfire + MySQL)

resource "aws_security_group" "sg_xmpp" {
  name        = "sg_xmpp"
  description = "Grupo de seguirdad para XMPP Openfire"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # XMPP Openfire (puertos predeterminados)
  ingress {
    from_port   = 5222
    to_port     = 5223
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 7777
    to_port     = 7777
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 5262
    to_port     = 5263
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 5269
    to_port     = 5270
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 7443
    to_port     = 7443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 7070
    to_port     = 7070
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 26001
    to_port     = 27000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port   = 50000
    to_port     = 55000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9999
    to_port     = 9999
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Tráfico de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_xmpp"
  }
}


#resource "aws_security_group" "MySQL_sg" {
#  name        = "MySQL_sg"
#  description = "Trafico a mysql"

#  ingress {
#    from_port   = 3306
#    to_port     = 3306
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]  
#  }

#  egress {
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#}


# ============================
# Instancias
# ============================

resource "aws_instance" "nginx" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public1.id 
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.sg_nginx.id]
  associate_public_ip_address = true
  private_ip             = "10.224.1.10"

  # Copy the script from local to remote
  provisioner "file" {
    source      = "C:/Users/Julio/Downloads/prueba/scripts_servicios/nginx.sh"  # ubicacion del script local
    destination = "/home/ubuntu/nginx.sh"          # destino en el equipo remoto
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key = file(".ssh/ssh-mensagl-2025-${var.nombre_alumno}.pem")
      host                = self.public_ip
    }
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./.ssh/ssh-mensagl-2025-${var.nombre_alumno}.pem")
      host        = self.public_ip
}
        inline = [
      "chmod +x /home/ubuntu/nginx.sh",
      "sudo /home/ubuntu/nginx.sh"
    ]
  }
  tags = {
    Name = "Nginx"
  }
  depends_on = [
    aws_vpc.main,
    aws_subnet.public1,
    aws_security_group.sg_nginx,
    aws_key_pair.ssh_key
  ]
}



resource "aws_instance" "XMPP-openfire" {
  ami                    = "ami-053b0d53c279acc90"  # Ubuntu Server 22.04 LTS en us-east-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.sg_xmpp.id]
  key_name               = aws_key_pair.ssh_key.key_name
  associate_public_ip_address = false
  private_ip             = "10.224.2.100"
  provisioner "file" {
    source      = "C:/Users/Julio/Downloads/prueba/scripts_servicios/openfire.sh"  # script local
    destination = "/home/ubuntu/openfire.sh" # destino
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = file("./.ssh/ssh-mensagl-2025-${var.nombre_alumno}.pem")
      host                = self.private_ip
      bastion_host        = aws_instance.nginx.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("./.ssh/ssh-mensagl-2025-${var.nombre_alumno}.pem")
          }
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("C:/Users/Julio/Downloads/prueba/.ssh/ssh-mensagl-2025-${var.nombre_alumno}.pem")
      host        = self.private_ip

      # SSH a través de nginx ya que es el unico con ip publica
      bastion_host        = aws_instance.nginx.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("C:/Users/Julio/Downloads/prueba/.ssh/ssh-mensagl-2025-${var.nombre_alumno}.pem")
    }

    inline = [
            "cd ~",
      "sudo chmod +x C:/Users/Julio/Downloads/prueba/scripts_servicios/openfire.sh",
      "sudo C:/Users/Julio/Downloads/prueba/scripts_servicios/openfire.sh"
    ]
  }
  tags = {
    Name = "OPENFIRE"
  }
  depends_on = [
    aws_vpc.main,
    aws_subnet.private1,
    aws_security_group.sg_xmpp,
    aws_instance.nginx,
    aws_key_pair.ssh_key
  ]
}




resource "aws_instance" "Wordpress" {
  ami                    = "ami-053b0d53c279acc90"  # Ubuntu Server 22.04 LTS en us-east-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private2.id
  vpc_security_group_ids = [aws_security_group.sg_cms.id]
  key_name               = aws_key_pair.ssh_key.key_name
  associate_public_ip_address = false
  private_ip             = "10.224.3.100"
  provisioner "file" {
    source      = "C:/Users/Julio/Downloads/prueba/scripts_servicios/wordpress.sh"  # script local
    destination = "/home/ubuntu/wordpress.sh" # destino
    connection {
      type                = "ssh"
      user                = "ubuntu"  
      private_key         = file("./.ssh/ssh-mensagl-2025-${var.nombre_alumno}.pem")
      host                = self.private_ip
      bastion_host        = aws_instance.nginx.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("./.ssh/ssh-mensagl-2025-${var.nombre_alumno}.pem")
          }
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("./.ssh/ssh-mensagl-2025-${var.nombre_alumno}.pem")
      host        = self.private_ip

      # SSH a través de nginx ya que es el unico con ip publica
      bastion_host        = aws_instance.nginx.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = file("./.ssh/ssh-mensagl-2025-${var.nombre_alumno}.pem")
    }

    inline = [
      "cd ~",
      "sudo chmod +x wordpress.sh",
      "sudo ./wordpress.sh"
    ]
  }
  tags = {
    Name = "WORDPRESS"
  }
  depends_on = [
    aws_vpc.main,
    aws_subnet.private2,
    aws_security_group.sg_cms,
    aws_instance.nginx,
    aws_key_pair.ssh_key,
    #aws_db_instance.MySQL_Wordpress
  ]
}
