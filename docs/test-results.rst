Testing
=======

**Stress-ng**

- **Rationale**
Stress-ng testing over a duration is necessary to find ou the stability, resilience and enduramce of the system.

- **Stress-ng command format**

    * stress-ng - main command
    * vm - virtual memory; stressor option
    * vm-bytes - bytes of virtual memorey allocates; stressor option
    * vm-method - methods to cycle through such as read, write, fill, touch, move, etc; stressor option
    * verify - ensures written data is read back correctly,tests correctness and speed; stressor option
    * mmap - maps memory regions and access them; stressor option
    * mmap-bytes - amount bytes allocated can be specified in number or %; stressor option
    * page-in - force page-in of mapped memory, stressing the page cache & fault handling; stressor option
    * timeout - duration for which tests need to run, default is 1 day if not specified
    * metrics - reports bogo-ops/sec and other stats at the end of tests
    * The numbers following each stressor option is the number of stressors

    Note: For ``vm-bytes`` and ``mmap-bytes`` % of memory has been specified, it can be a number too as mentioned before

    For Antelao RAM total: 15.6G

    For ITX Firefly RAM total: 7.5G

    We can just use the same command without having to change the ``vm-bytes`` and ``mmap-bytes`` according to both boards

    Note 2: For more information refer stress-ng --help

    If connected through ``adb shell``, the above command may result in a Segmentation fault. Use with ``|less`` or ``|more``

- **Stress-ng Results**

    * bogo ops → a counter of the operations done (not a real-world standardized unit, just a way to compare)
    * elapsed time (real, user, system)
    * bogo ops/s → throughput based on real time
    * bogo ops/s (usr+sys time) → throughput adjusted for CPU time actually consumed
    Basically, it gives you a summary of how hard the stressors worked and their relative performance

    * real time = wall-clock duration (10800s = 3h)
    * usr time = time spent in user space code
    * sys time = time spent in kernel space (syscalls, page faults, memory mapping)

- **Test results on Antelao board**

 .. code-block:: bash
    :linenos:

    antelao@antelao-3588:~$ stress-ng --vm 1 --vm-bytes 60% --vm-method all --verify --mmap 2 --mmap-bytes 30% --page-in --timeout 3h --metrics --verbose
    stress-ng: debug: [698] stress-ng 0.13.12 gf59bcb2fe1e2
    stress-ng: debug: [698] system: Linux antelao-3588 6.1.148-rockchip-standard #1 SMP Tue Sep  2 12:13:34 CEST 2025 aarch64
    stress-ng: debug: [698] RAM total: 15.6G, RAM free: 15.2G, swap free: 0.0
    stress-ng: debug: [698] 8 processors online, 8 processors configured
    stress-ng: info:  [698] setting to a 43200 second (12 hours, 0.00 secs) run per stressor
    stress-ng: info:  [698] dispatching hogs: 1 vm, 2 mmap
    stress-ng: debug: [698] cache allocate: shared cache buffer size: 3072K
    stress-ng: debug: [698] starting stressors
    stress-ng: debug: [698] 3 stressors started
    stress-ng: debug: [699] stress-ng-vm: started [699] (instance 0)
    stress-ng: debug: [700] stress-ng-mmap: started [700] (instance 0)
    stress-ng: debug: [701] stress-ng-mmap: started [701] (instance 1)
    stress-ng: debug: [699] stress-ng-vm using method 'all'
    stress-ng: debug: [699] stress-ng-vm: exited [699] (instance 0)
    stress-ng: debug: [698] process [699] terminated
    stress-ng: debug: [700] stress-ng-mmap: exited [700] (instance 0)
    stress-ng: debug: [698] process [700] terminated
    stress-ng: debug: [701] stress-ng-mmap: exited [701] (instance 1)
    stress-ng: debug: [698] process [701] terminated
    stress-ng: info:  [698] successful run completed in 43203.00s (12 hours, 3.00 secs)
    stress-ng: info:  [698] stressor       bogo ops real time  usr time  sys time   bogo ops/s     bogo ops/s CPU used per
    stress-ng: info:  [698]                           (secs)    (secs)    (secs)   (real time) (usr+sys time) instance (%)
    stress-ng: info:  [698] vm            395177506  43200.61  42595.21    606.78      9147.50        9147.21       100.00
    stress-ng: info:  [698] mmap               5346  43202.84  38523.23  47875.07         0.12           0.06        99.99
    stress-ng: debug: [698] metrics-check: all stressor metrics validated and sane

**Results**

The above results are for a duration of 12h which is good way of testing the stability of a board.


- **Test results on ITX board**

 .. code-block:: bash
    :linenos:

    firefly@itx-3588j:~$ stress-ng --vm 1 --vm-bytes 60% --vm-method all --verify --mmap 2 --mmap-bytes 30% --page-in --timeout 3h --metrics --verbose
    stress-ng: debug: [2462] stress-ng 0.13.12 gf59bcb2fe1e2
    stress-ng: debug: [2462] system: Linux itx-3588j 6.1.148-rockchip-standard #1 SMP Tue Sep  2 15:43:34 IST 2025 aarch64
    stress-ng: debug: [2462] RAM total: 7.5G, RAM free: 7.1G, swap free: 0.0
    stress-ng: debug: [2462] 8 processors online, 8 processors configured
    stress-ng: info:  [2462] setting to a 10800 second (3 hours, 0.00 secs) run per stressor
    stress-ng: info:  [2462] dispatching hogs: 1 vm, 2 mmap
    stress-ng: debug: [2462] cache allocate: shared cache buffer size: 3072K
    stress-ng: debug: [2462] starting stressors
    stress-ng: debug: [2462] 3 stressors started
    stress-ng: debug: [2463] stress-ng-vm: started [2463] (instance 0)
    stress-ng: debug: [2464] stress-ng-mmap: started [2464] (instance 0)
    stress-ng: debug: [2463] stress-ng-vm using method 'all'
    stress-ng: debug: [2465] stress-ng-mmap: started [2465] (instance 1)
    stress-ng: debug: [2464] stress-ng-mmap: exited [2464] (instance 0)
    stress-ng: debug: [2465] stress-ng-mmap: exited [2465] (instance 1)
    stress-ng: debug: [2463] stress-ng-vm: exited [2463] (instance 0)
    stress-ng: debug: [2462] process [2463] terminated
    stress-ng: debug: [2462] process [2464] terminated
    stress-ng: debug: [2462] process [2465] terminated
    stress-ng: info:  [2462] successful run completed in 10800.31s (3 hours, 0.31 secs)
    stress-ng: info:  [2462] stressor       bogo ops real time  usr time  sys time   bogo ops/s     bogo ops/s CPU used per
    stress-ng: info:  [2462]                           (secs)    (secs)    (secs)   (real time) (usr+sys time) instance (%)
    stress-ng: info:  [2462] vm            120831213  10800.31  10575.55    221.21     11187.75       11191.43        99.97
    stress-ng: info:  [2462] mmap               2257  10800.13   9043.67  12532.19         0.21           0.10        99.89
    stress-ng: debug: [2462] metrics-check: all stressor metrics validated and sane


**Results**

The test have run over 3h with all stressors specified and the board has been stable.
