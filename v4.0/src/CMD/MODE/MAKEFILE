#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: mode.com

mode.ctl: mode.skl \
      makefile \
      $(msg)\$(COUNTRY).msg


main.obj: main.asm \
   makefile \
  $(inc)\copyrigh.inc \
  $(inc)\versiona.inc \
  $(inc)\struc.inc \
  $(inc)\sysmsg.inc \
  $(inc)\msgserv.asm \
  mode.ctl \
  mode.cl1 \
  mode.cl2 \
  mode.cla \
  mode.clb

scrntab.obj: scrntab.asm \
	 makefile

modescrn.obj: modescrn.asm \
   makefile \
  $(inc)\struc.inc

rescode.obj: rescode.asm \
   makefile \
  $(inc)\struc.inc

modecom.obj: modecom.asm \
   makefile \
  $(inc)\struc.inc \
	     modequat.inc \
	     common.stc

modeprin.obj: modeprin.asm \
   makefile \
  $(inc)\struc.inc

modevid.obj: modevid.asm \
   makefile \
  $(inc)\struc.inc

modeecho.obj: modeecho.asm \
   makefile \
   common.stc \
  $(inc)\struc.inc

modeleng.obj: modeleng.asm \
	      modequat.inc \
	      makefile \
  $(inc)\struc.inc

modemes.obj: modemes.asm \
	    makefile \
  $(inc)\msgserv.asm \
	     modesubs.inc \
	     modedefs.inc \
	     modequat.inc \
	     common.stc

display.obj: display.asm \
	    makefile \
	     common.stc

typamat.obj: typamat.asm \
	    makefile \
  $(inc)\struc.inc \
	     modequat.inc

invoke.obj: invoke.asm \
	    makefile \
  $(inc)\struc.inc \
	    modequat.inc \
	    common.stc

modepars.obj: modepars.asm \
	    makefile \
  $(inc)\struc.inc \
  $(inc)\psdata.inc \
	      modequat.inc \
	      common.stc


parshell.obj: parshell.asm \
	    makefile \
  $(inc)\parse.asm


modecp.obj: modecp.asm \
	    makefile \
   modecpro.inc \
   modecpeq.inc \
   modecpms.inc \
  $(inc)\struc.inc

mode.com: main.obj \
   makefile \
   scrntab.obj \
   modescrn.obj \
   rescode.obj \
   modecom.obj \
   modeprin.obj \
   modevid.obj \
   modeleng.obj \
   modeecho.obj \
   modecp.obj \
   display.obj \
   typamat.obj \
   invoke.obj \
   parshell.obj \
   modepars.obj \
   modemes.obj \
   mode.lnk
	link @mode.lnk
	exe2bin mode.exe mode.com
	del mode.exe
