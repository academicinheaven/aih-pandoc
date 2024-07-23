# Pandoc Image for Academic in Heaven

This is an image with Pandoc and core Pandoc components on the basis of the `mambaorg/micromamba` image, which itself is (currently) based on Debian `bookwork-slim`. 

As [Academic in Heaven](https://github.com/academicinheaven) is based on `micromamba` and 

1. the official Debian packages for `Pandoc` are typically rather outdated
and
2. core Pandoc components like `pandoc-plot` need to be built with the same Pandoc version,

we build Pandoc and all required components components from their Haskell packages from their sources from the Haskell package repository [**Hackage**](https://hackage.haskell.org/) via [`cabal-install`](https://hackage.haskell.org/package/cabal-install).

As this is is a lengthy process (30 minutes and more), we keep this process separate from the core Academic in Heaven images.

## Components

1. [`micromamba-docker`](https://github.com/mamba-org/micromamba-docker/releases/)
    - [Github repository](https://github.com/mamba-org/micromamba-docker)
2. [`pandoc`](https://hackage.haskell.org/package/pandoc)
    - [Github repository](https://github.com/jgm/pandoc)
3. [`pandoc-cli`](https://hackage.haskell.org/package/pandoc-cli)
4. [`pandoc-crossref`](https://hackage.haskell.org/package/pandoc-crossref)
5. [`pandoc-plot`](https://hackage.haskell.org/package/pandoc-plot)


## Releases and Tags

The version numbering for `aih-pandoc` always follows **the  Pandoc version**, `latest` includes **the highest available Pandoc version for which all required components are available.** 

| Tag / Release | Pandoc version | Image tag on Docker Hub |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- 
| latest | max(Pandoc) | [mfhepp/aih-pandoc:3.2](https://hub.docker.com/repository/docker/mfhepp/aih-pandoc/general)
| v3.2 | 3.2 | [mfhepp/aih-pandoc:3.2](https://hub.docker.com/repository/docker/mfhepp/aih-pandoc/general)

The versions for `latest` are stored in [`versions.txt`](versions.txt). The versions for each previous release are in 
`freeze/<version>`.

## Build

### Build via Github Action


### Local Build

```bash
# Builds the Docker image from the Dockerfile
Usage: ./build.sh [ dev | update | freeze | push ]

Commands(s):
  dev: Build development image (create mh/aih-pandoc:dev)
  freeze: Update env.yaml.lock and ignore Docker cache
  push: Push Docker image to repository
  test: Run tests
  update: Force fresh build, ignoring cached build stages and versions from lock (will e.g. update Python packages)
  ```
