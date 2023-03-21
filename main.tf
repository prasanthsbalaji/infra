resource "aws_vpc" "demo-vpc" { //vpc creation
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "int-demo-vpc"
  }
}
resource "aws_internet_gateway" "igw" { //IG Creation
  vpc_id = aws_vpc.demo-vpc.id
}
resource "aws_route_table" "public_route_table" { //Route Table for IG
  vpc_id = aws_vpc.demo-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public Route Table"
  }
}
resource "aws_route_table_association" "public_route_table_association_subnet_1" { //Public Route Table Association for subnet-1
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_subnet" "public1" { //public subnet 1
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "int-demo-public1-subnet"
  }
}
resource "aws_subnet" "public100" { //public subnet 1
  vpc_id            = aws_vpc.demo-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "int-demo-public100-subnet"
  }
}
resource "aws_instance" "public" { //instance 1
  ami                         = "ami-0557a15b87f6559cf"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2_1_sg.id]
  user_data     = <<-EOF
                  #!/bin/bash
                  sudo apt-get update
                  sudo apt-get install -y nginx
                  EOF
  tags = {
    Name = "int-demo-ec2-1"
  }
}
resource "aws_security_group" "ec2_1_sg" { //ec2 1 security group
  name_prefix = "ec2-1"
  vpc_id      = aws_vpc.demo-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

}

resource "aws_instance" "public2" { //instance 2
  ami                         = "ami-0557a15b87f6559cf"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2_2_sg.id]
  user_data     = <<-EOF
                  #!/bin/bash
                  mkdir newfile
                  EOF
  tags = {
    Name = "int-demo-ec2-2"
  }
}
resource "aws_security_group" "ec2_2_sg" { //ec2 1 security group
  name_prefix = "ec2-2"
  vpc_id      = aws_vpc.demo-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

}

resource "aws_lb" "demo-alb" { //ALB Creation
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public1.id,aws_subnet.public100.id]
  tags = {
    Name = "int-demo-alb"
  }
}
resource "aws_security_group" "alb_sg" { //alb security group
  name_prefix = "alb"
  vpc_id      = aws_vpc.demo-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_lb_target_group" "private_subnet_target_group" { //target group for alb
  name     = "target-group-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo-vpc.id

}
resource "aws_lb_listener" "demo_listener" { // Listener Creation
  load_balancer_arn = aws_lb.demo-alb.id
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_subnet_target_group.arn
  }
}
resource "aws_lb_target_group_attachment" "demo_attachment_1" { //Target group attachement to ec2 1
  target_group_arn = aws_lb_target_group.private_subnet_target_group.arn
  target_id        = aws_instance.public.id
}
resource "aws_lb_target_group_attachment" "demo_attachment_2" { //Target group attachment to ec2 2
  target_group_arn = aws_lb_target_group.private_subnet_target_group.arn
  target_id        = aws_instance.public2.id
}
