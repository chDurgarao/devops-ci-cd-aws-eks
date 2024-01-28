provider "aws" {
  region  = "ap-south-1"
  profile = "dev"
}

resource "aws_security_group" "dj_sg_test" {
  name        = "dj-sg-test"
  description = "SSH port 22"
  vpc_id      = aws_vpc.dj-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.204.110.48/32"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.1.1.0/24"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/24"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["49.204.105.93/32"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.204.105.93/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "dj-public-ec2" {
  ami                    = "ami-05cb6d413538e2d15"
  key_name               = "pemkey"
  subnet_id              = aws_subnet.dj-public-subnet-01.id
  vpc_security_group_ids = [aws_security_group.dj_sg_test.id]
#  for_each               = toset(["jenkins-master", "build-slave", "ansible"])
  for_each = var.instance_types
  instance_type          = each.value
  tags                   = {
    Name = "${each.key}"
  }
}


resource "aws_vpc" "dj-vpc" {
  cidr_block = "10.1.0.0/16"
  tags       = {
    Name = "dj_vpc"
  }
}

resource "aws_subnet" "dj-public-subnet-01" {
  vpc_id                  = aws_vpc.dj-vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1a"
  tags                    = {
    Name = "dj_public_subnet_01"
  }
}

resource "aws_subnet" "dj-public-subnet-02" {
  vpc_id                  = aws_vpc.dj-vpc.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "ap-south-1b"
  tags                    = {
    Name = "dj_public_subnet_02"
  }
}

resource "aws_internet_gateway" "dj-igw" {
  vpc_id = aws_vpc.dj-vpc.id
  tags   = {
    Name = "dj_igw"
  }
}

resource "aws_route_table" "dj-rt-public" {
  vpc_id = aws_vpc.dj-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dj-igw.id
  }
  tags = {
    Name = "dj_rt_public"
  }
}

resource "aws_route_table_association" "dj-rta-public-01" {
  route_table_id = aws_route_table.dj-rt-public.id
  subnet_id      = aws_subnet.dj-public-subnet-01.id
}
aws architecture
resource "aws_route_table_association" "dj-rta-public-02" {
  route_table_id = aws_route_table.dj-rt-public.id
  subnet_id      = aws_subnet.dj-public-subnet-02.id
}

module "sgs" {
  source = "../sg_eks"
  vpc_id = aws_vpc.dj-vpc.id
}

module "eks" {
  source     = "../eks"
  vpc_id     = aws_vpc.dj-vpc.id
  subnet_ids = [aws_subnet.dj-public-subnet-01.id, aws_subnet.dj-public-subnet-02.id]
  sg_ids     = module.sgs.security_group_public
}