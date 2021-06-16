
#Internet Gateway
resource "aws_internet_gateway" "my-gw" {
  vpc_id = aws_vpc.main.id
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