# 1. Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Main"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main IGW"
  }
}

# 3. Create Public Subnets
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet ${each.key}"
  }
}

# 4. Create Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# 5. Associate Public Subnets with Route Table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# 6. Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

# 7. NAT Gateway (in public-1 subnet)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["public-1"].id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "NAT Gateway"
  }
}

# 8. Create App Private Subnets
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "Private Subnet ${each.key}"
  }
}

# 9. Create Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

# 10. Associate App Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# 11. Create DB Private Subnets
resource "aws_subnet" "db_private" {
  for_each = local.db_private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "DB Private Subnet ${each.key}"
  }
}

# 12. Create DB Private Route Table
resource "aws_route_table" "db_private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "DB Private Route Table"
  }
}

# 13. Associate DB Private Subnets with DB Route Table
resource "aws_route_table_association" "db_private" {
  for_each = aws_subnet.db_private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.db_private.id
}
