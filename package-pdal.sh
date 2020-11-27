#!/bin/sh

export PDAL_DEPLOY_DIR=/pdal-package
export SK_DEPLOY_DIR=/sk-package

PDAL_PACKAGE_NAME="pdal-lambda-deploy.zip"
SK_PACKAGE_NAME="pdal-python-lambda-deploy.zip"

mkdir -p $PDAL_DEPLOY_DIR/lib
mkdir -p $PDAL_DEPLOY_DIR/bin
mkdir -p $PDAL_DEPLOY_DIR/share

PYTHON_DEPLOY_DIR=$SK_DEPLOY_DIR/python/lib/python3.7/site-packages
mkdir -p $PYTHON_DEPLOY_DIR
mkdir -p $SK_DEPLOY_DIR/lib


cp /build/python/lib/libpdal_plugin_filter_python.so $SK_DEPLOY_DIR/lib
cp /build/python/lib/libpdal_plugin_reader_numpy.so $SK_DEPLOY_DIR/lib
#cp -r /usr/lib64/atlas/lib*.so* $SK_DEPLOY_DIR/lib
cp -r /usr/lib64/libgfortran.so* $SK_DEPLOY_DIR/lib
cp -r /usr/lib64/libquadmath.so* $SK_DEPLOY_DIR/lib
cp -r /usr/lib64/libblas.so* $SK_DEPLOY_DIR/lib
cp -r /usr/lib64/libopenblas.so* $SK_DEPLOY_DIR/lib
cp -r /usr/lib64/liblapack.so* $SK_DEPLOY_DIR/lib


strip_symbols()
{
    DIR=$1
    pushd $1

    FILES=$(find . -name '*.so*')

    for f in $FILES
    do
    echo "Stripping unneeded symbols from $f"
        strip --strip-unneeded $f
    done;
    popd
}

strip_symbols /build
strip_symbols $SK_DEPLOY_DIR

rm -rf /build/usr/lib/*.a

cd /build
find . -name '*.pyc' -delete
find . -name '*cmake*' -exec rm -rf {} +;
#find . -name '*tests*' -exec rm -rf {} +;
#find . -name '*test*' -exec rm -rf {} +;
find . -name '*__pycache__*' -exec rm -rf {} +;
find . -name '*datasets*' -exec rm -rf {} +;

rm -rf ./python/lib/python3.7/site-packages/joblib/test
cd python
find . -type d -name "datasets" -exec rm -rf \;
cp lib/libpdal_* $SK_DEPLOY_DIR/lib

cd ..

cp -r /build/usr/lib/* $PDAL_DEPLOY_DIR/lib
cp -r /build/usr/lib/libpdal_* $PDAL_DEPLOY_DIR/lib
cp -r /build/usr/lib64/* $PDAL_DEPLOY_DIR/lib
cp -r /build/usr/bin/gdal* $PDAL_DEPLOY_DIR/bin
cp -r /build/usr/bin/entwine $PDAL_DEPLOY_DIR/bin
cp -r /build/usr/bin/pdal $PDAL_DEPLOY_DIR/bin
cp -r /build/usr/bin/cs2cs $PDAL_DEPLOY_DIR/bin
cp -r /build/usr/bin/ogr* $PDAL_DEPLOY_DIR/bin

rm -rf /build/lib/cmake

copy_support()
{
    OUTDIR=$1

    cp /usr/lib64/libjpeg.so.62.0.0 $OUTDIR/lib/
    cp /usr/lib64/libxml2.so.2.9.1 $OUTDIR/lib/
    cp /usr/lib64/liblzma.so.5.2.2 $OUTDIR/lib/
    cp /usr/lib64/libtiff.so.5.2.0 $OUTDIR/lib/
    cp /usr/lib64/libpng.so.3.49.0 $OUTDIR/lib/
    cp /usr/lib/libsqlite3.so.0.8.6 $OUTDIR/lib/
}

copy_support $PDAL_DEPLOY_DIR


#cp -r /usr/lib64/atlas/libptf77blas.so* $SK_DEPLOY_DIR/lib
#cp -r /usr/lib64/atlas/libgfortran.so* $SK_DEPLOY_DIR/lib

rm /build/python/lib/libpdal_plugin_filter_python.so
rm /build/python/lib/libpdal_plugin_reader_numpy.so

cp -r /build/python/lib/python3.7/site-packages/* $PYTHON_DEPLOY_DIR




#rsync -ax /build/usr/share/gdal $PDAL_DEPLOY_DIR/share/
rsync -ax /build/usr/share/proj/proj.db $PDAL_DEPLOY_DIR/share/proj/

cd $PDAL_DEPLOY_DIR
zip --symlinks -9 -ruq ../$PDAL_PACKAGE_NAME ./
rm -rf $PDAL_DEPLOY_DIR
echo "writing deploy dir $PDAL_DEPLOY_DIR"

cd $SK_DEPLOY_DIR
zip --symlinks -9 -ruq ../$SK_PACKAGE_NAME ./
rm -rf $SK_DEPLOY_DIR
echo "writing deploy dir $SK_DEPLOY_DIR"

cp /$PDAL_PACKAGE_NAME /output
cp /$SK_PACKAGE_NAME /output


