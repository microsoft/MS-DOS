#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

map	=..\..\mapper
here	=..\cmd\restore

all: not_file restore.com

#-------BUILD MAPPER ----------------
not_file : makefile		 #Always perform these steps!
	cd $(map)
	nmake
	cd $(here)


_parse.obj :	_parse.asm			\
		makefile			\
		$(inc)\parse.asm		\
		$(inc)\psdata.inc

restore.ctl :	restore.skl			\
		makefile			\
		$(msg)\$(COUNTRY).msg


_msgret.obj:	_msgret.asm			\
		makefile			\
		restore.ctl			\
		restore.cl1			\
		$(inc)\msgserv.asm		\
		$(inc)\sysmsg.inc


restore.obj :	restore.c rt.h rt1.h rt2.h restpars.h makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

rtt1.obj :	rtt1.c rt.h rt1.h rt2.h restpars.h makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

rtt3.obj :	rtt3.c rt.h rt1.h rt2.h restpars.h makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

rtdo.obj :	rtdo.c	rt.h rt1.h rt2.h restpars.h  makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

rtdo1.obj :	rtdo1.c rt.h rt1.h rt2.h restpars.h makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

rtnew.obj :	rtnew.c rt.h rt1.h rt2.h restpars.h makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

rtnew1.obj :	rtnew1.c rt.h rt1.h rt2.h restpars.h makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

rtold.obj :	rtold.c rt.h rt1.h rt2.h restpars.h makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

rtold1.obj :	rtold1.c rt.h rt1.h rt2.h restpars.h makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

rtfile.obj  :	rtfile.c rt.h rt1.h rt2.h restpars.h makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

rtfile1.obj :	rtfile1.c rt.h rt1.h rt2.h restpars.h makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

restpars.obj :	restpars.c rt.h rt1.h rt2.h restpars.h makefile \
		$(hinc)\comsub.h    $(hinc)\doscalls.h	     \
		$(hinc)\error.h

restore.com:	 restore.obj \
		 restpars.obj \
		 rtdo.obj    \
		 rtdo1.obj   \
		 rtfile.obj  \
		 rtfile1.obj \
		 rtnew.obj   \
		 rtnew1.obj  \
		 rtold.obj   \
		 rtold1.obj  \
		 rtt1.obj    \
		 rtt3.obj    \
		 restore.lnk \
		 _msgret.obj \
		 _parse.obj  \
		 $(map)\mapper.lib
	link @restore.lnk
	convert restore.exe restore.com
	erase restore.exe
