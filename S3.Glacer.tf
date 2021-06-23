
#S3-Bucket
resource "aws_s3_bucket_object" "prod-folder" {
    bucket = aws_s3_bucket.gogreen-bucket.id
    acl = "private"
    key = "prod/"
    source = "/dev/null"
}
resource "aws_s3_bucket_object" "archive-folder" {
    bucket = aws_s3_bucket.gogreen-bucket.id
    acl = "private"
    key = "archive/"
    source = "/dev/null"  
}
resource "aws_s3_bucket" "gogreen-bucket" {
    bucket = "gogreen-lifecycle-123"
    acl = "private"
}

#KMS
resource "aws_kms_key" "Key" {
    description = "this key is used to encrypt bucket object"
    deletion_window_in_days = 10
}

#lifecycle
lifecycle_rule {
    id      = "archive"
    enabled = true

    prefix = "archive/"

    tags = {
        rule = "archive"
    }
    
    tag = {
        days = 90
        storage_class = "GLACIER"
    }
    expiration {
        days = 1825
    }
  }
  #S3 Policy
resource "aws_s3_bucket" "s3_policy_green" {
  bucket = "my-tf-test-bucket"
}

resource "aws_s3_bucket_policy" "s3_policy_green" {
  bucket = aws_s3_bucket.s3_policy_green.id

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
