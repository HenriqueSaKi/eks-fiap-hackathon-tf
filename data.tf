data "aws_vpc" "vpc" {
  filter {
    name   = "cidr-block"
    values = [var.cidrBlocks]
  }
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_subnet" "subnet" {
  for_each = toset(data.aws_subnets.subnets.ids)
  id       = each.value
}

data "aws_iam_role" "eks_service_role" {
  name = aws_iam_role.eks_service_role.name
}
