# Pandoc Image for Academic in Heaven

This is an `linux/arm64` image with Pandoc and core Pandoc components on the basis of the [`mambaorg/micromamba`](https://micromamba-docker.readthedocs.io/en/latest/) image for the [Academic in Heaven](https://github.com/academicinheaven) project.

We currently use the Debian 12 base image because the Pandoc workflow is currently based on the [`haskell:9.12-slim-bookworm`](https://hub.docker.com/layers/library/haskell/9.12-slim-bookworm/images/sha256-8919e82613029971d8129b51ffbe61140f61e51b4cbfb79f90da7be9e59b67ae) image.

As [Academic in Heaven](https://github.com/academicinheaven) is based on `micromamba` and 

1. the official Debian packages for `Pandoc` are typically rather outdated
and
2. core Pandoc components like `pandoc-plot` need to be built with the same Pandoc version,

we build Pandoc and all required components components from the Haskell package repository [**Hackage**](https://hackage.haskell.org/) using the same [`haskell:9.12-slim-bookworm`](https://hub.docker.com/layers/library/haskell/9.12-slim-bookworm/images/sha256-8919e82613029971d8129b51ffbe61140f61e51b4cbfb79f90da7be9e59b67ae) image that is being used by [`pandoc-dockerfiles`](https://github.com/pandoc/dockerfiles/blob/main/3.8.3/debian/Dockerfile). 

As this is is a lengthy process (15 minutes and more), we keep this process separate from the core Academic in Heaven images.

## Components

1. [`micromamba-docker`](https://github.com/mamba-org/micromamba-docker/releases/)
    - [Github repository](https://github.com/mamba-org/micromamba-docker)
2. [`pandoc`](https://hackage.haskell.org/package/pandoc)
    - [Github repository](https://github.com/jgm/pandoc)
3. [`pandoc-cli`](https://hackage.haskell.org/package/pandoc-cli)
4. [`pandoc-crossref`](https://hackage.haskell.org/package/pandoc-crossref)
5. [`pandoc-plot`](https://hackage.haskell.org/package/pandoc-plot)

## Usage

```bash
docker run --rm mfhepp/aih2-pandoc:latest /bin/bash -c "pandoc --version"
docker run --rm mfhepp/aih2-pandoc:3.8.3 /bin/bash -c "pandoc --version"
docker run --rm -it --mount type=bind,source="$(pwd)",target=/usr/aih/data/src \
    mfhepp/aih2-pandoc:latest  \
     /bin/bash
```

## Releases and Tags

The version numbering for `aih2-pandoc` always follows **the  Pandoc version**, `latest` includes **the highest available Pandoc version for which all required components are available.** Any updated version with the same Pandoc version will be marked with an `-rcx` suffix, like `aih2-pandoc-3.8.3-rc1`.

**Note:** The base name is now `aih2-pandoc` (used to be `aih-pandoc`).

| Tag / Release | Pandoc version | Image tag on Docker Hub |
| --- | --- | --- |
| latest | 3.8.3 | [mfhepp/aih2-pandoc:latest](https://hub.docker.com/repository/docker/mfhepp/aih2-pandoc/general) |
| v3.8.3 | 3.8.3 | [mfhepp/aih2-pandoc:3.8.3](https://hub.docker.com/repository/docker/mfhepp/aih2-pandoc/general) |
| v3.2.1 | 3.2.1 | [mfhepp/aih-pandoc:3.2.1](https://hub.docker.com/repository/docker/mfhepp/aih-pandoc/general) |
| v3.2 | 3.2 | [mfhepp/aih-pandoc:3.2](https://hub.docker.com/repository/docker/mfhepp/aih-pandoc/general) |

The versions for `latest` are stored in [`versions.txt`](versions.txt). The versions for each previous release will be in in 
`freeze/<version>/versions.txt`.

## Build

### Local Build and Push

The preferred way of building the images for Apple silicon is to use `build.sh` on an Apple M1 machine. You need Docker Desktop installed.

```bash
# Clone from Github
git clone https://github.com/academicinheaven/aih-pandoc
cd aih-pandoc
# Initialize Submodules
git submodule update --init --recursive
# Build
./build.sh
```

```bash
Usage: ./build.sh [ --help ] [ test | push | freeze | update | terminal]

Commands(s):
  (none):   Build image
  test:     Run tests
  push:     Push Docker image to repository
  freeze:   Create version folder and freeze version.txt and env.yaml.lock
  update:   Update submodules and external files
  terminal: Opens a Bash shell for debugging etc.
```

Here is the full process:

1. Make sure that `IMAGE_TAG` in `version.txt` is set properly; it will also determine the tag on Docker Hub.
2. Update all dependencies with `./build.sh update`.
3. Edit `versions.txt` as needed.
2. Build and test with `./build.sh` from a branch of your choice.
3. Freeze all components with `./build.sh freeze`.
4. Edit `README.md`.
5. Add a tag / release.
6. Commit / push to Github.
7. Push to Docker Hub with `./build.sh push`.


## Updating

1. Check latest versions for
  - [`micromamba-docker`](https://github.com/mamba-org/micromamba-docker/releases/)
  - [`pandoc`](https://hackage.haskell.org/package/pandoc)
2. Check if all Pandoc components on Hackage are compatible with the latest Pandoc version
  - [`pandoc-cli`](https://hackage.haskell.org/package/pandoc-cli)
  - [`pandoc-crossref`](https://hackage.haskell.org/package/pandoc-crossref)
  - [`pandoc-plot`](https://hackage.haskell.org/package/pandoc-plot)
3. Make sure `freeze/x.y.z/versions.txt` exists for the current version. If not, create it with `./build.sh freeze`.
4. Create a new branch: `git checkout -b update_to_pandoc_x.y.z`
5. Edit `versions.txt` and update all versions **and set `IMAGE_TAG` to the new Pandoc version**. Also check if the Docker seccomp profile [`seccomp-default.json`](https://github.com/moby/profiles/blob/main/seccomp/default.json) is available from <https://raw.githubusercontent.com/moby/profiles/refs/heads/main/seccomp/default.json>.
6. Update all Git submodules and other files with  `./build.sh update`. This essentially does the following:
```bash
# Update git submodules
   git submodule update --init --recursive
   cd dockerfiles
   git fetch
   git checkout main  # Replace 'main' with the branch you are tracking
   git pull           # Pull the latest changes
   cd ..
   # staging / commit / push will be up to the developer
   # Fetching the latest seccomp profile from https://raw.githubusercontent.com/moby/profiles/refs/heads/main/seccomp/default.json
   curl https://raw.githubusercontent.com/moby/profiles/refs/heads/main/seccomp/default.json -o seccomp-default.json
```
7. Try to build and test the updated combinations with `./build.sh`
8. If successful, produce a release:
  - Run  `./build.sh freeze`; this will create  a new folder in `freeze` and copy `versions.txt` and `env.yaml.lock`.
  - Support for `pip` is currently missing. (this is  not needed in this component of Academic in Heaven, but we aim at a unified approach.)
  - Add a release note to README.md (currently manual)
  - Create a release on Github (currently manual)
9. Commit, merge with main, add a tag, and push to Github.
10. Currently manually: Attach the `latest` tag to the latest version
```bash
docker login
docker pull mfhepp/aih-pandoc:3.2.1
docker tag mfhepp/aih-pandoc:3.2.1 mfhepp/aih-pandoc:latest
docker push mfhepp/aih-pandoc:latest
```

**Note:** We do not track the Haskell/Cabal versions for the build environment and rely on Debian for stability here.

## Releases

### v3.8.3

```
DEBIAN_RELEASE=12
DEBIAN_CODENAME=bookworm
MICROMAMBA_VERSION=2.5.0-debian12
PANDOC_VERSION=3.8.3
PANDOC_CLI_VERSION=3.8.3
PANDOC_CROSSREF_VERSION=0.3.22
LUA_VERSION=5.4
PANDOC_PLOT_VERSION=1.9.1
```

### v3.2.1

```
MICROMAMBA_VERSION=1.5.8
PANDOC_VERSION=3.2.1
PANDOC_CLI_VERSION=3.2.1
PANDOC_CROSSREF_VERSION=0.3.17.1
LUA_VERSION=5.4
PANDOC_PLOT_VERSION=1.8.0
```

 ### v3.2

```
MICROMAMBA_VERSION=1.5.8
PANDOC_VERSION=3.2
PANDOC_CLI_VERSION=3.2
PANDOC_CROSSREF_VERSION=0.3.17.1
LUA_VERSION=5.4
PANDOC_PLOT_VERSION=1.8.0
```

## License and Acknowledgments

We thankfully acknowledge the following components:

- [Pandoc](https://github.com/jgm/pandoc) under [GPL 2.0 or greater](https://github.com/jgm/pandoc#license)
- [micromamba-docker](https://github.com/mamba-org/micromamba-docker) under [Apache 2.0](https://github.com/mamba-org/micromamba-docker/blob/main/LICENSE)
- [pandoc-crossref](https://github.com/lierdakil/pandoc-crossref) under [GPL 2.0](https://github.com/lierdakil/pandoc-crossref/blob/master/LICENSE)
- [pandoc-dockerfiles](https://github.com/pandoc/dockerfiles) under [GPL 2.0](https://github.com/pandoc/dockerfiles/blob/master/LICENSE)
- [pandoc-plot](https://github.com/LaurentRDC/pandoc-plot/blob/master/LICENSE) under [GPL 2.0](https://github.com/LaurentRDC/pandoc-plot/blob/master/LICENSE)
- The [`seccomp` profile from the Moby project](https://github.com/moby/moby/tree/master) under [Apache 2.0](https://github.com/moby/moby/blob/master/LICENSE)