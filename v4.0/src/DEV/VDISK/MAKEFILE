#************************ Makefile for vdisk **************************

inc	=..\..\inc
msg	=..\..\messages
dos	=..\..\dos
hinc	=..\..\hinc

#
####################### Dependencies begin here. #######################
#

all: vdisk.sys

vdisk.ctl: vdisk.skl    \
           $(msg)\$(COUNTRY).msg    \
           makefile


vdisksys.obj: vdisksys.asm       \
           vdisksys.inc          \
           vdisk.ctl             \
           vdisk.cl2             \
           vdisk.cla             \
           vdisk.cl1             \
           $(inc)\msgserv.asm \
           $(inc)\sysmsg.inc  \
           makefile

vdisk.sys: vdisksys.obj \
           vdisk.lnk
        link @vdisk.lnk
        exe2bin vdisk.exe vdisk.sys
        del vdisk.exe
