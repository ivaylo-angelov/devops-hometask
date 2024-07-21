terraform {
  backend "s3" {
    bucket         = "devops-task-tf-state"
    region         = "eu-west-2"
    dynamodb_table = "terraform-lock-table"
    key            = "terraform.tfstate"
    encrypt        = true
  }
}