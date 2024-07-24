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


## Usage

```bash
docker run --rm mfhepp/aih-pandoc:3.2 /bin/bash -c "pandoc --version"
docker run --rm mfhepp/aih-pandoc:latest /bin/bash -c "pandoc --version"
```


## Releases and Tags
The version numbering for `aih-pandoc` always follows **the  Pandoc version**, `latest` includes **the highest available Pandoc version for which all required components are available.** 

| Tag / Release | Pandoc version | Image tag on Docker Hub |
| --- | --- | --- |
| latest | 3.2 | [mfhepp/aih-pandoc:3.2](https://hub.docker.com/repository/docker/mfhepp/aih-pandoc/general) |
| v3.2 | 3.2 | [mfhepp/aih-pandoc:3.2](https://hub.docker.com/repository/docker/mfhepp/aih-pandoc/general)

The versions for `latest` are stored in [`versions.txt`](versions.txt). The versions for each previous release will be in in 
`freeze/<version>`.

## Build

### Build via Github Action

A new image will be built and pushed to Docker Hub 

- for each commit to `main`
- for each commit with a tag like `v*.*.*`

**Important:** The digest part of the Docker Hub image will be determined by `IMAGE_NAME` in `versions.txt`. 

You can also trigger a **manual build and push workflow** like so:

```bash
# Trigger for the current main branch (latest commit):
gh workflow run 'Build Docker Image' --ref main

gh run --workflow=docker-build-and-push-osx-m1.yml --ref main

# Trigger for a specific branch (e.g., feature-branch):
gh workflow run 'Build Docker Image' --ref feature-branch

# Trigger for a specific tag (e.g., v1.2.3):
gh workflow run 'Build Docker Image' --ref v1.2.3

# Check status
gh run list --workflow=docker-build-and-push.yml
```

### Local Build and Push

You can also build the image locally with `build.sh`.

This is particularly useful for development and experiments.

**Warnings:** 
1. You can overwrite an existing image on  Docker Hub.
2. This is work-in-progress. The Github workflow is now the default mechanism.

#### Build development image from `versions-dev.txt``

```bash
./build.sh dev
```

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

## Updating

1. Check latest versions for
  - [`micromamba-docker`](https://github.com/mamba-org/micromamba-docker/releases/)
  - [`pandoc`](https://hackage.haskell.org/package/pandoc)
2. Check if all Pandoc components on Hackage are compatible with the latest Pandoc version
  - [`pandoc-cli`](https://hackage.haskell.org/package/pandoc-cli)
  - [`pandoc-crossref`](https://hackage.haskell.org/package/pandoc-crossref)
  - [`pandoc-plot`](https://hackage.haskell.org/package/pandoc-plot)
3. Make sure `versions_x.y.z.txt` exists for the current version. If not, create it.
4. Create a new branch: `git checkout -b update_to_pandoc_x.y.z`
5. Edit `versions.txt` and update all versions **and set `IMAGE_TAG` to the new Pandoc version**.
6. Update all Git submodules
```bash
# Update git submodules
   git submodule update --init --recursive
   cd dockerfiles
   git fetch
   git checkout main  # Replace 'main' with the branch you are tracking
   git pull           # Pull the latest changes
   cd ..
   # staging / commit / push will be up to the developer
   ```   
   7. Update the `seccomp` profile
```bash
   # Fetching the latest seccomp profile from https://github.com/moby/moby/blob/master/profiles/seccomp/default.json
   curl https://raw.githubusercontent.com/moby/moby/master/profiles/seccomp/default.json -o seccomp-default.json
```
7. Try to build and test the updated combinations.
8. If successful, produce a release:
  - Copy  `versions.txt` to `versions_x.y.z.txt` 
  - Export `env_x.y.z.yaml.lock` for the Micromamba components and PIP (this is currently not needed in this component of Academic in Heaven, but we aim at a unified approach.)
  - Add a release note to README.md (currently manual)
  - Create a release on Github (currently manual)
9. Currently manually: Attach the `latest` tag to the latest version
```bash
docker login
docker pull user/repo:3.2
docker tag user/repo:3.2 user/repo:latest
docker push user/repo:latest
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