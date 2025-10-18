output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security Group ID for EKS Cluster"
  value       = module.eks.cluster_security_group_id
}

output "instance_name" {
  description = "EC2 Instance Name"
  value       = aws_instance.ec2.tags["Name"]
}

output "instance_ami" {
  description = "EC2 Instance AMI"
  value       = aws_instance.ec2.ami
}

output "instance_public_ip" {
  description = "EC2 Instance Public IP"
  value       = aws_instance.ec2.public_ip
}

output "instance_private_ip" {
  description = "EC2 Instance Private IP"
  value       = aws_instance.ec2.private_ip
}

output "instance_security_group_id" {
  description = "Security Group IDs for EC2 Instance"
  value       = aws_instance.ec2.vpc_security_group_ids
}

output "current_region" {
  description = "Current AWS Region"
  value       = var.region
}