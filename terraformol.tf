terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
}

# Create private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2a"
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create public route for internet gateway
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
}

# Associate private subnet with private route table
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# Create security group for public instances
resource "aws_security_group" "public_security_group" {
  name        = "public-security-group"
  description = "Allow SSH, HTTP, and RDP"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_security_group" {
  name        = "private-security-group"
  description = "Allow inbound traffic from public instances"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    security_groups          = [aws_security_group.public_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create public linux EC2 instance
resource "aws_instance" "public_instance" {
  ami           = "ami-073858dcf4e30e586"  # Specify the appropriate AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public_security_group.id]
  key_name      = "windowseoul"  # Specify the name of your key pair
  associate_public_ip_address = true  # Assign a public IP to the instance
}
/*
# Create windows public EC2 instance
resource "aws_instance" "public_instance" {
  ami           = "ami-0001b82bb5ca55381"  # Specify the appropriate AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public_security_group.id]
  key_name      = "windowseoul"  # Specify the name of your key pair
  associate_public_ip_address = true  # Assign a public IP to the instance
}

# Create windows private EC2 instance
resource "aws_instance" "private_instance" {
  ami           = "ami-0001b82bb5ca55381"  # Specify the appropriate AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_security_group.id]
  key_name      = "windowseoul"  # Specify the name of your key pair
}
*/
 #Create private linux EC2 instance
resource "aws_instance" "private_instance" {
  ami           = "ami-073858dcf4e30e586"  # Specify the appropriate AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_security_group.id]
  key_name      = "windowseoul"  # Specify the name of your key pair
}

# Create NAT Gateway
resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

resource "aws_eip" "my_eip" {
  vpc = true
}

resource "aws_route" "private_route_to_internet" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway.id
}



#errors


Error: Invalid block definition
│ 
│   on vpcpeering.tf line 162, in resource "aws_nat_gateway" "my_nat_gateway":
│  162: s  allocation_id = aws_eip.my_eip.id
│ 
│ The equals sign "=" indicates an argument definition, and must not be used when defining a block.







│ Error: creating EC2 Subnet: InvalidParameterValue: Value (ap-northeast-2) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: ap-northeast-2a, ap-northeast-2b, ap-northeast-2c, ap-northeast-2d.
│       status code: 400, request id: 22e4fdbb-1a06-44b4-ab6b-08fe33c8fe16
│ 
│   with aws_subnet.public_subnet,
│   on newterraform.tf line 21, in resource "aws_subnet" "public_subnet":
│   21: resource "aws_subnet" "public_subnet" {
│ 
╵
╷
│ Error: creating EC2 Subnet: InvalidParameterValue: Value (ap-northeast-2) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: ap-northeast-2a, ap-northeast-2b, ap-northeast-2c, ap-northeast-2d.
│       status code: 400, request id: a8e5c4e6-0156-47e4-a5c2-07f0de0b97ce
│ 
│   with aws_subnet.private_subnet,
│   on newterraform.tf line 28, in resource "aws_subnet" "private_subnet":
│   28: resource "aws_subnet" "private_subnet" {
