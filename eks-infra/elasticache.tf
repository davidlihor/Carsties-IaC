resource "aws_elasticache_cluster" "redis" {
  cluster_id      = "carsties-redis"
  engine          = "redis"
  engine_version  = "7.1"
  node_type       = "cache.t3.micro"
  num_cache_nodes = 1
  port            = 6379

  parameter_group_name = aws_elasticache_parameter_group.redis_pg.name
  subnet_group_name    = aws_elasticache_subnet_group.redis_sg.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  tags = {
    Name        = "redis-cluster"
    Project     = var.projectName
    Environment = var.environment
  }
}

resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "Allow Redis access from EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = {
    Name        = "redis-security-group"
    Project     = var.projectName
    Environment = var.environment
  }
}

resource "aws_elasticache_parameter_group" "redis_pg" {
  name        = "carsties-redis-pg"
  family      = "redis7"
  description = "Parameter group for Redis 7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = {
    Name        = "redis-parameter-group"
    Project     = var.projectName
    Environment = var.environment
  }
}

resource "aws_elasticache_subnet_group" "redis_sg" {
  name        = "carsties-redis-sg"
  description = "Subnet group for Redis"
  subnet_ids  = module.vpc.private_subnets

  tags = {
    Name        = "redis-subnet-group"
    Project     = var.projectName
    Environment = var.environment
  }
}