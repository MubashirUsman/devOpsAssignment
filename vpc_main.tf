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

#Route tables for public
resource "aws_route_table" "publicRouteTable" {
    vpc_id = "${aws_vpc.terraformVpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.terraformVpcGateway.id}"
        #attributes     
        }

      route {
        ipv6_cidr_block = "::/0"
        gateway_id = "${aws_internet_gateway.terraformVpcGateway.id}"

      }

    tags = {
      Name = "publicRoutetable"
    }
}

#Route table association
resource "aws_route_table_association" "rtAssociationPublic" {
    subnet_id = aws_subnet.publicSubnet.id
    route_table_id = aws_route_table.publicRouteTable.id

}

#Secuirty group
resource "aws_security_group" "tfVpcSecurityGroup" {
    name = "tfVpcSecurityGroup"
    description = "Allow TLS inbound traffic"
    vpc_id = aws_vpc.terraformVpc.id

    ingress = [
    {
        description = "SSH"
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

#EC2
resource "aws_instance" "ec2InPublic" {
  ami = "ami-022e1a32d3f742bd8"
  key_name = aws_key_pair.key_tf.key_name
  associate_public_ip_address = true
  instance_type = "t2.micro"
  subnet_id = aws_subnet.publicSubnet.id
  vpc_security_group_ids = [aws_security_group.tfVpcSecurityGroup.id]

}

#Return EC2 IP
output "ec2_public_ip" {
    value = aws_instance.ec2InPublic.public_ip
} 