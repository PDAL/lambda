data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    actions    = ["sts:AssumeRole"]
    effect     = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "iam_role_for_lambda" {
  name   = "${var.prefix}_${var.stage}_Lambda_Function_Role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
}


data "aws_iam_policy_document" "iam_for_lambda_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "CreateCloudWatchLogs"
  }

  statement {
    actions = [
        "s3:GetObject",
        "s3:GetBucketTagging",
        "s3:PutObjectTagging",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject",
    ]
    effect    = "Allow"
    resources = [aws_s3_bucket.storage.arn]
    sid       = "ReadS3"
  }

}

resource "aws_iam_policy" "lambda_logging_policy" {
  name = "${var.prefix}-${var.stage}-lambda-logging-policy"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.iam_for_lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_logging_policy_attachment" {
  role       = aws_iam_role.iam_role_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name         = "${var.prefix}_${var.stage}_aws_iam_policy_for_terraform_aws_lambda_role"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy = data.aws_iam_policy_document.iam_for_lambda_policy_document.json
}

resource "aws_iam_role_policy_attachment" "basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.iam_role_for_lambda.name
}