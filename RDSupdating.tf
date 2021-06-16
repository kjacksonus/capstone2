/*provider "aws" {
  region = "us-wes-1"
}

resource "aws_db_instance" "my_project_RDS" {
  name                = "My-Project-RDS-SK"
  identifier          = "my-first-rds-SK"
  instance_class      = "db.t2.micro"
  engine              = "mysql"
  engine_version      = "5.7.42"
  username            = "project"
  password            = "password123"
  port                = 3306
  allocated_storage   = 5.5
  skip_final_snapshot = true

}
*/