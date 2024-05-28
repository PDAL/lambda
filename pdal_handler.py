import json
import subprocess
import shlex

from osgeo import osr

from shapely.ops import transform
from shapely.geometry import mapping, shape

import pyproj
from pyproj import CRS
from pyproj.transformer import TransformerGroup

import logging

# set up logger for CloudWatch
logger = logging.getLogger(__file__)
logger.setLevel(logging.DEBUG)

import pdal
import base64


def gatherImage(filename):

    command = f"gdaldem hillshade {filename} output.png"
    job = subprocess.Popen(shlex.split(command),
                           stdin=subprocess.PIPE,
                           stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
    try:
        outs, errs = job.communicate(timeout=15)
        logger.error(errs)
    except subprocess.TimeoutExpired:
        job.kill()
        outs, errs = job.communicate()
        logger.error(errs)

def handler(event, context):
    """Takes a PDAL pipeline and executes it"""

    logger.debug("'transform' handler called")
    logger.debug(event)

    pipeline = event['pipeline']
    pipeline = pdal.Pipeline(json.dumps(pipeline))
    count = pipeline.execute()

    gatherImage('iowa.tif')

    image = open('output.png','rb').read()
    out = {
            'headers': { "Content-Type": "image/png" },
            'statusCode': 200,
            'count': count,
            'body': base64.b64encode(image).decode('utf-8'),
            'isBase64Encoded': True
        }

    return json.dumps(out)


if __name__=='__main__':
    print (transform_geometry(example, None))
