
# Cretae VPC
resource "aws_vpc" "gogreen" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "My-VPC"
  }
}
#Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.gogreen.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "public_subnet"
  }
}
#Create Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.gogreen.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "private_subnet"
  }
}
#Internet Gateway
resource "aws_internet_gateway" "my-gw" {
  vpc_id = aws_vpc.gogreen.id
  tags = {
    Name = "my-IGW"
  }
}
#Elastic IP Address
resource "aws_eip" "lb" {
  vpc = true
}
#NAT Gateway
resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "gw NAT"
  }
}
#Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.gogreen.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-gw.id
  }
  tags = {
    Name = "public_route_table"
  }
}
#Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.gogreen.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gateway.id
  }
  tags = {
    Name = "private_route_table"
  }
}
# Public Route Table Associate
resource "aws_route_table_association" "public-route-table-ass" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}
# Private Route Table Associate
resource "aws_route_table_association" "private-route-table-ass" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}
# Web-server
resource "aws_instance" "Web-server" {
  instance_type = "t2.micro"
  ami           = "ami-0aeeebd8d2ab47354"
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "Web-Server"
  }
}
# App-server
resource "aws_instance" "App-server" {
  instance_type = "t2.micro"
  ami           = "ami-0aeeebd8d2ab47354"
  subnet_id     = aws_subnet.private_subnet.id
  tags = {
    Name = "App-Server"
  }
}
resource "aws_instance" "DB-server" {
  instance_type = "t2.micro"
  ami           = "ami-0aeeebd8d2ab47354"
  subnet_id     = aws_subnet.private_subnet.id
  tags = {
    Name = "DB-Server"
  }
}

variable "public_key" {
    type = string
    default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbCzIYEJDHSqW5whp455v9ZRv5jdHgoI6m/X/XYpI1XSsxfxHb0l/QCUbomAxWjbH/pauDmjo+5dEOVgc8eZu7hZkqRtnG5jZT/OM9YcxZZzVCShwgP7lG3rMA2wpg2DCOzOkmozm21zgUYIiO6UJy6zqLoPfoSliTEYWaUEExUoV/JG17s0Fy8SkuEjx/9qbhZrS7QRVfOlqrrlZJm5Scpj0Edq1+TAAspMb0laNBmJZgc4fg/muko9dmbXf3+2KOH5K9gV7Y8Q7CbY2pnp5BfvBq/IDufWzff+SNp2yl+/QjKDDwV9Pl4yYfVSDw650oBGoEdgt0/4pHiXXyh6O7"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
}

