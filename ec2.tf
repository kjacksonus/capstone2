/*provider "aws" {
  region = "us-west-1"

}

resource "aws_key_pair" "project_team" {
  key_name   = "project"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "web_tier" {
  ami           = "ami-04468e03c37242e1e"
  instance_type = "t2.micro"
  key_name               = aws_key_pair.project_team.key_name
  tags = {
    Name = "Web_Tier_SK"
  }

}

resource "aws_instance" "application_tier" {
  ami           = "ami-04468e03c37242e1e"
  instance_type = "t2.micro"
  key_name               = aws_key_pair.project_team.key_name
  tags = {
    Name = "Application_Tier_SK"
  }

}

resource "aws_instance" "database_tier" {
  ami           = "ami-04468e03c37242e1e"
  instance_type = "t2.micro"
  key_name               = aws_key_pair.project_team.key_name
  tags = {
    Name = "Database_Tier_SK"
  }

}
*