USB3.0 Loopback Testing
=========

- **Requirements**

  The USB3.0 Loopback testing included with the Voyager distribution is
  based on the USB3.0 Loopback Plug by Passmark:
  https://www.passmark.com/products/usb3loopback/

- **Instructions**

  The shipped utility works with Passmark's API to provide two tools:
  `u3loop`, a utility, and `u3bench`, a benchmarking tool.
  They simply require the Passmark USB3.0 Loopback Plug to be connected
  to any of the available USB ports, and will detect it automatically.

  To use them with the default configuration, after plugging in the
  Passmark device simply run:

    ::

      u3loop

  Or:

    ::

      u3bench

  If in need of further configuration, run the commands followed by `-h`.
