# Pandoc Image for Academic in Heaven

This is an image with Pandoc and core Pandoc components on the basis of the `mambaorg/micromamba` image, which itself is (currently) based on Debian `bookwork-slim`. 

As [Academic in Heaven](https://github.com/academicinheaven) is based on `micromamba` and 

1. the official Debian packages for `Pandoc` are typically rather outdated
and
2. core Pandoc components like `pandoc-plot` need to be built with the same Pandoc version,

we compile Pandoc and such components from their Haskell sources.

As this is is a lengthy process (30 minutes and more), we keep this process separate from the core Academic in Heaven images.
