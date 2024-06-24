resource "aws_lambda_function" "lambda-pdal-pipeline" {
    function_name = "${var.prefix}-${var.stage}-pipeline"
    description   = "Runs PDAL pipelines"

    image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.prefix}-${var.stage}-pdal_runner:${var.arch}"

    package_type  = "Image"
    architectures = ["${var.arch == "amd64" ? "x86_64" : "arm64"}"]
    role          = aws_iam_role.lambda_role.arn
    depends_on = [ null_resource.ecr_image ]
    timeout  = var.function_timeout
    memory_size = 1024

    image_config {
      command = ["lambda.ecr.pipeline.handler"]
    }
    tags = {
       name = var.prefix
       Name = "${var.prefix}:lambda.${var.stage}.pipeline"
       stage = var.stage
    }

    environment {
      variables = {
        HOME = "/var/task"
      }
    }
}

resource "aws_lambda_function" "lambda-pdal-info" {
    function_name = "${var.prefix}-${var.stage}-info"
    description   = "Extracts metadata info from point clouds and raster files"

    image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.prefix}-${var.stage}-pdal_runner:${var.arch}"

    package_type  = "Image"
    architectures = ["${var.arch == "amd64" ? "x86_64" : "arm64"}"]
    role          = aws_iam_role.lambda_role.arn
    depends_on = [ null_resource.ecr_image ]
    timeout  = var.function_timeout
    memory_size = 1024

    image_config {
      command = ["pdal_handler.info_handler"]
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