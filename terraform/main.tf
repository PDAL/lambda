module "resources" {
    source    = "./resources"

    prefix    = var.environment_name
    arch    = var.arch
    stage   = var.stage

}

variable "environment_name" {
    type = string
}

variable "arch" {
    type = string
    default = "arm64"
}

variable "stage" {
    type = string
    default = "dev"
}






output "environment" {
    description = "Environment name"
    value = module.resources.prefix
}

output "arch" {
    description = "ECR Architecture (amd64 or arm64)"
    value = var.arch
}

output "stage" {
    description = "Deployment stage"
    value = var.stage
}
