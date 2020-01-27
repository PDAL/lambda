#!/bin/sh

export DEPLOY_DIR=/output/lambda

PACKAGE_NAME="lambda-deploy.zip"
mkdir -p $DEPLOY_DIR/lib
mkdir -p $DEPLOY_DIR/share

cp -r /build/usr/lib/* $DEPLOY_DIR/lib
cp -r /build/usr/lib64/* $DEPLOY_DIR/lib
cp -r /build/usr/bin $DEPLOY_DIR/bin
cp /usr/lib64/libjpeg.so.62.0.0 $DEPLOY_DIR/lib/
cp /usr/lib64/libxml2.so.2.9.1 $DEPLOY_DIR/lib/
cp /usr/lib64/liblzma.so.5.2.2 $DEPLOY_DIR/lib/
cp /usr/lib64/libtiff.so.5.2.0 $DEPLOY_DIR/lib/
cp /usr/lib64/libpng.so.3.49.0 $DEPLOY_DIR/lib/
cp /usr/lib/libsqlite3.so.0.8.6 $DEPLOY_DIR/lib/
rm -rf $DEPLOY_DIR/lib/*.a
rm -rf $DEPLOY_DIR/bin/projinfo
rm -rf $DEPLOY_DIR/bin/gie
rm -rf $DEPLOY_DIR/lib/libpdal_plugin*
rm -rf $DEPLOY_DIR/lib/python3.6
cp -r /build/python/* $DEPLOY_DIR

FILES=$DEPLOY_DIR/lib/*.so*
for f in $FILES
do
echo "Stripping unneeded symbols from $f"
	strip --strip-unneeded $f
done;

rsync -ax /build/usr/share/gdal $DEPLOY_DIR/share/
rsync -ax /build/usr/share/proj $DEPLOY_DIR/share/

cd $DEPLOY_DIR
zip --symlinks -9 -ruq ../$PACKAGE_NAME ./
rm -rf $DEPLOY_DIR
echo "writing deploy dir $DEPLOY_DIR"




