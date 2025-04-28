# 1. Create a Web facing ALB

resource "aws_lb" "web-tier-alb" {
  name               = "web-tier-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = false

}

# 2. Target Group for Nginx EC2s
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tier-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "Web Tier Target Group"
  }
}


# 3. Listener for Public ALB
resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web-tier-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# 4. Create Web Server Instance ASG

resource "aws_launch_template" "web-template" {
  name_prefix   = "web-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.web_instance_profile.name
  }

  network_interfaces {
    device_index                = 0
    subnet_id                   = element([for subnet in aws_subnet.public : subnet.id], 0)
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(
    templatefile("${path.module}/user_data/web.sh", {
    internal_alb_dns = aws_lb.app_tier_alb.dns_name
    })
  )
}

resource "aws_autoscaling_group" "web-asg" {
  vpc_zone_identifier = [for subnet in aws_subnet.public : subnet.id]
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size

  launch_template {
    id      = aws_launch_template.web-template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.web_tg.arn]

  tag {
    key                 = "Name"
    value               = "Web Tier Instance"
    propagate_at_launch = true
  }
}

# 5. Wait for Cloud Init to Complete

resource "time_sleep" "wait_for_cloud_init" {
  depends_on = [aws_autoscaling_group.web-asg]
  
  create_duration = "90s"
}
