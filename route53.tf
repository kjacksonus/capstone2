
/*
resource "aws_route53_zone" "primary" {
  name = "www.gogreen.com"
}
resource "aws_route53_record" "route53" {
  zone_id = aws_route53_zone.primary.id
  name    = "www.gogreen.com"
  type    = "A"
  ttl     = "300"
}
*/