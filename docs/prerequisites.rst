Host Prerequisites
==================================================

Setting up a Linux distribution to build a yocto project using kas
is very easy. Below are the simple instructions on how to install
kas and podman (docker is also supported).

**Host requirements:**

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

  **Fedora 40**

  ::

    sudo dnf -y update; \
    sudo dnf install -y podman python3-pip; \
    pip3 install -y kas

  **Ubuntu 22.04**

  ::

    sudo apt -y update; \
    sudo apt install -y podman python3-pip; \
    pip install kas
