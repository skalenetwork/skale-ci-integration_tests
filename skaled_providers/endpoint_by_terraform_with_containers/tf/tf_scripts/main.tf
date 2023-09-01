# https://cloud-images.ubuntu.com/locator/ec2/ for ami identication

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
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

  # provisioner "remote-exec" {
  #   inline = [
  #     "export VOLUME_SIZE=${var.lvm_volume_size}",
  #     "echo /dev/`lsblk -do NAME,SIZE | grep $VOLUME_SIZE | cut -d ' ' -f 1` | sudo tee /root/lvm-block-device",
  #   ]
  #   connection {
  #     type     = "ssh"
  #     user     = "ubuntu"
  #     host = aws_eip.node_eip[count.index].public_ip
  #     # host = "${var.spot_instance ? aws_spot_instance_request.node[count.index].public_ip : aws_instance.node[count.index].public_ip}"
  #     private_key = file(var.path_to_pem)    
  #   }
  # }

}

resource "aws_ebs_volume" "lvm_volume" {
  count = var.COUNT
  availability_zone = var.availability_zone
  size = var.lvm_volume_size

  tags = {
    Name = "${var.prefix}-${count.index}-lvm-volume"
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


data "aws_vpc" "default" {
  default = true
}


resource "aws_eip_association" "eip_assoc" {
  count = var.COUNT
  allocation_id = aws_eip.node_eip[count.index].id
  instance_id = var.spot_instance ? aws_spot_instance_request.node[count.index].spot_instance_id : aws_instance.node[count.index].id
  provisioner "local-exec" {
    command = "echo 'node${count.index} ansible_host=${self.public_ip}' >> hosts"
  }
}

resource "aws_eip" "node_eip" {
  count = var.COUNT
}
