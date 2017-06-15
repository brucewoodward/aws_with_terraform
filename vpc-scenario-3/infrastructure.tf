variable "region"     {
  description = "AWS region to use"
  default     = "us-west-2"
}

provider "aws" {
  profile = "learning"
  region = "us-west-2"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-west-2a"

  tags {
    Name = "Public subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2b"

  tags {
    Name = "Private subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "Public route table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id                = "${aws_subnet.public.id}"
  route_table_id           = "${aws_route_table.public.id}"
}

resource "aws_security_group" "webserver" {
  name        = "webserver"
  description = "webserver"
  vpc_id      = "${aws_vpc.default.id}"

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
}

resource "aws_security_group" "dbserver" {
  name        = "dbserver"
  description = "dbserver"
  vpc_id      = "${aws_vpc.default.id}"

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
}

resource "aws_key_pair" "webserver" {
  key_name   = "webserver"
  public_key = "${file("webserver_public_key")}"
}

resource "aws_key_pair" "dbserver" {
  key_name   = "dbserver"
  public_key = "${file("dbserver_public_key")}" 
}

resource "aws_instance" "webserver" {
  connection {
   user = "ubuntu"
   type = "ssh"
   private_key = "${file("webserver.pem")}"
  } 

  instance_type = "t2.micro"
  ami = "ami-17ba2a77"
  key_name = "${aws_key_pair.webserver.key_name}"

  vpc_security_group_ids = ["${aws_security_group.webserver.id}"]
  subnet_id = "${aws_subnet.public.id}"
  associate_public_ip_address = false
}

resource "aws_eip" "webserverip" {
  vpc = true
  instance = "${aws_instance.webserver.id}"
}

output "webserver public ip address" {
  value = "${aws_eip.webserverip.public_ip}"
}

resource "aws_instance" "dbserver" {
  connection {
    user = "ubuntu"
    type = "ssh"
    private_key = "${file("dbserver.pem")}"
  } 

  instance_type = "t2.micro"
  ami = "ami-17ba2a77"
  key_name = "${aws_key_pair.dbserver.key_name}"

  vpc_security_group_ids = ["${aws_security_group.dbserver.id}"]
  subnet_id = "${aws_subnet.private.id}"
  associate_public_ip_address = false
}
