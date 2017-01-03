% VGOS Operators Notes
% December 2016

Introduction
============

These notes cover basic procedures for running VGOS experiment operations with
the Field System (FS). They are described in a logical order for the tasks
that need to be completed. If another order of operations make more sense for
some locale that is fine of course.

A basic assumption is that all the equipment is already up and
running.  The procedures check this and refer to the appendix for
set-up instructions for a device if it isn't already running.  In
addition to these setup procedures, the appendix also contains
instructions for some other useful operations.

As written here, the procedures are mostly station independent. However, some
station dependencies are noted. These only cover GGAO and KPGO for now but
Westford can, and will, be added. Some of the station dependencies can be
removed by writing some additional scripts that hid the dependencies. This is
also a good idea because the scripts can reduce the complexity of the
operations.

> **EH:** The etransfer instructions need to be checked.

Pre-setup
=========

DRUDG experiment files
----------------------

This step is first for two reasons.  First, the schedule file is typically
available before the day of the experiment.  Secondly, the number of modules in
a recording group may eventually depend on the experiment.  When that is the
case, the number needed will conveyed through the listing that is made in this
step.

To create the station specific SNAP and procedure files from the session
schedule, fetch the schedule from IVS and drudg by entering, in a FS PC shell,
the command

```tcsh
fesh -d <sched>
```
where `<sched>` is the schedule name, eg `v16033`.
If you have manually received the schedule, follow the instructions in
the [Manually processing schedules] section of the appendix.

Along with the `.snp` and `.prc` files for the FS, this
will create the listings file `<sched><stn id>.lst` in `/usr2/sched`
which shows a human readable summary of the schedule. Here `<stn id>` is
the two letter station code, eg "gs" for GGAO. To view this
on the FS PC, open in a text viewer; eg, in a FS shell

```tcsh
less /usr2/sched/<sched><stn id>.lst
```

Review the information in this listings file to ensure you have sufficient
storage for the observation.

Experiment setup
================

Start FS log file
-----------------

In the FS, open the experiment log so the set-up will recorded in that
log:

```fs
log=<schedule><stn id> # eg v16033gs
```

Check RDBE Status
-----------------

From the Field System, check the RDBEs

```fs
rdbe_status
```

The response values should be `0x0f41`.

> Old Server:
> The response values should be `0x0941`.

If the response is to not correct for any RDBEs, refer to 
[Setup of RDBEs from a cold start] in the appendix.

Check Mark 6 Status
-------------------

From the Field System, check the Mark6s

```fs
mk6=dts_id
```

You should receive a sensible response similar to

    !dts_id?0:Mark6-4605:1.0.24-1:1.2;

If the response is to not correct for any Mark6s, refer to 
[Set-up of Mark 6 server from a cold start] in the appendix.

Check MCI Status
----------------

> This is specific to GGAO.
>
> You can test whether this is needed by using the FS SNAP procedure:
>
> 
>     dewar
> 

> This is specific to KPGO.
>
> 
>     cryo
> 

If it is working, you will see the readouts for the 20K and 70K stages.
If not, see the [Setup MCI server] section in the appendix.


Mount Mark 6 Modules
--------------------

This step is included just after initial verification that all the
devices are working, but before the more detailed pre-experiment
checks.  This allows any issues with getting the modules mounted
resolved as soon as possible.  However, these steps can be done as
part of the making the test recording if that is preferred.

1.  This is to help with debugging, display and clear the Mark 6 message
    queue:

    ```fs
    mk6=msg?
    ```

    If an unexplained error happens during the following procedure,
    please use this command again to get more information.

2.  Initialize module; create, mount, and open module

    Check status:

    ```fs
    mk6=mstat?all
    ```

    After the two fields: return code and `cplane` status (hopefully
    `mstat?0:0`) there are 10 fields per group:

        group:slot:eMSN:#disks found:#disks nominal:free space:total space:status1:status2:type

    It may be easier to read if individual groups are queried; eg. for
    group 1:

    ```fs
    mk6=mstat?1
    ```

    If the module has already been initialized, ie `status1` is
    `initialized`, and the data is no longer needed (**be certain**),
    erase it:

    ```fs
    mk6=group=unprotect:<group>
    mk6=group=erase:<group>
    ```

    If the module has not been initialized (`status1` is "unknown" and
    no `eMSN`?), initialize it:

    ```fs
    mk6=mod_init=<slot#>:<#disks>:<MSN>:<type>:<new>
    ```

    For example

    ```fs
    mk6=mod_init=1:8:HAY%0001:sg:new
    ```

    > **Note:** due to a current incompatibility, the FS--Mark 6 connection will
    > timeout during long running commands such as this.
    >
    > Until this is fixed, you may want to run this command directly on
    > the Mark 6 with
    >
    > ```tcsh
    > ssh root@mark6a
    > da_client
    > mod_init=<slot#>:<#disks>:<MSN>:<type>:<new>;
    > ```
    >
    > note the final semicolon is necesseary in `da_client` but is
    > automatically added by the FS.

    Create, open and mount the group:

    ```fs
    mk6=group=new:<slots>
    mk6=group=mount:<slots>
    mk6=group=open:<slots>
    ```

    (Slots is a list of slot numbers included in the group, without any
    seperators, eg `<slots>=12`)

    To query if the group is created properly:

    ```fs
    mk6=group?;
    ```

    Print out should have the group number at the end. If it is `-`,
    something has gone wrong.



Verify RDBE time, offsets, and VDIF epochs
------------------------------------------

In the FS, check RDBE time, offsets, and VDIF epochs:

```fs
time
```

This will display the `pps_offset`, `dot`, and `gps_offset`:

    2016.320.18:11:39.28/rdbed/!dbe_pps_offset?0:-1.953124995e-08;
    2016.320.18:11:39.28/rdbec/!dbe_pps_offset?0:-1.953124995e-08;
    2016.320.18:11:39.29/rdbea/!dbe_pps_offset?0:-1.953124995e-08;
    2016.320.18:11:39.29/rdbeb/!dbe_pps_offset?0:-1.953124995e-08;
    2016.320.18:11:39.29/rdbeb/!dbe_dot?0:2016-320-18-11-39.296s:-0.007s:33;
    2016.320.18:11:39.29/rdbea/!dbe_dot?0:2016-320-18-11-39.296s:-0.018s:33;
    2016.320.18:11:39.29/rdbed/!dbe_dot?0:2016-320-18-11-39.296s:-0.024s:33;
    2016.320.18:11:39.29/rdbec/!dbe_dot?0:2016-320-18-11-39.296s:0.000s:33;
    2016.320.18:11:39.29/rdbeb/!dbe_gps_offset?0:-3.758203125e-05;
    2016.320.18:11:39.29/rdbed/!dbe_gps_offset?0:-3.758203125e-05;
    2016.320.18:11:39.29/rdbea/!dbe_gps_offset?0:-3.758203125e-05;
    2016.320.18:11:39.29/rdbec/!dbe_gps_offset?0:-3.758203125e-05;

The offsets should be small (GPS typically ± a few tens of
microseconds, PPS less than ±100 nanoseconds) and the DOT times should
be the same the FS log timestamps, within a about 0.1 seconds.  The
third field of 'dot' output is the VDIF epoch. All RDBEs must have the
same value, (33 in this case).  The VDIF epochs of all RDBEs are also
shown in the RDBE status window.

> For old server, the VDIF epoch not displayed

**If any of the DOT times are not correct**, the ones that are wrong must
be set with 'fmset'. To do this from the FS console, press
`<Control><Shift>T` to start `fmset`, or type

```tcsh
fmset
```

in an FS PC shell.

You can select the RDBE to set by letter: `a`, `b`, `c`, or `d`.

With that RDBE's time being displayed, verify that the time is correct
by comparing it to the FS/Computer time. If it is off by a lot, use
"." to get it close --- within a few seconds. Once it is close, you can
use `+` and/or `-` to increment and/or decrement the RDBE by a second
at time until it agrees with the FS time.

**If the PPS offset is greater in magnitude than ±1e-7 (100
nanoseconds)** for an RDBE, it must be resync'd. You can try using the
's' command in 'fmset' for each RDBE that has too large an offset.
This command will take approximately 45 seconds to complete.  If as a
result, the PPS offset comes within the tolerance, please check that
all the RDBEs are sending data with

```fs
mk6in
```

If an interface is not showing receipt of data, reinitilize the
correspond RDBE with:

```fs
rdbe_init<id>
```

where `<id>=a, b, c, or d` for the interface that is not recieving
data, `eth2, eth3, eth4, or eth5` respectively.

If this does not solve the data transmission problem. or the 's' did
not make the offset small enough, restart the RDBE, see [Setup of
RDBEs from a cold start] in the appendix.

> For the old server, you will need to restart the RDBE, see 
> [Setup of RDBEs from a cold start] in the appendix.

**If the displayed VDIF epochs are not the same,** use the `';'` command for each
RDBE to set the epoch to the nominal one.

> For the old server, the only way to verify this is to note that the
> Mark 6 will not record a test scan when you make one (but there
> could be other causes besides this one).  If this happens and you can
> determine which RDBEs do not have the current nominal VDIF epoch set
> its time explicitly.  If you don't know which is wrong just set them
> all explicitly. Use the procedure described below for after June 30
> or December 31 to set the time(s).

**If this is the first experiment since December 31 and June 30,** and
the RDBEs have not had their epoches reset since that date, they
should be reset. Use the `';'` command in 'fmset' for each RDBE to set
it to the nominal VDIF epoch. The third field in the 'dot' output
above must be the same for all the RDBEs.  The VDIF epochs of all
RDBEs are also shown in the RDBE status window.

> For the old server, this requires setting the time explicitly for
> each RDBE with 'fmset' even if it looks correct.  Use at least one
> of '.', '+', '-', or '=' commands and it is necessary then
> verify/set the time for each RDBE. The third field of the 'dot'
> output above will be missing for the old server and the VDIF epoch
> will not be in the RDBE status window.

If any changes were necessary due to the above considerations, check
the values again with:

```fs
time
```

to verify they are correct.  If not, follow the above instructions
again and/or seek assistance.

Initialize pointing
-------------------

In the FS, initialize pointing configuration and send antenna to a test
source:

```fs
proc=point
initp
casa
```

> This is KPGO specific:
>
> verify Az and El for source are acceptable
>
>     antenna=operate
>
> If not, try a different source first.

The following sources are the most reliable for these small antennas:

      Source Approximate L.S.T. of transit
  ---------- -------------------------------
    Taurus A             05:30
     Virgo A             12:30
    Cygnus A             20:00
       Cas A             23:30

> This following information is site specific.
>
> Local apparent sidereal time (L.A.S.T) is displayed in the antenna
> monitor window (monan) at GGAO and KPGO.  Cas A is always up at GGAO and
> Westford, but another source may be more appropriate at times.

Set mode and attenuators
------------------------

While waiting for the antenna to move to the test source, setup the
experiment mode and adjust attenuators. In the FS,

```fs
proc=<schedule><stn id> # eg. 'v16033gs'
setupbb
ifdbb
mk6bb
auto                    # sets the attenuators
proc=point
```

Check RDBEs
-----------

Locate the RDBE Monitor window or start it by pressing
`<Control><Shift>6` or typing `monit6` in a shell.  Noting that the
display switches between IF0 and IF1 every second, check for each RDBE
that:

1.  DOT ticking and correct time

2.  All RDBEs have the same epoch

    > Not applicable to old server

3.  DOT2GPS value small (a few µs) and stable (varies by 0.1 µs or less)

4.  RMS values close to 20. They be higher if the antenna has reached the source since
    the "auto" command above.  They may be higher or lower if the
    elevation has changed significantly since the "auto" or there is
    variable RFI.

    > Close to 32 for the old server. 

5.  Tsys IF0 and IF1 about 50-100, may be jumping a bit

6.  Phase-cal amplitude about 10-100, phase stable to within a few
    degrees

Leave the window open for later monitoring.

> *EH:* Is this needed?
>
> Check multicast for all 4 bands in FS shell prompt:
> 
> ```tcsh
> mon<id>
> ```
>
> where `<id>=a, b, c, or d` (eg. `mona` etc.)

Check RDBE data connectons

    rdbe=data_connect?

and verify that band a,b,c,and d equal 0,1,2, and 3.

Check pointing
--------------

Check is the antenna is now on the source we selected earlier with the
FS command

```fs
onsource
```

The result should be `TRACKING`.  If the antenna status is still
`SLEWING` wait until you see an onsource message in the FS log window.

Once the antenna is onsource, start the pointing check with

```fs
fivept
```

This will take a few minutes. Once complete `fivpt` will
give you output in the form:

              Az        El        xEl_offs  El_offs
    xoffset   99.4469   30.8190   0.01417  -0.00806  0.00452  0.00801 1 1 01d0 virgoa

The `xEl_offs` and `El_off` values (ie. the 3rd and 4th columns) are the
offsets in sky coordinates of the pointing fit.  The absolute value of
these should be less that ~0.02 degrees in each coordinate.  There
should also be the flags `1 1` in the 3rd and 4th columns from the end.

Next, measure the SEFDs on test source

```fs
onoff
```

This will also take a few minutes.  Once complete `onoff` will
give you output in the form:

        source       Az   El  De   I P   Center   Comp   Tsys  SEFD  Tcal(j) Tcal(r)
    VAL virgoa     170.9 63.0 15a0 1 l   3016.40 0.9943 52.03 2895.6  55.657  1.67
    VAL virgoa     170.9 63.0 15a1 2 r   3016.40 1.0088 47.93 2549.8  53.201  1.60
    VAL virgoa     170.9 63.0 15b0 3 l   5256.40 0.9946 49.58 2742.3  55.306  1.66
    VAL virgoa     170.9 63.0 15b1 4 r   5256.40 1.0148 41.57 2549.6  61.331  1.84
    VAL virgoa     170.9 63.0 15c0 5 l   6376.40 0.9831 42.57 2294.2  53.891  1.62
    VAL virgoa     170.9 63.0 15c1 6 r   6376.40 0.9862 44.09 2248.1  50.992  1.53
    VAL virgoa     170.9 63.0 15d0 7 l  10216.40 1.0121 51.91 3009.5  57.979  1.74
    VAL virgoa     170.9 63.0 15d1 8 r  10216.40 0.9870 53.64 3084.2  57.496  1.72
        source       Az   El  De   I P   Center   Comp   Tsys  SEFD  Tcal(j) Tcal(r)

Verify SEFDs for eight bands are reasonable. They should be in the range ~2000-3000.

Finally, zero the offsets:

```fs
azeloff=0d,0d
```
(note there is no space between arguments)

Make test recording
-------------------

1. Check Mark 6 inputs with

    ```fs
    mk6in
    ```

    which will show the Gb/s by interface in the FS log. For example, a
    rate of 2 Gb/s should should look like

        #popen#mk6in/eth2 2.078 eth3 2.079 eth4 2.079 eth5 2.079 Gb/s

    If one or more interfaces are not showing the approximate nominal
    data rate (initially 2 Gb/s per interface), it is likely that the
    corresponding RDBEs needs to be reconfigured.

    To see more details of the Ethernet ports state for the Mk6, use 

    ```fs
    mk6=input_stream? 
    ```

    Sample output:

        mk6a/!input_stream?0:0:rdbeB:vdif:8224:42:66:eth3:127.0.0.1:12000:0:rdbeC:vdif:8224:42:66:eth4:127.0.0.1:12000:0:rdbeA:vdif:8224:42:66:eth2:127.0.0.1:12000:0:rdbeD:vdif:8224:42:66:eth5:127.0.0.1:12000:0;

    which shows rdbeA going to eth2, rdbeB going to eth3, rdbeC going to
    eth4, and rdbeD going to eth5.

2. The modules and groups should have been set-up already.  If not refer
   to [Mount Mark 6 Modules] above.

3.  In FS, record some test data:

    ```fs
    mk6=record=on:30:30;
    ```

    verify that lights on the mk6 flash appropriately. You can check
    recording status with:

    ```fs
    mk6=record?;
    ```

    It should progress starting as "recording", then transitioning
    to "off".

    **If the status stays "pending",** it may be that not all the RDBEs
    are sending data. You can check this by using the FS SNAP procedure

    ```fs
    mk6in
    ```

    as shown in step #1 above.

    which will show the Gb/s by interface in the FS log. For example, a
    rate of 2 Gb/s should should look like

        #popen#mk6in/eth2 2.078 eth3 2.079 eth4 2.079 eth5 2.079 Gb/s

    If all interfaces are receiving data at the correct rate, it may
    be that the VDIF epochs of all the RDBEs don't agree.  See [Verify
    RDBE time, offsets, and VDIF epochs] for detail on how to
    verify/set.

    You can also check if the disk is full with

    ```fs
    mk6=rtime?
    ```

4.  Once recording ends, check quality:

    ```fs
    mk6=scan_check?;
    ```

    Results should show vdif, the time when recording was started, 30
    seconds of data, 30 GB of data and 8 Gbps data rate.

    > **EH:** data rate will eventually go to 16 and 32 Gbps.

Start experiment
================

Start non-FS multi-cast logging
-------------------------------

> **EH:** Once we have InfluxDB logging of data, maybe we can get rid of this logging,

From a FS enter:

```fs
start_mlog
```

If there are no errors reported and the "Done" message is printed the
logging has been started.

Send "Ready" message
--------------------

From FS console window enter Control-Shift-G.

> **EH:** Jason will eventually move `vgos-msg-gui.py` to the FS
> machines so we can have better functionality. Maybe the placement of
> the window should be controlled locally by `.Xresources`.

At this point a GUI window should pop up. Enter the session name,
station code (lower case) and select the type of message from the drop
down list.

-   Click the update values button. This collects the information in
    real time and the SEFDs from the pointing check in the log file.

-   Complete the maser offset value by looking at the maser counter in
    the maser room.

-   In the "to" email address field, send it to
    `ivs-vgos-ops@ivscc.gsfc.nasa.gov`

-   Enter a brief comment, include weather information.

-   Click the send message button when finished.

Start schedule
--------------

In FS Linux shell (xterm), look at the list file
`<schedule><stn id>.lst` created in the DRUDG step (eg. `v16033gs.lst`). Find the
first observation and note line number 'nnn' after scan name at start
of line.

Now, in the FS, start schedule:

```fs
schedule=<session><stn id>,#<nnn>
```

(**Note:** the pound sign (`#`) is required and there should be no spaces
in the command)

Send "Start" message
--------------------

Send "Start" message using the same procedure as in [Send "Ready" message].

Monitor experiment
==================

Monitor `scan_check`
--------------------

To display `scan_check` results as they come in (and the old ones so
far) open the 'scnch' window (`Control><Shift>K`).

Results should show vdif, reasonable record start time, about equal
seconds and GBs of data (typically 30+), and 8 Gbps data rate.  Be
aware `scan_checks` *occasionally* fails and the data is okay.

Position and size window for convenient viewing, new output will follow
any changed size. You can stop this with `<Control>-C`

> **EH:** The placement and size of the window can be controlled by
> .Xresources.

Check RDBE Monitor
------------------

Check the display for reasonable values periodically:

1.  DOT ticking and correct time

2.  VDIF epoches for all RDBEs agree

> NA for old server 

3.  DOT2GPS value small (a few µseconds) and stable (varies by 0.1
    µseconds or less)

4.  While recording RMS values are close to 32 for old server and 20
    for the new server, sometime RFI can cause the value to be off, but
    it should always be between 10 and 40 (note that the display
    switches between IF0 and IF1 every second).

5.  Tsys IF0 and IF1 about 50-100 (may lower at Wf due to use of a
    preliminary cal value), may be jumping a bit

6.  Phase-cal amplitude about 10-100, phase stable to within a few
    degrees (note the display switches between IF0 and IF1 every
    second)

Post experiment
===============

Stop the schedule
-----------------

In the FS, run

```fs
schedule=
```

Stop multicast logging
----------------------

In the FS, run

```fs
stop_mlog
```


Check pointing and SEFDs
------------------------

Select procedure 'point' library

```fs
proc=point
```

If the FS has been restarted since the initial check, you will need to
re-initialize the pointing set-up

```fs
initp
```

> Site Specific for KPGO:
>
>    antenna=off  (to allow verification of Az and El for source before antenna moves)

Try Cas-A as a source:

```fs
casa
```

> Site Specific for KPGO:
>
> If necessary, try other sources from table in [Initialize pointing]
> until one with a good position is found, then:
>
>    antenna=operate  (restart antenna)

If you re-ran 'initp' above, you will need to restore the experiment set-up:

```fs
proc=<schedule><stn id> # eg. 'v16033gs'
setupbb
ifdbb
mk6bb
auto
proc=point
```

Wait until the antenna is on source. You can either watch the log or
check with

```fs
onsource
```

The result should be "tracking".

As in the [Check pointing] section in pre-experiment, run a pointing check

```fs
fivept
```

and check the "xoffset" offset values are small. Then check the SEFDs

```fs
onoff
```

and verify SEFDs for eight bands are reasonable, ~2000-3000.

Finally, zero the offsets

```fs
azeloff=0d,0d
```

> Site specific for KPGO:
>
> source=stow
> (wait until stow is reached)
> antenna=off

Send "End" message
------------------

Send "End" message using the same procedure as in [Send "Ready" message].
Include details such as the stop time and the current weather conditions
on-site.

Send test scan data files
-------------------------

> **Chris**: This section is completely different for KPGO, due to our
e-transfer Mk6 being a different unit than our operational Mk6. Also for
actually sending entire experiments not just test scans. Below the
original steps provided in this procedure are the KPGO site specific
steps highlighted.

In a terminal, log in to the Mark 6

> **EH:** this is the part I know the least about and I suspect it different
> for different stations, maybe using something besides "gather", have
> tried it at GGAO?

```tcsh
ssh mark6a
gather /mnt/disks/<slot>/*/data/<filename>.vdif –o <filename>.vdif
dqa –d <filename>.vdif
scp <filename>_*.vdif evlbi1.haystack.mit.edu:/data-st12/vgos/
```

> **EH:** Maybe put into a script, or something, to minimize typing?
> As it is, it is definitely too much typing

Remove the module for shipping
------------------------------

In the FS

```fs
mk6=group=close:<slots>
mk6=group=unmount:<slots>
```

Before removing, check the modules are unmounted with

> key off disk before doing `mk6=mstat?all`

```fs
mk6=mstat?all
```

> **Chris**: KPGO site specific send test scan and e-transfer procedure

Close and unmount disk module(s) and prepare for e-transferring a scan
or experiment.

    mk6=group=close:<slots>
    mk6=group=unmount:<slots>

turn keys off, remove module(s)

    mk6=mstat?all;

(to clear module info and check the modules are unmounted)

Insert Mark6 modules into the e-tranfer Mark6

From the da-client mount the modules and verify all disks are seen:

    da-client
    group=mount:<slots>;
    mstat?all;

(if you get "6:0:1" restart cplane)

    group=open:<slots> list?

From another xterm window gather the scan(s) to your RAID disk, and
de-thread if necessary:

For test scan that needs to be de-threaded:

    gator <slots> <scan name>.vdif /mnt/raid
    dqa -d <scan name>.vdif

(this will create 4 files with thread ID on scan name)

For scans where you intend to transfer the entire experiment use
gather464:

    gator -t <slots> "scan name".vdif /mnt/raid

Start tsunami server specifying the scans of the session to transfer

    tsunamid <scan_name>_*.vdif

You will see the available scans to be pulled

At another xterm window (in "oper", not "root")

Ssh to Haystack storage nodes:

    ssh evlbi1.haystack.mit.edu  (password is oper password)
    cd /data-st12/vgos

Run tsunami, setting the transfer rate, error free, and connecting back
to your machine

    tsunami set rate 100M set error 0 connect 146.88.148.18

Make sure needed files are there to be pulled

    dir

Pull files

    get *

Once transfer is complete exit tsunami client to get prompt back

    exit
    ls <scan_name>*  (verify all scans were copied)

After last scan has copied logout

    logout
    <Ctrl-C> (to quit server)

From da-client unmount the disk and prepare for shipping

    group=unmount:<slots>;

turn keys off, remove modules

    mk6=mstat?all;

(clears module info and checks the modules are unmounted)

Transfer log file
-----------------

> This may be done before transferring the test scan.

In FS, close experiment log:

```fs
log=station
```

In a terminal, copy the log to CDDIS and Haystack with `plog`.
If you are transferring the most recent log you can use

```tcsh
plog -l
```

Otherwise use

```tcsh
plot <session> # v16033
```

Or if the log file does not conform to the standard naming convention

```tcsh
plog <log file path> # eg /usr2/log/v16033gs.log
```

If this is not successful, see [Manually uploading log files] in the appendix

Appendix
========

Setting Up Password-less SSH
----------------------------

It is convenient to setup password-less login for local devices from the Field
System PC. You can do this with SSH using public-key cryptography. To generate
public/private key pair with SSH (if you don't already have one), run

    ssh-keygen

Accept the defaults and enter a blank password when prompted.

For each computer you want to enable password-less login, append your public
key to `.ssh/authorized_keys` on the remote host. On a recent versions of the
Field System OS (ie FSL9 based on Debian Wheezy) use the command

    ssh-copy-id $host

If this is not available use

    cat ~/.ssh/id_rsa.pub | ssh $host 'cat >> ~/.ssh/authorized_keys'

If you do not wish to have *completely* password-less login, an alternative
is to encrypt your ssh key with a password and use ssh-agent to unlock it
for your session. The upshot is you still have the convenience of
password-less login, you just have to enter your password **once**
after you login to the FS computer.

This is also more secure since the ssh key is encrypted on disk and if anyone
ever takes your key, they can not gain access to your systems.

This is a good idea for remote terminals, although is slightly more cumbersome for
local access.

To encrypt your private key, enter a password when you generate it. To
encrypt an old key, or change its password, use

    ssh-keygen -p -f ~/.ssh/id_rsa

The process for adding your public key to a login to a remote host is the same as above.

Now, when you want to use your ssh key, add it to your ssh-agent with

    ssh-add ~/.ssh/id_rsa

This will decrypt your private key and allow any ssh clients the current login
session to use it without a password.

Setting Up Password-less Log Transfers
--------------------------------------

> *EH:* replace with new CDDIS transfer set-up procedure

Currently we are using FTP to transfer log files to CDDIS.
This is will change in the future. For now, add
the following line to the `~/.netrc` file:

    machine cddisin.gsfc.nasa.gov login <username> password <password>

replacing the appropriate fields with your username and password.

Manually uploading log files
----------------------------

> *EH*: must be re-written for new CDDIS procedure

In a terminal, copy the log to CDDIS

```tcsh
cd /usr2/log
ftp cddisin.gsfc.nasa.gov
user <your cddisin username>
password <your cddisin password>
put <session><stn id>.log      # eg 'v16033gs'
quit
```

And to Haystack:

    scp <session><stn id>.log evlbi1.haystack.mit.edu:/data-st12/vgos/logs

Manually processing schedules
-----------------------------

1.  Put schedule in `/usr2/sched` on FS PC

2.  Run `drudg`, from FS PC shell:

    ```tcsh
    cd /usr2/sched
    drudg <schedule>.skd
    ```

    Now, in `drudg`, give the following commands (ignoring text after
    `#` and filling in the variables)

    ```
    <stn id>                 # the two-letter station id (eg. 'gs' at GGAO)
    3                        # make .snp
    12                       # make .prc
    9                        # change printer output destination
    <schedule><stn id>.lst   # destination file, eg 'v16033gs.lst'
                             # three more <Return>s
    5                        # print summary
    0                        # exit DRUDG
    ```

Schedule rotation
-----------------

1.  Start DRUDG with original schedule

2.  Pick option 10 in DRUDG.

3.  Specify the full fine name for the output file, i.e., include the
    `.skd`. I suggest you call it `hYYDDD.skd`. The "h" is to avoid
    confusing it with *real* schedules.

4.  Pick the start time. YYYY MM DD HH MM SS

5.  Pick the duration --- usually 24 hours

6.  End DRUDG

7.  Restart DRUDG with the new file to make the normal output (or skip
    step #6 reselect schedule, option #8)

Module conditioning
-------------------

1.  Load modules and enter da-client

        ssh mark6a da-client

2.  In `da-client`, initialize the modules with the same `mod_init`
    command used for experiment set up:

        mod_init=<slot#>:<#disks>:<MSN>:<type>:<new>;

3.  Create a new group with the modules you want to condition. If more
    than 1 module is being conditioned, group them together.

        group=new:WXYZ;
        group=mount:WXYZ;
        group=open:WXYZ;

    WXYZ=slot 1, 2, 3, or 4. Only enter slots with modules in them.

4.  Check to the status. It should say "open:ready" for the modules
    included in the group.

        mstat?all;

5.  Leave `da-client` and navigate to bin.

        <Control>+C
        cd /home/oper/bin

6.  Run the hammer script. After, all 8 lights on each module should
    be lit.

        nohup hammer.sh &

7.  To break the group, do the `mod_init` command on each module and
    reassign groups. If recording on all the modules simultaneously, no
    further action is needed before an observation besides a
    test recording.

Setup Field System PC from Cold start
-------------------------------------


-   Start FS computer
-   Login as user `oper`
-   Check NTP by running 

    ```tcsh
    ntpq -np
    ```

    The output is of the form

             remote           refid      st t when poll reach   delay   offset  jitter
        ==============================================================================
        *192.168.1.20    18.26.4.105      2 u  444 1024  377    0.208   -0.336   0.396
        +192.168.1.21    18.26.4.105      2 u  167 1024  377    0.215   -0.822   0.153


    The offsets should be small and there must be a server with an
    asterisk `*` in the first column. It may take a few minutes to get an `*`.

-   Other local devices that use NTP (antenna, RDBE, Mark6, etc) can now
    be started

-   Start the Field System in the login shell

```tcsh
fs
```

Setup of RDBEs from a cold start
--------------------------------

###Power up RDBEs
 
Use the power switch to start or cycle the power of each RDBE to be started.

> New server:
>
> Check the status of all RDBEs with the FS command
>
> ```fs
> rdbe_status
> ```
>
> When the RDBEs respond with a status value `0x0f41`, skip to [Check/Set RDBE times]

###Start RDBE server


From FS PC shell prompt, login to each RDBE:

```tcsh
ssh root@rdbe<id>
```

use `<id>=a`, `b`, `c`, or `d` to log into RDBE-`<id>`.

Then, on each RDBE run

```tcsh
rbin
nohup ./rdbe_server 5000 6 &
exit
```

Repeat this for each RDBE that has been restarted. You can verify when
all the RDBEs have started from the FS with:

```fs
rdbe_status
```

There will be an error for each RDBE that is not ready. When all RDBEs
respond with a status value `0x0941`, proceed to the next step.

###Load Firmware

To load the firmware on all RDBEs, use the FS command:

```fs
rdbe_fpga
```

If you want to load the firmware individually for RDBE-`<id>`, you can
use the FS command

```fs
rdbe_fpga<id>
```

Again, use `<id>=a`, `b`, `c`, or `d` as necessary.

There will be an error for each RDBE, since it will not respond right
away and will time-out. You verify when this is finished from the FS
with again using

```fs
rdbe_status
```
This time, the RDBEs should respond with status `0x0f01`

> **EH:** is 0x0f01 correct?

When all status values reach the correct value, proceed to next step

###Configure RDBEs

To initialize the configuration on all RDBEs, use the FS command:

```fs
rdbe_init
```

You should get four "success" messages.

If you need initialize an RDBE individually use, the FS command

```fs
rdbe_init<id>
```

You should get a "success" message.

###Check/Set RDBE times

It is **necessary** to check/set the time with `fmset` for an RDBE
**every time** it is restarted.  The time only needs to be set if it is
not correct already.

To do this from the FS console, press `<Control><Shift>T` to start
`fmset`, or type

```tcsh
fmset
```

in an FS PC shell.

You can select the RDBE to set by letter: `a`, `b`, `c`, or `d`.

With that RDBE's time being displayed, verify that the time is correct
at the one second level (± a few tenths) by comparing it to the
FS/Computer time.  If it is off by a lot, use "." to get it close,
within a few seconds.  Once it is close, you can use `+` and/or `-` to
increment and/or decrement the RDBE by a second at time until it
agrees with the FS time.

Be sure to exit with `<Escape>`.


Set-up of Mark 6 server from a cold start
-----------------------------------------

Use the power switch to start or cycle the power of each Mark 6 to be started.

###Check Mark 6 connection (New server)

From the Field System, check the Mark 6 connection

``` {.fs}
mk6=dts_id
```

You should receive a sensible response similar to

    !dts_id?0:Mark6-4605:1.0.24-1:1.2;

If so, you can skip the rest of this section.

###Starting Mark 6 servers

If you receive an error, check that the Mark 6 servers are running. The
programs `cplane` and `dplane` need to be running on the Mark 6. These
should startup after boot.

To check check if they are running perform

```tcsh
ssh root@mark6a
ps aux | grep plane
```

If they are not, start them

```tcsh
/etc/init.d/dplane start
/etc/init.d/cplane start
```

Setup MCI server
----------------

>This is specific to GGAO.
>
> GGAO should be set-up agree with KPGO FS approach below.

You can test whether this is needed by using the FS SNAP procedure:

```fs
dewar
```

If it is working, you will see the readouts for the 20K and 70K stages.
If not, or if more MCI parameters are desired, use the following from a
shell window, login to the MCI computer and run the MCI client

```tcsh
ssh mci
./tcpip_client mci 10000
```

a prompt should come up. To display all the MCI data use the command

    mci_data?

If the server is not running, start it with

```tcsh
./startmciserver
```

> This is site specific to KPGO

You can test whether this is needed by using the FS SNAP procedure:

This is specific to KPGO.

```fs
 cryo
```

If it is working, you will see the readouts for the vacuum, 20K, and
70K stages.  If not, start the server from the FS:

```fs
startmci
```

If 'cryo' still doesn't work, then use log into the Hub PC in new xterm window of FS

     ssh oper@hubpc
     ps aux|grep mci (to see if mci server is running)
     startmciserver (to start the server if not running)

To display more MCI date from the FS, enter:

```fs
mci_data
```

If that doesn't work, log into the Backend PC in new xterm window on FS

    ssh oper@backend-pc
    mci_client.py 128.171.102.237 5000 (opens mci client on backend pc)
    mci_data? (displays all mci data points current state including dewar temperatures)
