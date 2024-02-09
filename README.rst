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

1. Build the containers. It should make both an arm64 and amd64 image

   ::

      $ ./build.sh pdal-lambda

2. Create an ECR repository in your account for the ``pdal-lambda``
   image

   ::

      aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION
      aws ecr create-repository \
         --repository-name pdal-lambda \
         --region $AWS_DEFAULT_REGION

3. Build the containers. It should make both an arm64 and amd64 image

   ::

      $ ./build.sh pdal-lambda

4. Push the containers

   ::
      $ ./push.sh pdal-lambda