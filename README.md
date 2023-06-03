# ZFSPoolTest
A perl script to perform automated tests on zfs pools.
Please note i started with this and its working, but at some point I stopped working on it. It may have bugs, it has debugging comments, it has a large list of ideas that I never implemented.

Please use at your own risk, no warranty it won't melt your drives or cause havoc on existing pools. It shouldnt, but if you misonfigure it ...


This script started as a winter holiday project when trying to do some performance measurements on zfs pools to use with high speed networking.

**Basically it takes a bunch of disks provided to it and combines them into various pool layouts, creates datasets on the pool, runs dd or fio tests on them (potentially many many many tests due to fio blocksize, iops, qd, read, write, zfs blocksize, sync/async, compression permutations) and then destroys everything. Rinse and Repeat.**
Tons of options eg to run sync/async, use l2arc, slog (or multiple of each), create database statements to insert results into pgsql and mysql (not tsmdb's yet)

It was originally created in 2019/20 so does not support metadata devices yet.

It was created on TNC11.x originally but its working on 13.0U5. I think it should also work on TNS. It should also work on other ZFS based systems. Might need to adjust json_pp to jsonpp on Linux

## Dependencies
- It needs json_pp to parse the fio results, included in TNC
- Its using disklist.pl https://github.com/nephri/FreeNas-DiskList

Output are reports in csv format, or sql statements for a SQL DB.
Always wanted to move the display to Grafana but never got around to it, but I've seen they have a sql plugin now, or CSV. Haven't tried.

Discussion - https://forums.servethehome.com/index.php?threads/zfs-pool-test.40314/



Configuration options from perl script - never got around to implement parameters...
Just dumping the current content with al the commented options. 
Maybe I'll do some cleanup in the script and here later. Or if someone else wants to...

**Main Disk config file is pool_test.config. Add all drives that are to be used in tests in there (or define directly in perl script)**

This is the disklist for pool_test.pl
Please configure the disks you want to test in here.
```
#Use a format like 
#<type>=disk-identifier
#<type>:disk-identifier

#valid types are 
#data  - for regular pool drives
#slog1 or slog2  - for slog devices (2 maximum)
#l2arc1 or l2arc2  - for l2arc devices (2 maximum)
#userpool= uses a precreated pool to perform tests [just skips pool creation]
slog1=da1
l2arc1=da2
data=/dev/ada0
data=/dev/ada5
```
## pool_test.pl Config options

### Pool configuration
```
Currently supported device to pool layout combinations
  type		single	mirror-2	mirror-3	stripe
  single	  o	  x		  x		  o
    z1		  x	  o		  o		  o
    z2		  x	  o		  o		  o
    z3		  x	  o		  o		  o

Currently supported device to pool layout combinations EXTENDED
   type		single	mirror-n	stripe-n
  single  	  x  	  x 		  x
    z1		  x	  -		  x
    z2		  x	  -		  x
    z3		  x	  -		  x
```
#### Pool layout configuration - default enables all possible pool configurations, including unsafe ones (eg single vdev)
- my @uservar_vdev_type=('single','z1','z2','z3');
- my @Uservar_vdev_redundancy=('single','stripe','mirror');
##### extend for wider mirrors
- my @uservar_vdev_mirrortypes=(2,3);

how many devices will be in a stripe at maximum stripe width. 0 = all available
note this means a lot of pools when used in combination with layout=individual below

## USER configurable parts 
- my $userpool_do=0; #set to 1 if you want to use a self created pool to be used for tests (with creating datasets), no automated pool creation. Needs 'userpool=' entry in pool_test.config
##### not implemented yet:
- my $testsonly_do=0; #set to 1 if you want only to run fio or dd tests on a given device or file 

### DISKS TO USE IN TESTS (only if config file is not present) 
##### these values will only be used if no alternative way of passing disks has been selected (i.e. no config file pool_test.config is present and has data)
- my $uservar_slogdev ="gptid/33b5d616-692d-11e9-9421-a4bf01059e9a";
- my @uservar_datadisks=('da0','da1','da2','da3');
- my $uservar_slogdev ="/dev/pmem0";
- my $uservar_slogdev2 ="slog2";
- my $uservar_l2arcdev ="l2arc1";
- my $uservar_l2arcdev2 ="l2arc2";

### LOG AND SCREEN output 
##### log verbosity - 4 is very very verbose
- my $verbose=4;  #level 1-4 (4=debug)

##### logs are written to a more persistent location (user specified or in a subdir of the current position) - else they are created on the tested pool
- my $user_make_logs_persistent=1;
- my $user_logdir=".";

### Program stop, info & adhoc report options
##### create this file (via touch pool_test.pl.stop) to stop processing asap (with creating results up to the time of stop, touchfile will be deleted)
- my $stopfile="$0.stop";

##### set to >0 to create the report more often, else you get nothing until the script exits (and nothing if it does not exit properly)
- 3 will create an output file after each fio/dd test - note this adds significant overhead especially on short tests as this will run after each single test and will dump out all results each time
- 2 will run the report after each dataset
- 1 will run the report after each pool
- my $_do_regular_output=2;

##### create this file (via touch pool_test.pl.info) to get runtime infos printed once (touchfile will be deleted afterwards)
- my $infofile="$0.info";

##### create this file (via touch pool_test.pl.report) to get a report printed once (touchfile will be deleted afterwards)
- my $reporttouchfile="$0.report";

##### create this file (via touch pool_test.pl.loglevelX) to get change the current loglevel (touchfile will be deleted afterwards)
- my $loglevel1touchfile="$0.loglevel1";
- my $loglevel2touchfile="$0.loglevel2";
- my $loglevel3touchfile="$0.loglevel3";
- my $loglevel4touchfile="$0.loglevel4";

### Other program options
- my $dryrun=0; # perform a dryrun only (=log all commands but don't execute them) - not really working all too well since some commands work on basis of other commands
    
##### todo my $log_testcommands=1; # save all commands that are being run for tests in a separate file without actual pool name so they can be rerun somewhere else.
- my $use_sep='.'; #use , as fraction separator instead of ,
- my $use_sep=','; #use , as fraction separator instead of .

- my $user_runzpooliostat=0; #run iostat while running commands - only gathering data for now, not being processed
- my $user_runpsaux=0; #run psaux while running benchmark commands to get cpu load - only gathering data for now
- my $user_rungstat=0; #run gstat while running benchmark commands to get individual drive load only gathering data for now
- my $user_gettemps=0; #get disk temps while running benchmarks
- my $user_gettemps_interval=15; #get disk temps every 15sec

### Limit ARC
- my $arc_limit_do=0; #set to 1 if you want the arc size to be limited
- my $arc_limit="512M"; #this limits arc_min_size, arc_max_size and arc_meta_limit to the given size - not sure how well that actually works

### Pool creation options 

##### trim on init (setting vfs.zfs.vdev.trim_on_init to 0) - dont use for real life tests unless you know the disk is clean - takes a while per disk
- #used for development
- my $skip_trim_on_create=0;

- #BEWARE - this forces pool creation and can lead to data loss if the wrong disks are used !!!!!
- #edit: actually only if a pool is not actually present (ie unimported pool on used disks)
- my $force_pool_creation=1;

- #Mirror of Raid Z vdevs will not work, so we will skip these
- #my @uservar_vdev_type=('sin','z1','z2','z3');
- #my @uservar_vdev_type=('sin','z2');
- my @uservar_vdev_type=('z1');
- #note you need 'no' and 'mir' if you want to test mirrors and zX in the same run
- #my @uservar_vdev_redundancy=('no','str','mir'); #no=no redundancy, str=stripes and mir=mirrors
- my @uservar_vdev_redundancy=('no');
- #extend for wider mirrors # 2-x
- #my @uservar_vdev_mirrortypes=(2,3); #run 2x mirrors and 3x mirrors on test
- my @uservar_vdev_mirrortypes=(2);
- #how many devices will be in a stripe at maximum stripe width. 0 = all available
- #note this means a lot of pools when used in combination with layout=individual below
- my $uservar_max_stripewidth=0;

##### define amount of disks per pooltype. O/C m2/m3 are not two pool types but only disk increase but it got its own type nevertheless.
##### Raid Z's are based on a 4+x [1,2,3] layout, not absolute minimums - larger values (y+x [y=4,5,6,7..., x=1,2,3]) can be specified
- my $_diskcount_z1=5; #minimum 2
- #my $_diskcount_z2=6; #minimum 3
- my $_diskcount_z2=10; #minimum 3 - you'll need 10 drives for this 
- my $_diskcount_z3=12; #minimum 4

## Pool build scenarios
##### provide different build pool options, valid combinations are 1+2, 2+3, 1 only, 2 only, 3 only
##### set appropriate option to non zero to activate
- 1. Build one big pool out of all possible vdevs (vdev_layout_full)
- 2. Build n single vdevs individually to compare one vdev against the next (identify faulty disks) (vdev_layout_individual)
- 3. Build staggered vdevs from minimum to maximum amount (vdev_layout_staggered)
- my $uservar_vdev_layout_full=1;
- my $uservar_vdev_layout_individual=0;
- my $uservar_vdev_layout_staggered=0;

## Cache & Slog options
```
#if we allow 2 l2arc and 2 slog devices these are the possible combinations that these can have
        #l2arc	#slog	type_l2arc	type_slog
	  0	  0	  none		  none
	  1	  0	  single	  none
	  2	  0	  mirror	  none
	  2	  2	  stripe	  none
	  0	  1	  none		  single
	  0	  2	  none		  mirror
	  0	  2	  none		  stripe
	  1	  1	  single	  single
	  1	  2	  single	  mirror
	  1	  2	  single	  stripe
	  2	  1	  mirror	  single
	  2	  2	  mirror	  mirror
	  2	  2	  mirror	  stripe
	  2	  1	  stripe	  single
	  2	  2	  stripe	  mirror
	  2	  2	  stripe	  stripe
```
- #This will create n pools for l2arc times m pools for slog times all the different dataset and test options - use with care
- #none=No cache/log/device
- #sf = single slog/cache, uses the first given device if it exists (slog1/l2arc1)
- #ss = single slog/cache, uses the second given device if it exists (slog2/l2arc2)
- #str = two slog/cache, uses both in str config
- #mirror = two slog/cache, uses both in mirror config
- #my @user_l2arcoptions= ('none','sf','ss','str','mirror');  #all options
- #my @user_slogoptions= ('none','sf','ss','str','mirror');  # all options
- my @user_l2arcoptions= ('no');
- my @user_slogoptions= ('no');

- #These are the currently implemented options
- my $usel2arc=0;# set this to 1 and populate the l2arc dev(s) if you want to use a cache drive
- my $uservar_useslog=1;# set this to 1 and populate the log dev if you want to use a slog
- my $useslogmirror=0;# set this to 1 and populate the mirror log dev if you want to use a slog mirror
- my $test_cache_separately=0;

## DATASET creation options 
- #my @zfs_recordsizes = ("16k","32k","64k","128k","512k","1M"); default value
- #my @zfs_sync_options = ("always","disabled"); default value
- #my @zfs_compression_options = ("off"); default value - but could also be "lz4", "gzip-7" ...
- #my @zfs_metadata_options= ("all","most");
- #my @zfs_recordsizes = ("4k","64k","128k","1M");

- my @zfs_recordsizes = ("64k","128k","1M");
- my @zfs_sync_options = ("disabled");
- my @zfs_compression_options = ("lz4");
- my @zfs_metadata_options= ("all");


## TEST: Diskinfo options 
- #run diskinfo test on all given disks first to compare basic performance parameters abd get details
- my $diskinfo_do=0;
- my $diskinfo_command="diskinfo -citvwS";

## TEST: FIO

- my $fio_do=1; #set to 1 if you want the fio tests to run - not implemented yet
- my $fio_run_automated_loop=1; #this will choose option 1 described below if set to 1 - loop over all possible test combinations, else it will use userdefined tests (option 2)
- my $fio_runs_per_test=1; #if we want to run multiple runs per actual test to get the average of 3 or 5. Set number of tests here
- my $fio_file_size="10G"; 
- my $fio_time_based="1"; #set to 1 if you want only runtime based runs, else runs will be based on combination of size and time (given size is used until time is up)
- my $fio_runtime = 60; #set runtime to either limit duration of a test or (together with file size=0) to run timebased
```
 #read       Sequential reads.
    #write        Sequential writes.
    #trim        Sequential trims (Linux block devices and SCSI character devices only).
    #randread        Random reads.
    #randwrite        Random writes.
    #randtrim        Random trims (Linux block devices and SCSI character devices only).
    #rw,readwrite        Sequential mixed reads and writes.
    #randrw        Random mixed reads and writes.
    #trimwrite        Sequential trim+write sequences. Blocks will be trimmed first, then the same blocks will be written to.
```

### Option 1  - loop over RW/IOD, #JOBS and all other options
- #my @fio_testtype = ('read','write', 'randread', 'randwrite');
- #my @fio_testtype = ('write');
- #my @fio_testtype = ('read','write', 'randread', 'randwrite', 'readwrite','randrw');
- my @fio_testtype = ('write',  'randwrite');
- #my @fio_testtype = ('read','write','randread','randwrite');
- #my @fio_testtype = ('write','randwrite');
- #my @fio_test_rw_pcts = (20,30,50,70); #we specify read percentage (rwmixread)
- my @fio_test_rw_pcts = (0,30,100); #we specify read percentage (rwmixread)
- #my @fio_test_rw_pcts = (0); #we specify read percentage (rwmixread)
- #my @fio_bs = ("4k","8k","32k","64k","128k","512K","1M","4M","8M");
- my @fio_bs = ("64K","128K","1M");
- #my @fio_bs = ("4k");
- #my @fio_iodepth = (1,2,4,8,16,32,64,128,256,512,1024);
- my @fio_iodepth = (1,16,32,64);
- #my @fio_iodepth = (16);
- #my @fio_numjobs = (1,2,4,8,16,32);
- my @fio_numjobs = (1,4,8,16);
- #my @fio_numjobs = (16);

### Option 2 -  loop over predefined test groups
- #my @fio_userdefined_tests = (
- #"--bs=4K --rw=randwrite --iodepth=1 --numjobs=2",
- #"--bs=64K --rw=randwrite --iodepth=1 --numjobs=2",
- #"--bs=64K --rw=rw --iodepth=1 --numjobs=2",
- #"--bs=1M --rw=rw --iodepth=1 --numjobs=2"
- #);
- my @fio_userdefined_tests = (
- "--bs=64K --rw=randwrite --iodepth=1 --numjobs=2",
- "--bs=1M --rw=rw --iodepth=1 --numjobs=2"
- );
- my $fio_ioengine='posixaio';
- my $fio_sleeptime=30; #add a sleeptime between two tests (in seconds)
- my $jsonppbinary="json_pp"; # default for FreeBSD/FreeNas - for Linux thats jsonpp


## TEST: DD
- my $dd_do=0; #set to 1 if you want the dd tests to run
- my $dd_concurrent_jobs_do=1; #set to 1 if you want to run the dd with multiple parallel processes
- my $dd_runs_per_test=1; #if we want to run multiple runs per actual test to get the average of 3 or 5. Set number of tests here
- #my $dd_file_size="100G"; # for fast disks/multiple vdevs/instances || note this size will be written per zfs option per dataset, so at least 2x per given recordsize (sync/async)
- my $dd_file_size="1G";
- #my @dd_blocksizes = ("4k","8k","64k","128k","512k","1M","4M"); default value
- my @dd_blocksizes = ("64k","1M");
- #my @dd_num_jobs = (1,2,4,8,16,32); #how many processes to spawn (note each will do the nth part of total size) - default value
- my @dd_num_jobs = (1);
- my $dd_sleeptime=1; #add a sleeptime between two tests (in seconds)

## Database options
	
- my $useDB="pgsql"; # alter this to use another DB type (used for generating created db & add data to db scripts) - you can add new databases by adding appropriate datatypes 
- my $_dbname="pool_test"; # alter this to use another databse or schema. this is currently called with "use $_dbname" in MySQL style
- #Please note that VARCHAR, INT and Float are being used in the script. If you have another Datatype, this table can be used to convert from the script internal name to the DB specific name, eg if FLOAT is called Float64 in SQLSERVER then add 
- #a line like this my %DBDataTypes{"SQLSERVER"}{"FLOAT"}="FLOAT64";  (and set useDB to SQLSERVER). Make sure to define all types per database even if they are identical
- my %DBDataTypes;
- my %dbout; #for output
- $DBDataTypes{"MySQL"}{"STRING"}="VARCHAR";
- $DBDataTypes{"MySQL"}{"INT"}="INT";
- $DBDataTypes{"MySQL"}{"BIGINT"}="BIGINT";
- $DBDataTypes{"MySQL"}{"FLOAT"}="FLOAT";
- $DBDataTypes{"sqlite"}{"STRING"}="VARCHAR"; #treated as TEXT
- $DBDataTypes{"sqlite"}{"INT"}="INTEGER";
- $DBDataTypes{"sqlite"}{"BIGINT"}="INTEGER";
- $DBDataTypes{"sqlite"}{"FLOAT"}="REAL";
- $DBDataTypes{"pgsql"}{"STRING"}="VARCHAR"; 
- $DBDataTypes{"pgsql"}{"SMALLINT"}="SMALLINT";
- $DBDataTypes{"pgsql"}{"INT"}="INTEGER";
- $DBDataTypes{"pgsql"}{"BIGINT"}="BIGINT";
- $DBDataTypes{"pgsql"}{"FLOAT"}="FLOAT";

- #valid sqllite create and insert statement
- #note primary key needs to be moved to the end
