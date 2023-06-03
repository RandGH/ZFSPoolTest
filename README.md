# ZFSPoolTest
A perl script to perform automated tests on zfs pools.
Please note i started with this and its working, but at some point I stopped working on it. It may have bugs, it has debugging comments, it has a large list of ideas that I never implemented.

Please use at your own risk, no warranty it won't melt your drives or cause havoc on existing pools. It shouldnt, but if you misonfigure it ...


This script started as a winter holidy project when trying to do some performance measurements on zfs pools to use with high speed networking.

Basically it takes a bunch of disks provided to it and combines them into various pool layouts, creates datasets on the pool, runs dd or fio tests on them and then destroys everything. Rinse and Repeat.
Tons of options eg to run sync/async, use l2arc, slog (or multiple of each).

It was originally created in 2019/20 so does not support metadata devices yet.

It was created on TNC11.x originally but its working on 13.0U5. I think it should also work on TNS. It should also work on other ZFS based systems

Dependencies - 
-It needs json_pp to parse the fio results, included in TNC
-Its using disklist.pl https://github.com/nephri/FreeNas-DiskList


