# Dockerfile for pandoc, pandoc-crossref, and pandoc-plot
# based on https://github.com/pandoc/dockerfiles

ARG MICROMAMBA_VERSION=latest
ARG ENVIRONMENT_FILE="env.yaml"
ARG BASE_IMAGE=mambaorg/micromamba
# Platform is used for URIs of binaries, mainly Pandoc
# Use ARG PLATFORM=amd64 for Intel (not tested)
ARG PLATFORM=arm64
ARG LUA_VERSION=5.4
# The core Pandoc components need to be compatible
ARG PANDOC_VERSION=3.2
ARG PANDOC_CLI_VERSION=3.2
ARG PANDOC_CROSSREF_VERSION=0.3.17.1
ARG PANDOC_PLOT_VERSION=1.8.0

# Stage 1: Patched version of Micromamba / Debian
FROM ${BASE_IMAGE}:${MICROMAMBA_VERSION} AS micromamba_patched
ARG PANDOC_VERSION
ARG PANDOC_CLI_VERSION
ARG PANDOC_CROSSREF_VERSION
ARG PANDOC_PLOT_VERSION
ARG ENVIRONMENT_FILE
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
# RUN echo --chown=$MAMBA_USER:$MAMBA_USER $ENVIRONMENT_FILE
COPY --chown=$MAMBA_USER:$MAMBA_USER $ENVIRONMENT_FILE /tmp/env.yaml
# ARG MAMBA_DOCKERFILE_ACTIVATE=1
# RUN echo Content of env.yaml
# RUN cat /tmp/env.yaml
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes
WORKDIR /usr/aih/data/src
COPY --chown=$MAMBA_USER:$MAMBA_USER tests/ ./
ARG MAMBA_DOCKERFILE_ACTIVATE=1
RUN ls .
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh"]
