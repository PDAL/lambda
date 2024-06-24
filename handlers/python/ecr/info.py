import json
import os
from pathlib import Path

import logging

# set up logger for CloudWatch
logger = logging.getLogger(__file__)
logger.setLevel(logging.DEBUG)

from . import util

def handler(event, context):
    """Takes a PDAL pipeline and executes it"""

    logger.debug("'info_handler' handler called")
    logger.debug(event)


    infos = []
    for path in util.extract_records(event['Records']): # yields s3path

        logger.debug(f'processing {path}')


        command = f'pdal info --debug {path.as_uri()}'
        env = os.environ.copy()

        # FIXME This hardcodes our s3 region to east to read our test file
        env['AWS_REGION'] = "us-east-1"

        response = util.run(command, env = env)
        logger.debug(f'response {response}')

        j = json.loads(response[0])
        infos.append(j)

    return infos


