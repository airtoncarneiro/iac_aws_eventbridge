provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      autor = var.autor,
      projeto = var.projeto
    }
  }
}

resource "aws_iam_role" "lambda_e_kinesis_policy" {
  name = "lambda_e_kinesis_policy"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "firehose.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


# resource "aws_iam_role_policy_attachment" "role_lambda_e_kinesis_policy_policy" {
#   role       = aws_iam_role.lambda_e_kinesis_policy.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole"
# }

# resource "aws_lambda_function" "lambda_func" {
#   function_name = "lambda_function_name"

#   filename         = "lambda_func_payload.zip"
#   role             = aws_iam_role.lambda_e_kinesis_policy.arn
#   handler          = "lambda_func_payload.lambda_func_payload"

#   source_code_hash = filebase64sha256("lambda_func_payload.zip")

#   runtime = "python3.8"
# }


# resource "aws_api_gateway_rest_api" "api" {
#   name        = "api_name"
#   description = "API Description"
# }

# resource "aws_api_gateway_resource" "resource" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   parent_id   = aws_api_gateway_rest_api.api.root_resource_id
#   path_part   = "{proxy+}"
# }

# resource "aws_api_gateway_method" "method" {
#   rest_api_id   = aws_api_gateway_rest_api.api.id
#   resource_id   = aws_api_gateway_resource.resource.id
#   http_method   = "POST"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "integration" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.resource.id
#   http_method = aws_api_gateway_method.method.http_method

#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.lambda_func.invoke_arn
# }

# resource "aws_lambda_permission" "permission" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.lambda_func.function_name
#   principal     = "apigateway.amazonaws.com"

#   source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
# }

# resource "aws_kinesis_stream" "kinesis_stream" {
#   name        = "kinesis_stream"
#   shard_count = 1
# }

# resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
#   name        = "firehose_stream"
#   destination = "extended_s3"

#   extended_s3_configuration {
#     role_arn            = aws_iam_role.lambda_e_kinesis_policy.arn
#     bucket_arn          = "arn:aws:s3:::mychallengeoneventbridge"
#     prefix              = "nome_prefixo/"
#     error_output_prefix = "nome_prefixo_erro/"
#     s3_backup_mode      = "Disabled"
#     compression_format  = "UNCOMPRESSED"
#   }
# }
