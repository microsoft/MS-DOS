#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: xcopy.exe

xcopy.ctl: xcopy.skl \
   $(msg)\$(COUNTRY).msg \
   makefile

xcopy.obj: xcopy.asm \
   makefile \
   $(inc)\versiona.inc \
   $(inc)\copyrigh.inc \
   $(inc)\sysmsg.inc \
   $(inc)\msgserv.asm \
   dos.equ \
   xcopy.equ \
   xcopy.ctl \
   xcopy.cl1 \
   xcopy.cl2 \
   xcopy.cla \
   xmainmsg.equ

xcpyinit.obj: xcpyinit.asm \
   makefile \
   $(inc)\versiona.inc \
   xcopy.equ \
   dos.equ \
   xinitmsg.equ

xcopypar.obj: xcopypar.asm \
   makefile \
   $(inc)\psdata.inc \
   $(inc)\parse.asm

xcopy.exe: xcopy.obj \
   makefile  \
   xcopy.lnk  \
   xcopypar.obj \
   xcpyinit.obj
        link @xcopy.lnk
