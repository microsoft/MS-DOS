#************************** makefile for cmd\append ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: diskcopy.com

diskcopy.ctl: diskcopy.skl \
   $(msg)\$(COUNTRY).msg \
   makefile

diskcopy.obj: diskcopy.asm \
   makefile \
   dcpymacr.inc \
   diskcopy.equ \
   $(inc)\bootform.inc

copyinit.obj: copyinit.asm \
   makefile \
   dcpymacr.inc \
   diskcopy.equ

dcopyp.obj: dcopyp.asm \
   makefile \
   $(inc)\parse.asm

dcopysm.obj: dcopysm.asm \
   makefile \
   $(inc)\sysmsg.inc \
   $(inc)\msghan.inc \
   $(inc)\versiona.inc \
   diskcopy.ctl \
   diskcopy.cla \
   diskcopy.cl1 \
   diskcopy.cl2 \
   dcopyms.inc \
   $(inc)\copyrigh.inc

dcopypar.obj: dcopypar.asm \
   makefile

diskcopy.com: diskcopy.obj \
   makefile \
   diskcopy.lnk \
   dcopysm.obj \
   dcopyp.obj \
   dcopypar.obj \
   copyinit.obj
	link @diskcopy.lnk
	exe2bin diskcopy.exe diskcopy.com
	del diskcopy.exe
