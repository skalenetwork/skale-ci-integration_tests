# https://cloud-images.ubuntu.com/locator/ec2/ for ami identication


locals {
  COUNT_ALT = var.COUNT * 1 + 8
}


provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}


provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region_alt
  alias = "alt"
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


resource "aws_volume_attachment" "ebs_att" {
  count = var.COUNT
  # skip_destroy = true
  device_name = "/dev/sdd"

  volume_id   = aws_ebs_volume.lvm_volume[count.index].id
  instance_id = var.spot_instance ? aws_spot_instance_request.node[count.index].spot_instance_id : aws_instance.node[count.index].id
}

resource "aws_ebs_volume" "lvm_volume" {
  count = var.COUNT
  availability_zone = var.availability_zone
  size = var.lvm_volume_size

  tags = {
    Name = "${var.prefix}-${count.index}"
  }
}


resource "aws_spot_instance_request" "node" {
  count = var.spot_instance ? var.COUNT : 0
  spot_price    = var.spot_price[var.instance_type]
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  availability_zone = var.availability_zone
  wait_for_fulfillment = true
  # vpc_security_group_ids = [aws_security_group.security_group.id]
  key_name = var.key_name

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = {
    Name = "${var.prefix}-${count.index}"
  }
  # provisioner "local-exec" {
  #   command = "echo 'node${count.index} ansible_host=${self.public_ip}' >> hosts"
  # }
}

resource "aws_instance" "node" {
  count = !var.spot_instance ? var.COUNT : 0
  ami   = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  availability_zone = var.availability_zone
  key_name = var.key_name
  # vpc_security_group_ids = [aws_security_group.security_group.id]

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = {
    Name = "${var.prefix}-${count.index}"
  }
  # provisioner "local-exec" {
  #   command = "echo 'node${count.index} ansible_host=${self.public_ip}' >> hosts"
  # }
  connection {
    type     = "ssh"
    user     = "ubuntu"
    # password = "${var.root_password}"
    host     = self.public_ip
    private_key = file(var.path_to_pem)
    # host = aws_spot_instance_request.node[count.index].public_ip
  }

  # copy authorized_keys
  provisioner "file" {
    source = "./scripts/authorized_keys"
    destination = "/home/ubuntu/.ssh/authorized_keys"
  }

}




##################### ALT ####################





data "aws_ami" "ubuntu_alt" {
  provider = aws.alt

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


resource "aws_volume_attachment" "ebs_att_alt" {
  count = local.COUNT_ALT
  device_name = "/dev/sdd"

  provider = aws.alt

  volume_id   = aws_ebs_volume.lvm_volume_alt[count.index].id
  instance_id = var.spot_instance ? aws_spot_instance_request.node_alt[count.index].spot_instance_id : aws_instance.node_alt[count.index].id
}

resource "aws_ebs_volume" "lvm_volume_alt" {

  provider = aws.alt


  count = local.COUNT_ALT
  availability_zone = var.availability_zone_alt
  size = var.lvm_volume_size

  tags = {
    Name = "${var.prefix}-${count.index}"
  }
}


resource "aws_spot_instance_request" "node_alt" {
  provider = aws.alt

  count = var.spot_instance ? var.COUNT : 0
  ami           = data.aws_ami.ubuntu_alt.id

  instance_type = var.instance_type
  availability_zone = var.availability_zone_alt
  spot_price    = var.spot_price[var.instance_type]
  wait_for_fulfillment = true
  # vpc_security_group_ids = [aws_security_group.security_group.id]
  key_name = var.key_name

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = {
    Name = "${var.prefix}-${var.COUNT+count.index}"
  }
  # provisioner "local-exec" {
  #   command = "echo 'node${count.index} ansible_host=${self.public_ip}' >> hosts"
  # }
}

resource "aws_instance" "node_alt" {

  provider = aws.alt


  count = !var.spot_instance ? var.COUNT : 0
  ami   = data.aws_ami.ubuntu_alt.id
  instance_type = var.instance_type
  availability_zone = var.availability_zone_alt
  key_name = var.key_name
  # vpc_security_group_ids = [aws_security_group.security_group.id]

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = {
    Name = "${var.prefix}-${count.index}"
  }
  # provisioner "local-exec" {
  #   command = "echo 'node${count.index} ansible_host=${self.public_ip}' >> hosts"
  # }
  connection {
    type     = "ssh"
    user     = "ubuntu"
    # password = "${var.root_password}"
    host     = self.public_ip
    private_key = file(var.path_to_pem)
    # host = aws_spot_instance_request.node[count.index].public_ip
  }

  # copy authorized_keys
  provisioner "file" {
    source = "./scripts/authorized_keys"
    destination = "/home/ubuntu/.ssh/authorized_keys"
  }

}




output "public_ips" {
  description = "map output of the hostname and public ip for each instance"
  value = zipmap(
  # data.template_file.node_names.*.rendered,
  concat(aws_instance.node.*.tags.Name, aws_instance.node_alt.*.tags.Name),
  concat(aws_instance.node.*.public_ip, aws_instance.node_alt.*.public_ip)
  #aws_eip.ip.*.public_ip
  )
}
