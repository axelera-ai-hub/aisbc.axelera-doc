Updating
==============
- **Update system**

  * Axelera devices uses `Mender 3.5.3 <https://mender.io/>`_ for A/B updates.

  * | Updates overwrite the rootfs partition not in use.
    | Upon reboot, the new rootfs and boot partition are used.

- **Where to find update files**

  * | Update files are generated automatically in the
    | ``build/tmp-glibc/deploy/images/${MACHINE}/`` directory as part of the build.
  * | The update files are named ``voyager-image-weston-<board_name>.mender``.

- **How to install updates**


  * | Upload the .mender file to the device using your preferred method.
    | Ensure the image is copied to a writeable directory such as ``/data`` or ``/home/<board_user>``,
    | since the rest of the rootfs is read-only.

    | If using ssh, from the host machine run:

    .. code-block:: bash

        scp path/to/voyager-image-weston-<board_name>-<version>.mender <board_user>@<board_ip_addr>:/data/

    | Or if using adb:

    .. code-block:: bash

        adb push path/to/voyager-image-weston-<board_name>-<version>.mender /data/

  * | Board can be accessed using ``ssh root@<board_ip_address>`` where board and host computer are on the same network
    | or ``adb shell`` where board is connected to host computer via USB port.
    | To install the update file, with root access from the board itself run:

    .. code-block:: bash

        mender install /data/voyager-image-weston-<board_name>-<version>.mender
        reboot

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
