variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_account_ids" {
  type    = list
  default = null
}

terraform {
  required_version = ">= 0.12.20"
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = var.aws_account_ids
  access_key          = "test"
  secret_key          = "test"

  # only required for non virtual hosted-style endpoint use case.
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#s3_use_path_style
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}
