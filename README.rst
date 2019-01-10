================================================================================
PDAL Lambda Layer for AWS
================================================================================

In December 2018, AWS released `Lambda Layers`_, which allow you to stack together
software runtime layers with AWS Lambda functions. Layers relax the requirements that
single Lambda functions must be less than 50mb, and now allow you to stack up to
five layers at 50mb each, and these layers can be composed with versioning and
other AWS management facilities that you would expect to use.

This repository borrows concepts from Development Seed's `GeoLambda`_ project, but
it simplifies the effort to a few things:

1. Build a Docker container based on https://github.com/lambci/lambci for `PDAL`_
   and its dependencies

2. Construct a ``.zip`` file package of the binaries and ``.so`` libraries needed
   to run PDAL and GDAL as a Lambda Layer

3. Provide a script to create a public PDAL Lambda Layer using the package

Instructions
--------------------------------------------------------------------------------

1. Build the Package. It's going to run docker and do a bunch of stuff. At the
   end when it is successful, you should have a ``lambda-deploy.zip`` file
   in your directory.

   ::

      $ ./build.sh

2. Set your ``AWS_PROFILE`` and ``AWS_REGION`` variables:


   ::

      $ export AWS_PROFILE=hobu
      $ export AWS_REGION=us-east-1

3. Execute the ``create-lambda-layer.sh`` bash script. It requires the `jq`_
   command in your path.

   ::

      $ ./create-lambda-layer.sh
      Published version 6 for Lambda layer pdal
      Setting execution access to public for version 6 for Lambda layer pdal
      Layer pdal is available at 'arn:aws:lambda:us-east-1:163178234892:layer:pdal'

.. _`Lambda Layers`: https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html
.. _`GeoLambda`: https://github.com/developmentseed/geolambda
.. _`jq`: https://stedolan.github.io/jq/
.. _`PDAL`: https://pdal.io
