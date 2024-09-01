#Provider AWS
provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16" # Classless Inter-Domain Routing
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24" # Classless Inter-Domain Routing
  availability_zone = var.aws_az

  tags = {
    Name = "public"
  }
}

# Create a private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24" # Classless Inter-Domain Routing
  availability_zone = var.aws_az

  tags = {
    Name = "private"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# Create a route table public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Classless Inter-Domain Routing
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate the public subnet with the route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a route table private
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-route-table"
  }
}

# Associate the private subnet with the route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create a security group public (to the load balancer)
resource "aws_security_group" "public" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "public security group"
  }
}

# Create a security group private (to the instances EC2)
resource "aws_security_group" "private" {
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  tags = {
    Name = "private security group"
  }
}

# EC2 instance Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "app-template-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = "mykey" # trocar por um pair-key existente

  network_interfaces {
    security_groups             = [aws_security_group.private.id]
    associate_public_ip_address = false
  }

  tags = {
    Name = "app-instance"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  desired_capacity = 2
  max_size         = 3
  min_size         = 1
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }

  vpc_zone_identifier = [aws_subnet.private.id]
}

# Load Balancer
resource "aws_lb" "app" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public.id]
  subnets            = [aws_subnet.public.id]

  tags = {
    Name = "main"
  }
}

# Target Group
resource "aws_lb_target_group" "app" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }
}

# Listener
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.app.arn
    type             = "forward"
  }
}