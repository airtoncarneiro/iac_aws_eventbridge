variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "autor" {
  description = "Author"
  type        = string
  default     = "Airton"
}

variable "projeto" {
  description = "Project"
  type        = string
  default     = "Hands On - Event Bridge"
}

variable "bucket" {
  description = "Nome do bucket que será usado"
  type        = string
  default     = "eventbridge-handson"
}

variable "bucket_bronze" {
  description = "Nome da 'pasta' onde serão armazenados os dados do Firehose"
  type        = string
  default     = "bronze"
}

