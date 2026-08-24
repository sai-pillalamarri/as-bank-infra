resource "aws_route53_zone" "primary" {
  name = "aslearnings.online"

  lifecycle {
    # Recreating the zone changes its nameservers and would break the Hostinger delegation.
    prevent_destroy = true
  }
}
