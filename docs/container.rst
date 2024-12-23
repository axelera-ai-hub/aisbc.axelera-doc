Axelera container usage
=======================

- **Prerequisites**

Please note all of the following commands must be
ran through a shell inside the board. The board MUST be
connected to the internet, as some components are fetched while compiling
`gst-operators`.

The easiest way to do this is to connect the board to your router through an
Ethernet cable.

- **Setup**

The setup script has to be executed on first boot, after flashing the board.

Head to the correct home directory, where you will find both scripts used to run the container.
This depends on which board you are using. For the firefly board:

  ::

    cd /home/firefly


While for the antelao board:

  ::

    cd /home/antelao

and run the setup script:

  ::

    ./setup_axelera_environment.sh

Note that this will take a long time, because it has to download about 6GB.

- **Starting and running the container**

For all usage of the container it will be sufficient to use Axelera's python script,
which can also be found at `/home/firefly/` or `/home/antelao`:

  ::

    ./start_axelera.py start

At the first invocation this should compile `gst-operators`, and finally provide a shell inside the docker container itself.
