###############################################
# OUTPUTS — Kubernetes Cluster EC2 Information
###############################################

output "control_plane_public_ip" {
  description = "Public IP of the Kubernetes control-plane node"
  value       = aws_instance.control_plane.public_ip
}

output "control_plane_private_ip" {
  description = "Private IP of the Kubernetes control-plane node"
  value       = aws_instance.control_plane.private_ip
}

output "worker_nodes_public_ips" {
  description = "List of public IPs of the Kubernetes worker nodes"
  value       = aws_instance.worker_nodes[*].public_ip
}

output "worker_nodes_private_ips" {
  description = "List of private IPs of the Kubernetes worker nodes"
  value       = aws_instance.worker_nodes[*].private_ip
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the created public subnets"
  value       = aws_subnet.public[*].id
}

