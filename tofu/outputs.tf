output "alb_dns_name" {
  description = "Open this URL in your browser to access ownCloud"
  value       = aws_lb.owncloud.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.owncloud.endpoint
}

output "efs_id" {
  value = aws_efs_file_system.owncloud.id
}

output "asg_name" {
  value = aws_autoscaling_group.owncloud.name
}