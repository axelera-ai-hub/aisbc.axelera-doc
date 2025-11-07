SATA Disk Benchmarking
======================

- **Requirements**

  Any internal SATA disk can be used for this purpose.
  It is sufficient to connect it to the SATA port that has to be tested
  and provide it with power.

- **Instructions**

  Since the rootfs is read-only, two mountpoints are already provided.

  To start, it is required to mount the disk to one of the provided
  mountpoints.
  Assuming the disk is on `/dev/sda1`, then:

    ::

      mount /dev/sda1 /mnt/sata0

  Or:

    ::

      mount /dev/sda1 /mnt/sata1

  Then, simply run the following script:

    ::

      #!/bin/bash

      # A simple script to benchmark a drive and clean up.
      # The script accepts one argument: the name of the mount point directory under /mnt/
      # Example: ./fiotest.sh sata0  (will use /mnt/sata0)
      # Example: ./fiotest.sh mydrive (will use /mnt/mydrive)
      #
      # This script requires 'fio' to be installed.

      # --- Argument Check ---
      if [[ "$#" -ne 1 ]]; then
          echo "Usage: $0 <mount_directory_name>"
          echo "Example: $0 sata0"
          echo "This will use /mnt/sata0 as the mount point."
          exit 1
      fi

      MOUNT_SUFFIX="$1"
      MOUNT_POINT="/mnt/${MOUNT_SUFFIX}"
      TEST_FILE="${MOUNT_POINT}/benchmark_testfile"
      FILE_SIZE_MB="1024" # 1GB

      # --- Helper Functions ---

      # Function to print a nice header
      print_header() {
          echo "-------------------------------------------------"
          echo "$1"
          echo "-------------------------------------------------"
      }

      # Function to clean up the test file
      cleanup() {
          echo ""
          print_header "Cleaning up test file"
          if [[ -f "${TEST_FILE}" ]]; then
              rm "${TEST_FILE}"
              echo "Removed ${TEST_FILE}"
          else
              echo "Test file not found, nothing to clean."
          fi
          echo "Benchmark complete."
      }

      # Ensure cleanup runs even if the script is interrupted (e.g., Ctrl+C)
      trap cleanup EXIT

      # --- Main Script ---

      echo "SATA Benchmark Script (fio required)"
      echo "Mount Point: ${MOUNT_POINT}"
      echo "Test File:   ${TEST_FILE}"
      echo "File Size:   ${FILE_SIZE_MB}MB"
      echo ""

      # Check if mount point exists and is mounted
      if ! mountpoint -q "${MOUNT_POINT}"; then
          echo "Error: ${MOUNT_POINT} is not a valid mount point."
          echo "Please ensure the drive is mounted there before running."
          exit 1
      fi

      # Check if fio is installed
      if ! command -v fio &> /dev/null; then
          print_header "Error: 'fio' not found"
          echo "'fio' is required for this benchmark script."
          echo "Please install 'fio' (e.g., via your Yocto build) and try again."
          exit 1
      fi

      # --- FIO BENCHMARK ---
      print_header "Running benchmark with FIO (bypasses cache)"

      echo "Test 1: Sequential Write (1M block)"
      fio --name=seq-write --rw=write --bs=1M --size="${FILE_SIZE_MB}"M \
          --direct=1 --filename="${TEST_FILE}" --do_verify=0 --ioengine=libaio | grep "bw="
      if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
          echo "Error during 'fio' sequential write test. Aborting."
          exit 1
      fi

      echo ""
      echo "Test 2: Sequential Read (1M block)"
      fio --name=seq-read --rw=read --bs=1M --size="${FILE_SIZE_MB}"M \
          --direct=1 --filename="${TEST_FILE}" --do_verify=0 --ioengine=libaio | grep "bw="
      if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
          echo "Error during 'fio' sequential read test. Aborting."
          exit 1
      fi

      echo ""
      echo "Test 3: 4K Random Write"
      fio --name=rand-write --rw=randwrite --bs=4k --size="${FILE_SIZE_MB}"M \
          --direct=1 --filename="${TEST_FILE}" --do_verify=0 --ioengine=libaio | grep "bw="
      if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
          echo "Error during 'fio' random write test. Aborting."
          exit 1
      fi

      echo ""
      echo "Test 4: 4K Random Read"
      fio --name=rand-read --rw=randread --bs=4k --size="${FILE_SIZE_MB}"M \
          --direct=1 --filename="${TEST_FILE}" --do_verify=0 --ioengine=libaio | grep "bw="
      if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
          echo "Error during 'fio' random read test. Aborting."
          exit 1
      fi

      # The 'trap' command will handle cleanup automatically at the end.
      exit 0

  The script itself will handle everything else and provide you with
  the benchmark data in different scenarios.

- **Results**

  The following are the results obtained with a `Samsung 840 EVO 500GB`
  SSD.

  Left SATA port:

    ::

      SATA Benchmark Script (fio required)
      Mount Point: /mnt/sata
      Test File:   /mnt/sata/benchmark_testfile
      File Size:   1024MB

      -------------------------------------------------
      Running benchmark with FIO (bypasses cache)
      -------------------------------------------------
      Test 1: Sequential Write (1M block)
        WRITE: bw=306MiB/s (321MB/s), 306MiB/s-306MiB/s (321MB/s-321MB/s), io=1024MiB (1074MB), run=3347-3347msec

      Test 2: Sequential Read (1M block)
         READ: bw=301MiB/s (316MB/s), 301MiB/s-301MiB/s (316MB/s-316MB/s), io=1024MiB (1074MB), run=3398-3398msec

      Test 3: 4K Random Write
        WRITE: bw=29.1MiB/s (30.5MB/s), 29.1MiB/s-29.1MiB/s (30.5MB/s-30.5MB/s), io=1024MiB (1074MB), run=35174-35174msec

      Test 4: 4K Random Read
         READ: bw=16.5MiB/s (17.3MB/s), 16.5MiB/s-16.5MiB/s (17.3MB/s-17.3MB/s), io=1024MiB (1074MB), run=62071-62071msec

      -------------------------------------------------
      Cleaning up test file
      -------------------------------------------------
      Removed /mnt/sata/benchmark_testfile
      Benchmark complete.

  Right SATA port:

    ::

      SATA Benchmark Script (fio required)
      Mount Point: /mnt/sata
      Test File:   /mnt/sata/benchmark_testfile
      File Size:   1024MB

      -------------------------------------------------
      Running benchmark with FIO (bypasses cache)
      -------------------------------------------------
      Test 1: Sequential Write (1M block)
        WRITE: bw=335MiB/s (351MB/s), 335MiB/s-335MiB/s (351MB/s-351MB/s), io=1024MiB (1074MB), run=3061-3061msec

      Test 2: Sequential Read (1M block)
         READ: bw=355MiB/s (372MB/s), 355MiB/s-355MiB/s (372MB/s-372MB/s), io=1024MiB (1074MB), run=2886-2886msec

      Test 3: 4K Random Write
        WRITE: bw=27.3MiB/s (28.6MB/s), 27.3MiB/s-27.3MiB/s (28.6MB/s-28.6MB/s), io=1024MiB (1074MB), run=37479-37479msec

      Test 4: 4K Random Read
         READ: bw=16.0MiB/s (16.7MB/s), 16.0MiB/s-16.0MiB/s (16.7MB/s-16.7MB/s), io=1024MiB (1074MB), run=64161-64161msec

      -------------------------------------------------
      Cleaning up test file
      -------------------------------------------------
      Removed /mnt/sata/benchmark_testfile
      Benchmark complete.
