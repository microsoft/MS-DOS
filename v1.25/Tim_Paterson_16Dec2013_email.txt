From: Tim Paterson 
To: Len Shustek 
Date: Mon, 16 Dec 2013 10:34:17 -0800
Subject: RE: Source code to MS-DOS 1.0


I have found and attached the source code for MS-DOS 1.25 as shipped by Seattle Computer Products.  Version 1.25 was the first general release to OEM customers other than IBM so was used by all the first clone manufacturers.
 
IBM's DOS 1.1 corresponds to MS-DOS 1.24.  There is one minor difference between 1.24 and 1.25, as noted in the revision history at the top of MSDOS.ASM.
 
Of the file attached, only STDDOS.ASM/MSDOS.ASM (DOS main code) and COMMAND.ASM (command processor) would have been used by an OEM other than Seattle Computer.  The other files:
 
IO.ASM - I/O system unique to SCP (equivalent to ibmbio.sys).
ASM.ASM & HEX2BIN.ASM - Old 8086 assembler developed by SCP (used to assemble older version of DOS).
TRANS.ASM - Z80 to 8086 assembly source code translator developed by SCP.
 
I also have a 6” stack of printouts of assembly listings for some of these and probably other related programs.
 
Tim Paterson
Paterson Technology
http://www.patersontech.com/
 
 
