provider "aws" {
    region = "us-west-2"
    shared_credentials_file = "/Users/jasurdosmetov/.aws/credentials"
    profile = "default"
}

 #module "aurora" {
#     source                          = "clouddrove/aurora/aws"
#     version                         = "0.12.0"
#     name                            = "backend"
#     application                     = ""
#     environment                     = "test"
#     label_order                     = []
#     username                        = "admin"
#     database_name                   = "dt"
#     engine                          = "aurora-mysql"
#     engine_version                  = "5.7.12"
#     subnets                         = [aws_subnet.private7.id, aws_subnet.private8.id]
#     aws_security_group              = [aws_security_group.db_sec_group,id]
#     replica_count                   = 1
#     instance_type                   = "db.t2.medium"
#     apply_immediately               = true
#     skip_final_snapshot             = true
#     publicly_accessible             = false
#   }
# data "aws_caller_identity" "current" {}
resource "aws_rds_cluster" "default" {
  cluster_identifier      = "aurora-cluster-demo"
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.03.2"
  availability_zones      = ["us-west-2a", "us-west-2b"]
  database_name           = "mydb"
  master_username         = var.db_username
  master_password         = var.db_password
  backup_retention_period = 0
  preferred_backup_window = "07:00-09:00"
  vpc_security_group_ids  = [aws_security_group.db_sec_group.id]
  skip_final_snapshot     = true
  # s3_import {
  #   source_engine         = "aurora-mysql"
  #   source_engine_version = "5.7"
  #   bucket_name           = "go-green-02262021"
  #   bucket_prefix         = "backups"
  #   ingestion_role        = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/role-xtrabackup-rds-restore"
  # }
}
resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "aurora-cluster-demo-${count.index}"
  cluster_identifier = aws_rds_cluster.default.id
  instance_class     = "db.r4.large"
  engine             = aws_rds_cluster.default.engine
  engine_version     = aws_rds_cluster.default.engine_version
}
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-sn-group"
  subnet_ids = [aws_subnet.private5.id, aws_subnet.private6.id]
  tags = {
    Name = "GoGreenDB"
  }
}
resource "aws_security_group" "db_sec_group" {
  name   = "db_sec_group"
  vpc_id = aws_vpc.team2vpc.id
  ingress {
    from_port       = "3306"
    to_port         = "3306"
    protocol        = "tcp"
    security_groups = [aws_security_group.sec_group.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}






resource "aws_security_group" "sec_group" {
  name   = "sec_group"
  vpc_id = aws_vpc.team2vpc.id
  ingress {
    from_port       = var.http_port
    to_port         = var.http_port
    protocol        = "tcp"
    security_groups = [aws_security_group.elb-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# resource "aws_launch_template" "web_tier_launch_template" {
#   name_prefix   = "web_tier"
#   image_id      = var.ami
#   instance_type = var.instance_type #"t2.micro"
#   vpc_security_group_ids = [aws_security_group.sec_group.id] # 02/24/2020 testing lb launch templete
# user_data = <<-EOF
#  #!/bin/bash
# sudo yum update
# sudo yum install -y httpd
# sudo chkconfig httpd on
# sudo service httpd start
# echo "<h1>Deployed via Terraform wih ELB</h1>" | sudo tee /var/www/html/index.html
# 	EOF	
# }
resource "aws_launch_configuration" "asg-launch-config-sample" {
  image_id        = var.ami
  instance_type   = var.instance_type
  security_groups = [aws_security_group.sec_group.id]
  user_data = <<-EOF
              #!/bin/bash -ex
              yum -y install httpd php mysql php-mysql
              chkconfig httpd on
              service httpd start
              if [ ! -f /var/www/html/lab-app.tgz ]; then
              cd /var/www/html
              wget https://aws-tc-largeobjects.s3-us-west-2.amazonaws.com/CUR-TF-200-ACACAD/studentdownload/lab-app.tgz
              tar xvfz lab-app.tgz
              chown apache:root /var/www/html/rds.conf.php
              fi
              EOF
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group" "elb-sg" {
  name   = "terraform-sample-elb-sg"
  vpc_id = aws_vpc.team2vpc.id
  # Allow all outbound
  # Inbound HTTP from anywhere
 ingress {
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_autoscaling_group" "asg-sample" {
  launch_configuration = aws_launch_configuration.asg-launch-config-sample.id
  vpc_zone_identifier  = [aws_subnet.private1.id, aws_subnet.private2.id]
  min_size             = 6
  max_size             = 12
  desired_capacity     = 6
  # load_balancers    = [aws_lb.web_lb.name]
  target_group_arns = [aws_lb_target_group.web_tg.arn]
  health_check_type = "ELB"
  tag {
    key                 = "Name"
    value               = "web-tier"
    propagate_at_launch = true
  }
}
resource "aws_lb" "web_lb" {
  name               = "web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb-sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
  # health_check {
  #   healthy_threshold   = 2
  #   unhealthy_threshold = 2
  #   timeout             = 3
  #   target              = "HTTP:80/index.html"
  #   interval            = 30
  # }
  # health_check {
  #   target              = "HTTP:${var.server_port}/"
  #   interval            = 300
  #   timeout             = 30
  #   healthy_threshold   = 20
  #   unhealthy_threshold = 20
  # }
}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = var.http_port
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
resource "aws_lb_target_group" "web_tg" {
  name     = "tf-web-lb-tg"
  port     = var.http_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.team2vpc.id
  health_check {
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

 #module "aurora" {
#     source                          = "clouddrove/aurora/aws"
#     version                         = "0.12.0"
#     name                            = "backend"
#     application                     = ""
#     environment                     = "test"
#     label_order                     = []
#     username                        = "admin"
#     database_name                   = "dt"
#     engine                          = "aurora-mysql"
#     engine_version                  = "5.7.12"
#     subnets                         = [aws_subnet.private7.id, aws_subnet.private8.id]
#     aws_security_group              = [aws_security_group.db_sec_group,id]
#     replica_count                   = 1
#     instance_type                   = "db.t2.medium"
#     apply_immediately               = true
#     skip_final_snapshot             = true
#     publicly_accessible             = false
#   }
# resource "aws_rds_cluster" "default" {
#   cluster_identifier      = "aurora-cluster-demo"
#   engine                  = "aurora-mysql"
#   engine_version          = "5.7.mysql_aurora.2.03.2"
#   availability_zones      = ["us-west-2a", "us-west-2b", "us-west-2c"]
#   database_name           = "mydb"
#   master_username         = "foo"
#   master_password         = "bar"
#   backup_retention_period = 0
#   preferred_backup_window = "07:00-09:00"
#   vpc_security_group_ids = [aws_security_group.db_sec_group.id]
#   skip_final_snapshot = true
# }
#     resource "aws_rds_cluster_instance" "cluster_instances" {
#   count              = 2
#   identifier         = "aurora-cluster-demo-${count.index}"
#   cluster_identifier = aws_rds_cluster.default.id
#   instance_class     = "db.r4.large"
#   engine             = aws_rds_cluster.default.engine
#   engine_version     = aws_rds_cluster.default.engine_version
# }
#   resource "aws_security_group" "db_sec_group" {
#   name   = "db_sec_group"
#   vpc_id = aws_vpc.team2vpc.id
#   ingress {
#     from_port   = "3306"
#     to_port     = "3306"
#     protocol    = "tcp"
#     security_groups = [aws_security_group.sec_group.id] 
#   }
#    egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

terraform {
  backend "s3" {
    bucket = "gogreen-statefile-03022021"
    key    = "tstate/gogreen.tfstate"
    region = "us-west-2"
  }
}

# this is cloudfront.tf file
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "${var.environment}-cloudfront-access-identity"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.bucket.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  comment             = var.comment
  default_root_object = var.default_root_object
  aliases             = var.aliases
  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods
    target_origin_id = aws_s3_bucket.bucket.bucket
    forwarded_values {
      query_string = var.query_string
      headers      = var.headers
      cookies {
        forward = var.forward
      }
    }
    viewer_protocol_policy = var.viewer_protocol_policy
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = var.compress
  }
  price_class = var.price_class
  restrictions {
    geo_restriction {
      restriction_type = var.restriction_type
      locations        = var.locations
    }
  }
  tags = {
    Environment = "var.environment"
  }
  viewer_certificate {
    cloudfront_default_certificate = var.cloudfront_default_certificate
  }
}

output "elb_dns_name" {
  value       = aws_lb.web_lb.dns_name
  description = "The domain name of the load balancer"
}
output "cloudfront_id" {
    value = aws_cloudfront_distribution.s3_distribution.id
}

#-------------------------------ec2 policies and roles
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "ec2-role"
  }
}
resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.ec2_role.name
}
resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = aws_iam_role.ec2_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "rds:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
#GROUPS POLICIES
resource "aws_iam_group_policy" "sysadmin_group_policy" {
  name  = "sysadmin_policy"
  group = aws_iam_group.SysAdmin.name
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# resource "aws_route53_zone" "l7gogreen" {
#   name = "l7gogreen.com"
# }
# resource "aws_route53_record" "www1" {
#   zone_id = aws_route53_zone.l7gogreen.zone_id
#   name    = "www.l7gogreen.com"
#   ttl = "300"
#   type    = "A"
#   records = [aws_route53_zone.l7gogreen.name]
#   # alias {
#   #   name    = aws_cloudfront.www.l7gogreen.com
#   #   zone_id = aws_cloudfront.zone.l7gogreen.zone_id
#   # }
# }

//Creates hosted zone in RT53
resource "aws_route53_zone" "gogreen" {
  name = "globalebsolutions.com"
}
//Creates record in hosted zone RT53
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.gogreen.zone_id
  name    = "www.globalebsolutions.com"
  type    = "A"
  alias {
    name    = "dualstack.${aws_lb.web_lb.dns_name}"  //resolves dns name to webtier lb dns name
    zone_id = aws_lb.web_lb.zone_id   
    evaluate_target_health = true
  }
}
//Outputs the 4 DNS servers that route traffic to DNS record
output "name_server" {
  value = aws_route53_zone.gogreen.name_servers
}

resource "aws_iam_role" "replication-role" {
  name = "s3-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}
resource "aws_iam_policy" "replication" {
  name = "s3-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.bucket.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.bucket.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.versioning_bucket.arn}/*"
    }
  ]
}
POLICY
}
resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication-role.name
  policy_arn = aws_iam_policy.replication.arn
}
resource "aws_s3_bucket" "bucket" {
  bucket = "go-green-02262021"
  acl    = "private"
  #   object_lock_configuration = false
  versioning {
    enabled = true
  }
  replication_configuration {
    role = aws_iam_role.replication-role.arn
    rules {
      id     = "rep-rule"
      prefix = "bckup"
      status = "Enabled"
      destination {
        bucket        = aws_s3_bucket.versioning_bucket.arn
        storage_class = "STANDARD"
      }
    }
  }
  lifecycle_rule {
    id      = "log"
    enabled = true
    prefix = "log/"
    tags = {
      rule      = "log"
      autoclean = "true"
    }
    transition {
      days          = 90
      storage_class = "STANDARD_IA" # or "ONEZONE_IA"
    }
    transition {
      days          = 180
      storage_class = "GLACIER"
    }
    expiration {
      days = 1825
    }
  }
  lifecycle_rule {
    id      = "main-lifecycle"
    prefix  = "tmp/"
    enabled = true
    expiration {
      date = "2030-01-12"
    }
  }
}
resource "aws_s3_bucket" "versioning_bucket" {
  bucket = "go-green-replication-02262021"
  acl    = "private"
  versioning {
    enabled = true
  }
  lifecycle_rule {
    prefix  = "config/"
    enabled = true
    noncurrent_version_transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    noncurrent_version_transition {
      days          = 180
      storage_class = "GLACIER"
    }
    noncurrent_version_expiration {
      days = 1825
    }
  }
}

resource "aws_sns_topic" "team2" {
  name = "team2"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}
resource "aws_sns_topic_subscription" "team2" {
  topic_arn = aws_sns_topic.team2.id
  protocol  = "sms"
  endpoint  = "2026707710"# needs phone number
}
resource "aws_cloudwatch_metric_alarm" "nlb_healthyhosts" {
  alarm_name          = "alarmname"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Number of healthy nodes in Target Group"
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.team2.arn]
  ok_actions          = [aws_sns_topic.team2.arn]
  dimensions = {
    TargetGroup  = aws_lb_target_group.web_tg.arn
    LoadBalancer = aws_lb.web_lb.arn
  }
}

#USERS AND THEIR ACCESS KEYS
resource "aws_iam_user" "sysadmin1" {
  name = "system_administrator_1"
}
resource "aws_iam_access_key" "sysadmin-1" {
  user = aws_iam_user.sysadmin1.name
}
resource "aws_iam_user" "sysadmin2" {
  name = "system_administrator_2"
}
resource "aws_iam_access_key" "sysadmin-2" {
  user = aws_iam_user.sysadmin2.name
}
resource "aws_iam_user" "dbadmin1" {
  name = "database_administrator_1"
}
resource "aws_iam_access_key" "dbadmin-1" {
  user = aws_iam_user.dbadmin1.name
}
resource "aws_iam_user" "dbadmin2" {
  name = "database_administrator_2"
}
resource "aws_iam_access_key" "dbadmin-2" {
  user = aws_iam_user.dbadmin2.name
}
resource "aws_iam_user" "monitoruser1" {
  name = "monitoring_user_1"
}
resource "aws_iam_access_key" "monitor-1" {
  user = aws_iam_user.monitoruser1.name
}
resource "aws_iam_user" "monitoruser2" {
  name = "monitoring_user_2"
}
resource "aws_iam_access_key" "monitor-2" {
  user = aws_iam_user.monitoruser2.name
}
resource "aws_iam_user" "monitoruser3" {
  name = "monitoring_user_3"
}
resource "aws_iam_access_key" "monitor-3" {
  user = aws_iam_user.monitoruser3.name
}
resource "aws_iam_user" "monitoruser4" {
  name = "monitoring_user_4"
}
resource "aws_iam_access_key" "monitor-4" {
  user = aws_iam_user.monitoruser4.name
}
#GROUPS/USERS_MEMBERSHIP
resource "aws_iam_group" "SysAdmin" {
  name = "system_admins"
}
resource "aws_iam_group" "DBAdmin" {
  name = "database_admins"
}
resource "aws_iam_group" "Monitor" {
  name = "monitoring_group"
}
resource "aws_iam_group_membership" "sysadmin_membership" {
  name = "membership_for_sysadmin_group"
  users = [
    aws_iam_user.sysadmin1.name,
    aws_iam_user.sysadmin2.name,
  ]
  group = aws_iam_group.SysAdmin.name
}
resource "aws_iam_group_membership" "dbadmin_membership" {
  name = "membership_for_dbadmin_group"
  users = [
    aws_iam_user.dbadmin1.name,
    aws_iam_user.dbadmin2.name,
  ]
  group = aws_iam_group.DBAdmin.name
}
resource "aws_iam_group_membership" "monitor_users_membership" {
  name = "membership_for_monitor_group"
  users = [
    aws_iam_user.monitoruser1.name,
    aws_iam_user.monitoruser2.name,
    aws_iam_user.monitoruser3.name,
    aws_iam_user.monitoruser4.name,
  ]
  group = aws_iam_group.Monitor.name
}
#PASSWD_POLICY
resource "aws_iam_account_password_policy" "passwd_policy" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  password_reuse_prevention      = 3
  max_password_age               = 90
  allow_users_to_change_password = true
}
#PROGRAMMATIC/CONSOLE ACCESS
# resource "aws_iam_user_login_profile" "console_access" { #console access
#   for_each = var.create_login_profiles
#   user    = aws_iam_user.sysadmin1.name
#   pgp_key = var.pgp_key
# }
# resource "aws_iam_user_login_profile" "sys1_console_access" {
#   user    = aws_iam_user.sysadmin1.name
#   pgp_key = var.pgp_key
# }
# resource "aws_iam_user_login_profile" "sys2_console_access" {
#   user    = aws_iam_user.sysadmin2.name
#   pgp_key = var.pgp_key
# }
# resource "aws_iam_user_login_profile" "dbsys1_console_access" {
#   user    = aws_iam_user.dbadmin1.name
#   pgp_key = var.pgp_key
# }
# resource "aws_iam_user_login_profile" "dbsys2_console_access" {
#   user    = aws_iam_user.dbadmin2.name
#   pgp_key = var.pgp_key
# }
# resource "aws_iam_user_login_profile" "monitor1_console_access" {
#   user    = aws_iam_user.monitoruser1.name
#   pgp_key = var.pgp_key
# }
# resource "aws_iam_user_login_profile" "monitor2_console_access" {
#   user    = aws_iam_user.monitoruser2.name
#   pgp_key = var.pgp_key
# }
# resource "aws_iam_user_login_profile" "monitor3_console_access" {
#   user    = aws_iam_user.monitoruser3.name
#   pgp_key = var.pgp_key
# }
# resource "aws_iam_user_login_profile" "monitor4_console_access" {
#   user    = aws_iam_user.monitoruser4.name
#   pgp_key = var.pgp_key
# }

variable "instance_type" {
  type        = string
  description = "This is my instance type"
  default     = "t2.micro"
}
variable "region" {
  type    = string
  default = "us-west-2"
}
# variable "key_name" {
#   type        = string
#   description = "Name of ssh key"
#   default = "my-key"
# }
variable "app_ec2_tags" {
  type = map(any)
  default = {
    Name = "app-tier"
  }
}
variable "web_ec2_tags" {
  type = map(any)
  default = {
    Name = "web-tier"
  }
}
variable "external_ip" {
  type    = string
  default = "0.0.0.0/0"
}
variable "server_port" {
  description = "The port the web server will be listening"
  type        = number
  default     = 8080
}
variable "http_port" {
  description = "The port the elb will be listening"
  type        = number
  default     = 80
}
variable "ami" {
  type    = string
  default = "ami-0e999cbd62129e3b1"
}
variable "users" {
  type        = list(string)
  description = "Users to create in a simple list format `[\"user1\", \"user2\"]. Use either variable `users` or `users_groups`"
  default     = ["sysadmin1", "sysadmin2", "dbadmin1", "dbadmin2", "monitoring_user_1", "monitoring_user_2", "monitoring_user_3", "monitoring_user_4"]
}
variable "create_access_keys" {
  type        = bool
  description = "Set to true to create programmatic access for all users"
  default     = true
}
# variable "create_login_profiles" {
#   type        = list(string)
#   description = "Set to true to create console access for all users"
#   default     = true
# }
variable "pgp_key" {
  type        = string
  description = "PGP key in plain text or using the format `keybase:username` to encrypt user keys and passwords"
  default     = "AKIAQWPSY6BWGNTFHBMT"
}
variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
  default     = "admin"
}
variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
  default     = "password1234"
}

variable "environment" {
  description = "Logical name of the environment."
  type        = string
  default     = "Dev"
}
variable "bucket_name" {
  type    = string
  default = "gogreen-02262021" # needs exicting bucket name
}
variable "bucket_visibility" {
  type    = string
  default = "private"
}
variable "bucket_tags" {
  type    = string
  default = "cloudfront-bucket"
}
variable "s3_origin_id" {
  type    = string
  default = "gogreen-02262021"
}
variable "enabled" {
  type    = bool
  default = true
}
variable "is_ipv6_enabled" {
  type    = bool
  default = true
}
variable "comment" {
  type        = string
  default     = null
  description = "Comment field for the distribution"
}
variable "default_root_object" {
  type    = string
  default = "index.html"
}
variable "aliases" {
  type    = list(string)
  default = [] # ["mysite.example.com"]
}
variable "include_cookies" {
  type    = bool
  default = false
}
variable "log_bucket" {
  type    = string
  default = "logb-bucket"
}
variable "log_prefix" {
  default = "cf_logs"
}
variable "allowed_methods" {
  type    = list(any)
  default = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
}
variable "cached_methods" {
  type    = list(any)
  default = ["GET", "HEAD"]
}
variable "min_ttl" {
  default = "0"
}
variable "default_ttl" {
  default = "3600"
}
variable "max_ttl" {
  default = "86400"
}
variable "headers" {
  type    = list(any)
  default = []
}
variable "query_string" {
  type    = bool
  default = "false"
}
variable "forward" {
  type    = string
  default = "none"
}
variable "compress" {
  type    = bool
  default = "true"
}
variable "viewer_protocol_policy" {
  type    = string
  default = "allow-all"
}
variable "price_class" {
  type    = string
  default = "PriceClass_200"
}
variable "restriction_type" {
  type    = string
  default = "none"
}
variable "locations" {
  type    = list(any)
  default = []
}
variable "cloudfront_default_certificate" {
  type    = bool
  default = "true"
}

resource "aws_vpc" "team2vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main"
  }
}
#_________________________________________ Public Subnets
resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.team2vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "Public Subnet1"
  }
}
resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.team2vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "Public Subnet2"
  }
}
#__________________________________________ Private Subnets
resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.team2vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "Private Subnet1"
  }
}
resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.team2vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "Private Subnet2"
  }
}
resource "aws_subnet" "private3" {
  vpc_id            = aws_vpc.team2vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "Private Subnet3"
  }
}
resource "aws_subnet" "private4" {
  vpc_id            = aws_vpc.team2vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "Private Subnet4"
  }
}
resource "aws_subnet" "private5" {
  vpc_id            = aws_vpc.team2vpc.id
  cidr_block        = "10.0.7.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "Private Subnet5"
  }
}
resource "aws_subnet" "private6" {
  vpc_id            = aws_vpc.team2vpc.id
  cidr_block        = "10.0.8.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "Private Subnet6"
  }
}
#____________________________________________________ Internet Gateway
resource "aws_internet_gateway" "IG" {
  vpc_id = aws_vpc.team2vpc.id
  tags = {
    Name    = "Internet Gateway for VPC"
    Project = "GoGreen team 2"
  }
}
#__________________________________________________________________ Public Route Tables/Subnet Associations
resource "aws_route_table" "public_table_us-west-2a" {
  vpc_id = aws_vpc.team2vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IG.id
  }
}
resource "aws_route_table_association" "public_subnet_association-2a" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_table_us-west-2a.id
}
resource "aws_route_table" "public_table_us-west-2b" {
  vpc_id = aws_vpc.team2vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IG.id
  }
}
resource "aws_route_table_association" "public_subnet_association-2b" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_table_us-west-2b.id
}
#___________________________________________________________________________ Private Route Tables/Subnet Associations
resource "aws_route_table" "private_table_us-west-2a" {
  vpc_id = aws_vpc.team2vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-2a.id
  }
}
resource "aws_route_table_association" "private1_subnet_association-2a" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_table_us-west-2a.id
}
resource "aws_route_table_association" "private3_subnet_association-2a" {
  subnet_id      = aws_subnet.private3.id
  route_table_id = aws_route_table.private_table_us-west-2a.id
}
resource "aws_route_table_association" "private5_subnet_association-2a" {
  subnet_id      = aws_subnet.private5.id
  route_table_id = aws_route_table.private_table_us-west-2a.id
}
resource "aws_route_table" "private_table_us-west-2b" {
  vpc_id = aws_vpc.team2vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-2b.id
  }
}
resource "aws_route_table_association" "private2_subnet_association-2b" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_table_us-west-2b.id
}
resource "aws_route_table_association" "private4_subnet_association-2b" {
  subnet_id      = aws_subnet.private4.id
  route_table_id = aws_route_table.private_table_us-west-2b.id
}
resource "aws_route_table_association" "private6_subnet_association-2b" {
  subnet_id      = aws_subnet.private6.id
  route_table_id = aws_route_table.private_table_us-west-2b.id
}
#____________________________________________________________________________ Elastic IPs
resource "aws_eip" "elastic_ip-2a" {
  vpc = true
  depends_on = [aws_internet_gateway.IG]
}
resource "aws_eip" "elastic_ip-2b" {
  vpc = true
  depends_on = [aws_internet_gateway.IG]
}
#________________________________________________________________________________ NATs
resource "aws_nat_gateway" "nat-2a" {
  allocation_id = aws_eip.elastic_ip-2a.id
  subnet_id     = aws_subnet.public1.id
}
resource "aws_nat_gateway" "nat-2b" {
  allocation_id = aws_eip.elastic_ip-2b.id
  subnet_id     = aws_subnet.public2.id
}