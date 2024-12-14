resource "aws_iam_role" "vpc_cni_role" {
  name = "vpc-cni-role"
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

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "eks_ng_cluster_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_ng_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_eks_node_group" "fiap_node_group" {
  cluster_name    = aws_eks_cluster.fiap_cluster.name
  node_group_name = "NG-${var.appName}"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  ami_type        = "AL2_x86_64"

  subnet_ids = [
    for subnet in data.aws_subnet.subnet : subnet.id
    if (
      data.aws_subnet.subnet[subnet.id].availability_zone == "us-east-1a" ||
      data.aws_subnet.subnet[subnet.id].availability_zone == "us-east-1b" ||
      data.aws_subnet.subnet[subnet.id].availability_zone == "us-east-1c" ||
      data.aws_subnet.subnet[subnet.id].availability_zone == "us-east-1d"
    )
  ]
  instance_types = [var.instanceType]
  disk_size      = 50

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_eks_cluster.fiap_cluster
  ]
}

