# run tf init to configure remote state
/**
terraform {
  backend "s3" {
    bucket                  = "tf-states"
    key                     = "terraform.state"
    region                  = "us-east-1"
    shared_credentials_file = "../credentials/.aws/credentials"
    profile                 = "fake_account"
    encrypt                 = true
  }
}
**/
provider "aws" {
  shared_credentials_file   = "../credentials/.aws/credentials"
  profile                   = "fake_account" #ctm
  region                    = "us-east-2"
}
module "key-pair" {
  source                    = "cloudposse/key-pair/aws"
  version                   = "0.2.1"
  namespace                 = "cp"
  stage                     = "oscar-testing-keypair"
  name                      = "oscar-testing-keypair"
  ssh_public_key_path       = "/Users/omendoza/git/dev-ops-challenge/terraform-challenge/credentials/created-pems"
  generate_ssh_key          = "true"
  private_key_extension     = ".pem"
  public_key_extension      = ".pub"
}
module "vpc-prod" {
  source                    = "terraform-aws-modules/vpc/aws"
  name                      = "oscar-testing-vpc"
  cidr                      = "10.0.0.0/22"
  azs                       = ["us-east-2a", "us-east-2b"]
  private_subnets           = ["10.0.1.0/24", "10.0.2.0/24"]
  tags = {
    Terraform               = "true"
    Environment             = "oscar-testing-vpc"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id                    = "${module.vpc-prod.vpc_id}"
}
module "secgrp-elb" {
  source                    = "terraform-aws-modules/security-group/aws"
  name                      = "oscar-testing-elb"
  description               = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id                    = "${module.vpc-prod.vpc_id}"
  ingress_cidr_blocks       = ["0.0.0.0/0"]
}
module "secgrp-instance" {
  source                    = "terraform-aws-modules/security-group/aws"
  name                      = "oscar-testing-instance-sg"
  description               = "SG for access to prod applicaiton instances"
  vpc_id                    = "${module.vpc-prod.vpc_id}"
  ingress_cidr_blocks       = ["10.10.0.0/16", "10.111.11.0/32", "10.121.11.0/32"]
  ingress_rules             = ["https-443-tcp"]
}
module "ec2-prod-2a" {
  source                    = "terraform-aws-modules/ec2-instance/aws"
  version                   = "1.2.0"
  ami                       = "ami-2581aa40"
  instance_type             = "m4.large"
  key_name                  = "${module.key-pair.key_name}"
  name                      = "ec2-oscar-2a"
  vpc_security_group_ids    = ["${module.secgrp-instance.this_security_group_id}"]
  subnet_id                 = "${module.vpc-prod.private_subnets[0]}"

  tags = {
    Terraform               = "true"
    Environment             = "oscar-testing-ec2-2a"
  }
}
module "ec2-prod-2b" {
  source                    = "terraform-aws-modules/ec2-instance/aws"
  version                   = "1.2.0"
  ami                       = "ami-2581aa40"
  instance_type             = "m4.large"
  key_name                  = "${module.key-pair.key_name}"
  name                      = "ec2-oscar-2b"
  vpc_security_group_ids    = ["${module.secgrp-instance.this_security_group_id}"]
  subnet_id                 = "${module.vpc-prod.private_subnets[0]}"

  tags = {
    Terraform               = "true"
    Environment             = "oscar-testing-ec2-2b"
  }
}
/**
# allocate eip, associate with instance
module "eip-prod-2a" {
  source                = "../modules/eip"
  instance_id           = "${module.ec2-prod-2a.id[0]}"
}
module "eip-prod-2b" {
  source                = "../modules/eip"
  instance_id           = "${module.ec2-prod-2b.id[0]}"
}

module "route53" {
  source  = "KoeSystems/route53/aws"
  version = "0.1.1"

  domain_name = "domain.localdomain"
}
module "route53-alias" {
  source  = "cloudposse/route53-alias/aws"
  version = "0.2.3"

  aliases         = ["www.example.com.", "static1.cdn.example.com.", "static2.cdn.example.com"]
  parent_zone_id  = "${module.route53.primary_public_zone_id}"
  target_dns_name = "${module.elb-prod.this_elb_dns_name}"
  target_zone_id  = "${module.elb-prod.this_elb_zone_id}"
}

# create CNAME record using elb for human-friendly address
module "route53-prod-elb" {
  source                = "../modules/route53"
  record_prefix         = "Unicorn-prod-elb"
  record_type           = "CNAME"
  records               = "${module.elb-prod.this_elb_dns_name}"
}
# create A record using eip public IP
module "route53-prod-ec2-2a" {
  source                = "../modules/route53"
  record_prefix         = "Unicorn-test"
  record_type           = "A"
  records               = "${module.eip-prod-2a.public_ip}"
}
module "route53-prod-ec2-2b" {
  source                = "../modules/route53"
  record_prefix         = "Unicorn-test"
  record_type           = "A"
  records               = "${module.eip-prod-2b.public_ip}"
}
**/
# elastic load balancers (elb)
module "elb-prod" {
  source                    = "terraform-aws-modules/elb/aws"
  name                      = "oscar-testing-elb"
  subnets                   = ["${module.vpc-prod.private_subnets[0]}", "${module.vpc-prod.private_subnets[1]}"]
  security_groups           = ["${module.secgrp-elb.this_security_group_id}"]
  internal                  = false
  listener = [
    {
      instance_port         = "80"
      instance_protocol     = "HTTP"
      lb_port               = "80"
      lb_protocol           = "HTTP"
    }
  ]

  health_check = [
    {
      target                = "HTTP:80/"
      interval              = 30
      healthy_threshold     = 2
      unhealthy_threshold   = 2
      timeout               = 5
    },
  ]
  number_of_instances       = 2
  instances                 = ["${module.ec2-prod-2a.id[0]}", "${module.ec2-prod-2b.id[0]}"]
  tags = {
    Owner                   = "Terraform"
    Environment             = "oscar-testing-elb"
  }
}
module "rds" {
  source                    = "terraform-aws-modules/rds/aws"
  version                   = "1.8.0"
  allocated_storage         = 5
  maintenance_window        = "Mon:00:00-Mon:03:00"
  backup_window             = "03:00-06:00"
  engine                    = "postgres"
  family                    = "postgres9.6"
  engine_version            = "9.6.6"
  instance_class            = "db.m4.large"
  identifier                = "prodpostgresql966"
  name                      = "prodPostgreSQL966"
  username                  = "adminoscar"
  password                  = "password!"
  port                      = "3306"
  subnet_ids                = ["${module.vpc-prod.private_subnets[0]}", "${module.vpc-prod.private_subnets[1]}"]
  vpc_security_group_ids    = ["${module.secgrp-instance.this_security_group_id}"]
  publicly_accessible       = false
  apply_immediately         = false
  allow_major_version_upgrade = false
}
