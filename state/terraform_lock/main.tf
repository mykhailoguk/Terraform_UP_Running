provider "aws" {
  region  = "${var.region}"
  profile = "training"
}

resource "aws_s3_bucket" "terraform-state" {
  bucket = "terraform-up-and-running-state-mguk"
  versioning {
    enabled = true
  }
  
  lifecycle {
    prevent_destroy = false
  }  
}

resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name            = "terraform-state-lock-dynamo"
  hash_key        = "LockID"
  read_capacity   = 2
  write_capacity  = 2
 
  attribute {
    name = "LockID"
    type = "S"
  }
 
  tags {
    Name = "DynamoDB Terraform State Lock Table"
  }
}
