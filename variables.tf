
variable "bucket_name" {
  type    = string
  default = "gogreen-02262021"
}
variable "bucket_visibility" {
  type    = string
  default = "private"
}

variable "environment" {
  description = "Logical name of the environment."
  type        = string
  default     = "Dev"
}
variable "bucket_tags" {
  type    = string
  default = "cloudfront-bucket"
}

variable "enabled" {
  type    = bool
  default = true
}
variable "is_ipv6_enabled" {
  type    = bool
  default = true
}
variable "comment" {
  type        = string
  default     = null
  description = "Comment field for the distribution"
}
variable "default_root_object" {
  type    = string
  default = "index.html"
}
variable "aliases" {
  type    = list(string)
  default = []
}
variable "include_cookies" {
  type    = bool
  default = false
}
variable "log_bucket" {
  type    = string
  default = "logb-bucket"
}
variable "log_prefix" {
  default = "cf_logs"
}
variable "allowed_methods" {
  type    = list(any)
  default = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
}
variable "cached_methods" {
  type    = list(any)
  default = ["GET", "HEAD"]
}
variable "min" {
  default = "0"
}
variable "price_class" {
  type    = string
  default = "PriceClass_200"
}
variable "default" {
  default = "3600"
}
variable "max" {
  default = "86400"
}
variable "headers" {
  type    = list(any)
  default = []
}
variable "query_string" {
  type    = bool
  default = "false"
}
variable "forward" {
  type    = string
  default = "none"
}
variable "compress" {
  type    = bool
  default = "true"
}

variable "locations" {
  type    = list(any)
  default = []
}
variable "viewer_protocol_policy" {
  type    = string
  default = "allow-all"
}

variable "restriction_type" {
  type    = string
  default = "none"
}

