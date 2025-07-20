provider "aws" {
  region  = var.aws_region
  profile = var.profile
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
}

module "ec2" {
  source                 = "./modules/ec2"
  ami                    = var.ami
  instance_type          = var.instance_type
  key_pair_name          = var.key_pair_name
  instance_name          = var.instance_name
  security_group_cidr_ip = var.my_ip
  iam_instance_profile   = module.cloudwatch.iam_instance_profile_name
}

module "s3" {
  source = "./modules/s3"
  bucket_name = "grocerymate-avatars-m"
}