terraform {
  backend "s3" {
    bucket          = "terraform-up-and-running-state-mguk"
    key             = "terraform_instance_beta/terraform.tfstate"
    dynamodb_table  = "terraform-state-lock-dynamo"
    profile         = "training"
    region          = "us-east-1"
  }
}

provider "aws" {
  region  = "${var.region}"
  profile = "training"
}

# data "terraform_remote_state" "global" {
#   backend = "s3"

#   config {
#     bucket = "terraform-up-and-running-state-mguk"
#     key = "terraform.tfstate"
#     region = "us-east-1"
#   }
# }

resource "aws_instance" "example" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  
  tags {
    Name = "terraform-example_beta"
  }

}

