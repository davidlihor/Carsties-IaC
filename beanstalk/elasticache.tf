resource "aws_elasticache_cluster" "memcached" {
  cluster_id      = "bytecraft-memcached"
  engine          = "memcached"
  engine_version  = "1.6.17"
  node_type       = "cache.t3.micro"
  num_cache_nodes = 1
  port            = 11211

  parameter_group_name = aws_elasticache_parameter_group.memcached_pg.name
  subnet_group_name    = aws_elasticache_subnet_group.memcached.name
  security_group_ids   = [aws_security_group.memcached_sg.id]

  tags = {
    Name        = "bytecraft-memcached"
    Project     = "ByteCraft"
    Environment = "dev"
  }
}

resource "aws_security_group" "memcached_sg" {
  name        = "memcached-sg"
  description = "Allow Memcached access from EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 11211
    to_port         = 11211
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
    Name        = "memcached-sg"
    Project     = "ByteCraft"
    Environment = "dev"
  }
}

resource "aws_elasticache_parameter_group" "memcached_pg" {
  name        = "bytecraft-memcached-pg"
  family      = "memcached1.6"
  description = "Parameter group for Memcached 1.6"

  parameter {
    name  = "chunk_size"
    value = "64"
  }

  parameter {
    name  = "cas_disabled"
    value = "1"
  }

  parameter {
    name  = "memcached_connections_overhead"
    value = "200"
  }

  tags = {
    Name        = "bytecraft-memcached-pg"
    Project     = "ByteCraft"
    Environment = "dev"
  }
}

resource "aws_elasticache_subnet_group" "memcached" {
  name        = "bytecraft-memcached-sg"
  description = "Subnet group for Memcached 1.6"
  subnet_ids  = module.vpc.private_subnets

  tags = {
    Name        = "bytecraft-memcached-sg"
    Project     = "ByteCraft"
    Environment = "dev"
  }
}