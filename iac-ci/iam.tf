resource "aws_iam_openid_connect_provider" "oidc-git" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "2b18947a6a9fc7764fd8b5fb18a863b0c6dac24f"
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
        # Referência dinâmica apontando para o recurso OIDC criado acima
        "Federated" : aws_iam_openid_connect_provider.oidc-git.arn
      },
      "Condition" : {
        "StringEquals" : {
          "token.actions.githubusercontent.com:aud" : [
            "sts.amazonaws.com"
          ]
        },
        "StringLike" : {
          "token.actions.githubusercontent.com:sub" : [
            "repo:nicolascosta-dev/rocketseat.ci.api:*"
          ]
        }
      }
    }]
  })

  tags = {
    iac = true
  }
}

# Política separada para evitar o warning de "inline_policy is deprecated"
resource "aws_iam_role_policy" "ecr_app_permission" {
  name = "ecr_app_permission"
  role = aws_iam_role.ecr-role.id # Vincula esta política à Role criada acima

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
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}