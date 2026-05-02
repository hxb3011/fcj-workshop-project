output "vpc2_id" {
  value = aws_vpc.network2.id
}

output "public2_subnet_ids" {
  value = aws_subnet.public2[*].id
}

output "backend_sg_id" {
  value = aws_security_group.ec2_backend_sg.id
}