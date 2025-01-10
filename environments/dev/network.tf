## VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

# For External ALB
resource "aws_subnet" "example1" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.50.0/24"
  availability_zone = "ap-northeast-1a"
}

resource "aws_subnet" "example2" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.60.0/24"
  availability_zone = "ap-northeast-1c"
}

# For internal ALB
resource "aws_subnet" "example3" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.70.0/24"
  availability_zone = "ap-northeast-1a"
}

resource "aws_subnet" "example4" {
  vpc_id            = aws_vpc.example.id
  cidr_block        = "10.0.80.0/24"
  availability_zone = "ap-northeast-1c"
}

# internet gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
}

# route table
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
}

# route table association
resource "aws_route_table_association" "example1" {
  subnet_id      = aws_subnet.example1.id
  route_table_id = aws_route_table.example.id
}

resource "aws_route_table_association" "example2" {
  subnet_id      = aws_subnet.example2.id
  route_table_id = aws_route_table.example.id
}
