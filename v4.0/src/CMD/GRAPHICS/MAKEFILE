#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: graphics.com


graphics.ctl: graphics.skl $(msg)\$(COUNTRY).msg

graphics.obj: graphics.asm  grinst.ext makefile

grinst.obj: grinst.asm	grload.ext grload2.ext grctrl.ext grprint.ext \
	    grcpsd.ext	grparms.ext  grparse.ext grbwprt.ext grcolprt.ext \
	    grint2fh.ext grmsg.equ  graphics.ctl graphics.cla graphics.cl1 \
	    graphics.clb \
	    graphics.cl2 graphics.clc \
	    $(inc)\sysmsg.inc $(inc)\struc.inc grshar.str  makefile

grcpsd.obj: grparse.asm makefile $(inc)\parse.asm

grparse.obj: grcpsd.asm makefile

grpattrn.obj: grpattrn.asm grpattrn.str makefile

grbwprt.obj: grbwprt.asm grcommon.ext grctrl.str grshar.str makefile \
	     grpattrn.str $(inc)\struc.inc makefile

grint2fh.obj: grint2fh.asm  grload.ext	grctrl.ext grprint.ext \
	      grcpsd.ext makefile

grctrl.obj: grctrl.asm grint2fh.ext grbwprt.ext grcolprt.ext grshar.str \
	    grpattrn.str grpattrn.ext grctrl.str $(inc)\struc.inc \
	    makefile

grcolprt.obj: grctrl.str grshar.str grpattrn.str grctrl.ext  \
	      $(inc)\struc.inc grcommon.asm makefile

grload.obj: grload.asm $(inc)\struc.inc grinst.ext grshar.str grparse.ext \
	    grload2.ext grload3.ext grmsg.equ  makefile

grload2.obj: grload2.asm $(inc)\struc.inc grinst.ext grshar.str grmsg.equ \
	     grinst.ext grload.ext grparse.ext grpattrn.str grpattrn.ext \
	     makefile

grload3.obj: grload3.asm $(inc)\struc.inc grinst.ext grshar.str grmsg.equ \
	     grinst.ext grload.ext grload2.ext grparse.ext grpattrn.str \
	     grpattrn.ext makefile

grparms.obj: grparms.asm grmsg.equ grshar.str grinst.ext grparse.ext \
	     $(inc)\struc.inc  makefile

graphics.com: graphics.obj grint2fh.obj grpattrn.obj grctrl.obj grcpsd.obj \
	      grcolprt.obj grbwprt.obj grinst.obj grparse.obj grparms.obj \
	      grload.obj grload2.obj grload3.obj graphics.lnk
	  link @graphics.lnk
	  exe2bin graphics.exe graphics.com
	  del graphics.exe
