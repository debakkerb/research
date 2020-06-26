resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "default" {
  vpc_id            = aws_vpc.default.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-west-1a"
}

resource "aws_security_group" "allow_ssh_access" {
  name   = "ssh-access"
  vpc_id = aws_vpc.default.id

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["86.175.196.169/32"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "default" {
  ami                         = "ami-02c4e2ce5b03c9ee9"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.default.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh_access.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh_key_pair.key_name
}

resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "publicKey"
  public_key = file(var.public_key_path)
}

resource "aws_internet_gateway" "public_access" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "public_access_routes" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_access.id
  }
}

resource "aws_route_table_association" "public_access" {
  route_table_id = aws_route_table.public_access_routes.id
  subnet_id      = aws_subnet.default.id
}

resource "aws_vpn_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_vpn_gateway_route_propagation" "default" {
  route_table_id = aws_route_table.public_access_routes.id
  vpn_gateway_id = aws_vpn_gateway.default.id
}

resource "aws_customer_gateway" "google" {
  bgp_asn    = 65000
  ip_address = ""
  type       = "ipsec.1"
}




