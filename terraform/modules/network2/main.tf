# --- VPC Mới cho Network 2 ---
resource "aws_vpc" "network2" {
  cidr_block           = var.vpc2_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { 
    Name    = "${var.project_name}-vpc-2"
    Network = "network2"
  }
}
data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_internet_gateway" "network2" {
  vpc_id = aws_vpc.network2.id
  tags   = { Name = "${var.project_name}-igw-2" }
}


resource "aws_subnet" "public2" {
  count                   = 2
  vpc_id                  = aws_vpc.network2.id

  cidr_block              = cidrsubnet(var.vpc2_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = var.enable_public_ip

  tags = { Name = "${var.project_name}-public-sn-2-${count.index}" }
}


resource "aws_route_table" "public2" {
  vpc_id = aws_vpc.network2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.network2.id
  }

  tags = { Name = "${var.project_name}-public-rt-2" }
}

resource "aws_route_table_association" "public2" {
  count          = 2
  subnet_id      = aws_subnet.public2[count.index].id
  route_table_id = aws_route_table.public2.id
}

resource "aws_security_group" "ec2_backend_sg" {
  name        = "${var.project_name}-backend-sg-${var.backend_port}"
  description = "Security Group cho Backend Python port ${var.backend_port}"
  vpc_id      = aws_vpc.network2.id


  ingress {
    from_port   = var.backend_port
    to_port     = var.backend_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-${var.backend_port}" }
}