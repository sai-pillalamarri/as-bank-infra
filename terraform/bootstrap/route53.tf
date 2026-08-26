resource "aws_route53_zone" "primary" {

  #checkov:skip=CKV2_AWS_38:DNSSEC is outside the current project scope and would add KMS and registrar DS-record management to Layer 0.
  #checkov:skip=CKV2_AWS_39:DNS query logging is not required at this stage and would add persistent logging cost.
  name = "aslearnings.online"

  lifecycle {
    # Recreating the zone changes its nameservers and would break the Hostinger delegation.
    prevent_destroy = true
  }
}
