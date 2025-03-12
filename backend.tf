terraform {
  backend "s3" {
    bucket = "fiap-hackathon-terraform-state-bucket"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}