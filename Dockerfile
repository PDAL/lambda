FROM lambci/lambda:build-python3.7 as builder

ARG http_proxy
ARG CURL_VERSION=7.70.1
ARG GDAL_VERSION=3.2.0
ARG GEOS_VERSION=3.8.1
ARG PROJ_VERSION=7.2.0
ARG LASZIP_VERSION=3.4.3
ARG GEOTIFF_VERSION=1.6.0
ARG PDAL_VERSION=2.2.0
ARG ENTWINE_VERSION=2.1.0
ARG DESTDIR="/build"
ARG PREFIX="/usr"
ARG PARALLEL=8
ARG CMAKE_VERSION=3.18.2



RUN \
  rpm --rebuilddb && \
  yum makecache fast && \
  yum install -y \
    automake16 \
    libpng-devel \
    nasm wget tar zlib-devel curl-devel zip libjpeg-devel rsync git ssh bzip2 automake \
    jq-libs jq-devel jq xz-devel openssl-devel ninja-build wget \
        glib2-devel libtiff-devel pkg-config libcurl-devel;   # required for pkg-config


#    curl -O https://mirror.centos.org/centos/6/extras/x86_64/Packages/centos-release-scl-rh-2-3.el6.centos.noarch.rpm && \
#    curl -O https://mirror.centos.org/centos/6/extras/x86_64/Packages/centos-release-scl-7-3.el6.centos.noarch.rpm && \

RUN \
    yum install -y iso-codes && \
    curl -O https://vault.centos.org/6.5/SCL/x86_64/scl-utils/scl-utils-20120927-11.el6.centos.alt.x86_64.rpm && \
    curl -O https://vault.centos.org/6.5/SCL/x86_64/scl-utils/scl-utils-build-20120927-11.el6.centos.alt.x86_64.rpm && \
    curl -O https://mirror.facebook.net/centos/6/extras/x86_64/Packages/centos-release-scl-rh-2-3.el6.centos.noarch.rpm && \
    curl -O https://mirror.facebook.net/centos/6/extras/x86_64/Packages/centos-release-scl-7-3.el6.centos.noarch.rpm && \
    rpm -Uvh *.rpm  && \
    rm *.rpm &&  \
    yum install -y devtoolset-7-gcc-c++ devtoolset-7-make devtoolset-7-build ;

SHELL [ "/usr/bin/scl", "enable", "devtoolset-7"]

RUN gcc --version


#RUN \
#    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
#    && chmod +x cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
#    && ./cmake-${CMAKE_VERSION}-Linux-x86_64.sh  --skip-license --prefix=/usr \
#    && cd /var/task \
#    && rm -rf cmake*

RUN \
    pip install cmake ninja

RUN git clone https://github.com/LASzip/LASzip.git laszip \
    && cd laszip \
    && git checkout ${LASZIP_VERSION} \
    && cmake  \
        -G Ninja \
        -DCMAKE_INSTALL_PREFIX=/usr/ \
        -DCMAKE_BUILD_TYPE="Release" \
     .  \
    && ninja -j ${PARALLEL} \
    && ninja install \
    && DESTDIR=/ ninja install \
    && cd /var/task \
    && rm -rf laszip*



RUN \
    git clone https://github.com/libgeos/geos.git geos \
    && cd geos*  \
    && cmake  \
        -G Ninja \
        -DCMAKE_INSTALL_PREFIX=/usr/ \
        -DCMAKE_BUILD_TYPE="Release" \
        -DBUILD_TESTING=OFF \
     .  \
    && ninja -j ${PARALLEL} \
    && ninja install \
    && DESTDIR=/ ninja install \
    && cd /var/task \
    && rm -rf geos*

ARG SQLITE_VERSION="sqlite-autoconf-3300100"
RUN wget https://www.sqlite.org/2019/${SQLITE_VERSION}.tar.gz \
    && tar zxvf ${SQLITE_VERSION}.tar.gz \
    && cd ${SQLITE_VERSION} \
    && ./configure --prefix=/usr \
    && make -j ${PARALLEL} \
    && make install \
    && DESTDIR=/ make install \
    && cd /var/task \
    && rm -rf sqlite*

RUN git clone https://github.com/OSGeo/PROJ.git --branch ${PROJ_VERSION} proj  \
#RUN git clone https://github.com/rouault/PROJ.git --branch rfc4_code_review proj\
    && cd proj \
    && ./autogen.sh \
    && SQLITE3_CFLAGS="-I/usr/include" SQLITE3_LIBS="-L/usr/lib -lsqlite3" ./configure --prefix=/usr \
    && make -j ${PARALLEL} \
    && make install \
    && DESTDIR=/ make install \
    && cd /var/task \
    && rm -rf proj*

RUN git clone --branch master https://github.com/OSGeo/libgeotiff.git --branch ${GEOTIFF_VERSION} \
    && cd libgeotiff/libgeotiff \
    && ./autogen.sh \
    && ./configure --prefix=/usr --with-proj=/usr \
    && make -j ${PARALLEL} \
    && make install \
    && DESTDIR=/ make install \
    && cd /var/task \
    && rm -rf libgeotiff*

RUN \
    wget https://github.com/facebook/zstd/releases/download/v1.4.5/zstd-1.4.5.tar.gz \
    && tar zxvf zstd-1.4.5.tar.gz \
    && cd zstd-1.4.5/build/cmake \
    && mkdir -p _build \
    && cd _build \
    && cmake  \
        -G Ninja \
        -DCMAKE_INSTALL_PREFIX=/usr/ \
        -DCMAKE_BUILD_TYPE="Release" \
        -DBUILD_TESTING=OFF \
     ..  \
    && ninja -j ${PARALLEL} \
    && ninja install \
    && DESTDIR=/ ninja install \
    && cd /var/task \
    && rm -rf zstd*


RUN git clone --branch release/ https://github.com/OSGeo/gdal.git --branch v${GDAL_VERSION} \
    && cd gdal/gdal \
    && ./configure --prefix=/usr \
            --mandir=/usr/share/man \
            --includedir=/usr/include/gdal \
            --with-threads \
            --without-libtool \
            --with-grass=no \
            --with-hide-internal-symbols=yes \
            --with-rename-internal-libtiff-symbols=yes \
            --with-rename-internal-libgeotiff-symbols=yes \
            --with-libtiff=/usr/ \
            --with-geos=/usr/bin/geos-config \
            --with-geotiff=/usr \
            --with-proj=/usr \
            --with-ogdi=no \
            --with-curl \
            --with-ecw=no \
            --with-mrsid=no \
    && make -j ${PARALLEL} \
    && make install \
    && DESTDIR=/ make install \
    && cd /var/task \
    && rm -rf gdal*


RUN \
    wget http://apache.mirrors.hoobly.com//xerces/c/3/sources/xerces-c-3.2.3.tar.gz \
    && tar zxvf xerces-c-3.2.3.tar.gz \
    && cd xerces-c-3.2.3 \
    && mkdir -p _build \
    && cd _build \
    && cmake .. \
        -G "Ninja" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DBUILD_TESTING=OFF \
    && ninja -j ${PARALLEL} \
    && ninja install \
    && DESTDIR= ninja install \
    && cd /var/task \
    && rm -rf xerces*


RUN \
    git clone https://github.com/PDAL/PDAL.git --branch ${PDAL_VERSION} \
    && cd PDAL \
    && git checkout $PDAL_VERSION \
    && mkdir -p _build \
    && cd _build \
    && cmake .. \
        -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_CXX_FLAGS="-std=c++11 -pg" \
        -DCMAKE_MAKE_PROGRAM=make \
        -DBUILD_PLUGIN_I3S=ON \
        -DBUILD_PLUGIN_E57=ON \
        -DWITH_LASZIP=ON \
        -DWITH_ZSTD=ON \
        -DCMAKE_LIBRARY_PATH:FILEPATH="$DESTDIR/usr/lib" \
        -DCMAKE_INCLUDE_PATH:FILEPATH="$DESTDIR/usr/include" \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DWITH_TESTS=OFF \
        -DCMAKE_INSTALL_LIBDIR=lib \
    && make  -j ${PARALLEL} \
    && make  install \
    && make install DESTDIR=/ \
    && DESTDIR=/ make install  \
    && cd /var/task \
    && rm -rf PDAL*

RUN \
    git clone https://github.com/connormanning/entwine.git --branch ${ENTWINE_VERSION} \
    && cd entwine \
    && mkdir -p _build \
    && cd _build \
    && cmake -G "Ninja" \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release .. \
    && ninja -j ${PARALLEL} \
    && ninja install \
    && DESTDIR=/ ninja install \
    && cd /var/task \
    && rm -rf entwine*

RUN wget https://github.com/Reference-LAPACK/lapack/archive/v3.9.0.tar.gz \
    && tar zxvf v3.9.0.tar.gz \
    && cd lapack-3.9.0/ \
    && mkdir -p _build \
    && cd _build \
    && cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release -G Ninja -DBUILD_SHARED_LIBS=ON \
    && ninja -j ${PARALLEL} \
    && ninja install \
    && DESTDIR=/ ninja install \
    && cd /var/task \
    && rm -rf lapack*

RUN wget https://github.com/xianyi/OpenBLAS/archive/v0.3.10.tar.gz \
    && tar zxvf v0.3.10.tar.gz \
    && cd OpenBLAS-0.3.10/ \
    && mkdir -p _build \
    && cd _build \
    && cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -G Ninja -DBUILD_SHARED_LIBS=ON \
    && ninja -j ${PARALLEL} \
    && ninja install \
    && DESTDIR=/ ninja install \
    && cd /var/task \
    && rm -rf OpenBLAS*

# scikit-build will respect our DESTDIR and put things in the wrong directory
RUN DESTDIR= python -m pip install PDAL --prefix /build/python \
    && python -m pip install pandas scipy scikit-learn --no-binary :all: --verbose --prefix /build/python \
    && cd /var/task \
    && rm -rf pdal-python

RUN DESTDIR= python -m pip install pytz  --target /build/python/lib/python3.7/site-packages/

RUN rm /build/usr/lib/*.la ; rm /build/usr/lib/*.a
RUN rm  /build/usr/lib64/*.a
RUN ldconfig
ADD package-pdal.sh /

