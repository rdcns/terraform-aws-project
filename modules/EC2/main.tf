resource "aws_instance" "instance" {
  ami           = local.resolved_ami
  instance_type = "t3.micro"
  security_groups = [aws_security_group.instances.name]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              python3 -m http.server 8080 &
              EOF

  tags = {
    Name        = "My EC2 Instance 1"
    Environment = "Dev"
  }
  key_name = aws_key_pair.deployer.key_name
}

data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  resolved_ami = var.ami != "" ? var.ami : data.aws_ssm_parameter.amazon_linux_2023.value
}

resource "aws_key_pair" "deployer" {
  key_name   = "test-aws-key-pair"
  public_key = file("${path.module}/../../keys/test-aws-key.pub")
}

resource "aws_security_group" "instances" {
  name = "instance-security-group"
}

#Setup security group rule to allow incoming traffic on port 8080 from any IP address
resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.instances.id
  cidr_blocks       = ["0.0.0.0/0"] #All IPs can access the instance on port 8080
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.instances.id
  cidr_blocks       = ["0.0.0.0/0"] #All IPs can access the instance on port 22
}

resource "aws_security_group_rule" "allow_alb_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "tcp"
  security_group_id = aws_security_group.instances.id
  cidr_blocks       = ["0.0.0.0/0"] #All IPs can access the instance
}