# Pandoc Image for Academic in Heaven

This is an `linux/arm64` image with Pandoc and core Pandoc components on the basis of the `mambaorg/micromamba` image, which itself is (currently) based on Debian `bookwork-slim` for the [Academic in Heaven](https://github.com/academicinheaven) project.

As [Academic in Heaven](https://github.com/academicinheaven) is based on `micromamba` and 

1. the official Debian packages for `Pandoc` are typically rather outdated
and
2. core Pandoc components like `pandoc-plot` need to be built with the same Pandoc version,

we build Pandoc and all required components components from the Haskell package repository [**Hackage**](https://hackage.haskell.org/) via [`cabal-install`](https://hackage.haskell.org/package/cabal-install).

As this is is a lengthy process (30 minutes and more), we keep this process separate from the core Academic in Heaven images.

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
docker run --rm mfhepp/aih-pandoc:latest /bin/bash -c "pandoc --version"
docker run --rm mfhepp/aih-pandoc:3.2 /bin/bash -c "pandoc --version"
```

## Releases and Tags

The version numbering for `aih-pandoc` always follows **the  Pandoc version**, `latest` includes **the highest available Pandoc version for which all required components are available.** 

| Tag / Release | Pandoc version | Image tag on Docker Hub |
| --- | --- | --- |
| latest | 3.2 | [mfhepp/aih-pandoc:3.2](https://hub.docker.com/repository/docker/mfhepp/aih-pandoc/general) |
| v3.2 | 3.2 | [mfhepp/aih-pandoc:3.2](https://hub.docker.com/repository/docker/mfhepp/aih-pandoc/general)

The versions for `latest` are stored in [`versions.txt`](versions.txt). The versions for each previous release will be in in 
`freeze/<version>/versions.txt`.

## Build

### Local Build and Push

The preferred way of building the images for Apple silicon is to use `build.sh` on an Apple M1 machine. You need Docker Desktop installed.

```bash
Usage: ./build.sh [ --help ] [ test | push | freeze | update ]

Commands(s):
  (none): Build image
  test:   Run tests
  push:   Push Docker image to repository
  freeze: Create version folder and freeze version.txt and env.yaml.lock
  update: Update submodules and external files
```

Here is the process:

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
5. Edit `versions.txt` and update all versions **and set `IMAGE_TAG` to the new Pandoc version**.
6. Update all Git submodules  and other files with  `./build.sh update`. This essentially does the following:
```bash
# Update git submodules
   git submodule update --init --recursive
   cd dockerfiles
   git fetch
   git checkout main  # Replace 'main' with the branch you are tracking
   git pull           # Pull the latest changes
   cd ..
   # staging / commit / push will be up to the developer
   # Fetching the latest seccomp profile from https://github.com/moby/moby/blob/master/profiles/seccomp/default.json
   curl https://raw.githubusercontent.com/moby/moby/master/profiles/seccomp/default.json -o seccomp-default.json
```
7. Try to build and test the updated combinations with `./build.sh`
8. If successful, produce a release:
  - Run  `./build.sh freeze`; this will create  a new folder in `freeze` and copy `versions.txt` and `env.yaml.lock`.
  - Support for `pip` is currently missing. (this is  not needed in this component of Academic in Heaven, but we aim at a unified approach.)
  - Add a release note to README.md (currently manual)
  - Create a release on Github (currently manual)
9. Commit, add a tag, and push to Github.
10. Currently manually: Attach the `latest` tag to the latest version
```bash
docker login
docker pull mfhepp/aih-pandoc:3.2
docker tag mfhepp/aih-pandoc:3.2 mfhepp/aih-pandoc:latest
docker push mfhepp/aih-pandoc:latest
```

**Note:** We do not track the Haskell/Cabal versions for the build environment and rely on Debian for stability here.

 ## Releases

 ### v3.2

```
MICROMAMBA_VERSION=1.5.8
PANDOC_VERSION=3.2
PANDOC_CLI_VERSION=3.2
PANDOC_CROSSREF_VERSION=0.3.17.1
LUA_VERSION=5.4
PANDOC_PLOT_VERSION=1.8.0
```