#************************** makefile for cmd\append ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: diskcomp.com

diskcomp.ctl: diskcomp.skl \
   $(msg)\$(COUNTRY).msg \
   makefile

diskcomp.obj: diskcomp.asm \
   makefile \
   dcmpmacr.inc \
   $(inc)\bootform.inc \
   diskcomp.equ

compinit.obj: compinit.asm \
   makefile \
   dcmpmacr.inc \
   $(inc)\bootform.inc \
   diskcomp.equ

dcompp.obj: dcompp.asm \
   makefile \
   $(inc)\parse.asm

dcompsm.obj: dcompsm.asm \
   makefile \
   $(inc)\sysmsg.inc \
   $(inc)\msghan.inc \
   $(inc)\versiona.inc \
   diskcomp.ctl \
   diskcomp.cla \
   diskcomp.cl1 \
   diskcomp.cl2 \
   dcompms.inc \
   $(inc)\copyrigh.inc

dcomppar.obj: dcomppar.asm \
   makefile

diskcomp.com: diskcomp.obj \
   makefile \
   diskcomp.lnk \
   dcompsm.obj \
   dcompp.obj \
   dcomppar.obj \
   compinit.obj
	link @diskcomp.lnk
	exe2bin diskcomp.exe diskcomp.com
	del diskcomp.exe

