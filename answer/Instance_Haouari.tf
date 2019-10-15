provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-1"
  access_key =  ""
  secret_key = ""
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


resource "aws_key_pair" "key_Haouari"{
key_name = "pkey"
public_key = ""
}

resource "aws_instance" "web" {
  vpc_security_group_ids = [
	"${aws_security_group.allow_ssh.id}"]
  subnet_id = "${aws_subnet.lgu_sn.id}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.key_Haouari.key_name}"
  tags = {
    Name = "HAOUARI Faysal"
  }
provisioner "remote-exec" {
    inline = [
	"sudo apt-get update -y",
	"sudo apt-get upgrade -y",
	"sudo apt install openjdk-7-jdk -y",
	"sudo apt install openjdk-7-jre -y",
	"sudo apt install maven -y",
	"sudo apt install git -y",
	"cd /home/ubuntu/Desktop",
	"git clone https://github.com/spring-projects/spring-petclinic.git",
	"sudo ufw allow 8080",
	"cd spring-petclinic",
	"export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64",
	"./mvnw package",
	"java -jar target/*.jar",
	"hostname -I"
]
	connection {
		type = "ssh"
		user = "ubuntu"
		host = "${self.public_ip}"
		private_key = "${file("")}"
	}
  }
}

resource "aws_vpc" "lgu_vpc"{
	cidr_block = "172.16.0.0/16"
	enable_dns_hostnames = true
	enable_dns_support = true

	tags = {
		Name = "lgu_vpc"
	}
}

resource "aws_subnet" "lgu_sn" {
	cidr_block = "${cidrsubnet(aws_vpc.lgu_vpc.cidr_block,3,1)}"
	vpc_id = "${aws_vpc.lgu_vpc.id}"
	availability_zone = "eu-west-1a"
	map_public_ip_on_launch = true

	tags = {
		Name = "lgu_sn"
	}
}

resource "aws_internet_gateway" "lgu_igw" {
	vpc_id = "${aws_vpc.lgu_vpc.id}"
}

resource "aws_route_table" "lgu_rt" {
	vpc_id = "${aws_vpc.lgu_vpc.id}"
	
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.lgu_igw.id}"
	}

	tags = {
		Name = "lgu_rt"
	}
}

resource "aws_route_table_association" "lgu_rta" {
	subnet_id = "${aws_subnet.lgu_sn.id}"
	route_table_id = "${aws_route_table.lgu_rt.id}"
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  vpc_id      = "${aws_vpc.lgu_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}