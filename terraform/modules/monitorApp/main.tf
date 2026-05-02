
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "monitor_app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile = var.iam_instance_profile_name
  
  # Quan trọng: Gán IAM Role để EC2 có quyền gọi DynamoDB, Athena, S3
  # iam_instance_profile = aws_iam_instance_profile.backend_profile.name

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker

              # Chạy Backend Container
              docker run -d \
                --name monitor-backend \
                -p 9000:9000 \
                ${join(" ", [for k, v in var.app_env_vars : "-e ${k}='${v}'"])} \
                your-docker-hub-username/fcaj-backend:latest
              EOF

  tags = {
    Name = "${var.project_name}-monitor-instance"
  }
}