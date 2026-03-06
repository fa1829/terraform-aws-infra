output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "ec2_public_ip" {
  description = "EC2 public IP — use this to SSH"
  value       = module.ec2.public_ip
}

output "ec2_public_dns" {
  description = "EC2 public DNS"
  value       = module.ec2.public_dns
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.bucket_name
}

output "ssh_command" {
  description = "Ready-to-run SSH command"
  value       = "ssh -i ${var.project_name}-key.pem ec2-user@${module.ec2.public_ip}"
}
