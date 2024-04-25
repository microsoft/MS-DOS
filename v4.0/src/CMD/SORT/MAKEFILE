#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: sort.exe

sort.ctl: sort.skl              \
        $(msg)\$(COUNTRY).msg \
        makefile

sort.obj: sort.asm              \
          makefile              \
          sort.ctl              \
          sort.cla              \
          sort.cl1              \
          sort.cl2              \
          $(inc)\parse.asm      \
          $(inc)\psdata.inc     \
          $(inc)\syscall.inc    \
          $(inc)\msgserv.asm    \
          $(inc)\sysmsg.inc

sortmes.obj: sort.asm           \
          makefile              \
          $(inc)\syscall.inc

sort.exe: sort.obj sortmes.obj
        link sort+sortmes,sort.exe;
        exefix sort.exe 1 1
