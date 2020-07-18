#Creating aws provider
provider "aws" {
  region     = "ap-south-1"
  profile = "hybrid"
}


#Creating VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "myVPC"
  }
}


#Creating public subnet for the vpc in 1a
resource "aws_subnet" "public_sub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet1"
  }
}


#Creating private subnet for the vpc in 1b
resource "aws_subnet" "private_sub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "subnet2"
  }
}


#Creating public facing internet gateway for the vpc we created
resource "aws_internet_gateway" "mygw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "myIgw"
  }
}


#Creating routing table with routing to our IG
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygw.id
  }
  tags = {
    Name = "myroute"
  }
}


#Associating with public subnet
resource "aws_route_table_association" "route_ass" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.route.id
}


#Creating new private key
resource "tls_private_key" "privateKey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_key_pair" "MyKey" {
  key_name = "My-Key"
  public_key = tls_private_key.privateKey.public_key_openssh
}


#Creating security group for WordPress
resource "aws_security_group" "newgrp1" {
  depends_on =[
    aws_vpc.myvpc
  ]
  name        = "MySecGrp1"
  description = "Allow HTTP inbound traffic"
  vpc_id = aws_vpc.myvpc.id
  
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
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
    Name = "MySecGrp1"
  }
}


#Creating WordPress instance
resource "aws_instance" "myin1" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.MyKey.key_name
  vpc_security_group_ids = [aws_security_group.newgrp1.id] 
  subnet_id = aws_subnet.public_sub.id

  tags = {
    Name = "MyWordPressIns"
  }
}


#Creating security group for Mysql
resource "aws_security_group" "newgrp2" {
   depends_on =[
    aws_vpc.myvpc
  ]
  name        = "MySecGrp2"
  description = "Allow Mysql inbound traffic"
  vpc_id = aws_vpc.myvpc.id
  
  ingress {
    description = "HTTP from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.newgrp1.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MySecGrp2"
  }
}


#Creating Mysql instance
resource "aws_instance" "myin2" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.MyKey.key_name
  vpc_security_group_ids = [aws_security_group.newgrp2.id] 
  subnet_id = aws_subnet.private_sub.id

  tags = {
    Name = "MysqlIns"
  }
}


#Saving the key
resource "local_file" "local1" { 
  filename = "Hybrid-Key.pem"
  content = tls_private_key.privateKey.private_key_pem
}


#Starting google chrome and navigating to WordPress instance's public ip
resource "null_resource" "local2" {
  depends_on =[
    aws_instance.myin1,aws_instance.myin2
  ]
  provisioner "local-exec" {
    command = "start chrome ${aws_instance.myin1.public_ip}"
  }
}