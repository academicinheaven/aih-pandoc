# Dockerfile for pandoc, pandoc-crossref, and pandoc-plot
# based on https://github.com/pandoc/dockerfiles
# ARG BUILDPLATFORM
# mambaorg/micromamba:debian12 is the latest release for Debian 12
ARG MICROMAMBA_VERSION="2.5.0-debian12"  # "latest" if Debian 13
# "@sha256:3955d0f1987accbcc382c37758a3d18c022eeed3e9f4a53f8f1e04feb5f576f8"
ARG BASE_IMAGE="mambaorg/micromamba:${MICROMAMBA_VERSION}"
ARG ENVIRONMENT_FILE=env.yaml
# The core Pandoc components need to be mutually compatible
# This is now set by versions.txt, these are just defaults
# TBD: Change to latest vs. preferred (Hackage)
ARG PANDOC_VERSION=latest
ARG PANDOC_CLI_VERSION=latest
ARG PANDOC_CROSSREF_VERSION=latest
ARG PANDOC_PLOT_VERSION=latest
# ARG LUA_VERSION=5.4


# #########################################################
# Stage: Patched version of Micromamba / Debian
# #########################################################
FROM "${BASE_IMAGE}" AS micromamba_patched

# Install security updates if base image is not yet patched
# Inspired by https://pythonspeed.com/articles/security-updates-in-docker/
# We may need to switch back to the original bash shell for all standard stuff,
# since Micromamba has its own shell script for all mamba-related stuff
# TODO: Check
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root
RUN apt-get update && apt-get -y upgrade && rm -rf /var/lib/apt/lists/*
# Back to the micromamba shell
# SHELL ["/usr/local/bin/_dockerfile_shell.sh"]
USER $MAMBA_USER
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]


# #########################################################
# Stage: Haskell build environment 
# #########################################################
# We use the same Haskell base image,
#    haskell:9.12-slim-bookworm
# as Pandoc in
# https://github.com/pandoc/dockerfiles/blob/main/x.y.z/debian/Dockerfile
# e.g.
# https://github.com/pandoc/dockerfiles/blob/main/3.8.3/debian/Dockerfile

# haskell:9.12.2-slim-bookworm

FROM haskell:9.12-slim-bookworm AS haskell_builder

ARG LUA_VERSION=5.4
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -q --no-allow-insecure-repositories update \
    && apt-get install --assume-yes --no-install-recommends \
        ca-certificates \
        liblua${LUA_VERSION}-dev \
        pkg-config \
        xz-utils \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
# Setup and configure cabal
# Use Cabal's default config location (~/.config/cabal/config).
# Initialize first, then overwrite with your config.
RUN cabal user-config init
# We copy directly from the submodule
COPY dockerfiles/cabal.root.config /root/.config/cabal/config
RUN cabal update
# Log versions of build environment
RUN cabal --version && ghc --version


# #########################################################
# Stage: Build pandoc, pandoc-crossref, and pandoc-plot
# #########################################################
FROM haskell_builder AS pandoc_binaries

ARG PANDOC_VERSION=""
ARG PANDOC_CLI_VERSION=""
ARG PANDOC_CROSSREF_VERSION=""
ARG PANDOC_PLOT_VERSION=""
RUN test -n "$PANDOC_VERSION" -a -n "$PANDOC_CLI_VERSION" -a -n "$PANDOC_CROSSREF_VERSION" -a -n "$PANDOC_PLOT_VERSION"
# ARG LUA_VERSION

# Log versions of build environment
RUN cabal --version && ghc --version
# Log ARGs
RUN echo "PANDOC_VERSION=${PANDOC_VERSION}" \
  && echo "PANDOC_CLI_VERSION=${PANDOC_CLI_VERSION}" \
  && echo "PANDOC_CROSSREF_VERSION=${PANDOC_CROSSREF_VERSION}" \
  && echo "PANDOC_PLOT_VERSION=${PANDOC_PLOT_VERSION}" 
#  && echo "LUA_VERSION=${LUA_VERSION}"
# Build pandoc and pandoc-cli
RUN set -eux; \
  cabal update; \
  cabal install -j \
    --installdir=/out/bin \
    --install-method=copy \
    --overwrite-policy=always \
    "pandoc-cli-${PANDOC_CLI_VERSION}" \
    "pandoc-crossref-${PANDOC_CROSSREF_VERSION}" \
    "pandoc-plot-${PANDOC_PLOT_VERSION}" \
    --constraint "pandoc == ${PANDOC_VERSION}" \
    --constraint "pandoc +embed_data_files"

# Show linked libs (debugging / sanity)
RUN set -eux; \
  for b in /out/bin/pandoc /out/bin/pandoc-crossref /out/bin/pandoc-plot; do \
    echo "===== ldd $b ====="; \
    ldd "$b" || true; \
  done
# Generate a minimal Debian runtime package list for these binaries.
# (Works because we're on Debian/bookworm in the builder stage.)
RUN set -eux; \
  libs="$(for b in /out/bin/pandoc /out/bin/pandoc-crossref /out/bin/pandoc-plot; do \
            ldd "$b" | awk '/=> \//{print $3} /^\//{print $1}'; \
          done | sort -u)"; \
  echo "===== shared objects ====="; echo "$libs"; \
  : > /out/runtime-packages.txt; \
  for so in $libs; do \
    # dpkg -S prints "package: path". We only want package name.
    dpkg -S "$so" 2>/dev/null | sed 's/:.*//' >> /out/runtime-packages.txt || true; \
  done; \
  sort -u /out/runtime-packages.txt -o /out/runtime-packages.txt; \
  echo "===== runtime Debian packages ====="; \
  cat /out/runtime-packages.txt
RUN echo OK: Pandoc binaries are now in /out/bin

# #########################################################
# Stage: Copy Pandoc binaries into fresh micromamba-patched
# (or aih-texlive)
# #########################################################

# TODO: Maybe use aih-texlive as the base image?
# TODO: Check required debian packages and versions
# TODO: TOP - compare with
# https://github.com/pandoc/dockerfiles/blob/main/3.8.3/debian/Dockerfile
# e.g. symlinks etc.
# https://github.com/pandoc/dockerfiles/blob/main/3.8.3/debian/core/Dockerfile
# https://github.com/pandoc/dockerfiles/blob/main/3.8.3/debian/extra/Dockerfile
# Maybe start with or align closer with those?
# think about uv instead of pip or mamba (but conda + pip is quite good for the moment)
FROM micromamba_patched AS aih_pandoc

ARG BASE_IMAGE
ARG PANDOC_VERSION
ARG PANDOC_CLI_VERSION
ARG PANDOC_CROSSREF_VERSION
ARG PANDOC_PLOT_VERSION
ARG DEBIAN_CODENAME
ARG DEBIAN_RELEASE
ARG IMAGE_TAG
# ---- OCI / provenance labels ----
LABEL org.opencontainers.image.title="aih-pandoc" \
      org.opencontainers.image.description="Pandoc toolchain image with pandoc, pandoc-crossref, and pandoc-plot built from Hackage" \
      org.opencontainers.image.version="${IMAGE_TAG}" \
      org.opencontainers.image.base.name="${BASE_IMAGE}" \
      org.opencontainers.image.vendor="Academic In Heaven" \
      org.opencontainers.image.licenses="GPL-2.0-or-later"
LABEL org.academicinheaven.pandoc.version="${PANDOC_VERSION}" \
      org.academicinheaven.pandoc-cli.version="${PANDOC_CLI_VERSION}" \
      org.academicinheaven.pandoc-crossref.version="${PANDOC_CROSSREF_VERSION}" \
      org.academicinheaven.pandoc-plot.version="${PANDOC_PLOT_VERSION}"
LABEL org.academicinheaven.os.debian.release="${DEBIAN_RELEASE}" \
      org.academicinheaven.os.debian.codename="${DEBIAN_CODENAME}"

ARG ENVIRONMENT_FILE
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
# TBD: Set user data directory?
# ENV XDG_DATA_HOME=/usr/local/share
# Create user data directory
# RUN mkdir -p "$XDG_DATA_HOME"/pandoc
USER root
# Create "freeze" folder to inspect installed packages etc.
RUN mkdir -p /usr/share/aih/freeze \
 && chmod 0755 /usr/share/aih /usr/share/aih/freeze
# Copy binaries + computed runtime deps list
COPY --from=pandoc_binaries /out/bin/ /usr/local/bin/
COPY --from=pandoc_binaries /out/runtime-packages.txt /usr/share/aih/freeze/runtime-packages.txt
COPY --chown=root:root ${ENVIRONMENT_FILE} /usr/share/aih/freeze/env.yaml
RUN set -eux; \
  chmod 0755 /usr/local/bin/pandoc /usr/local/bin/pandoc-crossref /usr/local/bin/pandoc-plot; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       gzip \
       tar \
       unzip \
  ; \
  xargs -r apt-get install -y --no-install-recommends < /usr/share/aih/freeze/runtime-packages.txt; \
  rm -rf /var/lib/apt/lists/* ; \
  pandoc --version; \
  pandoc-crossref --version; \
  pandoc-plot --help >/dev/null

# Add symlinks from
# https://github.com/pandoc/dockerfiles/blob/1cb0146d9fcad4682084ec86071e808f5a8de69b/3.8.3/debian/Dockerfile#L400C1-L416C38
RUN ln -sf /usr/local/bin/pandoc /usr/local/bin/pandoc-lua \
 && ln -sf /usr/local/bin/pandoc /usr/local/bin/pandoc-server

USER $MAMBA_USER
# TBD: Create Pandoc user directory
# RUN mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/pandoc"
RUN mkdir -p "$HOME/.local/share/pandoc"
# Install Python dependencies from ENVIRONMENT_FILE
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]       
# RUN echo --chown=${MAMBA_USER}:${MAMBA_USER} ${ENVIRONMENT_FILE}
RUN micromamba install -y -n base -f /usr/share/aih/freeze/env.yaml \
 && micromamba clean --all --yes
# COPY --chown=${MAMBA_USER}:${MAMBA_USER} ${ENVIRONMENT_FILE} /tmp/env.yaml
WORKDIR /usr/aih/data/src
ARG MAMBA_DOCKERFILE_ACTIVATE=1
COPY --chown=${MAMBA_USER}:${MAMBA_USER} tests tests
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]