resource "aws_iam_policy" "policy_custom" {
  name = "policy-custom"
  policy = jsonencoded({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "iam:GetRole",
          "eks:AccessKubernetesApi",
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_custom" {
  user       = "arn:aws:sts::489247846468:assumed-role/voclabs/user3713687=satoshikisaki@hotmail.com"
  policy_arn = aws_iam_policy.policy_custom.arn
}