#!/usr/local/bin/perl -w
###################################################################################
# pool_test.pl, 2019, 2022, 2023
# Release 0.8.2
#
# This script is inteded to autmatically create ZFS pools on a number of provided disks. Depending on the amount of disks (and configuration) different pool types will be built.
# For each pool a number of datasets is created with different settings on which tests will be run.
#
# Known Issues
#
# <pool not found> error while creating pool - drive needs to be wiped, but cli wipe did not work #### gpart create -s gpt /dev/da1
# zfs and smartctl don't agree on what a nvme drive should be called. zfs only does not accept /dev/nvmeX and smart does not like /dev/nvdX. So we expect /dev/nvdX and convert that for smart calls
# 
#
###################################################################################
use strict;
use warnings qw( all );
use POSIX 'WNOHANG';
use Data::Dumper;
use Sys::Hostname;
use Cwd;
use experimental 'smartmatch'; #for use of ~~

###################################################################################
#
#Investigate this
#
#  pool: p_sin_str02_v04_o00_cno_sno
# state: ONLINE
#  scan: none requested
#config:
#
#        NAME                                          STATE     READ WRITE CKSUM
#        p_sin_str02_v04_o00_cno_sno                   ONLINE       0     0     0
#          gptid/c69a9a24-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c7115f20-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c746aea0-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c77dc929-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c7b574d3-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c81b46d5-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#
#errors: No known data errors
#root@freenas[~]#  zpool status
#  pool: freenas-boot
# state: ONLINE
#  scan: none requested
#config:
#
#        NAME        STATE     READ WRITE CKSUM
#        freenas-boot  ONLINE       0     0     0
#          ada0p2    ONLINE       0     0     0
#
#errors: No known data errors
#
#  pool: p_sin_str02_v05_o00_cno_sno
# state: ONLINE
#  scan: none requested
#config:
#
#        NAME                                          STATE     READ WRITE CKSUM
#        p_sin_str02_v05_o00_cno_sno                   ONLINE       0     0     0
#          gptid/c69a9a24-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c7115f20-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c746aea0-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c77dc929-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c7b574d3-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c81b46d5-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c8829ffe-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c8ec7bcc-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c9538e61-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c9aee3cb-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#
#errors: No known data errors
#root@freenas[~]#  zpool status
#  pool: freenas-boot
# state: ONLINE
#  scan: none requested
#config:
#
#        NAME        STATE     READ WRITE CKSUM
#        freenas-boot  ONLINE       0     0     0
#          ada0p2    ONLINE       0     0     0
#
#errors: No known data errors
#
#  pool: p_sin_str04_v03_o00_cno_sno
# state: ONLINE
#  scan: none requested
#config:
#
#        NAME                                          STATE     READ WRITE CKSUM
#        p_sin_str04_v03_o00_cno_sno                   ONLINE       0     0     0
#          gptid/c69a9a24-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c7115f20-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c746aea0-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c77dc929-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c7b574d3-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c81b46d5-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c8829ffe-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c8ec7bcc-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c9538e61-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/c9aee3cb-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/ca164fb0-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#          gptid/ca71de04-0fbc-11ea-8848-ac1f6b412042  ONLINE       0     0     0
#

####
#investigate too
#50/112 (dataset 1/2, pool 9/14): Running fio Test 2 of 4 on
#
#
#45/56 (dataset 1/1, pool 8/14): Running fio Test 1 of 4 on pool/dataset p_sin_str05_v01_o00_cno_ssf/ds_64k_sync-always_compr-off-all
#Iteration 1 / 1
#RUN: 1 -> child 36861 still running
#The child processes for fio have finished executing.
#Test 45 done
#46/56 (dataset 1/1, pool 8/14): Running fio Test 2 of 4 on pool/dataset p_sin_str05_v01_o00_cno_ssf/ds_64k_sync-always_compr-off-all
#Iteration 1 / 1
#RUN: 1 -> child 37677 still running
#RUN: 1 -> child 37677 still running
#The child processes for fio have finished executing.
#Test 46 done
#47/56 (dataset 1/1, pool 8/14): Running fio Test 3 of 4 on pool/dataset p_sin_str05_v01_o00_cno_ssf/ds_64k_sync-always_compr-off-all
#Iteration 1 / 1
#RUN: 1 -> child 38519 still running
#RUN: 1 -> child 38519 still running
#The child processes for fio have finished executing.
#Test 47 done
#--------------------->48/56<-------------------------- (dataset 1/1, pool 8/14): Running fio Test 4 of 4 on pool/dataset p_sin_str05_v01_o00_cno_ssf/ds_64k_sync-always_compr-off-all
#Iteration 1 / 1
#RUN: 1 -> child 39418 still running
#The child processes for fio have finished executing.
#Test 48 done
#
#49/112 (dataset 1/2, pool 9/14): Running fio Test 1 of 4 on pool/dataset p_sin_str06_v01_o00_cno_sno/ds_64k_sync-always_compr-off-all
#Iteration 1 / 1
#RUN: 1 -> child 40142 still running
#The child processes for fio have finished executing.
#Test 49 done
#50/112 (dataset 1/2, pool 9/14): Running fio Test 2 of 4 on pool/dataset p_sin_str06_v01_o00_cno_sno/ds_64k_sync-always_compr-off-all
#Iteration 1 / 1
#RUN: 1 -> child 40968 still running
#The child processes for fio have finished executing.
#Test 50 done
#51/112 (dataset 1/2, pool 9/14): Running fio Test 3 of 4 on pool/dataset p_sin_str06_v01_o00_cno_sno/ds_64k_sync-always_compr-off-all
#Iteration 1 / 1
#RUN: 1 -> child 41800 still running
#RUN: 1 -> child 41800 still running
#The child processes for fio have finished executing.
#Test 51 done
#  - -------------->52/112<------------------------------------ (dataset 1/2, pool 9/14): Running fio Test 4 of 4 on pool/dataset p_sin_str06_v01_o00_cno_sno/ds_64k_sync-always_compr-off-all
#Iteration 1 / 1
#RUN: 1 -> child 42653 still running
#RUN: 1 -> child 42653 still running
#The child processes for fio have finished executing.
#Test 52 done
#53/112 (dataset 2/2, pool 9/14): Running fio Test 1 of 4 on pool/dataset p_sin_str06_v01_o00_cno_sno/ds_64k_sync-disabled_compr-off-all
#Iteration 1 / 1
#RUN: 1 -> child 43485 still running
#The child processes for fio have finished executing.
#Test 53 done
#54/112 (dataset 2/2, pool 9/14): Running fio Test 2 of 4 on pool/dataset p_sin_str06_v01_o00_cno_sno/ds_64k_sync-disabled_compr-off-all
#Iteration 1 / 1

#----> done after 84 tests




#2do
# implement test only option without creating datasets, just take a given pool and run all tests (what about zfs recordsize -> possible since we handle that with datasets?)
#done Implement runtime change of loglevel

#add disk info to misc info column, get all disks, deduplicate and add it (or to disk column)

#print used data disks (and potentially slog/l2arc)
# add disk vs disk comparison if two or more data disk types are detected
#reowrk full, staggerd approach since its not concise

#add logging of fio & dd commands to separate file for recreation (pool agnostic for reutilization)
#add logging of zpool fio & dd commands to separate file for recreation (pool specific for manual reporuction)

#add used disks /slog/cache to report (type, not all)
#add quick report (meta + read/write_iops_avg + read/write_bytes  

#implement disk existence check on non FreeBSD platform

### implement SKIPLIST to restart tests at a given point
#output on stop request
#load on restart request
#phase two - put all relevant settings to a file and read that in addition to skiplist above - i.e. config file - extend disklist file ? 

#done not tested add slog1/2, arc1/2 to output


# consider - is sync disabled the same as running without slog? could we eliminate these tests since they yield (near) identical results?


#move all user input to a config file
# done, not tested -  add a watch file to stop gracefully between iterations if it just takes too long - that way done work is not lost
# done, not tested -  and/or output results while script is still running
#
#
#
# New list, not merged with below yet
#
# initial Disk selection process (increasing order of priority: script variables, disklist, cli parameters or interactive selection)
# - via CLI parameters (--datadisks, --slog1, -- l2arc --bs...)
# - via CLI interactive selection
# - via disklist file
# - via Parameters in the script
#
#

# Report, add colums to reportkey_hash with key column nr, then int_id, ext_text, is_number/needs_conversion and potentially hash its used in
#
#

#zfs Settings
#implement redundant_metadata=all | most - done
#implement volblocksize=blocksize --- # only on iscsi /zvols?)

#enable testing different ashift settings (vfs.zfs.min_auto_ashift-> default 12), ggf zpool add -o ashift=12 tank mirror sdc sdd
# whats the impact of compression on speed ?https://utcc.utoronto.ca/~cks/space/blog/solaris/ZFSRecordsizeAndCompression?showcomments#comments

#sysctl -a | grep vdev    - https://www.delphix.com/blog/delphix-engineering/tuning-openzfs-write-throttle

# turn off cache entirely - zfs set primarycache=metadata $vdev
#or rather not - https://forums.freebsd.org/threads/zfs-primarycache-all-versus-metadata.45555/



#add CPU load and iostat averaged over test  to data and report
#add dates to log and output
#Rename variables to make use more clear
#1. POOL_VAR = pool specific variables
#2. DISK_VAR = Disk specific variables
#3. TEST_VAR = Test specific variables
#4.  DD_OUT = DD Output
#5.  FIO_Out = FIO Output

# is slog striping already supported?
#will partitions work?
#define scenarios (i.e. predefined values for certain use cases)
# can this run on Napp-It? consider multiplatform capability

#-----------------------------------------
#if zpool add fails, wipe disks via (old) gui
#http://zfsguru.com/forum/zfsgurusupport/494?
#-----------------------------------------


############################
#opt future functionality
############################

#implement pause functionality to allow manual interaction with created pool (eg remote mounting and tests)
#optionally implement automatic sharing via nfs/smb/iscsi


#disk info i.e. disk1 = type, name, size, serial, smart status, temperature before & after test
#allow disklist file to specify disk layout via sections
# allow disklist file to contain wildcards / regexp (*, [1-n])

#allow mirror of RaidZ groups
#normalise input disks

##
# compare SLOG Performance - SLOG1 vs SLOG2 - similar to $test_cache_separately
#device auto detection, +menu for selection
#capture test duration

#multiple runs per test w/ averaging - done, not tested
#fio


#implement individual device check
#l2arc device support - done not tested
#optionally larger raidz vdevs (not only 4+x per vdev) - should work, not tested
#add dryrun option to generate commands only (eg for cleanup if processing fails) - prevent DIE on various error occasions from happenning in that situation
#test all vdevs of a pool setup individually - done, not tested
# Slog comparison mode - run all tests with slog a, then b


#invalid vdev specification: raidz1 requires at least 2 devices
#invalid vdev specification: raidz2 requires at least 3 devices
#invalid vdev specification: raidz3 requires at least 4 devices



####
#Very Big one:
#remote test capability (how to communicate - sockets/touchfiles?)
#integrate remote testing? client/server based - need to create pool, mount, run remote load, rinse & repeat
# this needs to run on variuous (unknown) client OSs, needs local mount (nfs, smb, iscsi) capability, also config of serving out local content (ie locally config nfs/smb/iscsi share)
#####braindump

#reporting data potentially includes
#test number in current run
#actual result - need to get & convert
#pool config (type vdev, vdevs count, disk per vdev) --- we set that, so just log it
#pool config (potentially disk info/size) - need to get
#data set options (recordsize, sync, compression) --- we set that, so just log it
#arc info (min/max/meta)   --- we set that, so just log it
#test info (total size, blocksize, blockcount, #instances) --- we set that, so just log it
#cpu load? - need to get
#top -n |grep dd
#option do this per worker pid - add pid to filename and then gather files per pid to calculate ratios


#slog type (none, single,mirror) --- we set that, so just log it
#slog [opt: type  &size]  - need to get
#zpool iostat? - need to get
#system info (cpu: freq, count, type, mem total) - need to get

#############################


#############################################
# configure script behaviour here
#############################################
#############################
# Pool configuration
#############################
# Currently supported device to pool layout combinations
#   type		single	mirror-2	mirror-3	stripe
#		single		o				x					x					o
#		z1				x				o					o					o
#		z2				x				o					o					o
#		z3				x				o					o					o


# Currently supported device to pool layout combinations EXTENDED
#   type		single	mirror-n	stripe-n
#		single		x				x					x
#		z1				x				-					x
#		z2				x				-					x
#		z3				x				-					x

#
#Pool layout configuration - default enables all possible pool configurations, including unsafe ones (eg single vdev)
#my @uservar_vdev_type=('single','z1','z2','z3');
#my @Uservar_vdev_redundancy=('single','stripe','mirror');
#extend for wider mirrors
#my @uservar_vdev_mirrortypes=(2,3);
#how many devices will be in a stripe at maximum stripe width. 0 = all available
#note this means a lot of pools when used in combination with layout=individual below
#
#
###################################################################################


###############################################################################################################################
###############################################################################################################################
###############################################################################################################################
# USER configurable parts 
# most users will want to change below this block
###############################################################################################################################
###############################################################################################################################
###############################################################################################################################

my $userpool_do=0; #set to 1 if you want to use a self created pool to be used for tests (with creating datasets), no automated pool creation. Needs 'userpool=' entry in pool_test.config
#not implemented yet:
my $testsonly_do=0; #set to 1 if you want only to run fio or dd tests on a given device or file 

######################
#DISKS TO USE IN TESTS (only if config file is not present) 
######################
#these values will only be used if no alternative way of passing disks has been selected (i.e. no config file pool_test.config is present and has data)
#my $uservar_slogdev ="gptid/33b5d616-692d-11e9-9421-a4bf01059e9a";
my @uservar_datadisks=('da0','da1','da2','da3');
my $uservar_slogdev ="/dev/pmem0";
my $uservar_slogdev2 ="slog2";
my $uservar_l2arcdev ="l2arc1";
my $uservar_l2arcdev2 ="l2arc2";
######################
# END DISKS TO USE IN TESTS 
######################

######################
#LOG AND SCREEN output 
######################
#log verbosity - 4 is very very verbose
my $verbose=4;  #level 1-4 (4=debug)

#logs are written to a more persistent location (user specified or in a subdir of the current position) - else they are created on the tested pool
my $user_make_logs_persistent=1;
my $user_logdir=".";
######################
# END LOG AND SCREEN output 
######################


############################
#Program stop, info & adhoc report options
############################
#create this file (via touch pool_test.pl.stop) to stop processing asap (with creating results up to the time of stop, touchfile will be deleted)
my $stopfile="$0.stop";

#set to >0 to create the report more often, else you get nothing until the script exits (and nothing if it does not exit properly)
# 3 will create an output file after each fio/dd test - note this adds significant overhead especially on short tests as this will run after each single test and will dump out all results each time
# 2 will run the report after each dataset
# 1 will run the report after each pool
my $_do_regular_output=2;

#create this file (via touch pool_test.pl.info) to get runtime infos printed once (touchfile will be deleted afterwards)
my $infofile="$0.info";

#create this file (via touch pool_test.pl.report) to get a report printed once (touchfile will be deleted afterwards)
my $reporttouchfile="$0.report";

#create this file (via touch pool_test.pl.loglevelX) to get change the current loglevel (touchfile will be deleted afterwards)
my $loglevel1touchfile="$0.loglevel1";
my $loglevel2touchfile="$0.loglevel2";
my $loglevel3touchfile="$0.loglevel3";
my $loglevel4touchfile="$0.loglevel4";
############################
# END Program stop & info options
############################

############################
# Other program options
############################
my $dryrun=0; # perform a dryrun only (=log all commands but don't execute them) - not really working all to well since some commands work on basis of other commands 
# todo my $log_testcommands=1; # save all commands that are being run for tests in a separate file without actual pool name so they can be rerun somewhere else.

#my $use_sep='.'; #use , as fraction separator instead of .
my $use_sep=','; #use , as fraction separator instead of .

my $user_runzpooliostat=0; #run iostat while running commands - only gathering data for now
my $user_runpsaux=0; #run psaux while running benchmark commands to get cpu load - only gathering data for now
my $user_rungstat=0; #run gstat while running benchmark commands to get individual drive load only gathering data for now
my $user_gettemps=0; #get disk temps while running benchmarks
my $user_gettemps_interval=15; #get disk temps every 15sec
############################
# END Other program options
############################


############################
# Limit ARC
############################
my $arc_limit_do=0; #set to 1 if you want the arc size to be limited
my $arc_limit="512M"; #this limits arc_min_size, arc_max_size and arc_meta_limit to the given size
############################
# END Limit ARC
############################




######################
#Pool creation options 
######################
#trim on init (setting vfs.zfs.vdev.trim_on_init to 0) - dont use for real life tests unless you know the disk is clean - takes a while per disk
#used for development
my $skip_trim_on_create=0;

#****************************************
#BEWARE - this forces pool creation and can lead to data loss if the wrong disks are used !!!!!
# edit: actually only if a pool is not actually present (ie unimported pool on used disks)
#****************************************
my $force_pool_creation=1;

#Mirror of Raid Z vdevs will not work, so we will skip these
#my @uservar_vdev_type=('sin','z1','z2','z3');
#my @uservar_vdev_type=('sin','z2');
my @uservar_vdev_type=('z1');
#note you need 'no' and 'mir' if you want to test mirrors and zX in the same run
#my @uservar_vdev_redundancy=('no','str','mir');
#my @uservar_vdev_redundancy=('str');
#my @uservar_vdev_redundancy=('no','mir');
my @uservar_vdev_redundancy=('no');
#extend for wider mirrors #2-x
#my @uservar_vdev_mirrortypes=(2,3);
my @uservar_vdev_mirrortypes=(2);
#how many devices will be in a stripe at maximum stripe width. 0 = all available
#note this means a lot of pools when used in combination with layout=individual below
my $uservar_max_stripewidth=0;

#define amount of disks per pooltype. O/C m2/m3 are not two pool types but only disk increase but it got its own type nevertheless.
#Raid Z's are based on a 4+x [1,2,3] layout, not absolute minimums - larger values (y+x [y=4,5,6,7..., x=1,2,3]) can be specified
my $_diskcount_z1=5; #minimum 2
#my $_diskcount_z2=6; #minimum 3
my $_diskcount_z2=10; #minimum 3
my $_diskcount_z3=12; #minimum 4


#****************************************
# Pool build scenarios
#****************************************
#provide different build pool options, valid combinations are 1+2, 2+3, 1 only, 2 only, 3 only
#set appropriate option to non zero to activate
#1. Build one big pool out of all possible vdevs (vdev_layout_full)
#2. Build n single vdevs individually to compare one vdev against the next (identify faulty disks) (vdev_layout_individual)
#3. Build staggered vdevs from minimum to maximum amount (vdev_layout_staggered)
my $uservar_vdev_layout_full=1;
my $uservar_vdev_layout_individual=0;
my $uservar_vdev_layout_staggered=0;

#****************************************
# Cache & Slog options
#****************************************

#if we allow 2 l2arc and 2 slog devices these are the possible combinations that these can have
#	|#l2arc	#slog	type_l2arc	type_slog
#	|0			0			none				none
#	|1			0			single			none
#	|2			0			mirror			none
#	|2			2			stripe			none
#	|0			1			none				single
#	|0			2			none				mirror
#	|0			2			none				stripe
#	|1			1			single			single
#	|1			2			single			mirror
#	|1			2			single			stripe
#	|2			1			mirror			single
#	|2			2			mirror			mirror
#	|2			2			mirror			stripe
#	|2			1			stripe			single
#	|2			2			stripe			mirror
#	|2			2			stripe			stripe
#
#This will create n pools for l2arc times m pools for slog times all the different dataset and test options - use with care
# none=No cache/log/device
# sf = single slog/cache, uses the first given device if it exists (slog1/l2arc1)
# ss = single slog/cache, uses the second given device if it exists (slog2/l2arc2)
# str = two slog/cache, uses both in str config
# mirror = two slog/cache, uses both in mirror config
#my @user_l2arcoptions= ('none','sf','ss','str','mirror');  #all options
#my @user_slogoptions= ('none','sf','ss','str','mirror');  # all options

#my @user_l2arcoptions= ('no','sf','ss','str','mir');
my @user_l2arcoptions= ('no');
#my @user_slogoptions= ('no','sf','ss','str','mir');
#my @user_slogoptions= ('no','sf');
my @user_slogoptions= ('no');


# These are the currently implemented options
my $usel2arc=0;# set this to 1 and populate the l2arc dev(s) if you want to use a cache drive
my $uservar_useslog=1;# set this to 1 and populate the log dev if you want to use a slog
my $useslogmirror=0;# set this to 1 and populate the mirror log dev if you want to use a slog mirror
my $test_cache_separately=0;

######################
# END Pool creation options 
######################


######################
# DATASET creation options 
######################
#my @zfs_recordsizes = ("16k","32k","64k","128k","512k","1M"); default value
#my @zfs_sync_options = ("always","disabled"); default value
#my @zfs_compression_options = ("off"); default value - but could also be "lz4", "gzip-7" ...
#my @zfs_metadata_options= ("all","most");
#my @zfs_recordsizes = ("4k","64k","128k","1M");
my @zfs_recordsizes = ("64k","128k","1M");
#my @zfs_sync_options = ("disabled","always"); 
my @zfs_sync_options = ("always"); 
#my @zfs_sync_options = ("disabled");
#my @zfs_compression_options = ("off");
my @zfs_compression_options = ("lz4");
#my @zfs_metadata_options= ("all","most");
my @zfs_metadata_options= ("all");
######################
# END DATASET creation options 
######################


######################
# TEST: Diskinfo options 
######################
#run diskinfo test on all given disks first to compare basic performance parameters abd get details
my $diskinfo_do=0;
my $diskinfo_command="diskinfo -citvwS";
######################
# END TEST: Diskinfo options 
######################

######################
# TEST: FIO
######################
my $fio_do=1; #set to 1 if you want the fio tests to run - not implemented yet
my $fio_run_automated_loop=1; #this will choose option 1 described below if set to 1 - loop over all possible test combinations, else it will use userdefined tests (option 2)
my $fio_runs_per_test=1; #if we want to run multiple runs per actual test to get the average of 3 or 5. Set number of tests here
my $fio_file_size="10G"; 
my $fio_time_based="1"; #set to 1 if you want only runtime based runs, else runs will be based on combination of size and time (given size is used until time is up)
my $fio_runtime = 60; #set runtime to either limit duration of a test or (together with file size=0) to run timebased

 #read       Sequential reads.
    #write        Sequential writes.
    #trim        Sequential trims (Linux block devices and SCSI character devices only).
    #randread        Random reads.
    #randwrite        Random writes.
    #randtrim        Random trims (Linux block devices and SCSI character devices only).
    #rw,readwrite        Sequential mixed reads and writes.
    #randrw        Random mixed reads and writes.
    #trimwrite        Sequential trim+write sequences. Blocks will be trimmed first, then the same blocks will be written to.


	#Option 1  - loop over RW/IOD, #JOBS and all other options
#my @fio_testtype = ('read','write', 'randread', 'randwrite');
#my @fio_testtype = ('write');
#my @fio_testtype = ('read','write', 'randread', 'randwrite', 'readwrite','randrw');
my @fio_testtype = ('write',  'randwrite');
#my @fio_testtype = ('read','write','randread','randwrite');
#my @fio_testtype = ('write','randwrite');
#my @fio_test_rw_pcts = (20,30,50,70); #we specify read percentage (rwmixread)
my @fio_test_rw_pcts = (0,30,100); #we specify read percentage (rwmixread)
#my @fio_test_rw_pcts = (0); #we specify read percentage (rwmixread)
#my @fio_bs = ("4k","8k","32k","64k","128k","512K","1M","4M","8M");
my @fio_bs = ("64K","128K","1M");
#my @fio_bs = ("4k");
#my @fio_iodepth = (1,2,4,8,16,32,64,128,256,512,1024);
my @fio_iodepth = (1,16,32,64);
#my @fio_iodepth = (16);
#my @fio_numjobs = (1,2,4,8,16,32);
my @fio_numjobs = (1,4,8,16);
#my @fio_numjobs = (16);

	#Option 2 -  loop over predefined test groups
#my @fio_userdefined_tests = (
#"--bs=4K --rw=randwrite --iodepth=1 --numjobs=2",
#"--bs=64K --rw=randwrite --iodepth=1 --numjobs=2",
#"--bs=64K --rw=rw --iodepth=1 --numjobs=2",
#"--bs=1M --rw=rw --iodepth=1 --numjobs=2"
#);
my @fio_userdefined_tests = (
"--bs=64K --rw=randwrite --iodepth=1 --numjobs=2",
"--bs=1M --rw=rw --iodepth=1 --numjobs=2"
);


my $fio_ioengine='posixaio';

my $fio_sleeptime=30; #add a sleeptime between two tests (in seconds)
my $jsonppbinary="json_pp"; # default for FreeBSD/FreeNas - for Linux thats jsonpp

######################
# END TEST: FIO
######################


######################
# TEST: DD
######################
my $dd_do=0; #set to 1 if you want the dd tests to run
my $dd_concurrent_jobs_do=1; #set to 1 if you want to run the dd with multiple parallel processes
my $dd_runs_per_test=1; #if we want to run multiple runs per actual test to get the average of 3 or 5. Set number of tests here
#my $dd_file_size="100G"; # for fast disks/multiple vdevs/instances || note this size will be written per zfs option per dataset, so at least 2x per given recordsize (sync/async)
my $dd_file_size="1G";
#my @dd_blocksizes = ("4k","8k","64k","128k","512k","1M","4M"); default value
my @dd_blocksizes = ("64k","1M");
#my @dd_num_jobs = (1,2,4,8,16,32); #how many processes to spawn (note each will do the nth part of total size) - default value
my @dd_num_jobs = (1);
my $dd_sleeptime=1; #add a sleeptime between two tests (in seconds)
######################
# END TEST: DD
######################

my $useDB="pgsql"; # alter this to use another DB type (used for generating created db & add data to db scripts) - you cann new databases by adding appropriate datatypes 
my $_dbname="pool_test"; # alter this to use another databse or schema. this is currently calles with "use $_dbname" in MySQL style
#Please note that VARCHAR, INT and Float are being used in the script. If you have another Datatype, this table can be used to convert from the script internal name to the DB specific name, eg if FLOAT is called Float64 in SQLSERVER then add 
#a line like this my %DBDataTypes{"SQLSERVER"}{"FLOAT"}="FLOAT64";  (and set useDB to SQLSERVER). Make sure to define all types per database even if they are identical
my %DBDataTypes;
my %dbout; #for output
$DBDataTypes{"MySQL"}{"STRING"}="VARCHAR";
$DBDataTypes{"MySQL"}{"INT"}="INT";
$DBDataTypes{"MySQL"}{"BIGINT"}="BIGINT";
$DBDataTypes{"MySQL"}{"FLOAT"}="FLOAT";
$DBDataTypes{"sqlite"}{"STRING"}="VARCHAR"; #treated as TEXT
$DBDataTypes{"sqlite"}{"INT"}="INTEGER";
$DBDataTypes{"sqlite"}{"BIGINT"}="INTEGER";
$DBDataTypes{"sqlite"}{"FLOAT"}="REAL";
$DBDataTypes{"pgsql"}{"STRING"}="VARCHAR"; 
$DBDataTypes{"pgsql"}{"SMALLINT"}="SMALLINT";
$DBDataTypes{"pgsql"}{"INT"}="INTEGER";
$DBDataTypes{"pgsql"}{"BIGINT"}="BIGINT";
$DBDataTypes{"pgsql"}{"FLOAT"}="FLOAT";

#valid sqllite create and insert statement
#note primary key needs to be moved to the end
#CREATE TABLE pool_test_fio ( UniqueRunID VARCHAR(32), Testid INTEGER, NrCores INTEGER, CPUType VARCHAR(32) , Freq REAL(2) , Hostname VARCHAR(32) , Nr_of_vdevs INTEGER , disks_per_vdev INTEGER , Pooltype VARCHAR(64) , Nr_of_l2arc_devs INTEGER , l2arcoption VARCHAR(64) , l2arc1 VARCHAR(64) , l2arc2 VARCHAR(64) , Nr_of_slog_devs INTEGER , slogoption VARCHAR(32) , slog1 VARCHAR(64) , slog2 VARCHAR(64) , sync VARCHAR(64) , compression VARCHAR(64) , metadata VARCHAR(64) , zfs_recordsize VARCHAR(8) , BS VARCHAR(8) , runsPtest INTEGER , testfilesize BIGINTEGER , runtime INTEGER , timebased INTEGER , ioengine VARCHAR(32) , source VARCHAR(16) , iodepth INTEGER , numjobs INTEGER , testtype VARCHAR(16) , rwmixread INTEGER , sys_cpu_min REAL(2) , sys_cpu_avg REAL(2) , sys_cpu_max REAL(2) , usr_cpu_min REAL(2) , usr_cpu_avg REAL(2) , usr_cpu_max REAL(2) , cpu_ctx_min REAL(2) , cpu_ctx_avg REAL(2) , cpu_ctx_max REAL(2) , cpu_minf_min REAL(2) , cpu_minf_avg REAL(2) , cpu_minf_max REAL(2) , cpu_majf_min REAL(2) , cpu_majf_avg REAL(2) , cpu_majf_max REAL(2) , latency_us_2_min REAL(2) , latency_us_2_avg REAL(2) , latency_us_2_max REAL(2) , latency_us_4_min REAL(2) , latency_us_4_avg REAL(2) , latency_us_4_max REAL(2) , latency_us_10_min REAL(2) , latency_us_10_avg REAL(2) , latency_us_10_max REAL(2) , latency_us_20_min REAL(2) , latency_us_20_avg REAL(2) , latency_us_20_max REAL(2) , latency_us_50_min REAL(2) , latency_us_50_avg REAL(2) , latency_us_50_max REAL(2) , latency_us_100_min REAL(2) , latency_us_100_avg REAL(2) , latency_us_100_max REAL(2) , latency_us_250_min REAL(2) , latency_us_250_avg REAL(2) , latency_us_250_max REAL(2) , latency_us_500_min REAL(2) , latency_us_500_avg REAL(2) , latency_us_500_max REAL(2) , latency_us_750_min REAL(2) , latency_us_750_avg REAL(2) , latency_us_750_max REAL(2) , latency_us_1000_min REAL(2) , latency_us_1000_avg REAL(2) , latency_us_1000_max REAL(2) , read_slat_ns_min_min REAL(2) , read_slat_ns_min_avg REAL(2) , read_slat_ns_min_max REAL(2) , read_slat_ns_mean_min REAL(2) , read_slat_ns_mean_avg REAL(2) , read_slat_ns_mean_max REAL(2) , read_slat_ns_stddev_min REAL(2) , read_slat_ns_stddev_avg REAL(2) , read_slat_ns_stddev_max REAL(2) , read_slat_ns_max_min FLOAT(2) , read_slat_ns_max_avg REAL(2) , read_slat_ns_max_max REAL(2) , read_clat_ns_min_min REAL(2) , read_clat_ns_min_avg REAL(2) , read_clat_ns_min_max REAL(2) , read_clat_ns_mean_min REAL(2) , read_clat_ns_mean_avg REAL(2) , read_clat_ns_mean_max REAL(2) , read_clat_ns_stddev_min REAL(2) , read_clat_ns_stddev_avg REAL(2) , read_clat_ns_stddev_max REAL(2) , read_clat_ns_max_min REAL(2) , read_clat_ns_max_avg REAL(2) , read_clat_ns_max_max REAL(2) , read_lat_ns_min_min REAL(2) , read_lat_ns_min_avg REAL(2) , read_lat_ns_min_max REAL(2) , read_lat_ns_mean_min REAL(2) , read_lat_ns_mean_avg REAL(2) , read_lat_ns_mean_max REAL(2) , read_lat_ns_stddev_min REAL(2) , read_lat_ns_stddev_avg REAL(2) , read_lat_ns_stddev_max REAL(2) , read_lat_ns_max_min REAL(2) , read_lat_ns_max_avg REAL(2) , read_lat_ns_max_max REAL(2) , read_iops_max_min REAL(2) , read_iops_max_avg REAL(2) , read_iops_max_max REAL(2) , read_iops_min REAL(2) , read_iops_avg REAL(2) , read_iops_max REAL(2) , read_iops_min_min REAL(2) , read_iops_min_avg REAL(2) , read_iops_min_max REAL(2) , read_iops_stddev_min REAL(2) , read_iops_stddev_avg REAL(2) , read_iops_stddev_max REAL(2) , read_iops_mean_min REAL(2) , read_iops_mean_avg REAL(2) , read_iops_mean_max REAL(2) , read_bw_max_min REAL(2) , read_bw_max_avg REAL(2) , read_bw_max_max REAL(2) , read_bw_min REAL(2) , read_bw_avg REAL(2) , read_bw_max REAL(2) , read_bw_min_min REAL(2) , read_bw_min_avg REAL(2) , read_bw_min_max REAL(2) , read_bw_stddev_min REAL(2) , read_bw_stddev_avg REAL(2) , read_bw_stddev_max REAL(2) , read_bw_mean_min REAL(2) , read_bw_mean_avg REAL(2) , read_bw_mean_max REAL(2) , read_bw_agg_min REAL(2) , read_bw_agg_avg REAL(2) , read_bw_agg_max REAL(2) , read_short_ios_min REAL(2) , read_short_ios_avg REAL(2) , read_short_ios_max REAL(2) , read_drop_ios_min REAL(2) , read_drop_ios_avg REAL(2) , read_drop_ios_max REAL(2) , read_total_ios_min REAL(2) , read_total_ios_avg REAL(2) , read_total_ios_max REAL(2) , write_slat_ns_min_min REAL(2) , write_slat_ns_min_avg REAL(2) , write_slat_ns_min_max REAL(2) , write_slat_ns_mean_min REAL(2) , write_slat_ns_mean_avg REAL(2) , write_slat_ns_mean_max REAL(2) , write_slat_ns_stddev_min FLOAT(2) , write_slat_ns_stddev_avg REAL(2) , write_slat_ns_stddev_max REAL(2) , write_slat_ns_max_min REAL(2) , write_slat_ns_max_avg REAL(2) , write_slat_ns_max_max REAL(2) , write_clat_ns_min_min REAL(2) , write_clat_ns_min_avg REAL(2) , write_clat_ns_min_max REAL(2) , write_clat_ns_mean_min REAL(2) , write_clat_ns_mean_avg REAL(2) , write_clat_ns_mean_max REAL(2) , write_clat_ns_stddev_min REAL(2) , write_clat_ns_stddev_avg REAL(2) , write_clat_ns_stddev_max REAL(2) , write_clat_ns_max_min REAL(2) , write_clat_ns_max_avg REAL(2) , write_clat_ns_max_max REAL(2) , write_lat_ns_min_min REAL(2) , write_lat_ns_min_avg REAL(2) , write_lat_ns_min_max REAL(2) , write_lat_ns_mean_min REAL(2) , write_lat_ns_mean_avg REAL(2) , write_lat_ns_mean_max REAL(2) , write_lat_ns_stddev_min REAL(2) , write_lat_ns_stddev_avg REAL(2) , write_lat_ns_stddev_max REAL(2) , write_lat_ns_max_min REAL(2) , write_lat_ns_max_avg REAL(2) , write_lat_ns_max_max REAL(2) , write_iops_max_min REAL(2) , write_iops_max_avg REAL(2) , write_iops_max_max REAL(2) , write_iops_min REAL(2) , write_iops_avg REAL(2) , write_iops_max REAL(2) , write_iops_min_min REAL(2) , write_iops_min_avg REAL(2) , write_iops_min_max REAL(2) , write_iops_stddev_min REAL(2) , write_iops_stddev_avg REAL(2) , write_iops_stddev_max REAL(2) , write_iops_mean_min REAL(2) , write_iops_mean_avg REAL(2) , write_iops_mean_max REAL(2) , write_bw_max_min REAL(2) , write_bw_max_avg REAL(2) , write_bw_max_max REAL(2) , write_bw_min REAL(2) , write_bw_avg REAL(2) , write_bw_max REAL(2) , write_bw_min_min REAL(2) , write_bw_min_avg REAL(2) , write_bw_min_max REAL(2) , write_bw_stddev_min REAL(2) , write_bw_stddev_avg REAL(2) , write_bw_stddev_max REAL(2) , write_bw_mean_min REAL(2) , write_bw_mean_avg REAL(2) , write_bw_mean_max REAL(2) , write_bw_agg_min REAL(2) , write_bw_agg_avg REAL(2) , write_bw_agg_max REAL(2) , write_short_ios_min REAL(2) , write_short_ios_avg FLOAT(2) , write_short_ios_max REAL(2) , write_drop_ios_min REAL(2) , write_drop_ios_avg REAL(2) , write_drop_ios_max REAL(2) , write_total_ios_min REAL(2) , write_total_ios_avg REAL(2) , write_total_ios_max REAL(2) , sync_lat_ns_min_min REAL(2) , sync_lat_ns_min_avg REAL(2) , sync_lat_ns_min_max REAL(2) , sync_lat_ns_mean_min REAL(2) , sync_lat_ns_mean_avg REAL(2) , sync_lat_ns_mean_max REAL(2) , sync_lat_ns_stddev_min REAL(2) , sync_lat_ns_stddev_avg REAL(2) , sync_lat_ns_stddev_max REAL(2) , sync_lat_ns_max_min REAL(2) , sync_lat_ns_max_avg FLOAT(2) , sync_lat_ns_max_max REAL(2) , sync_total_ios_min REAL(2) , sync_total_ios_avg REAL(2) , sync_total_ios_max REAL(2), PRIMARY KEY(UniqueRunID,Testid) );
#INSERT into pool_test_fio (UniqueRunID, Testid, NrCores, CPUType, Freq, Hostname, Nr_of_vdevs, disks_per_vdev, Pooltype, Nr_of_l2arc_devs, l2arcoption, l2arc1, l2arc2, Nr_of_slog_devs, slogoption, slog1, slog2, sync, compression, metadata, zfs_recordsize, BS, runsPtest, testfilesize, runtime, timebased, ioengine, source, iodepth, numjobs, testtype, rwmixread, sys_cpu_min, sys_cpu_avg, sys_cpu_max, usr_cpu_min, usr_cpu_avg, usr_cpu_max, cpu_ctx_min, cpu_ctx_avg, cpu_ctx_max, cpu_minf_min, cpu_minf_avg, cpu_minf_max, cpu_majf_min, cpu_majf_avg, cpu_majf_max, latency_us_2_min, latency_us_2_avg, latency_us_2_max, latency_us_4_min, latency_us_4_avg, latency_us_4_max, latency_us_10_min, latency_us_10_avg, latency_us_10_max, latency_us_20_min, latency_us_20_avg, latency_us_20_max, latency_us_50_min, latency_us_50_avg, latency_us_50_max, latency_us_100_min, latency_us_100_avg, latency_us_100_max, latency_us_250_min, latency_us_250_avg, latency_us_250_max, latency_us_500_min, latency_us_500_avg, latency_us_500_max, latency_us_750_min, latency_us_750_avg, latency_us_750_max, latency_us_1000_min, latency_us_1000_avg, latency_us_1000_max, read_slat_ns_min_min, read_slat_ns_min_avg, read_slat_ns_min_max, read_slat_ns_mean_min, read_slat_ns_mean_avg, read_slat_ns_mean_max, read_slat_ns_stddev_min, read_slat_ns_stddev_avg, read_slat_ns_stddev_max, read_slat_ns_max_min, read_slat_ns_max_avg, read_slat_ns_max_max, read_clat_ns_min_min, read_clat_ns_min_avg, read_clat_ns_min_max, read_clat_ns_mean_min, read_clat_ns_mean_avg, read_clat_ns_mean_max, read_clat_ns_stddev_min, read_clat_ns_stddev_avg, read_clat_ns_stddev_max, read_clat_ns_max_min, read_clat_ns_max_avg, read_clat_ns_max_max, read_lat_ns_min_min, read_lat_ns_min_avg, read_lat_ns_min_max, read_lat_ns_mean_min, read_lat_ns_mean_avg, read_lat_ns_mean_max, read_lat_ns_stddev_min, read_lat_ns_stddev_avg, read_lat_ns_stddev_max, read_lat_ns_max_min, read_lat_ns_max_avg, read_lat_ns_max_max, read_iops_max_min, read_iops_max_avg, read_iops_max_max, read_iops_min, read_iops_avg, read_iops_max, read_iops_min_min, read_iops_min_avg, read_iops_min_max, read_iops_stddev_min, read_iops_stddev_avg, read_iops_stddev_max, read_iops_mean_min, read_iops_mean_avg, read_iops_mean_max, read_bw_max_min, read_bw_max_avg, read_bw_max_max, read_bw_min, read_bw_avg, read_bw_max, read_bw_min_min, read_bw_min_avg, read_bw_min_max, read_bw_stddev_min, read_bw_stddev_avg, read_bw_stddev_max, read_bw_mean_min, read_bw_mean_avg, read_bw_mean_max, read_bw_agg_min, read_bw_agg_avg, read_bw_agg_max, read_short_ios_min, read_short_ios_avg, read_short_ios_max, read_drop_ios_min, read_drop_ios_avg, read_drop_ios_max, read_total_ios_min, read_total_ios_avg, read_total_ios_max, write_slat_ns_min_min, write_slat_ns_min_avg, write_slat_ns_min_max, write_slat_ns_mean_min, write_slat_ns_mean_avg, write_slat_ns_mean_max, write_slat_ns_stddev_min, write_slat_ns_stddev_avg, write_slat_ns_stddev_max, write_slat_ns_max_min, write_slat_ns_max_avg, write_slat_ns_max_max, write_clat_ns_min_min, write_clat_ns_min_avg, write_clat_ns_min_max, write_clat_ns_mean_min, write_clat_ns_mean_avg, write_clat_ns_mean_max, write_clat_ns_stddev_min, write_clat_ns_stddev_avg, write_clat_ns_stddev_max, write_clat_ns_max_min, write_clat_ns_max_avg, write_clat_ns_max_max, write_lat_ns_min_min, write_lat_ns_min_avg, write_lat_ns_min_max, write_lat_ns_mean_min, write_lat_ns_mean_avg, write_lat_ns_mean_max, write_lat_ns_stddev_min, write_lat_ns_stddev_avg, write_lat_ns_stddev_max, write_lat_ns_max_min, write_lat_ns_max_avg, write_lat_ns_max_max, write_iops_max_min, write_iops_max_avg, write_iops_max_max, write_iops_min, write_iops_avg, write_iops_max, write_iops_min_min, write_iops_min_avg, write_iops_min_max, write_iops_stddev_min, write_iops_stddev_avg, write_iops_stddev_max, write_iops_mean_min, write_iops_mean_avg, write_iops_mean_max, write_bw_max_min, write_bw_max_avg, write_bw_max_max, write_bw_min, write_bw_avg, write_bw_max, write_bw_min_min, write_bw_min_avg, write_bw_min_max, write_bw_stddev_min, write_bw_stddev_avg, write_bw_stddev_max, write_bw_mean_min, write_bw_mean_avg, write_bw_mean_max, write_bw_agg_min, write_bw_agg_avg, write_bw_agg_max, write_short_ios_min, write_short_ios_avg, write_short_ios_max, write_drop_ios_min, write_drop_ios_avg, write_drop_ios_max, write_total_ios_min, write_total_ios_avg, write_total_ios_max, sync_lat_ns_min_min, sync_lat_ns_min_avg, sync_lat_ns_min_max, sync_lat_ns_mean_min, sync_lat_ns_mean_avg, sync_lat_ns_mean_max, sync_lat_ns_stddev_min, sync_lat_ns_stddev_avg, sync_lat_ns_stddev_max, sync_lat_ns_max_min, sync_lat_ns_max_avg, sync_lat_ns_max_max, sync_total_ios_min, sync_total_ios_avg, sync_total_ios_max) VALUES ('20220410204200-28744', 1, '16', 'Genuine Intel(R) CPU 0000%@', 3.70, 'freenas12.ad.voelligegal.de', '02', '2', 'single disk mirror', '0', 'none', 'none', 'none', '0', 'none', 'none', 'none', 'disabled', 'lz4', 'all', '128k', '4k', 1, '10737418240', '60', 1, 'posixaio', 'auto', '16', '16', 'write', 0, 6.52, 6.52, 6.52, 3.76, 3.76, 3.76, 11027831.00, 11027831.00, 11027831.00, 16.00, 16.00, 16.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 1.10, 1.10, 1.10, 97.45, 97.45, 97.45, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 299.00, 299.00, 299.00, 874.37, 874.37, 874.37, 470.18, 470.18, 470.18, 351517.00, 351517.00, 351517.00, 77327.00, 77327.00, 77327.00, 834612.88, 834612.88, 834612.88, 67278.51, 67278.51, 67278.51, 4255661.00, 4255661.00, 4255661.00, 91259.00, 91259.00, 91259.00, 835487.25, 835487.25, 835487.25, 67284.05, 67284.05, 67284.05, 4256233.00, 4256233.00, 4256233.00, 312434.00, 312434.00, 312434.00, 305276.18, 305276.18, 305276.18, 294846.00, 294846.00, 294846.00, 256.09, 256.09, 256.09, 305622.13, 305622.13, 305622.13, 1249784.00, 1249784.00, 1249784.00, 1221104.00, 1221104.00, 1221104.00, 1179389.00, 1179389.00, 1179389.00, 1024.16, 1024.16, 1024.16, 1222508.83, 1222508.83, 1222508.83, 100.00, 100.00, 100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 18316876.00, 18316876.00, 18316876.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00);

#valid pgsql create and insert statement
#note primary key needs to be moved to the end
#CREATE TABLE pool_test_fio ( UniqueRunID VARCHAR(32), Testid SMALLINT, NrCores SMALLINT, CPUType VARCHAR(32) , Freq FLOAT(2) , Hostname VARCHAR(32) , Nr_of_vdevs SMALLINT , disks_per_vdev SMALLINT , Pooltype VARCHAR(64) , Nr_of_l2arc_devs SMALLINT , l2arcoption VARCHAR(64) , l2arc1 VARCHAR(64) , l2arc2 VARCHAR(64) , Nr_of_slog_devs SMALLINT , slogoption VARCHAR(32) , slog1 VARCHAR(64) , slog2 VARCHAR(64) , sync VARCHAR(64) , compression VARCHAR(64) , metadata VARCHAR(64) , zfs_recordsize VARCHAR(8) , BS VARCHAR(8) , runsPtest SMALLINT , testfilesize BIGINT , runtime SMALLINT , timebased SMALLINT , ioengine VARCHAR(32) , source VARCHAR(16) , iodepth SMALLINT , numjobs SMALLINT , testtype VARCHAR(16) , rwmixread SMALLINT , sys_cpu_min FLOAT(2) , sys_cpu_avg FLOAT(2) , sys_cpu_max FLOAT(2) , usr_cpu_min FLOAT(2) , usr_cpu_avg FLOAT(2) , usr_cpu_max FLOAT(2) , cpu_ctx_min FLOAT(2) , cpu_ctx_avg FLOAT(2) , cpu_ctx_max FLOAT(2) , cpu_minf_min FLOAT(2) , cpu_minf_avg FLOAT(2) , cpu_minf_max FLOAT(2) , cpu_majf_min FLOAT(2) , cpu_majf_avg FLOAT(2) , cpu_majf_max FLOAT(2) , latency_us_2_min FLOAT(2) , latency_us_2_avg FLOAT(2) , latency_us_2_max FLOAT(2) , latency_us_4_min FLOAT(2) , latency_us_4_avg FLOAT(2) , latency_us_4_max FLOAT(2) , latency_us_10_min FLOAT(2) , latency_us_10_avg FLOAT(2) , latency_us_10_max FLOAT(2) , latency_us_20_min FLOAT(2) , latency_us_20_avg FLOAT(2) , latency_us_20_max FLOAT(2) , latency_us_50_min FLOAT(2) , latency_us_50_avg FLOAT(2) , latency_us_50_max FLOAT(2) , latency_us_100_min FLOAT(2) , latency_us_100_avg FLOAT(2) , latency_us_100_max FLOAT(2) , latency_us_250_min FLOAT(2) , latency_us_250_avg FLOAT(2) , latency_us_250_max FLOAT(2) , latency_us_500_min FLOAT(2) , latency_us_500_avg FLOAT(2) , latency_us_500_max FLOAT(2) , latency_us_750_min FLOAT(2) , latency_us_750_avg FLOAT(2) , latency_us_750_max FLOAT(2) , latency_us_1000_min FLOAT(2) , latency_us_1000_avg FLOAT(2) , latency_us_1000_max FLOAT(2) , read_slat_ns_min_min FLOAT(2) , read_slat_ns_min_avg FLOAT(2) , read_slat_ns_min_max FLOAT(2) , read_slat_ns_mean_min FLOAT(2) , read_slat_ns_mean_avg FLOAT(2) , read_slat_ns_mean_max FLOAT(2) , read_slat_ns_stddev_min FLOAT(2) , read_slat_ns_stddev_avg FLOAT(2) , read_slat_ns_stddev_max FLOAT(2) , read_slat_ns_max_min FLOAT(2) , read_slat_ns_max_avg FLOAT(2) , read_slat_ns_max_max FLOAT(2) , read_clat_ns_min_min FLOAT(2) , read_clat_ns_min_avg FLOAT(2) , read_clat_ns_min_max FLOAT(2) , read_clat_ns_mean_min FLOAT(2) , read_clat_ns_mean_avg FLOAT(2) , read_clat_ns_mean_max FLOAT(2) , read_clat_ns_stddev_min FLOAT(2) , read_clat_ns_stddev_avg FLOAT(2) , read_clat_ns_stddev_max FLOAT(2) , read_clat_ns_max_min FLOAT(2) , read_clat_ns_max_avg FLOAT(2) , read_clat_ns_max_max FLOAT(2) , read_lat_ns_min_min FLOAT(2) , read_lat_ns_min_avg FLOAT(2) , read_lat_ns_min_max FLOAT(2) , read_lat_ns_mean_min FLOAT(2) , read_lat_ns_mean_avg FLOAT(2) , read_lat_ns_mean_max FLOAT(2) , read_lat_ns_stddev_min FLOAT(2) , read_lat_ns_stddev_avg FLOAT(2) , read_lat_ns_stddev_max FLOAT(2) , read_lat_ns_max_min FLOAT(2) , read_lat_ns_max_avg FLOAT(2) , read_lat_ns_max_max FLOAT(2) , read_iops_max_min FLOAT(2) , read_iops_max_avg FLOAT(2) , read_iops_max_max FLOAT(2) , read_iops_min FLOAT(2) , read_iops_avg FLOAT(2) , read_iops_max FLOAT(2) , read_iops_min_min FLOAT(2) , read_iops_min_avg FLOAT(2) , read_iops_min_max FLOAT(2) , read_iops_stddev_min FLOAT(2) , read_iops_stddev_avg FLOAT(2) , read_iops_stddev_max FLOAT(2) , read_iops_mean_min FLOAT(2) , read_iops_mean_avg FLOAT(2) , read_iops_mean_max FLOAT(2) , read_bw_max_min FLOAT(2) , read_bw_max_avg FLOAT(2) , read_bw_max_max FLOAT(2) , read_bw_min FLOAT(2) , read_bw_avg FLOAT(2) , read_bw_max FLOAT(2) , read_bw_min_min FLOAT(2) , read_bw_min_avg FLOAT(2) , read_bw_min_max FLOAT(2) , read_bw_stddev_min FLOAT(2) , read_bw_stddev_avg FLOAT(2) , read_bw_stddev_max FLOAT(2) , read_bw_mean_min FLOAT(2) , read_bw_mean_avg FLOAT(2) , read_bw_mean_max FLOAT(2) , read_bw_agg_min FLOAT(2) , read_bw_agg_avg FLOAT(2) , read_bw_agg_max FLOAT(2) , read_short_ios_min FLOAT(2) , read_short_ios_avg FLOAT(2) , read_short_ios_max FLOAT(2) , read_drop_ios_min FLOAT(2) , read_drop_ios_avg FLOAT(2) , read_drop_ios_max FLOAT(2) , read_total_ios_min FLOAT(2) , read_total_ios_avg FLOAT(2) , read_total_ios_max FLOAT(2) , write_slat_ns_min_min FLOAT(2) , write_slat_ns_min_avg FLOAT(2) , write_slat_ns_min_max FLOAT(2) , write_slat_ns_mean_min FLOAT(2) , write_slat_ns_mean_avg FLOAT(2) , write_slat_ns_mean_max FLOAT(2) , write_slat_ns_stddev_min FLOAT(2) , write_slat_ns_stddev_avg FLOAT(2) , write_slat_ns_stddev_max FLOAT(2) , write_slat_ns_max_min FLOAT(2) , write_slat_ns_max_avg FLOAT(2) , write_slat_ns_max_max FLOAT(2) , write_clat_ns_min_min FLOAT(2) , write_clat_ns_min_avg FLOAT(2) , write_clat_ns_min_max FLOAT(2) , write_clat_ns_mean_min FLOAT(2) , write_clat_ns_mean_avg FLOAT(2) , write_clat_ns_mean_max FLOAT(2) , write_clat_ns_stddev_min FLOAT(2) , write_clat_ns_stddev_avg FLOAT(2) , write_clat_ns_stddev_max FLOAT(2) , write_clat_ns_max_min FLOAT(2) , write_clat_ns_max_avg FLOAT(2) , write_clat_ns_max_max FLOAT(2) , write_lat_ns_min_min FLOAT(2) , write_lat_ns_min_avg FLOAT(2) , write_lat_ns_min_max FLOAT(2) , write_lat_ns_mean_min FLOAT(2) , write_lat_ns_mean_avg FLOAT(2) , write_lat_ns_mean_max FLOAT(2) , write_lat_ns_stddev_min FLOAT(2) , write_lat_ns_stddev_avg FLOAT(2) , write_lat_ns_stddev_max FLOAT(2) , write_lat_ns_max_min FLOAT(2) , write_lat_ns_max_avg FLOAT(2) , write_lat_ns_max_max FLOAT(2) , write_iops_max_min FLOAT(2) , write_iops_max_avg FLOAT(2) , write_iops_max_max FLOAT(2) , write_iops_min FLOAT(2) , write_iops_avg FLOAT(2) , write_iops_max FLOAT(2) , write_iops_min_min FLOAT(2) , write_iops_min_avg FLOAT(2) , write_iops_min_max FLOAT(2) , write_iops_stddev_min FLOAT(2) , write_iops_stddev_avg FLOAT(2) , write_iops_stddev_max FLOAT(2) , write_iops_mean_min FLOAT(2) , write_iops_mean_avg FLOAT(2) , write_iops_mean_max FLOAT(2) , write_bw_max_min FLOAT(2) , write_bw_max_avg FLOAT(2) , write_bw_max_max FLOAT(2) , write_bw_min FLOAT(2) , write_bw_avg FLOAT(2) , write_bw_max FLOAT(2) , write_bw_min_min FLOAT(2) , write_bw_min_avg FLOAT(2) , write_bw_min_max FLOAT(2) , write_bw_stddev_min FLOAT(2) , write_bw_stddev_avg FLOAT(2) , write_bw_stddev_max FLOAT(2) , write_bw_mean_min FLOAT(2) , write_bw_mean_avg FLOAT(2) , write_bw_mean_max FLOAT(2) , write_bw_agg_min FLOAT(2) , write_bw_agg_avg FLOAT(2) , write_bw_agg_max FLOAT(2) , write_short_ios_min FLOAT(2) , write_short_ios_avg FLOAT(2) , write_short_ios_max FLOAT(2) , write_drop_ios_min FLOAT(2) , write_drop_ios_avg FLOAT(2) , write_drop_ios_max FLOAT(2) , write_total_ios_min FLOAT(2) , write_total_ios_avg FLOAT(2) , write_total_ios_max FLOAT(2) , sync_lat_ns_min_min FLOAT(2) , sync_lat_ns_min_avg FLOAT(2) , sync_lat_ns_min_max FLOAT(2) , sync_lat_ns_mean_min FLOAT(2) , sync_lat_ns_mean_avg FLOAT(2) , sync_lat_ns_mean_max FLOAT(2) , sync_lat_ns_stddev_min FLOAT(2) , sync_lat_ns_stddev_avg FLOAT(2) , sync_lat_ns_stddev_max FLOAT(2) , sync_lat_ns_max_min FLOAT(2) , sync_lat_ns_max_avg FLOAT(2) , sync_lat_ns_max_max FLOAT(2) , sync_total_ios_min FLOAT(2) , sync_total_ios_avg FLOAT(2) , sync_total_ios_max FLOAT(2), PRIMARY KEY(UniqueRunID,Testid) );
#INSERT into pool_test_fio (UniqueRunID, Testid, NrCores, CPUType, Freq, Hostname, Nr_of_vdevs, disks_per_vdev, Pooltype, Nr_of_l2arc_devs, l2arcoption, l2arc1, l2arc2, Nr_of_slog_devs, slogoption, slog1, slog2, sync, compression, metadata, zfs_recordsize, BS, runsPtest, testfilesize, runtime, timebased, ioengine, source, iodepth, numjobs, testtype, rwmixread, sys_cpu_min, sys_cpu_avg, sys_cpu_max, usr_cpu_min, usr_cpu_avg, usr_cpu_max, cpu_ctx_min, cpu_ctx_avg, cpu_ctx_max, cpu_minf_min, cpu_minf_avg, cpu_minf_max, cpu_majf_min, cpu_majf_avg, cpu_majf_max, latency_us_2_min, latency_us_2_avg, latency_us_2_max, latency_us_4_min, latency_us_4_avg, latency_us_4_max, latency_us_10_min, latency_us_10_avg, latency_us_10_max, latency_us_20_min, latency_us_20_avg, latency_us_20_max, latency_us_50_min, latency_us_50_avg, latency_us_50_max, latency_us_100_min, latency_us_100_avg, latency_us_100_max, latency_us_250_min, latency_us_250_avg, latency_us_250_max, latency_us_500_min, latency_us_500_avg, latency_us_500_max, latency_us_750_min, latency_us_750_avg, latency_us_750_max, latency_us_1000_min, latency_us_1000_avg, latency_us_1000_max, read_slat_ns_min_min, read_slat_ns_min_avg, read_slat_ns_min_max, read_slat_ns_mean_min, read_slat_ns_mean_avg, read_slat_ns_mean_max, read_slat_ns_stddev_min, read_slat_ns_stddev_avg, read_slat_ns_stddev_max, read_slat_ns_max_min, read_slat_ns_max_avg, read_slat_ns_max_max, read_clat_ns_min_min, read_clat_ns_min_avg, read_clat_ns_min_max, read_clat_ns_mean_min, read_clat_ns_mean_avg, read_clat_ns_mean_max, read_clat_ns_stddev_min, read_clat_ns_stddev_avg, read_clat_ns_stddev_max, read_clat_ns_max_min, read_clat_ns_max_avg, read_clat_ns_max_max, read_lat_ns_min_min, read_lat_ns_min_avg, read_lat_ns_min_max, read_lat_ns_mean_min, read_lat_ns_mean_avg, read_lat_ns_mean_max, read_lat_ns_stddev_min, read_lat_ns_stddev_avg, read_lat_ns_stddev_max, read_lat_ns_max_min, read_lat_ns_max_avg, read_lat_ns_max_max, read_iops_max_min, read_iops_max_avg, read_iops_max_max, read_iops_min, read_iops_avg, read_iops_max, read_iops_min_min, read_iops_min_avg, read_iops_min_max, read_iops_stddev_min, read_iops_stddev_avg, read_iops_stddev_max, read_iops_mean_min, read_iops_mean_avg, read_iops_mean_max, read_bw_max_min, read_bw_max_avg, read_bw_max_max, read_bw_min, read_bw_avg, read_bw_max, read_bw_min_min, read_bw_min_avg, read_bw_min_max, read_bw_stddev_min, read_bw_stddev_avg, read_bw_stddev_max, read_bw_mean_min, read_bw_mean_avg, read_bw_mean_max, read_bw_agg_min, read_bw_agg_avg, read_bw_agg_max, read_short_ios_min, read_short_ios_avg, read_short_ios_max, read_drop_ios_min, read_drop_ios_avg, read_drop_ios_max, read_total_ios_min, read_total_ios_avg, read_total_ios_max, write_slat_ns_min_min, write_slat_ns_min_avg, write_slat_ns_min_max, write_slat_ns_mean_min, write_slat_ns_mean_avg, write_slat_ns_mean_max, write_slat_ns_stddev_min, write_slat_ns_stddev_avg, write_slat_ns_stddev_max, write_slat_ns_max_min, write_slat_ns_max_avg, write_slat_ns_max_max, write_clat_ns_min_min, write_clat_ns_min_avg, write_clat_ns_min_max, write_clat_ns_mean_min, write_clat_ns_mean_avg, write_clat_ns_mean_max, write_clat_ns_stddev_min, write_clat_ns_stddev_avg, write_clat_ns_stddev_max, write_clat_ns_max_min, write_clat_ns_max_avg, write_clat_ns_max_max, write_lat_ns_min_min, write_lat_ns_min_avg, write_lat_ns_min_max, write_lat_ns_mean_min, write_lat_ns_mean_avg, write_lat_ns_mean_max, write_lat_ns_stddev_min, write_lat_ns_stddev_avg, write_lat_ns_stddev_max, write_lat_ns_max_min, write_lat_ns_max_avg, write_lat_ns_max_max, write_iops_max_min, write_iops_max_avg, write_iops_max_max, write_iops_min, write_iops_avg, write_iops_max, write_iops_min_min, write_iops_min_avg, write_iops_min_max, write_iops_stddev_min, write_iops_stddev_avg, write_iops_stddev_max, write_iops_mean_min, write_iops_mean_avg, write_iops_mean_max, write_bw_max_min, write_bw_max_avg, write_bw_max_max, write_bw_min, write_bw_avg, write_bw_max, write_bw_min_min, write_bw_min_avg, write_bw_min_max, write_bw_stddev_min, write_bw_stddev_avg, write_bw_stddev_max, write_bw_mean_min, write_bw_mean_avg, write_bw_mean_max, write_bw_agg_min, write_bw_agg_avg, write_bw_agg_max, write_short_ios_min, write_short_ios_avg, write_short_ios_max, write_drop_ios_min, write_drop_ios_avg, write_drop_ios_max, write_total_ios_min, write_total_ios_avg, write_total_ios_max, sync_lat_ns_min_min, sync_lat_ns_min_avg, sync_lat_ns_min_max, sync_lat_ns_mean_min, sync_lat_ns_mean_avg, sync_lat_ns_mean_max, sync_lat_ns_stddev_min, sync_lat_ns_stddev_avg, sync_lat_ns_stddev_max, sync_lat_ns_max_min, sync_lat_ns_max_avg, sync_lat_ns_max_max, sync_total_ios_min, sync_total_ios_avg, sync_total_ios_max) VALUES ('20220410204200-28744', 1, '16', 'Genuine Intel(R) CPU 0000%@', 3.70, 'freenas12.ad.voelligegal.de', '02', '2', 'single disk mirror', '0', 'none', 'none', 'none', '0', 'none', 'none', 'none', 'disabled', 'lz4', 'all', '128k', '4k', 1, 10737418240, '60', 1, 'posixaio', 'auto', '16', '16', 'write', 0, 6.52, 6.52, 6.52, 3.76, 3.76, 3.76, 11027831.00, 11027831.00, 11027831.00, 16.00, 16.00, 16.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 1.10, 1.10, 1.10, 97.45, 97.45, 97.45, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 299.00, 299.00, 299.00, 874.37, 874.37, 874.37, 470.18, 470.18, 470.18, 351517.00, 351517.00, 351517.00, 77327.00, 77327.00, 77327.00, 834612.88, 834612.88, 834612.88, 67278.51, 67278.51, 67278.51, 4255661.00, 4255661.00, 4255661.00, 91259.00, 91259.00, 91259.00, 835487.25, 835487.25, 835487.25, 67284.05, 67284.05, 67284.05, 4256233.00, 4256233.00, 4256233.00, 312434.00, 312434.00, 312434.00, 305276.18, 305276.18, 305276.18, 294846.00, 294846.00, 294846.00, 256.09, 256.09, 256.09, 305622.13, 305622.13, 305622.13, 1249784.00, 1249784.00, 1249784.00, 1221104.00, 1221104.00, 1221104.00, 1179389.00, 1179389.00, 1179389.00, 1024.16, 1024.16, 1024.16, 1222508.83, 1222508.83, 1222508.83, 100.00, 100.00, 100.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 18316876.00, 18316876.00, 18316876.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00);




###############################################################################################################################
###############################################################################################################################
###############################################################################################################################
# END of USER configurable parts 
# most users will want to leave the rest alone starting here
###############################################################################################################################
###############################################################################################################################
###############################################################################################################################




#for automatic disk identification
#my $disklookup_filter_data_drives = 'dummy'; #provide a string that will be used to grep for data drives in disklookup-tools output
#my $disklookup_filter_slog_drives = 'dummy'; #provide a string that will be used to grep for slog drives in disklookup-tools output, note only the first two will be used
#my $disklookup_filter_l2arc_drives = 'dummy'; #provide a string that will be used to grep for data drives in disklookup-tools output, note only the first two will be used (as of now)

my $user_dlpl="disklist.pl"; #assume in current path or provide with full path
my $ext_smartctl="smartctl"; #provide full path to smartcontrol binary if not in path


#for manual disk identification via file
#note this should be changed to define the type in the file, either by a prefix ("data=|slog=|l2arc=") or by a header line
my $_current_l2arcoption; #global var to safe the current iteration's value of l2arc
my $_current_slogoption; #global var to safe the current iteration's value of slog
my $diskfile="./pool_test.config";
my $poolroot='/mnt';
my $logpath="."; # default value, will be overridden by user variable
############## internal variables
# %_pooldisks => this will hold all the disks that have been selected to be in the pool by command line parameter, input file list or menu selection. The order of input determines the order in which they will be used
my (%_pooldisks,%_pooldisks_by_id,%_vdevs,%_alldisks_dev, %_alldisks, %_alldisks_gpt,%_alldisks_part,%_alldisks_pmem, %_alldisks_mp, @_all_pool_disks) ;
my (%__all_pools,%__l2arc_slog_combinations, %_masterpoollist,$totaltests,$totalpools,$poolnr,$dsnr,$dstotal,%map_short_to_long, %_userpool_info); #for new layout
my @__all_pools;
my @fio_tests;
my %fio_tests_info;
my (@dboutputcols, @dboutputdata);
my %diskinfo_testresults;
my $stop_requested=0;
my $host = `hostname`;


#to keep track of pools that ever existed so we can skip them if a request for the same comes again
my %_historic_pool_list;
#my ($m2,$m3,$z1,$z2,$z3); #_vdevs for pooltype
#define the number of disks in the various pooltype. This is the minimum, more are always possible (eg for a Raid Z3 you can use 4+3 or 8+3/vdev

my $_pid=$$;
my @_datasets=(); #all datasets names will be listed here including poolname, eg pool_<type>/dataset_<options>
my @log_master_command_list=();
my $command_list_outfile="${_pid}all_commands.txt";
my $testcommands_list_outfile="${_pid}test_commands.txt";
my %_poolinfo; #hash to save pool & dataset information
my %_pools; #hash to save pool information
my %_datasets; #hash to save dataset information
my %ddtests;
my %ddtestresults;
my %fiotests;
my %fiotestresults;
my %_mastertestinfo; # log all performed tests in here and provide info to look up results
my $ppid=$$; #current script pid for logs
my %job2cpu; # hash to map jobs to cpu load
my $poolinfofile="./". $$ . "_out_poolinfo";
my $detailddresultsfile="./". $$ . "_out_detailed_results";
my $ddresultsfile="./". $$ . "_out_results";
my ($pihandle,$drephandle,$rephandle); # for resultfiles
my $_masterpoolid=0; #global var to keep pools numberd over all iterations
my $_masterdsid=0; #global var to keep datasets numberd over all iterations
my $mastertestid=1; #global var to keep tests numberd over all iterations (start with 1 to make it simpler for non unix users)
my $masterresultid=1; #global var to keep results numbered over all iterations (its possible that multiple tests generate one result (eg avg of 3), thats why there are two variables)
my @oldarcsettings=(); #array to save old arc settings
my $total_datasets=0; #save calculated amount of datatsets for global reference
my $test_runs_per_ds=0; #save calculated amount of tests per dataset for global reference
my $total_test_runs=0; #save calculated amount of tests for global reference
my $UniqueRunID; #for adding reports to databases, must be unique per script run
my $_got_disks=0; #for checking which disk selection process to use
my $_skip_disklistpl=0; # for skipping disklist command on unsupported platforms
my $_skip_disklist=0; # for skipping disk existence verification on unsupported platforms
#for intermediate info file
my @_report_ddtests;
my @_report_fiotests;
my @_report_pools;
my @_report_datasets;
###
###
###
####### New reporting variables
my %_SystemInfo;

my %_out_masterreport_info;
my %_out_masterreport;
my %_int_masterreport=
(
		'_0_SystemInfo' => {},
		'_1_Pool' => {},
		'_2_vDev' => {},
		'_3_dataset' => {},
		'_4_test_Meta_DD' => {},
		'_5_test_Primary_DD' => {},
		'_6_test_Secondary_DD' => {},
		'_7_test_Meta_fio' => {},
		'_8_test_Primary_fio' => {},
		'_9_test_Secondary_fio' => {}
);
#

#
#
#
#

sub _get_system_info
{
	
	if ($^O=~/freebsd/)
	{

		#
		#machdep.tsc_freq: 2399998000
		my $_command="sysctl -a | grep -E \"machdep.tsc_freq\|kern.smp.cpus\|hw.model\"";
		push @log_master_command_list, $_command;
		my @_res=&_exec_command("$_command");
		foreach (@_res)
		{
			$_SystemInfo{cpus}=$1 if $_=~/^kern.smp.cpus:\s(\d+)/;
			$_SystemInfo{cpu_type}=$1 if $_=~/^hw.model:\s(.*)$/;
			$_SystemInfo{cpu_freq}=sprintf("%.2f", $1/1000/1000/1000) if $_=~/^machdep.tsc_freq:\s(\d+)/;

		}
	}
	elsif ($^O=~/linux/)
	{
		
		my $_command="cat /proc/cpuinfo | grep -E \"name\|processor\|MHz\"";
		push @log_master_command_list, $_command;
		my @_res=&_exec_command("$_command");
		my $cpucnt=0;
		foreach (@_res)
		{
			$cpucnt=$1 if $_=~/^processor\s+:\s(\d+)$/;
			$_SystemInfo{cpu_type}=$1 if $_=~/^model name\s+:\s(.*)$/;
			$_SystemInfo{cpu_freq}=sprintf("%.2f", $1) if $_=~/^cpu MHz\s+:\s(\d+\.\d+)/;

		}
		$_SystemInfo{cpus}=$cpucnt+1;		
		$_skip_disklistpl=1;
		$_skip_disklist=1;
		$user_rungstat=0; # turn off gstat
		$jsonppbinary="./json_pp";		
	}
	else
	{
		die "OS \"$^O\" not supported yet";
	}
	$_SystemInfo{hostname}=$host;
	$_int_masterreport{_0_SystemInfo}=\%_SystemInfo;
	
	$_out_masterreport_info{_0_SystemInfo}{0}{key}='cpus';
	$_out_masterreport_info{_0_SystemInfo}{0}{label_short}='NrCores';
	$_out_masterreport_info{_0_SystemInfo}{0}{label_long}='Nr. of Cores';
	#$_out_masterreport_info{_0_SystemInfo}{0}{isstring}='1';  #?
	$_out_masterreport_info{_0_SystemInfo}{0}{isstring}='0';  
	$_out_masterreport_info{_0_SystemInfo}{0}{needs_output_conversion_comma}=0;
	$_out_masterreport_info{_0_SystemInfo}{0}{needs_output_conversion_unit}=0;
	$_out_masterreport_info{_0_SystemInfo}{0}{isunit}='';
	$_out_masterreport_info{_0_SystemInfo}{0}{Datatype}=$DBDataTypes{$useDB}{"INT"};
	$_out_masterreport_info{_0_SystemInfo}{0}{DatatypeLength}=0;
	$_out_masterreport_info{_0_SystemInfo}{1}{key}='cpu_type';
	$_out_masterreport_info{_0_SystemInfo}{1}{label_short}='CPUType';
	$_out_masterreport_info{_0_SystemInfo}{1}{label_long}='HW model CPUs';
	$_out_masterreport_info{_0_SystemInfo}{1}{isstring}='1';
	$_out_masterreport_info{_0_SystemInfo}{1}{needs_output_conversion_comma}=0;
	$_out_masterreport_info{_0_SystemInfo}{1}{needs_output_conversion_unit}=0;
	$_out_masterreport_info{_0_SystemInfo}{1}{isunit}='';
	$_out_masterreport_info{_0_SystemInfo}{1}{Datatype}=$DBDataTypes{$useDB}{"STRING"}; 
	$_out_masterreport_info{_0_SystemInfo}{1}{DatatypeLength}=32;
	$_out_masterreport_info{_0_SystemInfo}{2}{key}='cpu_freq';
	$_out_masterreport_info{_0_SystemInfo}{2}{label_short}='Freq';
	$_out_masterreport_info{_0_SystemInfo}{2}{label_long}='Frequency of CPUs';
	#$_out_masterreport_info{_0_SystemInfo}{2}{isstring}='1';
	$_out_masterreport_info{_0_SystemInfo}{2}{isstring}='0';
	$_out_masterreport_info{_0_SystemInfo}{2}{needs_output_conversion_comma}=1;
	$_out_masterreport_info{_0_SystemInfo}{2}{needs_output_conversion_unit}=0;
	$_out_masterreport_info{_0_SystemInfo}{2}{isunit}='GHz';
	$_out_masterreport_info{_0_SystemInfo}{2}{Datatype}=$DBDataTypes{$useDB}{"FLOAT"};
	$_out_masterreport_info{_0_SystemInfo}{2}{DatatypeLength}=2;
	$_out_masterreport_info{_0_SystemInfo}{3}{key}='hostname';
	$_out_masterreport_info{_0_SystemInfo}{3}{label_short}='Hostname';
	$_out_masterreport_info{_0_SystemInfo}{3}{label_long}='Hostname of Testsystem';
	$_out_masterreport_info{_0_SystemInfo}{3}{isstring}='1';
	$_out_masterreport_info{_0_SystemInfo}{3}{needs_output_conversion_comma}=0;
	$_out_masterreport_info{_0_SystemInfo}{3}{needs_output_conversion_unit}=0;
	$_out_masterreport_info{_0_SystemInfo}{3}{isunit}='';
	$_out_masterreport_info{_0_SystemInfo}{3}{Datatype}=$DBDataTypes{$useDB}{"STRING"};
	$_out_masterreport_info{_0_SystemInfo}{3}{DatatypeLength}=32;
	
}

sub _getRunTime
{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    return sprintf ( "%04d%02d%02d%02d%02d%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec);
}

sub _getLogTime
{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    return sprintf ( "%04d-%02d-%02d-%02d:%02d:%02d", $year+1900,$mon+1,$mday,$hour,$min,$sec);
}


sub _print_log ()
{
	my ($level,$entry)=($_[0],$_[1]);
	
	my $print_to_log=($verbose<2)?2:$verbose; #write to log all the time with at least level 2
	my $print_to_screen=($verbose>3)?3:$verbose; #write to screen based on selected verbosity setting but only up to level 3


#	$print_to_screen=1 if (($level >= $verbose) || $debug));
#	$print_to_screen=1 if ($level == 3 && ($extraverbose|| $debug));
#	$print_to_screen=1 if ($level == 4 && $debug);
#	$print_to_screen=1 if ($level <= 1 );
	
	#$print_to_log  = $print_to_screen if $log_adhere_to_screen_verbosity;

	my $ts=&_getLogTime;

	

	if ($level <= $print_to_log)
	{
		open ( my $handle, '>>', "$0.$_pid.log");
		if ($entry =~ /\n$/)
		{			
				print $handle "$ts,$level>$entry"; #contains newline - print as new record	
		}
		else
		{
			print $handle "$entry"; #no newline - just continue previous entry (no date, no level)

		}
		close $handle;
	}

	if ($level <= $print_to_screen)
	{
		print "$entry";
	}


}

#&_get_drive_temps($_lastts, "${ppid}_temps_${dslong2}_$type.log");
sub _get_drive_temps ()
{
	my ($_lastts,$_outfile)=($_[0],$_[1]);
	my $_currentts=time();

	if ($_currentts - $_lastts >= $user_gettemps_interval)
	{
		&_print_log (3,"will check drive temps\n");
		my ($_handle);
		open ( $_handle, '>>', $_outfile);

#		foreach (keys %_alldisks_dev)
		foreach (@_all_pool_disks)
		{
			my $_drivetemp=&_get_drive_temps_single_disk($_);
			print $_handle "$_currentts;$_;$_drivetemp\n";
		}
		close $_handle;
	}
}
sub _get_drive_temps_single_disk ()
{
	my ($_disk)=($_[0]);
	#&_print_log (0,"Temp check for $_disk needs rework\n");
	&_print_log (4,"will check drive temps for disk $_\n");

	#get da and type to determine temp access path
	#set default temp to 0 so we can simply ignore non working drives
	my $_device="$_disk"; # unless ($_disk=~/\/dev\//);

	if (-e $_device)
	{
		#for sata disk
		#smartctl -a /dev/da4 | grep -E "^ID#|^194"
		#ID# ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
		#194 Temperature_Celsius     0x0002   181   181   000    Old_age   Always       -       33 (Min/Max 7/51)
		
		#### DIRTY HACK
		$_device="/dev/nvme$1" if ($_device=~/\/dev\/nvd(\d+)$/);
		#### DIRTY HACK
		
		&_print_log (3,"Skipping temp check for $_device\n") if ($_device=~/pmem/);
		return 0 if ($_device=~/pmem/); #need to find some oter way for this

		my $_command="$ext_smartctl -a $_device |grep -E \"ID#\|^194|^Current Drive Temperature:|^Temperature:\"";
		push @log_master_command_list, $_command;
		my @_res=&_exec_command("$_command");

		if (scalar @_res == 2)
		{
    	my $_indexline=	$_res[0];
    	my $_dataline=	$_res[1];

			my $_idx= index $_indexline,  "RAW_VALUE"; #get value position

			if ($_idx == -1)
			{
				&_print_log (1,"error getting smart RAW Data index for $_device\n");
				return 0;
			}
			my $_drivetemp = substr $_dataline, $_idx, 2; # assume drives should never get >99°C
			chomp $_drivetemp; #remove space if any
			&_print_log (3,"Found temp $_drivetemp for $_device\n");
			return $_drivetemp;
		} #else we will return 0
		elsif (scalar @_res == 1) #check if we got a SAS or NVME drive at hand
		{
			if ($_res[0]=~/Current Drive Temperature:\s+(\d{1,3})\sC$/)
			{
				my $_drivetemp = $1;
				chomp $_drivetemp; #remove space if any
				&_print_log (3,"Found temp $_drivetemp for $_device\n");
				return $_drivetemp;
			}
			elsif ($_res[0]=~/Temperature:\s+(\d{1,3})\sCelsius$/)
			{
				my $_drivetemp = $1;
				chomp $_drivetemp; #remove space if any
				&_print_log (3,"Found temp $_drivetemp for $_device\n");
				return $_drivetemp;
			}
			else
			{
				&_print_log (1,"error single line return smart data for $_device\n");
				return 0;
			}
		}
		else
		{
			&_print_log (1,"error getting smart data for $_device\n");
			return 0;
		}
	}
	&_print_log (1,"Device not found or not working as expected: $_device\n");
	return 0; #dummy value

}

#check
# -is it available
# -is it the same size as the other disks
# -is it the same type as the other disks
sub _check_disk ()
{
	my $_d=$_[0];
	&_print_log (1,"Future functionality: check $_d ...\n");

	#can we find it?
	if (($_d=~/da/)||($_d=~/\/dev\//))
	{
		unless ((-e $_d) || (-e "/dev/$_d"))
		{
    	die ("device $_d does not exist!\n");
		}
		else
		{
			&_print_log (1,"exists\n");
		}

	}
	&_check_disk_capbilities($_d);

}

# zpool status
#  pool: boot-pool
# state: ONLINE
#  scan: scrub repaired 0B in 00:01:20 with 0 errors on Wed Apr 20 03:46:20 2022
#config:
#
#        NAME        STATE     READ WRITE CKSUM
#        boot-pool   ONLINE       0     0     0
#          ada0p2    ONLINE       0     0     0
#
#errors: No known data errors
#
#  pool: pm1725a
# state: ONLINE
#  scan: scrub repaired 0B in 00:10:25 with 0 errors on Sun Apr 17 00:10:25 2022
#config:
#
#        NAME                                            STATE     READ WRITE CKSUM
#        pm1725a                                         ONLINE       0     0     0
#          mirror-0                                      ONLINE       0     0     0
#            gptid/1ab3d462-f912-11ea-962b-ac1f6b412042  ONLINE       0     0     0
#            gptid/1ab087e1-f912-11ea-962b-ac1f6b412042  ONLINE       0     0     0
#          mirror-1                                      ONLINE       0     0     0
#            gptid/d0aed2c3-f9f6-11ea-9d1b-ac1f6b412042  ONLINE       0     0     0
#            gptid/d0b59c85-f9f6-11ea-9d1b-ac1f6b412042  ONLINE       0     0     0
#        logs
#          gptid/01f650ca-9231-11ec-baa1-ac1f6b412042    ONLINE       0     0     0
#
#errors: No known data errors
#
#  pool: tank4
# state: ONLINE
#status: Some supported features are not enabled on the pool. The pool can
#        still be used, but some features are unavailable.
#action: Enable all features using 'zpool upgrade'. Once this is done,
#        the pool may no longer be accessible by software that does not support
#        the features. See zpool-features(5) for details.
#  scan: scrub repaired 0B in 18:54:10 with 0 errors on Sun Apr  3 18:54:13 2022
#config:
#
#        NAME                                            STATE     READ WRITE CKSUM
#        tank4                                           ONLINE       0     0     0
#          raidz2-0                                      ONLINE       0     0     0
#            gptid/e6fc9e47-80e0-11ec-bf85-ac1f6b412042  ONLINE       0     0     0
#            gptid/d61430be-4307-11ec-a6c2-ac1f6b412042  ONLINE       0     0     0
#            gptid/0ff1bcf2-81ac-11ec-bf85-ac1f6b412042  ONLINE       0     0     0
#            gptid/b78fc758-130c-11ec-937d-ac1f6b412042  ONLINE       0     0     0
#            gptid/ba4c25a1-3cc6-11ec-adbd-ac1f6b412042  ONLINE       0     0     0
#            gptid/6de191de-833e-11ec-9903-ac1f6b412042  ONLINE       0     0     0
#
#errors: No known data errors


sub _get_pool_info ()
{
		my $_p=$_[0];
		&_print_log (4,"Entering _get_pool_info\n");
		my $_command="zpool status $_p";
		push @log_master_command_list, $_command;
		my @zpool=&_exec_command("$_command");
		
		&_print_log(4, "Checking pool with \"$_command\"\n");
		
		my ($in_config,$foundpool,$layout,$slog,$cache,$state);
		my ($diskcnt,$slogcnt,$cachecnt,$vdevs) = (0,0,0,0);
		
		#parse zpool output
		foreach my $line (@zpool)
		{
			next if $line =~/^\s*$/; #skip empty lines
			chomp $line;
			
			#&_print_log(4, "Loop line $line\n");	
			$foundpool=$1 if ($line=~/^\s*pool:\s(\w+)\s*$/);
			$state=$1 if ($line=~/^\s*state:\s(\w+)\s*$/);
			$in_config=1 if ($line=~/^\s*config:/);
			if ($in_config)
			{
				#&_print_log(4, "user pool - checking config line $line\n");
				next if ($line=~/^\s*NAME:\s(\w+)\s*$/);
				$foundpool=1 if ($line=~/^\s*$_p/i);
				if (($line=~/^\s*(raidz\d)(-\d+)?/i) || ($line=~/^\s*(mirror)(-\d+)?/i))
				{
					$layout=$1;
					$vdevs++;
					&_print_log(4, "user pool - layout $layout\n");
					next;
				}
				if (defined $layout && $vdevs==1  && !defined $slog && !defined $cache)
				{
					$diskcnt++ if ($line=~/ONLINE/);#count online devices
				}
				elsif (defined $layout && defined $slog && !defined $cache)
				{
					$slogcnt++ if ($line=~/ONLINE/);#count online devices
				}
				elsif (defined $layout && defined $cache)
				{
					$cachecnt++ if ($line=~/ONLINE/);#count online devices
				}
				
				$slog=1 if ($line=~/^\s*logs/i) ;
				$cache=1 if ($line=~/^\s*cache/i) ;
				
			}
			if ($line=~/^\s*errors:/)
			{
				#last line of a pool entry, so handle to pool info 
				$in_config=0;
				$_userpool_info{"$_p"}{"found"}=$foundpool;
				$_userpool_info{"$_p"}{"state"}=$state;
				$_userpool_info{"$_p"}{"layout"}=$layout;
				$_userpool_info{"$_p"}{"vdevs"}=$vdevs;
				$_userpool_info{"$_p"}{"diskcnt"}=$diskcnt;
				$_userpool_info{"$_p"}{"slogcnt"}=$slogcnt;
				$_userpool_info{"$_p"}{"cachecnt"}=$cachecnt;
				
				&_print_log(3, "user pool - foundpool $foundpool, state $state, layout $layout, vdevs $vdevs, diskcnt $diskcnt, slogcnt $slogcnt, cachecnt $cachecnt\n");
			}
		}
		&_print_log (4,"Exiting _get_pool_info\n");
		return 0;
}

sub _check_disk_exists ()
{
	my $_d=$_[0];
	&_print_log (4,"_check_disk_exists\n");
	&_print_log (3,"check_exist $_d\n");
	my $retval=0;

	#easy solution here - check if the disk in in the disklist hashes. These should be filled right at the beginning
	if ($_d =~/^\/dev\//)
	{
		$retval++ if ($_alldisks_dev{"$_d"});
	}
	elsif ($_d =~/^gptid\//)
	{
		$retval++ if ($_alldisks_gpt{"$_d"});
	}
	elsif ($_d =~/^multipath\//)
	{
		$retval++ if ($_alldisks_mp{"$_d"});
	}
	else
	{
		$retval++ if ($_alldisks_dev{"/dev/$_d"});
	}

	$retval++ if ($_alldisks_part{$_d});
	#$retval++ if ($_alldisks_pmem{$_d});
	
	if ($^O=~/linux/)	
	{
		#run udevadm info --query=name /dev/nvme1n1
		
		my $_command="udevadm info --query=name $_d";
		push @log_master_command_list, $_command;
		my $name=&_exec_command("$_command");
		$retval++ if $_d=~/$name/;
		
	}
	
	&_print_log (4,"Exiting _check_disk_exists\n");
	return $retval;
}


#what type is it (vdev, sata, sas, nvme, pmem, other?
#can it support smart (for diskinfo), can we get temperature
sub _check_disk_capbilities
{
	my $_d=$_[0];
	&_print_log (1,"Future functionality: check capabilities $_d\n");

	#identify type and capabilities

}


sub _write_commandlist
{
	my $df=$_[0];
	my ($_handle);
	open ( $_handle, '>', $command_list_outfile);
	foreach my $cmd (@log_master_command_list)
	{
		print $_handle "$cmd\n";
	}
	close $_handle;

}

sub _assemble_disk_list_from_environment # not used yet, will be used for menu driven selection
{
	#placeholder function;
	my ($_command,$disk);

	#run disklist to get all disks
	my @_alld = &_get_diskinfo_disklistpl;

	&_print_log (0,"Future functionality: add menu or selection process to pick drives from environment, found the following:" . join "\n", @_alld);
	return;
	#We need now a selection process for all the disks found in the environment
	#we can check if they are are in a pool first and only offer 'free' ones
	#we can check if they are are in a pool first and only offer 'free' ones

}

sub _disk_not_found
{
	my ($text)=($_[0]);
	die "$text - please run 'perl disklist.pl' to verify\n" unless $_skip_disklist;
}

#this is our last option to get disks
sub _get_disks_from_script_vars
{
	&_print_log (4,"Begin _get_disks_from_script_vars\n");
	my ($disk,%diskvar_hash,%_tempdiskhash);

	my $pos=1;#start disk list with 1 to match pool create
	foreach $disk (@uservar_datadisks)
	{
		if (&_check_disk_exists($disk))
		{
			#add only if no duplicate
			if (exists $_tempdiskhash{$disk})
			{
				&_print_log (1,"$disk ignored (duplicate)\n");
			}
			else
			{
				$diskvar_hash{$pos}{id}="$disk"; #add only if no duplicate
	  		$_tempdiskhash{$disk}=1;
	  		$pos++;
			}

	  }
	  else
	 	{
	 		&_disk_not_found ("Disk \"$disk\" provided in Datadisk variable does not exists according to disklist");
	 	}
	}

	if (defined $uservar_slogdev && ($uservar_slogdev !~/slog1/))
	{
		$diskvar_hash{slogdev}{id}="$uservar_slogdev" if &_check_disk_exists($uservar_slogdev);
	}
	if (defined $uservar_slogdev2 && ($uservar_slogdev2 !~/slog2/))
	{
		$diskvar_hash{slogdev2}{id}="$uservar_slogdev2" if &_check_disk_exists($uservar_slogdev2);
	}
	if (defined $uservar_l2arcdev && ($uservar_l2arcdev !~/l2arc1/))
	{
		$diskvar_hash{l2arcdev}{id}="$uservar_l2arcdev" if &_check_disk_exists($uservar_l2arcdev);
	}
	if (defined $uservar_l2arcdev2 && ($uservar_l2arcdev2 !~/l2arc2/))
	{
		$diskvar_hash{l2arcdev2}{id}="$uservar_l2arcdev2" if &_check_disk_exists($uservar_l2arcdev2);
	}


	unless (scalar keys %diskvar_hash)
	{
		die "Datadisk varialble (".join " ", @uservar_datadisks. ") did not provide enough valid disks - no fallback option\n";

	}
	%_pooldisks=%diskvar_hash;
	&_print_log (4,"Finish _get_disks_from_script_vars\n");
	
}

sub _get_userpool_from_file ()
{
	my $df=$_[0];
	&_print_log (4, "Begin _get_userpool_from_file\n");
	my ($handle,@lines,$_userpool,$type);

	@lines=&_read_diskfile($df);
	
	foreach my $line (@lines)
	{
		chomp $line;
		next if $line =~/^\s*#/; #skip lines with comments
		next if $line =~/^\s*$/; #skip empty lines
		&_print_log (4,"Line $line found in $df\n");
		#new format found (data= or data: or slog/l2arc= ...)
		if ($line=~/^\s*userpool\s*=\s*(\w+?)\s*$/i)
		{

			$_userpool=$1;
			next unless ($_userpool =~ /\w+/);
			
			&_print_log (2,"User defined pool $_userpool found, getting details\n");
			&_get_pool_info($_userpool);
		}			


	}		  
	unless (scalar keys %_userpool_info)
	{
			print Dumper \%_userpool_info;
			if (defined $_userpool)
			{
				die ("userpool_do set to $userpool_do but User given pool $_userpool not valid (check log)");
			}
			else {
				die ("userpool_do set to $userpool_do but no User pool found (check log)");
			}
	}
	die ("User given pool $_userpool is not in an acceptable state (".$_userpool_info{$_userpool}{state}.")") unless (($_userpool_info{"$_userpool"}{"state"}=~/ONLINE/) || ($_userpool_info{"$_userpool"}{"state"}=~/DEGRADED/));

	my $nrdisk=$_userpool_info{"$_userpool"}{"vdevs"} * $_userpool_info{"$_userpool"}{"diskcnt"};
	&_print_log (3, "Found $nrdisk disks\n");
	&_print_log (4, "Finished _get_userpool_from_file\n");
	return $nrdisk; #all good

}

sub _read_diskfile ()
{
	my $df=$_[0];
	my ($handle,@lines);
	
	if (!-e $df)
	{
		&_print_log (1,"Data disk file ($df) not found  - falling back to internal variables\n");
		return 0;
	}
	if (-z $df)
	{
		&_print_log (1,"Data disk file ($df) is empty  - falling back to internal variables\n");
		return 0;
	}

	open ( $handle, '<', $df);
	chomp(@lines = <$handle>);
	close $handle;

	return @lines;
}

sub _get_disklist_from_file ()
{
	my $df=$_[0];
	&_print_log (4, "Begin _get_disklist_from_file\n");
	my (@lines,$disk,$type,%disklist_hash,%_tempdiskhash);

	@lines=&_read_diskfile($df);

	my $pos=1;#start disk list with 1 to match pool create
	foreach my $line (@lines)
	{
			chomp $line;
			next if $line =~/^\s*#/; #skip lines with comments
			next if $line =~/^\s*$/; #skip empty lines

			&_print_log (4,"Line $line found in $df\n");
			#new format found (data= or data: or slog/l2arc= ...)
			if ($line=~/(\w+)\s*[:=]\s*(.+)$/)
			{
				$type=$1;
				$disk=$2;
				unless (($type =~ /data/i) ||
								($type =~ /slog1/i) ||
								($type =~ /slog2/i)  ||
								($type =~ /l2arc1/i)  ||
								($type =~ /l2arc2/i) ||
								($type =~ /slogdev1/i) ||
								($type =~ /slogdev2/i)  ||
								($type =~ /l2arcdev1/i)  ||
								($type =~ /l2arcdev2/i) )
				{
					if (($type =~ /^slog$/i) || ($type =~ /^slogdev$/i))
					{
						$type="slog1";
					}
					elsif (($type =~ /^l2arc$/i) || ($type =~ /^l2arcdev$/i))
					{
						$type="l2arc1";
					}
					else
					{
						&_print_log (0,"Invalid disk type found ($type) in line \"$line\" ) - skipped (should be data, slog[12] or l2arc[12]\n");
						next;	
					}
					
				}

				if ($disk=~/(.+)\s*#.*$/)
				{
					$disk=$1;
				}
				&_print_log (3,"New format found in disklist line $line: values $type, $disk\n");
			}
			elsif ($line=~/^(gptid\/.+?)\s+ONLINE.*/)
	  	{
	  		$type='data'; #old format
		 		$disk=$1;
		  }
		  elsif ($line=~/^(gptid\/\w+?)$/)
	  	{
	  		$type='data'; #old format
		 		$disk=$1;
		  }
		  elsif ($line=~/^(da\d+).*/)
	  	{
	  		$type='data'; #old format
	  		$disk=$1;
	  		&_print_log (3,"Old format found in disklist line $line: values $type, $disk\n");
		  }
		  else
		  {
		  	die "unexpected format in disklist found :$line\n";
		  }

		if (&_check_disk_exists($disk))
		{
	  	if ($type=~/slog1/ || $type=~/slogdev1/ || $type=~/slogdev/)
			{
				$disklist_hash{slogdev}{id}="$disk";
			}
			elsif ($type=~/slog2/ || $type=~/slogdev2/)
			{
				$disklist_hash{slogdev2}{id}="$disk";
			}
			elsif ($type=~/l2arc1/ || $type=~/l2arcdev1/ || $type=~/l2arcdev/)
			{
				$disklist_hash{l2arcdev}{id}="$disk";
			}
			elsif ($type=~/l2arc2/ || $type=~/l2arcdev2/ )
			{
				$disklist_hash{l2arcdev2}{id}="$disk";
			}
			else # add disk only if its not a special disk type
			{
				#add only if no duplicate
				if (exists $_tempdiskhash{$disk})
				{
					&_print_log (1,"$disk ignored (duplicate)\n");
				}
				else
				{
					$disklist_hash{$pos}{id}="$disk" unless exists $_tempdiskhash{$disk} ; #add only if no duplicate
		  		$_tempdiskhash{$disk}=1;
		  		$pos++;
				}
			}
	  }
	  else
	 {
	 		&_disk_not_found ("Disk \"$disk\" provided in \"$line\" does not exists according to disklist");
	 }
	}

	unless (scalar (keys %disklist_hash) )
	{
		&_print_log (1,"Data disk file ($df) did not provide enough valid disks - falling back to internal variables\n");
		return 0;
	}

	#get gptids for all disks if they are known
	#print Dumper \%disklist_hash;
	foreach my $a (keys %disklist_hash)
	{
		$disklist_hash{$a}{gptid}  =  &_get_gptid ($disklist_hash{$a}{id});
	}
	$disklist_hash{l2arcdev}{gptid}  	=  &_get_gptid ($disklist_hash{l2arcdev}{id}) 	if exists $disklist_hash{l2arcdev};
	$disklist_hash{l2arcdev2}{gptid}  =  &_get_gptid ($disklist_hash{l2arcdev2}{id}) 	if exists $disklist_hash{l2arcdev2};
	$disklist_hash{slogdev}{gptid}  	=  &_get_gptid ($disklist_hash{slogdev}{id}) 		if exists $disklist_hash{slogdev};
	$disklist_hash{slogdev2}{gptid}  	=  &_get_gptid ($disklist_hash{slogdev2}{id})		if exists $disklist_hash{slogdev2};


	#print "838", Dumper \%disklist_hash;
	%_pooldisks=%disklist_hash;

	#print "disklist_hash:",Dumper \%disklist_hash;
	#print "_pooldisks", Dumper \%_pooldisks;

	my $nrdisk=scalar (keys %disklist_hash);
	&_print_log (3, "Found $nrdisk disks\n");
	&_print_log (4, "Finished _get_disklist_from_file\n");
	return $nrdisk; #all good

}

sub _get_gptid ()
{
	my $_disk=$_[0];
	my $diskdevid=$_disk; #return given diskname if we cant fid gptid
	&_print_log (4,"checking gptid for $_disk\n");
	$diskdevid = $_disk if ($_disk=~/\/dev\//);
	$diskdevid = $_alldisks_gpt{$_disk} if ($_disk=~/^gptid\//);
	$diskdevid = $_alldisks_part{$_disk} if ($_disk=~/^\w+\d+p\d+\//); #eg (a)da0p2
	$diskdevid = $_alldisks{$_disk} if ($_disk=~/^\w+\d+/); #eg (a)da0
	#&_print_log (4,"got diskdevid $diskdevid => $_alldisks_dev{$diskdevid}{gpt}\n") if (defined $diskdevid) ;
	return  $_alldisks_dev{$diskdevid}{gpt} ;
}

sub _get_devid ()
{
	my $_disk=$_[0];
	my $diskdevid="disk not found";
	&_print_log (4,"checking dev id for $_disk\n");
	$diskdevid = $_disk if ($_disk=~/\/dev\//);
	$diskdevid = $_alldisks_gpt{$_disk} if ($_disk=~/^gptid\//);
	$diskdevid = $_alldisks_part{$_disk} if ($_disk=~/^\w+\d+p\d+\//); #eg (a)da0p2
	$diskdevid = $_alldisks{$_disk} if ($_disk=~/^\w+\d+/); #eg (a)da0
	&_print_log (4,"got diskdevid $diskdevid\n");
	return $diskdevid ;
}


sub _check_drives_in_pool
{
 &_print_log(2, "Running check_drives_in_pool\n");
	my $disks_in_pools=0;
	foreach my $nr (sort keys %_pooldisks)
	{
		my $devid= &_get_devid ($_pooldisks{$nr}{id});
		push @_all_pool_disks, $devid;
		if (exists $_alldisks_dev{$devid})
		{
			my $existing_pool=$_alldisks_dev{$devid}{currentpool};

			if (defined $existing_pool && $existing_pool=~/\w+/)
			{
				&_print_log(0, "According to diskinfo.pl disk $devid is already in pool: $existing_pool\n");
				$disks_in_pools++;
			}
			else
			{
				&_print_log(4, "Disk $devid is not in an old pool\n");
			}
		}
	}

	return $disks_in_pools;
}


sub _normalize_pooldisks  #for easier reporting
{
	#_pooldisks
#	'7' => {
#                   'id' => '/dev/da9',
#                   'gptid' => 'gptid/f8b7f18d-126b-11e7-b2b0-0050569e17a3'
#                 },
#          'slogdev' => {
#                         'gptid' => 'gptid/f69a3c49-828b-11e8-975b-0050569e17a3',
#                         'id' => 'da1'
#
	foreach my $nr (sort keys %_pooldisks)
	{
		my $devid= &_get_devid ($_pooldisks{$nr}{id});
		if (exists $_alldisks_dev{$devid})
		{
			$_alldisks_dev{$devid}{pooldisk_position}=$nr;
			$_pooldisks{$nr}{oldid}=$_pooldisks{$nr}{id}; #save given id in case we need it
			$_pooldisks{$nr}{id}=$devid; #save actual device based id for consistency
		}
		else
		{
			die "unexpected error identifying disk #$nr ($_pooldisks{$nr}{id})";
		}
	}
}



sub _create_single_pool_and_run_tests_extended()
{
	#nr_vdevs is the amount of vdevs to add to the pool. 2+ vdevs means create pool + add vdev
	#offset is needed to skip disks in the disklist (i.e. offset 1 = skip 1 vdev worth of disks)
	my ($vdevtype,$redundancysize,$redundancytype,$vdevcount,$offsetcount,$cachetype,$logtype,$_pool) = ($_[0],$_[1],$_[2],$_[3],$_[4],$_[5],$_[6],$_[7]);
	my ($_diskcount,$_command,$type_verbose,$_type_tech,$_type_verbose,$_skipdisks,$_disks,$_redundancy_tech);
	my ($_diskcount_type,$_diskcount_rtype);
	#&_print_log(4, "_create_single_pool_and_run_tests_extended:$vdevtype,$redundancysize,$redundancytype,$vdevcount,$offsetcount,$cachetype,$logtype,$_pool \n");

	$poolnr++;
	$_pools{$_masterpoolid}{name}=$_pool;
	$_pools{$_masterpoolid}{status}=1; #set pool activce
	$_pools{$_masterpoolid}{nr_vdevs}=$vdevcount;
	$_pools{$_masterpoolid}{offset}=$offsetcount;
	$_current_l2arcoption=$cachetype;
	$_current_slogoption=$logtype;

	&_print_log(0, "Building pool $_pool ($poolnr/$totalpools)\n");

	#identify disks per vdev - thats the defined size per vdevtype times redundancy setting

				#my @uservar_vdev_type=('sin','z1','z2','z3');
				#my @uservar_vdev_redundancy=('no','str','mir');

				#define amount of disks per pooltype. O/C m2/m3 are not two pool types but only disk increase but it got its own type nevertheless.
				#Raid Z's are based on a 4+x [1,2,3] layout, not absolute minimums - larger values (y+x [y=4,5,6,7..., x=1,2,3]) can be specified
				#my $_diskcount_z1=5;
				#my $_diskcount_z2=6;
				#my $_diskcount_z3=7;
	if ($vdevtype=~/sin/)
	{
		$_diskcount_type=1;
		$_type_tech=''; # nothing here
		$_type_verbose="single disk";
	}
	elsif ($vdevtype=~/z1/)
	{
		$_diskcount_type=$_diskcount_z1;
		$_type_tech='raidz1';
		$_type_verbose=$_type_tech;		
	}
	elsif ($vdevtype=~/z2/)
	{
		$_diskcount_type=$_diskcount_z2;
		$_type_tech='raidz2';
		$_type_verbose=$_type_tech;
	}
	elsif ($vdevtype=~/z3/)
	{
		$_diskcount_type=$_diskcount_z3;
		$_type_tech='raidz3';
		$_type_verbose=$_type_tech;
	}
	else { die "unexpected vdevtype $vdevtype"}

	if ($redundancytype=~/no/)
	{
		$_diskcount_rtype=1;
		#$_type_verbose=""; #dont change
	}
	elsif ($redundancytype=~/str/)
	{
		$_diskcount_rtype=$redundancysize;
		$_type_verbose.=" stripe";
	}
	elsif ($redundancytype=~/mir/)
	{
		$_diskcount_rtype=$redundancysize;
		$_type_tech='mirror'; # set type to mirror
		$_type_verbose.=" mirror";
	}
	else { die "unexpected redundancytype $redundancytype"}

	$_diskcount=$_diskcount_type * $_diskcount_rtype;
	&_print_log (3, "creating pool $_pool with $_diskcount disks per vdev (type:$_type_verbose)\n");

	#identify how many disks to skip - basically n vdevs times offsetsize

	$_skipdisks=$offsetcount*$_diskcount;
	&_print_log (3, "Skipping $_skipdisks drives due to offset specification\n");


	$_pools{$_masterpoolid}{"diskspervdev"}=$_diskcount;
	$_pools{$_masterpoolid}{"type_tech"}=$_type_tech;
	$_pools{$_masterpoolid}{"type_verbose"}=$_type_verbose;
	#$_pools{$_masterpoolid}{"pooltype"}=$_pooltype;

	#prepare pool create command
	#single: zpool create <name> <disk1>
	#stripe: zpool create <name> <disk1> ... <diskn>
	#mirror: zpool create <name> mirror <disk1> ... <diskn>


	#extend zpool
	#zpool add tank mirror c4t7d0 c4t8d0

	#################
	# IF it exists add devices by gptid
	###############

	my $_curdisknr;
	my $_currentvdev=1;
	my $_nr_vdevs=$vdevcount;

	print "985", Dumper \%_pooldisks;
#	print "986", Dumper \%_alldisks_dev;

	for ($_currentvdev .. $_nr_vdevs)
	{
		$_disks=''; #reset disk list before next vdev
		&_print_log(2, "For the next vdev (vdev# $_currentvdev) \"$_type_verbose\" ...\n");
		#get the disk ids
		for (my $_d=1; $_d <= $_diskcount; $_d++)
		{
		  $_curdisknr=$_skipdisks+(($_currentvdev-1)*$_diskcount)+$_d;

			my $disk = $_pooldisks{$_curdisknr}{id}; #get /dev/id
			print "_d=$_d, disk=$disk\n";
			my $disk_gpt = &_get_gptid ($disk);
			$disk=(defined $disk_gpt && $disk_gpt=~/\w+/)?$disk_gpt:$disk;
			print "_d=$_d, disk=$disk\n";
			&_print_log(4,"Current disk# ($_curdisknr),skipdisks=$_skipdisks,currentvdev=$_currentvdev,diskcount=$_diskcount, d=$_d || curdisknr = $_skipdisks+(($_currentvdev-1)*$_diskcount)+$_d\n");

			$_disks.=" $disk";
			$_pools{$_masterpoolid}{vdevs}{"vdev_$_currentvdev"}{"disk$_d"}=$disk;
		}
		&_print_log(2,"...we will use disks:\t${_disks}\n");
		if ($_currentvdev==1)
		{
			#$_command ="zpool create -R $poolroot -n $_pool mirror ${disk1} ${disk2}";
			$_command ="zpool create -R $poolroot $_pool $_type_tech ${_disks}"  unless $force_pool_creation;
			$_command ="zpool create -f -R $poolroot $_pool $_type_tech ${_disks}"  if $force_pool_creation;

			#### This section handles the L2Arc and SLOG devices
			# This is a per pool setting
			#device existence checks have been done before
			
			
			#add log/cache info
			$_pools{$_masterpoolid}{"l2arcoption"}=$cachetype;
			$_pools{$_masterpoolid}{vdevs}{"l2arcdevs"}="none";							
			$_pools{$_masterpoolid}{"slogoption"}=$logtype; #leave in for processing, long for output set below
			$_pools{$_masterpoolid}{vdevs}{"slogdevs"}="none";
			$_pools{$_masterpoolid}{nr_l2arc_devs}=0;
			$_pools{$_masterpoolid}{nr_slog_devs}=0;
			
			
			if ($_current_l2arcoption=~/sf/)
			{
				$_command.=" cache $_pooldisks{'l2arcdev'}{id} ";
				$_pools{$_masterpoolid}{vdevs}{"l2arcdevs"}="$_pooldisks{'l2arcdev'}{id}";				
				$_pools{$_masterpoolid}{nr_l2arc_devs}=1;
				$_pools{$_masterpoolid}{"l2arcoptionlong"}="single_first";
				$_pools{$_masterpoolid}{"l2arc1"}=$_pooldisks{'l2arcdev'}{id};
				$_pools{$_masterpoolid}{"l2arc2"}="none";
			}
			elsif ($_current_l2arcoption=~/ss/)
			{
				$_command.=" cache $_pooldisks{'l2arcdev2'}{id} ";
				$_pools{$_masterpoolid}{vdevs}{"l2arcdevs"}="$_pooldisks{'l2arcdev2'}{id}";				
				$_pools{$_masterpoolid}{nr_l2arc_devs}=1;
				$_pools{$_masterpoolid}{"l2arcoptionlong"}="single_second";				
				$_pools{$_masterpoolid}{"l2arc1"}="none";
				$_pools{$_masterpoolid}{"l2arc2"}=$_pooldisks{'l2arcdev2'}{id};
			}
			elsif ($_current_l2arcoption=~/str/)
			{
				$_command.=" cache $_pooldisks{'l2arcdev'}{id} $_pooldisks{'l2arcdev2'}{id} ";
				$_pools{$_masterpoolid}{vdevs}{"l2arcdevs"}="stripe $_pooldisks{'l2arcdev'}{id} $_pooldisks{'l2arcdev2'}{id}";				
				$_pools{$_masterpoolid}{nr_l2arc_devs}=2;
				$_pools{$_masterpoolid}{"l2arcoptionlong"}="stripe_both";
				$_pools{$_masterpoolid}{"l2arc1"}=$_pooldisks{'l2arcdev'}{id};
				$_pools{$_masterpoolid}{"l2arc2"}=$_pooldisks{'l2arcdev2'}{id};
			}
			elsif ($_current_l2arcoption=~/mirror/)
			{
				$_command.=" cache mirror $_pooldisks{'l2arcdev'}{id} $_pooldisks{'l2arcdev2'}{id} ";
				$_pools{$_masterpoolid}{vdevs}{"l2arcdevs"}="mirror $_pooldisks{'l2arcdev'}{id} $_pooldisks{'l2arcdev2'}{id}";				
				$_pools{$_masterpoolid}{nr_l2arc_devs}=2;
				$_pools{$_masterpoolid}{"l2arcoptionlong"}="mirror_both";
				$_pools{$_masterpoolid}{"l2arc1"}=$_pooldisks{'l2arcdev'}{id};
				$_pools{$_masterpoolid}{"l2arc2"}=$_pooldisks{'l2arcdev2'}{id};
			}
			else
			{
				$_pools{$_masterpoolid}{"l2arcoptionlong"}="none";
				$_pools{$_masterpoolid}{"l2arc1"}="none";
				$_pools{$_masterpoolid}{"l2arc2"}="none";
			}
			

			if ($_current_slogoption=~/sf/)
			{
				$_command.=" log $_pooldisks{'slogdev'}{id} ";
				$_pools{$_masterpoolid}{vdevs}{"slogdevs"}="$_pooldisks{'slogdev'}{id}";				
				$_pools{$_masterpoolid}{nr_slog_devs}=1;
				$_pools{$_masterpoolid}{"slogoptionlong"}="single_first";
				$_pools{$_masterpoolid}{"slog1"}=$_pooldisks{'slogdev'}{id};
				$_pools{$_masterpoolid}{"slog2"}="none";
			}
			elsif ($_current_slogoption=~/ss/)
			{
				$_command.=" log $_pooldisks{'slogdev2'}{id} ";
				$_pools{$_masterpoolid}{vdevs}{"slogdevs"}="$_pooldisks{'slogdev2'}{id}";				
				$_pools{$_masterpoolid}{nr_slog_devs}=1;
				$_pools{$_masterpoolid}{"slogoptionlong"}="single_second";
				$_pools{$_masterpoolid}{"slog1"}="none";
				$_pools{$_masterpoolid}{"slog2"}=$_pooldisks{'slogdev2'}{id};
			}
			elsif ($_current_slogoption=~/str/)
			{
				$_command.=" log $_pooldisks{'slogdev'}{id} $_pooldisks{'slogdev2'}{id} ";
				$_pools{$_masterpoolid}{vdevs}{"slogdevs"}="stripe $_pooldisks{'slogdev'}{id} $_pooldisks{'slogdev2'}{id}";				
				$_pools{$_masterpoolid}{nr_slog_devs}=2;
				$_pools{$_masterpoolid}{"slogoptionlong"}="stripe_both";
				$_pools{$_masterpoolid}{"slog1"}=$_pooldisks{'slogdev'}{id};
			}
			elsif ($_current_slogoption=~/mirror/)
			{
				$_command.=" log mirror $_pooldisks{'slogdev'}{id} $_pooldisks{'slogdev2'}{id} ";
				$_pools{$_masterpoolid}{vdevs}{"slogdevs"}="mirror $_pooldisks{'slogdev'}{id} $_pooldisks{'slogdev2'}{id}";				
				$_pools{$_masterpoolid}{nr_slog_devs}=2;
				$_pools{$_masterpoolid}{"slogoptionlong"}="mirror_both";
				$_pools{$_masterpoolid}{"slog1"}=$_pooldisks{'slogdev'}{id};
				$_pools{$_masterpoolid}{"slog2"}=$_pooldisks{'slogdev2'}{id};
			}
			else
			{
				$_pools{$_masterpoolid}{"slogoptionlong"}="none";
				$_pools{$_masterpoolid}{"slog1"}="none";
				$_pools{$_masterpoolid}{"slog2"}="none";
			}
			#### /This section handles the L2Arc and SLOG devices


		}
		else
		{
			#$_command ="zpool add -n $_pool mirror ${disk1} ${disk2}";
			$_command ="zpool add $_pool $_type_tech ${_disks}" unless $force_pool_creation;
			$_command ="zpool add -f $_pool $_type_tech ${_disks}" if  $force_pool_creation;
		}

		&_print_log(3, "$_command\n");
		push @log_master_command_list, $_command;
		my $_currentts_pre=time();
		&_exec_command("$_command");
		my $_currentts_post=time();
		my $diff=$_currentts_post-$_currentts_pre;
		&_print_log(3, "Last pool action took $diff seconds\n");
		$_currentvdev++;

	}

	$_historic_pool_list{$_pool}=$_masterpoolid;
	&_create_datasets($_masterpoolid); #create datasets within this pool
	&_run_tests($_masterpoolid); # run tests on all datasets of this pool
	&_destroy_datasets($_masterpoolid);	#remove this pools datasets
	&_destroy_pool($_masterpoolid) unless $userpool_do;	 # remove this pool
	$_masterpoolid++;
	&_do_regular_output('pool');

}

#this sub assumes that all disks are empty and not in any pool
#it will create a mirror pool with the given amount of vdevs in total, starting with 1 vdev
#it will then call the test subroutine
#after all tests are done, the files and datasets are wiped
#if not all vdevs have been created another vdev is created and added to the existing pool
#rinse and repeat untill all vdevs have been created and all tests have been run
#then tear down the pool, cleaning the disks for the next pool type or end of testing


#destroy a zpool - this must have been sanitized before
sub _destroy_pool()
{
	my $_poolid = $_[0];
	my ($_command,$_pool);
	$_pool=$_pools{$_poolid}{name};
	$_command="zpool destroy $_pool";
	&_print_log(2, "Destroying pool $_pool with \"$_command\"\n");
	push @log_master_command_list, $_command;
	&_exec_command("$_command");
	$_pools{$_poolid}{status}=0; #set pool inactive
}

sub _destroy_datasets()
{
	my $_poolid = $_[0];
	my ($_command, $dslong);

	foreach my $dsid (keys %{$_pools{$_poolid}{datasets}})
	{
		$dslong=$_datasets{$dsid}{name};
		next unless ($_datasets{$dsid}{status}); #skip dataset if already inactive

		$_command="zfs destroy $dslong";
		&_print_log(2, "Destroying dataset $dslong (id $dsid) with \"$_command\"\n");
		push @log_master_command_list, $_command;
		&_exec_command("$_command");
		$_datasets{$dsid}{status}=0; #set dataset inactive
	}

}

#create a bunch of datasets for the various tests we want to perform
# options can be
#		sync, nosnyc
#		compression
#		recordsize
# zfs set redundant_metadata=most
# zfs create Tank1/disabled
# zfs set recordsize=128k compression=off sync=disabled Tank1/disabled
# dd if=/dev/zero of=$poolroot/Tank1/disabled/tmp.dat bs=2048k count=25k dd of=/dev/null if=$poolroot/Tank1/disabled/tmp.dat bs=2048k count=25k
# zfs destroy Tank1/disabled
#my @zfs_recordsizes = ("16k","32k","64k","128k","512k","1M");
#my @zfs_sync_options = ("always","disabled");
#my @zfs_compression_options = ("off");

sub _create_datasets()
{
	my $_poolid = $_[0];
	@_datasets=(); #reset
	my ($_command,$_rsize,$_so,$_co,$_mo,$_dsname);

	foreach $_rsize (@zfs_recordsizes)
	{
		foreach $_so (@zfs_sync_options)
		{
			#There are various combinations of slog and sync and we don't want/need to test all of them
			#slog can be 'no', 'sf', 'ss'  (part of pool name sno, ssf, sss)
			#sync can be 'always', 'disabled', 'standard' (in $_so)
			
			#example from output while running with 'no','sf' and 'always','disabled'
			#slogoption	slog1	slog2	sync
			#none	none	none	always
			#none	none	none	disabled
			#single_first	/dev/pmem0	none	always 
			#single_first	/dev/pmem0	none	disabled <--- useless
			#=>if slog options contain 'no' and current pool contains slog then skip 'sync option disaled' in order so save a run
			if (($_so=~/disabled/i) and ( "no" ~~ @user_slogoptions ) and ($_pools{$_poolid}{name}!~/sno/)  )
			{
				&_print_log(3, "Skipping sync option disabled due to existence of no slog test\n");
				next;
			}


			
			foreach $_co (@zfs_compression_options)
			{
				foreach $_mo (@zfs_metadata_options)
				{				
					$_dsname="$_pools{$_poolid}{name}/ds_${_rsize}_sync-${_so}_compr-${_co}-${_mo}";
					$_datasets{$_masterdsid}{name}=$_dsname;
					$_datasets{$_masterdsid}{poolid}=$_poolid;
					$_datasets{$_masterdsid}{name_short}="ds_${_rsize}_sync-${_so}_compr-${_co}";
					$_pools{$_poolid}{datasets}{$_masterdsid}=$_dsname; #link dataset to pool in poolhash
					push @_datasets, $_dsname;
					
					#split into single commands to accomodate ZoL (FreeBSD can run this in one)
					$_command="zfs create $_dsname && zfs set recordsize=$_rsize $_dsname";
					&_print_log(3, "Creating dataset $_dsname\n");
					&_print_log(4, "Creating datasets with \"$_command\"\n");
					push @log_master_command_list, $_command;
					&_exec_command("$_command");
					
					$_command="zfs set sync=$_so $_dsname";
					&_print_log(3, "Creating dataset $_dsname\n");
					&_print_log(4, "Creating datasets with \"$_command\"\n");
					push @log_master_command_list, $_command;
					&_exec_command("$_command");
					
					$_command="zfs set compression=$_co $_dsname";
					&_print_log(3, "Creating dataset $_dsname\n");
					&_print_log(4, "Creating datasets with \"$_command\"\n");
					push @log_master_command_list, $_command;
					&_exec_command("$_command");
					
					$_command="zfs set redundant_metadata=$_mo $_dsname";
					&_print_log(3, "Creating dataset $_dsname\n");
					&_print_log(4, "Creating datasets with \"$_command\"\n");
					push @log_master_command_list, $_command;
					&_exec_command("$_command");

					$_datasets{$_masterdsid}{dsinfo}{zfs_recordsizes}=$_rsize;
					$_datasets{$_masterdsid}{dsinfo}{zfs_sync_options}=$_so;
					$_datasets{$_masterdsid}{dsinfo}{zfs_compression_options}=$_co;
					$_datasets{$_masterdsid}{dsinfo}{zfs_metadata_options}=$_mo;
					$_datasets{$_masterdsid}{status}=1; #set dataset active - necessary since the same dataset can be created multiple times on different tests. The unique id remains for documentation reason on destroy while the ds gets removed, but this can cause issues on a later removal attempt.

					$_masterdsid++;
				}
			}
		}
	}
	@_report_datasets = @_datasets;

}

#run the diskinfo test on all given drives
sub _run_diskinfo_test
{	
	my ($name,$type);
	foreach my $_d (sort keys %_pooldisks)
	{
		if ($_d=~/^\d+$/)
		{
			$type="data";
		}
		else
		{
			 $type=$_d;
		}
		$name="$_pooldisks{$_d}{'id'}";
		&_print_log(1, "Running diskinfo test for $name (type=$type) - this takes about a minute per disk\n");
		my $diskinfofile="diskinfo$name";
		$diskinfofile=~tr/\//_/;
		
		#print "run_diskinfo_test: Will work on $name (type=$type)\n";
		my $logcommand="$diskinfo_command $_pooldisks{$_d}{'id'} |tee -a $logpath/$diskinfofile";
		push @log_master_command_list, $logcommand;
		&_exec_command("$logcommand");		
		my %a=&_parse_diskinfo_test_files("$logpath/$diskinfofile");
		$diskinfo_testresults{$_d}{name}=$name;
		$diskinfo_testresults{$_d}{type}=$type;
		$diskinfo_testresults{$_d}{results}=\%a;
	}
	#print Dumper \%diskinfo_testresults;
	#&_print_hash_generic(\%diskinfo_testresults, []);
	
}

sub _parse_diskinfo_test_files
{
	my $file2parse = $_[0];
	
	my %diskinfo_results;
	$diskinfo_results{info}{sectorsize} = 'none';
	$diskinfo_results{info}{mediasize_in_bytes} = 'none';
	$diskinfo_results{info}{mediasize_in_sectors} = 'none';
	$diskinfo_results{info}{stripesize} = 'none';
	$diskinfo_results{info}{stripeoffset} = 'none';
	$diskinfo_results{info}{Cylinders} = 'none';
	$diskinfo_results{info}{Heads} = 'none';
	$diskinfo_results{info}{Sectors} = 'none';
	$diskinfo_results{info}{description} = 'none';
	$diskinfo_results{info}{identifier} = 'none';
	$diskinfo_results{info}{TRIM_Support} = 'none';
	$diskinfo_results{info}{RPM} = 'none';
	$diskinfo_results{info}{ZoneMode} = 'none';
	$diskinfo_results{iooverhead}{"10MBblock"}{time} = 'none';
	$diskinfo_results{iooverhead}{"10MBblock"}{persector} = 'none';
	$diskinfo_results{iooverhead}{"20480sectors"}{time} = 'none';
	$diskinfo_results{iooverhead}{"20480sectors"}{persector} = 'none';
	$diskinfo_results{iooverhead}{overhead}{persector} = 'none';
	$diskinfo_results{seektimes}{Fullstroke}{totaltime} = 'none';
	$diskinfo_results{seektimes}{Fullstroke}{periter} = 'none';
	$diskinfo_results{seektimes}{Halfstroke}{totaltime} = 'none';
	$diskinfo_results{seektimes}{Halfstroke}{periter} = 'none';
	$diskinfo_results{seektimes}{Quarterstroke}{totaltime} = 'none';
	$diskinfo_results{seektimes}{Quarterstroke}{periter} = 'none';
	$diskinfo_results{seektimes}{Shortforward}{totaltime} = 'none';
	$diskinfo_results{seektimes}{Shortforward}{periter} = 'none';
	$diskinfo_results{seektimes}{Shortbackward}{totaltime} = 'none';
	$diskinfo_results{seektimes}{Shortbackward}{periter} = 'none';
	$diskinfo_results{seektimes}{Seqouter}{totaltime} = 'none';
	$diskinfo_results{seektimes}{Seqouter}{periter} = 'none';
	$diskinfo_results{seektimes}{Seqinner}{totaltime} = 'none';
	$diskinfo_results{seektimes}{Seqinner}{periter} = 'none';
	$diskinfo_results{transferrate}{outside}{totaltime} = 'none';
	$diskinfo_results{transferrate}{outside}{persec} = 'none';
	$diskinfo_results{transferrate}{middle}{totaltime} = 'none';
	$diskinfo_results{transferrate}{middle}{persec} = 'none';
	$diskinfo_results{transferrate}{inside}{totaltime} = 'none';
	$diskinfo_results{transferrate}{inside}{persec} = 'none';
	$diskinfo_results{asyncrandomread}{sectorsize}{ops} = 'none';
	$diskinfo_results{asyncrandomread}{sectorsize}{totaltime} = 'none';
	$diskinfo_results{asyncrandomread}{sectorsize}{IOPS} = 'none';
	$diskinfo_results{asyncrandomread}{"4k"}{ops} = 'none';
	$diskinfo_results{asyncrandomread}{"4k"}{totaltime} = 'none';
	$diskinfo_results{asyncrandomread}{"4k"}{IOPS} = 'none';
	$diskinfo_results{asyncrandomread}{"32k"}{ops} = 'none';
	$diskinfo_results{asyncrandomread}{"32k"}{totaltime} = 'none';
	$diskinfo_results{asyncrandomread}{"32k"}{IOPS} = 'none';
	$diskinfo_results{asyncrandomread}{"128k"}{ops} = 'none';
	$diskinfo_results{asyncrandomread}{"128k"}{totaltime} = 'none';
	$diskinfo_results{asyncrandomread}{"128k"}{IOPS} = 'none';
	$diskinfo_results{syncrandomwrite}{"0.5k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"0.5k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"1k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"1k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"2k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"2k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"4k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"4k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"8k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"8k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"16k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"16k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"32k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"32k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"64k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"64k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"128k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"128k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"256k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"256k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"512k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"512k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"1024k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"1024k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"2048k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"2048k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"4096k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"4096k"}{mbytes} = 'none';
	$diskinfo_results{syncrandomwrite}{"8192k"}{time} = 'none';
	$diskinfo_results{syncrandomwrite}{"8192k"}{mbytes} = 'none';



	open my $in, '<', "$file2parse" or die "parse diskinfo file: Could not find $file2parse\n";
	foreach my $line (<$in>)
	{
		next if ($line=~/^command/);
		next if ($line=~/^\s*$/); #skip empty lines

		next if ($line=~/^\/dev\//); #skip disk line
	#parse diskinfo
	#/dev/da3
	#        512             # sectorsize
	#        1600321314816   # mediasize in bytes (1.5T)
	#        3125627568      # mediasize in sectors
	#        4096            # stripesize
	#        0               # stripeoffset
	#        194561          # Cylinders according to firmware.
	#        255             # Heads according to firmware.
	#        63              # Sectors according to firmware.
	#        ATA INTEL SSDSC2BX01    # Disk descr.
	#        BTHC6486018N1P6PGN      # Disk ident.
	#        Yes             # TRIM/UNMAP support
	#        0               # Rotation rate in RPM
	#        Not_Zoned       # Zone Mode
				$diskinfo_results{info}{sectorsize} = $1 if ($line=~/^\s+(\d+)\s+\#\ssectorsize$/);
				$diskinfo_results{info}{mediasize_in_bytes} = $1 if ($line=~/^\s+(\d+)\s+\#\smediasize in bytes/);
				$diskinfo_results{info}{mediasize_in_sectors} = $1 if ($line=~/^\s+(\d+)\s+\#\smediasize in sectors/);
				$diskinfo_results{info}{stripesize} = $1 if ($line=~/^\s+(\d+)\s+\#\sstripesize/);
				$diskinfo_results{info}{stripeoffset} = $1 if ($line=~/^\s+(\d+)\s+\#\sstripeoffset/);
				$diskinfo_results{info}{Cylinders} = $1 if ($line=~/^\s+(\d+)\s+\#\sCylinders according to firmware/);
				$diskinfo_results{info}{Heads} = $1 if ($line=~/^\s+(\d+)\s+\#\sHeads according to firmware/);
				$diskinfo_results{info}{Sectors} = $1 if ($line=~/^\s+(\d+)\s+\#\sSectors according to firmware/);
				$diskinfo_results{info}{description} = $1 if ($line=~/^\s+(.+?)\s{2,}\#\sDisk descr/);
				$diskinfo_results{info}{identifier} = $1 if ($line=~/^\s+(.+?)\s+\#\sDisk ident/);
				$diskinfo_results{info}{TRIM_Support} = $1 if ($line=~/^\s+(\d+)\s+\#\sTRIM\/UNMAP support/);
				$diskinfo_results{info}{RPM} = $1 if ($line=~/^\s+(\d+)\s+\#\sRotation rate in RPM/);
				$diskinfo_results{info}{ZoneMode} = $1 if ($line=~/^\s+(\d+)\s+\#\sZone Mode/);
		
	#I/O command overhead:
	#        time to read 10MB block      0.025584 sec       =    0.001 msec/sector
	#        time to read 20480 sectors   2.921472 sec       =    0.143 msec/sector
	#        calculated command overhead                     =    0.141 msec/sector	
		
		next if ($line=~/I\/O command overhead:/);
		if ($line=~/^\s+time to read 10MB block\s+(.+) sec\s+=\s+(.+?)\smsec\/sector$/)
		{
			$diskinfo_results{iooverhead}{"10MBblock"}{time} = $1;
			$diskinfo_results{iooverhead}{"10MBblock"}{persector} = $2;
		}
		if ($line=~/^\s+time to read 20480 sectors\s+(.+) sec\s+=\s+(.+?)\smsec\/sector$/)
		{
			$diskinfo_results{iooverhead}{"20480sectors"}{time} = $1;
			$diskinfo_results{iooverhead}{"20480sectors"}{persector} = $2;
		}
		if ($line=~/^\s+calculated command overhead\s+=\s+(.+?)\smsec\/sector$/)
		{
			$diskinfo_results{iooverhead}{overhead}{persector} = $1;
		}

	#Seek times:
	#        Full stroke:      250 iter in   0.016277 sec =    0.065 msec
	#        Half stroke:      250 iter in   0.010561 sec =    0.042 msec
	#        Quarter stroke:   500 iter in   0.018194 sec =    0.036 msec
	#        Short forward:    400 iter in   0.014097 sec =    0.035 msec
	#        Short backward:   400 iter in   0.014219 sec =    0.036 msec
	#        Seq outer:       2048 iter in   0.065625 sec =    0.032 msec
	#        Seq inner:       2048 iter in   0.072317 sec =    0.035 msec
		next if ($line=~/Seek times:/);
		
		if ($line=~/^\s+Full stroke:\s+250 iter in \s+(.+?) sec = \s+(.+?) msec$/)
		{
			$diskinfo_results{seektimes}{Fullstroke}{totaltime} = $1;
			$diskinfo_results{seektimes}{Fullstroke}{periter} = $2;
		}
		if ($line=~/^\s+Half stroke:\s+250 iter in \s+(.+?) sec = \s+(.+?) msec$/)
		{
			$diskinfo_results{seektimes}{Halfstroke}{totaltime} = $1;
			$diskinfo_results{seektimes}{Halfstroke}{periter} = $2;
		}
		if ($line=~/^\s+Quarter stroke:\s+500 iter in \s+(.+?) sec = \s+(.+?) msec$/)
		{
			$diskinfo_results{seektimes}{Quarterstroke}{totaltime} = $1;
			$diskinfo_results{seektimes}{Quarterstroke}{periter} = $2;
		}
		if ($line=~/^\s+Short forward:\s+400 iter in \s+(.+?) sec = \s+(.+?) msec$/)
		{
			$diskinfo_results{seektimes}{Shortforward}{totaltime} = $1;
			$diskinfo_results{seektimes}{Shortforward}{periter} = $2;
		}
		if ($line=~/^\s+Short backward:\s+400 iter in \s+(.+?) sec = \s+(.+?) msec$/)
		{
			$diskinfo_results{seektimes}{Shortbackward}{totaltime} = $1;
			$diskinfo_results{seektimes}{Shortbackward}{periter} = $2;
		}
		if ($line=~/^\s+Seq outer:\s+2048 iter in \s+(.+?) sec = \s+(.+?) msec$/)
		{
			$diskinfo_results{seektimes}{Seqouter}{totaltime} = $1;
			$diskinfo_results{seektimes}{Seqouter}{periter} = $2;
		}
		if ($line=~/^\s+Seq inner:\s+2048 iter in \s+(.+?) sec = \s+(.+?) msec$/)
		{
			$diskinfo_results{seektimes}{Seqinner}{totaltime} = $1;
			$diskinfo_results{seektimes}{Seqinner}{periter} = $2;
		}
		
		#Transfer rates:
	#        outside:       102400 kbytes in   0.286891 sec =   356930 kbytes/sec
	#        middle:        102400 kbytes in   0.236237 sec =   433463 kbytes/sec
	#        inside:        102400 kbytes in   0.240426 sec =   425911 kbytes/sec
		next if ($line=~/Transfer rates:/);
		if ($line=~/^\s+outside:\s+102400 kbytes in\s+(.+?) sec =\s+(\d+?) kbytes\/sec$/)
		{
			$diskinfo_results{transferrate}{outside}{totaltime} = $1;
			$diskinfo_results{transferrate}{outside}{persec} = $2;
		}
		if ($line=~/^\s+middle:\s+102400 kbytes in\s+(.+?) sec =\s+(\d+?) kbytes\/sec$/)
		{
			$diskinfo_results{transferrate}{middle}{totaltime} = $1;
			$diskinfo_results{transferrate}{middle}{persec} = $2;
		}
		if ($line=~/^\s+middle:\s+102400 kbytes in\s+(.+?) sec =\s+(\d+?) kbytes\/sec$/)
		{
			$diskinfo_results{transferrate}{inside}{totaltime} = $1;
			$diskinfo_results{transferrate}{inside}{persec} = $2;
		}

	#Asynchronous random reads:
	#        sectorsize:    382560 ops in    3.001052 sec =   127475 IOPS
	#        4 kbytes:      255215 ops in    3.001556 sec =    85028 IOPS
	#        32 kbytes:      48687 ops in    3.007896 sec =    16186 IOPS
	#        128 kbytes:     13054 ops in    3.029678 sec =     4309 IOPS

		next if ($line=~/Asynchronous random reads:/);
		if ($line=~/^\s+sectorsize:\s+(\d+) ops in \s+(.+?) sec =\s+(\d+?) IOPS$/)
		{
			$diskinfo_results{asyncrandomread}{sectorsize}{ops} = $1;
			$diskinfo_results{asyncrandomread}{sectorsize}{totaltime} = $2;
			$diskinfo_results{asyncrandomread}{sectorsize}{IOPS} = $3;		
		}
		if ($line=~/^\s+4 kbytes:\s+(\d+) ops in \s+(.+?) sec =\s+(\d+?) IOPS$/)
		{
			$diskinfo_results{asyncrandomread}{"4k"}{ops} = $1;
			$diskinfo_results{asyncrandomread}{"4k"}{totaltime} = $2;
			$diskinfo_results{asyncrandomread}{"4k"}{IOPS} = $3;		
		}
		if ($line=~/^\s+32 kbytes:\s+(\d+) ops in \s+(.+?) sec =\s+(\d+?) IOPS$/)
		{
			$diskinfo_results{asyncrandomread}{"32k"}{ops} = $1;
			$diskinfo_results{asyncrandomread}{"32k"}{totaltime} = $2;
			$diskinfo_results{asyncrandomread}{"32k"}{IOPS} = $3;		
		}
		if ($line=~/^\s+128 kbytes:\s+(\d+) ops in \s+(.+?) sec =\s+(\d+?) IOPS$/)
		{
			$diskinfo_results{asyncrandomread}{"128k"}{ops} = $1;
			$diskinfo_results{asyncrandomread}{"128k"}{totaltime} = $2;
			$diskinfo_results{asyncrandomread}{"128k"}{IOPS} = $3;		
		}

	#Synchronous random writes:
	#         0.5 kbytes:    303.7 usec/IO =      1.6 Mbytes/s
	#           1 kbytes:    283.3 usec/IO =      3.4 Mbytes/s
	#           2 kbytes:    250.7 usec/IO =      7.8 Mbytes/s
	#           4 kbytes:    159.7 usec/IO =     24.5 Mbytes/s
	#           8 kbytes:    171.0 usec/IO =     45.7 Mbytes/s
	#          16 kbytes:    206.3 usec/IO =     75.7 Mbytes/s
	#          32 kbytes:    239.1 usec/IO =    130.7 Mbytes/s
	#          64 kbytes:    315.8 usec/IO =    197.9 Mbytes/s
	#         128 kbytes:    466.7 usec/IO =    267.8 Mbytes/s
	#         256 kbytes:    735.0 usec/IO =    340.2 Mbytes/s
	#         512 kbytes:   1225.1 usec/IO =    408.1 Mbytes/s
	#        1024 kbytes:   2314.0 usec/IO =    432.1 Mbytes/s
	#        2048 kbytes:   4345.3 usec/IO =    460.3 Mbytes/s
	#        4096 kbytes:   8462.8 usec/IO =    472.7 Mbytes/s
	#        8192 kbytes:  16869.4 usec/IO =    474.2 Mbytes/s

		next if ($line=~/Synchronous random writes:/);
		if ($line=~/^\s+0.5 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"0.5k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"0.5k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+1 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"1k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"1k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+2 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"2k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"2k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+4 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"4k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"4k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+8 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"8k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"8k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+16 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"16k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"16k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+32 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"32k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"32k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+64 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"64k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"64k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+128 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"128k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"128k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+256 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"256k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"256k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+512 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"512k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"512k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+1024 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"1024k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"1024k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+2048 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"2048k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"2048k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+4096 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"4096k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"4096k"}{mbytes} = $2;		
		}
		if ($line=~/^\s+8192 kbytes:\s+(.+?) usec\/IO =\s+(\d+\.\d+) Mbytes\/s$/)
		{		
			$diskinfo_results{syncrandomwrite}{"8192k"}{time} = $1;
			$diskinfo_results{syncrandomwrite}{"8192k"}{mbytes} = $2;		
		}

	}
	close $in;
		
	return 	%diskinfo_results;
}




#convert an inut value with K/M/G to a byte value
sub _get_as_bytes()
{
	my $inputsize = $_[0];
	my $outputsize;
	$outputsize=0 if ($inputsize=~/^\s+$/i); #set output to 0 if input is blank
	$outputsize=$inputsize if ($inputsize=~/^\d+$/i); #no conversion if input is already pure number
	$outputsize=1024*$1 if ($inputsize=~/(\d+(\.\d+)?)K/i);
	$outputsize=1024*1024*$1 if ($inputsize=~/(\d+(\.\d+)?)M/i);
	$outputsize=1024*1024*1024*$1 if ($inputsize=~/(\d+(\.\d+)?)G/i);
	&_print_log(4, "Converting \"$inputsize\" to $outputsize\n");
	return $outputsize;
}

#assuming we get bytes and want something more readable
sub _get_as()
{
	my ($inputsize,$target)= ($_[0],$_[1]);
	my $outputsize;
	&_print_log(4, "Converting \"$inputsize\" to $target\n");
	$outputsize=$inputsize/1024 if ($target=~/K/i);
	$outputsize=$inputsize/1024/1024 if ($target=~/M/i);
	$outputsize=$inputsize/1024/1024/1024 if ($target=~/G/i);

	return $outputsize;
}
#Convert between . and , as separator
sub _localize_numbers()
{
	my $input= $_[0];
	return $input if ($input =~/none/); # error while running diskinfo causing this
	my $tmp=sprintf("%.2f", $input);
	my $outputsize_localized=$tmp;
	if ($use_sep=~/,/)
	{
		$outputsize_localized=~s/\./,/g;
	}
	&_print_log(4, "localizing \"$input\", \"$tmp\" to $outputsize_localized\n");
	return $outputsize_localized;
}


#limit usable arc size via sysctl vfs.zfs.arc_min/max/meta_limit
# or turn off entirely - zfs set primarycache=metadata $vdev

sub _set_arc_limit()
{
	my ($factor,$newarcsize,$_command);
	
	#get current values
	#$_command="sysctl vfs.zfs.arc_min && sysctl vfs.zfs.arc_max && sysctl vfs.zfs.arc_meta_limit";   #meta limit does not seem to exist any more
	$_command="sysctl vfs.zfs.arc_min && sysctl vfs.zfs.arc_max";
	push @log_master_command_list, $_command;
	@oldarcsettings= &_exec_command("$_command");
	&_print_log(3, "Old arc settings: ", join " ", @oldarcsettings, "\n");
	foreach my $oa (@oldarcsettings)
	{
		$_SystemInfo{arc}{min}=$1 if ($oa=~/arc_min:\s(\d+)$/);
		$_SystemInfo{arc}{max}=$1 if ($oa=~/arc_max:\s(\d+)$/);
		#$_SystemInfo{arc}{limit}=$1 if ($oa=~/arc_meta_limit:\s(\d+)$/);
	}
	if ($arc_limit_do)
	{
		$newarcsize=&_get_as_bytes($arc_limit);
		&_print_log(2, "limiting arc size to $arc_limit ($newarcsize bytes)\n");

		#set min value first
		#$_command="sysctl vfs.zfs.arc_min=$newarcsize && sysctl vfs.zfs.arc_max=$newarcsize && sysctl vfs.zfs.arc_meta_limit=$newarcsize";
		$_command="sysctl vfs.zfs.arc_min=$newarcsize && sysctl vfs.zfs.arc_max=$newarcsize";
		&_print_log(3, "_command is $_command\n");
		push @log_master_command_list, $_command;
		&_exec_command("$_command");
		$_SystemInfo{arc_min}=$newarcsize;
		$_SystemInfo{arc_max}=$newarcsize;
		#$_SystemInfo{arc_limit}=$newarcsize;
	}
	else
	{
		&_print_log(2, "Not limiting arc size\n");
	}
	$_out_masterreport_info{_0_SystemInfo}{4}{key}='arc_min';
	$_out_masterreport_info{_0_SystemInfo}{4}{label_short}='ArcMin';
	$_out_masterreport_info{_0_SystemInfo}{4}{label_long}='Minimum Arcsize';
	$_out_masterreport_info{_0_SystemInfo}{4}{isstring}='0';
	$_out_masterreport_info{_0_SystemInfo}{4}{needs_output_conversion_comma}=0;
	$_out_masterreport_info{_0_SystemInfo}{4}{needs_output_conversion_unit}=1;
	$_out_masterreport_info{_0_SystemInfo}{4}{isunit}='byte';
	$_out_masterreport_info{_0_SystemInfo}{5}{key}='arc_max';
	$_out_masterreport_info{_0_SystemInfo}{5}{label_short}='ArcMax';
	$_out_masterreport_info{_0_SystemInfo}{5}{label_long}='Maximum Arcsize';
	$_out_masterreport_info{_0_SystemInfo}{5}{isstring}='0';
	$_out_masterreport_info{_0_SystemInfo}{5}{needs_output_conversion_comma}=0;
	$_out_masterreport_info{_0_SystemInfo}{5}{needs_output_conversion_unit}=1;
	$_out_masterreport_info{_0_SystemInfo}{5}{isunit}='byte';
	#$_out_masterreport_info{_0_SystemInfo}{6}{key}='arc_limit';
	#$_out_masterreport_info{_0_SystemInfo}{6}{label_short}='ArcMLimit';
	#$_out_masterreport_info{_0_SystemInfo}{6}{label_long}='Arcsize Meta Limit';
	#$_out_masterreport_info{_0_SystemInfo}{6}{isstring}='0';
	#$_out_masterreport_info{_0_SystemInfo}{6}{needs_output_conversion_comma}=0;
	#$_out_masterreport_info{_0_SystemInfo}{6}{needs_output_conversion_unit}=1;
	#$_out_masterreport_info{_0_SystemInfo}{6}{isunit}='byte';
}

sub _set_skip_trim()
{
	my ($_command);
	if ($skip_trim_on_create)
	{
		&_print_log(2, "Setting Skip Trim\n");


		#set min value first
		$_command="sysctl vfs.zfs.vdev.trim_on_init=0";
		&_print_log(3, "_command is $_command\n");
		push @log_master_command_list, $_command;
		&_exec_command("$_command");

	}
}


sub _start_temp_capturing
{
	my ($outputfile, $stayalivefile)= ($_[0],$_[1]);

	# Fork child process - temp Worker
	my $pid = fork();
	my $_lastts=0;
	my $logcommand;

	# Check if parent/child process
	if ($pid) # Parent
	{
	  return $pid;
	}
	elsif ($pid == 0) # Child
	{
		`touch $stayalivefile`;
		&_print_log(3, "\tChild $$ Running temp check now \n");
		while (-e $stayalivefile)
		{

			&_get_drive_temps($_lastts, "$outputfile");
			$_lastts=time();
			sleep($user_gettemps_interval);

		}
		exit 0;
	}
	else
	{ # Unable to fork
	  die "ERROR: Could not fork new process at _start_temp_capturing: $!\n\n";
	}
}

sub _stop_temp_capturing
{
	my ($stayalivefile)= ($_[0]);
	&_print_log(4, "\tStopping temp capturing now \n");
	unlink $stayalivefile; # this should make child stop
}


sub _start_gstat_capturing
{
	my ($outputfile, $stayalivefile)= ($_[0],$_[1]);

	# Fork child process - gstat Worker
	my $pid = fork();
	my $_currentts;
	my $logcommand;

	# Check if parent/child process
	if ($pid) # Parent
	{
	  return $pid;
	}
	elsif ($pid == 0) # Child
	{
		`touch $stayalivefile`;
		&_print_log(3, "\tChild $$ Running gstat now \n");
		while (-e $stayalivefile)
		{
			$_currentts=time();
			$logcommand="echo $_currentts >> $outputfile && gstat -b |tee -a $outputfile";
			&_exec_command("$logcommand");
		#		$logcommand="echo $outputfile >> gstat$$";
		#	&_exec_command("$logcommand");
			sleep(1);
		}
		exit 0;
	}
	else
	{ # Unable to fork
	  die "ERROR: Could not fork new process at _start_gstat_capturing: $!\n\n";
	}
}

sub _stop_gstat_capturing
{
	my ($stayalivefile)= ($_[0]);
	&_print_log(4, "\tStopping gstat capturing now \n");
	unlink $stayalivefile; # this should make child stop
}


sub _start_iostat_capturing
{
	my ($_pool, $outputfile, $stayalivefile)= ($_[0],$_[1],$_[2]);

	# Fork child process - iostat  Worker
	my $pid = fork();
	my $_currentts;
	my $logcommand;

	# Check if parent/child process
	if ($pid) # Parent
	{
	  return $pid;
	}
	elsif ($pid == 0) # Child
	{
		`touch $stayalivefile`;
		&_print_log(3, "\tChild $$ Running iostat now \n");
		while (-e $stayalivefile)
		{
			$_currentts=time();

			$logcommand="echo $_currentts >> $outputfile && zpool iostat $_pool |tee -a $outputfile";
			&_exec_command("$logcommand");
				#$logcommand="echo $outputfile >> iostat$$";
			#&_exec_command("$logcommand");
			sleep(1);
		}
		exit 0;
	}
	else
	{ # Unable to fork
	  die "ERROR: Could not fork new process at _start_iostat_capturing: $!\n\n";
	}
}

sub _stop_iostat_capturing
{
	my ($stayalivefile)= ($_[0]);
	&_print_log(4, "\tStopping iostat capturing now \n");
	unlink $stayalivefile; # this should make child stop

}

sub _start_psaux_capturing
{
	my ($outputfile, $stayalivefile)= ($_[0],$_[1]);
	my $_currentts;
	my $logcommand;

# Fork child process - psaux Worker
	my $pid = fork();
	# Check if parent/child process
	if ($pid) # Parent
	{
	  return $pid;
	}
	elsif ($pid == 0) # Child
	{
		`touch $stayalivefile`;
		#&_print_log(3, "\tChild $$ Running PSAUX now \n");
		while (-e $stayalivefile)
		{
			$_currentts=time();
			#fio --filename=/mnt/p_sin_mir02_v04_o00_cno_sno/ds_64k_sync-disabled_compr-off/fio.o

			#$logcommand="echo $_currentts >> $outputfile";
			#&_exec_command("$logcommand");
			#$logcommand="ps aux |grep \"$grepitem\" |grep -v grep |grep -v sh |tee -a $outputfile";
			#&_exec_command("$logcommand");
			$logcommand="echo $_currentts >> $outputfile; ps auxS |grep \"fio --direct=1\" |grep -v grep |grep -v sh |tee -a $outputfile";
			&_exec_command("$logcommand");
			#$logcommand="ps aux |tee -a /tmp/psauxextra";
			#&_exec_command("$logcommand");
			#$logcommand="ps aux |grep \"$grepitem\"|tee -a /tmp/psauxextra2";
			#&_exec_command("$logcommand");
			#$logcommand="ps aux |grep \"$grepitem\"|grep -v grep |tee -a /tmp/psauxextra3";
			#&_exec_command("$logcommand");
			#$logcommand="ps aux |grep \"$grepitem\"|grep -v grep |grep -v sh |tee -a /tmp/psauxextra4";
			#&_exec_command("$logcommand");

			#$logcommand="echo \"$$, $_currentts, $logcommand\">> /tmp/psauxextra5";
			#&_exec_command("$logcommand");
			sleep(1);
		}
		exit 0;
	}
	else
	{ # Unable to fork
	  die "ERROR: Could not fork new process at _start_psaux_capturing: $!\n\n";
	}
}

sub _stop_psaux_capturing
{
	my ($stayalivefile)= ($_[0]);
	&_print_log(4, "\tStopping PSAUX capturing now \n");
	unlink $stayalivefile; # this should make child stop
}

#reset arc settings to old values
sub _reset_arc_limit()
{

#	vfs.zfs.arc_min: 904399872
# vfs.zfs.arc_max: 7235198976
# vfs.zfs.arc_meta_limit: 1808799744

	my ($old_minarcsize, $old_maxarcsize, $old_limit, $_command);

	if ($arc_limit_do)
	{
		foreach my $line (@oldarcsettings)
		{
			$old_minarcsize = $1 if ($line=~/vfs.zfs.arc_min:\s+(\d+)/);
			$old_maxarcsize = $1 if ($line=~/vfs.zfs.arc_max:\s+(\d+)/);
			$old_limit = $1 if ($line=~/vfs.zfs.arc_meta_limit:\s+(\d+)/);
		}
			&_print_log(2, "restoring old arc size\n");
			#set arc max first this time
			$_command="sysctl vfs.zfs.arc_max=$old_maxarcsize && sysctl vfs.zfs.arc_min=$old_minarcsize && sysctl vfs.zfs.arc_meta_limit=$old_limit";
			&_print_log(3, "_command is $_command\n");
			push @log_master_command_list, $_command;
			&_exec_command("$_command");

	}
}


# 3 will create an output file after each fio/dd test - note this adds significant overhead especially on short tests as this will run after each single test and will dump out all results each time
# 2 will do run the report after each dataset
# 1 will do run the report after each pool

sub _do_regular_output()
{
	my $clabel = $_[0];	
	
	if (&_check_report_requested)
	{
		&_create_output;
	}
	else
	{
	  &_create_output if (($clabel =~/test/) && ($_do_regular_output == 3));
	  &_create_output if (($clabel =~/dataset/) && ($_do_regular_output == 2));
	  &_create_output if (($clabel =~/pool/) && ($_do_regular_output == 1));
	}
		
}





#this sub will assemble the actual tests to be run, eg dd, fio
sub _run_tests()
{
	my $_poolid = $_[0];
	my $dsid=0;
	$dsnr=0; #counting datasets
	$dstotal= scalar (keys %{$_pools{$_poolid}{datasets}});
	&_print_log(2, "Called RunTests for $_pools{$_poolid}{name}\n");
	$totaltests=&_get_total_tests;

	#get all datasets in the given pool
	foreach $dsid (sort keys %{$_pools{$_poolid}{datasets}})
	{
		$dsnr++;
		next unless ($_datasets{$dsid}{status}); #skip dataset if inactive (of a previous run, has been destroyed and marked inactive)
		&_print_log(1, "Running on dataset $dsnr/$dstotal for pool $_pools{$_poolid}{name}\n");
		if ($dd_do)
		{
		 	&_run_dd($dsid) unless $stop_requested;
		}
		else
		{
		 	&_print_log(2, "Skipped DD for $_datasets{$dsid}{name_short}\n")  unless $stop_requested; #no annoying skip dd msg
		}

		if ($fio_do)
		{			
		 	&_run_fio($dsid) unless $stop_requested;
		}
		else
		{
		 	&_print_log(2, "Skipped Fio for $_datasets{$dsid}{name_short}\n") unless $stop_requested; #no annoying skip fio msg
		}
		&_do_regular_output('dataset');
	}
}

#this function checks whether we have selected to loop over fio options or if the user has selected to provide tests manually
sub _determine_fio_tests
{
	my @_fio_auto_loop_tests;
	@fio_tests=(); #reset tests

	my $_fio_current_test=1;
	
	if ($fio_run_automated_loop)
	{
		foreach my $_bs (@fio_bs)
		{
			my $_fio_testl1="--bs=$_bs ";
			foreach my $_iod (@fio_iodepth)
			{
				my $_fio_testl2=$_fio_testl1. "--iodepth=$_iod ";
				foreach my $_nj (@fio_numjobs)
				{
					my $_fio_testl3=$_fio_testl2. "--numjobs=$_nj ";
					foreach my $_testtype (@fio_testtype)
					{
						if ($_testtype =~/readwrite/ || $_testtype =~/rw/ || $_testtype =~/randrw/)
						{
							#we need to add the rw percentages
							foreach my $_rwpct (@fio_test_rw_pcts)
							{
								my $_fio_testl4=$_fio_testl3. "--rw=$_testtype --rwmixread=$_rwpct ";
								push @_fio_auto_loop_tests, $_fio_testl4;

								$fio_tests_info{$_fio_current_test}{type}='auto';
								$fio_tests_info{$_fio_current_test}{bs}=$_bs;
								$fio_tests_info{$_fio_current_test}{iodepth}=$_iod;
								$fio_tests_info{$_fio_current_test}{numjobs}=$_nj;
								$fio_tests_info{$_fio_current_test}{testtype}=$_testtype;
								$fio_tests_info{$_fio_current_test}{rwmixread}=$_rwpct;
								$_fio_current_test++;
							}
						}
						else
						{
							my $_fio_testl4=$_fio_testl3. "--rw=$_testtype";
							push @_fio_auto_loop_tests, $_fio_testl4;
							$fio_tests_info{$_fio_current_test}{type}='auto';
							$fio_tests_info{$_fio_current_test}{bs}=$_bs;
							$fio_tests_info{$_fio_current_test}{iodepth}=$_iod;
							$fio_tests_info{$_fio_current_test}{numjobs}=$_nj;
							$fio_tests_info{$_fio_current_test}{testtype}=$_testtype;
							$fio_tests_info{$_fio_current_test}{rwmixread}=0;
							$_fio_current_test++;
						}
					}
				}
			}
		}
		@fio_tests=@_fio_auto_loop_tests;
	}
	else
	{
		@fio_tests=@fio_userdefined_tests;
		foreach my $usertest (@fio_userdefined_tests)
		{
			$fio_tests_info{$_fio_current_test}{type}='user';
			#"--bs=4K --rw=randwrite --iodepth=1 --numjobs=1",
			#"--bs=64K --rw=randwrite --iodepth=1 --numjobs=1",
			#"--bs=64K --rw=rw --iodepth=1 --numjobs=1",
			#"--bs=1M --rw=rw --iodepth=1 --numjobs=1"

			if ($usertest=~/--bs=(\d{1,}\w)/)
			{
				$fio_tests_info{$_fio_current_test}{bs}=$1;
			}
			if ($usertest=~/--rw=(\w+)/)
			{
				$fio_tests_info{$_fio_current_test}{testtype}=$1;
			}
			if ($usertest=~/--iodepth=(\d{1,})/)
			{
				$fio_tests_info{$_fio_current_test}{iodepth}=$1;
			}
			if ($usertest=~/--numjobs=(\d{1,})/)
			{
				$fio_tests_info{$_fio_current_test}{numjobs}=$1;
			}
			if ($usertest=~/--rwmixread=(\d{1,2})/)
			{
				$fio_tests_info{$_fio_current_test}{rwmixread}=$1;
			}
			elsif ($usertest=~/--rwmixwrite=(\d{1,2})/)
			{
				$fio_tests_info{$_fio_current_test}{rwmixread}=100-$1;
			}
			else
			{
				#default value if not specified
				$fio_tests_info{$_fio_current_test}{rwmixread}=50;
			}
			$_fio_current_test++;
		}
	}
	#now extract
	@_report_fiotests = @fio_tests;
	return scalar @fio_tests;
}


sub _run_fio()
{
	my ($dsid) =  ($_[0]);
	my (%pids,$_lastts,%async_paths,$fio_file_size_bytes);

	#fio --filename=\"$basepath_sync\"$filename --direct=1 --rw=randrw --refill_buffers --norandommap --randrepeat=0
	#--ioengine=posixaio --bs=$bs --rwmixread=0 --iodepth=$iod 	--numjobs=$jobs
	#--runtime=$runtime --group_reporting --name=$filename --size=$size $log";
	my $_dsname=$_datasets{$dsid}{name};
	my $_dsnameshort=$_datasets{$dsid}{name_short};
	my $_pool=$1 if ($_dsname=~/^(.+)\//); #or get it via pool id and name lookup
	my $dslong2=$_dsname;
	$dslong2=~tr/\//_/;
	$_lastts=0;
	$fio_file_size_bytes=&_get_as_bytes($fio_file_size);
	&_print_log(1, "Called RunFio for dataset $_dsnameshort (dataset $dsnr/$dstotal)\n");

	my $static_options=" --direct=1 --refill_buffers --norandommap --randrepeat=0 --group_reporting ";
	$static_options.="--ioengine=$fio_ioengine --name=\"$_dsname\" ";
	$static_options.=$fio_runtime?" --runtime=$fio_runtime":"";
	$static_options.=$fio_file_size?" --size=$fio_file_size":"";
	$static_options.=$fio_time_based?" --time_based ":"";
	
	&_print_log(3,"DS=$_dsname\n");
	&_print_log(4,"static_options=$static_options\n");
	my $datapath = $user_make_logs_persistent ?$logpath:"$poolroot/$_dsname";
	my $fiotestnr=1;

	foreach my $fiotest (@fio_tests)
	{
		last if &_check_stop_requested;
		&_check_runtimeinfo_requested();
		&_check_changeloglevel_requested();
		&_print_log(1, "$mastertestid/$totaltests (dataset $dsnr/$dstotal, pool $poolnr/$totalpools): Running fio Test $fiotestnr of ".scalar @fio_tests." on pool/dataset $_dsname \n");	
		$fiotests{$mastertestid}{info}{test}=$fiotest;
		$fiotests{$mastertestid}{info}{source}=$fio_tests_info{$fiotestnr}{type};
		$fiotests{$mastertestid}{info}{bs}=$fio_tests_info{$fiotestnr}{bs};
		$fiotests{$mastertestid}{info}{iodepth}=$fio_tests_info{$fiotestnr}{iodepth};
		$fiotests{$mastertestid}{info}{numjobs}=$fio_tests_info{$fiotestnr}{numjobs};
		$fiotests{$mastertestid}{info}{testtype}=$fio_tests_info{$fiotestnr}{testtype};
		$fiotests{$mastertestid}{info}{rwmixread}=$fio_tests_info{$fiotestnr}{rwmixread};
		
		$fiotests{$mastertestid}{info}{dsname}=$_dsname;		
		$fiotests{$mastertestid}{info}{dsname_short}=$_dsnameshort;		
		$fiotests{$mastertestid}{info}{fio_runs_per_test}=$fio_runs_per_test;
		$fiotests{$mastertestid}{info}{fio_file_size}=$fio_file_size;
		$fiotests{$mastertestid}{info}{fio_time_based}=$fio_time_based;		
		$fiotests{$mastertestid}{info}{fio_file_size_bytes}=$fio_file_size_bytes;
		$fiotests{$mastertestid}{info}{ioengine}=$fio_ioengine;
		$fiotests{$mastertestid}{info}{fio_runtime}=$fio_runtime;
		
		$fiotests{$mastertestid}{info}{dsid}=$dsid;
		$fiotests{$mastertestid}{info}{poolid}=$_datasets{$dsid}{poolid}; #add poolinfo to fiotests
		$_mastertestinfo{$mastertestid}{tool}='fio';
		$_mastertestinfo{$mastertestid}{dsid}=$dsid;
		$_mastertestinfo{$mastertestid}{poolid}=$_datasets{$dsid}{poolid};

		&_print_log(4,"Fio test ($fio_tests_info{$fiotestnr}{type}): $fiotest \n");

		for (my $run=1; $run <= $fio_runs_per_test; $run++)
	  {
	  	&_print_log(1, "Iteration $run / $fio_runs_per_test\n");	
	  	%pids=();
					#forking for fio is only done so we can run additional tools (gstat, iostat etc in parallel), not needed to simulate multiple instances/jobs like for dd
					######### Forking ###########

					my $logcommand;
					&_print_log(4,"aux=$user_runpsaux, iostat=$user_runzpooliostat, gstat=$user_rungstat, temps=$user_gettemps\n");

					my $async_basepath="${datapath}/${mastertestid}_${dslong2}_test${fiotestnr}_run${run}";
			    if ($user_runpsaux )
			    {
			    	#fio --filename=/mnt/p_sin_mir02_v04_o00_cno_sno/ds_64k_sync-disabled_compr-off/fio.o
			    	$async_paths{$dslong2}{psaux}{$run}{log}="${async_basepath}_psaux.log";
			    	$async_paths{$dslong2}{psaux}{$run}{alivefile}="${async_basepath}_psaux.run";
			    	$async_paths{$dslong2}{psaux}{$run}{pid}=&_start_psaux_capturing($async_paths{$dslong2}{psaux}{$run}{log},$async_paths{$dslong2}{psaux}{$run}{alivefile});			    	
					}
					if ($user_runzpooliostat)
			    {
			    	$async_paths{$dslong2}{iostat}{$run}{log}="${async_basepath}_iostat.log";
			    	$async_paths{$dslong2}{iostat}{$run}{alivefile}="${async_basepath}_iostat.run";
			    	$async_paths{$dslong2}{iostat}{$run}{pid}=&_start_iostat_capturing($_pool, $async_paths{$dslong2}{iostat}{$run}{log},$async_paths{$dslong2}{iostat}{$run}{alivefile});
					}
					if ($user_rungstat )
			    {
			    	$async_paths{$dslong2}{gstat}{$run}{log}="${async_basepath}_gstat.log";
			    	$async_paths{$dslong2}{gstat}{$run}{alivefile}="${async_basepath}_gstat.run";
			    	$async_paths{$dslong2}{gstat}{$run}{pid}=&_start_gstat_capturing($async_paths{$dslong2}{gstat}{$run}{log},$async_paths{$dslong2}{gstat}{$run}{alivefile});
					}
					if ($user_gettemps)
			    {
			    	$async_paths{$dslong2}{temp}{$run}{log}="${async_basepath}_temp.log";
			    	$async_paths{$dslong2}{temp}{$run}{alivefile}="${async_basepath}_temp.run";
			    	$async_paths{$dslong2}{temp}{$run}{pid}=&_start_temp_capturing($async_paths{$dslong2}{temp}{$run}{log},$async_paths{$dslong2}{temp}{$run}{alivefile});
					}

					my $_command="fio $static_options $fiotest --filename=$poolroot/$_dsname/fio_${run}.out --output $poolroot/$_dsname/fio_${run}_json.out --output-format=json 2>&1 |tee ${datapath}/fio_${run}.out";
					&_log_testcommand("fio $static_options $fiotest --filename=${poolroot}_${_dsname}_fio_${run}.out --output fio_${run}_json.out --output-format=json");
					&_print_log(3,"Fio: $_command\n");
					push @log_master_command_list, $_command;
					#&_exec_command("$_command");  #execution in fork

					# Fork child process
					my $pid = fork();

					# Check if parent/child process
					if ($pid) # Parent
					{
					  &_print_log(3, "RUN: $run -> Parent: Started fio worker Child with process id: $pid\n");
					  $pids{$pid}{active}=1;
					  $pids{$pid}{waiting}=0;
#					  $pids{$pid}{type}=$type;

					  $job2cpu{idstring}="--filename=$poolroot/$_dsname/fio.out";
					  $job2cpu{pid}=$pid;
#					  $job2cpu{$mastertestid}{$job}=$job;

					  $fiotests{$mastertestid}{details}{runs}{$run}{info}{pid}=$pid;
#					  $fiotests{$mastertestid}{details}{runs}{$run}{info}{jobs}{$job}{pid}=$pid;
					}
					elsif ($pid == 0) # Child
					{
						#now run fio in child
						&_print_log(3, "RUN: $run -> Child $$: Will now execute\n$_command\n");
						#`$_command`;
						&_exec_command("$_command");
						exit $?;
					}
					else
					{ # Unable to fork
					  die "ERROR: Could not fork new process: $!\n\n";
					}
					######### /Forking ###########
					#for waitpid
					my $stillWaiting;
					#/for waitpid

					do {			    		
							$stillWaiting = 0;
			    		foreach my $cpid (keys %pids)
			    		{
			    			if ($pids{$cpid}{active})
			    			{
			        		if (waitpid($cpid, WNOHANG) != 0)
			          	{
										# Child is done
			              &_print_log(3, "RUN: $run -> child $cpid done\n");
			              $pids{$cpid}{active} = 0;
			              $pids{$cpid}{waiting} =0;
			            }
			            else
			            {			             
			              # Still waiting on this child
			              $stillWaiting = 1;
			              if ($pids{$cpid}{waiting} > 30)
			              {
			              	&_print_log(2, "RUN: $run -> child $cpid still running\n");
			              	$pids{$cpid}{waiting} =1; #reset print counter
			              	last if &_check_stop_requested;
											&_check_runtimeinfo_requested;
											&_check_changeloglevel_requested();
			              }
			              else
			              {			              	
			              	$pids{$cpid}{waiting}++;
			              }
			            }
			          }
			        }
			       sleep(1);      #sleep here just to wait till the processes are done
						 } while ($stillWaiting);


#					do {
#			    		$stillWaiting = 0;
#
#			    		foreach my $cpid (keys %pids)
#			    		{
#			    			if ($pids{$cpid}{active})
#			    			{
#			        		if (waitpid($cpid, WNOHANG) != 0)
#			          	{
#										# Child is done
#			              &_print_log(3, "RUN: $run -> child $cpid done\n");
#			              $pids{$cpid}{active} = 0;
#			            }
#			            else
#			            {
#			              # Still waiting on this child
#			              if ($stillWaiting > 30)
#			              {
#			              	&_print_log(2, "RUN: $run -> child $cpid still running\n");
#			              	$stillWaiting =1; #reset print counter
#			              }
#			              else
#			              {
#			              	$stillWaiting ++;
#			              }
#			              
#			            }
#			          }
#			        }
#			       sleep(1);      #sleep here just to wait till the processes are done
#						} while ($stillWaiting);
					&_print_log(2, "The child processes for fio have finished executing.\n");


#					for (my $run=1; $run <= $fio_runs_per_test; $run++)
#	  			{
	  				&_print_log(3, "Stopping data capture for run $run if any\n");
						if ($user_runpsaux)
				    {
				    	&_stop_psaux_capturing("$async_paths{$dslong2}{psaux}{$run}{alivefile}");
				    	if (waitpid($async_paths{$dslong2}{psaux}{$run}{pid}, WNOHANG) != 0)
			        {
			          &_print_log(4, "psaux: child done\n");
			        }
				    	
						}
						if ($user_runzpooliostat)
				    {
				    	&_stop_iostat_capturing("$async_paths{$dslong2}{iostat}{$run}{alivefile}");
				    	if (waitpid($async_paths{$dslong2}{iostat}{$run}{pid}, WNOHANG) != 0)
			        {
			          &_print_log(4, "iostat: child done\n");
			        }
						}
						if ($user_rungstat)
				    {
							&_stop_gstat_capturing("$async_paths{$dslong2}{gstat}{$run}{alivefile}");
							if (waitpid($async_paths{$dslong2}{gstat}{$run}{pid}, WNOHANG) != 0)
			        {
			          &_print_log(4, "gstat: child done\n");
			        }
						}
						if ($user_gettemps)
				    {
				    	&_stop_temp_capturing("$async_paths{$dslong2}{temp}{$run}{alivefile}");
				    	if (waitpid($async_paths{$dslong2}{temp}{$run}{pid}, WNOHANG) != 0)
			        {
			          &_print_log(4, "temp: child done\n");
			        }
						}

						#Convert result back to sth readable
						$_command="cat $poolroot/$_dsname/fio_${run}_json.out | $jsonppbinary -f json -t dumper -json_opt pretty > ${datapath}/fio_${run}_json.out.dumper";
						&_print_log(4,"Fio: result cmd $_command\n");
						push @log_master_command_list, $_command;
						&_exec_command("$_command");

						#now read result files
						my ($jobtotal,$jobtotalduration,$totalcpu,$totalrios,$totalwios,$totalrbw,$totalwbw) =(0,0,0,0,0,0,0);

						open my $in, '<', "${datapath}/fio_${run}_json.out.dumper" or die "Cant access result file ${datapath}/fio_${run}_json.out.dumper, $!\n";
						my $data;
						{
							no warnings; no strict;
			    		local $/;    # slurp mode
			    		$data = eval <$in>;
			    		die "Eval'ing input failed with $@" if ($@);
			    		use strict; use warnings qw( all );
						}
						close $in;

						my %fio_result_hash = %{ $data };

						#foreach my $job=0 .. ($fio_result_hash{jobs}[0]{'job options'}{'numjobs'}) - 1
						#{
						#}

						#$fiotests{$mastertestid}{details}{"run$run"}{sys_cpu}=$fio_result_hash{jobs}[0]{sys_cpu};
						#$fiotests{$mastertestid}{details}{"run$run"}{usr_cpu}=$fio_result_hash{jobs}[0]{usr_cpu};
						#$fiotests{$mastertestid}{details}{"run$run"}{read_iops}=$fio_result_hash{jobs}[0]{read}{iops};
						#$fiotests{$mastertestid}{details}{"run$run"}{read_bw_agg}=$fio_result_hash{jobs}[0]{read}{bw_agg};
						#$fiotests{$mastertestid}{details}{"run$run"}{write_iops}=$fio_result_hash{jobs}[0]{write}{iops};
	          #$fiotests{$mastertestid}{details}{"run$run"}{write_bw_agg}=$fio_result_hash{jobs}[0]{write}{bw_agg};

						$fiotests{$mastertestid}{details}{sys_cpu}{"run$run"}										=$fio_result_hash{jobs}[0]{sys_cpu};
						$fiotests{$mastertestid}{details}{usr_cpu}{"run$run"}										=$fio_result_hash{jobs}[0]{usr_cpu};
						$fiotests{$mastertestid}{details}{cpu_ctx}{"run$run"}										=$fio_result_hash{jobs}[0]{ctx};
						$fiotests{$mastertestid}{details}{cpu_minf}{"run$run"}									=$fio_result_hash{jobs}[0]{minf};
						$fiotests{$mastertestid}{details}{cpu_majf}{"run$run"}									=$fio_result_hash{jobs}[0]{majf};

						$fiotests{$mastertestid}{details}{latency_us_2}{"run$run"}							=$fio_result_hash{jobs}[0]{latency_us}{2}		;
						$fiotests{$mastertestid}{details}{latency_us_4}{"run$run"}							=$fio_result_hash{jobs}[0]{latency_us}{4}		;
						$fiotests{$mastertestid}{details}{latency_us_10}{"run$run"}						=$fio_result_hash{jobs}[0]{latency_us}{10}		;
						$fiotests{$mastertestid}{details}{latency_us_20}{"run$run"}						=$fio_result_hash{jobs}[0]{latency_us}{20}		;
						$fiotests{$mastertestid}{details}{latency_us_50}{"run$run"}						=$fio_result_hash{jobs}[0]{latency_us}{50}		;
						$fiotests{$mastertestid}{details}{latency_us_100}{"run$run"}						=$fio_result_hash{jobs}[0]{latency_us}{100}	;
						$fiotests{$mastertestid}{details}{latency_us_250}{"run$run"}						=$fio_result_hash{jobs}[0]{latency_us}{250}	;
						$fiotests{$mastertestid}{details}{latency_us_500}{"run$run"}						=$fio_result_hash{jobs}[0]{latency_us}{500}	;
						$fiotests{$mastertestid}{details}{latency_us_750}{"run$run"}						=$fio_result_hash{jobs}[0]{latency_us}{750}	;
						$fiotests{$mastertestid}{details}{latency_us_1000}{"run$run"}					=$fio_result_hash{jobs}[0]{latency_us}{1000} ;

						$fiotests{$mastertestid}{details}{'read_slat_ns_min'}{"run$run"}	   	=$fio_result_hash{jobs}[0]{read}{'slat_ns'}{min};
						$fiotests{$mastertestid}{details}{'read_slat_ns_mean'}{"run$run"}  	 	=$fio_result_hash{jobs}[0]{read}{'slat_ns'}{mean};
						$fiotests{$mastertestid}{details}{'read_slat_ns_stddev'}{"run$run"}  	=$fio_result_hash{jobs}[0]{read}{'slat_ns'}{stddev};
						$fiotests{$mastertestid}{details}{'read_slat_ns_max'}{"run$run"}	   	=$fio_result_hash{jobs}[0]{read}{'slat_ns'}{max};
						$fiotests{$mastertestid}{details}{'read_clat_ns_min'}{"run$run"}	   	=$fio_result_hash{jobs}[0]{read}{'clat_ns'}{min};
						$fiotests{$mastertestid}{details}{'read_clat_ns_mean'}{"run$run"}    	=$fio_result_hash{jobs}[0]{read}{'clat_ns'}{mean};
						$fiotests{$mastertestid}{details}{'read_clat_ns_stddev'}{"run$run"}  	=$fio_result_hash{jobs}[0]{read}{'clat_ns'}{stddev};
						$fiotests{$mastertestid}{details}{'read_clat_ns_max'}{"run$run"}	   	=$fio_result_hash{jobs}[0]{read}{'clat_ns'}{max};
						$fiotests{$mastertestid}{details}{'read_lat_ns_min'}{"run$run"}	     	=$fio_result_hash{jobs}[0]{read}{'lat_ns'}{min};
						$fiotests{$mastertestid}{details}{'read_lat_ns_mean'}{"run$run"}     	=$fio_result_hash{jobs}[0]{read}{'lat_ns'}{mean};
						$fiotests{$mastertestid}{details}{'read_lat_ns_stddev'}{"run$run"}   	=$fio_result_hash{jobs}[0]{read}{'lat_ns'}{stddev};
						$fiotests{$mastertestid}{details}{'read_lat_ns_max'}{"run$run"}	     	=$fio_result_hash{jobs}[0]{read}{'lat_ns'}{max};
						$fiotests{$mastertestid}{details}{'read_iops_max'}{"run$run"}		     	=$fio_result_hash{jobs}[0]{read}{iops_max};
						$fiotests{$mastertestid}{details}{'read_iops'}{"run$run"}	   			 	 	=$fio_result_hash{jobs}[0]{read}{iops};
						$fiotests{$mastertestid}{details}{'read_iops_min'}{"run$run"}	  	   	=$fio_result_hash{jobs}[0]{read}{iops_min};
						$fiotests{$mastertestid}{details}{'read_iops_stddev'}{"run$run"}	 		 	=$fio_result_hash{jobs}[0]{read}{iops_stddev};
						$fiotests{$mastertestid}{details}{'read_iops_mean'}{"run$run"}	  			=$fio_result_hash{jobs}[0]{read}{iops_mean};
						$fiotests{$mastertestid}{details}{'read_bw_max'}{"run$run"}		    		=$fio_result_hash{jobs}[0]{read}{bw_max};
						$fiotests{$mastertestid}{details}{'read_bw'}{"run$run"}	   			  		=$fio_result_hash{jobs}[0]{read}{bw};
						$fiotests{$mastertestid}{details}{'read_bw_min'}{"run$run"}	  	   		=$fio_result_hash{jobs}[0]{read}{bw_min};
						$fiotests{$mastertestid}{details}{'read_bw_stddev'}{"run$run"}	  	   		=$fio_result_hash{jobs}[0]{read}{bw_dev};
						$fiotests{$mastertestid}{details}{'read_bw_mean'}{"run$run"}	  	 			=$fio_result_hash{jobs}[0]{read}{bw_mean};
						$fiotests{$mastertestid}{details}{'read_bw_agg'}{"run$run"}	 	  			=$fio_result_hash{jobs}[0]{read}{bw_agg};
						$fiotests{$mastertestid}{details}{'read_short_ios'}{"run$run"}	   			=$fio_result_hash{jobs}[0]{read}{short_ios};
						$fiotests{$mastertestid}{details}{'read_drop_ios'}{"run$run"}	  		 	=$fio_result_hash{jobs}[0]{read}{drop_ios};
						$fiotests{$mastertestid}{details}{'read_total_ios'}{"run$run"}	 				=$fio_result_hash{jobs}[0]{read}{total_ios};
                                                                    		                                                                    		
	          $fiotests{$mastertestid}{details}{'sync_lat_ns_min'}{"run$run"}	   		=$fio_result_hash{jobs}[0]{sync}{'lat_ns'}{min};
						$fiotests{$mastertestid}{details}{'sync_lat_ns_mean'}{"run$run"}    	=$fio_result_hash{jobs}[0]{sync}{'lat_ns'}{mean};
						$fiotests{$mastertestid}{details}{'sync_lat_ns_stddev'}{"run$run"}  	=$fio_result_hash{jobs}[0]{sync}{'lat_ns'}{stddev};
						$fiotests{$mastertestid}{details}{'sync_lat_ns_max'}{"run$run"}	   		=$fio_result_hash{jobs}[0]{sync}{'lat_ns'}{max};
						$fiotests{$mastertestid}{details}{'sync_total_ios'}{"run$run"}	   		=$fio_result_hash{jobs}[0]{sync}{'total_ios'};

						$fiotests{$mastertestid}{details}{'write_slat_ns_min'}{"run$run"}	  	=$fio_result_hash{jobs}[0]{write}{'slat_ns'}{min};
						$fiotests{$mastertestid}{details}{'write_slat_ns_mean'}{"run$run"}  	=$fio_result_hash{jobs}[0]{write}{'slat_ns'}{mean};
						$fiotests{$mastertestid}{details}{'write_slat_ns_stddev'}{"run$run"}  =$fio_result_hash{jobs}[0]{write}{'slat_ns'}{stddev};
						$fiotests{$mastertestid}{details}{'write_slat_ns_max'}{"run$run"}	  	=$fio_result_hash{jobs}[0]{write}{'slat_ns'}{max};
						$fiotests{$mastertestid}{details}{'write_clat_ns_min'}{"run$run"}	  	=$fio_result_hash{jobs}[0]{write}{'clat_ns'}{min};
						$fiotests{$mastertestid}{details}{'write_clat_ns_mean'}{"run$run"}   	=$fio_result_hash{jobs}[0]{write}{'clat_ns'}{mean};
						$fiotests{$mastertestid}{details}{'write_clat_ns_stddev'}{"run$run"} 	=$fio_result_hash{jobs}[0]{write}{'clat_ns'}{stddev};
						$fiotests{$mastertestid}{details}{'write_clat_ns_max'}{"run$run"}	  	=$fio_result_hash{jobs}[0]{write}{'clat_ns'}{max};
						$fiotests{$mastertestid}{details}{'write_lat_ns_min'}{"run$run"}	   	=$fio_result_hash{jobs}[0]{write}{'lat_ns'}{min};
						$fiotests{$mastertestid}{details}{'write_lat_ns_mean'}{"run$run"}   	=$fio_result_hash{jobs}[0]{write}{'lat_ns'}{mean};
						$fiotests{$mastertestid}{details}{'write_lat_ns_stddev'}{"run$run"} 	=$fio_result_hash{jobs}[0]{write}{'lat_ns'}{stddev};
						$fiotests{$mastertestid}{details}{'write_lat_ns_max'}{"run$run"}	   	=$fio_result_hash{jobs}[0]{write}{'lat_ns'}{max};
						$fiotests{$mastertestid}{details}{'write_iops_max'}{"run$run"}		   		=$fio_result_hash{jobs}[0]{write}{iops_max};
						$fiotests{$mastertestid}{details}{'write_iops'}{"run$run"}	   					=$fio_result_hash{jobs}[0]{write}{iops};
						$fiotests{$mastertestid}{details}{'write_iops_min'}{"run$run"}	  	 		=$fio_result_hash{jobs}[0]{write}{iops_min};
						$fiotests{$mastertestid}{details}{'write_iops_stddev'}{"run$run"}	 		=$fio_result_hash{jobs}[0]{write}{iops_stddev};
						$fiotests{$mastertestid}{details}{'write_iops_mean'}{"run$run"}	  		=$fio_result_hash{jobs}[0]{write}{iops_mean};
						$fiotests{$mastertestid}{details}{'write_bw_max'}{"run$run"}		    		=$fio_result_hash{jobs}[0]{write}{bw_max};
						$fiotests{$mastertestid}{details}{'write_bw'}{"run$run"}	   			  		=$fio_result_hash{jobs}[0]{write}{bw};
						$fiotests{$mastertestid}{details}{'write_bw_min'}{"run$run"}	  	   		=$fio_result_hash{jobs}[0]{write}{bw_min};
						$fiotests{$mastertestid}{details}{'write_bw_stddev'}{"run$run"}	  	   		=$fio_result_hash{jobs}[0]{write}{bw_dev};
						$fiotests{$mastertestid}{details}{'write_bw_mean'}{"run$run"}	  	 		=$fio_result_hash{jobs}[0]{write}{bw_mean};
						$fiotests{$mastertestid}{details}{'write_bw_agg'}{"run$run"}	 	  			=$fio_result_hash{jobs}[0]{write}{bw_agg};
						$fiotests{$mastertestid}{details}{'write_short_ios'}{"run$run"}	  	 	=$fio_result_hash{jobs}[0]{write}{short_ios};
						$fiotests{$mastertestid}{details}{'write_drop_ios'}{"run$run"}	  	 		=$fio_result_hash{jobs}[0]{write}{drop_ios};
						$fiotests{$mastertestid}{details}{'write_total_ios'}{"run$run"}	 	 		=$fio_result_hash{jobs}[0]{write}{total_ios};


						if ($user_runpsaux )
				    {
				    	my $psaux_result=&_handle_psaux_output("$async_paths{$dslong2}{psaux}{$run}{log}");
				    	$fiotests{$mastertestid}{details}{psaux}{"run$run"}=$psaux_result;
						}
						if ($user_runzpooliostat)
				    {
				    	my $zpooliostat_result=&_handle_iostat_output("$async_paths{$dslong2}{iostat}{$run}{log}",$_pool);
				    	$fiotests{$mastertestid}{details}{zpool}{"run$run"}=$zpooliostat_result;

						}
					#}
				
			
			#temperature before and after test
			#read : io=10240MB, bw=63317KB/s, iops=15829, runt=165607msec
			#put result files in subfolder or temp instead of pool (user defineable and autoamted)
			#slat = submission latency  min=44, max=18627, avg=61.33, stdev=17.91 , percentile?
			#clat = completion latency  min=44, max=18627, avg=61.33, stdev=17.91 , percentile?
			#bw (KB  /s): min=   71, max=  251, per=0.36%, avg=154.84, stdev=18.29
			#cpu          : usr=5.32%, sys=21.95%, ctx=2829095, majf=0, minf=21
			#&_print_hash_generic (\%fiotests, []);
			#print Dumper \%fiotests;
			
		}
		&_create_averages_min_max($mastertestid);
		#print "MTID $mastertestid", Dumper $fiotests{$mastertestid};
		&_print_log(2, "Test $mastertestid done\n");
		$mastertestid++;
		$fiotestnr++;
		&_do_regular_output('test');;
	}
	
	#my $filename = "sync_bs${bs}_jobs${jobs}_iod${iod}";

	#my $command="fio --filename=\"$basepath_sync\"$filename --direct=1 --rw=randrw --refill_buffers --norandommap --randrepeat=0 --ioengine=posixaio --bs=$bs --rwmixread=0 --iodepth=$iod 	--numjobs=$jobs --runtime=$runtime --group_reporting --name=$filename --size=$size $log";
	#my $command="fio
	#--filename=\"$basepath_sync\"$filename
	#--direct=1
	#--rw=randrw
	#--refill_buffers - If this option is given, fio will refill the I/O buffers on every submit. Only makes sense if zero_buffers isn’t specified, naturally.
	#--norandommap
	#--randrepeat=0 	- Seed the random number generator used for random I/O patterns in a predictable way so the pattern is repeatable across runs. Default: true.
	#--ioengine=posixaio
	#--bs=$bs
	#--rwmixread=0
	#--iodepth=$iod
	#--numjobs=$jobs
	#--runtime=$runtime
	#--group_reporting
	#--name=$filename
	#--size=$size $log";

	#https://fio.readthedocs.io/en/latest/fio_doc.htm
	#--rw=
    #read       Sequential reads.
    #write        Sequential writes.
    #trim        Sequential trims (Linux block devices and SCSI character devices only).
    #randread        Random reads.
    #randwrite        Random writes.
    #randtrim        Random trims (Linux block devices and SCSI character devices only).
    #rw,readwrite        Sequential mixed reads and writes.
    #randrw        Random mixed reads and writes.
    #trimwrite        Sequential trim+write sequences. Blocks will be trimmed first, then the same blocks will be written to.

		#--rwmixread=0
		#--iodepth=$iod
		#-numjobs=$jobs

	#Option 1  - loop over RW/IOD,#JOBS
	#Option 2 -  loop over predefined values

}

sub _get_avg_min_max
{
	my (@array) =  (@_);
	my @ret;
	my $nonnull_found=0;
	my ($sum,$min,$max,$avg) = (0,9999999999999999,0,0); 
	
	foreach (@array) 
	{ 
		$nonnull_found++ if $_>0;
		$sum += $_; 
		$min=$_ if ($_<$min);
		$max=$_ if ($_>$max);
	
	} # add each element of the array 
	
	$min=0 unless ($nonnull_found); # set min to 0 if all values in array were 0
	my $arraysize= (scalar @array)?scalar @array:1;
	#min/avg/max
	push @ret, ($min);
	push @ret, ($sum/$arraysize);
	push @ret, ($max);

	return @ret; 		
}

sub _create_averages_min_max
{
	my ($mtestid) =  ($_[0]);
	
	&_print_log(4,"_create_averages_min_max for id $mtestid\n");
	
	my $_testtool=$_mastertestinfo{$mtestid}{tool};		
	&_print_log(4,"tool=$_testtool\n");
	my @avg_min_max;
	if ($_testtool=~/fio/)
	{
		foreach my $a  ("sys_cpu","usr_cpu","cpu_ctx","cpu_minf","cpu_majf")
		{			
			@avg_min_max=&_get_avg_min_max(values %{$fiotests{$mastertestid}{details}{$a}});
			my $res= join " ", @avg_min_max;
			&_print_log(4,"camm: details ($a) -> results = $res \n");
			$fiotests{$mastertestid}{results}{"${a}_min"}=$avg_min_max[0];
			$fiotests{$mastertestid}{results}{"${a}_avg"}=$avg_min_max[1];
			$fiotests{$mastertestid}{results}{"${a}_max"}=$avg_min_max[2];
		}
			
		foreach my $a  (2,4,10,20,50,100,250,500,750,1000)
		{
			@avg_min_max=&_get_avg_min_max(values %{$fiotests{$mastertestid}{details}{"latency_us_$a"}});							
			my $res= join " ", @avg_min_max;
			&_print_log(4,"camm: details (latency_us_$a) -> results = $res \n");
			
			$fiotests{$mastertestid}{results}{"latency_us_${a}_min"}=$avg_min_max[0];
			$fiotests{$mastertestid}{results}{"latency_us_${a}_avg"}=$avg_min_max[1];
			$fiotests{$mastertestid}{results}{"latency_us_${a}_max"}=$avg_min_max[2];			
		}
			
		foreach my $z ("read","write")
		{		
			foreach my $a ("slat_ns","clat_ns","lat_ns")
			{
				foreach my $b  ("min","mean","stddev","max")
				{		
					
					@avg_min_max=&_get_avg_min_max(values %{$fiotests{$mastertestid}{details}{"${z}_${a}_$b"}});	 
					my $res= join " ", @avg_min_max;
					&_print_log(4,"camm: details ( ${z}_${a}_$b ) -> results = $res \n");
					$fiotests{$mastertestid}{results}{"${z}_${a}_${b}_min"}=$avg_min_max[0];
					$fiotests{$mastertestid}{results}{"${z}_${a}_${b}_avg"}=$avg_min_max[1];
					$fiotests{$mastertestid}{results}{"${z}_${a}_${b}_max"}=$avg_min_max[2];
				}
			}
			foreach my $a  ("iops_max","iops","iops_min","iops_stddev","iops_mean","bw_max","bw","bw_min","bw_stddev","bw_mean","bw_agg","short_ios","drop_ios","total_ios")
			{								
				@avg_min_max=&_get_avg_min_max(values %{$fiotests{$mastertestid}{details}{"${z}_${a}"}});		     	
				my $res= join " ", @avg_min_max;
				&_print_log(4,"camm: details ( ${z}_${a} ) -> results = $res \n");	
				$fiotests{$mastertestid}{results}{"${z}_${a}_min"}=$avg_min_max[0];
				$fiotests{$mastertestid}{results}{"${z}_${a}_avg"}=$avg_min_max[1];
				$fiotests{$mastertestid}{results}{"${z}_${a}_max"}=$avg_min_max[2];
				
			}
		}
		foreach my $a  ("min","mean","stddev","max")
		{								
			@avg_min_max=&_get_avg_min_max(values %{$fiotests{$mastertestid}{details}{"sync_lat_ns_$a"}});	
			my $res= join " ", @avg_min_max;
			&_print_log(4,"camm: details ( sync_lat_ns_${a} ) -> results = $res \n");    	
			$fiotests{$mastertestid}{results}{"sync_lat_ns_${a}_min"}=$avg_min_max[0];
			$fiotests{$mastertestid}{results}{"sync_lat_ns_${a}_avg"}=$avg_min_max[1];
			$fiotests{$mastertestid}{results}{"sync_lat_ns_${a}_max"}=$avg_min_max[2];		
		}
			@avg_min_max=&_get_avg_min_max(values %{$fiotests{$mastertestid}{details}{'sync_total_ios'}});		     	
			my $res= join " ", @avg_min_max;
			&_print_log(4,"camm: details ( sync_total_ios ) -> results = $res \n");    	
			$fiotests{$mastertestid}{results}{"sync_total_ios_min"}=$avg_min_max[0];
			$fiotests{$mastertestid}{results}{"sync_total_ios_avg"}=$avg_min_max[1];
			$fiotests{$mastertestid}{results}{"sync_total_ios_max"}=$avg_min_max[2];		
		
		
	}
	elsif ($_testtool=~/dd/)
	{
		
		foreach my $a  ("read","write")
		{	
			foreach my $b  ("total_bytes_all_jobs","total_duration_all_jobs","avg_bytes_per_job","avg_duration_per_job","avg_load_per_job","avg_rios_per_job","avg_wios_per_job","avg_rbw_per_job","avg_wbw_per_job")						
			{						
				@avg_min_max=&_get_avg_min_max(values %{$ddtests{$mastertestid}{details}{"${a}_$b"}});	
				my $res= join " ", @avg_min_max;
				&_print_log(4,"camm: details ( ${a}_$b ) -> results = $res \n");		
			#	print "4,camm: details ( ${a}_$b ) -> results = $res \n";					
				$ddtests{$mastertestid}{results}{"${a}_${b}_min"}=$avg_min_max[0];
				$ddtests{$mastertestid}{results}{"${a}_${b}_avg"}=$avg_min_max[1];
				$ddtests{$mastertestid}{results}{"${a}_${b}_max"}=$avg_min_max[2];		
			}
		}		
	}
}

sub _calculate_dd_runs
{
	&_print_log(4,"Calculating DD tests\n");
	my @dd_inst=();
	###########################################
	#counting tests to be performed. Keep this at the same layout as the actual testrun to get correct values
	###########################################
	my $test_runs_per_ds=0;
	push @dd_inst, 1 unless ($dd_concurrent_jobs_do); #run only one job unless user wants many
	@dd_inst = @dd_num_jobs if ($dd_concurrent_jobs_do); #run desiresd nr of parallel jobs
	foreach my $bs (@dd_blocksizes) # run test with these blocksizes
	{
		foreach my $instcnt (@dd_inst) # run test with $instcnt parallel jobs
		{
			push @_report_ddtests, "blocksize $bs, instances $instcnt, read+write";
			foreach ('write','read')
			{				
				for (my $_run=1; $_run <= $dd_runs_per_test; $_run++)
			  {
					$test_runs_per_ds++;
				}
	    }
	  }
	}
	&_print_log(2,"Will run $test_runs_per_ds DD tests per dataset\n");
	return $test_runs_per_ds;
}


#run dd tests
#my $dd_do=1; #set to 1 if you want the dd tests to run
#my $dd_concurrent_jobs_do=1;
#my @dd_blocksizes = ("4k","8k","64k","128k","512k","1M","4M");
#my @dd_num_jobs = (1,2,4,8,16,32); #how many processes to spawn (not each will do the nth part of total size)
#my $dd_file_size="100G";
# dd if=/dev/zero of=$poolroot/Tank1/disabled/tmp.dat bs=2048k count=25k
# dd of=/dev/null if=$poolroot/Tank1/disabled/tmp.dat bs=2048k count=25k
sub _run_dd()
{
	my ($dsid) =  ($_[0]);
	my @dd_inst=();
	my ($blockcount, $maxsize, $_command,$bs_bytes, $result, $duration,%pids,$_dsname, $_lastts,%async_paths);
	$_lastts=0;
	$_dsname=$_datasets{$dsid}{name};
	my $_dsname_short=$_datasets{$dsid}{name_short};   

	&_print_log(1, "Called RunDD for dataset $_dsname (test #$mastertestid)\n");

	push @dd_inst, 1 unless ($dd_concurrent_jobs_do); #run only one job unless user wants many
	@dd_inst = @dd_num_jobs if ($dd_concurrent_jobs_do); #run desiresd nr of parallel jobs
	$maxsize=&_get_as_bytes($dd_file_size); #convert given testfile size to bytes

	my $_pool=$1 if ($_dsname=~/^(.+)\//);
	my $dslong2=$_dsname;
	$dslong2=~tr/\//_/;


	###########################################
	$total_test_runs=$test_runs_per_ds*$total_datasets/2;  #divide by two since we run read and write in one test, so while its actually double the anmount we just show 1 test per read/write pair
	&_print_log(0, "DD will now perform $test_runs_per_ds tests (read + write) for the current dataset $_dsname_short \n");

	&_print_log(4, "dsid=$dsid");
	&_print_log(4, "dsname=$_dsname");
	&_print_log(4, "pool=$_pool");
	&_print_log(4, "dslong2=$dslong2");


	&_print_log(3, "DD total size = $dd_file_size ($maxsize bytes)\n");
	&_print_log(4, "DD blocksize loop\n");
	my $ddtestnr=1;
	foreach my $bs (@dd_blocksizes) # run test with these blocksizes
	{		
		&_print_log(2, "DD Running with BS $bs now\n");
		$bs_bytes=&_get_as_bytes($bs);
		%pids=(); #reset pids

		&_print_log(3, "DD instcnt loop\n");
		foreach my $instcnt (@dd_inst) # run test with $instcnt parallel jobs
		{
			$blockcount=$maxsize/$bs_bytes/$instcnt;
			&_print_log(3, "DD Running on DS $_dsname with $instcnt instances\n");
			&_print_log(3, "... using $blockcount blocks of size $bs\n");

			#perform write tests for all given instance counts
			#here we will need to add the best of X runs witgh average whould we ever want to do that

			&_print_log(3, "test #$mastertestid (DD)\n");
			foreach my $type ('write','read')
			{
				last if &_check_stop_requested;
				&_check_runtimeinfo_requested;
				&_check_changeloglevel_requested();
				my $runtotal=0;
				&_print_log(3, "DD $type run loop\n");
				for (my $run=1; $run <= $dd_runs_per_test; $run++)
			  {
			  	&_print_log(1, "Iteration $run / $dd_runs_per_test\n");	
			  	$_mastertestinfo{$mastertestid}{tool}='dd';
			  	$_mastertestinfo{$mastertestid}{dsid}=$dsid;
					$_mastertestinfo{$mastertestid}{poolid}=$_datasets{$dsid}{poolid};

					
			  	$ddtests{$mastertestid}{info}{dsid}=$dsid;
			  	$ddtests{$mastertestid}{info}{dsname}=$_dsname;
			  	$ddtests{$mastertestid}{info}{dsname_short}=$_dsname_short;
			  	$ddtests{$mastertestid}{info}{bs}=$bs;
			  	$ddtests{$mastertestid}{info}{jobs}=$instcnt;
			  	$ddtests{$mastertestid}{info}{dd_runs_per_test}=$dd_runs_per_test;
			  	$ddtests{$mastertestid}{info}{dd_file_size}=$dd_file_size;
			  	$ddtests{$mastertestid}{info}{dd_file_size_bytes}=$maxsize;

					&_print_log(4, "RUN: ${mastertestid}-$run -> $ddtests{$mastertestid}{info}{dsid}\n");
			  	&_print_log(4, "RUN: ${mastertestid}-$run -> $ddtests{$mastertestid}{info}{dsname}\n");
			  	&_print_log(4, "RUN: ${mastertestid}-$run -> $ddtests{$mastertestid}{info}{dsname_short}\n");
			  	&_print_log(4, "RUN: ${mastertestid}-$run -> $_mastertestinfo{$mastertestid}{tool}\n");
			  	&_print_log(4, "RUN: ${mastertestid}-$run -> $ddtests{$mastertestid}{info}{bs}\n");
			  	&_print_log(4, "RUN: ${mastertestid}-$run -> $ddtests{$mastertestid}{info}{jobs}\n");
			  	&_print_log(4, "RUN: ${mastertestid}-$run -> $ddtests{$mastertestid}{info}{dd_runs_per_test}\n");
			  	&_print_log(4, "RUN: ${mastertestid}-$run -> $ddtests{$mastertestid}{info}{dd_file_size}\n");
			  	#&_print_log(3, "RUN: ${mastertestid}-$run -> $ddtests{$mastertestid}{info}{dd_file_size_bytes}\n");


					my $datapath = $user_make_logs_persistent ?$logpath:"$poolroot/$_dsname";
					my $async_basepath="${datapath}/${mastertestid}_${dslong2}_test${ddtestnr}_run${run}";
					
				  for (my $job=1; $job <= $instcnt; $job++)
				  {

						my $ddlogpath="${async_basepath}_dd_${job}.${dslong2}.out.$type";
				  	if ($type=~/write/)
				  	{
				   		$_command="dd if=/dev/zero of=$poolroot/$_dsname/dd${job}.out bs=$bs count=$blockcount 2>&1 |tee -a ${ddlogpath}";
				   		&_log_testcommand("dd if=/dev/zero of=${poolroot}_${_dsname}_dd${job}.out bs=$bs count=$blockcount");
				   	}
				   	else
				   	{
				   		$_command="dd of=/dev/null if=$poolroot/$_dsname/dd${job}.out bs=$bs count=$blockcount 2>&1 |tee -a ${ddlogpath}";
				   		&_log_testcommand("dd of=/dev/zero if=${poolroot}_${_dsname}_dd${job}.out bs=$bs count=$blockcount");
				   	}
						
				   	#print "Running DD command for $type: $_command\n";
			  		push @log_master_command_list, $_command;
			  		#&_exec_command("$write_command"); #now in forked child
			  		#&_print_log(2, "...$type ...");

				  	######### Forking ###########
		
							
					    if ($user_runpsaux)
					    {
					    	#fio --filename=/mnt/p_sin_mir02_v04_o00_cno_sno/ds_64k_sync-disabled_compr-off/fio.o
					    	$async_paths{$dslong2}{psaux}{$run}{log}="${async_basepath}_psaux.log";
					    	$async_paths{$dslong2}{psaux}{$run}{alivefile}="${async_basepath}_psaux.run";
					    	$async_paths{$dslong2}{psaux}{$run}{pid}=&_start_psaux_capturing($async_paths{$dslong2}{psaux}{$run}{log},$async_paths{$dslong2}{psaux}{$run}{alivefile});
							}
							if ($user_runzpooliostat)
					    {
					    	$async_paths{$dslong2}{iostat}{$run}{log}="${async_basepath}_iostat.log";
					    	$async_paths{$dslong2}{iostat}{$run}{alivefile}="${async_basepath}_iostat.run";
					    	$async_paths{$dslong2}{iostat}{$run}{pid}=&_start_iostat_capturing($_pool, $async_paths{$dslong2}{iostat}{$run}{log},$async_paths{$dslong2}{iostat}{$run}{alivefile});
							}
							if ($user_rungstat)
					    {
					    	$async_paths{$dslong2}{gstat}{$run}{log}="${async_basepath}_gstat.log";
					    	$async_paths{$dslong2}{gstat}{$run}{alivefile}="${async_basepath}_gstat.run";
					    	$async_paths{$dslong2}{gstat}{$run}{pid}=&_start_gstat_capturing($async_paths{$dslong2}{gstat}{$run}{log},$async_paths{$dslong2}{gstat}{$run}{alivefile});
							}
							if ($user_gettemps)
					    {
					    	$async_paths{$dslong2}{temp}{$run}{log}="${async_basepath}_temp.log";
					    	$async_paths{$dslong2}{temp}{$run}{alivefile}="${async_basepath}_temp.run";
					    	$async_paths{$dslong2}{temp}{$run}{pid}=&_start_temp_capturing($async_paths{$dslong2}{temp}{$run}{log},$async_paths{$dslong2}{temp}{$run}{alivefile});
							}

					  	# Fork child process - DD Worker
							my $pid = fork();

							# Check if parent/child process
							if ($pid) # Parent
							{
							  &_print_log(3, "RUN: $run -> Parent: Started $type Child ${job} with process id: $pid\n");
							  $pids{$pid}{active}=1;
							  $pids{$pid}{waiting}=0;
							  $pids{$pid}{type}=$type;

							  $job2cpu{idstring}="$datapath/dd${job}.${dslong2}.out.$type";
							  $job2cpu{pid}=$pid;
							  $job2cpu{$mastertestid}{$job}=$job;


							  $ddtests{$mastertestid}{details}{$type}{runs}{$run}{info}{jobs}{$job}{pid}=$pid;
							  #$ddtests{$mastertestid}{details}{$type}{runs}{$run}{info}{type}=$type;
							}
							elsif ($pid == 0) # Child
							{
								#now run dd in child
								&_print_log(3, "RUN: $run -> $type Child $$: Will now execute\n$_command\n");

								#exec should execute the dd in the same context i.e. with the same pid
								#exec $_command or die "Child $$ could not exec dd command $!";
								#`$_command`;
								&_exec_command("$_command");
								exit $?;
							}
							else
							{ # Unable to fork
							  die "ERROR: Could not fork new process: $!\n\n";
							}
							######### /Forking ###########
					}
					&_print_log(3, "RUN: $run -> Waiting for the child processes ($type) to complete (all of them)...\n");

			 		#for waitpid
					my $stillWaiting ;
					#/for waitpid
					
					do {			    		
							$stillWaiting = 0;
			    		foreach my $cpid (keys %pids)
			    		{
			    			if ($pids{$cpid}{active})
			    			{
			        		if (waitpid($cpid, WNOHANG) != 0)
			          	{
										# Child is done
			              &_print_log(3, "RUN: $run -> child $cpid done\n");
			              $pids{$cpid}{active} = 0;
			              $pids{$cpid}{waiting} =0;
			            }
			            else
			            {			             
			              # Still waiting on this child
			              $stillWaiting = 1;
			              if ($pids{$cpid}{waiting} > 30)
			              {
			              	&_print_log(2, "RUN: $run -> child $cpid still running\n");
			              	$pids{$cpid}{waiting} =1; #reset print counter
			              	last if &_check_stop_requested;
											&_check_runtimeinfo_requested;
											&_check_changeloglevel_requested();
			              }
			              else
			              {			              	
			              	$pids{$cpid}{waiting}++;
			              }
			            }
			          }
			        }
			       sleep(1);      #sleep here just to wait till the processes are done
						 } while ($stillWaiting);
					&_print_log(2, "The child processes ($type) have finished executing.\n");


					for (my $run=1; $run <= $dd_runs_per_test; $run++)
	  			{
	  				&_print_log(3, "Stopping data capture for run $run if any\n");
						if ($user_runpsaux)
				    {
				    	&_stop_psaux_capturing("$async_paths{$dslong2}{psaux}{$run}{alivefile}");
				    	if (waitpid($async_paths{$dslong2}{psaux}{$run}{pid}, WNOHANG) != 0)
			        {
			          &_print_log(4, "psaux: child done\n");
			        }
				    	
						}
						if ($user_runzpooliostat)
				    {
				    	&_stop_iostat_capturing("$async_paths{$dslong2}{iostat}{$run}{alivefile}");
				    	if (waitpid($async_paths{$dslong2}{iostat}{$run}{pid}, WNOHANG) != 0)
			        {
			          &_print_log(4, "iostat: child done\n");
			        }
						}
						if ($user_rungstat)
				    {
							&_stop_gstat_capturing("$async_paths{$dslong2}{gstat}{$run}{alivefile}");
							if (waitpid($async_paths{$dslong2}{gstat}{$run}{pid}, WNOHANG) != 0)
			        {
			          &_print_log(4, "gstat: child done\n");
			        }
						}
						if ($user_gettemps)
				    {
				    	&_stop_temp_capturing("$async_paths{$dslong2}{temp}{$run}{alivefile}");
				    	if (waitpid($async_paths{$dslong2}{temp}{$run}{pid}, WNOHANG) != 0)
			        {
			          &_print_log(4, "temp: child done\n");
			        }
						}


						
						#now read result files
						my ($jobtotal,$jobtotalduration,$totalcpu,$totalrios,$totalwios,$totalrbw,$totalwbw) =(0,0,0,0,0,0,0);
						for (my $job=1; $job <= $instcnt; $job++)
					  {
					  	my $ddlogpath="${async_basepath}_dd_${job}.${dslong2}.out.$type";
					  	$result=0;
					  	$duration=0;
							#now gather result set - in ${datapath}/dd${job}.out.<type>
							open ( my $reshandle, '<', "${ddlogpath}");

							#163+0 records in
							#163+0 records out
							#10682368 bytes transferred in 0.043050 secs (248140065 bytes/sec)
							foreach my $line (<$reshandle>)
							{
								next if $line=~/records/;
								if ($line=~/in\s(.+)\ssecs\s\((\d+)\sbytes\/sec\)/)
								{
									$result=$2;
									$duration=$1;
								}
								last;
							}

							$result=0 unless (defined $result);
							$duration=0 unless (defined $duration);
							
							
							#$fiotests{$mastertestid}{details}{sys_cpu}{"run$run"}										=$fio_result_hash{jobs}[0]{sys_cpu};
							$ddtests{$mastertestid}{details}{jobs}{$job}{"${type}_bytes"}{"run$run"}=$result;
							$ddtests{$mastertestid}{details}{jobs}{$job}{"${type}_duration"}{"run$run"}=$duration;
							
							#my $mb=&_get_as($result,'M');
							#convert  with sprintf?
							#$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{jobs}{$job}{'bytes'}=$result;
							#$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{jobs}{$job}{'duration'}=$duration;
							#$ddtests{$mastertestid}{runs}{$run}{results}{jobs}{$job}{'megabytes'}=$mb;
							#add min, max, avg CPU here
							# add min, max, avg IOSTAT here
							$jobtotal+=$result;
							$jobtotalduration+=$duration;
							#&_print_log(3, "RUN: $run -> Handle this: $type $job: $result ($mb MB/s) ($duration secs)\n" );
							&_print_log(3, "RUN: $run -> Handle this: $type $job: $result ($duration secs)\n" );
							close $reshandle;

							if ($user_runpsaux)
				    	{

				    		my $psaux_result=&_handle_psaux_output("$async_paths{$dslong2}{psaux}{$run}{log}");
				    		$ddtests{$mastertestid}{details}{psaux}{"run$run"}=$psaux_result;
	#			    		my ($refpid,$max_cpu,$lines,$total_cpu)=(0,0,0,0);
	#							my $topfile ="${datapath}/${ppid}_psaux_${dslong2}_$type.log";
	#
	#							open ( my $tophandle, '<', "$topfile");
	#							foreach my $line (<$tophandle>)
	#							{
	#								next if ($line =~/tee/); #only get dd lines
	#								next unless ($line =~/($ddtests{$mastertestid}{info}{tool})$job/); #only get dd<jobid> lines
	#								my $path="${datapath}/dd${job}"; #do we need to add ${dslong2}. ?
	#								#root       8099    0.0  0.0   6268   2180  0  R+   14:24      0:00.02 dd of=/dev/null if=/mnt/pool_m2_vdevs-1_offset-2/ds_64k_sync-always_compr-off/dd1.ou
	#								#root       44910    0.0  0.0   6268   2164  0  D+   04:20       0:00.02 dd if=/dev/zero of=/mnt/pool_z3_vdevs-1_offset-0/ds_64k_sync-always_compr-off/dd1.out bs=4k count=262144
	#								#root       44911    0.0  0.0   6252   2048  0  D+   04:20       0:00.00 tee /mnt/pool_z3_vdevs-1_offset-0/ds_64k_sync-always_compr-off/dd1.out.write
	#								#--------USER-----PID-----CPU-------------MEM--------------VSZ---RSS-----TT------STAT--STARTED---------TIME---------------_command
	#								#if ($line=~/\w+\s+(\d+)\s+(\d{1,3}\.d{1,2})\d{1,2}\.d{1,2}\s+\d+\s+\d+\s+.{1,2}\s+.+\s+\d{2}:\d{2}\s+\d{1,}:\d{2}\.d{2}\s+($ddtests{$mastertestid}{tool}.*?$path\.out).*$)
	#								if ($line=~/\w+\s+(\d+)\s+(\d{1,3}\.\d{1,2})\s+\d{1,2}\.\d{1,2}\s+\d+\s+\d+\s+.{1,2}\s+.+\s+\d{2}:\d{2}\s+\d{1,}:\d{2}\.\d{2}\s+($ddtests{$mastertestid}{info}{tool}.*?$path).*?$/)
	#								{
	#									$refpid=$1;
	#									&_print_log(3, "psaux $1 $2=>" );
	#									next if ($2=~/0.0/);
	#
	#									$total_cpu+=$2;
	#									$lines++; # assume we ran every second, so we will average by dividing by lines below
	#									$max_cpu=$2 if ($2 > $max_cpu); #capture peak load
	#									&_print_log(3, "$total_cpu , $lines\n" );
	#								}
	#							}
	#							close $tophandle;
	#							&_print_log(3, "psaux $total_cpu $max_cpu, $lines lines\n" );
	#							$lines=1 unless ($lines); #prevent division by 0 error. If we didnt match any lines total_cpu is 0 too so no problem
	#							$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{jobs}{$job}{'realpid'}=$refpid;
	#							$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{jobs}{$job}{'load'}=$total_cpu/$lines;
	#							$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{jobs}{$job}{'load_peak'}=$max_cpu;
	#							$totalcpu+=$total_cpu/$lines; #add to total, will be divided by runs
	#							&_print_log(3, "loadavg: $total_cpu/$lines\n");
	#							&_print_log(3, "loadmax: $max_cpu\n");
							}
							if ($user_runzpooliostat)
				    	{
					    	my $zpooliostat_result=&_handle_iostat_output("$async_paths{$dslong2}{iostat}{$run}{log}",$_pool);
					    	$ddtests{$mastertestid}{details}{zpool}{"run$run"}=$zpooliostat_result;
	
	#							my $iostatfile = "${datapath}/${ppid}_zpooliostat_${dslong2}_$type.log";
	#							open ( my $ziohandle, '<', "$iostatfile");
	#							my ($r_ops,$w_ops,$r_bw,$w_bw,$total_r_ops,$total_w_ops,$total_r_bw,$total_w_bw,$lines)=(0,0,0,0,0,0,0,0,0);
	#
	#							foreach my $line (<$ziohandle>)
	#							{
	#								next if ($line !~/$_pool/); #only get the current pool's lines
	#								#                    capacity     operations    bandwidth
	#								#_pool              alloc   free   read  write   read  write
	#								#----------------  -----  -----  -----  -----  -----  -----
	#								#p_m2_vd-1_offs-0  1.91G   370G      0  5.44K  5.28K  65.7M
	#								if ($line=~/$_pool\s+.+?\s+.+?\s+(.+?)\s+(.+?)\s+(.+?)\s+(.+?)\s*$/)
	#								{
	#									$r_ops=&_get_as_bytes($1);
	#									$w_ops=&_get_as_bytes($2);
	#									$r_bw=&_get_as_bytes($3);
	#									$w_bw=&_get_as_bytes($4);
	#									$lines++; # assume we ran every second, so we average by dividing by lines
	#									$total_r_ops+=$r_ops;
	#									$total_w_ops+=$w_ops;
	#									$total_r_bw+=$r_bw;
	#									$total_w_bw+=$w_bw;
	#									&_print_log(3, "$line"); #has newline
	#									&_print_log(3,  "1-4 -> $1, $2, $3, $4 || r_ops, w_ops, r_bw, w_bw -> $r_ops, $w_ops, $r_bw, $w_bw || total-> $total_r_ops,$total_w_ops,$total_r_bw,$total_w_bw\n");
	#
	#								}
	#							}
	#							close $ziohandle;
	#							$lines=1 unless ($lines); #prevent division by 0 error. If we didnt match any lines total_cpu is 0 too so no problem
	#							$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_r_ops'}=$total_r_ops/$lines;
	#							$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_w_ops'}=$total_w_ops/$lines;
	#							$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_r_bw'}=$total_r_bw/$lines;
	#							$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_w_bw'}=$total_w_bw/$lines;
	#							#$ddtests{$mastertestid}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_r_bw_mb'}=&_get_as($total_r_bw/$lines,'M');;
	#							#$ddtests{$mastertestid}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_w_bw_mb'}=&_get_as($total_w_bw/$lines,'M');;
	#							$totalrios+=$total_r_ops/$lines; #add to total, will be divided by runs
	#							$totalwios+=$total_w_ops/$lines; #add to total, will be divided by runs
	#							$totalrbw+=$total_r_bw/$lines; #add to total, will be divided by runs
	#							$totalwbw+=$total_w_bw/$lines; #add to total, will be divided by runs
							}

				  	} #/JOB Loop
				  	&_print_log(2, "...done\n");

				  	#my $jobtotal_mb=&_get_as($jobtotal,'M');
				  	my $avg_bytes_per_job=$jobtotal/$instcnt;
				  	my $avg_duration_per_job=$jobtotalduration/$instcnt;
				  	#my $avg_bytes_per_job_mb=&_get_as($avg_bytes_per_job,'M');

				  	my $avg_load_per_job=$totalcpu/$instcnt; # from psaux
				  	my $avg_rios_per_job=$totalrios/$instcnt; # from zpool_iostat
				  	my $avg_wios_per_job=$totalwios/$instcnt; # from zpool_iostat
				  	my $avg_rbw_per_job=$totalrbw/$instcnt; # from zpool_iostat
				  	my $avg_wbw_per_job=$totalwbw/$instcnt; # from zpool_iostat


						$ddtests{$mastertestid}{details}{"${type}_total_bytes_all_jobs"}{"run$run"}=$jobtotal;
						$ddtests{$mastertestid}{details}{"${type}_total_duration_all_jobs"}{"run$run"}=$jobtotalduration;
						$ddtests{$mastertestid}{details}{"${type}_avg_bytes_per_job"}{"run$run"}=$avg_bytes_per_job;
						$ddtests{$mastertestid}{details}{"${type}_avg_duration_per_job"}{"run$run"}=$avg_duration_per_job;
						$ddtests{$mastertestid}{details}{"${type}_avg_load_per_job"}{"run$run"}=$avg_load_per_job;
						$ddtests{$mastertestid}{details}{"${type}_avg_rios_per_job"}{"run$run"}=$avg_rios_per_job;
						$ddtests{$mastertestid}{details}{"${type}_avg_wios_per_job"}{"run$run"}=$avg_wios_per_job;
						$ddtests{$mastertestid}{details}{"${type}_avg_rbw_per_job"}{"run$run"}=$avg_rbw_per_job;
						$ddtests{$mastertestid}{details}{"${type}_avg_wbw_per_job"}{"run$run"}=$avg_wbw_per_job;
						
						
				  	#$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{jobtotal}=$jobtotal;
				  	#$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{jobtotalduration}=$jobtotalduration;
				  	#$ddtests{$mastertestid}{$type}{runs}{$run}{results}{jobtotal_mb}=$jobtotal_mb;
				  	#$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{avg_bytes_per_job}=$avg_bytes_per_job;
				  	##$ddtests{$mastertestid}{$type}{runs}{$run}{results}{avg_bytes_per_job_mb}=$avg_bytes_per_job_mb;
				  	#$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{avg_load_per_job}=$avg_load_per_job;
				  	#$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{avg_rios_per_job}=$avg_rios_per_job;
				  	#$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{avg_wios_per_job}=$avg_wios_per_job;
				  	#$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{avg_rbw_per_job}=$avg_rbw_per_job;
				  	#$ddtests{$mastertestid}{details}{$type}{runs}{$run}{results}{avg_wbw_per_job}=$avg_wbw_per_job;

				  	$runtotal+=$jobtotal; #summarize job total r/w amount to a runtotal. This will be averaged by runtotal/#runs

				  	$ddtestnr++;
				  	sleep $dd_sleeptime;

				  }
			    &_print_log(0, "TestID:$mastertestid/$total_test_runs:\tBS:$bs\t$instcnt\tparallel jobs-> All ($dd_runs_per_test) runs done, type $type\n");

				  my $avg_per_run=$runtotal/$dd_runs_per_test;
				  #my $avg_per_run_mb=&_get_as($avg_per_run,'M');

					$ddtests{$mastertestid}{details}{"${type}_avg_per_run"}{"run$run"}=$avg_per_run;
					
				  #$ddtests{$mastertestid}{summary}{$type}{avg_per_run}=$avg_per_run;
				  #$ddtests{$mastertestid}{summary}{"avg_per_run_${type}"}=$avg_per_run;
				  #$ddtests{$mastertestid}{results}{avg_per_run_mb}=$avg_per_run_mb;


		    }
		  }
		  &_print_log(2, "Test $mastertestid done\n");
		  &_create_averages_min_max($mastertestid);
			$mastertestid++;
		  $masterresultid++;
		  &_do_regular_output('test');
#		  print Dumper \%ddtests;
		}
	}



}


#this sub takes __all_pools & all_cache_slog_combinations and combines them, then sorts them to have a proper order which minimizes pool activties
#this is intended to prevent the need to destroy and recreate pools that could be extended or modified by adding vdevs/cache/slog or removing l2arc/cache
#this o/c only matters for staggered pools (as we extend these by one vdev at a time usually), and for the log/cache options where
# add and remove might be cheaper/easier than drop and recreate
#
#atm we sort but don't provide an optimized creation strategy, we simply do drop / recreate
#
sub _combine_and_reorder_pools_and_cache_slog_options
{
	#print Dumper \%__all_pools;
	#$__all_pools{$___pool}="full";
	#%__l2arc_slog_combinations{"l2-${_current_l2arcoption}_sl-${_current_slogoption}"};


	my $__mastertestid=1;
	my ($key, $p_i, $p_s, $p_f,$csc);
	my (@full,@staggered,@individual);

	foreach my $pool (keys %__all_pools)
	{
		#print "$pool => $__all_pools{$pool}\n";
		push @full, $pool if ($__all_pools{$pool} =~/full/);
		push @staggered, $pool if ($__all_pools{$pool} =~/staggered/);
		push @individual, $pool if ($__all_pools{$pool} =~/individual/);
	}

	$p_f=keys @full;
	$p_i=keys @individual;
	$p_s=keys @staggered;
	$csc= scalar keys %__l2arc_slog_combinations;


	foreach my $pool (sort @full)
	{
		foreach my $l2sl (sort keys %__l2arc_slog_combinations)
		{
			$key = sprintf("%05d", "$__mastertestid");

			$_masterpoollist{$key}{name}="${pool}_$l2sl";
			$_masterpoollist{$key}{layout}="full";
		#	print "${pool}_$l2sl\n";

			#print "testid= $__mastertestid, key =$key\n";
			$__mastertestid++;
		}
	}
	foreach my $pool (sort @staggered)
	{
		foreach my $l2sl (sort keys %__l2arc_slog_combinations)
		{
			$key = sprintf("%05d", "$__mastertestid");
			$_masterpoollist{$key}{name}="${pool}_$l2sl";
			$_masterpoollist{$key}{layout}="staggered";
			#print "${pool}_$l2sl\n";
			$__mastertestid++;
		}

	}
	foreach my $pool (sort @individual)
	{
		foreach my $l2sl (sort keys %__l2arc_slog_combinations)
		{
			$key = sprintf("%05d", "$__mastertestid");

			$_masterpoollist{$key}{name}="${pool}_$l2sl";
			$_masterpoollist{$key}{layout}="individual";
			#print "${pool}_$l2sl\n";
			$__mastertestid++;
		}
	}


	$totalpools=$__mastertestid - 1;	
	&_print_log(0, "Defined $totalpools combinations of pools total ($p_f full + $p_i individual +  $p_s staggered times $csc cache/log options)\n");
	foreach my $test (sort (keys %_masterpoollist))
	{
		push @_report_pools, "pool $test/$totalpools = $_masterpoollist{$test}{name}";
	}
	
	#print Dumper \@full;
	#print Dumper \@staggered;
	#print Dumper \@individual;
	#print Dumper \%__l2arc_slog_combinations;
}


#This sub creates a list (deduplicated) of all pool combinations based on type, redundancy and selected layout options. Slog/Cache are not included here.
sub _calculate_pool_options_extended()
{
	&_print_log(3, "Entering _calculate_pool_options_extended\n");
	#my @uservar_vdev_type=('single','z1','z2','z3');
	#my @uservar_vdev_redundancy=('single','stripe','mirror');
	#extend for wider mirrors
	#my @uservar_vdev_mirrortypes=(2,3);
	#how many devices will be in a stripe at maximum stripe width. 0 = all available
	#note this means a lot of pools when used in combination with layout=individual below
	#my $uservar_max_stripewidth=0;
	#provide different build pool options, valid combinations are 1+2, 2+3, 1 only, 2 only, 3 only
	#1. Build one big pool out of all possible vdevs (vdev_layout_full)
	#2. Build n single vdevs individually to compare one vdev against the next (identify faulty disks) (vdev_layout_individual)
	#3. Build staggered vdevs from minimum to maximum amount (vdev_layout_staggered) (i.e. pool of 1 vdev, then pool of 2 vdevs and so on until max vdevs)
	#my $_vdev_layout_staggered=$uservar_vdev_layout_staggered;
	#my $_vdev_layout_full=$uservar_vdev_layout_full;
	#my $_vdev_layout_individual=$uservar_vdev_layout_individual;

	#my $nr_disks = keys %_pooldisks;

	my $nr_disks=0;
	foreach my $_d (keys %_pooldisks)
	{
		$nr_disks++ if ($_d=~/^\d+$/); #only count data disks here (which have a numeric position), not slog1/2, l2arc1/2
		&_print_log(4, "calculating pool - got disk $_d\n");
	}
	&_print_log(2, "calculating pool - found $nr_disks data drives\n");
	#we assume that if the dev key exists we also got the disk id
	&_print_log(2, "calculating pool - found slogdevice1 ($_pooldisks{'slogdev'}{id})\n") if exists ($_pooldisks{'slogdev'});
	&_print_log(2, "calculating pool - found slogdevice2 ($_pooldisks{'slogdev2'}{id})\n") if exists ($_pooldisks{'slogdev2'});
	&_print_log(2, "calculating pool - found l2arcdevice1 ($_pooldisks{'l2arcdev'}{id})\n") if exists ($_pooldisks{'l2arcdev'});
	&_print_log(2, "calculating pool - found l2arcdevice2 ($_pooldisks{'l2arcdev2'}{id})\n") if exists ($_pooldisks{'l2arcdev2'});



	my $_single_vdev_size=0;
	my $_vdev_red_size=0;
	my $_max_stripewidth=($uservar_max_stripewidth || $nr_disks); #if max_stripewidth is not set set to max disks
	&_print_log(3, "Max stripewidth set to $_max_stripewidth\n");
	&_print_log(4, "Max stripewidth based on uservar_max_stripewidth=$uservar_max_stripewidth && nr_disks=$nr_disks\n");
	
	my $_vdevs=0;
	#@uservar_vdev_type=('single','z1','z2','z3');
	foreach my $_vdevtype (@uservar_vdev_type)
	{
		&_print_log(3, "now working on vdevtype $_vdevtype\n");
		$_single_vdev_size=1 if ($_vdevtype=~/sin/); #type single
		$_single_vdev_size=$_diskcount_z1 if ($_vdevtype=~/z1/); #type z1
		$_single_vdev_size=$_diskcount_z2 if ($_vdevtype=~/z2/); #type z2
		$_single_vdev_size=$_diskcount_z3 if ($_vdevtype=~/z3/); #type z3
		die "unexpected device type $_vdevtype" unless ($_single_vdev_size); #if 0 then no value has been set

		#@uservar_vdev_redundancy=('single','stripe','mirror');
		#@uservar_vdev_redundancy=('no','str','mir);
		foreach my $_vdevred (@uservar_vdev_redundancy)
		{
			&_print_log(3, "now working on redundancy type $_vdevred\n");
			if ($_vdevred =~/no/)
			{
				$_vdev_red_size=1;
				$_vdevs=int $nr_disks / ($_single_vdev_size * $_vdev_red_size) ;

				$_vdevs{"${_vdevtype}_${_vdevred}0${_vdev_red_size}"}=$_vdevs if (${_vdev_red_size} <10);
				$_vdevs{"${_vdevtype}_${_vdevred}${_vdev_red_size}"}=$_vdevs if (${_vdev_red_size} >=10);
			}
			elsif ($_vdevred =~/mir/)
			{
				#Mirror of Raid Z vdevs will not work
				next if ($_vdevtype=~/z1/); #type z1
				next if ($_vdevtype=~/z2/); #type z2
				next if ($_vdevtype=~/z3/); #type z3

				foreach my $_mirrorwidth (@uservar_vdev_mirrortypes)
				{
				if ($_mirrorwidth == 1 )
				{
						&_print_log(1, "Minimum mirror width is 2 - adjusting (was $_mirrorwidth) \n");
					$_mirrorwidth=2;
				}

						$_vdev_red_size=$_mirrorwidth;
						$_vdevs=int $nr_disks / ($_single_vdev_size * $_vdev_red_size) ;

						$_vdevs{"${_vdevtype}_${_vdevred}0${_vdev_red_size}"}=$_vdevs if (${_vdev_red_size} <10);
						$_vdevs{"${_vdevtype}_${_vdevred}${_vdev_red_size}"}=$_vdevs if (${_vdev_red_size} >=10);

				}
			}
			elsif ($_vdevred =~/str/) #
			{
				# anything below 2 does not make sense (1=single)
				foreach my $_stripewidth (2 .. (int $_max_stripewidth/$_single_vdev_size))
				{
						$_vdev_red_size=$_stripewidth;
						$_vdevs=int $nr_disks / ($_single_vdev_size * $_vdev_red_size) ;
						
						&_print_log(4, "stripewidth = $_stripewidth, _single_vdev_size=$_single_vdev_size, max vdevs=$_vdevs \n");
						$_vdevs{"${_vdevtype}_${_vdevred}0${_vdev_red_size}"}=$_vdevs if (${_vdev_red_size} <10);
						$_vdevs{"${_vdevtype}_${_vdevred}${_vdev_red_size}"}=$_vdevs if (${_vdev_red_size} >=10);
				}
			}
			else
			{
				die "unexpected redundancy type $_vdevred";
			}
		}
	}
	
#	print "2071:", Dumper \%_pooldisks;
	#print "vdevs", Dumper \%_vdevs;
#	check_exist da0                                                           #check_exist da0
#check_exist da1                                                            #check_exist da1
#check_exist da2                                                            #check_exist da2
#check_exist /dev/da3                                                       #check_exist /dev/da3
#$VAR1 = {                                                                  #check_exist /dev/da4
#          'z1_stripe_3' => 0,                                              #check_exist /dev/da5
#          'single_single_1' => 4,                                          #check_exist /dev/da6
#          'z3_stripe_2' => 0,                                              #check_exist /dev/da7
#          'z3_single_1' => 0,                                              #check_exist /dev/da8
#          'z1_stripe_2' => 0,                                              #check_exist /dev/da9
#          'z3_mirror_3' => 0,                                              #check_exist /dev/da10
#          'single_stripe_2' => 2,                                          #$VAR1 = {
#          'z3_mirror_2' => 0,                                              #          'single_stripe_2' => 5,
#          'single_stripe_3' => 1,                                          #          'z1_mirror_3' => 0,
#          'z1_mirror_3' => 0,                                              #          'z1_single_1' => 2,
#          'single_mirror_2' => 2,                                          #          'single_stripe_11' => 1,
#          'z1_mirror_2' => 0,                                              #          'single_stripe_6' => 1,
#          'single_stripe_4' => 1,                                          #          'single_stripe_4' => 2,
#          'single_mirror_3' => 1,                                          #          'single_mirror_2' => 5,
#          'z3_stripe_4' => 0,                                              #          'z1_mirror_2' => 1,
#          'z1_stripe_4' => 0,                                              #          'single_mirror_3' => 3,
#          'z1_single_1' => 0,                                              #          'z3_mirror_2' => 0,
#          'z3_stripe_3' => 0                                               #          'z1_stripe_2' => 1,
#        };                                                                 #          'z3_mirror_3' => 0,
                                                                            #          'single_stripe_5' => 2,
                                                                            #          'single_single_1' => 11,
                                                                            #          'single_stripe_8' => 1,
                                                                            #          'single_stripe_9' => 1,
                                                                            #          'z3_single_1' => 1,
                                                                            #          'single_stripe_10' => 1,
                                                                            #          'single_stripe_7' => 1,
                                                                            #          'single_stripe_3' => 3
                                                                            #        };
  my $_offset=0;
  my $_currentvdev=1;
	foreach my $k (sort keys %_vdevs)
	{
		my $max_vdvs= $_vdevs{$k};

		next unless $max_vdvs; #skip if we can't build any vdevs for the selected combination

		&_print_log(2, "Total disks: $nr_disks, vdev_layout $k => $max_vdvs\n");
	}


	foreach my $k (sort keys %_vdevs)
	{
		my $max_vdvs= $_vdevs{$k};
		next unless $max_vdvs; #skip if we can't build any vdevs for the selected combination

		#get details: _vdevtype, vdevred, vdev_red_size
		my @__poolinfo= split /_/ , $k;

		my $_vls=$uservar_vdev_layout_staggered; 	#get global var
		my $_vlf=$uservar_vdev_layout_full; 			#get global var
		my $_vli=$uservar_vdev_layout_individual;	#get global var

			#&_print_log(3, "$k, vdevs=$max_vdvs full=$_vlf, staggered=$_vls, individual=$_vli\n");

				if ($max_vdvs == 1)
				{
					$_vls=0;
					$_vli=0;
					&_print_log(3, "Skipping staggered & individual layouts for type $k since only single vdev possible\n");
				}
				#1. Build one big pool out of all possible vdevs (vdev_layout_full)
				if ($_vlf)
				{
					&_print_log(3, "pool-type \"$k\", layout full selected ($max_vdvs vdevs)\n");
###				&_create_single_pool_and_run_tests($type,$max_vdvs,$_offset); #eg handover 8 as nr vdevs for 16 disks, will build a 8 way mirror, offset 0
					my $___pool; # "p_${k}_v${max_vdvs}_o${_offset}"; #set poolname
					$___pool="p_${k}_v0${max_vdvs}" if (${max_vdvs} <10);#set poolname
					$___pool="p_${k}_v${max_vdvs}" if (${max_vdvs} >=10);#set poolname
					$___pool.="_o0${_offset}" if (${_offset} <10);#set poolname
					$___pool.="_o${_offset}"  if (${_offset} >=10);#set poolname

					push  @__all_pools, $___pool;
					$__all_pools{$___pool}="full";
				}

				#2. Build n single vdevs individually to compare one vdev against the next (identify faulty disks) (vdev_layout_individual)
				if ($_vli)
				{

					$_currentvdev=1;
					for ($_currentvdev .. $max_vdvs)
					{
							&_print_log(3, "pool-type \"$k\", layout individual selected ($_currentvdev/$max_vdvs x different single vdev), current offset=$_offset\n");

							my $___pool;
							$___pool="p_${k}_v0${_currentvdev}" if (${_currentvdev} <10);#set poolname
							$___pool="p_${k}_v${_currentvdev}" if (${_currentvdev} >=10);#set poolname
							$___pool.="_o0${_offset}" if (${_offset} <10);#set poolname
							$___pool.="_o${_offset}"  if (${_offset} >=10);#set poolname

							push  @__all_pools, $___pool;
							$__all_pools{$___pool}="individual";
###						&_create_single_pool_and_run_tests($type,1,$_offset); #will call with 1 as nr vdevs for 16 disks, will build 8 different mirrors; offset 1 vdev per run
						$_currentvdev++;
						$_offset++; #one vdev offset for next run
					}
				}
				$_offset=0; #reset offset
				$_currentvdev=1; #reset currentvdev
				#3. Build staggered vdevs from minimum to maximum amount (vdev_layout_staggered) (i.e. pool of 1 vdev, then pool of 2 vdevs and so on until max vdevs)
				if ($_vls)
				{
					$_currentvdev=1;
					for ($_currentvdev .. $max_vdvs)
					{
						&_print_log(3, "pool-type \"$k\", layout staggered selected (current vdev = $_currentvdev, up to $max_vdvs vdevs) current offset=$_offset\n");
###					&_create_single_pool_and_run_tests($type,$_currentvdev,$_offset); #will call with 1..8 as nr vdevs for 16 disks, will build 8 different mirrors; offset 0

						my $___pool;
						$___pool="p_${k}_v0${_currentvdev}" if (${_currentvdev} <10);#set poolname
						$___pool="p_${k}_v${_currentvdev}" if (${_currentvdev} >=10);#set poolname
						$___pool.="_o0${_offset}" if (${_offset} <10);#set poolname
						$___pool.="_o${_offset}"  if (${_offset} >=10);#set poolname

						push  @__all_pools, $___pool;
						$__all_pools{$___pool}="staggered";
						$_currentvdev++;
					}
				}
			$_offset=0; #reset offset
			$_currentvdev=1; #reset currentvdev
			#create single pool found an issues - most likely with slog or l2arc device and wants us to skip this test

	}

	&_print_log(4, "__all_pools HASH elements:".scalar (keys %__all_pools)."\n");
	&_print_log(4, "__all_pools ARRAY elements:".scalar  @__all_pools."\n");

	#print "__all_pools", Dumper \%__all_pools;
	
	#foreach my $ap (sort keys %__all_pools)
	#{
	#	&_print_log(0, "$ap (from layout $__all_pools{$ap})\n");
	#}
	&_print_log(3, "Exiting _calculate_pool_options_extended\n");
}

sub _handle_user_given_pool () #handle multiple user pools?
{
		
	my $_masterpoolid=1;
	&_print_log(3, "Entering _handle_user_given_pool\n");
	foreach my $_userpoolname (sort keys %_userpool_info)
	{
		my $key = sprintf("%05d", $_masterpoolid);

		$_masterpoollist{$key}{name}="$_userpoolname";
		$_masterpoollist{$key}{layout}=$_userpool_info{$_userpoolname}{layout};
		
		
		$_pools{$_masterpoolid}{name}=$_userpoolname;
		$_pools{$_masterpoolid}{status}=1; #set pool activce
		$_pools{$_masterpoolid}{nr_vdevs}=$_userpool_info{$_userpoolname}{vdevs};
		$_pools{$_masterpoolid}{nr_vdevs}=$_userpool_info{$_userpoolname}{vdevs};
		$_pools{$_masterpoolid}{offset}=0;
		$_pools{$_masterpoolid}{diskspervdev}=$_userpool_info{$_userpoolname}{diskcnt};
		
		$_pools{$_masterpoolid}{"type_tech"}=$_userpool_info{$_userpoolname}{layout};
		$_pools{$_masterpoolid}{"type_verbose"}=$_userpool_info{$_userpoolname}{layout};

		$_pools{$_masterpoolid}{nr_l2arc_devs}=$_userpool_info{$_userpoolname}{cachecnt};
		$_pools{$_masterpoolid}{nr_slog_devs}=$_userpool_info{$_userpoolname}{slogcnt};
		$_pools{$_masterpoolid}{slogoptionlong}="userpool";
		$_pools{$_masterpoolid}{slog1}="userpool";
		$_pools{$_masterpoolid}{slog2}="userpool";
		$_pools{$_masterpoolid}{l2arcoptionlong}="userpool";
		$_pools{$_masterpoolid}{l2arc1}="userpool";
		$_pools{$_masterpoolid}{l2arc2}="userpool";
		
		
		
		#$poolinfo{"$_p"}{"found"}=$foundpool;
		#$poolinfo{"$_p"}{"state"}=$state;
		#$poolinfo{"$_p"}{"layout"}=$layout;
		#$poolinfo{"$_p"}{"vdevs"}=$vdevs;
		#$poolinfo{"$_p"}{"diskcnt"}=$diskcnt;
		#$poolinfo{"$_p"}{"slogcnt"}=$slogcnt;
		#$poolinfo{"$_p"}{"cachecnt"}=$cachecnt;

		
		
	
		$totalpools++;
		$poolnr++;
		$_historic_pool_list{${_userpoolname}}=$_masterpoolid;
		&_create_datasets($_masterpoolid); #create datasets within this pool
		&_run_tests($_masterpoolid); # run tests on all datasets of this pool
		&_destroy_datasets($_masterpoolid);	#remove this pools datasets
		$_masterpoolid++;
		&_do_regular_output('pool');
	}
	 
	
	
	&_print_log(3, "Exiting _handle_user_given_pool\n");
}


sub _print_disclaimer()
{

#"***** Use at your own risk - this script should maintain existing pools but no warranty ******" unless $force_pool_creation;
	#"***** Use at your own risk - this script is set to **force** pool creation              ******" if $force_pool_creation;
	my $disclaimer = <<"EOF";
*************************************************************************************************
*************************************************************************************************
* This script can run for a very long time, best call it with                                \t*
*                             <nohup perl $0 &>                                              \t*
* to prevent test result data loss                                                           \t*
*                                                                                            \t*
*                                                                                            \t*
* Note: if the script fails at 'zpool add' with <pool not found> wipe the errored vdevs      \t*
* disks in the old FreeNas Gui (only one disk at a time currently possible).                 \t*
*                                                                                            \t*
* Pid = $$ => Follow processing with tail -f pool_test.pl.$$.log                             \t*
*************************************************************************************************
*           run <touch $stopfile> to stop processing gracefully                              \t*
*           run <touch $infofile> to get runtime info on tests et al                         \t*
*           run <touch $reporttouchfile> to get a current report file                        \t*
*           run <touch $loglevel1touchfile .. $loglevel4touchfile> to set loglevel to 1..4   \t*
*************************************************************************************************
EOF
	print "$disclaimer\n";
	sleep 10;
}

sub _fill_master_report_info
{
	my ($_chapter,$id,$key,$short,$long,$isstring,$ccomma,$cunit,$iunit,$dt,$dtl)=@_;
	$_out_masterreport_info{$_chapter}{$id}{key}=$key;
	$_out_masterreport_info{$_chapter}{$id}{label_short}=$short;
	$_out_masterreport_info{$_chapter}{$id}{label_long}=$long;
	$_out_masterreport_info{$_chapter}{$id}{isstring}=$isstring;  
	$_out_masterreport_info{$_chapter}{$id}{needs_output_conversion_comma}=$ccomma;
	$_out_masterreport_info{$_chapter}{$id}{needs_output_conversion_unit}=$cunit;
	$_out_masterreport_info{$_chapter}{$id}{isunit}=$iunit;
	#datatype needs to be converted, it arrives in a format like VARCHAR, where VARCHAR is the generic datatype (which will be translated to selected Database output datatype, and 1024 is the length if applicable. If not -0 will ignore the le
	$_out_masterreport_info{$_chapter}{$id}{Datatype}=$DBDataTypes{$useDB}{$dt};
	#datatype length, value or 0 if not applicable 
	$_out_masterreport_info{$_chapter}{$id}{DatatypeLength}=$dtl;
	&_print_log(4, "fmri: $_chapter,$id,$key,$short,$long,$isstring,$ccomma,$cunit,$iunit \n");
	
	$map_short_to_long{$short}="$long";
	
	$id++;
	return $id;
}

sub _define_master_report
{
	
	#_1_Pool
	#nrvdevs
	my $count=0;
	$count=&_fill_master_report_info('_1_Pool',$count,'nr_vdevs','Nr_of_vdevs','Number of vDevs in pool',1,0,0,'',"INT",0);
	$count=&_fill_master_report_info('_1_Pool',$count,'diskspervdev','disks_per_vdev','Number of disks per vDevs in pool',1,0,0,'',"INT",0);
	$count=&_fill_master_report_info('_1_Pool',$count,'type_verbose','Pooltype','Pool type and redundancy',1,0,0,'',"STRING",64);
	$count=&_fill_master_report_info('_1_Pool',$count,'nr_l2arc_devs','Nr_of_l2arc_devs','Number of L2Arc devices in Pool',1,0,0,'',"INT",0);
	$count=&_fill_master_report_info('_1_Pool',$count,'l2arcoptionlong','l2arcoption','Configuration of L2 Arc devices',1,0,0,'',"STRING",64);
	$count=&_fill_master_report_info('_1_Pool',$count,'l2arc1','l2arc1','L2 Arc device 1',1,0,0,'',"STRING",64);
	$count=&_fill_master_report_info('_1_Pool',$count,'l2arc2','l2arc2','L2 Arc device 2',1,0,0,'',"STRING",64);
	
	$count=&_fill_master_report_info('_1_Pool',$count,'nr_slog_devs','Nr_of_slog_devs','Number of sLog devices in Pool',1,0,0,'',"INT",0);
	$count=&_fill_master_report_info('_1_Pool',$count,'slogoptionlong','slogoption','Configuration of sLog devices',1,0,0,'',"STRING",32);
	$count=&_fill_master_report_info('_1_Pool',$count,'slog1','slog1','slog device 1',1,0,0,'',"STRING",64);
	$count=&_fill_master_report_info('_1_Pool',$count,'slog2','slog2','slog device 2',1,0,0,'',"STRING",64);

	
	#_2_vDev
	#Nothing here for now
	
	#_3_dataset
	
	$count=0; #reset
	$count=&_fill_master_report_info('_3_dataset',$count,'zfs_sync_options','sync','dataset sync option',1,0,0,'',"STRING",64);
	$count=&_fill_master_report_info('_3_dataset',$count,'zfs_compression_options','compression','dataset sync option',1,0,0,'',"STRING",64);
	$count=&_fill_master_report_info('_3_dataset',$count,'zfs_metadata_options','metadata','dataset metadata option',1,0,0,'',"STRING",64);
	$count=&_fill_master_report_info('_3_dataset',$count,'zfs_recordsizes','zfs_recordsize','dataset recordsize',1,0,0,'',"STRING",8);
                               
	#_4_test_Meta_DD
#	dd_blocksizes	dd_num_jobs	runs_per_test	TestFileSize
#4k,"8k","64k","128k","512k","1M","4M"	1,2,4,8,16,32	1-5	10G

	$count=0; #reset
	$count=&_fill_master_report_info('_4_test_Meta_DD',$count,'bs','Blocksize','dd blocksize',1,0,0,'',"STRING",8);
	$count=&_fill_master_report_info('_4_test_Meta_DD',$count,'jobs','parallel_jobs','DD Number of parallel jobs',0,0,0,'',"INT",0);
	$count=&_fill_master_report_info('_4_test_Meta_DD',$count,'dd_runs_per_test','runs_per_test','dd nr of runs per test',0,0,0,'',"INT",0);
	$count=&_fill_master_report_info('_4_test_Meta_DD',$count,'dd_file_size_bytes','testfilesize','size of the testfile',0,0,1,'b',"BIGINT",0);
	
	#_5_test_Primary_DD	
	
	$count=0; #reset
	
	foreach my $type ('read','write')	
	{
		
		my $mintext="(minimum of all runs)";
		my $avgtext="(average of all runs)";
		my $maxtext="(maximum of all runs)";
#		my $basetext="System CPU utilization";
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_total_bytes_all_jobs_min","${type}_total_bytes_all_jobs_min","Total bytes $type over all jobs $mintext",0,1,1,'b',"BIGINT",0);
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_total_bytes_all_jobs_avg","${type}_total_bytes_all_jobs_avg","Total bytes $type over all jobs $avgtext",0,1,1,'b',"BIGINT",0);
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_total_bytes_all_jobs_max","${type}_total_bytes_all_jobs_max","Total bytes $type over all jobs $maxtext",0,1,1,'b',"BIGINT",0);
		
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_total_duration_all_jobs_min","${type}_total_duration_all_jobs_min","Total duration $type over all jobs $mintext",0,1,1,'s',"FLOAT",2);
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_total_duration_all_jobs_avg","${type}_total_duration_all_jobs_avg","Total duration $type over all jobs $avgtext",0,1,1,'s',"FLOAT",2);
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_total_duration_all_jobs_max","${type}_total_duration_all_jobs_max","Total duration $type over all jobs $maxtext",0,1,1,'s',"FLOAT",2);
		
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_avg_bytes_per_job_min","${type}_avg_bytes_per_job_min","Average bytes $type per job $mintext",0,1,1,'b',"FLOAT",2);
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_avg_bytes_per_job_avg","${type}_avg_bytes_per_job_avg","Average bytes $type per job $avgtext",0,1,1,'b',"FLOAT",2);
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_avg_bytes_per_job_max","${type}_avg_bytes_per_job_max","Average bytes $type per job $maxtext",0,1,1,'b',"FLOAT",2);
		
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_avg_duration_per_job_min","${type}_avg_duration_per_job_per_job_min","Average duration $type per job $mintext",0,1,1,'b',"FLOAT",2);
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_avg_duration_per_job_avg","${type}_avg_duration_per_job_per_job_avg","Average duration $type per job $avgtext",0,1,1,'b',"FLOAT",2);
		$count=&_fill_master_report_info('_5_test_Primary_DD',$count,"${type}_avg_duration_per_job_max","${type}_avg_duration_per_job_per_job_max","Average duration $type per job $maxtext",0,1,1,'b',"FLOAT",2);
		
	}	
	
	#_6_test_Secondary_DD
	$count=0; #reset
	foreach my $type ('read','write')	
	{		
		my $mintext="(minimum of all runs)";
		my $avgtext="(average of all runs)";
		my $maxtext="(maximum of all runs)";

		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_rios_per_job_min","${type}_avg_rios_per_job_min","Average Read IOS during $type per job $mintext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_rios_per_job_avg","${type}_avg_rios_per_job_avg","Average Read IOS during $type per job $avgtext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_rios_per_job_max","${type}_avg_rios_per_job_max","Average Read IOS during $type per job $maxtext",0,0,1,'',"FLOAT",2);
		
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_wios_per_job_min","${type}_avg_wios_per_job_min","Average Write IOS during $type per job $mintext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_wios_per_job_avg","${type}_avg_wios_per_job_avg","Average Write IOS during $type per job $avgtext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_wios_per_job_max","${type}_avg_wios_per_job_max","Average Write IOS during $type per job $maxtext",0,0,1,'',"FLOAT",2);
		
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_load_per_job_min","${type}_avg_load_per_job_min","Average load ($type) per job $mintext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_load_per_job_avg","${type}_avg_load_per_job_avg","Average load ($type) per job $avgtext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_load_per_job_max","${type}_avg_load_per_job_max","Average load ($type) per job $maxtext",0,0,1,'',"FLOAT",2);
		
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_rbw_per_job_min","${type}_avg_rbw_per_job_min","Average Read Bandwith during $type per job $mintext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_rbw_per_job_avg","${type}_avg_rbw_per_job_avg","Average Read Bandwith during $type per job $avgtext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_rbw_per_job_max","${type}_avg_rbw_per_job_max","Average Read Bandwith during $type per job $maxtext",0,0,1,'',"FLOAT",2);
		
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_rbw_per_job_min","${type}_avg_rbw_per_job_min","Average Write Bandwith during $type per job $mintext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_rbw_per_job_avg","${type}_avg_rbw_per_job_avg","Average Write Bandwith during $type per job $avgtext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_rbw_per_job_max","${type}_avg_rbw_per_job_max","Average Write Bandwith during $type per job $maxtext",0,0,1,'',"FLOAT",2);
		
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_wbw_per_job_min","${type}_avg_wbw_per_job_min","Average Write IOS ($type) per job $mintext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_wbw_per_job_avg","${type}_avg_wbw_per_job_avg","Average Write IOS ($type) per job $avgtext",0,0,1,'',"FLOAT",2);
		$count=&_fill_master_report_info('_6_test_Secondary_DD',$count,"${type}_avg_wbw_per_job_max","${type}_avg_wbw_per_job_max","Average Write IOS ($type) per job $maxtext",0,0,1,'',"FLOAT",2);
		
	}	
	
	
	
	
	#_7_test_Meta_fio
	
	$count=0; #reset
	$count=&_fill_master_report_info('_7_test_Meta_fio',$count,'bs','BS','fio blocksize',1,0,0,'',"STRING",8);   	
	$count=&_fill_master_report_info('_7_test_Meta_fio',$count,'fio_runs_per_test','runsPerTest','fio nr of runs per test',0,0,0,'',"INT",0);
	$count=&_fill_master_report_info('_7_test_Meta_fio',$count,'fio_file_size_bytes','testfilesize', 'size of the testfile',0,0,0,'b',"BIGINT",0);
	$count=&_fill_master_report_info('_7_test_Meta_fio',$count,'fio_runtime','runtime','Time the fio test was scheduled to run',0,0,0,'s',"INT",0);
	$count=&_fill_master_report_info('_7_test_Meta_fio',$count,'fio_time_based','timebased','Was fio run timebased',0,0,0,'',"INT",0);
	$count=&_fill_master_report_info('_7_test_Meta_fio',$count,'ioengine','ioengine','Fio ioengine used',1,0,0,'',"STRING",32);
	$count=&_fill_master_report_info('_7_test_Meta_fio',$count,'source','source','Source of the test (user or loop)',1,0,0,'',"STRING",16);
	$count=&_fill_master_report_info('_7_test_Meta_fio',$count,'iodepth','iodepth','IOdepth of the fio run',0,0,0,'',"INT",0);
	$count=&_fill_master_report_info('_7_test_Meta_fio',$count,'numjobs','numjobs','Number of concurrent processes',0,0,0,'',"INT",0);
	$count=&_fill_master_report_info('_7_test_Meta_fio',$count,'testtype','testtype','Type of test being run',1,0,0,'',"STRING",16);
	$count=&_fill_master_report_info('_7_test_Meta_fio',$count,'rwmixread','rwmixread','RWmix read percent',0,0,0,'%',"INT",0);
	

	
	#_8_test_Primary_fio
	
	$count=0;
	my $mintext="(minimum of all runs)";
	my $avgtext="(average of all runs)";
	my $maxtext="(maximum of all runs)";
	my $basetext="System CPU utilization";
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'sys_cpu_min','sys_cpu_min',"$basetext $mintext",0,1,0,'%',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'sys_cpu_avg','sys_cpu_avg',"$basetext $avgtext",0,1,0,'%',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'sys_cpu_max','sys_cpu_max',"$basetext $maxtext",0,1,0,'%',"FLOAT",2);
	
  $basetext="User CPU utilization";
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'usr_cpu_min','usr_cpu_min',"$basetext $mintext",0,1,0,'%',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'usr_cpu_avg','usr_cpu_avg',"$basetext $avgtext",0,1,0,'%',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'usr_cpu_max','usr_cpu_max',"$basetext $maxtext",0,1,0,'%',"FLOAT",2);
	
	$basetext="CPU Context Switches";
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'cpu_ctx_min','cpu_ctx_min',"$basetext $mintext",0,1,0,'',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'cpu_ctx_avg','cpu_ctx_avg',"$basetext $avgtext",0,1,0,'',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'cpu_ctx_max','cpu_ctx_max',"$basetext $maxtext",0,1,0,'',"FLOAT",2);

	$basetext="CPU minor faults ";
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'cpu_minf_min','cpu_minf_min',"$basetext $mintext",0,1,0,'',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'cpu_minf_avg','cpu_minf_avg',"$basetext $avgtext",0,1,0,'',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'cpu_minf_max','cpu_minf_max',"$basetext $maxtext",0,1,0,'',"FLOAT",2);

	$basetext="CPU major faults ";
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'cpu_majf_min','cpu_majf_min',"$basetext $mintext",0,1,0,'',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'cpu_majf_avg','cpu_majf_avg',"$basetext $avgtext",0,1,0,'',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,'cpu_majf_max','cpu_majf_max',"$basetext $maxtext",0,1,0,'',"FLOAT",2);

	foreach my $a (2,4,10,20,50,100,250,500,750,1000)	
	{
		$basetext="Percent calls with latency under $a us";
		$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"latency_us_${a}_min","latency_us_${a}_min","$basetext $mintext",0,1,0,'%',"FLOAT",2);
		$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"latency_us_${a}_avg","latency_us_${a}_avg","$basetext $avgtext",0,1,0,'%',"FLOAT",2);
		$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"latency_us_${a}_max","latency_us_${a}_max","$basetext $maxtext",0,1,0,'%',"FLOAT",2);
	}

	foreach my $z ("read","write")
	{		
		foreach my $a ("slat_ns","clat_ns","lat_ns")
		{
			my $texta;
			$texta="$z submission latency" if ($a=~/slat_ns/);
			$texta="$z completion latency" if ($a=~/clat_ns/);
			$texta="$z total latency" if ($a=~/lat_ns/);
			
			foreach my $b  ("min","mean","stddev","max")
			{		
				my $textb="($a)";
				
				$basetext="$texta $textb";
				$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"${z}_${a}_${b}_min","${z}_${a}_${b}_min","$basetext $mintext",0,1,0,'ns',"FLOAT",2);
				$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"${z}_${a}_${b}_avg","${z}_${a}_${b}_avg","$basetext $avgtext",0,1,0,'ns',"FLOAT",2);
				$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"${z}_${a}_${b}_max","${z}_${a}_${b}_max","$basetext $maxtext",0,1,0,'ns',"FLOAT",2);
			}
		}
		foreach my $a  ("iops_max","iops","iops_min","iops_stddev","iops_mean","bw_max","bw","bw_min","bw_stddev","bw_mean","bw_agg","short_ios","drop_ios","total_ios")
		{					
			my $texta;
			my $unit="";
			$unit="KB" if ($a=~/^bw/);
			$texta="$z IOPS maximum" if ($a=~/iops_max/);
			$texta="$z IOPS " if ($a=~/iops/);
			$texta="$z IOPS minimum" if ($a=~/iops_min/);
			$texta="$z IOPS std deviation" if ($a=~/iops_stddev/);
			$texta="$z IOPS mean" if ($a=~/iops_mean/);
			$texta="$z bandwith maximum" if ($a=~/bw_max/);
			$texta="$z bandwith" if ($a=~/bw/);
			$texta="$z bandwith minimum" if ($a=~/bw_min/);
			$texta="$z bandwith std deviation" if ($a=~/bw_stddev/);
			$texta="$z bandwith mean" if ($a=~/bw_mean/);
			$texta="$z pct of total aggregated bandwith" if ($a=~/bw_agg/);
			$texta="$z short IOs" if ($a=~/short_ios/);
			$texta="$z dropped IOs" if ($a=~/drop_ios/);
			$texta="$z total IOs" if ($a=~/total_ios/);
			
			$basetext="$texta";
			$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"${z}_${a}_min","${z}_${a}_min","$basetext $mintext",0,1,0,$unit,"FLOAT",2);
			$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"${z}_${a}_avg","${z}_${a}_avg","$basetext $avgtext",0,1,0,$unit,"FLOAT",2);
			$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"${z}_${a}_max","${z}_${a}_max","$basetext $maxtext",0,1,0,$unit,"FLOAT",2);
			
		}
	}
	foreach my $a ("min","mean","stddev","max")
	{								
		$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"sync_lat_ns_${a}_min","sync_lat_ns_${a}_min","Sync total latency (ns) $mintext",0,1,0,'ns',"FLOAT",2);
		$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"sync_lat_ns_${a}_avg","sync_lat_ns_${a}_avg","Sync total latency (ns) $avgtext",0,1,0,'ns',"FLOAT",2);
		$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"sync_lat_ns_${a}_max","sync_lat_ns_${a}_max","Sync total latency (ns) $maxtext",0,1,0,'ns',"FLOAT",2);
	
	}
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"sync_total_ios_min","sync_total_ios_min","Sync total IOs $mintext",0,1,0,'',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"sync_total_ios_avg","sync_total_ios_avg","Sync total IOs $avgtext",0,1,0,'',"FLOAT",2);
	$count=&_fill_master_report_info('_8_test_Primary_fio',$count,"sync_total_ios_max","sync_total_ios_max","Sync total IOs $maxtext",0,1,0,'',"FLOAT",2);
	
	#_9_test_Secondary_fio
	
	#print "_out_masterreport_info\n", Dumper \%_out_masterreport_info;
}


sub _print_diskinfo_report
{
	my $reportfile ="report_diskinfo_$$.csv";     
	my $reph;
	#contains all performed tests
	open ( $reph, '>', $reportfile);
	my $header="Name;type;info_sectorsize;info_mediasize_in_bytes;info_mediasize_in_sectors;info_stripesize;info_stripeoffset;info_Cylinders;info_Heads;info_Sectors;info_description;info_identifier;info_TRIM_Support;info_RPM;info_ZoneMode;iooverhead_10MBblock_time;iooverhead_10MBblock_persector;iooverhead_20480sectors_time;iooverhead_20480sectors_persector;iooverhead_overhead_persector;seektimes_Fullstroke_totaltime;seektimes_Fullstroke_periter;seektimes_Halfstroke_totaltime;seektimes_Halfstroke_periter;seektimes_Quarterstroke_totaltime;seektimes_Quarterstroke_periter;seektimes_Shortforward_totaltime;seektimes_Shortforward_periter;seektimes_Shortbackward_totaltime;seektimes_Shortbackward_periter;seektimes_Seqouter_totaltime;seektimes_Seqouter_periter;seektimes_Seqinner_totaltime;seektimes_Seqinner_periter;transferrate_outside_totaltime;transferrate_outside_persec;transferrate_middle_totaltime;transferrate_middle_persec;transferrate_inside_totaltime;transferrate_inside_persec;asyncrandomread_sectorsize_ops;asyncrandomread_sectorsize_totaltime;asyncrandomread_sectorsize_IOPS;asyncrandomread_4k_ops;asyncrandomread_4k_totaltime;asyncrandomread_4k_IOPS;asyncrandomread_32k_ops;asyncrandomread_32k_totaltime;asyncrandomread_32k_IOPS;asyncrandomread_128k_ops;asyncrandomread_128k_totaltime;asyncrandomread_128k_IOPS;syncrandomwrite_0.5k_time;syncrandomwrite_0.5k_mbytes;syncrandomwrite_1k_time;syncrandomwrite_1k_mbytes;syncrandomwrite_2k_time;syncrandomwrite_2k_mbytes;syncrandomwrite_4k_time;syncrandomwrite_4k_mbytes;syncrandomwrite_8k_time;syncrandomwrite_8k_mbytes;syncrandomwrite_16k_time;syncrandomwrite_16k_mbytes;syncrandomwrite_32k_time;syncrandomwrite_32k_mbytes;syncrandomwrite_64k_time;syncrandomwrite_64k_mbytes;syncrandomwrite_128k_time;syncrandomwrite_128k_mbytes;syncrandomwrite_256k_time;syncrandomwrite_256k_mbytes;syncrandomwrite_512k_time;syncrandomwrite_512k_mbytes;syncrandomwrite_1024k_time;syncrandomwrite_1024k_mbytes;syncrandomwrite_2048k_time;syncrandomwrite_2048k_mbytes;syncrandomwrite_4096k_time;syncrandomwrite_4096k_mbytes;syncrandomwrite_8192k_time;syncrandomwrite_8192k_mbytes";

	print $reph "$header\n";
	foreach my $disk (sort keys %diskinfo_testresults)
	{		
		
		my $line='"'.$diskinfo_testresults{$disk}{name}.'"';
		$line.=";".$diskinfo_testresults{$disk}{type}.'"';
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{sectorsize}.'"';
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{mediasize_in_bytes};
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{mediasize_in_sectors};
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{stripesize};
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{stripeoffset};
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{Cylinders};
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{Heads};
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{Sectors};
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{description};
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{identifier};
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{TRIM_Support};
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{RPM};
		$line.=";".$diskinfo_testresults{$disk}{results}{info}{ZoneMode};
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{iooverhead}{'10MBblock'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{iooverhead}{'10MBblock'}{persector});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{iooverhead}{'20480sectors'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{iooverhead}{'20480sectors'}{persector});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{iooverhead}{overhead}{persector});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Fullstroke}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Fullstroke}{periter});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Halfstroke}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Halfstroke}{periter});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Quarterstroke}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Quarterstroke}{periter});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Shortforward}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Shortforward}{periter});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Shortbackward}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Shortbackward}{periter});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Seqouter}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Seqouter}{periter});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Seqinner}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{seektimes}{Seqinner}{periter});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{transferrate}{outside}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{transferrate}{outside}{persec});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{transferrate}{middle}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{transferrate}{middle}{persec});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{transferrate}{inside}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{transferrate}{inside}{persec});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{sectorsize}{ops});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{sectorsize}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{sectorsize}{IOPS});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{'4k'}{ops});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{'4k'}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{'4k'}{IOPS});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{'32k'}{ops});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{'32k'}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{'32k'}{IOPS});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{'128k'}{ops});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{'128k'}{totaltime});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{asyncrandomread}{'128k'}{IOPS});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'0.5k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'0.5k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'1k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'1k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'2k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'2k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'4k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'4k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'8k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'8k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'16k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'16k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'32k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'32k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'64k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'64k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'128k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'128k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'256k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'256k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'512k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'512k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'1024k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'1024k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'2048k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'2048k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'4096k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'4096k'}{mbytes});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'8192k'}{time});
		$line.=";".&_localize_numbers($diskinfo_testresults{$disk}{results}{syncrandomwrite}{'8192k'}{mbytes});
		
		print $reph "$line\n";
	}
	
	close $reph;
}

sub _log_testcommand
{
	my ($command)=($_[0]);
	my $reportfile ="report_diskinfo_$$.csv";     
	my $tcffh;
	#contains all performed tests
	open ( $tcffh, '>>', $testcommands_list_outfile);
	print $tcffh "$command\n";
	close $tcffh;
}


sub _print_master_report
{
	my ($type)=($_[0]);
	my $reportfile ="report_${type}_$$.csv";     
	my $reportfile_map ="report_${type}_${$}_map.csv";  
	my $reph;
	my $rephmap;
	#contains all performed tests
	&_print_log(2,"Printing report\n");			
	open ( $reph, '>', $reportfile);
	
	my $dbcreatefile ="dbcreate_${type}_$$.sql";
	my $dbinsertfile ="dbinsert_${type}_$$.sql";
	unlink $dbcreatefile if -e $dbcreatefile; # should not be necessary but better safe than sorry
	open ( my $dbc, '>', $dbcreatefile);
	
	my $tablename;
	$tablename="pool_test";
	$tablename.="_dd" if $dd_do;
	$tablename.="_fio" if $fio_do;
	my $dbcprefix = "use $_dbname; CREATE TABLE $tablename ( UniqueRunID VARCHAR(32), Testid INT, PRIMARY KEY(UniqueRunID,Testid) ";
	my $dbcpostfix = ");";
	print $dbc $dbcprefix;
	
	
	#INSERT INTO `table_name`(column_1,column_2,...) VALUES (value_1,value_2,...);
	my $dbiprefix = "use $_dbname; INSERT into $tablename (";
	my $dbimiddle = ") VALUES (";
	my $dbipostfix = ");";
	
#'_0_SystemInfo' => {},
#		'_1_Pool' => {},
#		'_2_vDev' => {},
#		'_3_dataset' => {},
#		'_4_test_Meta_DD' => {},
#		'_5_test_Primary_DD' => {},
#		'_6_test_Secondary_DD' => {},
#		'_7_test_Meta_fio' => {},
#		'_8_test_Primary_fio' => {},
#		'_9_test_Secondary_fio' => {}
	
	#######################################
	#print two headers, one short, one long
	#######################################
	#foreach my $label ('label_short','label_long') #print only short label
	foreach my $label ('label_short')
	{
		my $column=0;
		foreach my $part (sort keys %_out_masterreport_info)
		{
			if ($part=~/_\d+_test/) #skip non matching test data
			{
				#skip entries if they are not of the given type
				
				if ($type=~/dd/i)
				{
					next unless ($part=~/_DD$/i );
				} 
				elsif ($type=~/fio/i)
				{
					next unless ($part=~/_fio$/i);
				} 
			}
			else
			{
			}
			&_print_log (4,"printmr: Will now print $part\n");
			#else (non test data is generic and should not be skipped at all)
			foreach my $key (sort { $a <=> $b } keys %{$_out_masterreport_info{$part}}) #key is numeric 10-246
			{	

				#old -no unit added 
	     	#print $reph "Testid;$_out_masterreport_info{$part}{$key}{$label}" unless $column;
				#print $reph ";$_out_masterreport_info{$part}{$key}{$label}" if $column;
				
				
				
				my $isunit=(length($_out_masterreport_info{$part}{$key}{isunit}) >0 )?"_($_out_masterreport_info{$part}{$key}{isunit})":''; #isunit _<unit> if unit is set
				print $reph "UniqueRunID;Testid;$_out_masterreport_info{$part}{$key}{$label}${isunit}" unless $column; #this prints label and unit for column0
				print $reph ";$_out_masterreport_info{$part}{$key}{$label}${isunit}" if $column;  #this prints label and unit for column >0

				#&_print_log (4,"printmrsql: Will now print $part -> key=$key label_short $_out_masterreport_info{$part}{$key}{label_short} \n");
				#&_print_log (4,"printmrsql: Will now print $part -> key=$key Datatype $_out_masterreport_info{$part}{$key}{Datatype} \n");
				#&_print_log (4,"printmrsql: Will now print $part -> key=$key DatatypeLength $_out_masterreport_info{$part}{$key}{DatatypeLength} \n");

				&_print_log(4,"printmrsql 4612: $part($key) $_out_masterreport_info{$part}{$key}{label_short} $_out_masterreport_info{$part}{$key}{Datatype}\n");
				
				#no separation between first and later columns needed here since the special parts(UniqueRunID;Testid) are added before)
				
				print $dbc ", " . $_out_masterreport_info{$part}{$key}{label_short}. " ". $_out_masterreport_info{$part}{$key}{Datatype};	
				if ($_out_masterreport_info{$part}{$key}{DatatypeLength})
				{
					#print $dbc "(". $_out_masterreport_info{$part}{$key}{DatatypeLength}.")\n";
					print $dbc "(". $_out_masterreport_info{$part}{$key}{DatatypeLength}.") ";
				}
				else 
				{
						#print $dbc "\n";
						print $dbc " ";
				}
				
				
				$column++;	     
				
					
			}
		}
		print $dbc $dbcpostfix;
		print $reph "\n"; 
	}
	
	#######################################
	#end of header
	#######################################
	
	#######################################
	#print actual data (primary, seconday, meta)
	#######################################	
	my $value;
	
	foreach my $mtestid (sort { $a <=> $b } keys %_mastertestinfo)
	{
		my $column=0;
		
		push @dboutputcols, "Testid";
		push @dboutputdata, "$mtestid";
		foreach my $part (sort keys %_out_masterreport_info)
		{	
			if ($part=~/_\d+_test/) #skip non matching test data
			{
				#skip entries if they are not of the given type
				
				if ($type=~/dd/i)
				{
					next unless ($part=~/_DD$/i );
				} 
				elsif ($type=~/fio/i)
				{
					next unless ($part=~/_fio$/i);
				} 
			}
			else #(non test data is generic and should not be skipped at all)
			{
			} 
			
			foreach my $key (sort { $a <=> $b } keys %{$_out_masterreport_info{$part}})
			{					
				#localize , and .                 
				#print "printmr:  _out_masterreport_info -> $part -> $key => value=$_out_masterreport{$mtestid}{$part}{$key} $_out_masterreport_info{$part}{$key}{'isstring'}\n";

				#&_print_log(4,"printmr: UniqueRunID $UniqueRunID, ");
				&_print_log(4,"printmr: Test $mtestid, ");
				&_print_log(4,"$part($key), ");
				&_print_log(4,"value=$_out_masterreport{$mtestid}{$part}{$key} ");
				&_print_log(4,"(string=$_out_masterreport_info{$part}{$key}{'isstring'},");
				&_print_log(4,"comma=$_out_masterreport_info{$part}{$key}{'needs_output_conversion_comma'}, ");
				&_print_log(4,"unitcon=$_out_masterreport_info{$part}{$key}{'needs_output_conversion_unit'})\n");
				
				$value = ($_out_masterreport_info{$part}{$key}{'needs_output_conversion_comma'})?&_localize_numbers($_out_masterreport{$mtestid}{$part}{$key}):$_out_masterreport{$mtestid}{$part}{$key};
				$value = ($_out_masterreport_info{$part}{$key}{'needs_output_conversion_unit'})?($value):$value; # handle conversion
				$value = ($_out_masterreport_info{$part}{$key}{'isstring'})?'"'.$value.'"':$value;
				&_print_log(4,"printmr_post: Test $mtestid, ");
				&_print_log(4,"$part($key), ");
				&_print_log(4,"value=$value ");
				&_print_log(4,"(string=$_out_masterreport_info{$part}{$key}{'isstring'},");
				&_print_log(4,"comma=$_out_masterreport_info{$part}{$key}{'needs_output_conversion_comma'}, ");
				&_print_log(4,"unitcon=$_out_masterreport_info{$part}{$key}{'needs_output_conversion_unit'})\n");				
				print $reph "$UniqueRunID;$mtestid;$value" unless $column;
				print $reph ";$value" if $column;
				
				#This should not print header info but only data
				
				push @dboutputcols, $_out_masterreport_info{$part}{$key}{label_short};
				push @dboutputdata, "$value";
				
				&_print_log(4,"pushing " . $_out_masterreport_info{$part}{$key}{label_short} . " to dboutputcols\n");	
				&_print_log(4,"pushing $value to dboutputdata\n");	
				
				$column++;
			}	
		}
		print $reph "\n"; #end of test
		$dbout{$mtestid}{cols}=\@dboutputcols;
		$dbout{$mtestid}{data}=\@dboutputdata;
		@dboutputcols=();
		@dboutputdata=();
	}
	#print Dumper \@dboutputcols;
	
	#print Dumper \%_out_masterreport_info;
	#print Dumper \%_mastertestinfo;
	#print Dumper \%_out_masterreport;
	
	close ( $dbc );
	close ( $reph );
	
	my $colcnt=scalar @dboutputcols;
	my $datacnt=scalar @dboutputdata;
	if ($colcnt != $datacnt)
	{
		&_print_log(2,"Number of rows in dboutputcols ($colcnt) and dboutputdata ($datacnt) do not match\n");
		&_print_log(4,"Skipping create insert statement\n");
	}
	else {
		&_print_log(4,"Number of rows in dboutputcols ($colcnt) and dboutputdata ($datacnt) do match\n");
		&_print_log(4,"Creating insert statement\n");
		
		open ( my $dbi, '>', $dbinsertfile);
		#print $dbi $dbiprefix;
		foreach my $dbouttestid (sort keys %dbout)
		{
			#my @dboutputcols = $dbout{$dbouttestid}{cols};
		  #my @dboutputdata = $dbout{$dbouttestid}{data};
		  my $dboutputcolsref = $dbout{$dbouttestid}{cols};
		  my $dboutputdataref = $dbout{$dbouttestid}{data};

			print $dbi $dbiprefix;
			print $dbi "UniqueRunID";
				
			foreach my $collabel (@{$dboutputcolsref})
			{
				print $dbi ", $collabel";
				&_print_log(4,"adding label $collabel\n");
			}
			print $dbi $dbimiddle;
			print $dbi "$UniqueRunID";
			
			foreach my $coldata (@{$dboutputdataref})
			{
				if ($coldata=~/^\d+\,\d{2}$/) #replace , with . for float, elsse sql might have issues
				{
					$coldata=~s/\,/\./ ;
				}
				elsif ($coldata=~/^\d$/)
				{
					#pure number, do nothing
				}
				else
				{
					$coldata= "'". $coldata ."'"; #quote the rest
					$coldata=~s/\"//g if ($coldata=~/\'\"/); #replace "'s if we have '" 
				}
				print $dbi ", $coldata";
				&_print_log(4,"adding data $coldata\n");
			}
		}
		print $dbi $dbipostfix;
		close ( $dbi );
	}
	
	
	&_print_log(2,"Printing header mapping file\n");				
	open ( $rephmap, '>', $reportfile_map);
	#print mapping of short to long labels
	print $rephmap "short_label;long_label\n";
	foreach my $s (sort keys %map_short_to_long)
	{
		print $rephmap "$s;$map_short_to_long{$s}\n";
	}
	close ( $rephmap );
}

#my %_out_masterreport=
#(
#		'_0_SystemInfo' => {},
#		'_1_Pool' => {},
#		'_2_vDev' => {},
#		'_3_dataset' => {},
#		'_4_test_Meta_DD' => {},
#		'_5_test_Primary_DD' => {},
#		'_6_test_Secondary_DD' => {},
#		'_7_test_Meta_fio' => {},
#		'_8_test_Primary_fio' => {},
#		'_9_test_Secondary_fio' => {}
#);
#
sub _build_master_report
{
		
#		my %reportorder;
#		# sort tests by pool and dataset, we can then report 
#		foreach my $mtestid (sort { $a <=> $b } keys %_mastertestinfo)
#		{
#			my $poolid = $_mastertestinfo{$mtestid}{poolid};
#			my $dsid = $_mastertestinfo{$mtestid}{dsid};
#			my $tt = $_mastertestinfo{$mtestid}{tool};
#			$reportorder{$poolid}{$dsid}{$tt}{$mtestid}=1;
#		}
#		
#		#since we do not sync tests between fio and dd we do not have the same amount of resultlines per pool/dataset. That means we cannot put dd and fio results in the same line (as we could have missing values at any
#		#time anyway, so why report mixed in the first place. so we split results in two files with same generic info.
#		#Alternatively we can rearrange to run only tests which can be run in either program or we are not in sync anyway - and that is not desirable
#		
#		#now check all run tests
#		
#		foreach my $poolid (sort { $a <=> $b } keys %reportorder)
#		{
#			foreach my $dsid (sort { $a <=> $b } keys $reportorder{$poolid})
#			{
#				foreach my $tt (sort { $a <=> $b } keys $reportorder{$poolid}{$dsid})
#				{
#				
#				}
#			}	
#		}
		my $part;
		foreach my $mtestid (sort { $a <=> $b } keys %_mastertestinfo)
		{
			
			my $_did=$_mastertestinfo{$mtestid}{dsid};
			my $_pid=$_mastertestinfo{$mtestid}{poolid};
			&_print_log(4,"bmr: poolid = $_pid, dataset id = $_did\n");
			$part="_0_SystemInfo";
			foreach my $subitem (sort keys %{$_out_masterreport_info{$part}})
			{
				#item and subitem are sortable units (subitem is numerical) so the order can be determined at output (sort { $a <=> $b })
				&_print_log(4,"bmr: Test $mtestid, ");
				&_print_log(4,"$part($subitem), ");
				&_print_log(4,"key=$_out_masterreport_info{$part}{$subitem}{key}, ");
				&_print_log(4,"value= $_int_masterreport{$part}{$_out_masterreport_info{$part}{$subitem}{key}} \n");
				$_out_masterreport{$mtestid}{$part}{$subitem}=$_int_masterreport{$part}{$_out_masterreport_info{$part}{$subitem}{key}};
			}
			
			$part="_1_Pool";
			#pool report info: from %_pools ------ #vdevs	#disks_p_vdev	pooltype	#l2arc	l2arc_setup	#slog_devs	slog_setup		
			foreach my $subitem (sort keys %{$_out_masterreport_info{$part}})
			{				
				$_out_masterreport{$mtestid}{$part}{$subitem}=$_pools{$_pid}{$_out_masterreport_info{$part}{$subitem}{key}};
				&_print_log(4,"bmr: Test $mtestid, ");
				&_print_log(4,"$part($subitem), ");
				&_print_log(4,"key=$_out_masterreport_info{$part}{$subitem}{key}, ");
				&_print_log(4,"value=$_pools{$_pid}{$_out_masterreport_info{$part}{$subitem}{key}}\n");
				#print "4,bmr: Test $mtestid, $part($subitem), key=$_out_masterreport_info{$part}{$subitem}{key}, value=$_pools{$_pid}{$_out_masterreport_info{$part}{$subitem}{key}}\n";
			}
			
			$part="_3_dataset";
			#Dataset Options: from %_datasets ------  recordsize x sync x compression
			foreach my $subitem (sort keys %{$_out_masterreport_info{$part}})
			{				
				$_out_masterreport{$mtestid}{$part}{$subitem}=$_datasets{$_did}{dsinfo}{$_out_masterreport_info{$part}{$subitem}{key}};
			}	
						
			my $_testtool=$_mastertestinfo{$mtestid}{tool};			
			
			&_print_log(4,"bmr: Test $mtestid, tool=$_testtool\n");
			if ($_testtool=~/fio/)
			{				
				$part="_7_test_Meta_fio";
				foreach my $subitem (sort keys %{$_out_masterreport_info{$part}})
				{	
#					print $fiotests{$mtestid}{info}{$_out_masterreport_info{$mtestid}{$subitem}{key}};
					$_out_masterreport{$mtestid}{$part}{$subitem}=$fiotests{$mtestid}{info}{$_out_masterreport_info{$part}{$subitem}{key}};
					&_print_log(4,"bmr: Test $mtestid, $part($subitem), key=$_out_masterreport_info{$part}{$subitem}{key}, value= $fiotests{$mtestid}{info}{$_out_masterreport_info{$part}{$subitem}{key}} \n");
				}
				
				$part="_8_test_Primary_fio";
				#$ddtests{$mastertestid}{summary}{$type}{avg_per_run}=$avg_per_run;
				foreach my $subitem (sort keys %{$_out_masterreport_info{$part}})
				{					
					
					$_out_masterreport{$mtestid}{$part}{$subitem}=$fiotests{$mtestid}{results}{$_out_masterreport_info{$part}{$subitem}{key}};	
					&_print_log(4,"bmr: Test $mtestid, $part($subitem), key=$_out_masterreport_info{$part}{$subitem}{key}, value=$fiotests{$mtestid}{results}{$_out_masterreport_info{$part}{$subitem}{key}} \n");
					
				}	
				
				#not cleanly implemented yet, should not create an error
				$part="_9_test_Secondary_fio";
				foreach my $subitem (sort keys %{$_out_masterreport_info{$part}})
				{					
					#$_out_masterreport{$mtestid}{$part}{$subitem}=$fiotests{$mtestid}{results}{$_out_masterreport_info{$part}{$subitem}{key}};	
				}								
			}
			elsif ($_testtool=~/dd/)
			{				
				$part="_4_test_Meta_DD";
				foreach my $subitem (sort keys %{$_out_masterreport_info{$part}})
				{					
					$_out_masterreport{$mtestid}{$part}{$subitem}=$ddtests{$mtestid}{info}{$_out_masterreport_info{$part}{$subitem}{key}};
					&_print_log(4,"bmr: Test $mtestid, $part($subitem), key=$_out_masterreport_info{$part}{$subitem}{key}, value=$ddtests{$mtestid}{info}{$_out_masterreport_info{$part}{$subitem}{key}}\n");
				}
				
				$part="_5_test_Primary_DD";
				#$ddtests{$mastertestid}{summary}{$type}{avg_per_run}=$avg_per_run;
				#	$ddtests{$mastertestid}{details}{"${type}_total_bytes_all_jobs"}{"run$run"}=$jobtotal;
				foreach my $subitem (sort keys %{$_out_masterreport_info{$part}})
				{					
					$_out_masterreport{$mtestid}{$part}{$subitem}=$ddtests{$mtestid}{results}{$_out_masterreport_info{$part}{$subitem}{key}};					
					&_print_log(4,"bmr: Test $mtestid, $part($subitem), key=$_out_masterreport_info{$part}{$subitem}{key}, value=$ddtests{$mtestid}{results}{$_out_masterreport_info{$part}{$subitem}{key}}\n");
				}	
				
				$part="_6_test_Secondary_DD";
				#not cleanly implemented yet, should not create an error - values are empty though
				foreach my $subitem (sort keys %{$_out_masterreport_info{$part}})
				{
					$_out_masterreport{$mtestid}{$part}{$subitem}=$ddtests{$mtestid}{results}{$_out_masterreport_info{$part}{$subitem}{key}};	
					&_print_log(4,"bmr: Test $mtestid, $part($subitem), key=$_out_masterreport_info{$part}{$subitem}{key}, value=$ddtests{$mtestid}{results}{$_out_masterreport_info{$part}{$subitem}{key}}\n");
				}	
				
			}
			
			else { print "unexpected testtool $_testtool found in _build_master_report";}
			
			
			
		}
	
	#print "_out_masterreport" ,Dumper \%_out_masterreport;
}



sub _report_fio_results()
{
}

#deprecated? - at least currently not used, from old style
#we need to do output localization in here
#and maybe also to_MB conversion. That one is partially still done before in specific variables, but there is little sense in having a mix of byte & mb values
sub _report_dd_results()
{

	&_print_log (0, "Running DD results - detailed\n");
	open ( $drephandle, '>', $detailddresultsfile);
	#print $drephandle "testid;dsid;_dsname;paralleljobs;dd_file_size;dd_file_size_bytes;bs;_rsize;_so;_co;type;dd_runs_per_test;run;runtype;runtotal;runtotal_mb;avg_bytes_per_job;avg_bytes_per_job_mb;job;jobresult;jobresult_mb;load_pct;load_peak;avg_r_ops;avg_w_ops;avg_r_bw_mb;avg_w_bw_mb\n";
	print $drephandle "testid;run;dsid;_dsname;paralleljobs;dd_file_size;bs;_rsize;_so;_co;type;dd_runs_per_test;run;runtype;runtotal;avg_bytes_per_job;job;jobresult;load_pct;load_peak;avg_r_ops;avg_w_ops\n";
	my $type;
	foreach my $testid (sort keys %ddtests)
	{
		next unless ($ddtests{$testid}{info}{tool}=~/dd/); #make sure this test was done with dd

	#	First - assemble generic information from the info tranch

		my $dsid = $ddtests{$testid}{info}{dsid};
		my $_dsname = $ddtests{$testid}{info}{dsname};
		my $test_ds = $ddtests{$testid}{info}{test_ds};
		my $paralleljobs = $ddtests{$testid}{info}{instcnt};
		my $bs = $ddtests{$testid}{info}{bs};
		my $dd_runs_per_test = $ddtests{$testid}{info}{dd_runs_per_test};
		my $dd_file_size = $ddtests{$testid}{info}{dd_file_size};

		#generic information about the dataset parameters
		my $_rsize = $_datasets{$dsid}{dsinfo}{zfs_recordsizes};
		my $_so = $_datasets{$dsid}{dsinfo}{zfs_sync_options};
		my $_co = $_datasets{$dsid}{dsinfo}{zfs_compression_options};
		my $_mo = $_datasets{$dsid}{dsinfo}{zfs_metadata_options};


	#	Second - gather data for each kind of test we have run - currently this is read & write, but in the future might include rewrite or whatever
		foreach $type (sort keys %{$ddtests{$testid}})
		{
			next if ($type=~/info/); #skip static values
			next if ($type=~/results/); #skip aggregated values - these will be used in the average report only

			foreach my $run (sort keys %{$ddtests{$testid}{runs}})
			{
				#these are averages over all jobs (basically medium aggregation level)
				my $runtotal = 					$ddtests{$testid}{$type}{info}{runs}{$run}{results}{jobtotal};
				my $avg_bytes_per_job = $ddtests{$testid}{$type}{info}{runs}{$run}{results}{avg_bytes_per_job};

				foreach my $job (sort keys %{$ddtests{$testid}{$type}{runs}{$run}{results}{jobs}})
				{
					my $jobresult = $ddtests{$testid}{$type}{runs}{$run}{results}{jobs}{$job}{'bytes'};
					my $load_pct = $ddtests{$testid}{$type}{runs}{$run}{results}{jobs}{$job}{'load'};
					my $load_peak = $ddtests{$testid}{$type}{runs}{$run}{results}{jobs}{$job}{'load_peak'};
					my $avg_r_ops = $ddtests{$testid}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_r_ops'};
					my $avg_w_ops = $ddtests{$testid}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_w_ops'};
					my $avg_r_bw = $ddtests{$testid}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_r_bw'};
					my $avg_w_bw = $ddtests{$testid}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_w_bw'};
					#my $avg_r_bw_mb = $ddtests{$testid}{runs}{$run}{results}{jobs}{$job}{'avg_r_bw_mb'};
					#my $avg_w_bw_mb = $ddtests{$testid}{runs}{$run}{results}{jobs}{$job}{'avg_w_bw_mb'};
					print "testid type run job - $testid $type $run $job\n";
					#print $drephandle "$testid;$dsid;$_dsname;$paralleljobs;$dd_file_size;$dd_file_size_bytes;$bs;$_rsize;$_so;$_co;$type;$dd_runs_per_test;$run;$type;$runtotal;$runtotal_mb;$avg_bytes_per_job;$avg_bytes_per_job_mb;$job;$jobresult;$jobresult_mb;$load_pct;$load_peak;$avg_r_ops;$avg_w_ops;$avg_r_bw_mb;$avg_w_bw_mb\n";
					print $drephandle "$testid;$run;$dsid;$_dsname;$paralleljobs;$dd_file_size;$bs;$_rsize;$_so;$_co;$type;$dd_runs_per_test;$run;$type;$runtotal;$avg_bytes_per_job;$job;$jobresult;$load_pct;$load_peak;$avg_r_ops;$avg_w_ops\n";
				}
			}
		}
	}
	close $drephandle;

	&_print_log (0, "Running DD results - avg\n");
	open ( $rephandle, '>', $ddresultsfile);
	#print $rephandle "Testid;dsid;_dsname;paralleljobs;dd_file_size;dd_file_size_bytes;bs;_rsize;_so;_co;type;avg_per_run;avg_per_run_mb\n";
	print $rephandle "Testid;dsid;_dsname;paralleljobs;dd_file_size;bs;_rsize;_so;_co;type;avg_per_run\n";
	foreach my $testid (sort keys %ddtests)
	{
		next unless ($ddtests{$testid}{info}{tool}=~/dd/); #make sure this test was done with dd

		my $dsid = $ddtests{$testid}{info}{dsid};
		my $_dsname = $ddtests{$testid}{info}{dsname};
		my $dd_runs_per_test = $ddtests{$testid}{info}{dd_runs_per_test};
		my $test_ds = $ddtests{$testid}{info}{test_ds};
		my $paralleljobs = $ddtests{$testid}{info}{instcnt};
		my $bs = $ddtests{$testid}{info}{bs};

	#	my $avg_per_run_mb = $ddtests{$testid}{results}{avg_per_run_mb};
		my $dd_file_size = $ddtests{$testid}{info}{dd_file_size};
		my $_rsize = $_datasets{$dsid}{dsinfo}{zfs_recordsizes};
		my $_so = $_datasets{$dsid}{dsinfo}{zfs_sync_options};
		my $_co = $_datasets{$dsid}{dsinfo}{zfs_compression_options};
		my $_mo = $_datasets{$dsid}{dsinfo}{zfs_metadata_options};

		foreach $type (sort keys %{$ddtests{$testid}})
		{
			next if ($type=~/info/);
			next if ($type=~/results/);
			next if ($type=~/runs/);
			my $avg_per_run = $ddtests{$testid}{results}{$type}{avg_per_run};
			#my $dd_file_size_bytes = $ddtests{$testid}{dd_file_size_bytes};

			#add CPU load and iostat averaged over test  to data and report

			#print $rephandle "$testid;$dsid;$_dsname;$paralleljobs;$dd_file_size;$dd_file_size_bytes;$bs;$_rsize;$_so;$_co;$type;$avg_per_run;$avg_per_run_mb\n";
			print $rephandle "$testid;$dsid;$_dsname;$paralleljobs;$dd_file_size;$bs;$_rsize;$_so;$_co;$type;$avg_per_run\n";
		}
	}
	close $rephandle;
}


#perl disklist.pl -all
#partition  label                                       zpool  device  sector  disk                  size  type  serial     rpm  location        multipath  mode
#---------------------------------------------------------------------------------------------------------------------------------------------------------------
#da1p1      gptid/f69a3c49-828b-11e8-975b-0050569e17a3  tank   da1        512  VMware Virtual disk     42  SSD   (null)       0
#da3p2      gptid/61f9f99a-1719-11e7-b3a3-0050569e17a3  tank   da3        512  ATA HGST HDN728080AL  8001  HDD   VLKGKKBY  7200  SAS2008(0):2#0
#da4p2      gptid/f72b1d2b-126b-11e7-b2b0-0050569e17a3  tank   da4        512  ATA HGST HDN728080AL  8001  HDD   VLKH1EGZ  7200  SAS2008(0):2#1
#da5p2      gptid/659d00e3-1719-11e7-b3a3-0050569e17a3  tank   da5        512  ATA HGST HDN728080AL  8001  HDD   VLKHVD6Y  7200  SAS2008(0):2#2
#da6p2      gptid/f82c7777-126b-11e7-b2b0-0050569e17a3  tank   da6        512  ATA HGST HDN728080AL  8001  HDD   VLKKW3GY  7200  SAS2008(0):2#3
#da7p2      gptid/f7af499b-126b-11e7-b2b0-0050569e17a3  tank   da7        512  ATA HGST HDN728080AL  8001  HDD   VLKJEJKY  7200  SAS2008(0):2#4
#da8p2      gptid/62892b14-1719-11e7-b3a3-0050569e17a3  tank   da8        512  ATA HGST HDN728080AL  8001  HDD   VLJWJ0VY  7200  SAS2008(0):2#5
#da9p2      gptid/f8b7f18d-126b-11e7-b2b0-0050569e17a3  tank   da9        512  ATA HGST HDN728080AL  8001  HDD   VLKJUTAY  7200  SAS2008(0):2#7
#da10p2     gptid/662cca81-1719-11e7-b3a3-0050569e17a3  tank   da10       512  ATA HGST HDN728080AL  8001  HDD   VLKH68ZZ  7200  SAS2008(0):2#8
#                                                              da0        512  VMware Virtual disk     68  SSD   (null)       0
#                                                              da2        512  VMware Virtual disk     42  SSD   (null)       0

# -o:csv
#partition;label;zpool;device;sector;disk;size;type;serial;rpm;location;multipath;mode
#da1p1;gptid/f69a3c49-828b-11e8-975b-0050569e17a3;tank;da1;512;VMware Virtual disk;42;SSD;(null);0;;;
#da3p2;gptid/61f9f99a-1719-11e7-b3a3-0050569e17a3;tank;da3;512;ATA HGST HDN728080AL;8001;HDD;VLKGKKBY;7200;SAS2008(0):2#0;;
#da4p2;gptid/f72b1d2b-126b-11e7-b2b0-0050569e17a3;tank;da4;512;ATA HGST HDN728080AL;8001;HDD;VLKH1EGZ;7200;SAS2008(0):2#1;;
#da5p2;gptid/659d00e3-1719-11e7-b3a3-0050569e17a3;tank;da5;512;ATA HGST HDN728080AL;8001;HDD;VLKHVD6Y;7200;SAS2008(0):2#2;;
#da6p2;gptid/f82c7777-126b-11e7-b2b0-0050569e17a3;tank;da6;512;ATA HGST HDN728080AL;8001;HDD;VLKKW3GY;7200;SAS2008(0):2#3;;
#da7p2;gptid/f7af499b-126b-11e7-b2b0-0050569e17a3;tank;da7;512;ATA HGST HDN728080AL;8001;HDD;VLKJEJKY;7200;SAS2008(0):2#4;;
#da8p2;gptid/62892b14-1719-11e7-b3a3-0050569e17a3;tank;da8;512;ATA HGST HDN728080AL;8001;HDD;VLJWJ0VY;7200;SAS2008(0):2#5;;
#da9p2;gptid/f8b7f18d-126b-11e7-b2b0-0050569e17a3;tank;da9;512;ATA HGST HDN728080AL;8001;HDD;VLKJUTAY;7200;SAS2008(0):2#7;;
#da10p2;gptid/662cca81-1719-11e7-b3a3-0050569e17a3;tank;da10;512;ATA HGST HDN728080AL;8001;HDD;VLKH68ZZ;7200;SAS2008(0):2#8;;
#;;;da0;512;VMware Virtual disk;68;SSD;(null);0;;;
#;;;da2;512;VMware Virtual disk;42;SSD;(null);0;;;


sub _get_diskinfo_disklistpl
{
	&_print_log (4, "Begin _get_diskinfo_disklistpl\n");
	my @_a_diskinfo=();
	my @_diskinfo_labels=();

	die ("File $user_dlpl not found") if (!-e $user_dlpl) ;

	my $_command="perl $user_dlpl -c:dDTHplzm -smartctl -o:csv";
	push @log_master_command_list, $_command;
	@_a_diskinfo=&_exec_command("$_command");

#root@freenas9:/tmp # perl disklist.pl -c:dDTHpl -smartctl
#device  disk                      type  temp  partition  label
#---------------------------------------------------------------------------------------------------
#da3     ATA INTEL SSDSC2BX01      SSD     28  da3p2      gptid/02856159-bd14-11e8-bfcd-0050569e17a3
#da4     ATA INTEL SSDSC2BX01      SSD     28  da4p2      gptid/01544d13-bd14-11e8-bfcd-0050569e17a3
#da5     ATA INTEL SSDSC2BX01      SSD     28  da5p2      gptid/008644e7-bd14-11e8-bfcd-0050569e17a3
#da6     ATA INTEL SSDSC2BX01      SSD     28  da6p2      gptid/c5c0beb8-c6f0-11e8-9bdd-0050569e17a3
#da7     ATA INTEL SSDSC2BX01      SSD     28  da7p2      gptid/00ec1fbe-bd14-11e8-bfcd-0050569e17a3
#da8     ATA INTEL SSDSC2BX01      SSD     28  da8p2      gptid/021aaa35-bd14-11e8-bfcd-0050569e17a3
#da9     SEAGATE ST320004CLAR2000  HDD     34  da9p2      gptid/645c8f3a-8ac5-11e9-94bf-0050568b85f8
#da0     VMware Virtual disk       ???    ???  da0p2      gptid/f6566c10-2517-11e6-8514-000c29e88918
#da1     ATA INTEL SSDSC2BX01      SSD     28  da1p2      gptid/c6326e4a-c6f0-11e8-9bdd-0050569e17a3
#da2     ATA INTEL SSDSC2BX01      SSD     28  da2p2      gptid/01ae2c5c-bd14-11e8-bfcd-0050569e17a3

#root@freenas[~]# perl disklist.pl -c:dDTHplzm -smartctl
#device               disk                  type   temp  partition           label                                       zpool         multipath
#------------------------------------------------------------------------------------------------------------------------------------------------------
#da52,da40,da13,da1   HGST HUSMM3280ASS204  SSD      29  multipath/disk1p2   gptid/2778ce65-3367-11ec-88a2-0050568b274b                multipath/disk1
#da51,da39,da12,da0   HGST HUSMM3280ASS204  SSD      28  multipath/disk2p2   gptid/2845ec02-3367-11ec-88a2-0050568b274b                multipath/disk2
#da62,da50,da23,da11  HGST HUSMM3280ASS204  SSD      29  multipath/disk3p2   gptid/27f9e9c2-3367-11ec-88a2-0050568b274b                multipath/disk3
#da60,da48,da21,da9   HGST HUSMM3280ASS204  SSD      28  multipath/disk4p2   gptid/2832fa15-3367-11ec-88a2-0050568b274b                multipath/disk4
#da53,da41,da14,da2   HGST HUSMM3280ASS204  SSD      31  multipath/disk5p2   gptid/280faafc-3367-11ec-88a2-0050568b274b                multipath/disk5
#da54,da42,da15,da3   HGST HUSMM3280ASS204  SSD      30  multipath/disk6p2   gptid/283cdab9-3367-11ec-88a2-0050568b274b                multipath/disk6
#da61,da49,da22,da10  HGST HUSMM3280ASS204  SSD      29  multipath/disk7p2   gptid/279830a5-3367-11ec-88a2-0050568b274b                multipath/disk7
#da59,da47,da20,da8   HGST HUSMM3280ASS204  SSD      31  multipath/disk10p2  gptid/281b7c42-3367-11ec-88a2-0050568b274b                multipath/disk10
#da58,da46,da19,da7   HGST HUSMM3280ASS204  SSD      30  multipath/disk11p2  gptid/27cc3342-3367-11ec-88a2-0050568b274b                multipath/disk11
#da57,da45,da18,da6   HGST HUSMM3280ASS204  SSD      29  multipath/disk12p2  gptid/27e7a3e4-3367-11ec-88a2-0050568b274b                multipath/disk12
#ada0                 INTEL SSDSA2CW160G3   SSD     ???  ada0p2              gptid/d991c191-0ec9-11ea-bb7b-ac1f6bba545a  freenas-boot
#pmem0                PMEM region 16GB      NVRAM   ???
#pmem1                PMEM region 16GB      NVRAM   ???
#da5                  HGST HUSMM3280ASS204  SSD      29                                                                                multipath/disk9
#da17                 HGST HUSMM3280ASS204  SSD      29                                                                                multipath/disk9
#da44                 HGST HUSMM3280ASS204  SSD      29                                                                                multipath/disk9
#da56                 HGST HUSMM3280ASS204  SSD      29                                                                                multipath/disk9
#da24                 ATA INTEL SSDSC2BA40  SSD      10                                                                                multipath/disk13
#da63                 ATA INTEL SSDSC2BA40  SSD      10                                                                                multipath/disk13
#da25                 ATA INTEL SSDSC2BA40  SSD      10                                                                                multipath/disk14
#da64                 ATA INTEL SSDSC2BA40  SSD      10                                                                                multipath/disk14
#da26                 ATA INTEL SSDSC2BA40  SSD      10                                                                                multipath/disk15
#da65                 ATA INTEL SSDSC2BA40  SSD      10                                                                                multipath/disk15
#da27                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk16
#da66                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk16
#da28                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk17
#da67                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk17
#da29                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk18
#da68                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk18
#da30                 ATA ITVSC2BA3SUN400G  SSD      11                                                                                multipath/disk19
#da69                 ATA ITVSC2BA3SUN400G  SSD      11                                                                                multipath/disk19
#da31                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk20
#da70                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk20
#da32                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk21
#da71                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk21
#da33                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk22
#da72                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk22
#da34                 ATA INTEL SSDSC2BA40  SSD      12                                                                                multipath/disk23
#da73                 ATA INTEL SSDSC2BA40  SSD      12                                                                                multipath/disk23
#da35                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk24
#da74                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk24
#da36                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk25
#da75                 ATA INTEL SSDSC2BA40  SSD      11                                                                                multipath/disk25
#da37                 ATA INTEL SSDSC2BA40  SSD      12                                                                                multipath/disk26
#da76                 ATA INTEL SSDSC2BA40  SSD      12                                                                                multipath/disk26
#da38                 ATA ITVSC2BA3SUN400G  SSD      11                                                                                multipath/disk27
#da77                 ATA ITVSC2BA3SUN400G  SSD      11                                                                                multipath/disk27
#
#47 selected disk(s)




	foreach my $__line (@_a_diskinfo)
	{
		chomp $__line;
		if ($__line=~/^device/)
		{
			(@_diskinfo_labels = split /;/ , $__line );
		}
		elsif ($__line=~/selected disk\(s\)/|| $__line=~/^\s*$/)
		{
			next;
		}
		else
		{
			my @_diskinfo=();
			@_diskinfo= split /;/ , $__line;
			#OLD 3= device, 7=type, 5=disk type, 6=zpool
			#OLD (-all v1) partition  fs label zpool  zpool-location  6= device  sector  8=disk 9=size  10= type   serial   rpm  sas-location  multipath  path-mode  path-state
			#or run with option c:dDT
			# device;disk;type;temp;partition;label;zpool;multipath
			# 0     ;1   ;2   ;3   ;4        ;5    ;6    ;7


			$_alldisks_dev{"/dev/$_diskinfo[0]"}{info}=\@_diskinfo;
			$_alldisks_dev{"/dev/$_diskinfo[0]"}{description}=$_diskinfo[1];
			$_alldisks_dev{"/dev/$_diskinfo[0]"}{type}=$_diskinfo[2];
			$_alldisks_dev{"/dev/$_diskinfo[0]"}{initial_temp}=$_diskinfo[3];
			$_alldisks_dev{"/dev/$_diskinfo[0]"}{gpt}=$_diskinfo[5];
			$_alldisks_dev{"/dev/$_diskinfo[0]"}{currentpool}=$_diskinfo[6];
			$_alldisks_dev{"/dev/$_diskinfo[7]"}{mulitpathdisk}=$_diskinfo[0];
			if ($_diskinfo[1] !~ /Virtual/)
			{
				#assume all physical devices can provide temperature info
				#$_alldisks{$_diskinfo[3]}{can_provide_temp}=1;
				#actually we will just set temp to 0 in this case
			}
			#save non device based references if any, link to actual dev
			$_alldisks_gpt{$_diskinfo[5]}="/dev/$_diskinfo[0]" if (defined $_diskinfo[5]);
			$_alldisks_part{$_diskinfo[4]}="/dev/$_diskinfo[0]" if (defined $_diskinfo[4]);
			$_alldisks{$_diskinfo[0]}="/dev/$_diskinfo[0]" if (defined $_diskinfo[0]);
			$_alldisks_mp{$_diskinfo[7]}="/dev/$_diskinfo[0]" if (defined $_diskinfo[7]);

		}
	}

	#&_print_hash_generic (\%_alldisks_dev, []);

	&_print_log (4, "Finished _get_diskinfo_disklistpl\n");
	return @_a_diskinfo;

}

sub _detect_pmem # check of there any pmem devices in the system
{

	my $_command="ls /dev/pmem\* 2>/dev/null";
	push @log_master_command_list, $_command;
	my @_pmem=&_exec_command("$_command",1);

	foreach (@_pmem)
	{
		$_alldisks_pmem{$_}=1;
	}

}

#not implemented yet
sub _get_disks_from_menu
{
	return 0;
	#&_assemble_disk_list_from_environment(); #not implementeded yet
}

#not implemented yet
sub _get_disks_from_cli_params
{
	return 0;
}


#this sub takes the result of the calculate_pool_options extended function and permutates with cache & log for a master pool list
sub _do_cache_and_log_checks_extended
{

	#this creates all possible combinations of cache and log devices
	foreach my $_l2 (@user_l2arcoptions)
	{
		&_print_log (3, "Matching selected L2Arc option ($_l2) with provided disks:\n");
		my ($_devl2arc1exists,$_devl2arc2exists)=(0,0);
		if (exists $_pooldisks{'l2arcdev'} && exists $_pooldisks{'l2arcdev'}{id})
		{
			$_devl2arc1exists=&_check_disk_exists($_pooldisks{'l2arcdev'}{id});
			&_print_log (3, " l2arcdev = ($_pooldisks{'l2arcdev'}{id})\n");
		}
		else
		{
			&_print_log (3, " l2arcdev = none (->skip l2arc mirror,stripe,sf)\n");
		}
		if (exists $_pooldisks{'l2arcdev2'} && exists $_pooldisks{'l2arcdev2'}{id})
		{
			$_devl2arc2exists=&_check_disk_exists($_pooldisks{'l2arcdev2'}{id});
			&_print_log (3, " l2arcdev2 = $_pooldisks{'l2arcdev2'}{id}\n");
		}
		else
		{
			&_print_log (3, " l2arcdev2 = none (->skip l2arc mirror,stripe,ss)\n");
		}

		#skip these if we dont have both devices
		if ($_l2=~/mir/ || ($_l2=~/str/))
		{
			next unless $_devl2arc1exists;
			next unless $_devl2arc2exists;
		}
		elsif ($_l2=~/sf/ )
		{
			next unless ($_devl2arc1exists);
		}
		elsif ($_l2=~/ss/ )
		{
			next unless ($_devl2arc2exists);
		}
		#we dont skip on 'none'


		&_print_log (3, "Found device for option $_l2\n");

		foreach my $_sl (@user_slogoptions)
		{
			&_print_log (3, "Matching selected sLog option ($_sl) with provided disks:\n");
			my ($_devslog1exists,$_devslog2exists)=(0,0);
			if (exists $_pooldisks{'slogdev'} && exists $_pooldisks{'slogdev'}{id})
			{
				$_devslog1exists=&_check_disk_exists($_pooldisks{'slogdev'}{id});
				&_print_log (3, " slogdev = $_pooldisks{'slogdev'}{id}\n");
			}
			else
			{
				&_print_log (3, " slogdev = none (->skip slog mirror,stripe,sf)\n");
			}
			if (exists $_pooldisks{'slogdev2'} && exists $_pooldisks{'slogdev2'}{id})
			{
				$_devslog2exists=&_check_disk_exists($_pooldisks{'slogdev2'}{id});
				&_print_log (3, " slogdev2 = $_pooldisks{'slogdev2'}{id}\n");
			}
			else
			{
				&_print_log (3, " slogdev2 = none (->skip slog mirror,stripe,ss)\n");
			}

			#skip these if we dont have both devices
			if ($_sl=~/mir/ || ($_sl=~/str/))
			{
				next unless $_devslog1exists;
				next unless $_devslog2exists;
			}
			elsif ($_sl=~/sf/ )
			{
				next unless $_devslog1exists;
			}
			elsif ($_sl=~/ss/ )
			{
				next unless $_devslog2exists;
			}
			#we dont skip on 'none'
			&_print_log (3, "Found device for option $_sl\n");

			#$_current_l2arcoption=$_l2;
			#$_current_slogoption=$_sl;
			&_print_log (3, "Adding L2Arc and Slog options ($_l2, $_sl) \n");

			##########################
			# This is the point main action loop
			##########################
			$__l2arc_slog_combinations{"c${_l2}_s${_sl}"}=1;

			##########################
		}
	}
}

#my @uservar_vdev_type=('sin','z1','z2','z3');
#my @uservar_vdev_redundancy=('no','str','mir');

#define amount of disks per pooltype. O/C m2/m3 are not two pool types but only disk increase but it got its own type nevertheless.
#Raid Z's are based on a 4+x [1,2,3] layout, not absolute minimums - larger values (y+x [y=4,5,6,7..., x=1,2,3]) can be specified

#my $_diskcount_z1=5;
#my $_diskcount_z2=6;
#my $_diskcount_z3=7;

# sf = single slog/cache, uses the first given device if it exists (slog1/l2arc1)
# ss = single slog/cache, uses the second given device if it exists (slog2/l2arc2)
# str = two slog/cache, uses both in str config
# mirror = two slog/cache, uses both in mirror config
#my @user_l2arcoptions= ('none','sf','ss','str','mirror');  #all options
#my @user_slogoptions= ('none','sf','ss','str','mirror');  # all options

#my @user_l2arcoptions= ('no','sf','ss','str','mir');
#my @user_slogoptions= ('no','sf','ss','str','mir');

sub _create_all_pools_extended
{
	my ($vdevtype,$redundancysize,$redundancytype,$vdevcount,$offsetcount,$cachetype,$logtype);
	#this sub needs to take the sorted master testpool hash and loop through it.
	#it will then decode the internal identifyers in the name to detect what kind of pool will be built, and with which options
	foreach my $pool (sort (keys %_masterpoollist))
	{
		last if &_check_stop_requested;
		&_check_runtimeinfo_requested;
		&_check_changeloglevel_requested();
		&_print_log (1, "Pool #$pool = $_masterpoollist{$pool}{name}\n");
		my @tests=split /_/, $_masterpoollist{$pool}{name};
	        #print "5151", Dumper \%_masterpoollist;

		#p_sin_mir02_v5_o0_cno_sno
		#skip 'p'
		my $vdevt=$tests[1];
		my $redundancy=$tests[2];
		my $nrvdevs=$tests[3];
		my $vdev_offset=$tests[4];
		my $cache_device=$tests[5];
		my $log_device=$tests[6];

		#my @uservar_vdev_type=('sin','z1','z2','z3');

		if ($vdevt=~/^(\w{2,3})$/)
		{
			$vdevtype=$1;
			&_print_log (3, "vdevtype: $vdevt => $vdevtype\n");
		}
		else
		{
			die "Unexpected vdev type ($1) in $pool";
		}

		#my @uservar_vdev_redundancy=('no','str','mir');

		if ($redundancy=~/^(\w{2,3})(\d{2})$/) #none
		{
			$redundancytype=$1;
			$redundancysize=$2;
			&_print_log (3, "redundancy: $redundancy => $redundancytype,$redundancysize \n");
		}
		else
		{
			die "Unexpected redundancy type or size ($1,$2) in $pool";
		}

		#vXX
		if ($nrvdevs=~/^v(\d{2})$/)
		{
			$vdevcount=$1;
			#we need to have vdevcount vdevs, in the selected layout (vdevtype x redundancy)
			&_print_log (3, "nrvdevs: $nrvdevs => $vdevcount\n");
		}
		else
		{
			die "Unexpected nrvdevs ($1) in $pool";
		}

		#oXX
		if ($vdev_offset=~/^o(\d{2})$/)
		{
			$offsetcount=$1;
			&_print_log (3, "vdev_offset: $vdev_offset => $offsetcount\n");
			#we need to have an offset here, $offsetcount x #disks for selected vdev type/size
		}
		else
		{
			die "Unexpected vdev_offset ($1) in $pool";
		}

		#my @user_l2arcoptions= ('no','sf','ss','str','mir');
		#cXX
		if ($cache_device=~/^c(\w{2,3})$/)
		{
			$cachetype=$1;
		&_print_log (3, "cache_device: $cache_device => $cachetype\n");
		}
		else
		{
			die "Unexpected cache type in $pool";
		}

		#my @user_slogoptions= ('no','sf','ss','str','mir');
		#sXX
		if ($log_device=~/^s(\w{2,3})$/)
		{
			$logtype=$1;
			&_print_log (3, "log_device: $log_device => $logtype\n");
		}
		else
		{
			die "Unexpected log type in $pool";
		}

		&_create_single_pool_and_run_tests_extended($vdevtype,$redundancysize,$redundancytype,$vdevcount,$offsetcount,$cachetype,$logtype,$_masterpoollist{$pool}{name});
	}
}

sub _handle_iostat_output
{
	my ($logpath,$_pool)=($_[0],$_[1]);
	my $iostatfile = $logpath;
	my %result;
	open ( my $ziohandle, '<', "$iostatfile");
	my ($r_ops,$w_ops,$r_bw,$w_bw,$total_r_ops,$total_w_ops,$total_r_bw,$total_w_bw,$lines)=(0,0,0,0,0,0,0,0,0);

	foreach my $line (<$ziohandle>)
	{
		next if ($line !~/$_pool/); #only get the current pool's lines
		#                    capacity     operations    bandwidth
		#_pool              alloc   free   read  write   read  write
		#----------------  -----  -----  -----  -----  -----  -----
		#p_m2_vd-1_offs-0  1.91G   370G      0  5.44K  5.28K  65.7M
		if ($line=~/$_pool\s+.+?\s+.+?\s+(.+?)\s+(.+?)\s+(.+?)\s+(.+?)\s*$/)
		{
			$r_ops=&_get_as_bytes($1);
			$w_ops=&_get_as_bytes($2);
			$r_bw=&_get_as_bytes($3);
			$w_bw=&_get_as_bytes($4);
			$lines++; # assume we ran every second, so we average by dividing by lines
			$total_r_ops+=$r_ops;
			$total_w_ops+=$w_ops;
			$total_r_bw+=$r_bw;
			$total_w_bw+=$w_bw;
			&_print_log(3, "$line"); #has newline
			&_print_log(3,  "1-4 -> $1, $2, $3, $4 || r_ops, w_ops, r_bw, w_bw -> $r_ops, $w_ops, $r_bw, $w_bw || total-> $total_r_ops,$total_w_ops,$total_r_bw,$total_w_bw\n");

		}
	}
	close $ziohandle;
	$lines=1 unless ($lines); #prevent division by 0 error. If we didnt match any lines total_cpu is 0 too so no problem
	$result{'avg_r_ops'}=$total_r_ops/$lines;
	$result{'avg_w_ops'}=$total_w_ops/$lines;
	$result{'avg_r_bw'}=$total_r_bw/$lines;
	$result{'avg_w_bw'}=$total_w_bw/$lines;
	return \%result;
	#$fiotests{$mastertestid}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_r_bw_mb'}=&_get_as($total_r_bw/$lines,'M');;
	#$fiotests{$mastertestid}{$type}{runs}{$run}{results}{jobs}{$job}{'avg_w_bw_mb'}=&_get_as($total_w_bw/$lines,'M');;
#	$totalrios+=$total_r_ops/$lines; #add to total, will be divided by runs
#	$totalwios+=$total_w_ops/$lines; #add to total, will be divided by runs
#	$totalrbw+=$total_r_bw/$lines; #add to total, will be divided by runs
#	$totalwbw+=$total_w_bw/$lines; #add to total, will be divided by runs
}






sub _handle_psaux_output
{
	my ($logpath)=($_[0]);

	my ($refpid,$max_cpu,$lines,$total_cpu)=(0,0,0,0);
	my $psauxfile ="$logpath";
	my %result;

	open ( my $pah, '<', "$psauxfile");
	foreach my $line (<$pah>)
	{
		next if ($line =~/tee/); #only get dd lines
		next unless ($line =~/fio/); #only get dd<jobid> lines
		my $path=""; #do we need to add ${dslong2}. ?
		#root       8099    0.0  0.0   6268   2180  0  R+   14:24      0:00.02 dd of=/dev/null if=/mnt/pool_m2_vdevs-1_offset-2/ds_64k_sync-always_compr-off/dd1.ou
		#root       44910    0.0  0.0   6268   2164  0  D+   04:20       0:00.02 dd if=/dev/zero of=/mnt/pool_z3_vdevs-1_offset-0/ds_64k_sync-always_compr-off/dd1.out bs=4k count=262144
		#root       44911    0.0  0.0   6252   2048  0  D+   04:20       0:00.00 tee /mnt/pool_z3_vdevs-1_offset-0/ds_64k_sync-always_compr-off/dd1.out.write
		#--------USER-----PID-----CPU-------------MEM--------------VSZ---RSS-----TT------STAT--STARTED---------TIME---------------_command
		#if ($line=~/\w+\s+(\d+)\s+(\d{1,3}\.d{1,2})\d{1,2}\.d{1,2}\s+\d+\s+\d+\s+.{1,2}\s+.+\s+\d{2}:\d{2}\s+\d{1,}:\d{2}\.d{2}\s+($ddtests{$mastertestid}{tool}.*?$path\.out).*$)
		if ($line=~/\w+\s+(\d+)\s+(\d{1,3}\.\d{1,2})\s+\d{1,2}\.\d{1,2}\s+\d+\s+\d+\s+.{1,2}\s+.+\s+\d{2}:\d{2}\s+\d{1,}:\d{2}\.\d{2}\s+(fio.*?$path).*?$/)
		{
			$refpid=$1;
			&_print_log(3, "psaux $1 $2=>" );
			next if ($2=~/0.0/);

			$total_cpu+=$2;
			$lines++; # assume we ran every second, so we will average by dividing by lines below
			$max_cpu=$2 if ($2 > $max_cpu); #capture peak load
			&_print_log(3, "$total_cpu , $lines\n" );
		}
	}
	close $pah;
	&_print_log(3, "psaux $total_cpu $max_cpu, $lines lines\n" );
	$lines=1 unless ($lines); #prevent division by 0 error. If we didnt match any lines total_cpu is 0 too so no problem
	$result{'realpid'}=$refpid;
	$result{'load'}=$total_cpu/$lines;
	$result{'load_peak'}=$max_cpu;
#	$totalcpu+=$total_cpu/$lines; #add to total, will be divided by runs
	&_print_log(3, "loadavg: $total_cpu/$lines\n");
	&_print_log(3, "loadmax: $max_cpu\n");
	#print "_handle_psaux_output", Dumper \%result;
	return \%result;

}


sub _do_sanity_checks
{
	die "Cant run with uservar_useslog and useslogmirror set at the same time" if ($uservar_useslog && $useslogmirror);
	die "Minimum nr of disks for z1 is 2" if $_diskcount_z1 <3;
	die "Minimum nr of disks for z2 is 3" if $_diskcount_z2 <4;
	die "Minimum nr of disks for z3 is 4" if $_diskcount_z3 <5;
	
	die "Cant do userpool and testsonly at the same time " if ($userpool_do && $testsonly_do);

  #safeguarding the primary freenas box
	die "force is on on $host" if ($force_pool_creation & $host=~/^freenas6/);

   my $dir = getcwd;
   die "Don't run this in /tmp for your own sanity (FreeNas looses /tmp on reboot)" if ($dir =~/^\/tmp/);
   
   



	if ($fio_do)
	{
		&_print_log (3, "fio selected - checking  $jsonppbinary \n");
		#check if we find  $jsonppbinary 
		my $_command="which $jsonppbinary ";
		push @log_master_command_list, $_command;
		my @_res=&_exec_command("$_command",1);
		die " $jsonppbinary  is not in path or does not exist at all - it is needed to read back fio output\nfor linux you can get it from https://github.com/jmhodges/jsonpp/releases/download/1.3.0/jsonpp-1.3.0-linux-x86_64.zip  " if $?;
	}
	
	if ($diskinfo_do)
	{
		&_print_log (3, "diskinfo selected - checking diskinfo binary\n");
		#check if we find diskinfo
		my $_command="which diskinfo ";
		push @log_master_command_list, $_command;
		my @_res=&_exec_command("$_command",1); #dont die here
		if ($?)
		{
			&_print_log (1, "->diskinfo is not in path or does not exist at all - it is needed to perform the diskinfo check - skipping\n");
			$diskinfo_do=0;
		}
		
	}

}

sub _prepare_logdir
{
	if ($user_make_logs_persistent)
	{
		$logpath="$user_logdir/$$.log";
		&_print_log (1, "Logging to $logpath\n");
		mkdir "$logpath" or die "cannot create directory $logpath ";

	}
	else
	{
		&_print_log (2, "Logging to temporary locations\n");
	}
}

sub _print_hash_generic
{

    # href = reference to the hash we're examining (i.e. \%extend_hash)
    # so_far = arrayref containing the hash keys we are accessing
    my $href = shift;
    my $so_far = shift;
    foreach my $k (keys %$href)
    {
        # put $k on to the array of keys
        push @$so_far, $k;
        # if $href->{$k} is a reference to another hash, call print_hash on that hash
        if (ref($href->{$k}) eq 'HASH')
        {
            &_print_hash_generic($href->{$k}, $so_far);
        }
        else
        {
        # $href->{$k} is a scalar, so print out @$so_far (our list of hash keys)
        # and the value in $href->{$k}
            print join(", ", @$so_far, $href->{$k}) . "\n";
        }
        # we've finished looking at $href->{$k}, so remove $k from the array of keys
        pop @$so_far;

		}
}

sub _check_changeloglevel_requested
{
	&_print_log (4, "Checking if loglevelfiles ($0.loglevelX) are present\n");
	my $old=$verbose;
	
	if (-e $loglevel1touchfile )
	{
		&_print_log (2, "Log Level 1 file ($loglevel1touchfile) found\n"); 
		unlink $loglevel1touchfile;
		$verbose=1;
		&_print_log (1, "Log Level 1 set (old value was $old)\n"); 
	}
	elsif (-e $loglevel2touchfile )
	{
		&_print_log (2, "Log Level 2 file ($loglevel2touchfile) found\n"); 
		unlink $loglevel2touchfile;
		$verbose=2;
		&_print_log (1, "Log Level 2 set (old value was $old)\n"); 
	}
	elsif (-e $loglevel3touchfile )
	{
		&_print_log (2, "Log Level 3 file ($loglevel3touchfile) found\n"); 
		unlink $loglevel3touchfile;
		$verbose=3;
		&_print_log (1, "Log Level 3 set (old value was $old)\n"); 
	}
	elsif (-e $loglevel4touchfile )
	{
		&_print_log (2, "Log Level 4 file ($loglevel4touchfile) found\n"); 
		unlink $loglevel4touchfile;
		$verbose=4;
		&_print_log (1, "Log Level 4 set (old value was $old)\n"); 
	}
	else
	{
		&_print_log (4, "Log Level file not found\n");
		return 0;
	}
}


sub _check_report_requested
{
	&_print_log (4, "Checking if reportfile ($reporttouchfile) is present\n");
	if (-e $reporttouchfile )
	{
		&_print_log (2, "Report file ($reporttouchfile) found\n"); 
		unlink $reporttouchfile;
		return 1;
	}
	else
	{
		&_print_log (4, "Report file ($reporttouchfile) not found\n");
		return 0;
	}
}

sub _check_stop_requested
{
	return 1 if $stop_requested; #no need to rerun while already stopping
	&_print_log (4, "Checking if stopfile ($stopfile) is present\n");
	if (-e $stopfile )
	{
		&_print_log (1, "Stop file ($stopfile) found - exiting\n"); 
		unlink $stopfile;
		$stop_requested=1;
		return 1;
	}
	else
	{
		&_print_log (4, "Stop file ($stopfile) not found - continuing\n");
		return 0;
	}
}

sub _check_runtimeinfo_requested
{
	&_print_log (4, "Checking if infofile ($infofile) is present\n");
	return unless (-e $infofile);
		
	&_print_log (2, "Info file ($infofile) found\n");
	
	my ($_cnt_pools,$_cnt_datasets,$_cnt_fio,$_cnt_dd)=(0,0,0,0);
	
	foreach my $a (@_report_pools)
	{
		&_print_log (0, "-----INFO-----:Poolinfo: $a\n");
		$_cnt_pools++;
		foreach my $b (@_report_datasets)
		{
			&_print_log (0, "-----INFO-----:\tDataset info: $b\n");
			$_cnt_datasets++;
			if ($fio_do)	
			{
				foreach my $a (@_report_fiotests)
				{
					&_print_log (0, "-----INFO-----:\t\tFIO: $a\n");
					$_cnt_fio++;					
				}
			}
			if ($dd_do)
			{
				foreach my $a (@_report_ddtests)
				{
					&_print_log (0, "-----INFO-----:\t\tDD: $a\n");
					$_cnt_dd++;
				}
			}
		}
	}
	
	my $_cnt_dd_per= scalar (@_report_ddtests);
	my $_cnt_fio_per= scalar (@_report_fiotests);
	my $actual_ds=$_cnt_datasets/$_cnt_pools; #datasets contains pools
	&_print_log (0, "-----INFO-----:pools $_cnt_pools , $actual_ds datasets, $_cnt_fio fio total ($_cnt_fio_per fio per ds), $_cnt_dd dd total ($_cnt_dd_per per ds)\n");
		
	my $sum=$_cnt_dd + $_cnt_fio; 
	my $calculated_sum=&_get_total_tests;
	&_print_log (0, "-----INFO-----:Total tests: $sum , calculated=$calculated_sum\n");
	&_print_log (0, "-----INFO-----:Currently at $mastertestid\n");
	
	unlink $infofile;
	unless (scalar (@_report_datasets))
	{
		print Dumper \@_report_pools;
		print Dumper \@_report_datasets;
		print Dumper \@_datasets;
		print Dumper \%_datasets;
		
		die "investigate me";
	}
	#	pools 6 , 0 datasets, 0 fio (total),  128 fio (per ds) , 0 dd, 0 dd (per ds)

}

sub _get_total_tests
{
	my $_dd_per_ds= scalar (@_report_ddtests);
	my $_fio_per_ds= scalar (@_report_fiotests);
	my $_pools= $totalpools;
	my $_ds= scalar (@_datasets); # contains pools
	#my $actual_ds=$_ds/$_pools; #datasets contains pools
	
	#print "_dd_per_ds $_dd_per_ds _fio_per_ds $_fio_per_ds _pools $_pools _ds $_ds\n";
	
	return ($_pools* $_ds * ($_dd_per_ds +$_fio_per_ds));

}

sub _exec_command()
{
	my ($_command,$dont_die)=($_[0],$_[1]);
	my ($handle,$retval,$retcode,@output);

	$dont_die=0 unless ($dont_die); # dont die if the calling functions says we dont need to. Most failed commands break the script, so die is the default

	open ( $handle, '>>', "${ppid}_executed_commands");
	print $handle "$_command";
	close $handle;

	unless ($dryrun)
	{
		@output = `$_command`;
		$retval=$?;
		$retcode=$!;
	}
	else
	{
		$retval=0;
		$retcode="Dryrun only";
	}

	open ( $handle, '>>', "${ppid}_executed_commands");
	print $handle "| $retval, $retcode |",join " ",@output, "\n";
	close $handle;

	if ($retval)
	{
		&_print_log(2, "executing command: $_command failed with $retval, $retcode, ",join " ",@output,"\n" );
		die "executing command: $_command failed with $retval, $retcode, ",join " ",@output,"\n" unless $dont_die;
	}
	return @output;
}

sub _create_output
{	
		&_define_master_report;		
		&_build_master_report; 		
		&_print_master_report ('dd') if $dd_do;
		&_print_master_report ('fio') if $fio_do;
}

&_get_system_info; # run before sanity checks to be able to adjust these by platform
&_do_sanity_checks();
&_print_disclaimer();


$UniqueRunID=&_getRunTime. "-$_pid";

&_get_diskinfo_disklistpl unless ($_skip_disklistpl || $userpool_do);
#&_detect_pmem;

#now determine which disks to use - we have 4 options - script variables, disklist, cli parameters or interactive selection)
#1. user selected interactive menu and chose file there (not implemented yet)
#2. user provided params on the cli (not implemented yet)
#3. user provided a list of drives in the disklist file
#4. user provided a list of drives in the script/config file

#dont do this if we get a user defined pool
unless ($userpool_do)
{
	$_got_disks=&_get_disks_from_menu;
	$_got_disks=&_get_disks_from_cli_params unless $_got_disks;
	$_got_disks=&_get_disklist_from_file ($diskfile) unless $_got_disks;
	$_got_disks=&_get_disks_from_script_vars unless $_got_disks; # this one dies if it can't find any drives
	&_normalize_pooldisks;# for easier reporting
	die "You provided drives for the pool which are already in a pool. This will cause \"drive is part of active pool\" error.\nPlease run zpool destroy on old pool or change disk assignment" if (&_check_drives_in_pool);
}
else 
{
	&_print_log(3, "Getting userpool from file $diskfile\n" );
	&_get_userpool_from_file($diskfile);
}


####
# ADD a mapping between the user provided info and _get_diskinfo_disklistpl to use the best info we have (eg gptid)
###

&_set_arc_limit if ($arc_limit_do && $^O!~/linux/);
&_prepare_logdir;


if ($fio_do)
{
	&print_log (0, "fio selected but no tests defined\n") unless &_determine_fio_tests;
}
if ($dd_do)
{
	&print_log (0, "dd selected but no tests defined\n") unless &_calculate_dd_runs;
}
unless ($userpool_do)
{
	&_set_skip_trim unless ($^O=~/linux/);
	&_run_diskinfo_test if $diskinfo_do;
	&_print_diskinfo_report if $diskinfo_do;
}

if ($fio_do || $dd_do)
{
	unless ($userpool_do)
	{
		#preparation
		&_calculate_pool_options_extended;
		&_do_cache_and_log_checks_extended;
		&_combine_and_reorder_pools_and_cache_slog_options;
		
		#execution
		&_create_all_pools_extended;
	}
	else #perform tests on user given pool only
	{
		_handle_user_given_pool;
	}
	
	#output
	&_create_output unless $_do_regular_output; # we should have output from the last "end of test" check - no need to run twice
	&_print_log (0, "Final create output skipped due to intermediate outputs\n") unless $_do_regular_output;
}
else
{
	&_print_log (0, "Neither fio nor dd selected\n");
}
	




#print "_out_masterreport_info\n";
#&_print_hash_generic(\%_out_masterreport_info, []);
#print "ddtests\n";
#&_print_hash_generic(\%ddtests, []);
#print "_out_masterreport\n";
#&_print_hash_generic(\%_out_masterreport, []);



#&_report_dd_results if ($dd_do);
#&_report_fio_results if ($fio_do);


#cleanup activities

&_write_commandlist;
&_reset_arc_limit unless ($^O=~/linux/); 
&_print_log (0, "Processing done - exiting $$\n");



#test_nr vdev_type	vdev_count	vdev_disks	ds_recordsize	ds_sync	ds_compression	slog_type	slog_count	test_total_size	test_bs	test_bc	test_inst_count	test_type	test_result




#open ( $pihandle, '>', $poolinfofile);
####build header
#my ($diskinfo,$rdisk);
#for (my $disknr=1; $disknr <= $_diskcount_z3; $disknr++)
#{
#	$rdisk="disk$disknr";
#	$diskinfo.=$rdisk if ($disknr==1);
#	$diskinfo.=";$rdisk";
#}
#print $pihandle "ID;poolname;_pooltype;max_vdevs;diskspervdev;uselog;useslogmirror;vdev_nr;$diskinfo\n";
#my $id=0;
#### loop for actual data
#print Dumper \%_poolinfo;
#foreach my $reppoolname (keys %_poolinfo)
#{
#	foreach my $reppoolvdev (keys %{$_poolinfo{$reppoolname}})
#	{
#		next if $reppoolvdev!~/vdev/; #skip all but vdevs here
#		#all other info is about the n current vdevs
#
#		my $diskinfo;
#		for (my $disknr=1; $disknr <= $_diskcount_z3; $disknr++)
#		{
#			$rdisk='none';
#			$rdisk=$_poolinfo{$reppoolname}{$reppoolvdev}{"disk$disknr"} if exists ($_poolinfo{$reppoolname}{$reppoolvdev}{"disk$disknr"});
#			$diskinfo.=$rdisk if ($disknr==1);
#			$diskinfo.=";$rdisk";
#
#		}
#		print $pihandle "$id;$reppoolname;$_poolinfo{$reppoolname}{poolinfo}{type};$_poolinfo{$reppoolname}{poolinfo}{max_vdevs};$_poolinfo{$reppoolname}{poolinfo}{diskspervdev};$_poolinfo{$reppoolname}{poolinfo}{uselog};$_poolinfo{$reppoolname}{poolinfo}{useslogmirror};$reppoolvdev;$diskinfo\n";
#		$id++;
#	}
#}
#close $pihandle;



#print "_mastertestinfo:", Dumper \%_mastertestinfo;
#print "_pools:", Dumper \%_pools;
#print "_datasets:", Dumper \%_datasets;

#print "ddtests:", Dumper \%ddtests;


exit;


__END__
_mastertestinfo:$VAR1 = {
          '4' => {
                   'tool' => 'fio'
                 },
          '7' => {
                   'tool' => 'fio'
                 },
          '11' => {
                    'tool' => 'fio'
                  },
          '2' => {
                   'tool' => 'fio'
                 },
          '8' => {
                   'tool' => 'fio'
                 },
          '6' => {
                   'tool' => 'fio'
                 },
          '12' => {
                    'tool' => 'fio'
                  },
          '10' => {
                    'tool' => 'fio'
                  },
          '1' => {
                   'tool' => 'fio'
                 },
          '5' => {
                   'tool' => 'fio'
                 },
          '3' => {
                   'tool' => 'fio'
                 },
          '9' => {
                   'tool' => 'fio'
                 }
        };
_pools:$VAR1 = {
          '1' => {
                   'datasets' => {
                                   '2' => 'p_sin_no01_v08_o00_cno_sno/ds_64k_sync-always_compr-off',
                                   '3' => 'p_sin_no01_v08_o00_cno_sno/ds_64k_sync-disabled_compr-off'
                                 },
                   'name' => 'p_sin_no01_v08_o00_cno_sno',
                   'type_verbose' => 'single disk',
                   'nr_vdevs' => '08',
                   'type_tech' => '',
                   'diskspervdev' => 1,
                   'offset' => '00',
                   'slogoption' => 'no',
                   'l2arcoption' => 'no',
                   'status' => 0,
                   'vdevs' => {
                                'vdev_5' => {
                                              'disk1' => 'gptid/008644e7-bd14-11e8-bfcd-0050569e17a3'
                                            },
                                'vdev_6' => {
                                              'disk1' => 'gptid/c5c0beb8-c6f0-11e8-9bdd-0050569e17a3'
                                            },
                                'vdev_3' => {
                                              'disk1' => 'gptid/02856159-bd14-11e8-bfcd-0050569e17a3'
                                            },
                                'vdev_2' => {
                                              'disk1' => 'gptid/01ae2c5c-bd14-11e8-bfcd-0050569e17a3'
                                            },
                                'vdev_4' => {
                                              'disk1' => 'gptid/01544d13-bd14-11e8-bfcd-0050569e17a3'
                                            },
                                'l2arcdevs' => 'none',
                                'vdev_1' => {
                                              'disk1' => 'gptid/c6326e4a-c6f0-11e8-9bdd-0050569e17a3'
                                            },
                                'vdev_7' => {
                                              'disk1' => 'gptid/00ec1fbe-bd14-11e8-bfcd-0050569e17a3'
                                            },
                                'slogdevs' => 'none',
                                'vdev_8' => {
                                              'disk1' => 'gptid/021aaa35-bd14-11e8-bfcd-0050569e17a3'
                                            }
                              }
                 },
          '2' => {
                   'diskspervdev' => 8,
                   'type_verbose' => 'raidz2',
                   'type_tech' => 'raidz2',
                   'nr_vdevs' => '01',
                   'datasets' => {
                                   '4' => 'p_z2_no01_v01_o00_cno_sno/ds_64k_sync-always_compr-off',
                                   '5' => 'p_z2_no01_v01_o00_cno_sno/ds_64k_sync-disabled_compr-off'
                                 },
                   'name' => 'p_z2_no01_v01_o00_cno_sno',
                   'vdevs' => {
                                'l2arcdevs' => 'none',
                                'vdev_1' => {
                                              'disk2' => 'gptid/01ae2c5c-bd14-11e8-bfcd-0050569e17a3',
                                              'disk6' => 'gptid/c5c0beb8-c6f0-11e8-9bdd-0050569e17a3',
                                              'disk8' => 'gptid/021aaa35-bd14-11e8-bfcd-0050569e17a3',
                                              'disk5' => 'gptid/008644e7-bd14-11e8-bfcd-0050569e17a3',
                                              'disk1' => 'gptid/c6326e4a-c6f0-11e8-9bdd-0050569e17a3',
                                              'disk4' => 'gptid/01544d13-bd14-11e8-bfcd-0050569e17a3',
                                              'disk3' => 'gptid/02856159-bd14-11e8-bfcd-0050569e17a3',
                                              'disk7' => 'gptid/00ec1fbe-bd14-11e8-bfcd-0050569e17a3'
                                            },
                                'slogdevs' => 'none'
                              },
                   'status' => 0,
                   'slogoption' => 'no',
                   'l2arcoption' => 'no',
                   'offset' => '00'
                 },
          '0' => {
                   'slogoption' => 'no',
                   'l2arcoption' => 'no',
                   'offset' => '00',
                   'vdevs' => {
                                'vdev_3' => {
                                              'disk2' => 'gptid/c5c0beb8-c6f0-11e8-9bdd-0050569e17a3',
                                              'disk1' => 'gptid/008644e7-bd14-11e8-bfcd-0050569e17a3'
                                            },
                                'slogdevs' => 'none',
                                'l2arcdevs' => 'none',
                                'vdev_1' => {
                                              'disk1' => 'gptid/c6326e4a-c6f0-11e8-9bdd-0050569e17a3',
                                              'disk2' => 'gptid/01ae2c5c-bd14-11e8-bfcd-0050569e17a3'
                                            },
                                'vdev_2' => {
                                              'disk2' => 'gptid/01544d13-bd14-11e8-bfcd-0050569e17a3',
                                              'disk1' => 'gptid/02856159-bd14-11e8-bfcd-0050569e17a3'
                                            },
                                'vdev_4' => {
                                              'disk2' => 'gptid/021aaa35-bd14-11e8-bfcd-0050569e17a3',
                                              'disk1' => 'gptid/00ec1fbe-bd14-11e8-bfcd-0050569e17a3'
                                            }
                              },
                   'status' => 0,
                   'name' => 'p_sin_mir02_v04_o00_cno_sno',
                   'datasets' => {
                                   '1' => 'p_sin_mir02_v04_o00_cno_sno/ds_64k_sync-disabled_compr-off',
                                   '0' => 'p_sin_mir02_v04_o00_cno_sno/ds_64k_sync-always_compr-off'
                                 },
                   'diskspervdev' => 2,
                   'type_verbose' => 'single disk mirror',
                   'type_tech' => 'mirror',
                   'nr_vdevs' => '04'
                 }
        };
_datasets:$VAR1 = {
          '1' => {
                   'poolid' => 0,
                   'name' => 'p_sin_mir02_v04_o00_cno_sno/ds_64k_sync-disabled_compr-off',
                   'dsinfo' => {
                                 'zfs_sync_options' => 'disabled',
                                 'zfs_compression_options' => 'off',
                                 'zfs_recordsizes' => '64k'
                               },
                   'name_short' => 'ds_64k_sync-disabled_compr-off',
                   'status' => 0
                 },
          '4' => {
                   'poolid' => 2,
                   'name' => 'p_z2_no01_v01_o00_cno_sno/ds_64k_sync-always_compr-off',
                   'name_short' => 'ds_64k_sync-always_compr-off',
                   'status' => 0,
                   'dsinfo' => {
                                 'zfs_recordsizes' => '64k',
                                 'zfs_compression_options' => 'off',
                                 'zfs_sync_options' => 'always'
                               }
                 },
          '2' => {
                   'name_short' => 'ds_64k_sync-always_compr-off',
                   'status' => 0,
                   'dsinfo' => {
                                 'zfs_compression_options' => 'off',
                                 'zfs_sync_options' => 'always',
                                 'zfs_recordsizes' => '64k'
                               },
                   'poolid' => 1,
                   'name' => 'p_sin_no01_v08_o00_cno_sno/ds_64k_sync-always_compr-off'
                 },
          '5' => {
                   'dsinfo' => {
                                 'zfs_sync_options' => 'disabled',
                                 'zfs_compression_options' => 'off',
                                 'zfs_recordsizes' => '64k'
                               },
                   'status' => 0,
                   'name_short' => 'ds_64k_sync-disabled_compr-off',
                   'name' => 'p_z2_no01_v01_o00_cno_sno/ds_64k_sync-disabled_compr-off',
                   'poolid' => 2
                 },
          '0' => {
                   'poolid' => 0,
                   'name' => 'p_sin_mir02_v04_o00_cno_sno/ds_64k_sync-always_compr-off',
                   'dsinfo' => {
                                 'zfs_compression_options' => 'off',
                                 'zfs_recordsizes' => '64k',
                                 'zfs_sync_options' => 'always'
                               },
                   'status' => 0,
                   'name_short' => 'ds_64k_sync-always_compr-off'
                 },
          '3' => {
                   'name_short' => 'ds_64k_sync-disabled_compr-off',
                   'status' => 0,
                   'dsinfo' => {
                                 'zfs_compression_options' => 'off',
                                 'zfs_recordsizes' => '64k',
                                 'zfs_sync_options' => 'disabled'
                               },
                   'poolid' => 1,
                   'name' => 'p_sin_no01_v08_o00_cno_sno/ds_64k_sync-disabled_compr-off'
                 }
        };


ddtests

'30' => {
                    'details' => {
                                   'read_avg_bytes_per_job' => {
                                                                 'run1' => '923899992'
                                                               },
                                   'read_total_bytes_all_jobs' => {
                                                                    'run1' => 923899992
                                                                  },
                                   'write_total_duration_all_jobs' => {
                                                                        'run1' => '0.895425'
                                                                      },
                                   'read' => {
                                               'runs' => {
                                                           '1' => {
                                                                    'info' => {
                                                                                'jobs' => {
                                                                                            '1' => {
                                                                                                     'pid' => 14916
                                                                                                   }
                                                                                          }
                                                                              }
                                                                  }
                                                         }
                                             },
                                   'read_avg_wbw_per_job' => {
                                                               'run1' => '0'
                                                             },
                                   'read_avg_per_run' => {
                                                           'run1' => '923899992'
                                                         },
                                   'write_avg_per_run' => {
                                                            'run1' => '1199142436'
                                                          },
                                   'read_avg_load_per_job' => {
                                                                'run1' => '0'
                                                              },
                                   'read_avg_wios_per_job' => {
                                                                'run1' => '0'
                                                              },
                                   'write_avg_bytes_per_job' => {
                                                                  'run1' => '1199142436'
                                                                },
                                   'read_avg_rios_per_job' => {
                                                                'run1' => '0'
                                                              },
                                   'write_avg_wbw_per_job' => {
                                                                'run1' => '0'
                                                              },
                                   'jobs' => {
                                               '1' => {
                                                        'write_bytes' => {
                                                                           'run1' => '1199142436'
                                                                         },
                                                        'read_duration' => {
                                                                             'run1' => '1.162184'
                                                                           },
                                                        'write_duration' => {
                                                                              'run1' => '0.895425'
                                                                            },
                                                        'read_bytes' => {
                                                                          'run1' => '923899992'
                                                                        }
                                                      }
                                             },
                                   'write_avg_duration_per_job' => {
                                                                     'run1' => '0.895425'
                                                                   },
                                   'run1' => {
                                               'psaux' => {
                                                            'realpid' => 0,
                                                            'load_peak' => 0,
                                                            'load' => '0'
                                                          },
                                               'zpool' => {
                                                            'avg_w_ops' => '2952.53333333333',
                                                            'avg_r_bw' => '104752742.4',
                                                            'avg_w_bw' => '130722474.666667',
                                                            'avg_r_ops' => '1245.86666666667'
                                                          }
                                             },
                                   'write_avg_rios_per_job' => {
                                                                 'run1' => '0'
                                                               },
                                   'write_total_bytes_all_jobs' => {
                                                                     'run1' => 1199142436
                                                                   },
                                   'read_total_duration_all_jobs' => {
                                                                       'run1' => '1.162184'
                                                                     },
                                   'write_avg_rbw_per_job' => {
                                                                'run1' => '0'
                                                              },
                                   'read_avg_rbw_per_job' => {
                                                               'run1' => '0'
                                                             },
                                   'write_avg_load_per_job' => {
                                                                 'run1' => '0'
                                                               },
                                   'read_avg_duration_per_job' => {
                                                                    'run1' => '1.162184'
                                                                  },
                                   'write_avg_wios_per_job' => {
                                                                 'run1' => '0'
                                                               },
                                   'write' => {
                                                'runs' => {
                                                            '1' => {
                                                                     'info' => {
                                                                                 'jobs' => {
                                                                                             '1' => {
                                                                                                      'pid' => 14848
                                                                                                    }
                                                                                           }
                                                                               }
                                                                   }
                                                          }
                                              }
                                 },
                    'info' => {
                                'dsid' => '14',
                                'dd_file_size' => '1G',
                                'instcnt' => 1,
                                'dsname_short' => 'ds_64k_sync-disabled_compr-off',
                                'dd_file_size_bytes' => 1073741824,
                                'bs' => '1M',
                                'dd_runs_per_test' => 1,
                                'dsname' => 'p_sin_no01_v08_o00_cno_sno/ds_64k_sync-disabled_compr-off-all'
                              }
                  }
        };
Skipped Fio for 20
Called RunDD for dataset p_sin_no01_v08_o00_cno_sno/ds_1M_sync-always_compr-off-most (test #43)
