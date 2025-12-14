#############################################
# IAM Role for EC2 Nodes (allows S3 access)
#############################################

resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

#############################################
# IAM Policy allowing S3 bucket read
#############################################

resource "aws_iam_policy" "s3_bootstrap_policy" {
  name        = "${var.project_name}-s3-bootstrap-policy"
  description = "Allow EC2 to download bootstrap scripts from S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
	  "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.bootstrap.arn,
          "${aws_s3_bucket.bootstrap.arn}/*"
        ]
      }
    ]
  })
}

#############################################
# Attach policy to EC2 role
#############################################

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_bootstrap_policy.arn
}

#############################################
# Instance Profile for EC2 nodes
#############################################

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

#############################################
# Attach ECR ReadOnly Policy (for Kubernetes nodes)
#############################################
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


#############################################
# IAM for GitHub Actions (CI/CD User)
# Creates a dedicated, least-privilege user for pushing to ECR.
#############################################

# 1. Create the dedicated IAM Policy with ECR Push Permissions
resource "aws_iam_policy" "ci_ecr_push_policy" {
  # AWS Resource Name: retail-vadim-github-actions-ecr-push-policy
  name        = "${var.project_prefix}-github-actions-ecr-push-policy"
  description = "Least privilege policy for GitHub Actions to login and push images to ECR"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          # Required for ECR login
          "ecr:GetAuthorizationToken",
          # Required actions for pushing images (write access)
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:CreateRepository",
          "ecr:DescribeRepositories"
        ],
        "Resource" : "*" # Applies to all ECR resources
      }
    ]
  })
}

# 2. Create the dedicated, prefixed IAM User
resource "aws_iam_user" "ci_github_actions_user" {
  # AWS Resource Name: retail-vadim-github-actions-user
  name = "${var.project_prefix}-github-actions-user"
}

# 3. Attach the Policy to the User
resource "aws_iam_user_policy_attachment" "ci_ecr_push_attachment" {
  user       = aws_iam_user.ci_github_actions_user.name
  policy_arn = aws_iam_policy.ci_ecr_push_policy.arn
}

# 4. Create Access Keys for the User
resource "aws_iam_access_key" "ci_github_actions_key" {
  user = aws_iam_user.ci_github_actions_user.name
}

# 5. Output the Credentials to be saved as GitHub Secrets
output "ci_aws_access_key_id" {
  description = "AWS Access Key ID for CI/CD User (Save as GitHub Secret AWS_ACCESS_KEY_ID)"
  value       = aws_iam_access_key.ci_github_actions_key.id
  sensitive   = true
}

output "ci_aws_secret_access_key" {
  description = "AWS Secret Access Key for CI/CD User (Save as GitHub Secret AWS_SECRET_ACCESS_KEY)"
  value       = aws_iam_access_key.ci_github_actions_key.secret
  sensitive   = true
}
