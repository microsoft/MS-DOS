#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: recover.com

recover.ctl : recover.skl    \
	     $(msg)\$(COUNTRY).msg \
	     makefile

recover.obj: recover.asm			  \
	     recequ.inc recmacro.inc   \
	     recseg.inc recdata.inc recparse.inc  \
	     recmsg.inc 			  \
	     recover.ctl recover.cl1		  \
	     recover.cl2 recover.cla		  \
	     $(inc)\dossym.inc $(inc)\syscall.inc \
	     $(inc)\sysmsg.inc $(inc)\parse.asm   \
	     makefile

recinit.obj: recinit.asm			 \
	     recequ.inc recmacro.inc  \
	     recseg.inc recdata.inc recparse.inc \
	     recmsg.inc 			 \
	     recover.ctl recover.cl1		  \
	     recover.cl2 recover.cla		  \
	     $(inc)\dossym.inc $(inc)\syscall.inc \
	     $(inc)\sysmsg.inc $(inc)\parse.asm   \
	     makefile


recproc.obj: recproc.asm			 \
	     recequ.inc recmacro.inc  \
	     recseg.inc recdata.inc recparse.inc \
	     recmsg.inc 			 \
	     recover.ctl recover.cl1		  \
	     recover.cl2 recover.cla		  \
	     $(inc)\dossym.inc $(inc)\syscall.inc \
	     $(inc)\sysmsg.inc $(inc)\parse.asm   \
	     makefile

recdisp.obj: recdisp.asm			 \
	     recequ.inc recmacro.inc  \
	     recseg.inc recdata.inc recparse.inc \
	     recmsg.inc 			 \
	     recover.ctl recover.cl1		  \
	     recover.cl2 recover.cla		  \
	     $(inc)\dossym.inc $(inc)\syscall.inc \
	     $(inc)\sysmsg.inc $(inc)\parse.asm   \
	     makefile


recover.com: recover.obj recproc.obj recinit.obj \
	     recdisp.obj	     \
	     recover.lnk makefile
	link @recover.lnk
	convert recover.exe
