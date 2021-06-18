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
      Name = "GoGreenCorpIGW"}
}
}
