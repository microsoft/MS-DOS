#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

map	=..\..\mapper
here	=..\cmd\fdisk

all: fdisk.exe


# Handle the FDISK 'C' source compilations first

fdiskm.c  : $(msg)\$(COUNTRY).msg fdisk.msg
        menubld fdisk.msg  $(msg)\$(COUNTRY).MSG

fdisk5.cl1 : fdisk5.skl $(msg)\$(COUNTRY).msg

fdisk.ctl : fdisk.skl $(msg)\$(COUNTRY).msg

main.obj : main.c \
           fdisk.h subtype.h extern.h fdiskmsg.h msgret.h doscall.h 

fdisk.obj : fdisk.c \
            fdisk.h subtype.h extern.h fdiskmsg.h doscall.h msgret.h

mainmenu.obj : mainmenu.c fdisk.h subtype.h extern.h fdiskmsg.h 

display.obj : display.c \
              fdisk.h subtype.h extern.h fdiskmsg.h doscall.h

d_menus.obj : d_menus.c fdisk.h subtype.h extern.h fdiskmsg.h 

c_menus.obj : c_menus.c fdisk.h subtype.h extern.h fdiskmsg.h 

input.obj : input.c fdisk.h subtype.h extern.h fdiskmsg.h doscall.h

tdisplay.obj : tdisplay.c fdisk.h subtype.h extern.h fdiskmsg.h 

vdisplay.obj : vdisplay.c fdisk.h subtype.h extern.h fdiskmsg.h 

space.obj : space.c fdisk.h subtype.h extern.h

partinfo.obj : partinfo.c fdisk.h subtype.h extern.h 

makepart.obj : makepart.c fdisk.h subtype.h extern.h 

video.obj : video.c fdisk.h extern.h subtype.h fdiskmsg.h doscall.h

int13.obj : int13.c fdisk.h subtype.h extern.h fdiskmsg.h

diskout.obj : diskout.c fdisk.h subtype.h extern.h

fdparse.obj : fdparse.c fdisk.h subtype.h extern.h parse.h msgret.h 

convert.obj : convert.c fdisk.h subtype.h extern.h 

global.obj : global.c fdisk.h makefile 

fdiskm.obj : fdiskm.c

messages.obj : messages.c msgret.h extern.h subtype.h fdisk.h


# Handle the FDISK MASM source


fdboot.obj : fdboot.asm fdisk5.cl1

fdboot.inc: fdboot.obj
        link fdboot;
        exe2bin fdboot
        del fdboot.exe
        dbof fdboot.bin fdboot.inc 600 200

_parse.obj : _parse.asm $(inc)\psdata.inc $(inc)\parse.asm \
             makefile

_msgret.obj : _msgret.asm $(inc)\psdata.inc \
             fdisk.ctl fdisk.cla fdisk.clb fdisk.cl1 fdisk.cl2 \
             makefile

bootrec.obj : bootrec.asm fdboot.inc \
              makefile

reboot.obj : reboot.asm \
             makefile

$(map)\mapper.lib:
	cd $(map)
	nmake
	cd $(here)

# Do the link of FDISK

fdisk.exe : fdisk.obj reboot.obj bootrec.obj fdboot.obj \
            display.obj input.obj tdisplay.obj vdisplay.obj \
            space.obj partinfo.obj video.obj makepart.obj \
            int13.obj diskout.obj messages.obj fdparse.obj \
            convert.obj global.obj fdiskm.obj main.obj \
            c_menus.obj d_menus.obj mainmenu.obj _msgret.obj  \
	    $(map)\mapper.lib makefile fdisk.lnk fdisk.ctl _parse.obj \
            $(inc)\comsubs.lib
	cd $(inc)
	nmake
	cd $(here)
        link @fdisk.lnk

