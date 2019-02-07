resource "aws_instance" "master" {
  count                  = "${var.cluster_size}"
  ami                    = "${data.aws_ami.selected.id}"
  subnet_id              = "${var.master_subnet}"
  instance_type          = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.redis.id}"]
  key_name               = "${var.ssh_key_pair}"
  iam_instance_profile   = "${aws_iam_instance_profile.profile.id}"

  user_data = "${element(data.template_cloudinit_config.provision_master.*.rendered, count.index)}"

  root_block_device {
    volume_size           = "${var.storage_size}"
    delete_on_termination = true
  }

  tags = {
    Name        = "${lower("${var.namespace}${var.stage}_redis_master${count.index}")}"
    Environment = "${var.stage}"
    Role        = "redis_master"
    Provision   = "terraform"
    Inventory   = "ansible"
  }

  lifecycle {
    ignore_changes = ["ami", "user_data"]
  }
}

resource "aws_instance" "slave" {
  count                  = "${var.cluster_size}"
  ami                    = "${data.aws_ami.selected.id}"
  subnet_id              = "${var.slave_subnet}"
  instance_type          = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.redis.id}"]
  key_name               = "${var.ssh_key_pair}"
  iam_instance_profile   = "${aws_iam_instance_profile.profile.id}"

  user_data = "${element(data.template_cloudinit_config.provision_slave.*.rendered, count.index)}"

  root_block_device {
    volume_size           = "${var.storage_size}"
    delete_on_termination = true
  }

  tags = {
    Name        = "${lower("${var.namespace}${var.stage}_redis_slave${count.index}")}"
    Environment = "${var.stage}"
    Role        = "redis_slave"
    Provision   = "terraform"
    Inventory   = "ansible"
  }

  lifecycle {
    ignore_changes = ["ami", "user_data"]
  }
}

resource "aws_security_group" "redis" {
  name        = "${lower("${var.namespace}${var.stage}_redis")}"
  description = "Allow inbound traffic to redis"
  vpc_id      = "${var.vpc}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${lower("${var.namespace}${var.stage}_redis")}"
    Environment = "${var.stage}"
    Provision   = "terraform"
  }
}

data "aws_iam_policy_document" "redis" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "redis" {
  name               = "${lower("${var.namespace}${var.stage}_redis")}"
  assume_role_policy = "${data.aws_iam_policy_document.redis.json}"
}

resource "aws_iam_role_policy" "policy" {
  name = "${lower("${var.namespace}${var.stage}_redis")}"
  role = "${aws_iam_role.redis.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "profile" {
  name_prefix = "${lower("${var.namespace}${var.stage}_redis")}"
  role        = "${aws_iam_role.redis.name}"
}
