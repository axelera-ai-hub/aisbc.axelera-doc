==============
Build Variants
==============

To support distinct Engineering (ENG) and Release builds, the CI/CD
pipeline and Yocto configurations have been updated. The differentiation
is driven by Kas configuration overlays and propagates through artifact
generation, Jenkins archival, and automated DUT testing.

Yocto Configuration And Build Variant Definition
================================================

``kas/base.yaml``:

.. code-block:: yaml

   engineering: |
    DISTRO_FEATURES:append = "${@' voyager-dm-verity' if d.getVar('AXE_ENGINEERING_BUILD') != '1' else ''}"
    AXE_ENGINEERING_BUILD ?= "1"
    TMPDIR:append = "${@'' if d.getVar('AXE_ENGINEERING_BUILD') == '1' else '-release'}"

The build variant is controlled by the ``AXE_ENGINEERING_BUILD``
variable, which defaults to ``1`` (ENG) unless explicitly overridden by
the ``security.yaml`` Kas overlay.

*   **Default (ENG)**: In ``kas/include/base.yaml``,
    ``AXE_ENGINEERING_BUILD`` is initialized and conditionally assigned
    ``?= "1"``.
*   **Release**: When ``kas/security.yaml`` is appended to the build
    command, it overrides the variable, setting
    ``AXE_ENGINEERING_BUILD = "0"`` and inheriting ``mend`` and
    ``cve-check``.

Image Differentiation Variables
-------------------------------

Based on the value of ``AXE_ENGINEERING_BUILD``, the following technical
differentiations are applied in the Yocto environment:

*   **DISTRO_FEATURES**: The ``voyager-dm-verity`` feature is appended
    *only* if ``AXE_ENGINEERING_BUILD != 1`` (Release).
*   **TMPDIR Configuration**: To allow both build variants to coexist on
    the disk during the CI pipeline, the output directories are split.
    ``TMPDIR`` appends the string ``-release`` if the build is not ENG.

    *   *ENG Path*: ``build/tmp-glibc/``
    *   *Release Path*: ``build/tmp-glibc-release/``

*   **IMAGE_LINK_NAME**: In ``voyager-image.inc``, the string ``eng`` is
    injected between the image basename and machine name (e.g., resulting
    in ``*-eng-antelao-*``) when building for ENG. Additionally,
    test-related packages are conditioned to install only when
    ``AXE_ENGINEERING_BUILD == 1``.

BSP Jenkins Pipeline Updates
============================

The main build pipeline has been refactored to explicitly build, isolate,
and archive both variants.

New Build Stages
----------------

*   **Yocto image Antelao (Release)**: Built using
    ``kas/antelao.yaml:kas/security.yaml``. Vulnerability scans (CVE/Mend
    reports) have been rerouted to pick up outputs from the updated
    ``build/tmp-glibc-release/log/mend/`` and ``.../cve/`` paths.
*   **Yocto image Antelao (ENG)**: A new explicit stage was added that
    builds the image using only ``kas/antelao.yaml`` (dropping the
    security overlay).

Artifact Archival and S3 Upload Layout
--------------------------------------

Because ``TMPDIR`` was split, the Jenkins layout for fetching artifacts
was updated to target the correct directories:

*   **Release Artifacts**: ``.update.img``, ``.wic.gz``, and ``.mender``
    files are now collected and uploaded to S3 from
    ``${out}-release/deploy/images/antelao-3588``.
*   **ENG Artifacts**: Standard artifacts are fetched from
    ``${out}/deploy/images/antelao-3588``. The existing glob patterns
    (``voyager-image*-antelao-3588-*``) automatically capture the new
    ``-eng`` nomenclature without requiring pattern changes.
*   **Debian Packages**: ``.deb`` packages (e.g.,
    ``udev-conf-axelera_*.deb`` and ``kernel-module-metis-*.deb``) are
    restricted to the ENG variant because the secure boot implementation
    in the Release build prevents their installation. These are strictly
    archived from ``build/tmp-glibc/deploy/deb/...``.

Labgrid DUT Testing Exclusions
==============================

The automated hardware testing pipeline must not test security features on
ENG artifacts, as they do not include secure boot. To prevent ENG
artifacts from being deployed to the DUTs, the downstream Jenkinsfile has
been updated to filter them out entirely.

*   **Jenkins copyArtifacts Filter**: The artifact download step includes
    a new exclusion rule: ``excludes: '**/*-eng-*'``.
*   **Mender Path Resolution**: The shell ``find`` commands used to locate
    the ``.mender`` artifacts for both the test build and the reference
    build have been updated with ``! -name '*-eng-*'``. This guarantees
    the test suite exclusively assigns and flashes Release artifacts.
