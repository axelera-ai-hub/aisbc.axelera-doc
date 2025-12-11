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


Firefly
-------

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

   sudo upgrade_tool UF path/to/voyager-image-weston-itx-3588j.update.img

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

    sudo upgrade_tool UF path/to/voyager-image-weston-itx-3588j.update.img

  * Tap the reset button

- **Program SD**

  Insert the SD card into host.

  ::

   sudo bmaptool copy --bmap path/to/voyager-image-weston-itx-3588j.wic.bmap path/to/voyager-image-weston-itx-3588j.wic.gz /dev/sdX


Antelao
-------

- **Program eMMC**


  | There are no MASKROM or Recovery buttons in Antelao board.
  | If for any reason you cannot access Linux of the device, for example if you flash the wrong image and it doesn't boot anymore,or if it's frozen,
  | then power off the board, short the two pins of SW1, and power on the board back. This causes it to go into Maskrom mode.
  | There is no Recovery mode for Antelao.

  Loader Mode (Maskrom mode)

    * Ensure you are having root access to board's Linux

    * Use ``reboot bootloader`` to enter MASKROM mode

    ::

      lsusb  | grep Rockchip
      Bus 008 Device 018: ID 2207:0006 Fuzhou Rockchip Electronics Company RK3xxx
      upgrade_tool LD
      List of rockusb connected(1)
      DevNo=8    Vid=0x2207,Pid=0x0006,LocationID=12    Mode=Maskrom    SerialNo=

    * Program the eMMC

    ::

     sudo upgrade_tool UF path/to/voyager-image-weston-antelao-3588.update.img

- **Program SD**

  Insert the SD card into host.

  ::

   sudo bmaptool copy --bmap path/to/voyager-image-weston-antelao-3588.wic.bmap path/to/voyager-image-weston-antelao-3588.wic.gz /dev/sdX   
