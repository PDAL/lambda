================================================================================
PDAL Lambda Container for AWS
================================================================================

Instructions
--------------------------------------------------------------------------------


Note that this set of scripts has only been run on an M1/M2 Mac. Multi-arch
containers are often quite slow.

0. Set your AWS variables into your environment:

   ::

      AWS_ACCESS_KEY_ID=something
      AWS_SECRET_ACCESS_KEY=somethingelse
      AWS_DEFAULT_REGION=us-east-1

1. (optional) Edit your variables

   ::

      cat terraform/pdal.tfvars

      environment_name="pdal-lambda"
      arch="arm64"

2. Initialize your Terraform Environment

   ::

      cd terraform
      terraform init
      terraform validate
      terraform apply -var-file pdal.tfvars

   The Terraform configuration will create some resources including an ECR
   repository to store the image, a role for execution of the lambda,
   and the lambda itself. Adjust your configuration as needed in `./terraform/resources`

3. Test locally

   Fire up the Lambda Docker container in one terminal:

   ::

      cd docker
      ./run-local.sh /var/task/python-entry.sh pdal_lambda.ecr.info.handler

   In another terminal, issue the test. Note that it currently defaults to running
   on port 9000. Adjust the script as necessary.

   ::

      cd docker
      ./test-local.sh info-event.json

4. Test remotely


   ::

      cd docker
      ./test-remote.sh info-event.json
      cat response.json

