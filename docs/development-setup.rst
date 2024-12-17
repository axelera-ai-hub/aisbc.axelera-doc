Development Setup
=================

- **ADB**

  * The kas/include/base.yaml file already has the necessary lines to enable ADB, so no modifications are needed to the build system.

  * Install adb

    * Fedora: sudo dnf intall -y adb
    * Ubuntu: sudo apt install -y adb

  * Power on the board.
  * When ADB starts on the board, the board will appear under Devices on your system. For example:

  .. image:: /images/adb_mount_example.png

  * When the device appears, check to make sure the device appears under adb devices:

  ::

    $adb devices
    List of devices attached
    0123456789ABCDEF        device

  * Start the adb shell using the "adb shell" command.

  ::

    $adb shell
    sh-5.1#

- **Serial**

  .. image:: /images/debug_connection.jpg

  * Baud rate: 1500000
  * Data bit: 8
  * Stop bit: 1
  * Parity check: none
  * Flow control: none

  **Note: The default baud rate of ITX-3588J is 1500000! Many TTY chipsets are not capable of handling 1.5MBps, as almost all products use 115200 for console output. If you use a TTY -> USB device and get nothing but garbage output on the screen, try an adapter with one of the following chipsets listed below:**

  * From https://wiki.t-firefly.com/en/Core-3588J/debug.html the follwing TTY chipsets are suggested:

    * CP2104
    * PL2303
    * CH340



