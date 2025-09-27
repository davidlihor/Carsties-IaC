resource "aws_db_instance" "mysql" {
  identifier        = "bytecraft-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = "admin"
  password = "YourStrongPassword123!"
  db_name  = "accounts"

  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  parameter_group_name   = aws_db_parameter_group.mysql_pg.name
  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name        = "bytecraft-mysql"
    Project     = "ByteCraft"
    Environment = "dev"
  }
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "Allow MySQL access from EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  ingress {
    from_port       = 3306
    to_port         = 3306
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
    Name        = "mysql-sg"
    Project     = "ByteCraft"
    Environment = "dev"
  }
}

resource "aws_db_parameter_group" "mysql_pg" {
  name        = "bytecraft-mysql-pg"
  family      = "mysql8.0"
  description = "Parameter group for MySQL 8.0"

  tags = {
    Name        = "bytecraft-mysql-pg"
    Project     = "ByteCraft"
    Environment = "dev"
  }
}

resource "aws_db_subnet_group" "mysql" {
  name        = "bytecraft-mysql-sg"
  description = "Subnet group for MySQL 8.0"
  subnet_ids  = module.vpc.private_subnets

  tags = {
    Name        = "bytecraft-mysql-sg"
    Project     = "ByteCraft"
    Environment = "dev"
  }
}
