#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: label.com

labl.ctl: labl.skl     \
  makefile             \
  $(msg)\$(COUNTRY).msg

label.obj: label.asm    \
  makefile

labelm.obj: labelm.asm  \
  labl.ctl 		\
  makefile             \
  $(inc)\copyrigh.inc   \
  $(inc)\sysmsg.inc     \
  $(inc)\msgserv.asm

label.com: label.obj    \
  labelm.obj            \
  makefile             \
  label.lnk
       link @label.lnk
       exe2bin label.exe label.com
       del label.exe
