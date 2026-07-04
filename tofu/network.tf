# ── Public subnets (ALB + NAT Gateway) ──────────────────────────
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.owncloud_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "owncloud-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.owncloud_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "owncloud-public-b" }
}

# ── Private app subnets (EC2 / ASG) ─────────────────────────────
resource "aws_subnet" "private_app_a" {
  vpc_id            = aws_vpc.owncloud_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "owncloud-private-app-a" }
}

resource "aws_subnet" "private_app_b" {
  vpc_id            = aws_vpc.owncloud_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "owncloud-private-app-b" }
}

# ── Private data subnets (RDS + EFS) ────────────────────────────
resource "aws_subnet" "private_data_a" {
  vpc_id            = aws_vpc.owncloud_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "owncloud-private-data-a" }
}

resource "aws_subnet" "private_data_b" {
  vpc_id            = aws_vpc.owncloud_vpc.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "owncloud-private-data-b" }
}

# ── Internet Gateway ─────────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.owncloud_vpc.id
  tags   = { Name = "owncloud-igw" }
}

# ── Elastic IPs for NAT Gateways ────────────────────────────────
resource "aws_eip" "nat_a" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  tags       = { Name = "owncloud-nat-eip-a" }
}

resource "aws_eip" "nat_b" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  tags       = { Name = "owncloud-nat-eip-b" }
}

# ── NAT Gateways (one per AZ) ────────────────────────────────────
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "owncloud-nat-a" }
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "owncloud-nat-b" }
}

# ── Public route table ───────────────────────────────────────────
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.owncloud_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "owncloud-public-rt" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# ── Private route tables (each AZ routes to its own NAT) ─────────
resource "aws_route_table" "private_rt_a" {
  vpc_id = aws_vpc.owncloud_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
  tags = { Name = "owncloud-private-rt-a" }
}

resource "aws_route_table" "private_rt_b" {
  vpc_id = aws_vpc.owncloud_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }
  tags = { Name = "owncloud-private-rt-b" }
}

resource "aws_route_table_association" "private_app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

resource "aws_route_table_association" "private_app_b" {
  subnet_id      = aws_subnet.private_app_b.id
  route_table_id = aws_route_table.private_rt_b.id
}

resource "aws_route_table_association" "private_data_a" {
  subnet_id      = aws_subnet.private_data_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

resource "aws_route_table_association" "private_data_b" {
  subnet_id      = aws_subnet.private_data_b.id
  route_table_id = aws_route_table.private_rt_b.id
}