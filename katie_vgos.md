GGAO VGOS Operation Notes

Sept 2016

1.  ***Set-up of RDBE from a cold start (if needed):***

    A.  Start RDBE server, from FS PC shell prompt:

> **ssh root@rdbeX** X=a, b, c, or d (logs into RDBE-X)

On RDBE:

**rbin**

**nohup ./rdbe\_server 5000 6 &**

**exit**

> Repeat this for each RDBE restarted. You can verify when all RDBEs
> have restarted from the FS with:

**rdbe\_status**

> There will be an error for each RDBE that is not ready. When all RDBEs
> respond with a status value (0x0e01), proceed to step B.

A.  From the FS, load the firmware for RDBE-X:

> **rdbe\_fpgaX** X=a, b, c, or d

To load all RDBEs, use:

**rdbe\_fpga**

> There will be an error for each RDBE since it will not respond right
> away and will time-out You verify when this is finished from the FS
> with:

**rdbe\_status**

> as above. This time you are looking for the third digit from the right
> in the status message to be a ‘1’: 0x0f01.
>
> When all status values reach the correct value, proceed to step C. The
> LED screen on the RDBEs should display the date and time.

A.  From the FS, initialize the configuration for RDBE-X:

> **rdbe\_initX** X=a, b, c, or d

You should get a “success” message. To load all RDBEs, use:

**rdbe\_init**

You should get 4 “success” messages. Check the status using:

> **rdbe\_status **

The values should be 0x0f41 for all 4 RDBEs.

A.  It is necessary to sync and set the time with FMSET for an RDBE
    every time it is restarted. RDBEs need to be restarted as a group as
    soon as feasible after December 31^st^ and June 30^th^, before the
    first experiment after those dates at the latest). To do this from
    the FS console, press **&lt;Control&gt;&lt;Shift&gt;T** to
    start FMSET. You can select the RDBE to set by letter: **a**, **b**,
    **c**, or **d**. With that RDBE’s time being displayed, type **s**
    to sync it (and **y** to confirm), then type **.** (dot) to set the
    time to FS time. If the resulting displayed time is off by up to a
    few seconds, use **+** and/or **–** to increment and/or decrement
    the RDBE by a second at a time until it agrees with the FS time. Be
    sure to exit with **&lt;Esc&gt;**. Note if an experiment spans the
    end of a December 31 or a June 30 and any RDBE gets its time reset
    after that but before the end of the experiment, all the RDBEs must
    have their times reset before recordings will work again.

**After setting the time for each RDBE that needs it, repeat step C
above for each RDBE that was set.**

1.  ***Set-up of Mark 6 from a cold start (if needed):***

    A.  Start cplane and dplane (if necessary):

> **ssh root@mark6a** Login to Mark6
>
> (t35T%mk64605)

Check if cplane and dplane are running:

**ps aux | grep plane**

Dplane must be started before cplane. To start them if they are not
running:

**/etc/init.d/dplane start**

**/etc/init.d/cplane start**

Starting dplane and cplane can also be done from oper@mark6a:

**sudo /etc/init.d/dplane start**

**sudo /etc/init.d/cplane start**

1.  ***Set-up MCI server (if needed):***

> You can test whether this is needed by using the FS SNAP procedure:
>
> **dewar**

If it is working, you will see the readouts for the 20K and 70K stages.
If not, or if more MCI parameters are desired, use the following from a
shell window:

**ssh 192.168.1.51 **

PW: FS..

**./tcpip\_client 192.168.1.51 10000** a prompt should come up

**mci\_data?**

1.  ***DRUDG experiment files:***

    A.  Put schedule in /usr2/sched on FS PC

        To download from cddis from FS oper:

        **ftp cddis.gsfc.nasa.gov**

        user: **anonymous**

        password: **\[your email\]** insert your email address

        **cd vlbi/ivs/data/aux/2016/\[schedule name\]**

        **get &lt;schedule name&gt;**

        **quit**

    B.  Run DRUDG, from FS PC shell prompt

> **cd /usr2/sched**
>
> **drudg &lt;schedule name&gt;.skd**
>
> **XX** select your station code XX (gs=GGAO)
>
> **3** make .snp
>
> **12** make .prc
>
> **9** change printer output destination
>
> **&lt;schedule name&gt;XX.lst** destination file, XX=station code
>
> three more **&lt;Return&gt;**s
>
> **5** print summary
>
> **0** exit DRUDG

1.  ***Experiment set-up***

    A.  In the FS, open the experiment log so the set-up will be
        recorded in that log:

        **log=&lt;schedule name&gt;XX.log** XX=station code

    B.  If this is the first experiment since December 31 or June 30,
        and the RDBEs have not had their times set since that epoch,
        reset the time of each RDBE according to step 1D above. This
        must be done even if the time appears to be correct in step
        C below.

    C.  In the FS, check RDBE time and offsets:

        **time**

> The offsets should be small (&lt;0.01s) and the DOT times should be
> the same as the FS log timestamps. If not, run FMSET
> (**&lt;Control&gt;&lt;Shift&gt;T**) and verify and set times (don’t
> **s** for sync unless that RDBE had a PPS offset larger than +/-
> 2e-08, **if you do sync, you must re-initialize that RDBE afterwards,
> as is step 1C above**) by cycling through RDBEs (type band letter:
> **a**, **b**, **c**, or **d**), and be sure to exit
> (**&lt;Escape&gt;**).

A.  In the FS, initialize pointing setup and send antenna to the test
    source:

> **proc=point**
>
> **initp**
>
> **casa**

A.  In the FS, set-up experiment mode and adjust attenuators

> **proc=&lt;schedule name&gt;XX** XX=station code
>
> **setupbb**
>
> **ifdbb**
>
> **mk6bb**
>
> **auto** sets attenuators three times
>
> **raw**

A.  Run RDBE Monitor program if not displayed
    (&lt;Control&gt;&lt;Shift&gt;6), check for each RDBE that:

<!-- -->

1.  DOT ticking and correct time

2.  DOT2GPS value small (a few µseconds) and stable (varies by 0.1
    µseconds or less)

3.  RMS value close to 32

4.  Tsys IF0 and IF1 about 50-100, may be jumping a bit

5.  Phase-cal amplitude about 10-100, phase stable to within a few
    degrees

    A.  In the FS, check pointing and SEFDs on test source when you have
        reached the source:

        **onsource** result should be TRACKING

        **fivept** verify xoffset offset values are small

        **onoff** verify SEFDs for eight bands are reasonable,
        \~2000-3000

        **azeloff=0d,0d** zero offsets

    B.  Make a test recording:

<!-- -->

a.  This is to help with debugging, display and clear the Mark 6 message
    queue:

    **mk6=msg?;**

> If an unexplained error happens during the following procedure, please
> use this command again to get more information.

a.  Initialize the module; create, mount, and open module

    Check status:

    **mk6=mstat?all;**

After the two fields: return code and cplane status (hopefully
*mstat?0:0*) there are 10 fields per group:

*group : slot : eMSN : \# disks found : \# disks nominal: free space :
total space : status1 : status2 : type *

It may be easier to read if individual groups are queried, for group 1:

**mk6=mstat?1;**

Sometimes, especially after switching a disk format from RAID to SG, the
mstat query will need to be refreshed:

**disk\_info?serial:&lt;slot&gt;**

If the module has already been initialized (status1 is “initialized”),
and the data is no longer needed, erase it:

**mk6=group=unprotect:&lt;group&gt;;**

**mk6=group=erase:&lt;group&gt;; **

If the module has not been initialized (status1 is “unknown” and no eMSN
number), initialize it:

**mk6=mod\_init=&lt;slot\#&gt;:&lt;\#disks&gt;:&lt;MSN&gt;:&lt;type&gt;:&lt;new&gt;;**

(example: mk6=mod\_init=1:8:HAY%0001:sg:new;)

Create, open and mount the group:

**mk6=group=new:&lt;slots&gt;;**

**mk6=group=mount:&lt;slots&gt;;**

**mk6=group=open:&lt;slots&gt;;**

To query if the group is created properly:

**mk6=group?;**

Print out should have the group number at the end. If it is a “-“
something has gone wrong.

a.  In the FS, record some test data:

> **mk6=record=on:30:30;**

Verify that lights flas appropriately. Check recording status with:

**mk6=record?;**

It should progress starting as “*recording*” then transition to “*off*”

If the status says “*pending*”, it is usually either an RDBE problem or
the Mark6 is not seeing the data streams. You can check this by using
the FS SNAP procedure **mk6in**, which will show the Gb/s by interface.
If one or more interfaces are not showing the approximate nominal data
rate (initially 2Gb/s per interface), it is likely that the
corresponding RDBEs need to be reconfigured. Sample, correct 2Gb/s FS
log output:

2015.211.18:34:44.63\#popen\#mk6in/eth2 2.078 eth3 2.079 eth4 2.079 eth5
2.079 Gb/s

Another way is to log into the Mark6 oper account and check the packets
each eth is sending:

**/sbin/ifconfig –a** will check all interfaces

**/sbin/ifconfig ethX** will check a specific interface, x=0, 1, 2, or 3

To check if the disk is full is through **rtime** in the Mark6 oper
account.

a.  Once the recording ends, check quality:

> **mk6=scan\_check?;**
>
> Results should show *vdif*, time of “record=on”, 30 seconds of data,
> 30GB of data and 8 Gbps data rate.

1.  ***Start experiment***

    A.  Check multicast logging for all 4 bands in FS shell prompt:

        **monX** X=a, b, c, or d

    B.  Start non-FS multicast logging

        From a FS shell prompt, connect to monkey

        **ssh oper@monkey**

        Start logging:

        **start\_multicast\_logging**

        **exit**

    C.  Send “Ready” message

> From FS shell prompt, connect to monkey
>
> **ssh –Y oper@monkey**
>
> **cd bin**
>
> **python vgos-msg-gui.py**
>
> At this point a GUI window should pop up. Enter the session name,
> station code (lower case) and select the type of message from the drop
> down list.
>
> -Click the update values button. This collects the information in real
> time and the SEFDs from the pointing check in the log file.
>
> -Complete the maser offset value by looking at the maser counter in
> the maser room.
>
> -In the “to” email address field, send it to
> **ivs-vgos-ops@ivscc.gsfc.nasa.gov**
>
> -Enter a brief comment, include weather information.
>
> -Click the send message button when finished.

A.  Start schedule

> In FS shell (**/usr2/sched**), look at the .lst file created during
> DRUDG to find the line the observation will start on and note the line
> number.
>
> In FS, start the schedule:

**schedule=&lt;schedule name&gt;XX,\#nnn** XX=station code, nnn=line
number

A.  Send “Start” message using step 6C.

<!-- -->

1.  ***Monitor experiment***

    A.  To display *scan\_check* results as they come in (and old ones
        from the log) open an new window
        (**&lt;Control&gt;&lt;Shift&gt;W**), then

> **scan\_check** or **ctrl+shift+K**
>
> (which does *tail –f –n +1 /usr2/log/’lognm’.log | grep scan\_check)*

Results should show *vdif*, reasonable record start time, about equal
seconds and GBs of data (typically 30+) and 8 Gbps data rate. The
scan\_checks can occasionally fail.

A.  Check the RDBE Monitor display for reasonable values:

<!-- -->

1.  DOT ticking and correct time

2.  DOT2GPS value small (a few usec) and stable (varies by 0.1usec
    or less)

3.  RMS value close to 32

4.  Tsys IF0 and IF1 about 50-100

5.  Phase-cal amplitude about 10-100, phase stable to within a few
    degrees

<!-- -->

1.  ***Post experiment***

    A.  Stop the schedule:

> **schedule=**

A.  Stop multicast logging (start at FS shell prompt)

    **ssh oper@monkey**

    **stop\_multicast\_logging**

    **exit**

B.  Take post experiment SEFDs on casa:

> **proc=point**
>
> **casa**
>
> **onsource** result should be TRACKING
>
> **fivept** verify xoffset offset values are small
>
> **onoff** verify SEFDs for eight bands are reasonable, \~2000-3000
>
> **azeloff=0d,0d** zero offsets

A.  Send “End” message using step 6C. Include details such as the stop
    time and the current weather conditions onsite.

B.  Send test scan data (start in FS shell)

    **ssh oper@mark6a**

    **gather /mnt/disks/X/\*/data/\[filename\].vdif –o
    \[filename\].vdif** X=slot \#

    **dqa –d \[filename\].vdif**

    **scp \[filename\]\_\*.vdif
    oper@evlbi1.haystack.mit.edu:/data-st12/vgos/** PW=FS…

C.  Remove the module for shipping

> **mk6=group=close:&lt;slots&gt;;**
>
> **mk6=group=unmount:&lt;slots&gt;;**
>
> **mk6=mstat?all;** to check the modules are unmounted

A.  Transfer the log file

    In the FS, close the experiment log:

    **log=station**

    In FS shell prompt:

    **cd /usr2/log**

    **ftp cddisin.gsfc.nasa.gov**

    ***user*** ggaovlbi

    ***password*** pTKq4423

    **put &lt;log name&gt;XX.log** XX=station code

    **quit**

    Scp the log to Haystack:

    **Scp &lt;log name&gt;XX.log
    oper@evlbi1.haystack.mit.edu:/data-st12/vgos/logs**

**\
**

***Schedule rotation:***

1\. Start DRUDG with original schedule

2\. Pick option 10 in DRUDG.

3\. Specify the full fine name for the output file, i.e., include the
.skd. I suggest you call it

hYYDDD.skd. The "h" is to avoid confusing it with \*real\* schedules.

4\. Pick the start time. YYYY MM DD HH MM SS

5\. Pick the duration-usually 24 hours

6\. End DRUDG

7\. Restart DRUDG with the new file to make the normal output

***Module conditioning:***

1.  Load modules and enter da-client

    **ssh oper@mark6a**

    **da-client**

2.  In da-client, initialize the modules with the same mod\_init command
    used for experiment set up:

> **mod\_init=&lt;slot\#&gt;:&lt;\#disks&gt;:&lt;MSN&gt;:&lt;type&gt;:&lt;new&gt;;**

1.  Create a new group with the modules you want to condition. If more
    than 1 module is being conditioned, group them together.

    a.  **group=new:WXYZ;** WXYZ=slot 1, 2, 3, or 4. Only enter slots
        with modules in them.

    b.  **group=mount:WXYZ;**

    c.  **group=open:WXYZ;**

2.  Check to the status. It should say “open:ready” for the modules
    included in the group.

> **mstat?all;**

1.  Leave da-client and navigate to bin.

> **&lt;Control&gt;+C**
>
> **cd /home/oper/bin**

1.  Run the hammer script. After, all 8 lights on each module should
    be lit.

> **nohup hammer.sh &**

1.  To break the group, do the mod\_init command on each module and
    reassign groups. If recording on all the modules simultaneously, no
    further action is needed before an observation besides a
    test recording.


