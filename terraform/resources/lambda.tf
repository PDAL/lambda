
resource "aws_lambda_function" "lambda_pdal_info" {
    function_name = "${var.prefix}-${var.stage}-info"
    description   = "Extracts metadata info from point clouds and raster files"

    image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.prefix}-${var.stage}-pdal_runner:${var.arch}"

    package_type  = "Image"
    architectures = ["${var.arch == "amd64" ? "x86_64" : "arm64"}"]
    role          = aws_iam_role.iam_role_for_lambda.arn
    depends_on = [ null_resource.ecr_image ]
    timeout  = var.function_timeout
    memory_size = 1024

    image_config {
      command = ["pdal_lambda.ecr.info.handler"]
    }
    tags = {
       name = var.prefix
       Name = "${var.prefix}:lambda.${var.stage}.info"
       stage = var.stage
    }

    environment {
      variables = {
        HOME = "/var/task"
      }
    }
}

resource "aws_lambda_function_event_invoke_config" "lambda_event_invoke_config" {
  function_name                = aws_lambda_function.lambda_pdal_info.function_name
  maximum_event_age_in_seconds = 60
  maximum_retry_attempts       = 0
}

output "info_lambda_name" {
  value = aws_lambda_function.lambda_pdal_info.function_name
}

