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

