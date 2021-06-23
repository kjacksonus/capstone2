

#DBAdmin
resource "aws_iam_group_membership" "dbadmin" {
  name = "tf-testing-group-membership"
  users = [
    aws_iam_user.dbadmin1.name,
    aws_iam_user.dbadmin2.name,
  ]
  group = aws_iam_group.dbadmin.name
}
resource "aws_iam_group" "dbadmin" {
  name = "test-dbadmin"
}
#Dbadmin 1
resource "aws_iam_user" "dbadmin1" {
  name          = "dbadmin1"
  path          = "/system/"
  force_destroy = true
}
resource "aws_iam_access_key" "dbadmin1_access_key" {
  user = aws_iam_user.dbadmin1.name
}
#Dbadmin 2
resource "aws_iam_user" "dbadmin2" {
  name          = "dbadmin2"
  path          = "/system/"
  force_destroy = true
}
resource "aws_iam_access_key" "dbadmin2_access_key" {
  user = aws_iam_user.dbadmin2.name
}
resource "aws_iam_group_policy" "dbadmin_policy" {
  name   = "dbadmin"
  group  = aws_iam_group.dbadmin.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "rds:*",
            "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_iam_account_password_policy" "dbadmin_password" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
}
