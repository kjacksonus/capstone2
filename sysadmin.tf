
provider "aws" {
  region     = "us-east-1"
  shared_credentials_file = "/Users/nilusultanva/.aws/credentials"
  profile = "default"
}
resource "aws_iam_group_membership" "sysadmin" {
  name = "tf-testing-group-membership"
  users = [
    aws_iam_user.sysadmin1.name,
    aws_iam_user.sysadmin2.name,
  ]
  group = aws_iam_group.sysadmin.name
}
resource "aws_iam_group" "sysadmin" {
  name = "test-sysadmin"
}
#SysAdmin 1
resource "aws_iam_user" "sysadmin1" {
  name          = "sysadmin1"
  path          = "/system/"
  force_destroy = true
}
resource "aws_iam_access_key" "sysadmin1_access_key" {
  user = aws_iam_user.sysadmin1.name
}
#SysAdmin 2
resource "aws_iam_user" "sysadmin2" {
  name          = "sysadmin2"
  path          = "/system/"
  force_destroy = true
}
resource "aws_iam_access_key" "sysadmin2_access_key" {
  user = aws_iam_user.sysadmin2.name
}

resource "aws_iam_group_policy" "sysadmin_policy" {
  name  = "sysadmin"
  group = aws_iam_group.sysadmin.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "*"
      ],
      "Effect": "Allow",
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
