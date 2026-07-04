resource "aws_db_subnet_group" "owncloud" {
  name       = "owncloud-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_data_a.id,
    aws_subnet.private_data_b.id
  ]
  tags = { Name = "owncloud-db-subnet-group" }
}

resource "aws_db_parameter_group" "owncloud" {
  name   = "owncloud-mysql8-params"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "max_allowed_packet"
    value = "67108864"
  }

  tags = { Name = "owncloud-mysql8-params" }
}

resource "aws_db_instance" "owncloud" {
  identifier        = "owncloud-rds"
  engine            = "mysql"
  engine_version    = "8.0.46"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.owncloud.name
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  parameter_group_name   = aws_db_parameter_group.owncloud.name

  multi_az            = true
  publicly_accessible = false

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = { Name = "owncloud-rds" }
}