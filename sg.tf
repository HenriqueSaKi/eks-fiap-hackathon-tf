resource "aws_security_group" "sg" {
  name   = "SG-${var.appName}"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    description = "HTTP"
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

resource "aws_security_group" "cluster_sg" {
  name   = "Cluster-SG-${var.appName}"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort Services"
    from_port   = 30000
    to_port     = 32767
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

resource "aws_security_group" "eks_sg" {
  name   = "EKS-SG-${var.appName}"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
    description    = "Cluster HTTPS Access"
    from_port      = 443
    to_port        = 443
    protocol       = "tcp"
    security_groups = [aws_security_group.cluster_sg.id]
  }

  ingress {
    description    = "Node Communication"
    from_port      = 0
    to_port        = 65535
    protocol       = "tcp"
    cidr_blocks    = ["10.0.0.0/16"] # Adjusted to match VPC range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "nat-gateway-${var.appName}"
  }
}

resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "10.0.0.0/24"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id

  lifecycle {
    ignore_changes = [destination_cidr_block]
  }
}


resource "aws_route_table" "private_route_table" {
  vpc_id = data.aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "private-route-table-${var.appName}"
  }
}

resource "aws_route_table_association" "private_route_assoc" {
  count             = length(aws_subnet.private_subnets)
  subnet_id         = aws_subnet.private_subnets[count.index].id
  route_table_id    = aws_route_table.private_route_table.id
  depends_on        = [aws_nat_gateway.nat_gateway]
}


resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.vpc.id
  cidr_block              = "172.31.128.0/20"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${var.appName}"
  }
}

resource "aws_subnet" "private_subnets" {
  count                   = 2
  vpc_id                  = data.aws_vpc.vpc.id
  cidr_block              = element(["172.31.144.0/20", "172.31.160.0/20"], count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-${var.appName}-${count.index}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  tags = {
    Name = "igw-${var.appName}"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = data.aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "public-route-table-${var.appName}"
  }
}

resource "aws_route_table_association" "public_route_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}
