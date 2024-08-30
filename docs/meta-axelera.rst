meta-axelera contents
==================================================

**Important items:**

* conf/

  * distro/

    * voyager.conf: Voyager is the name of the distribution. This file contains information for any machine built for the voyager distribution.

  * machine/

    * itx-3588j.conf: itx machine kernel and uboot information.

  * layer.conf: meta-axelera layer information.

* recipes-core:

  * images/

    * voyager-image.bb: Base image. This will be used for production images.

    * voyager-image-weston.bb: Debug image that includes Wayland and Weston.

    * voyager.inc: Includes tasks to run before or after an image builds.
