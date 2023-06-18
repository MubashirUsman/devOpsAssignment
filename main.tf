#Provider block
provider "aws" {
  profile = "default"
  region = "us-east-1"
}

#Resource blocks
#create vpc
resource "aws_vpc" "terraformVpc" {
    cidr_block = "192.168.0.0/22"
    tags = {
      Name = "terraformVPC"
    }
}

#variable for availability zones
variable "azs" {
    type = list(string)
    description = "Availability zones"
    default = [ "us-east-1a", "us-east-1b" ]
}

#create subnets
resource "aws_subnet" "privateSubnet" {
  vpc_id = aws_vpc.terraformVpc.id
  cidr_block = "192.168.0.0/23"
  availability_zone = element(var.azs, 0)

  tags = {
    Name = "privateSubet"
  }
}
resource "aws_subnet" "publicSubnet" {
  vpc_id = aws_vpc.terraformVpc.id
  cidr_block = "192.168.2.0/23"
  availability_zone = element(var.azs, 1)

  tags = {
    Name = "publicSubet"
  }
}

#Internet gateway
resource "aws_internet_gateway" "terraformVpcGateway" {
    vpc_id = aws_vpc.terraformVpc.id

    tags = {
      Name ="terraformVpcGateway"
    }
}

#Elastic IP for nat gateway
resource "aws_eip" "forNat" {
  depends_on = [ aws_internet_gateway.terraformVpcGateway ]

}

#nat gateway
resource "aws_nat_gateway" "natGateway" {
  allocation_id = aws_eip.forNat.id
  subnet_id = aws_subnet.publicSubnet.id #public subnet in which nat gateway is present

  tags = {
    Name = "natGateway"
  }

}

#Route tables for public subnet
resource "aws_route_table" "publicRouteTable" {
    vpc_id = "${aws_vpc.terraformVpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.terraformVpcGateway.id}"
             
        }

      route {
        ipv6_cidr_block = "::/0"
        gateway_id = "${aws_internet_gateway.terraformVpcGateway.id}"

      }

    tags = {
      Name = "publicRoutetable"
    }
}

#Route table for private subnet
resource "aws_route_table" "privateRouteTable" {
    vpc_id = "${aws_vpc.terraformVpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.natGateway.id}"
             
        }

      #route {
      #  ipv6_cidr_block = "::/0"
      #  nat_gateway_id = "${aws_nat_gateway.natGateway.id}"

      #}

    tags = {
      Name = "privateRoutetable"
    }
}

#Route table association for public subnet
resource "aws_route_table_association" "rtAssociationPublic" {
    subnet_id = aws_subnet.publicSubnet.id
    route_table_id = aws_route_table.publicRouteTable.id

}

#Route table association for private subnet
resource "aws_route_table_association" "rtAssociationPrivate" {
    subnet_id = aws_subnet.privateSubnet.id
    route_table_id = aws_route_table.privateRouteTable.id

}

#Secuirty group
resource "aws_security_group" "tfVpcSecurityGroup" {
    name = "tfVpcSecurityGroup"
    description = "Allow TLS inbound traffic"
    vpc_id = aws_vpc.terraformVpc.id

    ingress = [
    {
        description = "Allowing SSH for incoming traffic"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        prefix_list_ids = []
        security_groups = []
        self = false
        }
    ]
    egress = [
    {
        description = "for outgoing traffic"
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
        prefix_list_ids = []
        security_groups = []
        self = false
        }
    ]
    tags = {
      Name = "security group ec2"
    }
}

#create EC2 in public subnet
resource "aws_instance" "ec2InPublic" {
  ami = "ami-022e1a32d3f742bd8"
  key_name = aws_key_pair.key_tf.key_name
  associate_public_ip_address = true
  instance_type = "t2.micro"
  subnet_id = aws_subnet.publicSubnet.id
  vpc_security_group_ids = [aws_security_group.tfVpcSecurityGroup.id]

}

#Return EC2 public IP
output "ec2_public_ip" {
    value = aws_instance.ec2InPublic.public_ip
} 