provider "aws"{
	region = "ap-south-1"
	profile = "juzer"

}
resource "aws_vpc" "main" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "task_vpc"
  }
}
output "myvpcvar"{
    value=aws_vpc.main
}
resource "aws_subnet" "subnet1" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"

  tags = {
    Name = "tasksubnet1-1a"
  }
}
resource "aws_subnet" "subnet2" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "192.168.1.0/24"
  map_public_ip_on_launch = false
  availability_zone = "ap-south-1b"

  tags = {
    Name = "tasksubnet1-1b"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "taskigw"
  }
}
resource "aws_route_table" "taskroute" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "taskroute"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.taskroute.id
}
resource "tls_private_key" "test" {
  algorithm   = "RSA"
 
}
output "myop_tlskey"{
	value= tls_private_key.test 
}

resource "local_file" "web" {
    content     = tls_private_key.test.public_key_openssh
    filename = "mykey2.pem"
    file_permission = 0400
}
 
//Create new aws key_pair

resource "aws_key_pair" "test_key" {
  key_name   = "mykey2"
  public_key = tls_private_key.test.public_key_openssh

}


output "myop_key"{
	value= aws_key_pair.test_key

}

resource "aws_security_group" "terra_s" {
  name        = "wpsg"
  description = "Allow HTTP SSH inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "Allow SSH"
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
    Name = "allow_tcp"
  }
}

resource "aws_security_group" "terra1_s" {
  name        = "mysqlsg"
  description = "Allow MYSQL inbound traffic"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "Allow MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups  = ["${aws_security_group.terra_s.id}"]
  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_mysql"
  }
}

output "mysec"{
	value = aws_security_group.terra_s
}



resource "aws_instance" "myin" {
	
	ami           = "ami-06aa3ba6f5ce2f2d0"
	instance_type = "t2.micro"
	key_name = aws_key_pair.test_key.key_name
	vpc_security_group_ids  = ["${aws_security_group.terra_s.id}"]
        subnet_id = "${aws_subnet.subnet1.id}"

	tags = {
		Name = "WPOs"
  }
}

resource "aws_instance" "myin1" {
	
	ami           = "ami-08f51256df22d9a82"
	instance_type = "t2.micro"
	key_name = aws_key_pair.test_key.key_name
	vpc_security_group_ids  = ["${aws_security_group.terra1_s.id}"]
        subnet_id = "${aws_subnet.subnet2.id}"

	tags = {
		Name = "MySQLOs"
  }
}


