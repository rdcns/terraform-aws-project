terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  /*
  backend "s3" {
    bucket         = "cia-project-bucket"
    key            = "cia-project/dev/terraform.tfstate" #where to store the state file in the bucket
    region         = "eu-west-3"
    encrypt = true
    profile = "terraform-login" #TODO: See to it if you can set it on commandline with powershell
    use_lockfile = true
  }
  */

}

# Create an S3 bucket to store the Terraform state file
# Bucket name has to be unique worldwide to act like a unique internet address for storage
# Bucket is private by default

module "my-basic-vpc" {
  source = "./modules/VPC"
}

module "my-instance-1" {
  source = "./modules/EC2"
  ami = var.ami
  instance_type = var.instance_type
}

module "my-instance-2" {
  source = "./modules/EC2"
  ami = var.ami
  instance_type = var.instance_type
}

module "my-load-balancer" {
  source = "./modules/LoadBalancer"
  security_group_id = module.my-instance-1.security_group_id
  subnet_ids = [module.my-basic-vpc.public_subnet_id]
  vpc = module.my-basic-vpc.vpc
  instance_ids = [
    module.my-instance-1.instance_id,
    module.my-instance-2.instance_id
  ]
}