variable "region" {
  default = "us-east-1"
}

variable "appName" {
  default = "fiap-tech-challenge"
}

variable "authMode" {
  default = "API_AND_CONFIG_MAP"
}

variable "policyArn" {
  default = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}

variable "node_group_name" {
  default = "fiap-tech-nodes"
}

variable "instanceType" {
  default = "t3.medium"
}

variable "cidrBlocks" {
  default = "172.31.0.0/16"
}