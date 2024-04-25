#************************ makefile for dev\xma2ems************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: xma2ems.sys

xma2ems.ctl:	xma2ems.skl $(MSG)\$(country).MSG makefile

xma2ems.obj:	xma2ems.asm xma1diag.inc xma2ems.cl1 $(inc)\COPYRIGH.INC \
		parmpars.inc lim40.inc ps2_5060.inc makefile \
		emsinit.inc genioctl.inc xma2emsp.inc lim40b.inc romscan.inc \
		$(inc)\psdata.inc

xma2ems.sys: xma2ems.obj makefile
		link xma2ems;
		exe2bin xma2ems.exe xma2ems.sys
		del xma2ems.exe
