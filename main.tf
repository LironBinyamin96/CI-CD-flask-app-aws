provider "aws" {
  region = var.region
}

# Reference existing VPC, subnets, ECS cluster, and ALB
data "aws_vpc" "existing_vpc" {
  id = var.vpc_id
}

data "aws_subnet" "subnet_a" {
  id = var.subnet_private_1
}

data "aws_subnet" "subnet_b" {
  id = var.subnet_private_2
}

data "aws_ecs_cluster" "existing_cluster" {
  cluster_name = var.cluster_name
}

data "aws_lb" "existing_lb" {
  name = var.aws_lb_name
}

# IAM Roles for ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsExecutionRole-liron"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole-liron-flask"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "flask_integration_task" {
  family                   = "flask-integration-task-liron-tf"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  container_definitions = jsonencode([{
    name      = "flask"
    image     = "314525640319.dkr.ecr.il-central-1.amazonaws.com/liron-repo:14"

    essential = true
    portMappings = [{
      containerPort = 5000
      protocol      = "tcp"
    }]
  }])
}

# Target Group on port 100, forwarding to container port 200
resource "aws_lb_target_group" "flask_target_group" {
  name        = "flask-app-liron-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.existing_vpc.id
  target_type = "ip"
  health_check {
    protocol = "HTTP"
    port     = "5000"
    path     = "/"
  }
}

# Listener on port 100 in the existing ALB
resource "aws_lb_listener" "flask_listener" {
  load_balancer_arn = data.aws_lb.existing_lb.arn
  port              = 5000
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_target_group.arn
  }
}

# ECS Service that uses the Task Definition and Target Group
resource "aws_ecs_service" "flask_service" {
  name            = "flask-service-liron"
  cluster         = data.aws_ecs_cluster.existing_cluster.id
  task_definition = aws_ecs_task_definition.flask_integration_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [data.aws_subnet.subnet_a.id, data.aws_subnet.subnet_b.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.flask_target_group.arn
    container_name   = "flask"
    container_port   = 5000
  }
  depends_on = [
    aws_lb_listener.flask_listener
  ]
}
