FROM lambci/lambda:build-python3.7 as builder

ARG http_proxy
ARG CURL_VERSION=7.63.0
ARG GDAL_VERSION=3.0.0
ARG GEOS_VERSION=3.7.2
ARG PROJ_VERSION=6.0.0
ARG LASZIP_VERSION=3.4.1
ARG GEOTIFF_VERSION=1.5.1
ARG PDAL_VERSION=1.9.1
ARG PDAL_PYTHON_VERSION=2.1.8
ARG NUM_BUILDERS=1
ARG DESTDIR="/build"
ARG PREFIX="/usr"

RUN \
  rpm --rebuilddb && \
  yum makecache fast && \
  yum install -y \
    automake16 \
    libpng-devel \
    nasm wget tar zlib-devel curl-devel zip libjpeg-devel rsync git ssh bzip2 automake \
        glib2-devel libtiff-devel pkg-config libcurl-devel;   # required for pkg-config



RUN \
    yum install -y iso-codes && \
    curl -O http://vault.centos.org/6.5/SCL/x86_64/scl-utils/scl-utils-20120927-11.el6.centos.alt.x86_64.rpm && \
    curl -O http://vault.centos.org/6.5/SCL/x86_64/scl-utils/scl-utils-build-20120927-11.el6.centos.alt.x86_64.rpm && \
    curl -O http://mirror.centos.org/centos/6/extras/x86_64/Packages/centos-release-scl-rh-2-3.el6.centos.noarch.rpm && \
    curl -O http://mirror.centos.org/centos/6/extras/x86_64/Packages/centos-release-scl-7-3.el6.centos.noarch.rpm && \
    rpm -Uvh *.rpm  && \
    rm *.rpm &&  \
    yum install -y devtoolset-7-gcc-c++ devtoolset-7-make devtoolset-7-build ;

SHELL [ "/usr/bin/scl", "enable", "devtoolset-7"]

RUN gcc --version


RUN \
    wget https://github.com/Kitware/CMake/releases/download/v3.14.3/cmake-3.14.3.tar.gz; \
    tar -zxvf cmake-3.14.3.tar.gz; \
    cd cmake-3.14.3; \
    ./bootstrap --prefix=/usr ;\
    make ;\
    make install DESTDIR=/


RUN \
    wget https://github.com/LASzip/LASzip/releases/download/$LASZIP_VERSION/laszip-src-$LASZIP_VERSION.tar.gz; \
    tar -xzvf laszip-src-$LASZIP_VERSION.tar.gz; \
    cd laszip-src-$LASZIP_VERSION;\
    cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_STATIC_LIBS=OFF \
        -DCMAKE_INSTALL_LIBDIR=lib \
    ; \
    make -j$NUM_BUILDERS; make install; make install DESTDIR= ; cd ..; \
    rm -rf laszip-src-${LASZIP_VERSION} laszip-src-$LASZIP_VERSION.tar.gz;

RUN \
    wget http://download.osgeo.org/geos/geos-$GEOS_VERSION.tar.bz2; \
    tar xjf geos*bz2; \
    cd geos*; \
    ./configure --prefix=$PREFIX CFLAGS="-O2 -Os"; \
    make -j$NUM_BUILDERS; make install; make install DESTDIR= ;\
    cd ..; \
    rm -rf geos*;

RUN \
    wget http://download.osgeo.org/proj/proj-$PROJ_VERSION.tar.gz; \
    tar -zvxf proj-$PROJ_VERSION.tar.gz; \
    cd proj-$PROJ_VERSION; \
    ./configure --prefix=$PREFIX; \
    make; make install; make install DESTDIR=; cd ..; \
    rm -rf proj-$PROJ_VERSION proj-$PROJ_VERSION.tar.gz

RUN \
    wget https://github.com/OSGeo/libgeotiff/releases/download/$GEOTIFF_VERSION/libgeotiff-$GEOTIFF_VERSION.tar.gz; \
    tar -xzvf libgeotiff-$GEOTIFF_VERSION.tar.gz; \
    cd libgeotiff-$GEOTIFF_VERSION; \
    ./configure \
        --prefix=$PREFIX --with-proj=/build/usr ;\
    make -j$NUM_BUILDERS; make install; make install DESTDIR=; cd ..; \
    rm -rf libgeotiff-$GEOTIFF_VERSION.tar.gz libgeotiff-$GEOTIFF_VERSION;

# GDAL
RUN \
    wget http://download.osgeo.org/gdal/$GDAL_VERSION/gdal-$GDAL_VERSION.tar.gz; \
    tar -xzvf gdal-$GDAL_VERSION.tar.gz; \
    cd gdal-$GDAL_VERSION; \
    ./configure \
        --prefix=$PREFIX \
        --with-geotiff=$DESTDIR/usr \
        --with-tiff=/usr \
        --with-curl=yes \
        --without-python \
        --with-geos=$DESTDIR/usr/bin/geos-config \
        --with-hide-internal-symbols=yes \
        CFLAGS="-O2 -Os" CXXFLAGS="-O2 -Os"; \
    make -j$NUM_BUILDERS; make install; make install DESTDIR= ; \
    cd $BUILD; rm -rf gdal-$GDAL_VERSION*

# compile numpy to save space https://stackoverflow.com/q/53274271
RUN \
    CFLAGS="-g0 -I/var/lang/include:/usr/include -L/var/lang/lib:/usr/lib:/var/local/lib" pip install numpy --compile --no-cache-dir --global-option=build_ext --global-option="-j $NUM_BUILDERS"

RUN \
    pip install cython packaging; \
    git clone https://github.com/PDAL/PDAL.git --branch $PDAL_VERSION --depth 1; \
    cd PDAL; \
    mkdir -p _build; \
    cd _build; \
    cmake .. \
        -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_FLAGS="-std=c++11" \
        -DCMAKE_MAKE_PROGRAM=make \
        -DBUILD_PLUGIN_I3S=ON \
        -DWITH_LASZIP=ON \
        -DCMAKE_LIBRARY_PATH:FILEPATH="$DESTDIR/usr/lib" \
        -DCMAKE_INCLUDE_PATH:FILEPATH="$DESTDIR/usr/include" \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DWITH_TESTS=OFF \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_PLUGIN_PYTHON=ON \
        -DPDAL_PYTHON_LIBRARY="libpython3.so" \
    ; \
    make -j$NUM_BUILDERS; make install; make install DESTDIR= ;

RUN \
    git clone https://github.com/PDAL/python pdalextension  --branch $PDAL_PYTHON_VERSION --depth 1; \
    cd pdalextension; \
    pip install . ;

RUN rm /build/usr/lib/*.la ; rm /build/usr/lib/*.a
RUN ldconfig
ADD package-pdal.sh /

