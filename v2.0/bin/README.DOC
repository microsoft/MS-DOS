                         MSDOS 2.0 RELEASE


The 2.0 Release of MSDOS includes five 5 1/4 double density single sided
diskettes or three 8 iinch CP/M 80 format diskettes.

The software/documentation on the five inch diskettes is arranged
as follows:

1.   DOS distribution diskette.  This diskette contains files which
     should be distriibuted to all users.  This allows the DOS distri-
     bution diskette to meet the requirements of users of high level
     language compilers as well as users running only applications.
     Many compilers marketed independently through the retail channel
     (including those of Microsoft) assume LINK comes with the DOS, as
     in the case of IBM.  How you choose to distrubute BASIC (contracted
     for separately) is up to you.

2.   Assembly Language Development System diskette.  This diskette
     contains files of interest to assembly language programmers.
     High level language programmers do not need these programs unless
     they are writing assembly language subroutines.  IBM chose to
     unbundle this package from the DOS distribution diskette (except
     for DEBUG), but you do not have to do so.

3.   PRINT and FORMAT diskette.  This diskette contains .ASM source
     files which are necessary to assemble the print spooler, which you
     may wish to customize for greater performance.  .OBJ files are also
     included for the FORMAT utility.

4.   Skeltal BIOS and documentation diskette.  This diskette contains
     the skeltal BIOS source code and the SYSINIT and SYSIMES object
     modules which must be linked with your BIOS module.  The proper
     sequence for linking is BIOS - SYSINIT - SYSIMES.
     A profiler utiliity is also included on the diskette, but this
     is not intended for end-users.  This is distributed for use by
     your development staff only and is not supported by Microsoft
     If you do decide to distribute it, it is at your own risk!


5.   Documentation.  Features of 2.0 are documented on this disk.

The user manual contains some significant errors.  Most of these are
due to last minute changes to achieve a greater degree of compatibility
with IBM's implementation of MS-DOS (PC DOS).  This includes the use
of "\" instead of "/" as the path separator, and "/" instead of "-"
as the switch character.  For transporting of batch files across
machines, Microsoft encourages the use of "\" and "/" respectively
in the U.S. market.  (See DOSPATCH.TXT for how you can overide this.
The user guide explains how the end-user can override this in CONFIG.SYS).
Both the printer echo keys and insert mode keys have now been made to
toggle.  The default prompt (this may also be changed by the user
with the PROMPT command) has been changed from "A:" to "A>".
We apologize for any inconveniences these changes may have caused
your technical publications staff.


Here is what you need to do to MSDOS 2.0 to create a shipable product:
(see "Making a Bootable Diskette" below)

1.  BIOS.  If you have developed a BIOS for the Beta Test 2.0 version
    You should link your BIOS module to SYSINIT.OBJ and SYSIMES.OBJ.
    You must modify your BIOS to accomodate the call back to the BIOS
    at the end of SYSINIT.  If you have no need for this call, simply
    find a far RET and label it RE_INIT and declare it public.
    An example of this can be found in the skeletal BIOS.  In addition
    please add support for the new fast console output routine as
    described in the device drivers document.  We strongly recommend
    that you adapt the standard boot sector format also described in
    device drivers.  Once again, please refer to the skeletal BIOS.
    If you have not yet implemented version 2.0 please read the device
    drivers document.  Microsoft strongly recommends that machines
    incorporating integrated display devices with memory mapped video
    RAM implement some sort of terminal emulations through the use of
    escape sequences.  The skeletal  BIOS includes a sample ANSI
    terminal driver.

2.  Please refer to DOSPATCH.TXT for possible changes you might wish
    to make.  We strongly recommend that you not patch the switch
    characters for the U.S. market.  Your one byte serial number
    will be issued upon signing the license agreement.  Please patch
    the DOS accordingly.  If you wish to serialize the DOS, this is
    described in DOSPATCH.TXT.  Please patch the editing template
    definitions.  Please note the addition of the Control-Z entry
    at the beginning of the table.   Also note that the insert switches
    have now both been made to toggle.

3.  Utilities.  FORMAT must be configured for each specific system.
    GENFOR is a generic example of a system independent format module,
    but it is not recommended that this be distributed to your customers.
    Link in the following order:  FORMAT, FORMES, (your format module).
    The print spooler is distributed as an executable file, which only
    prints during wait for keyboard input.  If you wish with your
    implementation to steal some compute time when printing as well,
    you will need to customize it and reassemble.  Please note that
    you can use a printer-ready or timer interrupt.  The former is more
    efficient, but ties the user to a specific device.  Sample code
    is conditionaled out for the IBM PC timer interrupt.

The following problems are known to exist:

1.  Macro assembler does not support the initialization of 10-byte
    floating point constants in 8087 emulation mode - the last two bytes
    are zero filled.

2.  LIB has not been provided.  The version which incorporates support
    for 2.0 path names will be completed in a couple of weeks.  The
    1.x version should work fine if you cannot wait.  Because the library
    manager acts as a counterpart to the linker, we recommend that it
    be distributed with the DOS distribution diskette as opposed to the
    assembly language development system.

3.  International (French, German, Japanese, and U.K.) versions will be
    available in several months.

4.  COMMAND.ASM is currently too large to assemble on a micro.  It is
    being broken down into separate modules so it can be asembled on
    a machine.  Source licensees should realize that the resultant
    binaries from the new version will not correspond exactly to the
    old version.

5.  If you have any further questions regarding the MSDOS 2.0 distribution
    please contact Don Immerwahr (OEM technical support (206) 828-8086).


    Sincerely yours,


    Chris Larson
    MS-DOS Product Marketing Manager
    (206) 828-8080



            BUILDING A BOOTABLE (MSDOS FORMAT) DISKETTE


1.  In implementing MSDOS on a new machine, it is highly recommended
    that an MSDOS machine be available for the development.
    Please note that utilities shipped with MSDOS 2.0 use MSDOS 2.0
    system calls and WILL NOT not run under MSDOS 1.25.

2.  Use your MSDOS development machine and EDLIN or a word processor
    package to write BOOT.ASM, your bootstrap loader BIOS.ASM and
    your Format module.

3.  Use MASM, the Microsoft Macro-86 Assembler, to assemble these
    modules.  LINK is then used to link together the .OBJ modules in
    the order specified.

4.  Link creates .EXE format files which are not memory image files
    and contain relocation information in their headers.  Since your
    BIOS and BOOT routines will not be loaded by the EXE loader in
    MSDOS, they must first be turned into memory image files by
    using the EXE2BIN utility.

5.  The easiest thing to do is to (using your development machine)
    FORMAT a single sided diskette without the system.  Use DEBUG
    to load and write your BOOT.COM bootstrap loader to the BOOT
    sector of that diskette.  You may decide to have your bootstrap
    load BIOS and let the BIOS load MSDOS or it may load both.  Note that
    the Bootstrap loader will have to know physically where to go on
    the disk to get the BIOS and the DOS.   COMMAND.COM is loaded
    by the SYSINIT module.

6.  Use the COPY command to copy your IO.SYS file (what the
    BIOS-SYSINIT-SYSIMES module is usually called) onto the disk
    followed by MSDOS.SYS and COMMAND.COM.   You may use DEBUG
    to change the directory attribute bytes to make these files hidden.

CAUTION:

At all times, the BIOS writer should be careful to preserve the state
of the DOS - including the flags.  You should be also be cautioned that
the MSDOS stack is not deep.  You should not count on more than one or
two pushes of the registers.
                                                                                   