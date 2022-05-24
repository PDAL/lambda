#!/bin/bash


event=$(<test-event.json)
echo $event
curl -POST -v "http://localhost:9000/2015-03-31/functions/function/invocations" -d @test-event.json


