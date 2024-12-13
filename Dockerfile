FROM alpine:latest AS builder

RUN apk add --no-cache \
    wget \
    tar \
    gcc \
    g++ \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    patch \
    musl-dev \
    openssl-dev \
    zlib-dev \
    readline-dev \
    sqlite-dev \
    bzip2-dev \
    libffi-dev \
    unzip \
    # Geospatial dependencies
    gdal-dev \
    proj-dev \
    # Image processing dependencies
    jpeg-dev \
    libpng-dev \
    freetype-dev \
    tiff-dev \
    lcms2-dev \
    openjpeg-dev \
    # Mapnik dependencies
    boost-dev\
    icu-dev \
    postgresql-dev \
    sqlite-dev \
    zlib-dev \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    tiff-dev \
    proj-dev \
    gdal-dev \
    harfbuzz-dev \
    libxml2-dev \
    protobuf-dev \
    python3-dev \
    py3-setuptools

RUN mkdir -p /tmp/ne_data \
    && wget https://naciscdn.org/naturalearth/110m/physical/ne_110m_land.zip -O /tmp/ne_data/land.zip \
    && unzip /tmp/ne_data/land.zip -d /tmp/ne_data \
    && rm /tmp/ne_data/land.zip

WORKDIR /tmp
RUN wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz \
    && tar xzf Python-2.7.18.tgz

WORKDIR /tmp/Python-2.7.18
RUN ./configure \
    --prefix=/usr/local \
    --enable-shared \
    --with-ensurepip=install \
    && make \
    && make install

RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py \
    && python get-pip.py

WORKDIR /tmp
RUN wget https://github.com/mapnik/mapnik/releases/download/v3.0.12/mapnik-v3.0.12.tar.bz2 \
    && tar xjf mapnik-v3.0.12.tar.bz2

WORKDIR /tmp/mapnik-v3.0.12
RUN ./configure \
    --prefix=/usr/local \
    --with-python=/usr/local/bin/python \
    && make \
    && make install

RUN pip install \
    GDAL==2.1.0 \
    pyproj==1.9.6 \
    Pillow==6.2.2 \
    mapnik==0.1 \
    numpy==1.16.6

FROM alpine:latest

COPY --from=builder /usr/local /usr/local
COPY --from=builder /usr/lib/python2.7/site-packages /usr/local/lib/python2.7/site-packages
COPY --from=builder /tmp/ne_data /app/ne_110m_land

RUN apk add --no-cache \
    libstdc++ \
    libgcc \
    gdal \
    proj \
    mapnik \
    jpeg \
    libpng \
    freetype \
    tiff \
    lcms2 \
    openjpeg

ENV PATH="/usr/local/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"
ENV PYTHONPATH="/usr/local/lib/python2.7/site-packages:${PYTHONPATH}"

WORKDIR /app

COPY makeGlobe.py .

RUN pip install -r requirements.txt

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
