data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "Infoblox-Lab" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.100.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = { Name = "public-subnet" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.100.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = { Name = "public-subnet-b" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# --- Security Groups ---

resource "aws_security_group" "rdp_sg" {
  name        = "allow_rdp"
  description = "Allow RDP, HTTPS, DNS, SSH to client VM"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rdp-sg"
  }
}

# --- TLS Key Pair ---

resource "tls_private_key" "rdp" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "rdp" {
  key_name   = "instruqt-dc-key"
  public_key = tls_private_key.rdp.public_key_openssh
}

resource "local_sensitive_file" "private_key_pem" {
  filename        = "./instruqt-dc-key.pem"
  content         = tls_private_key.rdp.private_key_pem
  file_permission = "0400"
}

# ===========================================================
# NIOS Grid Master (GM1) - eu-central-1
# ===========================================================

locals {
  gm_ami_id = "ami-0038ccc4c1a0034fb"
}

# --- GM Management Network Interface (10.100.0.10) ---
resource "aws_network_interface" "gm_mgmt" {
  subnet_id       = aws_subnet.public.id
  private_ips     = ["10.100.0.10"]
  security_groups = [aws_security_group.rdp_sg.id]
  tags = { Name = "gm-mgmt-nic" }
}

# --- GM LAN1 Network Interface (10.100.0.11) - must be same AZ as MGMT ---
resource "aws_network_interface" "gm_lan1" {
  subnet_id       = aws_subnet.public.id
  private_ips     = ["10.100.0.11"]
  security_groups = [aws_security_group.rdp_sg.id]
  tags = { Name = "gm-lan1-nic" }
}

# --- GM EC2 Instance ---
resource "aws_instance" "gm" {
  ami           = local.gm_ami_id
  instance_type = "m5.2xlarge"
  key_name      = aws_key_pair.rdp.key_name

  network_interface {
    network_interface_id = aws_network_interface.gm_mgmt.id
    device_index         = 0
  }
  network_interface {
    network_interface_id = aws_network_interface.gm_lan1.id
    device_index         = 1
  }

  user_data = <<-EOF
#infoblox-config
temp_license: nios IB-V825 enterprise dns dhcp cloud
remote_console_enabled: y
default_admin_password: "${var.windows_admin_password}"
lan1:
  v4_addr: 10.100.0.11
  v4_netmask: 255.255.255.0
  v4_gw: 10.100.0.1
mgmt:
  v4_addr: 10.100.0.10
  v4_netmask: 255.255.255.0
  v4_gw: 10.100.0.1
EOF

  tags = { Name = "Infoblox-GM" }

  depends_on = [aws_internet_gateway.gw]
}

# --- EIP for GM (attached to LAN1 for external access) ---
resource "aws_eip" "gm_eip" {
  domain = "vpc"
  tags   = { Name = "gm-eip" }
}

resource "aws_eip_association" "gm_eip_assoc" {
  network_interface_id = aws_network_interface.gm_lan1.id
  allocation_id        = aws_eip.gm_eip.id
  private_ip_address   = "10.100.0.11"

  depends_on = [aws_instance.gm]
}
