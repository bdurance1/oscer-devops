
# TODO: 
# 1. set up flow log for network visibiltiy, trouble shooting and analyzing 
# traffic flows.
# 2. netwrok integration testing.

# Fetch AZs
data "aws_availability_zones" "available" {
}

# Create VPC
resource "aws_vpc" "vpc_dev" {
  cidr_block = "172.15.0.0/16"

  tags = {
    Name = "vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_dev.id

  tags = {
    Name = "igw"
  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "add_route" {
  route_table_id = aws_vpc.vpc_dev.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

# Create public subnets
resource "aws_subnet" "public" {
  count = var.az_count
  cidr_block = cidrsubnet(aws_vpc.vpc_dev.cidr_block, 8, var.az_count + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id = aws_vpc.vpc_dev.id
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_public_${count.index}"
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count = var.az_count
  cidr_block = cidrsubnet(aws_vpc.vpc_dev.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id = aws_vpc.vpc_dev.id

  tags = {
    Name = "subnet_private_${count.index}"
  }
}

# Create a NAT gateway with an Elastic IP 
resource "aws_eip" "ngw_eip" {
  count = var.az_count
  vpc = true
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "ngw_eip_${count.index}"
  }
}

resource "aws_nat_gateway" "ngw" {
  count = var.az_count
  subnet_id = element(aws_subnet.public.*.id, count.index)
  allocation_id = element(aws_eip.ngw_eip.*.id, count.index)

    tags = {
      Name = "ngw_${count.index}"
  }
}

# Create route table for private subnets, route traffic through the NAT gateway
resource "aws_route_table" "private" {
  count = var.az_count
  vpc_id = aws_vpc.vpc_dev.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.ngw.*.id, count.index)
  }

  tags = {
    Name = "route_table_${count.index}"
  }
}

# Associate route tables to the private subnets
resource "aws_route_table_association" "private" {
  count = var.az_count
  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}
