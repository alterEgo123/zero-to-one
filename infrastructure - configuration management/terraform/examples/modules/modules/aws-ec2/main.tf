variable "instance_types" {
  type = list(string)
  description = "List of instance types"
  default = ["t2.micro"]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  count = length(var.instance_types)
  instance_type = var.instance_types[count.index]

  tags = {
    Name = "HelloWorld"
  }
}