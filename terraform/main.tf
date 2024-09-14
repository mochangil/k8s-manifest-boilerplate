provider "aws" {
  region = "ap-northeast-2"
}

# 1. VPC 생성
resource "aws_vpc" "main" {
  cidr_block = "192.170.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name        = "main-vpc"
  }
}

# 2. 서브넷 생성 (퍼블릭 서브넷 1, 프라이빗 서브넷 1)
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.170.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-northeast-2a"

  tags = {
    Name        = "public-subnet-1"
  }
}


resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.170.2.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name        = "private-subnet-1"
  }
}

# 3. 퍼블릭 라우트 테이블 생성 및 연결
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "public-route-table"
  }
}

# 3-1. 퍼블릭 서브넷을 라우트 테이블과 연결
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

# 4. Internet Gateway 생성
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "main-internet-gateway"
  }
}

# 4-1. 퍼블릭 서브넷이 인터넷 게이트웨이를 통해 외부와 통신할 수 있도록 라우트 설정
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# 4-2. NAT Gateway 생성
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name        = "nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name        = "main-nat-gateway"
  }
}

# 4-3. 프라이빗 서브넷 라우트 테이블 생성 및 NAT Gateway 연결
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "private-route-table"
  }
}

resource "aws_route" "private_nat_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private.id
}

# 5. 노드 스펙 및 보안 그룹 설정은 eksctl에서 관리할 예정

# 6. 보안 그룹 생성
resource "aws_security_group" "eks_security_group" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name        = "eks-security-group"
  }
}