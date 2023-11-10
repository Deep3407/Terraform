terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.56.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# creating VPC
resource "aws_vpc" "newvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "newvpc"
  }
}
# subnet creations
resource "aws_subnet" "publicsub" {
  vpc_id     = aws_vpc.newvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "publicsub"
  }
}

resource "aws_subnet" "privatesub" {
  vpc_id     = aws_vpc.newvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "privatesub"
  }
}
# intergateway creation
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.newvpc.id

  tags = {
    Name = "IGW"
  }
}
# Routeing table creation
resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.newvpc.id

  route = [
    {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.IGW.id
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      nat_gateway_id             = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    }
  ]
      tags = {
    Name = "publicRT"
  }
}

resource "aws_route_table" "privateRT" {
  vpc_id = aws_vpc.newvpc.id

  route = [
    {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.MYNAT.id
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      nat_gateway_id             = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    }
  ]
      tags = {
    Name = "privateRT"
  }
}

# subnet Association
resource "aws_route_table_association" "publicsubacc" {
  subnet_id      = aws_subnet.publicsub.id
  route_table_id = aws_route_table.publicRT.id
}

resource "aws_route_table_association" "privatesubacc" {
  subnet_id      = aws_subnet.privatesub.id
  route_table_id = aws_route_table.privateRT.id
}

#public security groups
resource "aws_security_group" "pubsec1" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.newvpc.id

  ingress = [
    {
      description      = "TLS from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
      }
  ]

   egress = [
    {
      description      = "ssh"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
      
    }
  ]

  tags = {
    Name = "pubsec1"
  }
}

resource "aws_eip" "myip" {
  #instance = aws_instance.web.id
  vpc      = true
}

#creating a NAT
resource "aws_nat_gateway" "MYNAT" {
  allocation_id = aws_eip.myip.id
  subnet_id     = aws_subnet.publicsub.id
  
  tags = {
    Name = "MYNAT"
  }
   
}

resource "aws_instance" "publicserver" {
  ami           = "ami-06fc49795bc410a0c"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.pubsec1.id}"]
  subnet_id = aws_subnet.publicsub.id
  associate_public_ip_address = true

  tags = {
    Name = "publicserver"
  }
}

