meta-axelera
============

meta-axelera
------------

- **conf/**

  * distro/

    * voyager.conf: Voyager is the name of the distribution. This file contains information for any machine built for the voyager distribution.

  * machine/

    * itx-3588j.conf: itx machine kernel and uboot information.

  * layer.conf: meta-axelera layer information.

- **recipes-core**

  * images/

    * voyager-image.bb: Base image. This will be used for production images.

    * voyager-image-weston.bb: Debug image that includes Wayland and Weston.

    * voyager.inc: Includes tasks to run before or after an image builds.

Host Prerequisites
------------------

Setting up a Linux distribution to build a yocto project using kas
is very easy. Below are the simple instructions on how to install
kas and podman (docker is also supported).

- **Host requirements:**

  Minimum:
  - A Linux distribution with at least 128GB of free space.
  - 16GB of ram.
  - 8Core/16Thread CPU

  Recommended:
  - Gen 4 NVME or newer.
  - 32GB+ of ram
  - 16Core/32Thread CPU


  **Note: kas uses a Debian 12 container to build Yocto, any**
  **distribution with either podman or Docker will work.**

- **Fedora 40**

  ::

    sudo dnf -y update; \
    sudo dnf install -y podman python3-pip; \
    pip3 install -y kas

- **Ubuntu 22.04**

  ::

    sudo apt -y update; \
    sudo apt install -y bmap-tools podman python3-pip; \
    pip install kas

Build
-----

- **Build meta-axelera**

  ::

   git clone ssh://<user_name>@gerrit-review.amarulasolutions.com:29418/axelera/meta-axelera
   cd meta-axelera
   kas-container build

- **Build voyager specific**

  ::

   kas-container --ssh-agent shell .config.yaml -c \
          "mkdir -p /builder/.ssh && ssh-keyscan -p 38745 gitea.amarulasolutions.com >> \
          /builder/.ssh/known_hosts && bitbake voyager-image voyager-image-weston"


  Once complete, wic images are found in build/tmp-glibc/deploy/images/itx-3588j

- **Clean kernel-module-axelera**

  ::

   kas-container shell -c "bitbake -c cleansstate kernel-module-axelera"

- **Build kernel-module-axelera**

  ::

   kas-container shell -c "bitbake kernel-module-axelera"
