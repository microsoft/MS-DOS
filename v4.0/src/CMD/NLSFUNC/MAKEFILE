#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: nlsfunc.exe

nlsfunc.ctl: nlsfunc.skl	\
	     $(msg)\$(COUNTRY).msg	\
	     makefile


nlsfunc.obj: nlsfunc.asm	  \
	     funcdbcs.inc	  \
	     msg2nls.inc	  \
	     funcparm.inc	  \
	     nlsfunc.ctl	  \
	     nlsfunc.cla	  \
	     nlsfunc.cl1	  \
	     nlsfunc.cl2	  \
	     doesmac.inc       \
	     $(inc)\mult.inc     \
	     $(inc)\msgserv.asm   \
	     $(inc)\doscntry.inc \
	     $(inc)\devsym.inc   \
	     $(inc)\struc.inc    \
	     $(inc)\copyrigh.inc \
	     makefile

nlsparm.obj:  nlsparm.asm	  \
	      $(inc)\parse.asm \
	      $(inc)\psdata.inc \
	      makefile



nlsfunc.exe: nlsfunc.obj nlsparm.obj
	link nlsfunc+nlsparm;

