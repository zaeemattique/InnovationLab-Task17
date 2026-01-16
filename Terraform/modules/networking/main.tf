resource "aws_vpc" "Task17-VPC-Zaeem" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Task17-VPC-Zaeem"
  }
}

resource "aws_internet_gateway" "Task17-IGW-Zaeem" {
  vpc_id = aws_vpc.Task17-VPC-Zaeem.id

  tags = {
    Name = "$Task17-VPC-Zaeem"
  }
}

resource "aws_subnet" "Task17-Public-SN-A-Zaeem" {
  vpc_id                  = aws_vpc.Task17-VPC-Zaeem.id
  cidr_block              = var.public_sna_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Task17-${var.cluster_name}-Public-SN-A-Zaeem"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/cluster/Task17-EKS-Cluster-Zaeem" = "shared"
  }
}

resource "aws_subnet" "Task17-Public-SN-B-Zaeem" {
  vpc_id                  = aws_vpc.Task17-VPC-Zaeem.id
  cidr_block              = var.public_snb_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Task17-${var.cluster_name}-Public-SN-A-Zaeem"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/cluster/Task17-EKS-Cluster-Zaeem" = "shared"
  }
}

resource "aws_subnet" "Task17-Private-SN-A-Zaeem" {
  vpc_id            = aws_vpc.Task17-VPC-Zaeem.id
  cidr_block        = var.private_sna_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "Task17-${var.cluster_name}-Private-SN-A-Zaeem"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/cluster/Task17-EKS-Cluster-Zaeem" = "shared"

  }
}

resource "aws_subnet" "Task17-Private-SN-B-Zaeem" {
  vpc_id            = aws_vpc.Task17-VPC-Zaeem.id
  cidr_block        = var.private_snb_cidr
  availability_zone = "us-east-1b"

  tags = {
    Name = "Task17-${var.cluster_name}-Private-SN-B-Zaeem"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/cluster/Task17-EKS-Cluster-Zaeem" = "shared"

  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "Task17-NGW-Zaeem" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.Task17-Public-SN-A-Zaeem.id

  tags = {
    Name = "Task17-${var.cluster_name}-NGW-Zaeem"
  }
}

resource "aws_route_table" "Task17-Public-RT-Zaeem" {
  vpc_id = aws_vpc.Task17-VPC-Zaeem.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Task17-IGW-Zaeem.id
  }

  tags = {
    Name = "Task17-${var.cluster_name}-Public-RT-Zaeem"
  }
}

resource "aws_route_table" "Task17-Private-RT-Zaeem" {
  vpc_id = aws_vpc.Task17-VPC-Zaeem.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Task17-NGW-Zaeem.id
  }

  tags = {
    Name = "Task17-${var.cluster_name}-Private-RT-Zaeem"
  }
}

resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.Task17-Public-SN-A-Zaeem.id
  route_table_id = aws_route_table.Task17-Public-RT-Zaeem.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.Task17-Public-SN-B-Zaeem.id
  route_table_id = aws_route_table.Task17-Public-RT-Zaeem.id
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.Task17-Private-SN-A-Zaeem.id
  route_table_id = aws_route_table.Task17-Private-RT-Zaeem.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.Task17-Private-SN-B-Zaeem.id
  route_table_id = aws_route_table.Task17-Private-RT-Zaeem.id
}
