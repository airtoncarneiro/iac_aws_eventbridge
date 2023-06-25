terraform {
  required_version = "~> 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.4.0" # or whatever version you want to use
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
  }
}
