.. _security-guide:

==============
Security Guide
==============

This guide documents the security architecture of the Axelera Voyager BSP on
RK3588: the verified boot chain, root filesystem integrity,
and signed over-the-air updates. It covers how each mechanism is
built, how the pieces interact, and what would be required to turn it into a
production configuration.

.. admonition:: Read this first
   :class: important

   This is a **working proof of concept, not a shipping security feature.**

   We will not ship with secure boot enabled.
   Everything from U-Boot upwards is therefore implemented and functional, with
   development keys deliberately committed to the repository so that a clean
   kas build produces a bootable, self-consistent demonstration with no
   external inputs and no per-developer setup.

   The hardware root of trust below U-Boot (loader signing and OTP fusing)
   is **not implemented, not tested, and not planned**. Without it the chain
   provides no security guarantee whatsoever, by design. See
   :ref:`security-overview` for what that means concretely and
   :ref:`security-production` for what closing the gap would involve.

   Read the rest of this document as "here is how the mechanism works and how
   you would configure it", not "here is how this device is secured".

.. contents::
   :local:
   :depth: 2


.. _security-overview:

Overview
========

Four largely independent mechanisms are involved:

.. list-table::
   :header-rows: 1
   :widths: 22 30 48

   * - Mechanism
     - Protects
     - Enforcement point
   * - Rockchip loader secure boot
     - ``idblock``, U-Boot
     - BootROM, against a hash fused into OTP
   * - AVB (Android Verified Boot)
     - ``boot.img`` (kernel + DTB + initramfs)
     - U-Boot, against a public key compiled into U-Boot
   * - dm-verity
     - root filesystem, per 4 KiB block
     - Kernel, against a root hash embedded in the initramfs
   * - Mender artifact signing
     - OTA update payloads
     - ``mender-client``, against a public key in the rootfs

Only the last three are implemented here; the first one is out of scope.


Chain of trust
--------------

.. image:: /build/generated/secure-bootflow.drawio.*
   :width: 70%
   :alt: Verified boot chain of trust on RK3588

.. important::

   **The chain is anchored at U-Boot, not at the BootROM.**

   ``0012-avb-Add-Rockchip-patch-to-hardcode-pubkey.patch`` replaces the
   eFuse-based key validation in ``validate_vbmeta_public_key()`` with a
   ``memcmp()`` against a byte array compiled into U-Boot. That is sound
   *only if* U-Boot itself cannot be replaced, which requires the Rockchip
   loader secure boot stage to be signed and the OTP fused.

   That stage is out of scope for this BSP. Anyone with write access to the
   eMMC can replace U-Boot with one carrying their own AVB public key, at
   which point every layer above it verifies happily against the attacker's
   key. Every mechanism documented below is therefore a **correctness and
   integrity** mechanism (it detects accidental corruption, interrupted
   updates and unsigned artifacts) and not a defence against an attacker
   with physical or root access.

   This is a deliberate scope decision, not an oversight. See
   :ref:`security-production-otp`.


Scope and non-goals
-------------------

Out of scope **by decision**, and not planned:

* Loader/U-Boot signing and OTP fusing. This is the hardware root of trust,
  and its absence is what reduces everything else to an integrity mechanism.


.. _security-avb-vs-fit:

Why AVB and not FIT
-------------------

Rockchip's official secure boot documentation presents **FIT image signature
verification** as the supported mechanism for Linux on RK3588, and describes
AVB as the preferred method for other SoCs but **NOT for the RK3588**.
This BSP does the opposite: it runs a Linux system through Rockchip's Android
bootflow (``boot.img`` built with ``mkbootimg``, A/B slots,
``vbmeta``) and uses AVB to verify it.
This was a deliberate choice, and it was done to maintain the generated image
types and flashing methods used up to now: changing the image to FIT would
have required an entire architectural overhaul.

Two practical consequences follow, and both matter when reading vendor
material:

* **Vendor documentation on this subject should be treated as a starting
  point, not as authoritative.** The claim that AVB is not supported
  is demonstrably not true on this platform, thanks to our work and custom
  patches to allow just that. Where the Rockchip docs
  and the behaviour observed here disagree, the observed behaviour has been
  right so far.
* **This BSP is off the vendor-supported path.** Rockchip support for AVB
  problems on the RK3588 SoC should not be assumed, and BSP bumps may break
  the patches in :ref:`security-uboot` without warning. Budget for that at
  every kernel or U-Boot version bump.


.. _security-partitions:

Partition layout
================

The security work reshaped the GPT substantially. The layout below is the
final state after the introduction of security features, as produced by
``meta-axelera/meta-voyager/wic/voyager-gptdisk.wks.in``.

.. list-table::
   :header-rows: 1
   :widths: 8 20 12 60

   * - Dev
     - Name
     - Size
     - Purpose
   * - N/A
     - ``idblock``
     - N/A
     - ``--no-table``; BootROM-loaded TPL/SPL at sector 32
   * - p1
     - ``uboot``
     - 12M
     - U-Boot proper
   * - p2
     - ``boot_a``
     - 48M
     - Slot A ``boot.img`` (kernel + resource + verity initramfs)
   * - p3
     - ``boot_b``
     - 48M
     - Slot B ``boot.img``
   * - p4
     - ``misc``
     - 512K
     - AVB bootloader control block. Required by Rockchip's AVB code
       to exist; see :ref:`security-uboot-ab` for why it is not actually
       used for slot selection.
   * - p5
     - ``security``
     - 2M
     - Required by the Rockchip bootflow; unused in practice
   * - p6
     - ``vbmeta_a``
     - 768K
     - Signed AVB metadata for slot A
   * - p7
     - ``vbmeta_b``
     - 768K
     - Signed AVB metadata for slot B
   * - p8
     - ``env_a``
     - 128K
     - U-Boot environment (main)
   * - p9
     - ``env_b``
     - 128K
     - U-Boot environment (redundant)
   * - p10
     - ``system_a``
     - 2048M
     - Slot A dm-verity rootfs (ext4 + appended hash tree)
   * - p11
     - ``system_b``
     - 2048M
     - Slot B dm-verity rootfs
   * - p12
     - ``voyager-factory``
     - 128M
     - Factory data, mounted at ``/factory``
   * - p13
     - ``voyager-data``
     - rest
     - Persistent data, mounted at ``/data``; backs the ``/etc`` and ``/home`` overlays


The environment offset invariant
--------------------------------

``CONFIG_ENV_OFFSET`` in ``environment.cfg`` is an absolute byte offset that
U-Boot uses before any partition table is parsed. It **must** land exactly on
the start of ``env_a``. This is a hand-maintained invariant with no build-time
check, and it is the single most common way to break this layout.

The arithmetic for the current layout, with ``--align 8192`` (8 MiB) on
``uboot``:

.. code-block:: text

   uboot      8M      -> 20M
   boot_a     20M     -> 68M     (48M)
   boot_b     68M     -> 116M    (48M)
   misc       116M    -> 116.5M  (512K)
   security   116.5M  -> 118.5M  (2M)
   vbmeta_a   118.5M  -> 119.25M (768K)
   vbmeta_b   119.25M -> 120M    (768K)
   env_a      120M            = 0x7800000  <-- CONFIG_ENV_OFFSET
   env_b      120.125M        = 0x7820000  <-- CONFIG_ENV_OFFSET_REDUND

This is why the series shrank ``boot_a``/``boot_b`` from 32M to 30M when
introducing ``misc``, ``security`` and ``vbmeta_{a,b}``: the four new
partitions total exactly 4 MiB, so 2 MiB came out of each boot slot to keep
the environment at ``0x5400000``. When the boot slots were later grown to 48M
for the verity initramfs, the offsets moved to ``0x7800000``.


Changing the layout
-------------------

Partition numbers are hardcoded in seven places. If you renumber anything,
work through all of them:

.. list-table::
   :header-rows: 1
   :widths: 55 45

   * - File
     - Contains
   * - ``meta-voyager/wic/voyager-gptdisk.wks.in``
     - the layout itself
   * - ``recipes-bsp/u-boot/u-boot-rockchip/environment.cfg``
     - ``CONFIG_ENV_OFFSET``, ``CONFIG_ENV_OFFSET_REDUND``
   * - ``recipes-bsp/u-boot/libubootenv/fw_env.config``
     - ``p8`` / ``p9``
   * - ``conf/machine/include/mender.inc``
     - rootfs A/B numbers, data partition number
   * - ``conf/machine/include/axelera-base.inc``
     - ``OVERLAYFS_ETC_DEVICE``
   * - ``recipes-core/base-files/files/fstab``
     - ``/factory``, ``/data``
   * - ``recipes-mender/mender-client/files/mender.conf``
     - rootfs, boot and vbmeta device paths

Additionally, ``avbtool add_hash_footer --partition_size`` in
``linux-rockchip.inc`` must match the ``boot_a``/``boot_b`` ``--fixed-size``
exactly (currently ``50331648`` = 48 MiB). A mismatch produces a ``boot.img``
whose footer is written at the wrong offset, and AVB verification fails at
boot with a magic or hash error.


.. _security-keys:

Key material
============

There are **three** distinct key roles. Two of them are RSA keypairs used at
different boot stages by different tools, so it is best to not confuse them.

.. list-table::
   :header-rows: 1
   :widths: 20 14 22 44

   * - Role
     - Algorithm
     - Tool
     - Where the public half lives
   * - Loader PSK/ISK
     - per Rockchip doc
     - ``rk_sign_tool``
     - Hash fused into OTP/eFuse
   * - AVB root key
     - **RSA-2048**
     - ``avbtool``
     - Compiled into U-Boot as
       ``include/android_avb/avb_root_pub.h``
   * - Mender artifact key
     - RSA (size configurable)
     - ``mender-artifact``
     - Rootfs, ``/etc/mender/artifact-verify-key.pem``


Development keys in the tree
----------------------------

Two private keys are committed to the repository:

* ``meta-axelera/recipes-kernel/linux/files/private_key.pem`` - AVB
* ``meta-axelera/recipes-mender/mender-client/files/dev-private.key`` - Mender

This is **intentional**. Keeping them in-tree is what makes the proof of
concept reproducible: a clean checkout builds, boots and accepts a signed OTA
with no key ceremony and no per-developer configuration.

The obvious consequence is that any device built with defaults trusts anyone
who has cloned the repository. Given that the chain is unanchored anyway (see
:ref:`security-overview`), these keys are not the weakest link, but they do
mean the repository must be treated as containing no secrets.

.. warning::

   Removing the files later is not sufficient. Both keys are in git history
   and would have to be treated as permanently compromised, with history
   rewritten or the repository re-created.


Generating the AVB root key
---------------------------

.. code-block:: bash

   openssl genpkey -algorithm RSA \
       -pkeyopt rsa_keygen_bits:2048 \
       -outform PEM \
       -out avb_private_key.pem

   openssl rsa -in avb_private_key.pem -pubout -out avb_public_key.pem

Move the new private key to the linux-rockchip recipe files:

.. code-block:: bash

   cp path/to/avb_private_key.pem meta-axelera/recipes-kernel/linux/files/private_key.pem


.. _embedding-avb-key-uboot:

Embedding the AVB public key in U-Boot
--------------------------------------

.. note::

   Using the ``avbtool`` included with the ``rk-binary-native``
   requires ``python2`` on the host.
   The simplest way to have it on modern distros is using ``pyenv``, which
   can be obtained at this link:
   https://github.com/pyenv/pyenv

``avbtool`` emits the public key in AVB's own binary format (not PEM),
which is what U-Boot compares against:

.. code-block:: bash

   python2 ./build/tmp-glibc/sysroots-components/x86_64/rk-binary-native/usr/bin/avbtool extract_public_key \
   --key path/to/avb_private_key.pem \
   --output avb_root_pub.bin

   xxd -i avb_root_pub.bin > avb_root_pub.h

Finally, replace the ``avb_root_pub.h`` file in the U-Boot source.

.. note::

   This will require updating patch :ref:`security-uboot-pubkey`.
   The easiest way to do this is using ``devtool`` within ``kas-container``.

   To enter the ``kas-container`` shell, use the following command:

   .. code-block:: bash

    KAS_CONTAINER_IMAGE_DISTRO=debian-bookworm kas-container --ssh-dir ssh-build-hosts --ssh-agent shell kas/antelao.yaml

   Then, from within this shell, run:

   .. code-block:: bash

    devtool modify u-boot-rockchip
    cd /work/build/workspace/sources/u-boot-rockchip
    git log --oneline --grep "Add Rockchip patch to hardcode pubkey"
    # Assuming for example the output of this command is:
    # a07789be61 avb: Add Rockchip patch to hardcode pubkey
    git rebase -i a07789be61^

   Within the interactive rebase prompt, change ``pick`` to ``edit`` in the
   first line, save and quit.

   Next, move the newly generated ``avb_root_pub.h`` to ``include/android_avb/avb_root_pub.h``,
   and then run:

   .. code-block:: bash

    git add include/android_avb/avb_root_pub.h
    git commit --amend
    git rebase --continue
    devtool finish -f u-boot-rockchip /work/meta-axelera/

   You should see something like:

   .. code-block:: bash

    NOTE: Copying 0012-avb-Add-Rockchip-patch-to-hardcode-pubkey.patch to /work/meta-axelera/recipes-bsp/u-boot/u-boot-rockchip/0012-avb-Add-Rockchip-patch-to-hardcode-pubkey.patch

   ``git status`` should show that patch :ref:`security-uboot-pubkey` has been modified.
   This change should be ready to commit and the repo should be ready
   to be built.


Generating the Mender artifact key
----------------------------------

.. code-block:: bash

   openssl genpkey -algorithm RSA \
       -pkeyopt rsa_keygen_bits:3072 \
       -out mender-private.key

   openssl rsa -in mender-private.key -pubout -out mender-public.key

Both halves are wired in through kas:

.. code-block:: diff

   diff --git a/kas/include/base.yaml b/kas/include/base.yaml
   index b90ce52..c6e8dd5 100644
   --- a/kas/include/base.yaml
   +++ b/kas/include/base.yaml
   @@ -167,5 +167,5 @@ local_conf_header:
        TOOLCHAIN_TARGET_TASK:append = "${@'' if d.getVar('PN') == 'buildtools-tarball' else ' kernel-devsrc'}"

      mender: |
   -    AXE_MENDER_ARTIFACT_SIGN_KEY = "/work/meta-axelera/recipes-mender/mender-client/files/dev-private.key"
   -    AXE_MENDER_ARTIFACT_PUBKEY = "/work/meta-axelera/recipes-mender/mender-client/files/dev-public.key"
   +    AXE_MENDER_ARTIFACT_SIGN_KEY = "path/to/your/mender-private.key"
   +    AXE_MENDER_ARTIFACT_PUBKEY = "path/to/your/mender-public.key"

Paths are resolved inside the kas container, so ``/work`` is the bind-mounted
repository root. A key held outside the repository must be mounted into the
container explicitly.

``AXE_MENDER_ARTIFACT_SIGN_KEY`` is consumed by ``voyager-updateimg.bbclass``
at artifact-build time and has no default; the class calls ``bbfatal`` if it
is empty, so an unsigned artifact cannot be produced by accident.
``AXE_MENDER_ARTIFACT_PUBKEY`` defaults to the shipped development key in
``mender-client_3.%.bbappend``, which means a **missing** public key silently
yields a device that trusts the development key. Consider making that default
fatal for production builds.


.. _security-avb-build:

AVB: build-side implementation
==============================

Tooling
-------

Rockchip's ``avbtool`` lives in the ``rk-binary`` repository under
``extra/linux/Linux_SecurityAVB/scripts/`` and is installed by an append.

This copy of ``avbtool`` is a legacy fork that still requires **Python 2**,
which is why ``meta-python2`` is pinned into ``kas/include/base.yaml`` and why
the kernel recipe depends on ``python-native`` and invokes ``nativepython``
rather than ``python3``.


Image generation
----------------

All AVB work happens in ``do_deploy:append()`` in ``linux-rockchip.inc``, in
three steps.

**1. Build boot.img with the verity ramdisk embedded**

.. code-block:: bash

   ${S}/scripts/mkbootimg \
       --kernel  ${B}/arch/${ARCH}/boot/Image.lz4 \
       --ramdisk ${DEPLOY_DIR_IMAGE}/${INITRAMFS_IMAGE}-${MACHINE}.cpio.gz \
       --second  ${B}/resource.img \
       --cmdline "root=PARTUUID=${RK_ROOTDEV_UUID}" \
       -o ${DEPLOYDIR}/boot.img

The image is rebuilt by hand rather than reusing the kernel's own
``boot.img`` because ``mkbootimg`` must be given ``--ramdisk``, and because
``--cmdline`` now carries ``root=``. The hardcoded ``PARTUUID`` values were
removed from the board device trees' ``bootargs`` in a separate commit so
that this is the single source of truth.

**2. Add the AVB hash footer**

.. code-block:: bash

   nativepython ${STAGING_BINDIR_NATIVE}/avbtool add_hash_footer \
       --image          ${DEPLOYDIR}/boot.img \
       --partition_name boot \
       --partition_size 50331648 \
       --algorithm      SHA256_RSA2048 \
       --key            ${WORKDIR}/private_key.pem

``--partition_name boot`` (not ``boot_a``) is significant; see
:ref:`security-uboot-partname`.

**3. Generate the standalone vbmeta image**

.. code-block:: bash

   nativepython ${STAGING_BINDIR_NATIVE}/avbtool make_vbmeta_image \
       --include_descriptors_from_image ${DEPLOYDIR}/boot.img \
       --padding_size 4096 \
       --algorithm    SHA256_RSA2048 \
       --key          ${WORKDIR}/private_key.pem \
       --output       ${DEPLOYDIR}/vbmeta.img

``vbmeta.img`` is the signed root of the AVB metadata: it carries the hash
descriptor extracted from ``boot.img`` plus a signature over the whole
structure. It is written to *both* ``vbmeta_a`` and ``vbmeta_b`` by the WKS.

An unsigned copy of ``boot.img`` is also deployed as ``unsigned_boot.img``
for debugging and lab testing.

.. note::

   This logic originally lived in ``do_install:append()`` and was moved to
   ``do_deploy:append()`` when dm-verity was introduced, because the ramdisk
   dependency created a loop through the image recipe.


.. _security-uboot:

AVB: U-Boot modifications
=========================

Five patches and one config fragment are applied to the Rockchip U-Boot fork.
All are marked ``Upstream-Status: Inappropriate [oe-specific]``.

These patches are what makes AVB verification work for a Linux payload rather
than an Android one; see :ref:`security-avb-vs-fit`. They are the most
fragile part of the BSP and the first thing to re-test after any U-Boot
version bump; three of the five touch ``common/android_bootloader.c``.

.. list-table::
   :header-rows: 1
   :widths: 8 34 58

   * - #
     - Patch
     - Purpose
   * - 0010
     - ``avb-Spoof-A-B-slot-routing-to-follow-Mender``
     - Make AVB read the active slot from the U-Boot environment
   * - 0011
     - ``android_bootloader.c-Fix-boot-crash-with-AVB-images``
     - Strip the A/B suffix before descriptor lookup
   * - 0012
     - ``avb-Add-Rockchip-patch-to-hardcode-pubkey``
     - Replace eFuse key validation with a compiled-in key
   * - 0013
     - ``include-configs-Enlarge-SYS_BOOTM_LEN``
     - 64M -> 128M decompression window
   * - 0014
     - ``android_bootloader-Avoid-to-skip_initramfs-for-dm-ve``
     - Stop U-Boot suppressing the initramfs

``secureboot.cfg`` contains a single option:

.. code-block:: text

   CONFIG_ANDROID_AB=y


.. _security-uboot-ab:

0010 - Slot routing
-------------------

Two A/B mechanisms are in play and they disagree:

* **AVB** reads the active slot from the ``misc`` partition's bootloader
  control block, via ``rk_avb_get_current_slot()``.
* **Mender** reads and writes the U-Boot environment variable
  ``mender_boot_part``.

Rather than teach Mender to write the ``misc`` partition, which
would make the matter extremely complex,
the patch redirects AVB to the environment:

.. code-block:: diff

    int ab_get_slot_suffix(char *slot_suffix)
    {
   -	/* TODO: get from pre-loader or misc partition */
   -	if (rk_avb_get_current_slot(slot_suffix)) {
   -		printf("rk_avb_get_current_slot() failed\n");
   -		return -1;
   -	}
   +	/* Mender Integration: Override AVB slot selection */
   +	ulong part_num = env_get_ulong("mender_boot_part", 10, MENDER_ROOTFS_PART_A_NUMBER);

The patch also allows AVB to write the Mender variables back on a failed
boot, so that a boot-loop is broken by the same mechanism Mender uses.

Note the consequence: ``mender_boot_part`` holds a **rootfs** partition number
(10 or 11), and U-Boot derives the *boot* slot from it. The mapping between
rootfs slot and boot slot is therefore fixed by convention in three places:
this patch, the update module, and the WKS ordering; therefore it is not
expressible as configuration.

``MENDER_ROOTFS_PART_A_NUMBER`` reaches U-Boot through
``config_mender_defines.h``, generated by meta-mender's U-Boot integration.

.. note::

   The ``misc`` partition still has to exist for the Rockchip AVB code to
   initialise, but is no longer consulted for slot selection.


.. _security-uboot-partname:

0011 - Descriptor name mismatch
-------------------------------

``avbtool add_hash_footer --partition_name boot`` writes a descriptor named
``boot``. U-Boot, however, passes the *physical* partition name (``boot_a``
or ``boot_b``) into ``android_slot_verify()`` as the requested partition,
and libavb then fails to find a matching descriptor. The resulting NULL
dereference on the ``hdr`` array crashes the boot.

The patch strips the slot suffix before building the request list:

.. code-block:: diff

   +	char boot_base_partname[PART_NAME_LEN] = {0};
   +
   +	strncpy(boot_base_partname, boot_partname, sizeof(boot_base_partname) - 1);
   +
   +	if (slot_suffix && strlen(slot_suffix) >= 2) {
   +		/* drop a trailing "_a" / "_b" if present */
   +	}
   +
    	const char *requested_partitions[] = {
   -		boot_partname,
   +		boot_base_partname,

The alternative, signing each slot with ``--partition_name boot_a`` and
``boot_b`` and generating two vbmeta images, was not taken; it would imply
maintaining two distinct signed boot images per build, which would be identical
in all except the ``partition_name``.

.. _security-uboot-pubkey:

0012 - Hardcoded public key
---------------------------

This patch does two things.

It replaces the body of ``validate_vbmeta_public_key()`` and
``validate_public_key_for_partition()``, which in the vendor tree either
call ``avb_atx_validate_vbmeta_public_key()`` (eFuse-backed) or
unconditionally trust the key depending on ``CONFIG_AVB_VBMETA_PUBLIC_KEY_VALIDATE``,
with a direct comparison:

.. code-block:: diff

   +	*out_is_trusted = false;
   +	if (public_key_length != avb_root_pub_bin_len)
   +		return AVB_IO_RESULT_ERROR_IO;
   +	if (memcmp(public_key_data, avb_root_pub_bin, public_key_length) == 0)
   +		*out_is_trusted = true;

Note that the ``#else`` branch of the original code set ``*out_is_trusted =
true`` unconditionally. Without this patch, **AVB verification is a no-op**:
any correctly-formatted vbmeta signed by any key is accepted.

It also forces the device lock state:

.. code-block:: diff

    	if (ops->read_is_device_unlocked(ops, (bool *)&unlocked) != AVB_IO_RESULT_OK)
    		printf("Error determining whether device is unlocked.\n");

   +	unlocked = 0; /* Lock State Fixed */

An unlocked device skips verification entirely, so this is required; however,
it also means the ``security`` partition's lock state is ignored and there is
no supported way to unlock a unit for development. Development units need a
separate U-Boot build.

The approach is taken verbatim from Rockchip's public secure boot
documentation and is only as strong as the loader-stage signing beneath it.


0013 - Decompression window
---------------------------

Adding the ramdisk pushed the decompressed image past U-Boot's default 64 MiB
``bootm`` window:

.. code-block:: text

   Uncompressing LZ4 Kernel Image from 0x05480000 to 0x00400000 ...
   Image too large(0x4000000 >= 0x4000000): increase CONFIG_SYS_BOOTM_LEN

Raised to 128 MiB.


.. _uboot-initramfs-suppression:

0014 - Initramfs suppression
----------------------------

Rockchip's ``android_bootloader_boot_flow()`` passes ``skip_initramfs`` on the
kernel command line unless it detects Android >= 10 with dynamic partitions.
Since dm-verity setup lives *in* the initramfs, skipping it means the rootfs
is never mapped:

.. code-block:: diff

   -		if (ab_is_support_dynamic_partition(dev_desc)) {
   -			mode_cmdline = "androidboot.force_normal_boot=1";
   -		} else {
   -			mode_cmdline = "skip_initramfs";
   -		}
   +		/* For Linux dm-verity, do NOT skip_initramfs */
   +		mode_cmdline = "androidboot.force_normal_boot=1";


.. _security-dmverity:

dm-verity
=========

dm-verity presents the rootfs as a read-only device-mapper target whose every
4 KiB block is checked against a Merkle tree at read time. The tree's root
hash is fixed at build time and baked into the initramfs, which is itself
inside the AVB-verified ``boot.img``.


Kernel configuration
--------------------

``meta-axelera/recipes-kernel/linux/files/security.cfg``:

.. code-block:: text

   # Options to allow DM Verity
   CONFIG_BLK_DEV_DM=y
   CONFIG_DM_CRYPT=y
   CONFIG_BLK_DEV_CRYPTOLOOP=y
   CONFIG_DM_VERITY=y

.. note::

   This configuration came from the Rockchip reference configuration.


Build configuration
-------------------

.. code-block:: diff

   diff --git a/meta-axelera/meta-voyager/conf/distro/voyager.conf b/meta-axelera/meta-voyager/conf/distro/voyager.conf
   --- a/meta-axelera/meta-voyager/conf/distro/voyager.conf
   +++ b/meta-axelera/meta-voyager/conf/distro/voyager.conf
   @@ -39,5 +39,10 @@ DISTRO_FEATURES:remove = "vulkan"

   +INITRAMFS_IMAGE = "dm-verity-image-initramfs"
   +DM_VERITY_IMAGE = "voyager-image-weston"
   +DM_VERITY_IMAGE_TYPE = "ext4"
   +IMAGE_CLASSES += "dm-verity-img"

``dm-verity-img.bbclass`` (from ``meta-security``) hooks the image type named
by ``DM_VERITY_IMAGE_TYPE`` for the recipe named by ``DM_VERITY_IMAGE``, runs
``veritysetup format`` over the ext4 image, appends the hash tree, and
deposits ``<image>.ext4.verity`` in ``IMGDEPLOYDIR``. The root hash is picked
up by ``dm-verity-image-initramfs``, whose init script maps the volume.

.. warning::

   ``DM_VERITY_IMAGE`` is set to ``voyager-image-weston`` specifically. Other
   images that include ``voyager-image.inc`` will not get a ``.verity``
   artifact, but the WKS unconditionally references
   ``${IMAGE_LINK_NAME}.${DM_VERITY_IMAGE_TYPE}.verity``. Building a different
   image against this WKS will fail at ``do_image_wic`` rather than produce
   something insecure, but the failure is opaque.


Breaking the dependency loop
----------------------------

The natural dependency graph is circular:

.. code-block:: text

   voyager-image-weston:do_image_wic
       needs boot.img
           needs the verity initramfs
               needs the root hash
                   needs voyager-image-weston's ext4  <-- same recipe

It is resolved by keeping the loop between *tasks* rather than recipes:

* ``do_image_voyager_updateimg[depends]`` and ``do_image_wic[depends]`` point
  at ``${PN}:do_image_ext4`` and ``virtual/kernel:do_deploy``, never at
  ``do_image_complete``.
* ``IMAGE_FSTYPES`` and ``IMAGE_TYPEDEP`` were converted away from ``:append``
  so that the initramfs recipe can override them:

  .. code-block:: text

     # meta-voyager/recipes-core/images/dm-verity-image-initramfs.bbappend
     IMAGE_FSTYPES = "cpio.gz"
     IMAGE_CLASSES = "dm-verity-img"
     IMAGE_ROOTFS_SIZE = "8192"

  Without the hard assignment the initramfs would inherit ``wic``,
  ``voyager-updateimg`` and friends from the distro and recurse.


Runtime consequences
--------------------

A verity rootfs is immutable. Everything that used to write to ``/`` must be
relocated:

* ``/etc`` is an overlayfs with its upper layer on ``/data`` (p13), assembled
  by ``overlayfs-etc-preinit.sh``.
* ``/factory`` (p12) holds Mender's ``device_type``.
* ``/data`` holds Mender state and the update staging area.
* ``/home`` also lives in ``/data`` as an overlay, so the user's home directory
  can be used as normal.

Any packaging change that installs a file expected to be modified in place
will now fail at runtime rather than at build time.


.. _security-mender:

Signed OTA updates
==================

Why the rootfs A/B module was replaced
--------------------------------------

Mender's stock ``rootfs-image`` update module writes a filesystem image to
the inactive rootfs partition. Under this design that is not sufficient:

* The rootfs image is now ``ext4 + verity hash tree``, and its root hash is
  baked into the initramfs inside ``boot.img``. Updating the rootfs without
  updating ``boot.img`` produces a hash mismatch and an unbootable slot.
* ``boot.img`` and ``vbmeta.img`` are no longer shipped inside the rootfs
  (they moved to ``do_deploy``), so the old post-install script that copied
  them out of ``/boot`` no longer has anything to copy.

We therefore replaced ``mender-axelera-state-scripts`` with a custom
update module, ``mender-voyager-update-module``, which ships all three
images together.


Artifact structure
------------------

``voyager-updateimg.bbclass`` builds a zstd tarball containing:

.. code-block:: text

   <image>.ext4.verity     rootfs + hash tree
   boot.img                signed, with AVB footer and verity initramfs
   vbmeta.img              signed AVB metadata
   contents.json           { "boot": ..., "root": ..., "vbmeta": ... }

wrapped in a Mender ``module-image`` artifact of type ``mender-update``.
``contents.json`` gives the on-device module the filenames without needing to
guess them from ``DISTRO_VERSION``.


Artifact verification
---------------------

Verification is configured through ``mender.conf``:

.. code-block:: text

   "ArtifactVerifyKey": "/etc/mender/artifact-verify-key.pem"

installed from ``AXE_MENDER_ARTIFACT_PUBKEY`` by
``mender-client_3.%.bbappend``.


The mender.conf split
---------------------

Mender reads two configuration files: ``/var/lib/mender/mender.conf``
(persistent) and ``/etc/mender/mender.conf`` (transient). The BSP previously
installed its own ``/etc/mender/mender.conf`` and symlinked the other to it,
so both reads saw the same file. That was harmless until signature checking
was added, at which point:

.. code-block:: text

   ERRO[0000] both ArtifactVerifyKey and ArtifactVerifyKeys are set

The fix is to stop overriding the install and let the upstream
``mender-client`` recipe do its own splitting of the ``mender.conf`` found in
``SRC_URI``. The update module compensates by merging both files when it
parses configuration.


Update flow
-----------

.. list-table::
   :header-rows: 1
   :widths: 26 74

   * - State
     - Action
   * - ``Download``
     - Stream the tarball into ``/data/mender/update-files/staging``
   * - ``ArtifactInstall``
     - Unpack, read ``contents.json``, then write rootfs -> inactive
       ``system_{a,b}``, ``boot.img`` -> inactive ``boot_{a,b}``,
       ``vbmeta.img`` -> inactive ``vbmeta_{a,b}``. Set
       ``mender_boot_part``, ``upgrade_available=1``, ``bootcount=0``
   * - ``ArtifactVerifyReboot``
     - Assert ``upgrade_available == 1``
   * - ``ArtifactCommit``
     - Clear ``upgrade_available``
   * - ``ArtifactRollback``
     - Restore ``mender_boot_part`` from ``${FILES}/tmp/orig-part``
   * - ``Cleanup``
     - Remove the staging directory

The module reports ``SupportsRollback: Yes`` and
``NeedsArtifactReboot: Automatic``.

Because U-Boot's AVB slot selection is driven by ``mender_boot_part``
(patch 0010), writing that variable is what switches *both* the rootfs and
the verified boot slot atomically.

.. note::

   Slot A/B routing depends on ``fw_setenv`` writing an environment that
   U-Boot can read. The ``mender_saveenv_canary`` check in the module exists
   to catch a broken integration. Related: ``mkenvimage`` is invoked with
   ``-r`` so the generated ``u-boot-env.img`` carries the redundant-environment
   flag byte that ``CONFIG_ENV_OFFSET_REDUND`` makes U-Boot expect; without
   it, every boot logs ``*** Warning - bad CRC, using default environment``
   and the Mender variables are silently lost.


.. _security-production:

What a production configuration would require
=============================================

This section is **not a procedure to follow**. It exists so that the distance
between the current proof of concept and a genuinely secured device is
written down and can be estimated, should the requirement ever appear.

Software side
-------------

All of this is within the BSP and has been exercised in some form:

* Generate AVB, Mender and loader keypairs in an HSM or an offline key store.
* Replace ``private_key.pem`` and set ``AXE_MENDER_ARTIFACT_SIGN_KEY`` /
  ``AXE_MENDER_ARTIFACT_PUBKEY`` (see :ref:`security-keys`).
* Regenerate ``avb_root_pub.h`` and update patch :ref:`security-uboot-pubkey`
  (see :ref:`embedding-avb-key-uboot` for an idea on how to approach the problem).
* Purge the development keys, treating both as compromised and rewriting
  history.
* Make ``AXE_MENDER_ARTIFACT_PUBKEY`` fatal when unset, rather than defaulting
  to the development key.

Hardware side
-------------

Note that none of this has been attempted:

* Sign the ``idblock``/loader and U-Boot with ``rk_sign_tool``.
* Flash the signed firmware.
* Fuse the OTP with the hash of the loader public key.
* Confirm that a device flashed with an unsigned or differently-signed loader
  now refuses to boot.


.. _security-production-otp:

OTP fusing
----------

.. warning::

   Fusing is **irreversible**. A unit fused with the wrong key hash, or fused
   before the corresponding signed loader is in place, is permanently bricked.
   Any attempt at this must start on sacrificial hardware.

This flow has **not been run by the BSP team** and is not documented here.
Follow the official Rockchip secure boot documentation for RK3588, which is
the authoritative source for it.

In rough outline, so that the shape of the work is visible:
a keypair is generated with ``rk_sign_tool``, used to sign the
``idblock``/loader and U-Boot; the signed firmware is flashed; and the loader
writes the hash of the public key into OTP, after which the BootROM enforces
it. The exact tool invocations, key directory layout, whether secure boot
must be enabled as a separate fuse, and the RK3588-specific caveats are all
things to take from the vendor documentation rather than from this page.

.. note::

   Vendor documentation on this platform has already proven inaccurate in at
   least one respect; see :ref:`security-avb-vs-fit`. Verify each step
   against observed hardware behaviour rather than assuming the document is
   correct, and expect the loader-signing flow to need the same kind of
   investigation the AVB work did.


.. _security-verification:

Verification
============

Boot chain
----------

* Confirm AVB verified the boot image and that initramfs was not skipped:

  .. code-block:: console

     cat /proc/cmdline

  Expect to find the following:

  .. code-block:: console

     androidboot.verifiedbootstate=green
     androidboot.veritymode=enforcing
     root=PARTUUID=...

  And ``skip_initramfs`` to be **absent** (see :ref:`uboot-initramfs-suppression` above).

  .. note::

    ``verifiedbootstate`` is the most useful single indicator. U-Boot sets it to
    ``green`` only when the vbmeta signature validated against the compiled-in
    key *and* every hash descriptor matched. ``orange`` means verification was
    skipped because the device reported itself unlocked; since
    patch :ref:`security-uboot-pubkey` is meant to make this impossible,
    treat it as that patch having stopped working rather than as a configuration
    problem. ``red`` means verification ran and failed.

    ``veritymode=enforcing`` confirms dm-verity will fail on a hash
    mismatch rather than merely logging it.

Root filesystem integrity
-------------------------

* Check device-mapper came up at all:

  .. code-block:: console

     dmesg | grep -i "device-mapper"

  Expect an ``ioctl ... initialised`` line. If this is missing, nothing below
  will work and the kernel configuration is the place to look for mistakes.

* Check ``dm-verity`` is initialised:

  .. code-block:: console

     dmesg | grep -i "device-mapper: verity"

  Which should output something similar to this:

  .. code-block:: console

     [    6.136278] device-mapper: verity: sha256 using implementation "sha256-ce"

* And check that the rootfs is correctly mounted:

  .. code-block:: console

     findmnt /

  The root mount should be a ``/dev/mapper`` device and read-only,
  something like:

  .. code-block:: console

     TARGET SOURCE             FSTYPE OPTIONS
     /      /dev/mapper/rootfs ext4   ro,relatime,seclabel

  The source must be a ``/dev/mapper`` node. 

  .. note::

   A raw ``/dev/mmcblk*`` source means the initramfs fell through to mounting
   the backing partition directly, so dm-verity is not in the path at all.
   The rootfs would still appear read-only in that case, so this check cannot
   be replaced by looking at the mount options alone.

* Confirm the mapped device is a verity target and not some other
  device-mapper type:

  .. code-block:: console

     cat /sys/block/$(basename $(readlink -f /dev/mapper/rootfs))/dm/uuid

  Expect a ``CRYPT-VERITY-`` prefix (or ``VERITY-``).

* Negative test

  It must not be possible to remount the rootfs as read-write, even with
  root access to the board:

  .. code-block:: console

    mount -o remount,rw /

  Expect something similar to:

  .. code-block:: text

    mount: /: cannot remount /dev/root read-write, is write-protected.

  This is the strongest check in this section. It fails at the *block device*
  layer, not the mount layer: a dm-verity target implements no write path, so
  the mapped device carries the read-only flag and the kernel refuses the
  remount outright. A rootfs that is merely mounted ``ro``, with a writable
  device underneath, would remount successfully here.

  A write to a protected path must be refused:

  .. code-block:: console

     echo test > /usr/bin/verity_write_probe

  Expect ``Read-only file system``. Anything else means the rootfs is
  writable and the integrity guarantee is void; remove the file if it was
  actually created.

  This check is weaker than the remount one but is closer to how a real-world
  problem tied to this would come up, e.g. a script or a daemon attempting
  to write something in ``/``. It is good to double check.

Update signing
--------------

* Sign an artifact with a different key and confirm the client rejects it
  rather than installing it. A build without ``AXE_MENDER_ARTIFACT_SIGN_KEY``
  must fail at ``do_image_voyager_updateimg``.


.. _security-limitations:

Known limitations
=================

Deliberate, per the current scope
---------------------------------

.. list-table::
   :header-rows: 1
   :widths: 40 60

   * - Limitation
     - Consequence
   * - Loader signing and OTP not implemented
     - No hardware root of trust. Everything above is an integrity mechanism
       only.
   * - Development private keys in git history
     - The repository contains no secrets and must not be assumed to.
   * - Device lock state hardcoded
     - No supported unlock path; dev units need a separate U-Boot.
