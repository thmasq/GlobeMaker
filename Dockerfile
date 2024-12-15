FROM archlinux:latest AS builder

RUN pacman --disable-sandbox -Syu --noconfirm --needed \
    base-devel \
    git \
    wget \
    unzip

RUN mkdir -p /tmp/ne_data \
    && wget https://naciscdn.org/naturalearth/110m/physical/ne_110m_land.zip -O /tmp/ne_data/land.zip \
    && unzip /tmp/ne_data/land.zip -d /tmp/ne_data \
    && rm /tmp/ne_data/land.zip

RUN useradd -m builder && echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /packages
RUN chown -R builder:builder /packages

USER builder

WORKDIR /packages
RUN git clone https://aur.archlinux.org/python-pyshp.git
WORKDIR /packages/python-pyshp
RUN if [ -z "$(ls *.pkg.tar.zst 2>/dev/null)" ]; then makepkg -si --noconfirm; else echo "Package already built. Skipping."; fi

WORKDIR /packages
RUN git clone https://aur.archlinux.org/python-cartopy.git
WORKDIR /packages/python-cartopy
RUN if [ -z "$(ls *.pkg.tar.zst 2>/dev/null)" ]; then makepkg -s --noconfirm; else echo "Package already built. Skipping."; fi

USER root

FROM archlinux:latest

COPY --from=builder /tmp/ne_data /app/ne_110m_land
COPY --from=builder /packages/python-pyshp/*.pkg.tar.zst /tmp/
COPY --from=builder /packages/python-cartopy/*.pkg.tar.zst /tmp/

RUN pacman --disable-sandbox -Syu --noconfirm --needed \
    python-gdal \
    python-pyproj \
    python-pillow \
    python-pyarrow \
    python-typing_extensions \
    python-matplotlib

RUN pacman -U --noconfirm /tmp/*.pkg.tar.zst

ENV PATH="/usr/local/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

WORKDIR /app

COPY makeGlobe.py .
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
