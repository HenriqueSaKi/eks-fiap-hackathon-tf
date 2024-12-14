resource "aws_iam_role" "eks_service_role" {
  name = "eks-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_controller_policy" {
  role       = aws_iam_role.eks_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_policy" "eks_policy" {
  name        = "eks_policy"
  description = "Policy for EKS cluster access"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_eks_access_policy_association" "eks-policy" {
  cluster_name  = aws_eks_cluster.fiap_cluster.name
  policy_arn    = var.policyArn
  principal_arn = data.aws_iam_role.eks_service_role.arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_cluster" "fiap_cluster" {
  name     = "EKS-${var.appName}"
  role_arn = data.aws_iam_role.eks_service_role.arn

  vpc_config {
    subnet_ids = [
      for subnet in data.aws_subnet.subnet :
      subnet.id if (
        subnet.availability_zone == "us-east-1a" ||
        subnet.availability_zone == "us-east-1b" ||
        subnet.availability_zone == "us-east-1c"
      )
    ]
    security_group_ids = [aws_security_group.eks_sg.id]
  }

  access_config {
    authentication_mode = var.authMode
  }

  depends_on = [
    aws_nat_gateway.nat_gateway,
    aws_internet_gateway.internet_gateway,
    aws_route_table.private_route_table
  ]
}

resource "aws_eks_addon" "vpc_cni_addon" {
  cluster_name             = aws_eks_cluster.fiap_cluster.name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.eks_service_role.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  addon_version = "v1.19.0-eksbuild.1"

  timeouts {
    create = "60m"  # Aumenta o tempo de criação para 60 minutos
  }
}

resource "aws_iam_role_policy_attachment" "vpc_cni_policy_attachment" {
  role       = aws_iam_role.eks_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

