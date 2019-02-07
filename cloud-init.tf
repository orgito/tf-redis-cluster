data "template_file" "conf" {
  template = "${file("${path.module}/files/redis.conf")}"
}

data "template_file" "provision_master" {
  count    = "${var.cluster_size}"
  template = "${file("${path.module}/files/provision.sh")}"

  vars {
    index        = "${count.index}"
    role         = "master"
    version      = "${var.version}"
    redis_conf   = "${data.template_file.conf.rendered}"
    region       = "${var.region}"
    prefix       = "${lower("${var.namespace}${var.stage}_redis")}"
    cluster_size = "${var.cluster_size}"
  }
}

data "template_file" "provision_slave" {
  count    = "${var.cluster_size}"
  template = "${file("${path.module}/files/provision.sh")}"

  vars {
    index        = "${count.index}"
    role         = "slave"
    version      = "${var.version}"
    redis_conf   = "${data.template_file.conf.rendered}"
    region       = "${var.region}"
    prefix       = "${lower("${var.namespace}${var.stage}_redis")}"
    cluster_size = "${var.cluster_size}"
  }
}

data "template_cloudinit_config" "provision_master" {
  count         = "${var.cluster_size}"
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.provision_master.*.rendered, count.index)}"
  }
}

data "template_cloudinit_config" "provision_slave" {
  count         = "${var.cluster_size}"
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.provision_slave.*.rendered, count.index)}"
  }
}
