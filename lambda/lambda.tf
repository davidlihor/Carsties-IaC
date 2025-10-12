data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "py_lambda" {
  function_name = "python_lambda"
  role          = aws_iam_role.lambda_role.arn

  handler = "lambda_function.handler"
  runtime = "python3.9"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout = 300

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.compliance_topic.arn
      S3_BUCKET     = module.s3-bucket.s3_bucket_id
    }
  }

  tags = {
    Name = "SecurityAuditLambda"
  }
}
