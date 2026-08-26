resource "aws_s3_bucket" "terraform_state" {
  #checkov:skip=CKV_AWS_18:State access is restricted to scoped project roles; a second persistent access-log bucket is outside the current scope.
  #checkov:skip=CKV_AWS_145:The state bucket already uses server-side AES-256 encryption; a customer-managed KMS key is not required by the project.
  #checkov:skip=CKV_AWS_144:Cross-region replication is intentionally out of scope until the project has an RTO that requires multi-region recovery.
  #checkov:skip=CKV2_AWS_62:Terraform state is not an event-driven workload, so bucket notifications have no consumer.
  #checkov:skip=CKV2_AWS_61:State history is retained through S3 versioning; automatic expiry is not enabled while the project is active.
  bucket = "as-bank-terraform-state-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
