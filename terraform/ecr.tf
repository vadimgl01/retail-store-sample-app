resource "aws_ecr_repository" "retail_vadim_store_ecr_repos" {
  count                = length(var.ecr_repos)
  name                 = var.ecr_repos[count.index]
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repo_urls" {
  value = aws_ecr_repository.retail_vadim_store_ecr_repos[*].repository_url
}
