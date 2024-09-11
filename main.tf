# Definiere den AWS Provider und die Region
provider "aws" {
  region = "eu-central-1"  # Ersetze dies durch deine gewünschte AWS-Region
}

# Erstelle eine VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "main_vpc"
  }
}

# Erstelle ein öffentliches Subnetz in der VPC
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"  # Ersetze dies durch deine gewünschte Availability Zone
  map_public_ip_on_launch = true  # Erlaubt, dass Instanzen im Subnetz eine öffentliche IP erhalten
  tags = {
    Name = "main_subnet"
  }
}

# Erstelle ein Internet-Gateway und verbinde es mit der VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main_internet_gateway"
  }
}

# Erstelle eine Route-Tabelle und füge eine Route zum Internet-Gateway hinzu
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main_route_table"
  }
}

# Verknüpfe das Subnetz mit der Route-Tabelle
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Definiere die EC2-Instanz
resource "aws_instance" "feedback_app" {
  ami           = "ami-04f76ebf53292ef4d"  # Ersetze dies durch die ID des Amazon Linux 2023 AMI
  instance_type = "t2.micro"       

  # Userdata-Skript, das beim Starten der Instanz ausgeführt wird
  user_data = file("userdata.sh")

  # Sicherheitsgruppen-ID hinzufügen
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  # Subnetz-ID hinzufügen
  subnet_id = aws_subnet.main.id

  # Erlaube Zuweisung einer öffentlichen IP
  associate_public_ip_address = true

  tags = {
    Name = "FeedbackAppInstance" 
  }
}

# Sicherheitsgruppe, um SSH und HTTP-Zugriff zu ermöglichen
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  # Regel für SSH-Zugriff (Port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Regel für HTTP-Zugriff (Port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  # Regel für Port 3030 (Feedback-App)
  ingress {
    from_port   = 3030
    to_port     = 3030
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  # Egress-Regel, um allen ausgehenden Verkehr zu erlauben
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Output für die öffentliche IP-Adresse der Instanz
output "instance_public_ip" {
  value = aws_instance.feedback_app.public_ip
}
