/*provider "aws" {
  region = "us-west-1"
  shared_credentials_file = "/Users/nilusultanva/.aws/credentials"
  profile = "default"
}
resource "aws_db_instance" "my_project_rds" {
  name              = "myrdsql"
  instance_class    = "db.t2.micro"
  engine            = "mysql"
  engine_version    = "8.0.20"
  username          = "project"
  password          = "password123"
  port              = 3306
  allocated_storage = 5
}
*/