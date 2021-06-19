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
   
# Create NAT and elastic ip
# resource "aws eip" "go_green_nat_eip" {
#   vpc                          = true
#   associate_with_private_ip    = "10.0.30.0"
# }
# Provision NAT Gateway
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

# Create Private Route Table (PVRT)
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

# Private Route creation 
# resource "aws_route" "gg_priv_route" {
# route_table_id         = aws_route_table.gg_pvrt.id 
# destination cidr block = "0.0.0.0/0"
# nat_gateway_id         =   aws_nat_gateway.go_green_natgw.id
# }

# Make "gg_pub_route" PURT the main route table (not AWS auto created one for VPC)
resource "aws_main_route_table_association" "gg_pub_route" {
  vpc_id          = aws_vpc.go_green_corp_vpc.id
  route_table_id  = aws_route_table.gg_pub_route.id
}

#Assoc PURT with Public Subnet(s)
resource "aws_route_table_association" "pub_sub_assoc_az1" {
  route_table_id = aws_route_table.gg_pub_route.id #assoc this PURT
  subnet_id      = aws_subnet.pub_az1_subnet.id    #with this pub subnet in AZ1
}

resource "aws_route_table_association" "pub_sub_assoc_az2" {
  route_table_id = aws_route_table.gg_pub_route.id #assoc this PURT
  subnet_id      = aws_subnet.pub_az1_subnet.id    #with this pub subnet in AZ1 
}

# Assoc PVRT with Private Subnet(s)
# resource "aws_route_table_association" "priv1_sub_assoc_az1" {
#   route_table_id = aws_route_table.gg_priv_route.id
#   subnet_id      = aws_subnet.priv1_sub_az1_subnet.id
# }

# resource "aws_route_table_association" "priv1_sub_assoc_az2" {
#   route_table_id = aws_route_table.gg_priv_route.id
#   subnet_id      = aws_subnet.priv1_sub_az2_subnet.id
# }

# resource "aws_route_table_association" "priv2_sub_assoc_az1" {
#   route_table_id = aws_route_table.gg_priv_route.id
#   subnet_id      = aws_subnet.priv2_sub_az1_subnet.id
# }

# resource "aws_route_table_association" "priv2_sub_assoc_az2" {
#   route_table_id = aws_route_table.gg_priv_route.id
#   subnet_id      = aws_subnet.priv2_sub_az2_subnet.id
# }

# Create Instance for PubSub (Public Subnet) 
resource "aws_instance" "Go_Green_Bastion" {
  ami                         = "ami-0aeeebd8d2ab47354"
  instance_type               = "t2.micro"
  subnet_id                   =  aws_subnet.pub_sub_assoc_az1.id
  security_groups             = [aws_security_group.go_green_pub_sg.id]
  associate_public_ip_address = true 
  key_name                    = aws_key_pair.deployer.key_name
  iam_instance_profile        = aws_iam_instance_profile.kj_profile.name
  
  user_data = file("gguser-data.sh")
  tags  = {
    Name  = "Go_Green_Bastion"
  }
}
variable "public_key" {
  type = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHRTGOvhPXOHxX/XwzFXrAdp0/yr3sC06Te17IozpdE2W/pVVCKDrSxu6vJBEw2w0tunLD9XfogzlFT6rCeSS0bH9lNzscncmt+eJjXfbQwAVcLkt7on/IgI/IEFzwbZUNEuRZFJAULisbHvMn6OHXQ+NklwVPsNphvzDAYiwG/nW6PPKaSVryEn2H41Rs7/yyBgf/CgeosaOqRuPJo3gBzZQgvvaWqjcSdYhVFmZf3ypB6l43YOnTWm/RLsaDMAHNG+E3SeOpMgW3Jk/JW9O/9JWPSrvhh/wMMKVV1MgDJNVu7fpR+4aNfc54S6R8df8Oje/JOLF35v9/UkCug5ph kjacksonus@gmail.com"
}

resource "aws_key_pair" "deploy" {
  key_name      = "deploy-key"
  public_key    = var.public_key  
}

# Create Instance for PrivSub (Private Subnet) 
resource "aws_instance" "Go_Green_private_ec2" {
  ami                         = "ami-0b2ca94b5b49e0132"
  instance_type               = "t2.nano"
  subnet_id                   =  aws_subnet.priv1_sub_assoc_az1.id
  security_groups             = [aws_security_group.go_green_priv1_sg.id]
  associate_public_ip_address = true 
  key_nano                    = aws_key_pair.deployer.key_nano
  user_data                   = file("userdata.sh")
  tags  = {
    Name  = "Go_Green_Priv_ec2"
  }
}

# resource "aws_eip_association" "eip_assoc" {
# instance_id   = aws_instance.go_green_priv_ec2.id
# allocation_id = aws.eip.example.id
# }

# resource "aws_eip" "example" {
#   instance = aws_instance.go_green_priv_ec2.id
#   vpc      = true
# }

## After deployment of infrastructure, an 'output' will show-up on command line for Web App Load Balancer DNS naming
## C&P (copy and paste) into new browser 