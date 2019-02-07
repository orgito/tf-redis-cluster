output "masters" {
  value = "${aws_instance.master.*.private_ip}"
}

output "slaves" {
  value = "${aws_instance.slave.*.private_ip}"
}
