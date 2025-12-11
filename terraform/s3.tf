resource "aws_s3_bucket" "bootstrap" {
  bucket        = var.bootstrap_bucket
  force_destroy = true

  tags = {
    Name = "${var.project_name}-bootstrap-scripts"
  }
}

resource "aws_s3_bucket_public_access_block" "bootstrap_block" {
  bucket                  = aws_s3_bucket.bootstrap.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_versioning" "bootstrap_versioning" {
  bucket = aws_s3_bucket.bootstrap.id

  versioning_configuration {
    status = "Enabled"
  }
}
