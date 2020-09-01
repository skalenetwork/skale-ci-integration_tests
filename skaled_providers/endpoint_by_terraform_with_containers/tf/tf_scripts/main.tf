provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# resource "aws_key_pair" "deployer" {
#   # pem name
#   key_name   = var.key_name
#   public_key = var.id_rsa_pub
# }

resource "aws_volume_attachment" "ebs_att" {
  count = var.COUNT
  # skip_destroy = true
  device_name = "/dev/sdd"
  
  volume_id   = aws_ebs_volume.lvm_volume[count.index].id
  instance_id = aws_spot_instance_request.node[count.index].spot_instance_id

  # todo: from ivan need to test it
  # not working with elastic_ip
  # provisioner "remote-exec" {
  #   inline = [
  #     "export VOLUME_SIZE=${var.lvm_volume_size}",
  #     "echo /dev/`lsblk -do NAME,SIZE | grep $VOLUME_SIZE | cut -d ' ' -f 1` | sudo tee /home/ubuntu/lvm-block-device",
  #   ]

  #   connection {
  #     type     = "ssh"
  #     user     = "ubuntu"
  #     host = aws_spot_instance_request.node[count.index].public_ip
  #     private_key = file(var.path_to_pem)  
  #   }
  # }
  
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
  count = var.COUNT
  ami   = data.aws_ami.ubuntu.id
  
  instance_type = var.instance_type
  availability_zone = var.availability_zone
  # pem name
  key_name = var.key_name
  # Our Security group to allow HTTP and SSH access
  # vpc_security_group_ids = [aws_security_group.default.id]
  # for spot
  spot_price    = var.spot_price[var.instance_type]
  wait_for_fulfillment = true
  #
  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = {
    Name = "${var.prefix}-${count.index}"
  }

  connection {
    type     = "ssh"
    user     = "ubuntu"
    # password = "${var.root_password}"
    host     = self.public_ip
    private_key = file(var.path_to_pem)
    # host = aws_spot_instance_request.node[count.index].public_ip
  }


#  # copy .env
#  provisioner "file" {
#   source = "../.env_for_node_aws_spot"
#   destination = "/home/ubuntu/.env"
#  }

#  # copy scripts
#  provisioner "file" {
#    source = "../scripts"
#    destination = "/tmp/scripts"
#  }

#  # copy ssl files
#  provisioner "file" {
#    source = "../ssl"
#    destination = "/tmp/ssl"
#  }

  # copy authorized_keys
  provisioner "file" {
    source = "./scripts/authorized_keys"
    destination = "/home/ubuntu/.ssh/authorized_keys"
  }
}


//security.tf
# resource "aws_security_group" "default" {
#   name = "spot-aws-allow-all"
#   ingress {
#     from_port = 22
#     to_port = 22
#     protocol = "tcp"
#     cidr_blocks = [
#       "0.0.0.0/0"
#     ]
#   }
#   // Terraform removes the default rule
#   egress {
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

// add elasticIP to instance
// first var
# resource "aws_eip" "ip" {
#   count    = var.COUNT
#   vpc      = true
#   instance = aws_spot_instance_request.node[count.index].spot_instance_id
# }

// OR this ctructure
// add elasticIP to instance
// second var
resource "aws_eip" "ip" {
  count    = var.COUNT
  vpc      = true
}
resource "aws_eip_association" "eip_assoc" {
  count = var.COUNT
  instance_id   = aws_spot_instance_request.node[count.index].spot_instance_id
  allocation_id = aws_eip.ip[count.index].id
}


// outputs
output "public_ips" {
  description = "map output of the hostname and public ip for each instance"
  value = zipmap(
  # data.template_file.node_names.*.rendered,
  aws_spot_instance_request.node.*.tags.Name,
  #aws_spot_instance_request.node.*.public_ip,
  aws_eip.ip.*.public_ip
  )
}


#output "ids_of_droplets" {
#  description = "map output of the hostname and ID for each instance"
#  value = zipmap(
#  # data.template_file.node_names.*.rendered,
#  aws_spot_instance_request.node.*.tags.Name,
#  aws_spot_instance_request.node.*.spot_instance_id,
#  )
#}
