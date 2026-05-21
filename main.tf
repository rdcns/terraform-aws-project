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

module "vpc_cute" {
  source = "./modules/VPC"
}

module "my-instance" {
  source = "./modules/EC2"
}

