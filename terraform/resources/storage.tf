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


locals {
    our_rendered_content = templatefile("${path.root}/../docker/info-event.tftpl", {bucket = aws_s3_bucket.storage.bucket})
}

resource "null_resource" "local" {
  triggers = {
    template = local.our_rendered_content
  }

  depends_on = [
    aws_s3_bucket.storage,
  ]

  # Render to local file on machine
  # https://github.com/hashicorp/terraform/issues/8090#issuecomment-291823613
  provisioner "local-exec" {
    command = format(
      "cat <<\"EOF\" > \"%s\"\n%s\nEOF",
      "${path.root}/../docker/info-event.json",
      local.our_rendered_content
    )
  }
}
