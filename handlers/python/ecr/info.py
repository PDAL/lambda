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

        # env['VERBOSE'] = "1"

        response = util.run(command, env = env)
        logger.debug(f'response {response}')

        j = json.loads(response)
        infos.append(j)

    return infos


