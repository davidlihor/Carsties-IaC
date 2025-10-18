resource "aws_db_instance" "postgres" {
  identifier        = "carsties-postgres"
  engine            = "postgres"
  engine_version    = "17.4"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  username = "postgres"
  password = "YourStrongPassword123!"
  db_name  = "keycloak"

  vpc_security_group_ids = [aws_security_group.postgres_sg.id]
  parameter_group_name   = aws_db_parameter_group.postgres_pg.name
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name        = "postgres-db-instance"
    Project     = var.projectName
    Environment = var.environment
  }
}

resource "aws_security_group" "postgres_sg" {
  name        = "postgres-sg"
  description = "Allow PostgreSQL access from EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "postgres-security-group"
    Project     = var.projectName
    Environment = var.environment
  }
}

resource "aws_db_parameter_group" "postgres_pg" {
  name        = "carsties-postgres-pg"
  family      = "postgres17"
  description = "Parameter group for PostgreSQL 17"

  tags = {
    Name        = "postgres-parameter-group"
    Project     = var.projectName
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "postgres" {
  name        = "carsties-postgres-subnet-group"
  description = "Subnet group for PostgreSQL"
  subnet_ids  = module.vpc.private_subnets

  tags = {
    Name        = "postgres-subnet-group"
    Project     = var.projectName
    Environment = var.environment
  }
}
