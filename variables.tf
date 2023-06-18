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

variable "json_path" {
  description = "Path to the policy and roles files"
  default     = "/source/aws/"
}
