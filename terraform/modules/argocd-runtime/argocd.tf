resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "10.4.0"

  wait    = true
  timeout = 900

  values = [
    yamlencode({
      configs = {
        cm = {
          "resource.customizations.health.argoproj.io_Application" = <<-EOT
          hs = {}
          hs.status = "Progressing"
          hs.message = ""

          if obj.status ~= nil then
            if obj.status.health ~= nil then
              hs.status = obj.status.health.status

              if obj.status.health.message ~= nil then
                hs.message = obj.status.health.message
              end
            end
          end

          return hs
        EOT
        }
      }

      repoServer = {
        # GitOps must not contain the AWS account ID embedded in private ECR URLs.
        env = [
          {
            name  = "ECR_REGISTRY"
            value = var.ecr_registry
          }
        ]
      }
    })
  ]
}

resource "helm_release" "gitops_root" {
  name      = "as-bank-gitops-root"
  namespace = "argocd"
  chart     = "${path.module}/chart"

  wait    = true
  timeout = 600

  set = [
    {
      name  = "environment"
      value = var.environment
    },
    {
      name  = "repositoryUrl"
      value = var.gitops_repository_url
    },
    {
      name  = "revision"
      value = var.gitops_revision
    },
  ]

  depends_on = [
    helm_release.argocd,
  ]
}
