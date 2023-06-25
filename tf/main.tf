data "archive_file" "lambda_func_payload" {
  type        = "zip"
  source_dir  = "../source/aws"
  output_path = "../func_payload.zip"
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

resource "aws_iam_role" "lambda_and_kinesis_role" {
  name = "lambda_and_kinesis_role"

  description        = "Role para que a Lambda e Kinesis se interajam"
  assume_role_policy = file("lambda_and_kinesis_role.json")
}

resource "aws_iam_role_policy_attachment" "lambda_e_kinesis_policy" {
  role       = aws_iam_role.lambda_and_kinesis_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole"
}

resource "aws_iam_policy" "s3_bucket_policy" {
  name        = "S3BucketPolicy"
  path        = "/"
  description = "Policy for S3 bucket policy operations"

  policy = templatefile("s3_policy.tpl", { bucket_arn = aws_s3_bucket.bucket.arn })
}


resource "aws_iam_policy_attachment" "s3_bucket_policy_attachment" {
  name       = "S3BucketPolicyAttachment"
  roles      = [aws_iam_role.lambda_and_kinesis_role.name]
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}

resource "aws_iam_role_policy" "kinesis_put_record_policy" {
  name = "kinesis_put_record_policy"
  role = aws_iam_role.lambda_and_kinesis_role.id

  policy = templatefile("kinesis_put_record_policy.tpl", { stream_arn = aws_kinesis_stream.kinesis_stream.arn, bucket_arn = aws_s3_bucket.bucket.arn })
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

resource "aws_lambda_permission" "permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_func_payload.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api_to_lambda_func_payload.execution_arn}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

resource "aws_kinesis_stream" "kinesis_stream" {
  name             = "kinesis_stream"
  shard_count      = 1
  retention_period = 24
}

resource "aws_kinesis_firehose_delivery_stream" "firehose_stream" {
  name        = "firehose_stream_3"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.lambda_and_kinesis_role.arn
    bucket_arn          = aws_s3_bucket.bucket.arn
    prefix              = var.bucket_bronze
    error_output_prefix = ""
    s3_backup_mode      = "Disabled"
    compression_format  = "UNCOMPRESSED"
    buffering_size      = 1
    buffering_interval  = 60
  }

  kinesis_source_configuration {
    #kinesis_stream_arn = aws_kinesis_stream.kinesis_stream.arn
    kinesis_stream_arn = aws_kinesis_stream.kinesis_stream.arn
    role_arn           = aws_iam_role.lambda_and_kinesis_role.arn
  }
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

  depends_on = [
    aws_api_gateway_resource.resource,
    aws_api_gateway_method.method,
    aws_api_gateway_integration.integration,
  ]
}
