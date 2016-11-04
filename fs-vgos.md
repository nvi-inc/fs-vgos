% VGOS Operations Notes
% KPGO
% October 2016

Setup Field System PC
=====================

> This section is not complete

> **EH:** Need FS start section: boot PC, auto-logged in (or manually) as
> "oper", verify NTP sync'd, then start FS (anything else?). For KPGO
> and GGAO, if antenna must be started, do it after NTP has sync'd on FS
> computer. (what about other devices dependent on NTP?)

-   Start FS computer (if needed)
-   Login as user `oper`

-   Check NTP: 

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

Setup of RDBE from a cold start
===============================

> **EH:** This section will change completely with the new server. It will
boot to a state where the configuration step has finished. There will
be a different status code to indicate success. It will just be
necessary to sync after boot.

Start RDBE server
-----------------

From FS PC shell prompt, login to each RDBE:

```tcsh
ssh root@rdbe<id>
```

> **EH:** All devices should be set-up so the operator can ssh into them
> without providing a password. That isn't part of the procedure, but
> maybe should be noted somewhere (other issues?).

> **DH:** There are notes in the appendix for this

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

> **Chris**: Example of rdbe_status output for Kokee is "0:0x0941". We found
that if this number is different than above system does not work
properly so we note it in our procedure.

There will be an error for each RDBE that is not ready. When all RDBEs
respond with a status value `0x0e01`, proceed to the next step.

Load Firmware
-------------

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
rdbe_init<id>
```

You should get a "success" message.

Sync RDBEs
----------

It is **necessary** to sync and set the time with `fmset` for an RDBE
**every time** it is restarted.

(And also as soon as feasible after a December 31 and a June 30, before
the first experiment after those dates at the latest.)

To do this from the FS console, press `<Control><Shift>T` to start
`fmset`, or type

```tcsh
fmset
```

in an FS PC shell.

You can select the RDBE to set by letter: `a`, `b`, `c`, or `d`.

With that RDBE's time being displayed, type `s` to sync it (and `y` to
confirm), then type `.` (dot) to set the time to FS time.

If the resulting displayed time is off by up to a few seconds, use `+`
and/or `-` to increment and/or decrement the RDBE by a second at time
until it agrees with the FS time.

Be sure to exit with `<Escape>`.

**After setting the time for each RDBE that needs it, repeat the
[Configure RDBEs] step above for each RDBE that was set.**

> If an experiment spans the end of a December 31 or a June 30 and any
> RDBE gets its time reset after that but before the end of the
> experiment, **all** the RDBEs must have their times reset before
> recordings will work again.

> **EH:** This will change with the new server/FS, which will display the
VDIF epoch and FMSET will let you set it per RDBE. In that case, if
one RDBE is rebooted after an epoch change (December 31 or June 30),
that RDBE can be moved back to the previous epoch.

Set-up of Mark 6 server from a cold start
=====================================

Check Mark 6 connection
-----------------------

From the Field System, check the Mark 6 connection

```fs
mk6=dts_id
```

You should receive a sensible response similar to

    !dts_id?0:Mark6-4605:1.0.24-1:1.2;

Starting Mark 6 servers
-----------------------

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

> **Chris**: After setting up Mk6 server we would normally setup up our
> disks modules at this point. We found that this is one of the more
> likely problem areas while setting up so we like to set it up early in
> the process to give time to resolve issues if needed.

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

    > **Note:** due to a current bug, the FS--Mark 6 connection will
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
    seperates eg `<slots>=12`)

    To query if the group is created properly:

    ```fs
    mk6=group?;
    ```

    Print out should have the group number at the end. If it is `-`,
    something has gone wrong.

Setup MCI server
================

>This is specific to GGAO.

You can test whether this is needed by using the FS SNAP procedure:

```fs
dewar
```

If it is working, you will see the readouts for the 20K and 70K stages.
If not, or if more MCI parameters are desired, use the following from a
shell window, login to the MCI computer and run the MCI client

```tcsh
ssh mci
./tcpip_client 192.168.1.51 10000
```

a prompt should come up. To display all the MCI data use the command

    mci_data?


If the server is not running, start it with

```tcsh
./startmciserver
```

> **Chris**: This section is completely different at KPGO currently so below
the GGAO site specific procedures are KPGO procedures highlighted.

> This is site specific to KPGO

Log into the Hub PC in new Xterm window of FS

> ssh oper@128.171.102.237 ps aux|grep mci (to see if mci server is
> running) startmciserver (to start the server if not running)

Log into the Backend PC in new Xterm window on FS

> ssh oper@128.171.102.224 mci\_client.py 128.171.102.237 5000 (opens
> mci client on backend pc) mci\_data? (displays all mci data points
> current state including dewar temperatures)

DRUDG experiment files
======================

> **Chris**: we manually receive and process schedules as described in the
appendix.

To create the station specific SNAP and procedure files from the session
schedule, fetch the schedule from IVS and drudg it with

> **EH:** need to provide 'fesh' script, it will greatly simplify this step. Thanks.

```tcsh
fesh -d <sched>
```

where `<sched>` is the schedule name, eg `v16033`.

If you have manually received the schedule, follow the instructions in
the [Manually processing schedules] section of the appendix.

Experiment set-up
=================

Start FS log file
-----------------

In the FS, open the experiment log so the set-up will recorded in that
log:

```fs
log=<schedule><stn id> # eg v16033gs
```

Check RDBE time and offsets
---------------------------

**Note:** if this is the first experiment since December 31 and June
30, and the RDBEs have not had their time set since that epoch, reset
the time each of RDBE according the [Sync RDBEs] step above. This must
be done even if the time appears to be correct in the step below.

In the FS, check RDBE time and offsets:

```fs
time
```

The offsets should be small and the DOT times should be the same and the
same as the FS log timestamps. If not, run `fmset` (`<Control><Shift>T`)
and verify and set times by cycling through RDBEs (type each band
letter: `a`, `b`, `c`, or `d`), and be sure to exit (`<Escape>`)

Don't use `s` for sync unless that RDBE had a PPS offset larger that
±2e-8. **If you do sync, you must re-initialize that RDBE afterwards,
following the [Configure RDBEs] step above.**

Initialize pointing
-------------------

In the FS, initialize pointing configuration and send antenna to a test
source:

```fs
proc=point
initp
casa
```

> verify Az and El for source are acceptable antenna=operate

> **Chris**: We normally do not have the antenna in operate mode until good
Az and El positions are verified for the selected source

The following sources are most reliable for these small antennas are:

      Source Approximate L.S.T. of transit
  ---------- -------------------------------
    Taurus A 05:30
     Virgo A 12:30
    Cygnus A 20:00
       Cas A 23:30

Local apparent sidereal time (L.A.S.T) is displayed in the antenna
monitor window (monan) at GGAO and KPGO. Cas A is always up at GGAO and
Westford but another source may be more appropriate at times.

Set mode and attenuators
------------------------

While waiting for the antenna to move to the test source, setup the
experiment mode and adjust attenuators. In the FS,

```fs
proc=<schedule><stn id> # eg. 'v16033gs'
setupbb
ifdbb
mk6bb
auto                    # sets all attenuators three times
```

> **EH:** with the new server/FS, the comment no longer applies, the command
> is still "auto", but it only sets it once.

Check the attenuation with

```fs
raw
```

The levels should all be ~32, and should not be higher than 40 or less than around 10.

Check RDBEs
-----------

Locate the RDBE Monitor window or start it by pressing
`<Control><Shift>6` or typing `monit6` in a shell. Noting that the
display switches between IF0 and IF1 every second, check for each RDBE
that:

1.  DOT ticking and correct time

2.  DOT2GPS value small (a few µs) and stable (varies by 0.1 µs or less)

3.  RMS value close to 32

4.  Tsys IF0 and IF1 about 50-100, may be jumping a bit

5.  Phase-cal amplitude about 10-100, phase stable to within a few
    degrees

Leave the window open for later monitoring.

Check multicast for all 4 bands in FS shell prompt:

```tcsh
mon<id>
```

where `<id>=a, b, c, or d` (eg. `mona` etc.)


> **Chris**: we would typically do this before pointing and test scan.

    rdbe=data_connect? (verifies that band a,b,c,and d equal 0,1,2,and 3)

Check pointing
--------------

Check is the antenna is now on the source we selected earlier with the
FS command

```fs
onsource            
```

The result should be `TRACKING`. If the antenna status is still
`SLEWING` wait until you seen an on source message in the FS window.

Once the antenna is on source, start the pointing check with

```fs
fivept              
```

This will take a few minutes. Once complete `fivpt` will
give you output in the form:

              Az        El        xEl_offs  El_offs
    xoffset   99.4469   30.8190   0.01417  -0.00806  0.00452  0.00801 1 1 01d0 virgoa

The `xEl_offs` and `El_off` values (ie. the 3rd and 4th columns) are the
offsets in sky coordinates of the pointing fit. The absolute value of
these should be less that ~0.02 degrees in each coordinate. There
should also be the flags `1 1` in the 3rd and 4th columns from the end.

Next, measure the SEFDs on test source

```fs
onoff
```

This will also take a few minutes. Once complete `onoff` will
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

Verify SEFDs for eight bands are reasonable. 
They should be in the range ~2000-3000.

Finally, zero the offsets

```fs
azeloff=0d,0d
```

Make test recording
-------------------

> **Chris**: we normally would do the below two commands at this point to
check the Mk6 inputs before doing test scan.

    mk6in             (checks data rates on Ethernet ports) 
    mk6=input_stream? (shows in more detail the Ethernet ports state for the Mk6)

> **Chris**: At this point we normally have our disk modules setup and would
move to step #3.

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

    > **Note:** due to a current bug, the FS--Mark 6 connection will
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
    seperates eg `<slots>=12`)

    To query if the group is created properly:

    ```fs
    mk6=group?;
    ```

    Print out should have the group number at the end. If it is `-`,
    something has gone wrong.

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

    which will show the Gb/s by interface in the FS log. For example, a
    rate of 2 Gb/s should should look like

        #popen#mk6in/eth2 2.078 eth3 2.079 eth4 2.079 eth5 2.079 Gb/s

    If one or more interfaces are not showing the approximate nominal
    data rate (initially 2 Gb/s per interface), it is likely that the
    corresponding RDBEs needs to be reconfigured.

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

> **EH:** This is not really to check mult-cast logging, but the data being
> sent in multicast messages. MONIT6 demonstrates that multicast is
> working. Maybe we can get rid of use the "monitor" program. To
> be discussed with Chet. Comments on this (as well as everything else) from
> sites would be helpful.

Start non-FS multi-cast logging
-------------------------------

> **EH:** With Influx logging of data, maybe we can get rid of this logging,
> once InfluxDB is installed.

From a FS PC shell prompt, connect to the backend PC

```tcsh
ssh backend-pc
```

Start logging and exit:

```tcsh
start_multicast_logging
exit
```

Send "Ready" message
--------------------

From FS shell prompt, connect to monkey

```tcsh
ssh -X backend-pc
cd bin
python vgos-msg-gui.py
```

> **EH:** Different hosts at different sites of course, but
> at KPGO I fixed this so `.fvwm2rc` short-cut Control-Shift-G starts it,
> all the sites should get that. Jason will eventually move
> `vgos-msg-gui.py` to the FS machines so we can have better
> functionality. Maybe the placement of the window should be controlled
> locally by `.Xresources`.

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

(**Note:** the pound sign (`#`) is required and there should be no space
in the command)

> **DH:** can you just do `schedule=<session><stn id>`? (does it find the
> next scan after 5 min?)

> **EH:** Well yes, if are more than five minutes from the start of
> schedule, but sometimes we start in the middle. Is it better to have
> one description that works for all situations or two different ones,
> what do you think? Your choice.

Send "Start" message
--------------------

Send "Start" message using the same procedure as in [Send "Ready" message].

Monitor experiment
==================

Monitor `scan_check`
--------------------

To display `scan_check` results as they come in (and the old ones so
far) open a new window (`Control><Shift>W`) then

```tcsh
scan_check
```

(which does `` tail -f -n +1 /usr2/log/`lognm`.log| grep scan_check ``)

Results should show vdif, reasonable record start time, about equal
seconds and GBs of data (typically 30+), and 8 Gbps data rate. Be aware
`scan_checks` *occasionally* fails.

Position and size window for convenient viewing, new output will follow
any changed size. You can stop this with `<Control>-C`

> **EH:** I set up KPGO so that .fvwm2rc short-cut Control-Shift-K opens a
> window with this output. The placement and size of the window is
> controlled by .Xresources. I think everyone should get this if they
> don't already have it.

Check RDBE Monitor
------------------

Check the display for reasonable values:

1.  DOT ticking and correct time

> **EH:** new server/FS: and VDIF epoches for all RDBEs agree

2.  DOT2GPS value small (a few µseconds) and stable (varies by 0.1
    µseconds or less)

3.  RMS value close to 32 (note that the display switches between IF0
    and IF1 every second).

> **EH:** new server/FS: RMS value close to 20

4.  Tsys IF0 and IF1 about 50-100, but may lower at Wf due to
    preliminary cal value, may be jumping a bit

5.  Phase-cal amplitude about 10-100, phase stable to within a few
    degrees (note the display switches between IF0 and IF1 every second)

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

From a FS PC shell prompt, connect to the backend-pc

```tcsh
ssh backend-pc
```

then

```tcsh
stop_multicast_logging
exit
```


Check pointing and SEFDs
------------------------

If the FS *not* been restarted since the initial check, then the only set-up you will need is command the source (e.q. casa):

```fs
proc=point
initp
```
>**Chris:**
>    antenna=off (to allow us to verify Az and El for source before antenna moves)

```
casa
```
>**Chris:** verify Az and El are acceptable
>    antenna=operate

If the FS has been restarted since the initial setup, you will need to reset
everything and send the antenna to an appropriate source (eg. casa)

```fs
proc=point
initp
casa
proc=<schedule><stn id> # eg. 'v16033gs'
setupbb
ifdbb
mk6bb
auto
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

and check the "xoffset" values are small. Then check the SEFDs

```fs
onoff
```

and verify SEFDs for eight bands are reasonable, ~2000-3000.

Finally, zero the offsets

```fs
azeloff=0d,0d
```

> **Chris**: we would normally stow the antenna at this point and go to
standby mode with drives off.

> source=stow antenna=off

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

> **DH:** I don't know enough about this. Maybe I need to ask Katie. Comments from other stations might
> be needed here.

```tcsh
ssh mark6a
gather /mnt/disks/<slot>/*/data/<filename>.vdif –o <filename>.vdif
dqa –d <filename>.vdif
scp <filename>_*.vdif evlbi1.haystack.mit.edu:/data-st12/vgos/
```

> **EH:**  Maybe put into a script, or something, to minimize typing? It is definitely too much typing

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

> Mk6=group=close:<slots>; Mk6=group=unmount:<slots>; turn keys off,
> remove module(s) Mk6=mstat?all; (to clear module info and check the
> modules are unmounted)

Insert Mark6 modules into the e-tranfer Mark6

From the da-client mount the modules and verify all disks are seen:

> da-client group=mount:<slots>; mstat?all (if you get "6:0:1"
> restart cplane) group=open:<slots> list?

From another xterm window gather the scan(s) to your RAID disk, and
de-thread if necessary:

For test scan that needs to be de-threaded:

> gator <slots> <scan name>.vdif /mnt/raid 
> dqa -d <scan name>.vdif
> (this will create 4files with thread ID on scan name)

For scans where you intend to transfer the entire experiment use
gather464:

> gator -t <slots> "scan name".vdif /mnt/raid

Start tsunami server specifying the scans of the session to transfer

> tsunamid <scan_name>\_\*.vdif

You will see the available scans to be pulled

At another xterm window (in "oper", not "root")

Ssh to Haystack storage nodes &gt;ssh evlbi1.haystack.mit.edu
&gt;password is oper password

> cd /data-st12/vgos

Run tsunami, setting the transfer rate, error free, and connecting back
to your machine

> tsunami set rate 100M set error 0 connect 146.88.148.18

Make sure needed files are there to be pulled

> dir

Pull files

> get \*

Once transfer is complete exit tsunami client to get prompt back

> exit ls <scan_name>\* (verify all scans were copied)

After last scan has copied logout

> logout ctrl C (to quit server)

From da-client unmount the disk and prepare for shipping

> group=unmount:<slots> turn keys off, remove modules mk6=mstat?all;
> (clears module info and checks the modules are unmounted)

Transfer log file
-----------------

> **Chris**: (We normally will have already completed this section prior to
e-tranfer of test scan, manually like described in the appendix)
> **Chris**: normally done before e-transfer of test scan.

In FS, close experiment log:

```fs
log=station
```

In a terminal, copy the log to CDDIS and Haystack with

> **EH:** need to provide 'plog' script, it will greatly simplify this step. Thanks.

> **DH:** `plog` and `fesh` are in `fs-9.12.8/misc`

```tcsh
plog <log file path> # eg /usr2/log/v16033gs.log
```

If you are transferring the most recent log you can use

```tcsh
plog -l
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

> **EH:** This is *not* a good idea for oper account on FS machine.

> **DH:** It requires a password to be entered once per login session (after `ssh-add`).
> It seems like a good balance between security and convenience if a site is more
> concerned. But probably not necessary for oper@pcfs.

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

Currently we are using FTP to transfer log files to CDDIS.
This is will change in the future. For now, add
the following line to the `~/.netrc` file:

    machine cddisin.gsfc.nasa.gov login <username> password <password>

replacing the appropriate fields with your username and password.


Manually uploading log files
----------------------------

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

> **EH:** or reselect schedule (option #8)

7.  Restart DRUDG with the new file to make the normal output

Module conditioning
-------------------

> **EH:** no experience myself, have you tested?

> **DH:** These are Katie's notes, I haven't tested them.
> it's almost worth

1.  Load modules and enter da-client

        ssh mark6a da-client

2.  In da-client, initialize the modules with the same `mod_init`
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
