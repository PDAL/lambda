#!/bin/sh

export DEPLOY_DIR=/output/lambda

PACKAGE_NAME="lambda-deploy.zip"

# make deployment directory and add lambda handler
cp -r /build/usr/lib $DEPLOY_DIR/lib
cp -r /build/usr/bin $DEPLOY_DIR/bin
cp /usr/lib64/libjpeg.so.62.0.0 $DEPLOY_DIR/lib/
cp /usr/lib64/libxml2.so.2.9.1 $DEPLOY_DIR/lib/
cp /usr/lib64/liblzma.so.5.0.99 $DEPLOY_DIR/lib/
cp /usr/lib64/libtiff.so.5.2.0 $DEPLOY_DIR/lib/
cp /usr/lib64/libpng.so.3.49.0 $DEPLOY_DIR/lib/
cp /usr/lib64/libsqlite3.so.0.8.6 $DEPLOY_DIR/lib/
mkdir $DEPLOY_DIR/python
cp -r /usr/lib64/libsqlite3.so.0.8.6 $DEPLOY_DIR/lib/
cp /var/lang/lib/python3.7/site-packages/cython.py $DEPLOY_DIR/python/
cp -r /var/lang/lib/python3.7/site-packages/Cython $DEPLOY_DIR/python/
cp -r /var/lang/lib/python3.7/site-packages/numpy $DEPLOY_DIR/python/
cp -r /var/lang/lib/python3.7/site-packages/pyximport $DEPLOY_DIR/python/
cp -r /var/lang/lib/python3.7/site-packages/pdal $DEPLOY_DIR/python/
cp /var/lang/lib/python3.7/site-packages/pyparsing.py $DEPLOY_DIR/python/

rm -rf $DEPLOY_DIR/lib/*.a
rm -rf $DEPLOY_DIR/bin/projinfo
rm -rf $DEPLOY_DIR/bin/gie

rsync -ax /build/usr/share/gdal $DEPLOY_DIR/share/
rsync -ax /build/usr/share/proj $DEPLOY_DIR/share/

cd $DEPLOY_DIR
zip --symlinks -9 -ruq ../$PACKAGE_NAME ./
rm -rf $DEPLOY_DIR



