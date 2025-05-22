Generic usage guide
=======================

- **Default passwords**

The default login passwords for the various users are:

.. list-table:: Default passwords
   :widths: 25 25
   :header-rows: 1

   * - Username
     - Password
   * - antelao
     - AxeAntelao2025
   * - firefly
     - AxeFirefly2025
   * - root
     - AxeRoot2025

Note that the `firefly` user is only present on the Firefly ITX-3588J board,
while the `antelao` user is only present on the Antelao board.

- **Change Linux user password**

To change the password for the currently logged in user,
simply run:

  ::

    passwd

And follow the prompts:

  ::

    Changing password for antelao.
    Current password:
    New password:
    Retype new password:
    passwd: password updated successfully

- **Set static IP address**

To set a static IP address for any board running Voyager Linux,
it is necessary to be running a version that comes with `nmcli`.
To check this, run:

  ::

    nmcli --version

If it's not present on the system, please flash the board with a more
recent version.

To start, check active connections:

  ::

    nmcli dev status

  ::

    DEVICE  TYPE      STATE        CONNECTION
    eth1    ethernet  connected    Wired connection 2
    eth0    ethernet  unavailable  --
    dummy0  dummy     unmanaged    --
    lo      loopback  unmanaged    --

In this example, `Wired connection 2` is active on `eth1` with the
default configuration.
First of all, disconnect the device and start editing the connection:

  ::

    nmcli dev disconnect eth1

    nmcli con edit "Wired connection 2"

This will open an interactive prompt to easily edit all properties
of the connection.
To print all the information about it:

  ::

    nmcli> print
    ===============================================================================
                    Connection profile details (Wired connection 2)
    ===============================================================================
    connection.id:                          Wired connection 2
    connection.uuid:                        282725cf-b2d1-3a4d-ae66-7240c06abd1f
    connection.stable-id:                   --
    connection.type:                        802-3-ethernet
    connection.interface-name:              eth1
    connection.autoconnect:                 yes
    connection.autoconnect-priority:        -999
    connection.autoconnect-retries:         -1 (default)
    connection.multi-connect:               0 (default)
    connection.auth-retries:                -1
    connection.timestamp:                   1747318179
    connection.read-only:                   no
    connection.permissions:                 --
    connection.zone:                        --
    connection.master:                      --
    connection.slave-type:                  --
    connection.autoconnect-slaves:          -1 (default)
    connection.secondaries:                 --
    connection.gateway-ping-timeout:        0
    connection.metered:                     unknown
    connection.lldp:                        default
    connection.mdns:                        -1 (default)
    connection.llmnr:                       -1 (default)
    connection.dns-over-tls:                -1 (default)
    connection.wait-device-timeout:         -1
    -------------------------------------------------------------------------------
    802-3-ethernet.port:                    --
    802-3-ethernet.speed:                   0
    802-3-ethernet.duplex:                  --
    802-3-ethernet.auto-negotiate:          no
    802-3-ethernet.mac-address:             --
    802-3-ethernet.cloned-mac-address:      --
    802-3-ethernet.generate-mac-address-mask:--
    802-3-ethernet.mac-address-blacklist:   --
    802-3-ethernet.mtu:                     auto
    802-3-ethernet.s390-subchannels:        --
    802-3-ethernet.s390-nettype:            --
    802-3-ethernet.s390-options:            --
    802-3-ethernet.wake-on-lan:             default
    802-3-ethernet.wake-on-lan-password:    --
    802-3-ethernet.accept-all-mac-addresses:-1 (default)
    -------------------------------------------------------------------------------
    ipv4.method:                            auto
    ipv4.dns:                               --
    ipv4.dns-search:                        --
    ipv4.dns-options:                       --
    ipv4.dns-priority:                      0
    ipv4.addresses:                         --
    ipv4.gateway:                           --
    ipv4.routes:                            --
    ipv4.route-metric:                      -1
    ipv4.route-table:                       0 (unspec)
    ipv4.routing-rules:                     --
    ipv4.ignore-auto-routes:                no
    ipv4.ignore-auto-dns:                   no
    ipv4.dhcp-client-id:                    --
    ipv4.dhcp-iaid:                         --
    ipv4.dhcp-timeout:                      0 (default)
    ipv4.dhcp-send-hostname:                yes
    ipv4.dhcp-hostname:                     --
    ipv4.dhcp-fqdn:                         --
    ipv4.dhcp-hostname-flags:               0x0 (none)
    ipv4.never-default:                     no
    ipv4.may-fail:                          yes
    ipv4.required-timeout:                  -1 (default)
    ipv4.dad-timeout:                       -1 (default)
    ipv4.dhcp-vendor-class-identifier:      --
    ipv4.dhcp-reject-servers:               --
    -------------------------------------------------------------------------------
    ipv6.method:                            auto
    ipv6.dns:                               --
    ipv6.dns-search:                        --
    ipv6.dns-options:                       --
    ipv6.dns-priority:                      0
    ipv6.addresses:                         --
    ipv6.gateway:                           --
    ipv6.routes:                            --
    ipv6.route-metric:                      -1
    ipv6.route-table:                       0 (unspec)
    ipv6.routing-rules:                     --
    ipv6.ignore-auto-routes:                no
    ipv6.ignore-auto-dns:                   no
    ipv6.never-default:                     no
    ipv6.may-fail:                          yes
    ipv6.required-timeout:                  -1 (default)
    ipv6.ip6-privacy:                       -1 (unknown)
    ipv6.addr-gen-mode:                     stable-privacy
    ipv6.ra-timeout:                        0 (default)
    ipv6.dhcp-duid:                         --
    ipv6.dhcp-iaid:                         --
    ipv6.dhcp-timeout:                      0 (default)
    ipv6.dhcp-send-hostname:                yes
    ipv6.dhcp-hostname:                     --
    ipv6.dhcp-hostname-flags:               0x0 (none)
    ipv6.token:                             --
    -------------------------------------------------------------------------------
    proxy.method:                           none
    proxy.browser-only:                     no
    proxy.pac-url:                          --
    proxy.pac-script:                       --
    -------------------------------------------------------------------------------

It may be a good idea to change the name from the default one, such as
`Wired connection 2`, to an easier one, such as `eth1`:

  ::

    nmcli> set connection.id eth1

Then, to set the static IP address, for example to `10.42.0.77`:

  ::

    nmcli> set ipv4.address 10.42.0.77/24
    Do you also want to set 'ipv4.method' to 'manual'? [yes]: yes

    nmcli> set ipv4.gateway 10.42.0.1

Finally, verify the connection, save the configuration and reconnect
the device:

  ::

    nmcli> verify
    Verify connection: OK

    nmcli> save
    Connection 'eth1' (282725cf-b2d1-3a4d-ae66-7240c06abd1f) successfully updated.

    nmcli> quit

  ::

    nmcli dev connect eth1

To check if the process was successful:

  ::

    ip addr show eth1

  ::

    4: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq qlen 1000
        link/ether 42:20:9a:5d:67:98 brd ff:ff:ff:ff:ff:ff
        inet 10.42.0.77/24 brd 10.42.0.255 scope global noprefixroute eth1
           valid_lft forever preferred_lft forever
        inet6 fe80::bbf5:174d:c2c6:dc2e/64 scope link noprefixroute 
           valid_lft forever preferred_lft forever

- **Setting up WireGuard VPN**

The configuration for this section is entirely dependent upon how the
WireGuard hosting is handled, therefore no information will be provided
about it in this section.
The assumption here is that the configuration file is found at:

  ::

    /etc/wireguard/wg0.conf

Please replace this path in all following commands with your correct
one.

Using the `nmcli` utility, the first step is to import the new
connection using the configuration file:

  ::

    nmcli connection import type wireguard file /etc/wireguard/wg0.conf

As in the previous example about setting a static IP address,
the connection can be edited as needed with:

  ::

    nmcli connection edit wg0

To activate the connection:

  ::

    nmcli connection up wg0

To check it's working as intended, check the device status from `nmcli`:

  ::

    nmcli device status

  ::

    DEVICE  TYPE       STATE                   CONNECTION
    [...]
    wg0     wireguard  connected               wg0
    [...]

And check that the `wg0` interface has the correct IP address assigned,
for example:

  ::

    ip addr show wg0

  ::

    23: wg0: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1420 qdisc noqueue qlen 1000
        link/[65534]
        inet 10.8.0.2/24 brd 10.8.0.255 scope global noprefixroute wg0
           valid_lft forever preferred_lft forever

Try to ping, to check the connection and the DNS resolution are working
correctly:

  ::

    ping -I wg0 axelera.ai

  ::

    PING axelera.ai (199.60.103.26): 56 data bytes
    64 bytes from 199.60.103.26: seq=0 ttl=51 time=83.498 ms
    64 bytes from 199.60.103.26: seq=1 ttl=51 time=93.698 ms
    64 bytes from 199.60.103.26: seq=2 ttl=51 time=48.087 ms
    64 bytes from 199.60.103.26: seq=3 ttl=51 time=44.390 ms
    ^C
    --- axelera.ai ping statistics ---
    4 packets transmitted, 4 packets received, 0% packet loss
    round-trip min/avg/max = 44.390/67.418/93.698 ms

And finally, to close the VPN connection:

  ::

    nmcli connection down wg0

- **Changing SSH server configuration**

The SSH server running on the distribution is based on Dropbear.
Specifically, the Dropbear systemd socket is responsible for the port
listening.
To change the port from the default `22` to, for example, `2222`:

  ::

    systemctl edit dropbear.socket

  ::

    ### Editing /etc/systemd/system/dropbear.socket.d/override.conf
    ### Anything between here and the comment below will become the new contents of

    [Socket]
    ListenStream=
    ListenStream=2222

    ### Lines below this comment will be discarded

    ### /lib/systemd/system/dropbear.socket
    # [Unit]
    # Conflicts=dropbear.service
    #
    # [Socket]
    # ListenStream=22
    # Accept=yes
    #
    # [Install]
    # WantedBy=sockets.target
    # Also=dropbearkey.service

For the rest of the configuration, which is Dropbear-specific,
the default configuration file for dropbear, which is automatically
imported by the systemd service template, can be found at
:code:`/etc/default/dropbear`.

To change the command line arguments for dropbear, e.g.:

  ::

    dropbear -h

    Dropbear server v2020.81 https://matt.ucc.asn.au/dropbear/dropbear.html
    Usage: dropbear [options]
    -b bannerfile	Display the contents of bannerfile before user login
                (default: none)
    -r keyfile      Specify hostkeys (repeatable)
                defaults:
                - dss /etc/dropbear/dropbear_dss_host_key
                - rsa /etc/dropbear/dropbear_rsa_host_key
                - ecdsa /etc/dropbear/dropbear_ecdsa_host_key
                - ed25519 /etc/dropbear/dropbear_ed25519_host_key
    -R		Create hostkeys as required
    -F		Don't fork into background
    -E		Log to stderr rather than syslog
    -m		Don't display the motd on login
    -w		Disallow root logins
    -G		Restrict logins to members of specified group
    -s		Disable password logins
    -g		Disable password logins for root
    -B		Allow blank password logins
    -T		Maximum authentication tries (default 10)
    -j		Disable local port forwarding
    -k		Disable remote port forwarding
    -a		Allow connections to forwarded ports from any host
    -c command	Force executed command
    -p [address:]port
                Listen on specified tcp port (and optionally address),
                up to 10 can be specified
                (default port is 22 if none specified)
    -P PidFile	Create pid file PidFile
                (default /var/run/dropbear.pid)
    -i		Start for inetd
    -W <receive_window_buffer> (default 24576, larger may be faster, max 1MB)
    -K <keepalive>  (0 is never, default 0, in seconds)
    -I <idle_timeout>  (0 is never, default 0, in seconds)
    -V    Version

For example, to disable password logins for root, open
:code:`/etc/default/dropbear` with a text editor and add `-g`
to the `DROPBEAR_EXTRA_ARGS`:

  ::

    # Disallow root logins by default
    DROPBEAR_EXTRA_ARGS=" -B -g"
