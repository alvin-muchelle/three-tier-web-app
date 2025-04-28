# 1. Internal ALB in private subnets
resource "aws_lb" "app_tier_alb" {
  name               = "app-tier-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_alb_sg.id]
  subnets            = [for subnet in aws_subnet.private : subnet.id]

  depends_on = [null_resource.update_rds_secret]

  enable_deletion_protection = false

  tags = {
    Name = "App Tier ALB"
  }
}

# 2. Internal ALB Target Group for App EC2s
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tier-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  depends_on = [null_resource.update_rds_secret]

  tags = {
    Name = "App Tier Target Group"
  }
}

# 3. Internal ALB Listener on port 80
resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app_tier_alb.arn
  port              = 80
  protocol          = "HTTP"

  depends_on = [null_resource.update_rds_secret]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# 4. Launch App Tier ASG

resource "aws_launch_template" "app-template" {
  name_prefix   = "app-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data/app.sh", {
    notification_email = var.notification_email
    region = var.aws_region
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.app_instance_profile.name
  }
  
  depends_on = [
    null_resource.update_rds_secret,
    aws_iam_policy.app_secrets_policy
  ]

}

resource "aws_autoscaling_group" "app-asg" {
  vpc_zone_identifier = [for subnet in aws_subnet.private : subnet.id]
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  
  launch_template {
    id      = aws_launch_template.app-template.id
    version = "$Latest"
  }

  depends_on = [null_resource.update_rds_secret]
  
  target_group_arns = [aws_lb_target_group.app_tg.arn]

  tag {
    key                 = "Name"
    value               = "App Tier Instance"
    propagate_at_launch = true
  }
}
