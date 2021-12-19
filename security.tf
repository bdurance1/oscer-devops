
# Restrict access to the application.
resource "aws_security_group" "alb" {
  name        = "alb_security_group"
  description = "Controls access to the ALB"
  vpc_id      = aws_vpc.vpc_dev.id

  ingress {
    protocol    = "tcp"
    from_port   = var.app_port
    to_port     = var.app_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}


# Restrict inbound traffic to the ECS Cluster i.e. must originate from the ALB.
resource "aws_security_group" "ecs_tasks" {
  name        = "ecs_tasks_security_group"
  description = "Contorls access to the ECS cluster"
  vpc_id      = aws_vpc.vpc_dev.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port
    to_port         = var.app_port
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-security-group"
  }
}

