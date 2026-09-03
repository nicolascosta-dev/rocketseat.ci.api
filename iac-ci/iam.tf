# 1. Busca dinamicamente o certificado atual do GitHub
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "oidc-git" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # Usa o thumbprint buscado no bloco de dados acima
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

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
        # Usa o ARN do provider gerado no Terraform em vez de chumbado
        "Federated" : aws_iam_openid_connect_provider.oidc-git.arn
      },
      "Condition" : {
        "StringEquals" : {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        },
        "StringLike" : {
          # ATENÇÃO: Confirme se letras maiúsculas/minúsculas estão EXATAMENTE como no GitHub
          "token.actions.githubusercontent.com:sub" = "repo:nicolascosta-dev/*"
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