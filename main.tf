provider "aws" {
    region = "us-east-1"
    access_key = 
    secret_key = 
}


#1 Key Pair
resource "aws_key_pair" "keypair" {
  key_name   = "project"
  public_key = "  "
# 2 Project VPC
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "project_vpc"
  }
}
# 3 Public Subnet
resource "aws_subnet" "projectpublica" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "project_public_A"
    }
  availability_zone = "us-east-1a"
  cidr_block = "10.0.1.0/24"
}
# 4 Elastic IP
resource "aws_eip" "eip" {
  vpc      = true
}
# 5 Instance with Root block device
resource "aws_instance" "ec2" {
  ami = var.project_ami
  availability_zone = "us-east-1a"
  instance_type = var.project_instance_type
  key_name = var.key_name
  subnet_id = aws_subnet.projectpublica.id
root_block_device {
    volume_size = 8
    volume_type = "gp2"
    delete_on_termination = true
  }
  tags = var.default_tags
}
# 6 Security Group
resource "aws_security_group" "securitygroup" {
    name = "cloud-test1"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [var.cidr_blocks]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [var.cidr_blocks]
    }
    egress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = [var.cidr_blocks]
    }
  }
# 7 EIP Association
resource "aws_eip_association" "eipassociation" {
  instance_id   = aws_instance.ec2.id
  allocation_id = aws_eip.eip.id
}
# 8 Output
output "eip" {
  value = aws_eip.eip.public_ip
}
# 9 Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}