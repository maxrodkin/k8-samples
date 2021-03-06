data "aws_iam_user" "user" {
  user_name = "user1"
}

output "user_name" {
  value = data.aws_iam_user.user.arn
}

data "aws_ami" "default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "template_file" "init" {
  template = file("${path.root}/download-and-run-scripts.sh")
}

data "template_cloudinit_config" "init" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.init.rendered
  }
}

data "aws_iam_role" "k8s" {
  name = "k8s"
}