Axelera AI Accelerator Firefly RK3588J Yocto Guide
==================================================

.. contents::
    :depth: 2
    :local:

Contents
--------

0. Revision History
-------------------

+----------+------------+-----------------------------+---------+-------------------+
|   Date   | Author     | E-Mail                      | Version | Description       |
+----------+------------+-----------------------------+---------+-------------------+
| 01-08-24 | Jagan Teki | jagan@amarulasolutions.com  | V1.0    |                   |
+----------+------------+-----------------------------+---------+-------------------+
|          |            |                             |         |                   |
+----------+------------+-----------------------------+---------+-------------------+

1. Specification
----------------

2. meta-axelera
---------------

- **Host Prerequisite**

  Ubuntu 22.04 

  ::

    sudo apt update && sudo apt install -y python3-pip && pip install kas
    sudo apt install -y podman
 
- **Build**

  ::
    
    git clone git@github.com:amarula/meta-axelera.git && cd meta-axelera
    kas-container build

- **Program**  

  ::

    cd meta-axelera && ls -l build/tmp-glibc/deploy/images/itx-3588j

3. Support
----------

