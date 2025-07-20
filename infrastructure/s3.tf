provider "aws" {
    region  = var.aws_region
    profile = var.profile
}

resource "aws_s3_bucket" "avatars-m" {
  bucket = "grocerymate-avatars-m"

  tags = {
    Name        = "grocerymate-avatars-m"
    Environment = "Dev"
  }
}