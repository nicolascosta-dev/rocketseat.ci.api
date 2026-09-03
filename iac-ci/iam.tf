resource "aws_iam_openid_connect_provider" "oidc-git" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  
  # Estes são os 3 Thumbprints oficiais e raízes que a AWS aceita hoje para o GitHub
  thumbprint_list = [
    "1b511abead59c6ce207077c0bf0e0043b1382612",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = {
    iac = true
  }
}

resource "aws_iam_role" "ecr-role" {
  name = "ecr-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : "sts:AssumeRoleWithWebIdentity",
      "Principal" : {
        "Federated" : aws_iam_openid_connect_provider.oidc-git.arn
      },
      "Condition" : {
        "StringEquals" : {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        # Ignora letras maiúsculas/minúsculas e trava na branch main
        "StringEqualsIgnoreCase" : {
          "token.actions.githubusercontent.com:sub": "repo:nicolascosta-dev/rocketseat.ci.api:ref:refs/heads/main"
        }
      }
    }]
  })

  tags = {
    iac = true
  }
}

resource "aws_iam_role_policy" "ecr_app_permission" {
  name = "ecr_app_permission"
  role = aws_iam_role.ecr-role.name

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid = "Statement1"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
        ]
        Effect = "Allow"
        Resource = "*"
      },
    ]
  })
}