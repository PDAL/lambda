//VARIABLES

variable "prefix" {
    type = string
}


variable "stage" {
    type = string
    default = "dev"
}

variable "arch" {
    type = string
    default = "arm64"
}

variable "function_timeout" {
    type = number
    default = 300
}


variable "lambda_python_runtime" {
    type = string
    default = "python3.10"
}


output "prefix" {
    description = "prefix"
    value = var.prefix
}



