Flashing
==================================================

Download the upgrade_tool from the following URL provided by firefly-linux:
https://drive.google.com/file/d/1uT9haefw3tmA_KCxbTBSp5fUqnf7RUCD

Unfortuantly, upgrade_tool is not open source and is only provided as a
pre-compiled binary. The URL above is tested and safe.

The shasum for upgrade_tool_v2.36_for_linux.zip is:
237e962f8e4c778c0f2380ee0956e07a952d472a4d14cebc1237f6eac33445ad


.. code-block::
   :caption: use upgrade_tool to flash the weston image

     unzip upgrade_tool_v2.36_for_linux.zip

     chmod +x ./upgrade_tool_v2.36_for_linux/upgrade_tool

     sudo mv ./upgrade_tool_v2.36_for_linux/upgrade_tool /usr/local/bin

     sudo upgrade_tool wl 0 ./build/tmp/deploy/images/itx-3588j/core-image-weston-itx-3588j.wic
