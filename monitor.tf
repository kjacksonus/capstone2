/*
provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "/Users/nilusultanva/.aws/credentials"
  profile                 = "default"
}

#Manitor
resource "aws_iam_group_membership" "monitor" {
  name = "tf-testing-group-membership"
  users = [
    aws_iam_user.monitoruser1.name,
    aws_iam_user.monitoruser2.name,
    aws_iam_user.monitoruser3.name,
    aws_iam_user.monitoruser4.name,
  ] 
  
  group = aws_iam_group.monitor.name
}
resource "aws_iam_group" "monitor" {
  name = "test-monitor"
}

#Monitoruser 1
resource "aws_iam_user" "monitoruser1" {
  name          = "monitoruser1"
  path          = "/system/"
  force_destroy = true
}
resource "aws_iam_access_key" "monitoruser1_access_key" {
  user = aws_iam_user.monitoruser1.name
}
#Monitoruser 2
resource "aws_iam_user" "monitoruser2" {
  name          = "monitoruser2"
  path          = "/system/"
  force_destroy = true
}
resource "aws_iam_access_key" "monitoruser2_access_key" {
  user = aws_iam_user.monitoruser2.name
}
#Monitoruser 3
resource "aws_iam_user" "monitoruser3" {
  name          = "monitoruser3"
  path          = "/system/"
  force_destroy = true
}
resource "aws_iam_access_key" "monitoruser3_access_key" {
  user = aws_iam_user.monitoruser3.name
}
#Monitoruser 4
resource "aws_iam_user" "monitoruser4" {
  name          = "monitoruser4"
  path          = "/system/"
  force_destroy = true
}
resource "aws_iam_access_key" "monitoruser4_access_key" {
  user = aws_iam_user.monitoruser4.name
}

resource "aws_iam_group_policy" "monitor_policy" {
  name  = "monitor"
  group = aws_iam_group.monitor.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "cloudwatch:*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_account_password_policy" "syadmin_password" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}
*/