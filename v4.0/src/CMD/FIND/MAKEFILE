#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: find.exe

find.ctl: find.skl              \
          $(msg)\$(COUNTRY).msg \
          makefile

find.obj: find.asm              \
          makefile              \
          find.ctl              \
          find.cla              \
          find.cl1              \
          find.cl2              \
          find.inc              \
          $(inc)\parse.asm      \
          $(inc)\psdata.inc     \
          $(inc)\syscall.inc    \
          $(inc)\msgserv.asm    \
          $(inc)\sysmsg.inc

findmes.obj: findmes.asm

find.exe: find.obj findmes.obj
        link find+findmes,find.exe/ex;
