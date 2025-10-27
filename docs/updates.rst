Updating
==============
- **Update system**

  * Axelera devices uses `Mender 3.5.3 <https://mender.io/>`_ for A/B updates.

  * | Updates overwrite the rootfs partition not in use.
    | Upon reboot, the new rootfs and boot partition are used.

- **Where to find update files**

  * | Update files are generated automatically in the
    | ``build/tmp-glibc/deploy/images/${MACHINE}/`` directory as part of the build.
  * | The update files are named either ``voyager-image-weston-itx-3588j.mender`` or
    | ``voyager-image-weston-antelao.mender``.

- **How to install updates**

  * | Upload the .mender file to the device using adb:**

    .. code-block:: bash

        MACHINE="antelao"
        IMAGE_DIR=build/tmp-glibc/deploy/images/${MACHINE}
        adb push ${IMAGE_DIR}/voyager-image-weston-${MACHINE}.mender /data/

  * | Enter the adb shell and install the udpate file

    .. code-block:: bash

        adb shell
        sh-5.1# mender install /data/voyager-image-weston-${MACHINE}.mender
        sh-5.1# reboot

- **Partition layout**

  * | The partition layout is shown below:

    .. code-block:: bash

        sh-5.1# lsblk
        NAME         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
        mmcblk0      179:0    0 58.5G  0 disk
        |-mmcblk0p1  179:1    0    4M  0 part
        |-mmcblk0p2  179:2    0   24M  0 part
        |-mmcblk0p3  179:3    0   24M  0 part
        |-mmcblk0p4  179:4    0  128K  0 part
        |-mmcblk0p5  179:5    0  128K  0 part
        |-mmcblk0p6  179:6    0    2G  0 part /
        |-mmcblk0p7  179:7    0    2G  0 part
        |-mmcblk0p8  179:8    0  128M  0 part /factory
        `-mmcblk0p9  179:9    0 54.3G  0 part /data

  * | After installation of the update file and rebooting, the active root
    | partition changes to the rootfs not currently in use.

    .. code-block:: bash

        sh-5.1# lsblk
        NAME         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
        mmcblk0      179:0    0 58.5G  0 disk
        |-mmcblk0p1  179:1    0    4M  0 part
        |-mmcblk0p2  179:2    0   24M  0 part
        |-mmcblk0p3  179:3    0   24M  0 part
        |-mmcblk0p4  179:4    0  128K  0 part
        |-mmcblk0p5  179:5    0  128K  0 part
        |-mmcblk0p6  179:6    0    2G  0 part
        |-mmcblk0p7  179:7    0    2G  0 part /
        |-mmcblk0p8  179:8    0  128M  0 part /factory
        `-mmcblk0p9  179:9    0 54.3G  0 part /data
