provider "aws" {
    region = "eu-north-1"
}

locals {
  alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    assign_generated_ipv6_cidr_block = true 
    tags = {
        Name = "${var.env}-vpc"
    }
}

resource "aws_egress_only_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
}

resource "aws_internet_gateway" "main" {
    vpc_id  = aws_vpc.main.id
    tags = {
        Name = "${var.env}-igw"
    }
}

#-------Public subnets with route table--------------------------

resource "aws_subnet" "public_subnets" {
    count                       = length(var.public_subnet_cidrs)
    vpc_id                      = aws_vpc.main.id
    cidr_block                  = element(var.public_subnet_cidrs, count.index)
#    ipv6_cidr_block             = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)
    availability_zone           = data.aws_availability_zones.available.names[0]
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.env}-Public-subnet-${element(local.alphabet, count.index)}"
    }
}

resource "aws_route_table" "public_subnets" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
    route {
        ipv6_cidr_block        = "::/0"
        gateway_id = aws_internet_gateway.main.id
    }
    tags = {
            Name = "${var.env}-route-Public-subnets"
        }
}

resource "aws_route_table_association" "public_routes" {
    count               = length(aws_subnet.public_subnets[*].id)
    route_table_id      = aws_route_table.public_subnets.id
    subnet_id           = element(aws_subnet.public_subnets[*].id, count.index)
}

#-------NAT gateways with EIP ------------------------------------

resource "aws_eip" "nat" {
    vpc     = true
    tags = {
        Name = "${var.env}-nat-gw"
    }
}

resource "aws_nat_gateway" "nat" {
    allocation_id   = aws_eip.nat.id
    subnet_id       = aws_subnet.private_subnets[0].id
    tags = {
        Name  = "${var.env}-nat-gw"
    }
}

#-------Private Subnets and Routes------------------------------------

resource "aws_subnet" "private_subnets" {
    count                       = length(var.private_subnet_cidrs)
    vpc_id                      = aws_vpc.main.id
    cidr_block                  = element(var.private_subnet_cidrs, count.index)
#    ipv6_cidr_block             = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 4, count.index)
    availability_zone           = data.aws_availability_zones.available.names[0]
    tags = {
        Name = "${var.env}-private-App-subnet-${element(local.alphabet, count.index)}"
    }
}

resource "aws_route_table" "private_subnets" {
    count           = length(var.private_subnet_cidrs)
    vpc_id          = aws_vpc.main.id
    route {
        cidr_block  = "0.0.0.0/0"
        gateway_id  = aws_nat_gateway.nat.id
    }
    route {
        ipv6_cidr_block        = "::/0"
        egress_only_gateway_id = aws_egress_only_internet_gateway.main.id
    }
        tags = {
            Name  = "${var.env}-route-private-App-subnet-${element(local.alphabet, count.index)}"
        }
}

resource "aws_route_table_association" "private_routes" {
    count           = length(aws_subnet.private_subnets[*].id)
    route_table_id  = aws_route_table.private_subnets[count.index].id
    subnet_id       = element(aws_subnet.private_subnets[*].id, count.index)
}
