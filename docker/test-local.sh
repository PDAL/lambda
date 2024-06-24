#!/bin/bash

eventfilename=$1

event=$(<$eventfilename)
echo $event
curl -POST -v "http://localhost:9000/2015-03-31/functions/function/invocations" -d @$eventfilename


