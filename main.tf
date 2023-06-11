provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      autor   = var.autor,
      projeto = var.projeto
    }
  }
}

resource "aws_iam_role" "lambda_and_kinesis_role" {
  name = "lambda_and_kinesis_role"

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


data "archive_file" "lambda_func_payload" {
  type        = "zip"
  source_dir  = "${path.module}/source/aws"
  output_path = "${path.module}/func_payload.zip"
}


resource "aws_iam_role_policy_attachment" "lambda_e_kinesis_policy" {
  role       = aws_iam_role.lambda_and_kinesis_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole"
}

resource "aws_lambda_function" "lambda_func_payload" {
  function_name    = "capture_external_post_event_to_kinesis"
  filename         = data.archive_file.lambda_func_payload.output_path
  role             = aws_iam_role.lambda_and_kinesis_role.arn
  handler          = "lambda_func_payload.capture_external_post_event_to_kinesis"
  source_code_hash = filebase64sha256(data.archive_file.lambda_func_payload.output_path)
  timeout          = 60
  runtime          = "python3.8"
}

resource "aws_api_gateway_rest_api" "api_to_lambda_func_payload" {
  name        = "api_on_gateway"
  description = "API Description"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api_to_lambda_func_payload.id
  parent_id   = aws_api_gateway_rest_api.api_to_lambda_func_payload.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api_to_lambda_func_payload.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.api_to_lambda_func_payload.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_func_payload.invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_to_lambda_func_payload.id
  stage_name  = "dev"

  # Este recurso depende do resource, method e integration, então nós os incluímos no depends_on
  depends_on = [
    aws_api_gateway_resource.resource,
    aws_api_gateway_method.method,
    aws_api_gateway_integration.integration,
  ]
}

output "invoke_url" {
  value = "https://${aws_api_gateway_deployment.deployment.rest_api_id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_deployment.deployment.stage_name}"
}


resource "aws_lambda_permission" "permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_func_payload.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api_to_lambda_func_payload.execution_arn}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

resource "random_pet" "unique_id" {
  length    = 2
  separator = "-"
}
resource "aws_s3_bucket" "bucket" {
  bucket = "eventbridge-${random_pet.unique_id.id}"
}

output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "S3BucketPolicy"
  path        = "/"
  description = "Policy for S3 bucket policy operations"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutBucketPolicy"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "s3_bucket_policy_attachment" {
  name       = "S3BucketPolicyAttachment"
  roles      = [aws_iam_role.lambda_and_kinesis_role.name]
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}


data "aws_iam_policy_document" "private" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.bucket.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:userid"
      values   = ["*"]
    }
  }
}

resource "aws_iam_role_policy" "kinesis_put_record_policy" {
  name = "kinesis_put_record_policy"
  role = aws_iam_role.lambda_and_kinesis_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Effect   = "Allow"
        Resource = aws_kinesis_stream.kinesis_stream.arn
      }
    ]
  })
}

resource "aws_kinesis_stream" "kinesis_stream" {
  name        = "kinesis_stream"
  shard_count = 1
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name        = "firehose_stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.lambda_and_kinesis_role.arn
    bucket_arn          = aws_s3_bucket.bucket.arn
    prefix              = "nome_prefixo/"
    error_output_prefix = "nome_prefixo_erro/"
    s3_backup_mode      = "Disabled"
    compression_format  = "UNCOMPRESSED"
  }
}
