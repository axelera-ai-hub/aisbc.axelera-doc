Axelera container usage
=======================

- **Prerequisites**

First of all, build and flash the board with the patch which adds support for
the Axelera docker image.

Please note all of the following commands must be
ran through a shell inside the Firefly ITX-3588J board. The board MUST be
connected to the internet, as some components are fetched while compiling
`gst-operators`.

The easiest way to do this is to connect the board to your router through an
Ethernet cable.

- **Setup**

The setup script has to be executed after flashing the board, and each time we restart it.

Head to the correct directory, where you will find both scripts used to run the container:

  ::

    cd /home/firefly

and run the setup script:

  ::

    ./setup_axelera_environment.sh

Note that this will take a long time at first execution, because it has to download about 6GB.
All the subsequent times, it will take a few minutes because of the docker service startup time.

- **Starting and running the container**

For all usage of the container it will be sufficient to use Axelera's python script,
which can also be found at `/home/firefly/`:

  ::

    ./start_axelera.py start

At the first invocation this should compile `gst-operators`, and finally provide a shell inside the docker container itself.
