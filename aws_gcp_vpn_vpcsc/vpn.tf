resource "aws_vpn_gateway" "gcp_vpn_gateway" {
  vpc_id            = aws_vpc.default.id
  availability_zone = aws_subnet.default.availability_zone_id
}