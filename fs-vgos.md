---
title: VGOS Operations Notes
date: September 2016
---

Setup of RDBE from a cold start
===============================

Start RDBE server
-----------------
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

If you want to load the firmware individually for RDBE-`<id>`,
you can use the FS command

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

You should a "success" message.


Sync RDBEs
----------
It is **necessary** to sync and set the time with `fmset` for an RDBE
**every time** it is restarted. 

(And also as soon as feasible after a
December 31 and a June 30, before the first experiment after those dates
at the latest.) 

To do this from the FS console,
press `<Control><Shift>T` to start `fmset`, or type

```tcsh
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

**After setting the time for each RDBE that needs it, repeat the
[Configure RDBEs] step above for each RDBE that was set.**

>*Dave: is this right? Is it possible to sync before configure?*

>If an experiment spans the end of a December 31 or a June 30 and any
RDBE gets its time reset after that but before the end of the experiment,
**all** the RDBEs must have their times reset before recordings will work
again.


Start Mark 6 servers
====================

>*Dave: is there an FS command to check if these are running?*

The programs `cplane` and `dplane` need
to be running on the Mark 6. These should startup after boot. 

If you have a problem check if they are running 
with
```tcsh
ssh root@mark6a
ps aux | grep plane
```

To start them if they are not running:

```tcsh
/etc/init.d/dplane start
/etc/init.d/cplane start
```

Note: dplane must be started before cplane.

Setup MCI server 
================

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
```
mci_data?
```

>*Dave: Is this the correct command?*

```tcsh
./startmciserver
```

And log out of the MCI server node

DRUDG experiment files
======================
To create the station specific schedule and procedure files from the master file:

1.  Put schedule in `/usr2/sched` on FS PC

    To download from cddis, in an FS terimal:
    ```tcsh
    cd /usr2/sched
    ftp cddis.gsfc.nasa.gov
    ```
    then, in the ftp prompt
    ```
    Name: anonymous
    password: <your email address>
    cd vlbi/ivs/data/aux/2016/<schedule> 
    get <schedule>
    quit
    ```
    >*Dave: Should this be `get <schedule>.skd?`*

    Here `<schedule>` should be something like "v16033".



2. Run `drudg`, from FS PC shell:
    ```tcsh
    cd /usr2/sched
    drudg <schedule>.skd
    ```
    Now, in `drudg`, give the following commands (ignoring text after `#` and filling
    in the variables)

    ```drudg
    <stn id>                 # the two-letter station id (eg. 'gs' at GGAO)
    3                        # make .snp
    12                       # make .prc
    9                        # change printer output destination
    <schedule><stn id>.lst   # destination file, eg 'v16033gs.lst'
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
log=<schedule><stn id> # eg v16033gs
```

Check RDBE time and offsets
---------------------------

>**Note:** if this is the first experiment since December 31 and June 30, and
the RDBEs have not had their time set since that epoch, reset the time each of
RDBE according the [Sync RDBEs] step above. This must be done even if the
time appears to be correct in the step below.

In the FS, check RDBE time and offsets:

```fs
time
```

The offsets should be small and the DOT times should be the same and the
same as the FS log timestamps. If not, run `fmset` (`<Control><Shift>T`) and verify and set times
by cycling through RDBEs (type each band letter: `a`, `b`, `c`, or `d`), and be sure to exit (`<Escape>`)

>Don't use `s` for sync unless that RDBE had a PPS offset larger that ±2e-8.
**If you do sync, you must re-initialize that RDBE afterwards,
following the [Configure RDBEs] step above.**


Initialize pointing
-------------------
In the FS, initialize pointing setup and send antenna to test source:

```fs
proc=point
initp
casa
```

>*Dave: which sources are good and when?*

Set mode and attenuators
------------------------

While waiting for the antenna to move to the test source,
setup the experiment mode and adjust attenuators. 
In the FS,

```fs
proc=<schedule><stn id> # eg. 'v16033gs'
setupbb
ifdbb
mk6bb
auto                    # sets all attenuators three times
```


Check the attenuation with 
```fs
raw
```
The levels should all be ~32.


Check RDBEs
-----------

Run RDBE Monitor program (`<Control><Shift>6` or `monit6` in a shell),
and check for each RDBE that:

1.  DOT ticking and correct time

2.  DOT2GPS value small (a few µseconds) and stable (varies by 0.1
    µseconds or less)

3.  RMS value close to 32

4.  Tsys IF0 and IF1 about 50-100, may be jumping a bit

5.  Phase-cal amplitude about 10-100, phase stable to within a few
    degrees (note the display switches between IF0 and IF1 every second)

Leave the window open for later monitoring but position out of the way
as necessary.

Check pointing
--------------
Check is the antenna is now on the source we selected earlier with
the FS command

```fs
onsource            
```

The result should be `TRACKING`.

Once the antenna is on source, start the pointing check with

```fs
fivept              
```

This will take a few minutes. One complete you will get an output like
```
#                      Az        El        Lon_offs  Lat_offs
<time>#fivpt#xoffset   99.4469   30.8190   0.01417  -0.00806  0.00452  0.00801 1 1 01d0 virgoa
```
The `Lon_offs` and `Lat_off` values (ie. the 3rd and 4th columns) are the offsets
in sky coordinates of the pointing fit. The absolute value of these should be
less that ~0.02 degrees in each coordinate.

Next, measure the SEFDs on test source
```fs
onoff               
```
Verify SEFDs for eight bands are reasonable. They should be in the range ~2000-3000.

Finally, zero the offsets
```fs
azeloff=0d,0d
```

Make test recording
-------------------

a.  This is to help with debugging, display and clear the Mark 6 message
    queue:
    ```fs
    mk6=msg?
    ```
    If an unexplained error happens during the following procedure, please
    use this command again to get more information.


b.  Initialize module; create, mount, and open module

    Check status:
    ```fs
    mk6=mstat?all
    ```
    After the two fields: return code and `cplane` status (hopefully `mstat?0:0`)
    there are 10 fields per group:

    ```
    group:slot:eMSN:#disks found:#disks nominal:free space:total space:status1:status2:type
    ```

    It may be easier to read if individual groups are queried; eg. for group 1:

    ```fs
    mk6=mstat?1
    ```

    If the module has already been initialized, ie `status1` is `initialized`,
    and the data is no longer needed (**be certain**), erase it:

    ```fs
    mk6=group=unprotect:<group>
    mk6=group=erase:<group>
    ```

    If the module has not been initialized (`status1` is "unknown" and no
    `eMSN`?), initialize it:

    ```fs
    mk6=mod_init=<slot#>:<#disks>:<MSN>:<type>:<new>
    ```

    For example
    ```fs
    mk6=mod_init=1:8:HAY%0001:sg:new
    ```

    > **Note:** due to a current bug, the FS--Mark 6 connection will timeout
    > during long running commands such as this.
    > 
    > Until this is fixed, you may want to run this command directly on the Mark 6 with
    > ```tcsh
    > ssh root@mark6a
    > da_client
    > mod_init=<slot#>:<#disks>:<MSN>:<type>:<new>;
    > ```
    > note the final semicolon is necesseary in `da_client` but is automatically added
    > by the FS.


    Create, open and mount the group:

    ```fs
    mk6=group=new:<slots>
    mk6=group=mount:<slots>
    mk6=group=open:<slots>
    ```

    (Slots is a list of slot numbers included in the group, without any seperates eg `<slots>=12`)

    To query if the group is created properly:

    ```fs
    mk6=group?;
    ```

    Print out should have the group number at the end. If it is `-`,
    something has gone wrong.

c.  In FS, record some test data:

    ```fs
    mk6=record=on:30:30;
    ```

    verify that lights on the mk6 flash appropriately. You can check recording status
    with:

    ```fs
    mk6=record?;
    ```

    It should progress starting as "recording", then transitioning to "off".

    **If the status stays "pending",** it may be that not all the RDBEs are
    sending data. You can check this by using the FS SNAP procedure
    ```fs
    mk6in
    ```
    which will show the Gb/s by interface in the FS log. For example,
    a rate of 2 Gb/s should should look like
    ```
    <time>#popen#mk6in/eth2 2.078 eth3 2.079 eth4 2.079 eth5 2.079 Gb/s
    ```
    If one or more interfaces are not showing the approximate nominal data rate (initially
    2 Gb/s per interface), it is likely that the corresponding RDBEs needs to
    be reconfigured. 


    If need-be, you can check this direcly on the Mark6 with
    by logging into the Mark 6
    ```tcsh 
    ssh oper@mark6
    ```
    Then, to check all interfaces, running
    ```
    /sbin/ifconfig –a     
    ```
    or, to check check a specific interface, 
    ```
    /sbin/ifconfig eth<X>
    ```
    where `<X>`=`0`, `1`, `2`, or `3`
    
    You can also check if the disk is full with

    ```tcsh
    ssh oper@mark6
    rtime
    ```

    >*Dave: can you check this in the FS? `disk_pos`?*


d. Once recording ends, check quality:

    ```fs
    mk6=scan_check?;
    ```

    Results should show vdif, the time when recording was started, 30 seconds of data, 30 GB
    of data and 8 Gbps data rate.

Start experiment
================
Check multicast logging for all 4 bands in FS shell prompt:
```tcsh
mon<id>  #<id>=a, b, c, or d
```

Start non-FS multi-cast logging
--------------------------------
From a FS PC shell prompt,
connect to mark5-19 (Wf)

```tcsh
ssh oper@wfmark5-19
```
or monkey (Gs):
```tcsh
ssh oper@monkey
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
ssh –Y oper@monkey
cd bin
python vgos-msg-gui.py
```

At this point a GUI window should pop up. Enter the session name,
station code (lower case) and select the type of message from the drop
down list.

-   Click the update values button. This collects the information in
    real time and the SEFDs from the pointing check in the log file.

-   Complete the maser offset value by looking at the maser counter in
    the maser room.

-   In the "to" email address field, send it 
    to `ivs-vgos-ops@ivscc.gsfc.nasa.gov`

-   Enter a brief comment, include weather information.

-   Click the send message button when finished.

Start schedule
--------------

In FS PC Shell, look at the list file `<schedule><stn id>.lst` created
in the DRUDG step (eg. `v16033gs.lst`). Find the first observation and note line
number 'nnn' after scan name at start of line.

Now, in the FS, start schedule:

```fs
schedule=<session><stn id>,#<nnn>
```

(**Note:** the pound sign (`#`) is required and there should be no space in the command)

>*Dave: can you just do `schedule=<session><stn id>`? (does it find the next scan after 5 min like AuScope?)*


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

Stop the schedule
-----------------

In the FS, run

```fs
schedule=
```

Stop multicast logging
----------------------

From a FS PC shell prompt, connect to mark5-19 (Wf) or monkey (Gs):

```.tcsh
ssh oper@mark5-19  
```

or

```tcsh
ssh oper@monkey
```

then

```tcsh
stop_multicast_logging
exit
```

Check pointing and SEFDs
------------------------


Load the pointing procedure file and send the
antenna to an appropriate source (eg. casa)

```fs
proc=point
casa
```

Wait until the antenna is on source. You can
either watch the log or check with 

```fs
onsource 
```

The result should be "tracking".

As in [Check pointing] in pre-experiment, run a pointing check
```fs
fivept
```
and check the "xoffset" values are small. Then check the SEFDs
```fs
onoff
```
and verify SEFDs for eight bands are reasonable, ~2000-3000.

Finally, zero offsets
```fs
azeloff=0d,0d
```

Send "End" message
------------------

Send "End" message using the same procedure as in [Send "Ready" message]. 
Include details such as the stop time and the current weather conditions on-site.

Send test scan data files
-------------------------

In a terminal, log in to the Mark 6

```tcsh
ssh oper@mark6a
gather /mnt/disks/<slot>/*/data/<filename>.vdif –o <filename>.vdif
dqa –d <filename>.vdif
scp <filename>_*.vdif oper@evlbi1.haystack.mit.edu:/data-st12/vgos/
```


Remove the module for shipping
-------------------------------

In the FS

```fs
mk6=group=close:<slots>
mk6=group=unmount:<slots>
```

Before removing, check the modules are unmounted with

```fs
mk6=mstat?all
```

Transfer log file
-----------------

In FS, close experiment log:

```fs
log=station
```

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

```
scp <session><stn id>.log oper@evlbi1.haystack.mit.edu:/data-st12/vgos/logs
```

Appendix
========

Schedule rotation
-----------------

1. Start DRUDG with original schedule

2. Pick option 10 in DRUDG.

3. Specify the full fine name for the output file, i.e., include the `.skd`.
I suggest you call it `hYYDDD.skd`. The "h" is to avoid confusing it with *real* schedules.

4. Pick the start time. YYYY MM DD HH MM SS

5. Pick the duration --- usually 24 hours

6. End DRUDG

7. Restart DRUDG with the new file to make the normal output

Module conditioning
-------------------

1.  Load modules and enter da-client

```
ssh oper@mark6a
da-client
```

2.  In da-client, initialize the modules with the same `mod_init` command
    used for experiment set up:

```
mod_init=<slot#>:<#disks>:<MSN>:<type>:<new>;
```

1.  Create a new group with the modules you want to condition. If more
    than 1 module is being conditioned, group them together.

    a.  `group=new:WXYZ;`
        WXYZ=slot 1, 2, 3, or 4. Only enter slots with modules in them.

    b.  `group=mount:WXYZ;`

    c.  `group=open:WXYZ;`

2.  Check to the status. It should say "open:ready" for the modules
    included in the group.

```
mstat?all;
```

3.  Leave da-client and navigate to bin.
    ```
    <Control>+C
    cd /home/oper/bin
    ```

4.  Run the hammer script. After, all 8 lights on each module should
    be lit.

    ```
    nohup hammer.sh &
    ```

5.  To break the group, do the `mod_init` command on each module and
    reassign groups. If recording on all the modules simultaneously, no
    further action is needed before an observation besides a
    test recording.



