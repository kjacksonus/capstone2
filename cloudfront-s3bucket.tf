/*
# S3bucket with KMS and SSEncryption

resource "aws_kms_key" "kmskey" {
  description             = "kmskey"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "s3bucket" {
  bucket = "projectgogreenbucket"
  tags = {
    Name = "main bucket"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.kmskey.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    id      = "log"
    enabled = true

    prefix = "log/"

    tags = {
      Name = "Lifecycle"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 1825
    }

  }
}


# Cloudfront

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "comment"
}
resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = aws_s3_bucket.s3bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.s3bucket.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  comment             = "some comment"
  default_root_object = var.default_root_object
  aliases             = var.aliases
  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods
    target_origin_id = aws_s3_bucket.s3bucket.bucket
    forwarded_values {
      query_string = var.query_string
      headers      = var.headers
      cookies {
        forward = var.forward
      }
    }
    viewer_protocol_policy = var.viewer_protocol_policy
    min_ttl                = var.min
    default_ttl            = var.default
    max_ttl                = var.max
    compress               = var.compress
  }
  price_class = var.price_class
  restrictions {
    geo_restriction {
      restriction_type = var.restriction_type
      locations        = var.locations
    }
  }
  tags = {
    Environment = "var.environment"
  }
   viewer_certificate {
    cloudfront_default_certificate = true
  }
}
*/
