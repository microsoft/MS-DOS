#************************** makefile for cmd\append ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: chkdsk.com

chkdsk.ctl: chkdsk.skl \
	    makefile \
	    $(msg)\$(COUNTRY).msg

chkinit.obj: chkinit.asm   \
	     chkequ.inc chkmacro.inc chkparse.inc chkchng.inc \
	     makefile  chkseg.inc \
		$(inc)\ioctl.inc

chkdsk1.obj: chkdsk1.asm \
	     chkequ.inc chkmacro.inc chkchng.inc \
	     makefile chkseg.inc chkdata.inc \
		$(inc)\dossym.inc $(inc)\sysmsg.inc  $(inc)\devsym.inc	 \
		$(inc)\cpmfcb.inc $(inc)\dosmac.inc $(inc)\ioctl.inc	 \
		$(inc)\syscall.inc

chkdsk2.obj: chkdsk2.asm \
	     chkequ.inc chkmacro.inc chkchng.inc \
	     makefile  chkseg.inc \
		$(inc)\dossym.inc $(inc)\sysmsg.inc  $(inc)\devsym.inc	 \
		$(inc)\cpmfcb.inc $(inc)\dosmac.inc $(inc)\ioctl.inc	 \
		$(inc)\syscall.inc

chkproc.obj: chkproc.asm \
	     chkequ.inc chkmacro.inc chkchng.inc \
	     makefile  chkseg.inc \
		$(inc)\dossym.inc $(inc)\sysmsg.inc  $(inc)\devsym.inc	 \
		$(inc)\cpmfcb.inc $(inc)\dosmac.inc $(inc)\ioctl.inc	 \
		$(inc)\syscall.inc

chkproc2.obj: chkproc2.asm \
	     chkequ.inc chkmacro.inc chkchng.inc \
	     makefile  chkseg.inc \
		$(inc)\dossym.inc $(inc)\sysmsg.inc  $(inc)\devsym.inc	 \
		$(inc)\cpmfcb.inc $(inc)\dosmac.inc $(inc)\ioctl.inc	 \
		$(inc)\syscall.inc

chkdisk.obj:  chkdisk.asm  \
	     chkequ.inc chkmacro.inc chkchng.inc \
	     makefile  chkseg.inc \
		$(inc)\dossym.inc $(inc)\sysmsg.inc  $(inc)\devsym.inc	 \
		$(inc)\cpmfcb.inc $(inc)\dosmac.inc $(inc)\ioctl.inc	 \
		$(inc)\syscall.inc

chkfat.obj:   chkfat.asm   \
	     chkequ.inc chkmacro.inc chkchng.inc \
	     makefile  chkseg.inc \
		$(inc)\dossym.inc $(inc)\sysmsg.inc  $(inc)\devsym.inc	 \
		$(inc)\cpmfcb.inc $(inc)\dosmac.inc $(inc)\ioctl.inc	 \
		$(inc)\syscall.inc

chkprmt.obj: chkprmt.asm \
	     chkequ.inc chkmacro.inc chkchng.inc \
	     makefile  chkseg.inc \
		$(inc)\dossym.inc $(inc)\sysmsg.inc  $(inc)\devsym.inc	 \
		$(inc)\cpmfcb.inc $(inc)\dosmac.inc $(inc)\ioctl.inc	 \
		$(inc)\syscall.inc

#chkexec.obj: chkexec.asm  \							;an038;bgb #commented out when received from IBM (mrw)
#	      chkequ.inc chkmacro.inc chkchng.inc \				;an038;bgb
#	      makefile  chkseg.inc \						;an038;bgb
#		 $(inc)\dossym.inc $(inc)\sysmsg.inc  $(inc)\devsym.inc   \	;an038;bgb
#		 $(inc)\cpmfcb.inc $(inc)\dosmac.inc $(inc)\ioctl.inc	  \	;an038;bgb
#		 $(inc)\syscall.inc						;an038;bgb

chkdisp.obj: chkdisp.asm    \
	chkdsk.ctl \
	chkdsk.cla chkdsk.clb chkdsk.clc chkdsk.cld chkdsk.cl1 chkdsk.cl2 \
	     chkequ.inc chkmacro.inc chkparse.inc chkmsg.inc chkchng.inc \
	     makefile  chkseg.inc \
		$(inc)\dossym.inc $(inc)\sysmsg.inc  $(inc)\devsym.inc	 \
		$(inc)\cpmfcb.inc $(inc)\dosmac.inc $(inc)\ioctl.inc	 \
		$(inc)\syscall.inc


chkdsk.com: chkdsk1.obj chkdsk2.obj chkproc.obj chkproc2.obj chkprmt.obj \
	    chkdisk.obj chkfat.obj \
	    chkinit.obj chkdisp.obj \
	    chkdsk.lnk	makefile
	link @chkdsk.lnk
	convert chkdsk.exe
