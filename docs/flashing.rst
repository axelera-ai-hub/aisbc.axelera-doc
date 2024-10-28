Flashing
=========

- **Download upgrade_tool**

  Download it from firefox-linux `upgrade_tool <https://drive.google.com/file/d/1uT9haefw3tmA_KCxbTBSp5fUqnf7RUCD>`_

  Check the sha256sum

  ::

    sha256sum upgrade_tool_v2.36_for_linux.zip
    237e962f8e4c778c0f2380ee0956e07a952d472a4d14cebc1237f6eac33445ad  upgrade_tool_v2.36_for_linux.zip

  Unzip

  ::

    unzip upgrade_tool_v2.36_for_linux.zip
    chmod +x ./upgrade_tool_v2.36_for_linux/upgrade_tool
    sudo mv ./upgrade_tool_v2.36_for_linux/upgrade_tool /usr/local/bin

- **Program eMMC**

  Loader Mode

  * Disconnect the power adapter first
  * Type-C data cable connects one end to the host and the other end to the development board.

  .. image:: /images/otg-conn.png

  * Press MASKROM button

  .. image:: /images/maskrom.png

  * Connect the power adapter

  * Release MASKROM button

  * Check the device

  ::

    lsusb  | grep Rockchip
    Bus 001 Device 010: ID 2207:350b Fuzhou Rockchip Electronics Company
    sudo upgrade_tool LD
    List of rockusb connected(1)
    DevNo=1    Vid=0x2207,Pid=0x350b,LocationID=12    Mode=Maskrom    SerialNo=

  * Program the eMMC

  ::

   sudo upgrade_tool wl 0 build/tmp-glibc/deploy/images/itx-3588j/voyager-image-weston-itx-3588j.wic
