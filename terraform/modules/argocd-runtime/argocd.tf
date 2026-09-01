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

        cmp = {
          create = true

          plugins = {
            "as-bank-helm" = {
              discover = {
                fileName = "./Chart.yaml"
              }

              generate = {
                command = [
                  "sh",
                  "-c",
                ]

                args = [
                  <<-EOT
                    exec helm template "$ARGOCD_APP_NAME" . \
                      --namespace "$ARGOCD_APP_NAMESPACE" \
                      --values "values-$AS_BANK_ENVIRONMENT.yaml" \
                      --set-string "global.imageRegistry=$ECR_REGISTRY"
                  EOT
                ]
              }
            }
          }
        }
      }

      repoServer = {
        env = [
          {
            name  = "ECR_REGISTRY"
            value = var.ecr_registry
          }
        ]

        # The plugin can read Terraform-provided runtime values without putting
        # the AWS account ID in the GitOps repository.
        extraContainers = [
          {
            name = "cmp-as-bank-helm"

            command = [
              "/var/run/argocd/argocd-cmp-server",
            ]

            image = "quay.io/argoproj/argocd:v3.5.1"

            env = [
              {
                name  = "ECR_REGISTRY"
                value = var.ecr_registry
              },
              {
                name  = "AS_BANK_ENVIRONMENT"
                value = var.environment
              },
              {
                name  = "HELM_CACHE_HOME"
                value = "/tmp/helm/cache"
              },
              {
                name  = "HELM_CONFIG_HOME"
                value = "/tmp/helm/config"
              },
              {
                name  = "HELM_DATA_HOME"
                value = "/tmp/helm/data"
              },
            ]

            securityContext = {
              runAsNonRoot             = true
              runAsUser                = 999
              allowPrivilegeEscalation = false
              readOnlyRootFilesystem   = true

              seccompProfile = {
                type = "RuntimeDefault"
              }

              capabilities = {
                drop = ["ALL"]
              }
            }

            resources = {
              requests = {
                cpu    = "25m"
                memory = "64Mi"
              }

              limits = {
                cpu    = "200m"
                memory = "256Mi"
              }
            }

            volumeMounts = [
              {
                name      = "var-files"
                mountPath = "/var/run/argocd"
              },
              {
                name      = "plugins"
                mountPath = "/home/argocd/cmp-server/plugins"
              },
              {
                name      = "argocd-cmp-cm"
                mountPath = "/home/argocd/cmp-server/config/plugin.yaml"
                subPath   = "as-bank-helm.yaml"
              },
              {
                name      = "cmp-tmp"
                mountPath = "/tmp"
              },
            ]
          }
        ]

        volumes = [
          {
            name = "argocd-cmp-cm"

            configMap = {
              name = "argocd-cmp-cm"
            }
          },
          {
            name     = "cmp-tmp"
            emptyDir = {}
          },
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
