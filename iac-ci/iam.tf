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
        "Federated" : "arn:aws:iam::634530189592:oidc-provider/token.actions.githubusercontent.com"
      },
      "Condition" : {
        "StringEquals" : {
          "token.actions.githubusercontent.com:aud" : [
            "sts.amazonaws.com"
          ]
        },
        "StringLike" : {
          "token.actions.githubusercontent.com:sub" : [
            "repo:nicolascosta-dev/rocketseat.ci.cpi:ref:refs/heads/main",
            "repo:nicolascosta-dev/rocketseat.ci.cpi:ref:refs/heads/main"
          ]
        }
      }
    }]
  })

  inline_policy {
    name = "ecr_app_permission"

    policy = jsonencode ({
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

  tags = {
    iac = true
  }
}