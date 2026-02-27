# ===========================================================
# NIOS Grid Master #2 (GM2) - us-east-1
# Second independent NIOS grid, registered to same CSP tenant
# ===========================================================

locals {
  gm2_ami_id = "ami-00251cc14ee13cc21"
}

# --- VPC in us-east-1 ---

data "aws_availability_zones" "us_east_1" {
  provider = aws.us_east_1
  state    = "available"
}

resource "aws_vpc" "gm2" {
  provider             = aws.us_east_1
  cidr_block           = "10.200.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "gm2-vpc" }
}

resource "aws_subnet" "gm2_public" {
  provider                = aws.us_east_1
  vpc_id                  = aws_vpc.gm2.id
  cidr_block              = "10.200.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.us_east_1.names[0]
  tags = { Name = "gm2-public-subnet" }
}

resource "aws_internet_gateway" "gm2_gw" {
  provider = aws.us_east_1
  vpc_id   = aws_vpc.gm2.id
  tags     = { Name = "gm2-igw" }
}

resource "aws_route_table" "gm2_public" {
  provider = aws.us_east_1
  vpc_id   = aws_vpc.gm2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gm2_gw.id
  }
  tags = { Name = "gm2-public-rt" }
}

resource "aws_route_table_association" "gm2_public" {
  provider       = aws.us_east_1
  subnet_id      = aws_subnet.gm2_public.id
  route_table_id = aws_route_table.gm2_public.id
}

# --- Security Group ---

resource "aws_security_group" "gm2_sg" {
  provider    = aws.us_east_1
  name        = "gm2-nios-sg"
  description = "Allow HTTPS, DNS, SSH to NIOS GM2"
  vpc_id      = aws_vpc.gm2.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "gm2-nios-sg" }
}

# --- GM2 Network Interfaces ---

resource "aws_network_interface" "gm2_mgmt" {
  provider        = aws.us_east_1
  subnet_id       = aws_subnet.gm2_public.id
  private_ips     = ["10.200.0.10"]
  security_groups = [aws_security_group.gm2_sg.id]
  tags = { Name = "gm2-mgmt-nic" }
}

resource "aws_network_interface" "gm2_lan1" {
  provider        = aws.us_east_1
  subnet_id       = aws_subnet.gm2_public.id
  private_ips     = ["10.200.0.11"]
  security_groups = [aws_security_group.gm2_sg.id]
  tags = { Name = "gm2-lan1-nic" }
}

# --- GM2 EC2 Instance ---

resource "aws_instance" "gm2" {
  provider      = aws.us_east_1
  ami           = local.gm2_ami_id
  instance_type = "m5.2xlarge"
  key_name      = aws_key_pair.gm2_key.key_name

  network_interface {
    network_interface_id = aws_network_interface.gm2_mgmt.id
    device_index         = 0
  }
  network_interface {
    network_interface_id = aws_network_interface.gm2_lan1.id
    device_index         = 1
  }

  user_data = <<-EOF
#infoblox-config
temp_license: nios IB-V825 enterprise dns dhcp cloud
remote_console_enabled: y
default_admin_password: "${var.windows_admin_password}"
lan1:
  v4_addr: 10.200.0.11
  v4_netmask: 255.255.255.0
  v4_gw: 10.200.0.1
mgmt:
  v4_addr: 10.200.0.10
  v4_netmask: 255.255.255.0
  v4_gw: 10.200.0.1
EOF

  tags = { Name = "Infoblox-GM2" }

  depends_on = [aws_internet_gateway.gm2_gw]
}

# --- Key Pair for us-east-1 (keys are regional) ---

resource "aws_key_pair" "gm2_key" {
  provider   = aws.us_east_1
  key_name   = "instruqt-gm2-key"
  public_key = tls_private_key.rdp.public_key_openssh
}

# --- EIP for GM2 (attached to LAN1) ---

resource "aws_eip" "gm2_eip" {
  provider = aws.us_east_1
  domain   = "vpc"
  tags     = { Name = "gm2-eip" }
}

resource "aws_eip_association" "gm2_eip_assoc" {
  provider             = aws.us_east_1
  network_interface_id = aws_network_interface.gm2_lan1.id
  allocation_id        = aws_eip.gm2_eip.id
  private_ip_address   = "10.200.0.11"

  depends_on = [aws_instance.gm2]
}
