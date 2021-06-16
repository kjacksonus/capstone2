provider "aws" {
  region                = "us-east-1"
  shared_credentials_file = "/Users/nozima/.aws/credentials"
  profile = "default"
}

resource "aws_s3_bucket" "s3_policy" {
  bucket = "my-tf-test-bucket"
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.s3_policy.id

policy = jsonencode({

  "Version" : "2012-10-17",
  "Statement" : [

    {
      "Sid" : "VisualEditor0",
      "Effect" : "Allow",
      "Action" : "s3:*",
      "Resource" : "*"
    }
  ]
  }
)
}