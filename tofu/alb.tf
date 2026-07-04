resource "aws_lb" "owncloud" {
  name                       = "owncloud-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.sg_alb.id]
  subnets                    = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
  enable_deletion_protection = false
  tags = { Name = "owncloud-alb" }
}

resource "aws_lb_target_group" "owncloud" {
  name        = "owncloud-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.owncloud_vpc.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/status.php"
    port                = "8080"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30
  tags = { Name = "owncloud-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.owncloud.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.owncloud.arn
  }
}