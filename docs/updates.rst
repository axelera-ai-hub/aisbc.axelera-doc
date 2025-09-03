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
        mmcblk0      179:0    0 58.3G  0 disk
        |-mmcblk0p1  179:1    0    8M  0 part
        |-mmcblk0p2  179:2    0 20.7M  0 part
        |-mmcblk0p3  179:3    0  2.5G  0 part /
        |-mmcblk0p4  179:4    0  2.5G  0 part
        |-mmcblk0p5  179:5    0   64M  0 part /factory
        |-mmcblk0p6  179:6    0 53.2G  0 part /data

  * | After installation of the update file and rebooting, the active root
    | partition changes to the rootfs not currently in use.

    .. code-block:: bash

        sh-5.1# lsblk
        NAME         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
        mmcblk0      179:0    0 58.3G  0 disk
        |-mmcblk0p1  179:1    0    8M  0 part
        |-mmcblk0p2  179:2    0 20.7M  0 part
        |-mmcblk0p3  179:3    0  2.5G  0 part
        |-mmcblk0p4  179:4    0  2.5G  0 part /
        |-mmcblk0p5  179:5    0   64M  0 part /factory
        |-mmcblk0p6  179:6    0 53.2G  0 part /data
