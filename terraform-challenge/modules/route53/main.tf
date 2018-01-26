resource "aws_route53_record" "r53_record" {
  zone_id = "${var.hosted_zone_id}"
  name    = "${var.record_prefix}${var.domain_name}"
  type    = "${var.record_type}"
  ttl     = "${var.ttl}"
  records = ["${var.records}"]
}
