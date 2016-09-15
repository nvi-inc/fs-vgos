---
title: VGOS Operations Notes
subtitle: Version 0.9
date: September 2016
---

Set-up of RDBE from a cold start (if needed):
================================================

Start RDBE server
-----------------

From FS PC shell prompt, login to each RDBE:
```bash
ssh root@rdbe$X
```
use `$X=a`, `b`, `c`, or `d` to log into RDBE-`$X`.

Then, on each RDBE run
```bash
rbin
nohup ./rdbe_server 5000 6 &
exit
```
Repeat this for each RDBE that has been restarted. You can verify when all the RDBEs
have started from the FS with:
```fs
rdbe_status
```
There will be error for each RDBE that is not ready. When all RDBEs
respond with a status value `0x0e01`, proceed to step the next step.

Load Firmware
-------------

To load the firmware on all RDBEs, use the FS command:
```fs
rdbe_fpga
```

If you want to load the firmware individually for RDBE-`$X`,
you can use the FS command
```fs
rdbe_fpga$X
```
again, where `$X=a`, `b`, `c`, or `d` as necessary.

There will be an error for each RDBE, since it will not respond right
away and will time-out. You verify when this is finished from the FS
with again using
```fs
rdbe_status
```

This time, the RDBEs should respond with status `0x0f01`

When all status values reach the correct value, proceed to step C.

Configure RDBEs
---------------

To initialize the configuration on all RDBEs, use the FS command:

```fs
rdbe_init
```
You should get four "success" messages.


If you need initialize an RDBE individually use, the FS command
```fs
rdbe_init$X
```
You should get four "success" messages.


Sync RDBEs
----------

It is **necessary** to sync and set the time with `fmset` for an RDBE
**every time** it is restarted. (And also as soon as feasible after a
December 31 and a June 30, before the first experiment after those dates
at the latest).

To do this from the FS console,
press `<Control><Shift>T` to start `fmset`, or type
```bash
fmset
```
in an FS PC shell.

You can select the RDBE to set by letter: `a`, `b`, `c`, or `d`. 

With that RDBE's time being displayed, type `s` to sync it (and `y` to confirm), then
type `.` (dot) to set the time to FS time. 

If the resulting displayed time is off by up to a few seconds, use `+` and/or `-` to increment
and/or decrement the RDBE by a second at time until it agrees with the
FS time. 

Be sure to exit with `<Escape>`. 

>Note: if an experiment spans the end of a December 31 or a June 30 and any RDBE gets its time
reset after that but before the end of the experiment, **all** the RDBEs
must have their times reset before recordings will work again.

**After setting the time for each RDBE that needs it, repeat the
[configure step above](#configure-rdbes) for each RDBE that was set.**

Set-up of Mark 6 from a cold start (if needed):
===============================================

Start cplane and dplane
-----------------------

Login to the mark6:
```bash
ssh root@mark6a
```
Check if `cplane` and `dplane` are running:

```bash
ps aux | grep plane
```

To start them if they are not running:

```bash
/etc/init.d/dplane start
/etc/init.d/cplane start
```

Set-up MCI server (if needed):
==============================

You can test whether this is needed by using the FS SNAP procedure:

```fs
dewar
```

and see if you get useful output. If not, log into the MCI server node
(need details: as oper? is a password needed? Will `ssh oper@mci`
work?), and start the server with:

```bash
./startmciserver
```

And log out of the MCI server node

DRUDG experiment files
======================
To create the station specific files schedule and procedure files from the master file:

1. Put schedule in `/usr2/sched` on FS PC

2. Run `drudg`, from FS PC shell:
    ```bash
    cd /usr2/sched
    drudg <schedule_name>.skd
    ```
    Now, in `drudg`, give the following commands (ignoring text after `#`)
    ```drudg
    XX                       # select your station code XX (gs = GGAO)
    3                        # make .snp
    12                       # make .prc
    9                        # change printer output destination
    <schedule_name>XX.lst    # destination file, XX = station code
                             # three more <Return>s
    5                        # print summary
    0                        # exit DRUDG
    ```

Experiment set-up
=================

Start FS log file
-----------------

In the FS, open the experiment log so the set-up will recorded in
that log:
```fs
log=v15xxxXX
```

Check RDBE time and offsets
---------------------------

>**Note:** if this is the first experiment since December 31 and June 30, and
the RDBEs have not had their time set since that epoch, reset the time each of
RDBE according [the sync RDBEs step 1.D above](#sync-rdbes). This must be done even if the
time appears to be correct in the step below.

In the FS, check RDBE time and offsets:

```fs
time
```

The offsets should be small and the DOT times should be the same and the
same as the FS log timestamps. If not, run `fmset` (`<Control><Shift>T`) and verify and set times.

(Don't use `s` for sync unless that RDBE had a PPS offset larger that ±2e-8.
**If you do sync, you must re-initialize that RDBE afterwards, following [step 1.C above](#configure-rdbes)**) by cycling through RDBEs (type each band letter:
`a`, `b`, `c`, or `d`), and be sure to exit (`<Escape>`)

Initialize pointing
-------------------
In the FS, initialize pointing setup and send antenna to test source:

```fs
proc=point
initp
casa
```

Set mode and attenuators
------------------------

In the FS, set-up experiment mode and adjust attenuators

```fs
proc=v15xxxXX
setupbb
ifdbb
mk6bb
auto           # sets all attenuators three times
```

Check RDBEs
-----------

Run RDBE Monitor program (`<Control><Shift>6`),
and check for each RDBE that:

1.  DOT ticking and correct time

2.  DOT2GPS value small (a few µseconds) and stable (varies by 0.1
    µseconds or less)

3.  RMS value close to 32

4.  Tsys IF0 and IF1 about 50-100, may be jumping a bit

5.  Phase-cal amplitude about 10-100, phase stable to within a few
    degrees

Leave the window open for later monitoring but position out of the way
as necessary.

Check pointing
--------------

In the FS, Check pointing and SEFDs on test source when you have
reached the source

```fs
onsource            # result should be TRACKING
fivept              # verify xoffset offset values are small
onoff               # verify SEFDs for eight bands are reasonable, \~2000-3000
azeloff=0d,0d       # zero offsets
```

Make test recording
-------------------

a.  This is to help with debugging, display and clear the Mark 6 message
    queue:

    ```fs
    mk6=msg?;
    ```

    If an unexplained error happens during the following procedure, please
    use this command again to get more information.


b.  Initialize module; create, mount, and open module

    Check status:

    ```fs
    mk6=mstat?all;
    ```

    After the two fields: return code and `cplane` status (hopefully `mstat?0:0`)
    there are 10 fields per group:

    ```
    group:slot:eMSN:#disks found:#disks nominal:free space:total space:status1:status2:type
    ```

    It may be easier to read if individual groups are queried; eg. for group 1:

    ```fs
    mk6=mstat?1;
    ```

    If the module has already been initialized (status1 is `initialized`),
    and the data is no longer needed, erase it:

    ```fs
    mk6=group=unprotect:<group>;
    mk6=group=erase:<group>;
    ```

    If the module has not been initialized (`status1` is "unknown" and no
    `eMSN`?), initialize it:

    ```fs
    mk6=mod_init=<slot#>:<#disks>:<MSN>:<type>:<new>;
    ```

    For example
    ```fs
    mk6=mod_init=1:8:HAY%0001:sg:new;
    ```

    Create, open and mount the group:

    ```fs
    mk6=group=new:<slots>;
    mk6=group=mount:<slots>;
    mk6=group=open:<slots>;
    ```

    To query if the group is created properly:

    ```fs
    mk6=group?;
    ```

    Print out should have the group number at the end. If it is a “-”
    something has gone wrong

c. In FS, record some test data:

    ```fs
    mk6=record=on:30:30;
    ```

    verify that lights flash appropriately. You can check recording status
    with:

    ```fs
    mk6=record?;
    ```

    It should progress starting as "recording" then transitioning to "off".

    If the status stays “pending”, it maybe that not all the RDBEs are
    sending data. You can check this by using the FS SNAP procedure
    **mk6in**, which will show the Gb/s by interface. If one or more
    interfaces are not showing the approximate nominal data rate (initially
    2 Gb/s per interface), it is likely that the corresponding RDBEs need to
    be reconfigured. Sample, correct 2 Gb/s FS log output:

    ```
    2015.211.18:34:44.63\#popen\#mk6in/eth2 2.078 eth3 2.079 eth4 2.079 eth5
    2.079 Gb/s
    ```

d. Once recording ends, check quality:

    ```fs
    mk6=scan_check?;
    ```

    Results should show vdif, time of `record=on`, 30 seconds of data, 30 GB
    of data and 8 Gbps data rate.

Start experiment
===================

Start non-FS multi-cast logging:
--------------------------------

From a FS PC shell prompt, connect to mark5-19 (Wf)

```bash
ssh oper@wfmark5-19
```
 or monkey (Gs):

```bash
ssh oper@monkey
```

Clean-out old monitor data as appropriate, to delete all:

```bash
rm -i rdbe30_mon_dat_*.log
```

Start logging and exit:

```bash
start_multicast_logging
exit
```

Send "Ready" message
--------------------

Details are to be determined, but the message should include at least an
SEFD from each IF, and the DOT2GPS for each band.

Start schedule
--------------

In FS PC Shell, look at the`v15*xxxXX*.lst` file (eg. `less v15xxxXX.lst`)
and find first observation, note line number 'nnn' after scan name at start of line.

In FS, start schedule:

```fs
schedule=v15*xxxXX,#nnn
```

Send "Start" message
--------------------

Details are to be determined, but the message should be sent after the
first scan and include the scan name and source of the first scan.


Monitor experiment
==================


Monitor `scan_check`
--------------------

To display `scan_check` results as they come in (and the old ones so
far) open a new window (`Control><Shift>W`) then

```bash
scan_check
```

(which does ``tail -f -n +1 /usr2/log/`lognm`.log| grep scan_check``)

Results should show vdif, reasonable record start time, about equal
seconds and GBs of data (typically 30+), and 8 Gbps data rate. The
scan\_checks *occasionally* fail.

Position and size window for convenient viewing, new output will follow
any changed size. You can stop this with `<Control>C`

Check RDBE Monitor
------------------

Check the display for reasonable values:

1.  DOT ticking and correct time

2.  DOT2GPS value small (a few µseconds) and stable (varies by 0.1
    µseconds or less)

3.  RMS value close to 32

4.  Tsys IF0 and IF1 about 50-100, but may lower at Wf due to
    preliminary cal value, may be jumping a bit

5.  Phase-cal amplitude about 10-100, phase stable to within a few
    degrees

Post experiment
===============

Stop the schedule:
------------------

```fs
schedule=
```

Stop multicast logging
----------------------

From a FS PC shell prompt, connect to mark5-19 (Wf) or monkey (Gs):

```bash
ssh oper@mark5-19  
```
or 
```bash
ssh oper@monkey
```
then
```bash
stop_multicast_logging
exit
```

Send "End" message
------------------

Details are to be determined, but the message should include at least
the last the scan name for the last scan recorded and reports of any
issues that occurred.

Send test scan data files
-------------------------

NEEDS FEEDBACK. Which method should be used and what corrections are
needed? Where can more wildcards and other shortcuts be used to reduce
typing?

Original (does `gator` need a `o` argument? Does it need the quotes)

```bash
ssh oper@mark6a
gator <scan name>.vdif # this takes several minutes
dqa -d <scan name>.vdif # this takes several minutes
scp <scan name>_0.vdif oper@evlbi1.haystack.mit.edu:/data-st12/vgos/
scp <scan name>_1.vdif oper@evlbi1.haystack.mit.edu:/data-st12/vgos/
scp <scan name>_2.vdif
oper@evlbi1.haystack.mit.edu:/data-st12/vgos/
scp <scan name>_3.vdif
oper@evlbi1.haystack.mit.edu:/data-st12/vgos/
```

(example `<scan name>`: `104-1535`)


Suggested alternate instructions:

```bash
ssh oper@mark6a
gather /mnt/disks/1/\/data/<file name>.vdif -o <file name>.vdif
dqa -d <file name>
scp <file name>\_0.vdif oper@evlbi1.haystack.mit.edu:/data-st12/vgos/
```

(example `<file name>`: `v15132_gs_132-1432`)

If the directory is full, the `dqa` command will fail. The user has to
log into the mark6 and remove old `.vdif` files that have been gathered
and sent already. The transfers will take roughly 20 min per 10 seconds
of data.

Remove the module for shipping:
-------------------------------

```fs
mk6=group=close:<slots>;
mk6=group=unmount:<slots>;
```
to check the modules are unmounted
```
mk6=mstat?all; 
```

Transfer log file
-----------------

In FS, close experiment log:

```fs
log=station
```

In FS Shell prompt

```bash
cd /usr2/log
ftp cddisin.gsfc.nasa.gov
user Supply your user cddisin user name
password Supply your user cddisin password
put v15xxxXX.log
quit
```


Transfer multi-cast log:
------------------------


Details to be added.
