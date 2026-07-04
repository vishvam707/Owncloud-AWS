variable "db_name" {
  type    = string
  default = "owncloud"
}

variable "db_username" {
  type    = string
  default = "owncloud_admin"
}

variable "db_password" {
  description = "RDS master password — pass as TF_VAR_db_password, never hardcode"
  type        = string
  sensitive   = true
}

variable "owncloud_admin_password" {
  description = "ownCloud admin UI password — pass as TF_VAR_owncloud_admin_password"
  type        = string
  sensitive   = true
}

variable "ami_id" {
  description = "Amazon Linux 2023 AMI for EC2 instances"
  type        = string
  default     = "ami-08f44e8eca9095668"
}
