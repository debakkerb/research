// Networking resources
resource "aws_vpc" "bastion_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "bastion_subnet" {
  vpc_id            = aws_vpc.bastion_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.bastion_vpc.id
}

resource "aws_default_route_table" "public_internet_access" {
  default_route_table_id = aws_vpc.bastion_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  propagating_vgws = [
    aws_vpn_gateway.vpn_gateway.id
  ]
}

resource "aws_route_table_association" "default" {
  route_table_id = aws_vpc.bastion_vpc.default_route_table_id
  subnet_id      = aws_subnet.bastion_subnet.id
}

// Compute
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_security_group" "bastion_access" {
  name   = "bastion-ssh-access"
  vpc_id = aws_vpc.bastion_vpc.id

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = [
      "${var.public_ip_address}/32"
    ]
  }

}

resource "aws_key_pair" "ec2_access_key" {
  key_name   = "bastion_access_key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "bastion_host" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.small"
  key_name                    = aws_key_pair.ec2_access_key.id
  subnet_id                   = aws_subnet.bastion_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.bastion_access.id
  ]
}

// VPN Resources
resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = aws_vpc.bastion_vpc.id
}

resource "aws_customer_gateway" "customer_gateway_one" {
  bgp_asn    = google_compute_router.gcp_cr_gw.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.gcp_vpn_gateway.vpn_interfaces[0].ip_address
  type       = "ipsec.1"
}

resource "aws_customer_gateway" "customer_gateway_two" {
  bgp_asn    = google_compute_router.gcp_cr_gw.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.gcp_vpn_gateway.vpn_interfaces[1].ip_address
  type       = "ipsec.1"
}

resource "aws_vpn_connection" "vpn_conn_one" {
  customer_gateway_id = aws_customer_gateway.customer_gateway_one.id
  vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
  type                = "ipsec.1"
}

resource "aws_vpn_connection" "vpn_conn_two" {
  customer_gateway_id = aws_customer_gateway.customer_gateway_two.id
  vpn_gateway_id      =  aws_vpn_gateway.vpn_gateway.id
  type                = "ipsec.1"
}