#This Terraform Code Deploys Basic VPC Infra.
provider "aws" {
  region = "${var.aws_region}"
}

terraform {
  backend "s3" {
    bucket = "balaterraformbucket"
    key = "function.tfstate"
    region = "us-east-1"
  }
}

resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}"
    Owner = local.Owner
    costcenter = local.costcenter
    TeamDL = local.TeamDL
    environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags = {
    Name = "${var.vpc_name}-IGW"
  }
}

resource "aws_subnet" "public-subnet" {
#  count = 3
  count = "${length(var.public_cidr_block)}"
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${element(var.public_cidr_block, count.index+1)}"
  availability_zone = "${element(var.azs, count.index)}"
  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index+1}"
    Owner = local.Owner
    costcenter = local.costcenter
    TeamDL = local.TeamDL
    environment = "${var.environment}"
  }
}

resource "aws_subnet" "private-subnet" {
#  count = 3
  count = "${length(var.private_cidr_block)}"
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${element(var.private_cidr_block, count.index+1)}"
  availability_zone = "${element(var.azs, count.index)}"
  tags = {
    Name = "${var.vpc_name}-private-subnet-${count.index+1}"
    Owner = local.Owner
    costcenter = local.costcenter
    TeamDL = local.TeamDL
    environment = "${var.environment}"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
  tags = {
    Name = "${var.vpc_name}-public-RT"
    Owner = local.Owner
    costcenter = local.costcenter
    TeamDL = local.TeamDL
    environment = "${var.environment}"
  }
}

resource "aws_route_table" "private-route-table" {
  vpc_id = "${aws_vpc.default.id}"
  tags = {
    Name = "${var.vpc_name}-private-RT"
    Owner = local.Owner
    costcenter = local.costcenter
    TeamDL = local.TeamDL
    environment = "${var.environment}"
  }
}

resource "aws_route_table_association" "public-subnets-RT-Association" {
  count = "${length(var.public_cidr_block)}"
  subnet_id = "${element(aws_subnet.public-subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public-route-table.id}"
}

resource "aws_route_table_association" "private-subnets-RT-Association" {
  count = "${length(var.private_cidr_block)}"
  subnet_id = "${element(aws_subnet.private-subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private-route-table.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "${var.vpc_name}-allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.default.id}"
  dynamic "ingress" {
    for_each = var.ingress_service
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.vpc_name}-allow-all"
    Owner = local.Owner
    costcenter = local.costcenter
    TeamDL = local.TeamDL
    environment = "${var.environment}"
  }
}

#data "aws_ami" "my_ami" {
#  most_recent      = true
#  #name_regex       = "^sai"
#  owners           = ["232323232323232323"]
#}


resource "aws_instance" "public-server" {
  count = length(var.public_cidr_block)
  ami = "${lookup(var.amis, var.aws_region)}"
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = "${element(aws_subnet.public-subnet.*.id, count.index+1)}"
  vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
  associate_public_ip_address = true
  tags = {
    Name = "${var.vpc_name}-Public-server-${count.index+1}"
    Owner = local.Owner
    costcenter = local.costcenter
    TeamDL = local.TeamDL
    environment = "${var.environment}"
  }
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install nginx -y
    sudo apt install git -y
    sudo git clone https://github.com/saikiranpi/SecOps-game.git
    sudo rm -rf /var/www/html/index.nginx-debian.html
    sudo cp SecOps-game/index.html /var/www/html/index.html
    echo "<h1>${var.vpc_name}-Public-Server-${count.index+1}</h1>" >> /var/www/html/index.html
    sudo systemctl start nginx
    sudo systemctl enable nginx
  EOF
}

#resource "aws_dynamodb_table" "state_locking" {
#  hash_key = "LockID"
#  name     = "dynamodb-state-locking"
#  attribute {
#    name = "LockID"
#    type = "S"
#  }
#  billing_mode = "PAY_PER_REQUEST"
#}

##output "ami_id" {
#  value = "${data.aws_ami.my_ami.id}"
#}
#!/bin/bash
# echo "Listing the files in the repo."
# ls -al
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Packer Now...!!"
# packer build -var=aws_access_key=AAAAAAAAAAAAAAAAAA -var=aws_secret_key=BBBBBBBBBBBBB packer.json
# echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "Running Terraform Now...!!"
# terraform init
# terraform apply --var-file terraform.tfvars -var="aws_access_key=AAAAAAAAAAAAAAAAAA" -var="aws_secret_key=BBBBBBBBBBBBB" --auto-approve
