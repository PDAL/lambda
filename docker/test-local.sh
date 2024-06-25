#!/bin/bash

eventfilename=$1

if [ -z "$AWS_ACCESS_KEY_ID" ]
then
    echo "AWS_ACCESS_KEY_ID must be set in environment!"
    exit 1;
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]
then
    echo "AWS_SECRET_ACCESS_KEY must be set in environment!"
    exit 1;
fi


event=$(<$eventfilename)
echo $event
curl -POST -v "http://localhost:9000/2015-03-31/functions/function/invocations" -d @$eventfilename


