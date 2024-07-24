# Dockerfile for pandoc, pandoc-crossref, and pandoc-plot
# based on https://github.com/pandoc/dockerfiles
ARG BUILDPLATFORM
ARG MICROMAMBA_VERSION=latest
ARG ENVIRONMENT_FILE=env.yaml
ARG BASE_IMAGE=mambaorg/micromamba
# Platform is used for URIs of binaries, mainly Pandoc
# Use ARG PLATFORM=amd64 for Intel (not tested)
# This is currently not used
# ARG PLATFORM=arm64
ARG LUA_VERSION=5.4
# The core Pandoc components need to be mutually compatible
# This is now set by versions.txt, these are just defaults
# TBD: Change to latest.
ARG PANDOC_VERSION=3.2
ARG PANDOC_CLI_VERSION=3.2
ARG PANDOC_CROSSREF_VERSION=0.3.17.1
ARG PANDOC_PLOT_VERSION=1.8.0

# Stage 1: Patched version of Micromamba / Debian
FROM --platform=$BUILDPLATFORM ${BASE_IMAGE}:${MICROMAMBA_VERSION} AS micromamba_patched
ARG PANDOC_VERSION
ARG PANDOC_CLI_VERSION
ARG PANDOC_CROSSREF_VERSION
ARG PANDOC_PLOT_VERSION
# Install security updates if base image is not yet patched
# Inspired by https://pythonspeed.com/articles/security-updates-in-docker/
# We need to switch back to the original bash shell for all standard stuff,
# since Micromamba has its own shell script for all mamba-related stuff
# TODO: Check
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root
RUN apt-get update && apt-get -y upgrade && rm -rf /var/lib/apt/lists/*
# Back to the micromamba shell
# SHELL ["/usr/local/bin/_dockerfile_shell.sh"]
USER $MAMBA_USER
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]

# Stage 2: Haskell build environment
# Build pandoc, pandoc-cli, pandoc-crossref and pandoc-plot for debian-bookworm and arm64
# In multiple steps for performance reasons
# https://github.com/lierdakil/pandoc-crossref#building-from-hackage-with-cabal-install
FROM micromamba_patched AS haskell_build
ARG LUA_VERSION
ARG PANDOC_VERSION
ARG PANDOC_CLI_VERSION
ARG PANDOC_CROSSREF_VERSION
ARG PANDOC_PLOT_VERSION
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive
USER root
# Install Haskell build environment, see https://www.haskell.org/ghcup/install/
# Pandoc Dockerfile differences:
# - libgmp-dev=2:6.* \
# - not using: cabal-debian \
RUN apt-get --no-allow-insecure-repositories update \
  && apt-get install -y \
  bash \
  ca-certificates \
  build-essential \
  cabal-debian \
  cabal-install \
  curl \
  fakeroot=* \
  git \
  ghc=* \
  libffi-dev \
  libffi8 \
  libgmp-dev \
  libgmp10 \
  lua$LUA_VERSION \
  liblua$LUA_VERSION-dev \
  libncurses-dev \
  libncurses5 \
  libtinfo5 \
  pkg-config \
  zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*
# Back to the micromamba shell
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]
USER $MAMBA_USER

# Stage 3: Pandoc and Pandoc CLI
FROM haskell_build as pandoc_binaries
ARG PANDOC_VERSION
ARG PANDOC_CLI_VERSION
ARG PANDOC_CROSSREF_VERSION
ARG PANDOC_PLOT_VERSION
# Debug ARGs
RUN echo "PANDOC_VERSION=${PANDOC_VERSION}" \
  && echo "PANDOC_CLI_VERSION=${PANDOC_CLI_VERSION}" \
  && echo "PANDOC_CROSSREF_VERSION=${PANDOC_CROSSREF_VERSION}" \
  && echo "PANDOC_PLOT_VERSION=${PANDOC_PLOT_VERSION}"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root
# OLD, will be removed
# This will be copied from the git submodule and updated via 
# ./build.sh update
# COPY cabal.root.config /root/.cabal/config
# We copy directly from the submodule
COPY dockerfiles/cabal.root.config /root/.cabal/config
# Build pandoc and pandoc-cli
# TBD: Add version specs!
# -fembed_data_files is critical to make the resulting binary self-contained
# https://pandoc.org/installing.html#creating-a-relocatable-binary
RUN cabal --version \
  && ghc --version \
  && cabal v2-update 


# DEBUG
#  && cabal v2-install --install-method=copy \
#  pandoc-${PANDOC_VERSION} \
#  pandoc-cli-${PANDOC_CLI_VERSION} \
#  pandoc-crossref-${PANDOC_CROSSREF_VERSION} \
#  pandoc-plot-${PANDOC_PLOT_VERSION} \
#  -fembed_data_files

# Note: The Pandoc dockerfiles use cabal build:
# Build pandoc and pandoc-crossref. The `allow-newer` is required for
# when pandoc-crossref has not been updated yet, but we want to build
# anyway.
# RUN cabal v2-update \
#  && cabal v2-build \
#      --allow-newer 'lib:pandoc' \
#      --disable-tests \
#      --disable-bench \
#      --jobs \
#      . $extra_packages
RUN echo OK: Pandoc binaries are now in "$HOME/.cabal/bin"
# Back to the micromamba shell
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]
USER $MAMBA_USER
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]

# Stage 4: Copy into fresh micromamba-patched (or aih-texlive)
# FROM micromamba_patched as aih-pandoc
FROM --platform=${BUILDPLATFORM} ${BASE_IMAGE}:${MICROMAMBA_VERSION} AS aih-pandoc
ARG LUA_VERSION
ARG ENVIRONMENT_FILE
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive
USER root

# DEBUG
# Copy Pandoc, pandoc-cli, pandoc-crossref, and pandoc-plot from previous stage
#COPY --from=pandoc_binaries \
#  /root/.cabal/bin \
#  /usr/local/bin

# TODO:
# Maybe add pandoc symlinks and install runtime dependencies
# RUN ln -s /usr/local/bin/pandoc /usr/local/bin/pandoc-lua \
#  && ln -s /usr/local/bin/pandoc /usr/local/bin/pandoc-server \
RUN apt-get --no-allow-insecure-repositories update \
  && apt-get install -y \
       ca-certificates=\* \
       curl \
       gzip \
       liblua$LUA_VERSION-0=\* \
       lua$LUA_VERSION \
       liblua$LUA_VERSION-dev \
       libatomic1=\* \
       libgmp10=\* \
       libpcre3=\* \
       libyaml-0-2=\* \
       lua-lpeg=\* \
       perl \
       tar \
       unzip \
       wget \
       xzdec \
       xz-utils \
       zlib1g=\* \
  && rm -rf /var/lib/apt/lists/*
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]       
USER $MAMBA_USER
RUN echo --chown=${MAMBA_USER}:${MAMBA_USER} ${ENVIRONMENT_FILE}
COPY --chown=${MAMBA_USER}:${MAMBA_USER} ${ENVIRONMENT_FILE} /tmp/env.yaml
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes
WORKDIR /usr/aih/data/src
ARG MAMBA_DOCKERFILE_ACTIVATE=1
COPY --chown=${MAMBA_USER}:${MAMBA_USER} tests tests
# RUN ls -la tests
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]