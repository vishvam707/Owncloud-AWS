# ── Security group shells (no inline rules) ─────────────────────

resource "aws_security_group" "sg_alb" {
  name        = "owncloud-sg-alb"
  description = "ALB: HTTP and HTTPS from internet"
  vpc_id      = aws_vpc.owncloud_vpc.id
  tags        = { Name = "owncloud-sg-alb" }
}

resource "aws_security_group" "sg_app" {
  name        = "owncloud-sg-app"
  description = "EC2 ownCloud: ingress from ALB only, egress to RDS and EFS"
  vpc_id      = aws_vpc.owncloud_vpc.id
  tags        = { Name = "owncloud-sg-app" }
}

resource "aws_security_group" "sg_rds" {
  name        = "owncloud-sg-rds"
  description = "RDS MySQL: ingress from sg-app only"
  vpc_id      = aws_vpc.owncloud_vpc.id
  tags        = { Name = "owncloud-sg-rds" }
}

resource "aws_security_group" "sg_efs" {
  name        = "owncloud-sg-efs"
  description = "EFS: NFS ingress from sg-app only"
  vpc_id      = aws_vpc.owncloud_vpc.id
  tags        = { Name = "owncloud-sg-efs" }
}

# ── sg_alb rules ─────────────────────────────────────────────────

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.sg_alb.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.sg_alb.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_egress_to_app" {
  type                     = "egress"
  security_group_id       = aws_security_group.sg_alb.id
  from_port               = 8080
  to_port                 = 8080
  protocol                = "tcp"
  source_security_group_id = aws_security_group.sg_app.id
}

# ── sg_app rules ─────────────────────────────────────────────────

resource "aws_security_group_rule" "app_ingress_from_alb" {
  type                     = "ingress"
  security_group_id       = aws_security_group.sg_app.id
  from_port               = 8080
  to_port                 = 8080
  protocol                = "tcp"
  source_security_group_id = aws_security_group.sg_alb.id
}

resource "aws_security_group_rule" "app_egress_to_rds" {
  type                     = "egress"
  security_group_id       = aws_security_group.sg_app.id
  from_port               = 3306
  to_port                 = 3306
  protocol                = "tcp"
  source_security_group_id = aws_security_group.sg_rds.id
}

resource "aws_security_group_rule" "app_egress_to_efs" {
  type                     = "egress"
  security_group_id       = aws_security_group.sg_app.id
  from_port               = 2049
  to_port                 = 2049
  protocol                = "tcp"
  source_security_group_id = aws_security_group.sg_efs.id
}

resource "aws_security_group_rule" "app_egress_https" {
  type              = "egress"
  security_group_id = aws_security_group.sg_app.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_egress_http" {
  type              = "egress"
  security_group_id = aws_security_group.sg_app.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_egress_dns_tcp" {
  type              = "egress"
  security_group_id = aws_security_group.sg_app.id
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_egress_dns_udp" {
  type              = "egress"
  security_group_id = aws_security_group.sg_app.id
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ── sg_rds rules ─────────────────────────────────────────────────

resource "aws_security_group_rule" "rds_ingress_from_app" {
  type                     = "ingress"
  security_group_id       = aws_security_group.sg_rds.id
  from_port               = 3306
  to_port                 = 3306
  protocol                = "tcp"
  source_security_group_id = aws_security_group.sg_app.id
}

# ── sg_efs rules ─────────────────────────────────────────────────

resource "aws_security_group_rule" "efs_ingress_from_app" {
  type                     = "ingress"
  security_group_id       = aws_security_group.sg_efs.id
  from_port               = 2049
  to_port                 = 2049
  protocol                = "tcp"
  source_security_group_id = aws_security_group.sg_app.id
}
