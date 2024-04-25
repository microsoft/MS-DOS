#************************** makefile for cmd\backup ***************************

cflags	= -AS -Od -Zp $(extcsw)
msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h
map	=..\..\mapper
here	=..\cmd\backup

#
#######################	dependencies begin here. #########################
#

all: backup.com

$(map)\mapper.lib:
	cd $(map)
	nmake
	cd $(here)

_parse.obj:	_parse.asm			\
		$(inc)\parse.asm		\
		$(inc)\psdata.inc		\
		makefile

backup.ctl:	backup.skl			\
		$(msg)\$(COUNTRY).MSG		

_msgret.obj:	_msgret.asm			\
		backup.ctl			\
		$(inc)\msgserv.asm		\
		$(inc)\sysmsg.inc		\
		$(inc)\versiona.inc		\
		$(inc)\copyrigh.inc		\
		makefile

backup.obj:  backup.c  backpars.h backup.h  makefile	\
	     $(hinc)\doscalls.h

backup.com: backup.obj _parse.obj _msgret.obj		\
	    $(map)\mapper.lib $(inc)\comsubs.lib
	link /NOE backup + _parse + _msgret,,,$(map)\mapper + $(inc)\comsubs;
	convert backup.exe backup.com
	del backup.exe
