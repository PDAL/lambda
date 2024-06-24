locals {
    ecr_repository_name = "${var.prefix}-${var.stage}-pdal_runner"
}

resource aws_ecr_repository runner_ecr_repo {
    name = local.ecr_repository_name
    image_tag_mutability = "MUTABLE"
    force_delete = true
}

resource null_resource ecr_image {
 triggers = {
   docker_file = md5(file("${path.root}/../docker/Dockerfile.runner"))
   environment_file = md5(file("${path.root}/../docker/run-environment.yml"))
   entry_file = md5(file("${path.root}/../docker/python-entry.sh"))
   handlers = sha1(join("", [for f in fileset("${path.root}/../handlers/", "**"): filesha1("${path.root}/../handlers/${f}")]))
 }

provisioner "local-exec" {
   command = <<EOF
           aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin "https://${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
           if [ "${var.arch}" = "arm64" ]; then
            LAMBDA_IMAGE="amazon/aws-lambda-provided:al2023.2024.05.01.10"
           else
            LAMBDA_IMAGE="amazon/aws-lambda-provided:al2"
           fi

           cp -r "${path.root}/../handlers/" "${path.root}/../docker/handlers"
           echo "Building image architecture ${var.arch} with image $LAMBDA_IMAGE"
           docker buildx build --platform linux/${var.arch} \
                --build-arg LAMBDA_IMAGE="$LAMBDA_IMAGE" \
                --build-arg RIE_ARCH=${var.arch == "amd64" ? "x86_64" : "arm64"} \
                --load \
                -t ${aws_ecr_repository.runner_ecr_repo.repository_url}:${var.arch} \
                "${path.root}/../docker/" \
                -f "${path.root}/../docker/Dockerfile.runner"
           docker push "${aws_ecr_repository.runner_ecr_repo.repository_url}:${var.arch}" -q
           rm -rf "${path.root}/../docker/handlers"
       EOF
 }
}


data aws_ecr_image runner_image {
    repository_name = aws_ecr_repository.runner_ecr_repo.name
    image_tag = var.arch
    depends_on = [ null_resource.ecr_image, aws_ecr_repository.runner_ecr_repo ]
}
