variable "region" {
  default = "us-east-1"
}

variable "projectName" {
  default = "fiap-tech-challenge"
}

variable "vpcCidr" {
  default = "172.31.0.0/16"
}

variable "instanceType" {
  default = "t3a.medium"
}

variable "accountIdVoclabs" {
  default = "489247846468"
}

variable "authMode" {
  default = "API_AND_CONFIG_MAP"
}

variable "policyArn" {
  default = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}