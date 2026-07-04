locals {
  user_data = base64encode(<<-USERDATA
    #!/bin/bash
    set -euo pipefail
    exec > /var/log/user_data.log 2>&1

    yum update -y
    yum install -y ansible git

    ansible-galaxy collection install community.docker

    cat > /tmp/extra-vars.yml <<'VARSEOF'
    efs_id: "${aws_efs_file_system.owncloud.id}"
    efs_ap_id: "${aws_efs_access_point.owncloud.id}"
    rds_address: "${aws_db_instance.owncloud.address}"
    db_name: "${var.db_name}"
    db_username: "${var.db_username}"
    db_password: "${var.db_password}"
    owncloud_admin_password: "${var.owncloud_admin_password}"
    alb_dns: "${aws_lb.owncloud.dns_name}"
    VARSEOF

    ansible-pull \
      -U https://github.com/nicolasduarter/acc-owncloud-project.git \
      --checkout main \
      --directory /tmp/ansible-pull \
      -i localhost, \
      ansible/site.yml \
      --extra-vars @/tmp/extra-vars.yml
  USERDATA
  )
}

resource "aws_launch_template" "owncloud" {
  name_prefix   = "owncloud-lt-"
  image_id      = var.ami_id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.sg_app.id]
  user_data              = local.user_data

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "owncloud-node" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "owncloud" {
  name                = "owncloud-asg"
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = [
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_b.id
  ]

  launch_template {
    id      = aws_launch_template.owncloud.id
    version = "$Latest"
  }

  target_group_arns         = [aws_lb_target_group.owncloud.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 600

  tag {
    key                 = "Name"
    value               = "owncloud-node"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "owncloud-scale-out"
  autoscaling_group_name = aws_autoscaling_group.owncloud.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "owncloud-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.owncloud.name }
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "owncloud-scale-in"
  autoscaling_group_name = aws_autoscaling_group.owncloud.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "owncloud-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.owncloud.name }
}