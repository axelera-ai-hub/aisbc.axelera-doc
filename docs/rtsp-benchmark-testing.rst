Encoding/Decoding RTSP Benchmark Testing
=========

- **Dependencies**

  Install pytest:

  ::

    pip install pytest

- **Use ADB**

  * This particular testing suite is run directly on the host machine and not on
    the board itself.
    This means that we require `adb` support, so that gstreamer can be run
    directly from the python script running on your host.

    The kas/include/base.yaml file already has the necessary lines to enable ADB, so no
    modifications are needed.

- **Instructions for first use**

  * Clone the repository

    ::

      git clone "ssh://<user_name>@gerrit-review.amarulasolutions.com:29418/axelera/axelera-test-bsp"

  * Disconnect the power from the board.

  * Connect your host machine to TYPEC0 port on the board:

    .. image:: /images/typec-conn.png

  * Connect the board directly to your host machine through an Ethernet cable,
    in any of the two available ports:

    .. image:: /images/ethernet-conn.png

  * Share your host machine's connection through this Ethernet one.

    For example, to do this in Ubuntu 24.04, go to

    * Settings, Network, Wired, IPv4

    And set it to `Shared to other computers`:

      .. image:: /images/share-ethernet-conn.png

  * Connect the power back to the board. Once it has booted succesfully,
    there should be an IP address dedicated to this connection on your
    host machine.

    One way to find it is by running:

      ::

        ip addr show

    The default for Ubuntu should be `10.42.0.1`, and for the moment it is the
    only address supported. If yours is different, please change it to this.

  * Run the following command once, so you download the docker image that contains the RTSP server.

    ::

      docker run --rm -it --network=host bluenviron/mediamtx:latest-ffmpeg

    Once it finishes downloading and starts running successfully, you can close it.

  * Make sure that adb is working properly:

    ::

      adb devices

    should show the device, and:

    ::

      adb shell

    should open a shell in the board.

  * You are now ready to run tests.

- **Running tests**

  To run the tests, simply go to the cloned directory, e.g.

    ::

      cd axelera-test-bsp

  and run the following command:

    ::

      pytest

  The output data will be saved in `output/test-results-YYYYMMDD.csv`
