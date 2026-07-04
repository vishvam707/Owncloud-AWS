resource "aws_efs_file_system" "owncloud" {
  creation_token   = "owncloud-efs"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  tags             = { Name = "owncloud-efs" }
}

resource "aws_efs_mount_target" "a" {
  file_system_id  = aws_efs_file_system.owncloud.id
  subnet_id       = aws_subnet.private_data_a.id
  security_groups = [aws_security_group.sg_efs.id]
}

resource "aws_efs_mount_target" "b" {
  file_system_id  = aws_efs_file_system.owncloud.id
  subnet_id       = aws_subnet.private_data_b.id
  security_groups = [aws_security_group.sg_efs.id]
}

resource "aws_efs_access_point" "owncloud" {
  file_system_id = aws_efs_file_system.owncloud.id

  posix_user {
    uid = 33
    gid = 33
  }

  root_directory {
    path = "/owncloud-data"
    creation_info {
      owner_uid   = 33
      owner_gid   = 33
      permissions = "0755"
    }
  }

  tags = { Name = "owncloud-efs-ap" }
}