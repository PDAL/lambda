resource "null_resource" "upload_autzen" {
  triggers = {
    shell_hash = "${filesha256("${path.root}/../data/autzen-classified.copc.laz")}"
  }

  provisioner "local-exec" {
    command =  "aws s3 cp ${path.root}/../data/autzen-classified.copc.laz s3://${aws_s3_bucket.storage.bucket}/autzen-classified.copc.laz"
  }
  depends_on = [
    aws_s3_bucket.storage,
  ]
}

resource "aws_s3_bucket" "storage" {
    bucket = "${var.prefix}-${var.stage}-pdal-lambda-storage"
    force_destroy = true

    depends_on = [
      aws_lambda_function.lambda_pdal_info,
    ]

    tags = {
      Name = "${var.prefix}:s3.${var.stage}.storage"
      prefix = var.prefix
      stage = var.stage
    }
}

output "bucket" {
    description = "bucket"
    value = aws_s3_bucket.storage.bucket
}
