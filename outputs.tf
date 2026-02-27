# Outputs
output "gm_public_ip" {
  description = "Public IP of NIOS Grid Master (GM1) in eu-central-1"
  value       = aws_eip.gm_eip.public_ip
}

output "gm2_public_ip" {
  description = "Public IP of NIOS Grid Master (GM2) in us-east-1"
  value       = aws_eip.gm2_eip.public_ip
}
