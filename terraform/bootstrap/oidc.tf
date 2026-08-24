resource "aws_iam_openid_connect_provider" "github" {
  url = "https://${local.github_oidc_host}"

  client_id_list = [
    "sts.amazonaws.com",
  ]
}
