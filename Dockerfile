FROM lambci/lambda:build-python3.7 as builder

ARG http_proxy
ARG CURL_VERSION=7.68.0
ARG GDAL_VERSION=3.0.4
ARG GEOS_VERSION=3.8.1
ARG PROJ_VERSION=7.0.0
ARG LASZIP_VERSION=3.4.3
ARG GEOTIFF_VERSION=1.5.1
ARG PDAL_VERSION=2.1.0
ARG ENTWINE_VERSION=2.1.0
ARG DESTDIR="/build"
ARG PREFIX="/usr"
ARG PARALLEL=4
ARG CMAKE_VERSION=3.17.1


RUN \
  rpm --rebuilddb && \
  yum makecache fast && \
  yum install -y \
    automake16 \
    libpng-devel \
    nasm wget tar zlib-devel curl-devel zip libjpeg-devel rsync git ssh bzip2 automake \
    jq-libs jq-devel jq xz-devel openssl-devel ninja-build wget \
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
    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz \
    && tar -zxvf cmake-${CMAKE_VERSION}.tar.gz \
    && cd cmake-${CMAKE_VERSION} \
    && ./bootstrap --parallel=${PARALLEL} --prefix=/usr \
    && make -j ${PARALLEL} \
    && make install DESTDIR=/ \
    && cd /var/task \
    && rm -rf cmake*


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


RUN git clone --branch release/ https://github.com/OSGeo/gdal.git --branch v${GDAL_VERSION} \
    && cd gdal/gdal \
    && ./configure --prefix=/usr \
            --mandir=/usr/share/man \
            --includedir=/usr/include/gdal \
            --with-threads \
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
    wget https://github.com/facebook/zstd/releases/download/v1.4.4/zstd-1.4.4.tar.gz \
    && tar zxvf zstd-1.4.4.tar.gz \
    && cd zstd-1.4.4/build/cmake \
    && mkdir -p _build \
    && cd _build \
    && cmake  \
        -G Ninja \
        -DCMAKE_INSTALL_PREFIX=/usr/ \
        -DCMAKE_BUILD_TYPE="Release" \
     ..  \
    && ninja -j ${PARALLEL} \
    && ninja install \
    && DESTDIR=/ ninja install \
    && cd /var/task \
    && rm -rf zstd*

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
    && ninja -j ${PARALLEL} \
    && ninja install \
    && DESTDIR= ninja install \
    && cd /var/task \
    && rm -rf xerces*

ADD https://api.github.com/repos/PDAL/PDAL/commits?sha=${PDAL_VERSION} \
    /tmp/bust-cache

ENV \
    PACKAGE_PREFIX=${DESTDIR}/python

RUN \
    git clone https://github.com/PDAL/PDAL.git --branch ${PDAL_VERSION} \
    && cd PDAL \
    && git checkout $PDAL_VERSION \
    && mkdir -p _build \
    && cd _build \
    && cmake .. \
        -G "Unix Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_FLAGS="-std=c++11" \
        -DCMAKE_MAKE_PROGRAM=make \
        -DBUILD_PLUGIN_I3S=ON \
        -DBUILD_PLUGIN_E57=ON \
        -DWITH_LASZIP=ON \
        -DWITH_ZSTD=ON \
        -DCMAKE_LIBRARY_PATH:FILEPATH="$DESTDIR/usr/lib" \
        -DCMAKE_INCLUDE_PATH:FILEPATH="$DESTDIR/usr/include" \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DWITH_TESTS=OFF \
        -DCMAKE_INSTALL_LIBDIR=lib \
    && make  -j ${PARALLEL} \
    && make  install \
    && make install DESTDIR=/ \
    && DESTDIR=/ make install  \
    && cd /var/task \
    && rm -rf pdal*

#RUN \
#    git clone https://github.com/PDAL/python.git pdal-python \
#    && cd pdal-python \
#    && pip install numpy Cython packaging \
#    && ls /usr/bin/pd* \
#    && PDAL_CONFIG=/usr/bin/pdal-config pip install . --no-binary numpy -t $PACKAGE_PREFIX \
#    && ls $PACKAGE_PREFIX

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

RUN rm /build/usr/lib/*.la ; rm /build/usr/lib/*.a
RUN rm /build/usr/lib64/*.a
RUN ldconfig
ADD package-pdal.sh /

