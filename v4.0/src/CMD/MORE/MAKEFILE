#************************ makefile for cmd\more *************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: more.com

more.ctl:       more.skl \
                $(msg)\$(COUNTRY).msg \
                makefile

more.obj: more.asm             \
          more.inc             \
          makefile             \
          more.ctl             \
          more.cla             \
          more.cl1             \
          more.cl2             \
          $(inc)\syscall.inc   \
          $(inc)\struc.inc     \
          $(inc)\msgserv.asm   \
          $(inc)\sysmsg.inc    \
          $(inc)\versiona.inc  \
          $(inc)\copyrigh.inc

more.com: more.obj \
          more.lnk 
        link @more.lnk
        exe2bin more.exe more.com
        del more.exe
