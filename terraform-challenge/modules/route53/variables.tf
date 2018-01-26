# Hosted zone ID from AWS account
variable "hosted_zone_id" {
  default = ""
}

variable "domain_name" {
  default = ""
}

# specific domain prefix
variable "record_prefix" {
}

# values can be "CNAME", "A"
variable "record_type" {
  default = "CNAME"
}

# required for non-Alias records
variable "ttl" {
  default = "120"
}

# target value of the CNAME record, or IP for A records
#  ex) ["ec2-51-20-206-171.compute-1.amazonaws.com"], or ["51.20.206.171"]
variable "records" {
}
