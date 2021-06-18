# #provision vpc, all subnets, igw, and default (main) route-table 
# #VPC-1, 6 subnets (includes duplication of infrastructure; web -pub-,app, and dbase)
# #provision corporate vpc 
resource "aws_vpc" "go_green_corp_vpc" {
  cidr_block           ="10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "GoGreenCorpVPC"
  }
}

# Create IGW (Internet Gateway)
resource "aws_internet_gateway" "go_green_igw" {
    vpc_id = aws_vpc.go_green_corp_vpc.id
    tags = {
      Name = "GoGreenCorpIGW"
    }
}
   
# # Create NAT and elastic ip
# resource "aws eip" "go_green_nat_eip" {
#   vpc                          = true
#   associate_with_private_ip    = "10.0.30.0"
# }
# # Provision NAT Gateway
# resource "aws_nat_gateway" "go_green_natgw" {
# allocation_id = aws_eip.go_green_nat_eip.id
# subnet_id     = aws_subnet.pub_az1_subnet.id
# depends_on    = [aws_eip.go_green_nat_eip]
# tags = {
#   Name = "Go-Green-NATGW"
#   }
# }

# Public Route Table (PURT) creation
resource "aws_route_table" "gg_purt" {
  vpc_id = aws_vpc.go_green_corp_vpc.id
  tags = {
    Name = "Go-Green-Pub-Route-Table"
  } 
}

# # Create Private Route Table (PVRT)
# resource "aws_route_table" "gg_pvrt" {
# vpc_id = aws_vpc.go_green_corp_vpc.id
# tags = {
#   Name = "Go-Green-Priv-Route-Table"
#  } 
# }

# Public Route creation 
resource "aws_route" "gg_pub_route" {
  route_table_id = aws_route_table.gg_purt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.go_green_igw.id  
}

# # Private Route creation 
# resource "aws_route" "gg_priv_route" {
# route_table_id         = aws_route_table.gg_pvrt.id 
# destination cidr block = "0.0.0.0/0"
}
