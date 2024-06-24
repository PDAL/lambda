import json
import os

from cloudpathlib import S3Path

import logging
import subprocess
import shlex

# set up logger for CloudWatch
logger = logging.getLogger(__file__)
logger.setLevel(logging.DEBUG)


def run(cargs, working_dir=None, env = None):
    cargs = shlex.split(cargs)
    logger.debug(" ".join(cargs))
    if env:
        local_env = env
    else:
        local_env = os.environ.copy()

    p = subprocess.Popen(
        cargs,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        encoding="utf8",
        cwd = working_dir,
        env = local_env,
    )
    ret = p.communicate()

    body, error = ret
    if p.returncode != 0:
        logger.error(cargs)
        logger.error(error)
        error = {"args": cargs, "error": error, "body": body}
        raise AttributeError(error)

    return body




def extract_records(records):

    # prefixes = []

    for record in records:

        handle = None
        if 'receiptHandle' in record:
            handle = record['receiptHandle']

        logger.debug(f"message {record}")

        if record['eventSource'] == 'aws:sqs':
            # pipeline comes through record['body'] as text
            body = json.loads(record['body'])
            logger.debug(f"body {body}")
            message = json.loads(body['Message'])
            logger.debug(f"message {message}")
            bucket = message['bucket']
            key = message['key'].strip('/')

        if record['eventSource'] == 'aws:sns':
            # pipeline comes through record['body'] as text
            message = json.loads(record['message'])
            bucket = message['bucket']
            key = message['key'].strip('/')

        elif record['eventSource'] == 'aws:s3':

            # pipeline is the bucket/key
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']

        key = key.lstrip('/')
        # uri = os.path.join('s3://', bucket, key)
        uri = f's3://{bucket}/{key}'
        key = S3Path(uri)
        yield key

