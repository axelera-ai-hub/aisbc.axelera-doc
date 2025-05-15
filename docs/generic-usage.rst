Generic usage guide
=======================

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

