#*********************** Makefile for ansi.sys ****************************

dos	=..\..\dos
inc	=..\..\inc
msg	=..\..\messages

#
####################### Dependencies Begin Here ##########################
#

all: ansi.sys

ansi.ctl:       ansi.skl $(msg)\$(COUNTRY).msg

ansi.obj:       ansi.asm ansi.inc \
                $(inc)\vector.inc \
                $(inc)\mult.inc \
                $(inc)\struc.inc

ioctl.obj:      ioctl.asm ansi.inc \
                $(inc)\struc.inc

ansiinit.obj:   ansiinit.asm ansi.inc ansivid.inc \
                $(inc)\struc.inc

parser.obj:     parser.asm ansi.inc $(inc)\sysmsg.inc $(inc)\parse.asm \
                $(inc)\struc.inc ansi.ctl $(inc)\versiona.inc

ansi.sys:       ansi.obj ioctl.obj ansiinit.obj parser.obj ansi.lnk makefile
			link    @ansi.lnk
			exe2bin ansi.exe ansi.sys
			del     ansi.exe

