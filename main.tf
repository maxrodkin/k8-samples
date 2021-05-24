terraform {
  required_providers {
    rke = {
      source  = "rancher/rke"
      version = "1.1.0"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "default"
}
provider "rke" {
}

#####################################

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "subnet-a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block = "${cidrsubnet(aws_vpc.vpc.cidr_block, 3, 1)}"
  availability_zone = "us-west-2a"
}

resource "aws_security_group" "security-group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    //    cidr_blocks = ["0.0.0.0/0", data.aws_vpc.docker-vpc.cidr_block]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ping from anywhere"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "docker TLS from anywhere"
    from_port   = 2376
    to_port     = 2376
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "KubeAPI port [6443] on Control Plane from anywhere"
    from_port   = 6443
    to_port     = 6443
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
    Name = "allow_ssh_ping_docker"
  }
}

resource "aws_key_pair" "ec2-user" {
  key_name   = "ec2-user-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCXF/SOqlX0NzflOvoN7aiztVbZOZMSU7smKFDcGRRwLZyA0GQBt14wnuAOmV/ySsehCuMkVaBvrcO3OrZyR6tlBHYZLwJL8lxRtG9f/agPSoKJNJXNgbjwkW1viMXv1oW2gQgfOcYnNACyGsxX8xEacHV/3ytXIyiOV8x0jXDhmxvNLIvGYedIK8MdxEduTRcj7F5Wdh04iGKDvBdi36jhEUPKGj4kMtWSLT2cXSpaEEVKJ5x/Szm7CQJ6yOoBMDRQWARiokVhvOh0x1V6Vhrm9YvsnxW65nX7l3o3IPEHcVnffvGSmCT1FeuM0QDMaMrxKSuPtrELYq3aA9wfWS7oDXziQb96MVMW5Rl7b1r9VBmDeA8bV09uqhwqgHDWOS8WsAf1k/gxcAAI30x2mIb7bDJWyWdHkVL9ay6pRJhx0Rezwgw4XKpOWWSMpc4b7PZs+qBDHlSIm4/0CBgvzNVgPRNtWzyclTmN9SwPu3/Zv46SgzdBSSwfQA6dOLI8X+s="
}


/*module "ec2-instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.19.0"
  instance_type = "t2.micro"
  ami = data.aws_ami.default.id
  name = "k8s"
  key_name   = "ec2-user-key"
  associate_public_ip_address = true
  ipv6_address_count = 0
  private_ip = "172.16.0.100"
  vpc_security_group_ids      = [aws_security_group.security-group.id]

}*/
resource "aws_eip" "ip" {
  instance = aws_instance.instance.id
  vpc      = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
      Name = "k8s-gw"
    }
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.vpc.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }
  tags = {
      Name = "k8s-route-table"
    }
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.subnet-a.id
  route_table_id = aws_route_table.route.id
}

resource "aws_iam_instance_profile" "k8s_profile" {
  name = "k8s_profile"
  role = data.aws_iam_role.k8s.name
}

resource "aws_instance" "instance" {
  tags = {
    Name = "k8s"
  }
  iam_instance_profile = aws_iam_instance_profile.k8s_profile.name
  instance_type               = "t2.micro"
  ami                         = data.aws_ami.default.id
  key_name                    = "ec2-user-key"
  associate_public_ip_address = true
  ipv6_address_count          = 0
  vpc_security_group_ids = [aws_security_group.security-group.id]
  subnet_id = aws_subnet.subnet-a.id
#  user_data_base64 = data.template_cloudinit_config.init.rendered
  user_data = data.template_file.init.template

/*  connection {
    user = "ec2-user"
    host = self.public_ip
     private_key = file("/Users/mrodkin/.ssh/id_rsa")
    agent       = "false"
  }

  provisioner "file" {
    source      = "/Users/mrodkin/.ssh/id_rsa"
    destination = "~/.ssh/id_rsa"
  }*/

//  provisioner "remote-exec" {
//    inline = [
//      "cloud-init analyze show -i /var/log/cloud-init.log",
//    ]
//  }

}
resource "rke_cluster" "cluster" {
  depends_on = [aws_instance.instance, aws_eip.ip]
  ignore_docker_version = true
  nodes {

#    address = module.ec2-instance.public_dns
    address = aws_eip.ip.public_dns
    user    = "ec2-user"
    role    = ["controlplane", "worker", "etcd"]
    ssh_key = file("~/.ssh/id_rsa")
#    ssh_key_path = "~/.ssh/id_rsa"
  }
  addons_include = [
    "https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml",
    "https://gist.githubusercontent.com/superseb/499f2caa2637c404af41cfb7e5f4a938/raw/930841ac00653fdff8beca61dab9a20bb8983782/k8s-dashboard-user.yml",
  ]
}
resource "local_file" "kube_cluster_yaml" {
  filename = "${path.root}/kube_config_cluster.yml"
  sensitive_content  = rke_cluster.cluster.kube_config_yaml
}

#output "aws_ami" { value = data.aws_ami.default.arn}
#output "public_ip" {value = module.ec2-instance.public_ip}
#output "public_ip" { value = aws_instance.instance.public_ip }
output "eip_public_ip" { value = aws_eip.ip.public_ip }
output "eip_public_dns" { value = aws_eip.ip.public_dns }
