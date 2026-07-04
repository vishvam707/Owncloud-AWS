# ── ALB — only entry point from internet ───────────────────────
resource "aws_security_group" "sg_alb" {
  name        = "owncloud-sg-alb"
  description = "ALB: HTTP and HTTPS from internet"
  vpc_id      = aws_vpc.owncloud_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_app.id]
  }

  tags = { Name = "owncloud-sg-alb" }
}

# ── App — EC2 / ASG nodes ───────────────────────────────────────
resource "aws_security_group" "sg_app" {
  name        = "owncloud-sg-app"
  description = "EC2 ownCloud: ingress from ALB only, egress to RDS and EFS"
  vpc_id      = aws_vpc.owncloud_vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_rds.id]
  }

  egress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_efs.id]
  }

  # Outbound internet access via NAT Gateway (Docker pulls, OS updates)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "owncloud-sg-app" }
}

# ── RDS — database layer ────────────────────────────────────────
resource "aws_security_group" "sg_rds" {
  name        = "owncloud-sg-rds"
  description = "RDS MySQL: ingress from sg-app only"
  vpc_id      = aws_vpc.owncloud_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_app.id]
  }

  tags = { Name = "owncloud-sg-rds" }
}

# ── EFS — shared filesystem layer ──────────────────────────────
resource "aws_security_group" "sg_efs" {
  name        = "owncloud-sg-efs"
  description = "EFS: NFS ingress from sg-app only"
  vpc_id      = aws_vpc.owncloud_vpc.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_app.id]
  }

  tags = { Name = "owncloud-sg-efs" }
}