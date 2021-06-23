resource "aws_key_pair" "project_team" {
  key_name   = "project"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_autoscaling_attachment" "project-web" {
  autoscaling_group_name = aws_autoscaling_group.project-web.id
  elb                    = aws_lb.web_tier_lb.id
}

resource "aws_autoscaling_group" "project-web" {
  name                      = "project-StrongCloud"
  availability_zones        = ["us-west-1a"]
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  #placement_group           = aws_placement_group.test.id
  #launch_configuration      = aws_launch_configuration.foobar.name
  #vpc_zone_identifier       = [aws_subnet.example1.id, aws_subnet.example2.id]

}

resource "aws_instance" "web_tier" {
  ami           = "ami-04468e03c37242e1e"
  instance_type = "t2.micro"
  #aws_autoscaling_group = "aws_autoscaling_attachment.bar.id"
  key_name = aws_key_pair.project_team.key_name
  tags = {
    Name = "Web_Tier_SK"
  }

}

resource "aws_instance" "application_tier" {
  ami           = "ami-04468e03c37242e1e"
  instance_type = "t2.micro"
  #aws_autoscaling_group = "aws_autoscaling_attachment.bar.id"
  key_name = aws_key_pair.project_team.key_name
  tags = {
    Name = "Application_Tier_SK"
  }

}

resource "aws_instance" "database_tier" {
  ami           = "ami-04468e03c37242e1e"
  instance_type = "t2.micro"
  #aws_autoscaling_group = "aws_autoscaling_attachment.bar.id"
  key_name = aws_key_pair.project_team.key_name
  tags = {
    Name = "Database_Tier_SK"
  }

}

resource "aws_lb" "web_tier_lb" {
  name               = "web-lb-tf"
  internal           = false
  load_balancer_type = "application"
  #security_groups    = [aws_security_group.lb_sg.id]
  #subnets            = aws_subnet.public.*.id

  enable_deletion_protection = true

  #access_logs {
  # bucket  = aws_s3_bucket.lb_logs.bucket
  #prefix  = "test-lb"
  #enabled = true
  #}

  tags = {
    Environment = "project-application-tier"
  }
}


resource "aws_elb_attachment" "web_tier_lb" {
  elb      = aws_lb.web_tier_lb.id
  instance = aws_instance.web_tier.id
}

#instances                   = [aws_instance.foo.id]
#cross_zone_load_balancing   = true
#idle_timeout                = 400
#connection_draining         = true
