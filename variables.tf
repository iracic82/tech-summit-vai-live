variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.100.0.0/16"
}

variable "windows_admin_password" {
  description = "Password for the NIOS admin account"
  type        = string
  sensitive   = true
}
