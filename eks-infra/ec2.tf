resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  key_name                    = "web-key"
  associate_public_ip_address = true

  tags = {
    Name        = local.instance_name
    Project     = var.projectName
    Environment = var.environment
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "carsties-ec2-sg"
  description = "Allow SSH and Web access to EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from my IP"
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

  tags = {
    Name        = "ec2-security-group"
    Project     = var.projectName
    Environment = var.environment
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
