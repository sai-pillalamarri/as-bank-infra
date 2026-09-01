resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = "external-dns"
  create_namespace = true

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = "1.21.1"

  wait    = true
  timeout = 600

  values = [
    yamlencode({
      provider = {
        name = "aws"
      }

      policy   = "sync"
      registry = "txt"

      txtOwnerId = "as-bank-${var.environment}"

      domainFilters = [
        var.domain_name,
      ]

      sources = [
        "ingress",
      ]

      extraArgs = [
        "--aws-zone-type=public",
        "--zone-id-filter=${var.route53_zone_id}",
      ]

      serviceAccount = {
        create = true
        name   = "external-dns"
      }
    })
  ]
}
