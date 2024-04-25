#************************ makefile for cmd\format *************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h
boot	=..\..\boot

#
#######################	dependencies begin here. #########################
#

all: format.com

boot.cl1:
		copy $(boot)\boot.cl1

format.ctl:     format.skl $(msg)\$(COUNTRY).msg

display.obj:    display.asm forequ.inc formsg.inc formacro.inc makefile \
                format.ctl format.cl1 format.cl2 format.cla $(inc)\sysmsg.inc \
                $(inc)\msgserv.asm \
                format.clb format.clc formacro.inc

forexec.obj:    forexec.asm forequ.inc makefile $(inc)\syscall.inc \
                formacro.inc

forlabel.obj:   forlabel.asm forequ.inc formacro.inc makefile \
                $(inc)\syscall.inc $(inc)\ioctl.inc $(inc)\dosmac.inc \
                forswtch.inc

format.obj:     format.asm $(inc)\dosmac.inc $(inc)\bpb.inc \
                $(inc)\dirent.inc $(inc)\dpb.inc $(inc)\curdir.inc \
                $(inc)\cpmfcb.inc $(inc)\pdb.inc makefile \
                $(inc)\error.inc $(inc)\syscall.inc $(inc)\ioctl.inc \
                forequ.inc formacro.inc forswtch.inc

forinit.obj:    forinit.asm forequ.inc formacro.inc makefile \
                $(inc)\syscall.inc $(inc)\ioctl.inc forparse.inc \
                forswtch.inc $(inc)\parse.asm $(inc)\psdata.inc

msfor.obj:      msfor.asm $(inc)\dosmac.inc $(inc)\syscall.inc $(inc)\bpb.inc \
                $(inc)\dirent.inc boot.cl1 $(inc)\ioctl.inc \
                $(inc)\boot.inc $(inc)\boot11.inc makefile \
                $(inc)\bootform.inc filesize.inc forequ.inc formacro.inc forswtch.inc

forproc.obj:    forproc.asm $(inc)\syscall.inc makefile forequ.inc \
                formacro.inc forswtch.inc


format.com:     format.obj forproc.obj msfor.obj forexec.obj display.obj \
                forinit.obj forlabel.obj 
        link  @format.lnk
        convert format.exe
        del format.exe
