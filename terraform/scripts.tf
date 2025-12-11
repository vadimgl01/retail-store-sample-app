locals {
  kube_common    = file("${path.module}/scripts/kube-common.sh")
  control_plane  = file("${path.module}/scripts/control-plane.sh")
  worker         = file("${path.module}/scripts/worker.sh")
}

resource "aws_s3_object" "kube_common" {
  bucket  = aws_s3_bucket.bootstrap.bucket
  key     = "kube-common.sh"
  content = local.kube_common
}

resource "aws_s3_object" "control_plane" {
  bucket  = aws_s3_bucket.bootstrap.bucket
  key     = "control-plane.sh"
  content = local.control_plane
}

resource "aws_s3_object" "worker" {
  bucket  = aws_s3_bucket.bootstrap.bucket
  key     = "worker.sh"
  content = local.worker
}

