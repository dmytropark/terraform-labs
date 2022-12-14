resource "aws_vpc" "main" {
  cidr_block           = "10.118.8.0/22"
  enable_dns_hostnames = true
  tags = {
    Name = "section-7-stage"
  }
}

# internal subnets
resource "aws_subnet" "internal-01" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.118.8.128/25"
  map_public_ip_on_launch = "false"
  availability_zone       = "eu-central-1a"
  tags = {
    Name = "internal-01"
  }

}

resource "aws_subnet" "internal-02" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.118.9.128/25"
  map_public_ip_on_launch = "false"
  availability_zone       = "eu-central-1b"
  tags = {
    Name = "internal-02"
  }

}

# public subnets
resource "aws_subnet" "external-01" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.118.8.0/25"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-central-1a"
  tags = {
    Name = "external-01"
  }

}

resource "aws_subnet" "external-02" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.118.9.0/25"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-central-1b"
  tags = {
    Name = "external-02"
  }

}


#internet gateway
resource "aws_internet_gateway" "stage-internet-gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "stage-internet-gw"
  }
}


# route table for public subnets
resource "aws_route_table" "rt-table-public-ig" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.stage-internet-gw.id
  }

  tags = {
    Name = "rt-stage-external"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "stage-nat-gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.external-01.id

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on    = [aws_internet_gateway.stage-internet-gw]
  
  tags = {
    Name = "stage-nat-gw"
  }
}

# route table for  NAT Gateway
resource "aws_route_table" "rt-stage-internal" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.stage-nat-gw.id}"
    }
 
    tags = {
        Name = "stage-nat-gw-route-table"
    }
}

# NAT Gateway route table association for internal subnet.
resource "aws_route_table_association" "stage-internal-01-rt-association" {
    subnet_id = "${aws_subnet.internal-01.id}"
    route_table_id = "${aws_route_table.rt-stage-internal.id}"
}

resource "aws_route_table_association" "stage-internal-02-rt-association" {
    subnet_id = "${aws_subnet.internal-02.id}"
    route_table_id = "${aws_route_table.rt-stage-internal.id}"
}

# NAT Gateway route table association for exteranal subnet.
resource "aws_route_table_association" "stage-external-01-rt-association" {
    subnet_id = "${aws_subnet.external-01.id}"
    route_table_id = "${aws_route_table.rt-table-public-ig.id}"
}

resource "aws_route_table_association" "stage-external-02-rt-association" {
    subnet_id = "${aws_subnet.external-02.id}"
    route_table_id = "${aws_route_table.rt-table-public-ig.id}"
}