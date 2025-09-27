resource "aws_mq_broker" "rabbitmq" {
  broker_name                = "bytecraft-rabbitmq"
  engine_type                = "RabbitMQ"
  engine_version             = "3.13"
  host_instance_type         = "mq.t3.micro"
  publicly_accessible        = false
  auto_minor_version_upgrade = true

  subnet_ids      = [module.vpc.private_subnets[0]]
  security_groups = [aws_security_group.rabbitmq_sg.id]

  user {
    username = "admin"
    password = "YourStrongPassword123!"
  }

  logs {
    general = true
    audit   = false
  }

  tags = {
    Name        = "bytecraft-rabbitmq"
    Project     = "ByteCraft"
    Environment = "dev"
  }

  lifecycle {
    ignore_changes = [
      tags,
      tags_all
    ]
  }
}

resource "aws_security_group" "rabbitmq_sg" {
  name        = "rabbitmq-sg"
  description = "Allow Memcached access from EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5671
    to_port         = 5671
    protocol        = "tcp"
    security_groups = [aws_security_group.beanstalk_ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "rabbitmq-sg"
    Project     = "ByteCraft"
    Environment = "dev"
  }
}
