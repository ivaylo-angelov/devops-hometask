terraform {
  backend "s3" {
    bucket         = "devops-task-tf-states"
    region         = "eu-west-1"
    dynamodb_table = "terraform-lock-table"
    key            = "terraform.tfstate"
    encrypt        = true
  }
}