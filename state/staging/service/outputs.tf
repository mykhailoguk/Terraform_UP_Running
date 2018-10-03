output "elb_dns_name" {
  value = "${aws_elb.web_cluster_elb.dns_name}"
}

