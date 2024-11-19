Axelera container usage
=======================

- **Prerequisites**

First of all, build and flash the board with the patch which adds support for
the Axelera docker image. Please note all of the following commands must be
ran through a shell inside the Firefly ITX-3588J board. The board MUST be
connected to the internet, as some components are fetched while compiling gst-
operators. The easiest way to do this is to connect it to your router through an
Ethernet cable.

Before beginning, the docker service must be started:

  ::

    systemctl start docker

And the .tar archive must be imported into docker itself:

  ::

    cd /home/firefly
    docker load < axelera-sdk-ubuntu-2204-arm64.tar


- **Copying the SDK**

Axelera's SDK must be copied from the docker image to the home directory.

To do this, a container must be created using the image we previously imported:

  ::

    docker create axelera-sdk-ubuntu-2204-arm64:1.0.0-a6

Next, the id of the container must be found:

  ::

    docker ps -a

Which should output something like:

  ::

    CONTAINER ID   IMAGE                                     COMMAND            CREATED         STATUS    PORTS     NAMES
    <your_id>      axelera-sdk-ubuntu-2204-arm64:1.0.0-a6    "/entrypoint.sh"   2 seconds ago   Created             <example_name>

Using this id we can copy the SDK from the image to out current directory, which as previously stated must be `/home/firefly`.

  ::

    docker cp <your_id>:/home/ubuntu/voyager-sdk .

Since we have finished using this particular container, we can delete it now:

  ::

    docker rm <your_id>

And finally, we must change the ownership of this directory such that the docker container itself can create and modify subdirectories inside of it:

  ::

    chown -R 1000:1000 voyager-sdk


- **Starting and running the container**

After copying the SDK, for all future usage of the container it will be sufficient to use Axelera's python script:

  ::

    ./start_axelera.py start

At the first invocation this should compile `gst-operators`, and finally provide a shell inside the docker container itself.
