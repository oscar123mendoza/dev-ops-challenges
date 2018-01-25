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
  shared_credentials_file = "../credentials/.aws/credentials"
  profile                 = "fake_account"
  region                  = "us-east-1"
}
module "vpc-prod" {
  source = "terraform-aws-modules/vpc/aws"

  name = "prod-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  tags = {
    Terraform = "true"
    Environment = "Prod"
  }
}
module "secgrp-elb" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "prod-elb"
  description = "Security group with HTTP ports open for everybody (IPv4 CIDR), egress ports are all world open"
  vpc_id      = "${module.vpc-prod.vpc_id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
}
# security groups for application servers
module "secgrp-instance" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "prod-instance"
  description = "SG for access to prod applicaiton instances"
  vpc_id      = "${module.vpc-prod.vpc_id}"

  ingress_cidr_blocks      = ["10.10.0.0/16"]
  ingress_rules            = ["https-443-tcp"]
}
module "ec2-prod-1a" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "1.2.0"

  ami                    = "ami-ebd02392"
  instance_type          = "t5.large"
  key_name               = "fake-key"
  name                   = "ec2-prod-1a"
  vpc_security_group_ids = ["${module.secgrp-instance.this_security_group_id}"]
  subnet_id              = ["${module.vpc-prod.private_subnets[0]}"]

  tags = {
    Terraform = "true"
    Environment = "Prod"
  }
}
module "ec2-prod-1b" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "1.2.0"

  ami                    = "ami-ebd02392"
  instance_type          = "t5.large"
  key_name               = "fake-key"
  name                   = "ec2-prod-1b"
  vpc_security_group_ids = ["${module.secgrp-instance.this_security_group_id}"]
  subnet_id              = ["${module.vpc-prod.private_subnets[0]}"]

  tags = {
    Terraform = "true"
    Environment = "Prod"
  }
}
/**
module "ec2-prod-1a" {
  source                 = "../modules/aws/ec2"

  client_name            = "Client_name_tag"
  environment_name       = "prod"
  application_name       = "Unicorn"
  application_version    = "0.0.1"
  application_tier       = "Unicorn"
  ami_id                 = "ami-01991e7b"   #centos us-west-2
  number_of_instances    = "1"
  instance_type          = "m5.large"
  subnet_id              = ["${module.vpc-prod.private_subnets[0]}"]
  key_name               = "fake-key"
  #iam_instance_profile  = "ec2-profile"
  root_block_size        = "24"
  ebs_device_name        = "/dev/sdf"
  ebs_block_type         = "gp2"
  ebs_block_size         = "200"
  vpc_security_group_ids = ["${module.secgrp-instance.security_group_id}"]
  mount_point            = "sudo su -c 'grep opt /etc/fstab || echo /dev/xvdf    /opt    auto    defaults        0 0 >> /etc/fstab'"
  sleep_hack             = "sudo sleep 1"
  ssh_key                = "../credentials/pems/fake-ssh-key.pem"
  user_name              = "centos"
  chef_environment_name  = "Unicorn"
  run_list               = ["role[Base]","recipe[Unicorn]"]
  node_name              = "prod-unicorn-1a"
  chef_user_name         = "fake_chef_user"
  chef_url               = "https://api.chef.io/organizations/ctmsp12"
  user_key               = "../credentials/pems/fake-chef-key.pem"
  timeout                = "10m"
}

module "ec2-prod-1b" {
  source                 = "../modules/aws/ec2"

  client_name            = "Client_name_tag"
  environment_name       = "prod"
  application_name       = "Unicorn"
  application_version    = "0.0.1"
  application_tier       = "Unicorn"
  ami_id                 = "ami-01991e7b"   #centos us-west-2
  number_of_instances    = "1"
  instance_type          = "m5.large"
  subnet_id              = ["${module.vpc-prod.private_subnets[1]}"]
  key_name               = "fake-key"
  #iam_instance_profile  = "ec2-profile"
  root_block_size        = "24"
  ebs_device_name        = "/dev/sdf"
  ebs_block_type         = "gp2"
  ebs_block_size         = "200"
  vpc_security_group_ids = ["${module.secgrp-instance.security_group_id}"]
  mount_point            = "sudo su -c 'grep opt /etc/fstab || echo /dev/xvdf    /opt    auto    defaults        0 0 >> /etc/fstab'"
  sleep_hack             = "sudo sleep 1"
  ssh_key                = "../credentials/pems/fake-ssh-key.pem"
  user_name              = "centos"
  chef_environment_name  = "Unicorn"
  run_list               = ["role[Base]","recipe[Unicorn]"]
  node_name              = "prod-unicorn-1b"
  chef_user_name         = "fake_chef_user"
  chef_url               = "https://api.chef.io/organizations/ctmsp12"
  user_key               = "../credentials/pems/fake-chef-key.pem"
  timeout                = "10m"
}
**/
# allocate eip, associate with instance
module "eip-prod-1a" {
  source                = "../modules/eip"
  instance_id           = "${module.ec2-prod-1a.id[0]}"
}
module "eip-prod-1b" {
  source                = "../modules/eip"
  instance_id           = "${module.ec2-prod-1b.id[0]}"
}
# create A record using eip public IP
module "route53-prod-ec2-1a" {
  source                = "../modules/route53"
  record_prefix         = "Unicorn-test"
  record_type           = "A"
  records               = "${module.eip-prod-1a.public_ip}"
}
module "route53-prod-ec2-1b" {
  source                = "../modules/route53"
  record_prefix         = "Unicorn-test"
  record_type           = "A"
  records               = "${module.eip-prod-1b.public_ip}"
}
# elastic load balancers (elb)
module "elb-prod" {
  source = "terraform-aws-modules/elb/aws"

  name = "elb-prod"

  subnets         = ["${module.vpc-prod.private_subnets[0]}", "${module.vpc-prod.private_subnets[1]}"]
  security_groups = "${module.secgrp-elb.this_security_group_id}"
  internal        = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
    {
      instance_port     = "8080"
      instance_protocol = "HTTP"
      lb_port           = "8080"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = [
    {
      target              = "HTTP:80/"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]

  number_of_instances = 2
  instances           = ["${module.ec2-prod-1a.id[0]}", "${module.ec2-prod-1b.id[0]}"]

  tags = {
    Owner       = "Terraform"
    Environment = "Prod"
  }
}
# create CNAME record using elb for human-friendly address
module "route53-prod-elb" {
  source                = "../modules/route53"
  record_prefix         = "Unicorn-prod-elb"
  record_type           = "CNAME"
  records               = "${module.elb-prod.this_elb_dns_name}"
}
# Some of the rds module attributes will be changed by the snapshot used to build the instance, e.g. username, storage size, etc.
module "rds-prod" {
  source                  = "../modules/rds"
  db_subnet_group         = "Unicorn"         #(Optional) Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC, or in EC2 Classic, if available.
  private_subnets         = ["${module.vpc-prod.private_subnets[0]}", "${module.vpc-prod.private_subnets[1]}"] #(Required) List of subnet ID. Subnets do not have to be private.
  identifier              = "prod-unicorn"#(Optional) The name of the RDS instance, if omitted, Terraform will assign a random, unique identifier.
  instance_class          = "db.m5.large"      #(Required) The instance type of the RDS instance
  name                    = "Unicorn_Postgres"
  password                = "password"      #(Required) Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file
  vpc_security_group_ids  = ["${module.secgrp-instance.this_security_group_id}"]    #(Optional) List of VPC security groups to associate.
  client_name             = "Unicorn"              #For tagging purposes
  environment_name        = "prod"              #For tagging purposes
  application_name        = "Unicorn"         #For tagging purposes
  allocated_storage       = "20"                #Minimum value is 20GB but the snapshot used to build the instance has it set to 15
}