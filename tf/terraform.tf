provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      autor   = var.autor,
      projeto = var.projeto
    }
  }
}
