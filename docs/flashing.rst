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

  Loader Mode (Maskrom mode)

  * Disconnect the power adapter first or hold the reset button
  * Type-C data cable connects one end to the host and the other end to the development board.

  .. image:: /images/otg-conn.png

  * Press MASKROM button

  .. image:: /images/maskrom.png

  * Connect the power adapter or release reset button

  * Release MASKROM button

  * Check the device

  * Alternative you can reboot bootloader. This reboot in a compatible mask rom mode

  ::

    lsusb  | grep Rockchip
    Bus 001 Device 010: ID 2207:350b Fuzhou Rockchip Electronics Company
    sudo upgrade_tool LD
    List of rockusb connected(1)
    DevNo=1    Vid=0x2207,Pid=0x350b,LocationID=12    Mode=Maskrom    SerialNo=

  * Program the eMMC

  ::

   sudo upgrade_tool wl 0 build/tmp-glibc/deploy/images/itx-3588j/voyager-image-weston-itx-3588j.wic

  Loader Mode (Recovery mode)

  * Connect one end to the host and the other end to the usb-c port on the development board.

  .. image:: /images/otg-conn.png

  .. image:: /images/upgrade_recovery_reset_new.jpg

  * While holding the recovery button, tap the reset button.
  * Wait 2 seconds, and release the reset button.
  * Check the device

  ::

    lsusb  | grep Rockchip
    Bus 001 Device 047: ID 2207:350b Fuzhou Rockchip Electronics Company USB download gadget

    sudo upgrade_tool LD
    List of rockusb connected(1)
    DevNo=1 Vid=0x2207,Pid=0x350b,LocationID=14     Mode=Loader    SerialNo=xxxxxxxxxxxxxxxx

  * Program the eMMC

  ::

  sudo upgrade_tool uf build/tmp-glibc/deploy/images/itx-3588j/voyager-image-weston-itx-3588j.update.img

  * Tap the reset button

- **Program SD**

  Insert the SD card into host.

  ::

   sudo bmaptool copy --bmap build/tmp-glibc/deploy/images/itx-3588j/voyager-image-weston-itx-3588j.wic.bmap build/tmp-glibc/deploy/images/itx-3588j/voyager-image-weston-itx-3588j.wic.gz /dev/sdX
