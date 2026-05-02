output "instance_public_ip" {
  value       = aws_instance.monitor_app.public_ip
  description = "Địa chỉ IP public để truy cập API"
}

output "instance_id" {
  value = aws_instance.monitor_app.id
}