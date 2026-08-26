output "release_name" {
  description = "Helm release name for the Karpenter controller."
  value       = helm_release.karpenter.name
}

output "config_release_name" {
  description = "Helm release containing the AS Bank NodePool and EC2NodeClass."
  value       = helm_release.karpenter_config.name
}
