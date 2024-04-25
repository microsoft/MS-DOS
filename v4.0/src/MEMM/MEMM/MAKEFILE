#******************************************************************************
#	title	MAKEFILE - MEMM build file
#******************************************************************************
#
#   (C) Copyright MICROSOFT Corp. 1986
#
#   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
#
#   Module:   MAKEFILE
#
#   Version:  0.06
#
#   Date:     May 12, 1986
#
#   Author:
#
#******************************************************************************
#
#   Change log:
#
#     DATE    REVISION			DESCRIPTION
#   --------  --------	-------------------------------------------------------
#	      Original
#   05/12/86  B-	Cleanup and segment reorganization
#   06/03/86  C-	Added module for driver i/f
#   06/08/86  C-	Merge in lastest code from MS
#   06/17/86  D-	Added debug version.
#   06/28/86  0.02	Name change from MEMM386 to MEMM
#   07/01/86  0.03	Added MapDMA module.
#   07/11/86  0.05	Moved HIFLAG into global includes.
#
#******************************************************************************
#
#   Functional Description:
#
#   This file assembles and links
#	(1) EMM386.EXE	  - Production version of EMM386 driver
#	(2) EMM386.COM	  - Production version of EMM386 utility
#	(3) EMM386D.EXE   - Debug (Internal) version of EMM386 driver
#
#******************************************************************************

#******************************************************************************
#	R U L E S   and   M A C R O S
#******************************************************************************
.SUFFIXES:
.SUFFIXES:	.c .asm .obj .lst .def .lnk .lrf .exe .com


#	Definition for turning OFF high memory allocation
#		HIFLAG = -DNOHIMEM => turns it off
#		HIFLAG =	   => turns on high memory allocation
HIFLAG        = -DNOHIMEM
#HIFLAG	=

#	Definitions for assembler
#ASM = c:\bin\masm400
#ASM	   = masm400
ASM		= masm
AFLAGS		= -Mx -t -DI386 -DNoBugMode $(HIFLAG)
ADFLAGS 	= -Mx -t -DI386 $(HIFLAG)
AINC		= -i..\emm

#	Defines for C Compiler
C	= cl
CFLAGS	=/AS /G2 /Oat /Gs /Ze /Zl /Fc /c

#	Definitions for linker for old style .exe files
#LINK = c:\bin\link
#LINK	   = link
LINK	= link
LFLAGS	= /NOI

#	Definitions for .COM generation
CONVERT = c:\dos\exe2bin
#CONVERT = exe2bin

#	Rules for generating object and linker response and definition files
.asm.obj:
	$(ASM) $(AFLAGS) $(AINC) -p $*.asm;

.asm.lst:
	$(ASM) -l -n $(AFLAGS) $(AINC) -p $*.asm;

#******************************************************************************
#	List of include files required
#******************************************************************************
MEMMINC = ascii_sm.equ driver.equ pic_def.equ romstruc.equ romxbios.equ \
		desc.inc elim.inc emm386.inc instr386.inc kbd.inc loadall.inc \
		oemdep.inc page.inc vdmseg.inc vdmsel.inc vm386.inc mach_id.inc


#******************************************************************************
#	List of object files required
#******************************************************************************

MEMMOBJ = memm386.obj elimfunc.obj init.obj allocmem.obj ppage.obj emmmes.obj \
		inittab.obj memmonf.obj rom_srch.obj i286.obj trapdef.obj \
		i386.obj tabdef.obj vmtrap.obj vminst.obj elimtrap.obj \
		vminit.obj moveb.obj em286ll.obj em386ll.obj retreal.obj \
		rrtrap.obj vdminit.obj initepg.obj errhndlr.obj maplin.obj \
		ekbd.obj util.obj initdeb.obj emm.obj emminit.obj mapdma.obj \
		iotrap.obj a20trap.obj oemproc.obj m_state.obj \
		shiphi.obj extpool.obj

COMOBJ = memmcom.obj memmonf.obj

BUGOBJ = memm386.obj elimfunc.obj init.obj allocmem.obj ppage.obj emmmes.obj \
		inittab.obj memmonf.obj rom_srch.obj i286.obj trapdef.obj \
		i386.obj tabdefD.obj vmtrapD.obj vminstD.obj elimtrap.obj \
		vminit.obj moveb.obj em286ll.obj em386ll.obj retreal.obj \
		rrtrap.obj vdminitD.obj initepg.obj errhndlr.obj maplin.obj \
		ekbd.obj util.obj initdebD.obj emmD.obj emminit.obj mapdma.obj \
		iotrap.obj a20trap.obj oemproc.obj kbd.obj print.obj m_state.obj

#******************************************************************************
#	List of libraries required
#******************************************************************************

MEMMLIBS	= ..\emm\emmlib.lib

BUGLIBS 	= ..\deb386\buglib.lib ..\emm\emmlib.lib

#******************************************************************************
#	Listing files
#******************************************************************************
MEMMLST = memm386.lst elimfunc.lst init.lst ppage.lst allocmem.lst emmmes.lst \
		inittab.lst memmonf.lst rom_srch.lst i286.lst trapdef.obj \
		i386.lst tabdef.lst vmtrap.lst vminst.lst elimtrap.lst \
		vminit.lst moveb.lst em286ll.lst em386ll.lst retreal.lst \
		rrtrap.lst vdminit.lst initepg.lst errhndlr.lst maplin.lst \
		ekbd.lst util.lst initdeb.lst emm.lst emminit.lst mapdma.lst \
		iotrap.lst a20trap.lst memminc.lst oemproc.lst shiphi.lst \
		extpool.lst

COMLST = memmcom.lst memmonf.lst

BUGLST = memm386.lst elimfunc.lst init.lst allocmem.lst ppage.lst emmmes.lst \
		inittab.lst memmonf.lst rom_srch.lst i286.lst trapdef.lst \
		i386.lst tabdefD.lst vmtrapD.lst vminstD.lst elimtrap.lst \
		vminit.lst moveb.lst em286ll.lst em386ll.lst retreal.lst \
		rrtrap.lst vdminitD.lst initepg.lst errhndlr.lst maplin.lst \
		ekbd.lst util.lst initdebD.lst emmD.lst emminit.lst mapdma.lst \
		iotrap.lst a20trap.lst kbd.lst emmincD.lst oemproc.lst


#******************************************************************************
#	MEMM targets
#******************************************************************************
#emm386: emm386.exe emm386.com emm386d.exe
emm386: emm386.exe

#	production version of EMM386 device driver
#
emm386.exe: $(MEMMOBJ) $(MEMMLIBS) emm386.lnk
	$(LINK) $(LFLAGS) @emm386.lnk
	del emm386.sys
	ren emm386.exe emm386.sys

#	EMM386.COM utility
#
#emm386.com: $(COMOBJ) emmcom.lnk
#	 $(LINK) $(LFLAGS) @emmcom.lnk
#	 $(CONVERT) emmcom.exe emm386.com

#	debug version of EMM386 driver
#
#emm386d.exe: $(BUGOBJ) $(BUGLIBS) emm386d.lnk
#	 $(LINK) $(LFLAGS) @emm386d.lnk

#******************************************************************************
# EMM386 driver i/f modules
#******************************************************************************

memm386.obj: memm386.asm $(MEMMINC)
	$(ASM) $(AFLAGS) $(AINC) $*.asm;
memm386.lst:  memm386.asm $(MEMMINC)
	$(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;

elimfunc.obj: elimfunc.asm $(MEMMINC)
	$(ASM) $(AFLAGS) $(AINC) $*.asm;
elimfunc.lst:  elimfunc.asm  $(MEMMINC)
	$(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;

init.obj: init.asm $(MEMMINC)
	$(ASM) $(AFLAGS) $(AINC) $*.asm;
init.lst: init.asm $(MEMMINC)
	$(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;

allocmem.obj: allocmem.asm $(MEMMINC)
	$(ASM) $(AFLAGS) $(AINC) $*.asm;
allocmem.lst: allocmem.asm $(MEMMINC)
	$(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;

rom_srch.obj: rom_srch.asm  $(MEMMINC)
	$(ASM) $(AFLAGS) $(AINC) $*.asm;
rom_srch.lst: rom_srch.asm  $(MEMMINC)
	$(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;

inittab.obj inittab.lst: inittab.asm $(MEMMINC)

emmmes.obj emmmes.lst: emmmes.asm $(MEMMINC)

extpool.obj extpool.lst: extpool.asm $(MEMMINC)

shiphi.obj shiphi.lst: shiphi.asm $(MEMMINC)

m_state.obj m_state.lst: m_state.asm $(MEMMINC)

ppage.obj ppage.lst: ppage.asm $(MEMMINC) ..\emm\emmdef.inc

#******************************************************************************
# VDM modules
#******************************************************************************

vdminit.obj vdminit.lst: vdminit.asm $(MEMMINC)

i286.obj i286.lst: i286.asm $(MEMMINC)

i386.obj i386.lst: i386.asm $(MEMMINC)

trapdef.obj trapdef.lst: trapdef.asm $(MEMMINC)

tabdef.obj tabdef.lst: tabdef.asm $(MEMMINC)

vmtrap.obj vmtrap.lst: vmtrap.asm $(MEMMINC)

vminst.obj vminst.lst: vminst.asm $(MEMMINC)

elimtrap.obj: elimtrap.asm $(MEMMINC) ..\emm\emmdef.inc
	$(ASM) $(AFLAGS) $(AINC) $*.asm;
elimtrap.lst: elimtrap.asm $(MEMMINC) ..\emm\emmdef.inc
	$(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;

iotrap.obj iotrap.lst: iotrap.asm $(MEMMINC)

initepg.obj: initepg.asm $(MEMMINC)
	$(ASM) $(AFLAGS) $(AINC) $*.asm;
initepg.lst: initepg.asm $(MEMMINC)
	$(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;

vminit.obj vminit.lst: vminit.asm $(MEMMINC)

em286ll.obj em286ll.lst: em286ll.asm $(MEMMINC)

em386ll.obj em386ll.lst: em386ll.asm $(MEMMINC)

moveb.obj: moveb.asm $(MEMMINC)
	$(ASM) $(AFLAGS) $(AINC) $*.asm;
moveb.lst: moveb.asm $(MEMMINC)
	$(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;

util.obj: util.asm $(MEMMINC)
	$(ASM) $(AFLAGS) $(AINC) $*.asm;
util.lst: util.asm $(MEMMINC)
	$(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;

maplin.obj maplin.lst: maplin.asm $(MEMMINC)

a20trap.obj a20trap.lst: a20trap.asm $(MEMMINC)

oemproc.obj oemproc.lst: oemproc.asm $(MEMMINC)

rrtrap.obj rrtrap.lst: rrtrap.asm $(MEMMINC)

retreal.obj retreal.lst: retreal.asm $(MEMMINC)

errhndlr.obj errhndlr.lst: errhndlr.asm $(MEMMINC)

ekbd.obj ekbd.lst: ekbd.asm $(MEMMINC)

initdeb.obj initdeb.lst: initdeb.asm $(MEMMINC)

emminit.obj emminit.lst: emminit.asm $(MEMMINC)

emm.obj emm.lst: emm.asm $(MEMMINC)

mapdma.obj mapdma.lst: mapdma.c
        $(C) /ASw /G2 /Oat /Gs /Ze /Zl /Fc /c mapdma.c

memminc.lst: memminc.asm $(MEMMINC)
	$(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;

#******************************************************************************
# debug modules
#******************************************************************************

#tabdefD.obj: tabdef.asm $(MEMMINC)
#	 $(ASM) $(ADFLAGS) $(AINC) tabdef.asm,tabdefD.obj;
#tabdefD.lst: tabdef.asm $(MEMMINC)
#	 $(ASM) -l -n $(ADFLAGS) $(AINC) tabdef.asm,tabdefD.obj,tabdefD.lst;
#
#vminstD.obj: vminst.asm $(MEMMINC)
#	 $(ASM) $(ADFLAGS) $(AINC) vminst.asm,vminstD.obj;
#vminstD.lst: vminst.asm $(MEMMINC)
#	 $(ASM) -l -n $(ADFLAGS) $(AINC) vminst.asm,vminstD.obj,vminstD.lst;

#vmtrapD.obj: vmtrap.asm $(MEMMINC)
#	 $(ASM) $(ADFLAGS) $(AINC) vmtrap.asm,vmtrapD.obj;
#vmtrapD.lst: vmtrap.asm $(MEMMINC)
#	 $(ASM) -l -n $(ADFLAGS) $(AINC) vmtrap.asm,vmtrapD.obj,vmtrapD.lst;
#
#vdminitD.obj: vdminit.asm $(MEMMINC)
#	 $(ASM) $(ADFLAGS) $(AINC) vdminit.asm,vdminitD.obj;
#vdminitD.lst: vdminit.asm $(MEMMINC)
#	 $(ASM) -l -n $(ADFLAGS) $(AINC) vdminit.asm,vdminitD.obj,vdminitD.lst;

#initdebD.obj: initdeb.asm $(MEMMINC)
#	 $(ASM) $(ADFLAGS) $(AINC) initdeb.asm,initdebD.obj;
#initdebD.lst: initdeb.asm $(MEMMINC)
#	 $(ASM) -l -n $(ADFLAGS) $(AINC) initdeb.asm,initdebD.obj,initdebD.lst;

#emmD.obj: emm.asm $(MEMMINC)
#	 $(ASM) $(ADFLAGS) $(AINC) emm.asm,emmD.obj;
#emmD.lst: emm.asm $(MEMMINC)
#	 $(ASM) -l -n $(ADFLAGS) $(AINC) emm.asm,emmD.obj,emmD.lst;

#kbd.obj kbd.lst: kbd.asm $(MEMMINC)
#	 $(ASM) $(ADFLAGS) $(AINC) -p $*.asm;

#print.obj print.lst: print.asm $(MEMMINC)
#	 $(ASM) $(ADFLAGS) $(AINC) -p $*.asm;

#memmincD.lst: memminc.asm $(MEMMINC)
#	 $(ASM) -l -n $(ADFLAGS) $(AINC) memminc.asm,memmincD.obj,memmincD.lst;

#******************************************************************************
# EMM386.COM modules
#******************************************************************************

#memmcom.obj: memmcom.asm
#	 $(ASM) $(AFLAGS) $(AINC) $*.asm;
#memmcom.lst: memmcom.asm
#	 $(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;

#memmonf.obj: memmonf.asm memm_msg.inc
#	 $(ASM) $(AFLAGS) $(AINC) $*.asm;
#memmonf.lst: memmonf.asm memm_msg.inc
#	 $(ASM) -l -n $(AFLAGS) $(AINC) $*.asm;



