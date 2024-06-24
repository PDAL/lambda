#!/bin/sh

env
if [ -z "${AWS_LAMBDA_RUNTIME_API}" ]; then
    exec /usr/bin/aws-lambda-rie /var/task/bin/python -m awslambdaric $1
else
    exec /var/task/bin/python -m awslambdaric $1
fi


