resource "aws_ecr_repository" "application" {
  for_each = local.ecr_repositories

  name                 = "as-bank/${each.value}"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
