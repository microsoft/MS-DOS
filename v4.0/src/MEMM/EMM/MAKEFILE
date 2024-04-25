#******************************************************************************
#	title	MAKEFILE - EMMLIB.LIB build file
#******************************************************************************
#
#   (C) Copyright MICROSOFT Corp. 1986
#
#   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
#		EMMLIB.LIB - EMM functions library
#
#   Module:   MAKEFILE for EMMLIB - EMM library
#
#   Version:  0.02
#
#   Date:     May 12, 1986
#
#******************************************************************************
#
#   Change log:
#
#     DATE    REVISION			DESCRIPTION
#   --------  --------	-------------------------------------------------------
#   06/12/86  Original
#   06/25/86  0.02	Added EMMDEF.INC (SBP).
#
#******************************************************************************
#
#   Functional Description:
#
#   This file assembles and links EMMLIB.LIB
#
#******************************************************************************
.SUFFIXES:
.SUFFIXES:	.c .asm .obj .lst .def .lnk .lrf .exe .com

#	Definition for turning OFF high memory allocation
#		HIFLAG = -DNOHIMEM => turns it off
#		HIFLAG =	   => turns on high memory allocation
HIFLAG	      = /DNOHIMEM
#HIFLAG	=

#	Definitions for assembler
#	(using masm 4.00)
MASM	= masm
#MASM	= \bin\masm400
#MASM	 = masm400
AFLAGS	= /Mx /t /DI386  /i..\memm $(HIFLAG)
AINC	= ..\memm\vdmseg.inc ..\memm\vdmsel.inc emmdef.inc

#	Definitions for linker for old style .exe files
#LINK	= \bin\link
LINK	 = link
LFLAGS	= /NOI /M
LIBS	=

#	Definitions for librarian
#LIB	= \bin\lib
LIB	 = lib

#	Defines for C Compiler
C	= cl
#C	= \bin\msc
#C	 = msc
CFLAGS	=/ASw /G2 /Oat /Gs /Ze /Zl /Fc /c

#
# definition of objects
#
OBJS=emmfunct.obj emm40.obj emmp.obj emmsup.obj emmdisp.obj emmdata.obj emminc.obj
LOBJS=emmfunct.obj+emm40.obj+emmp.obj+emmsup.obj+emmdisp.obj+emmdata.obj

emmlib.lib:	$(OBJS)
		del emmlib.lib
		$(LIB) emmlib+$(LOBJS),;

emmfunct.obj:	emmfunct.c emm.h
		$(C) $(CFLAGS) emmfunct.c

emm40.obj:	emm40.c emm.h
		$(C) $(CFLAGS) emm40.c

emmp.obj:	emmp.asm $(AINC)
		$(MASM) $(AFLAGS) emmp.asm,emmp.obj,emmp.lst;

emmsup.obj:	emmsup.asm $(AINC)
		$(MASM) $(AFLAGS) emmsup.asm,emmsup.obj,emmsup.lst;

emmdisp.obj:	emmdisp.asm $(AINC)
		$(MASM) $(AFLAGS) emmdisp.asm,emmdisp.obj,emmdisp.lst;

emmdata.obj:	emmdata.asm $(AINC)
		$(MASM) $(AFLAGS) emmdata.asm,emmdata.obj,emmdata.lst;

emminc.obj:	emminc.asm $(AINC)
		$(MASM) $(AFLAGS) emminc.asm,emminc.obj,emminc.lst;

