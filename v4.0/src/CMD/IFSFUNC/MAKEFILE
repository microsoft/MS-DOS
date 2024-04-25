#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h
here	=..\cmd\ifsfunc
make	=nmake -i

#
#######################	dependencies begin here. #########################
#

all: ifsfunc.exe

msdos.cl1: $(dos)\msdos.skl		\
	$(msg)\$(COUNTRY).msg		\
	$(dos)\makefile
	copy $(dos)\msdos.skl
	nosrvbld msdos.skl $(msg)\$(COUNTRY).msg

ifsfunc.ctl: ifsfunc.skl  $(msg)\$(COUNTRY).msg makefile

$(inc)\dossym.inc:	 $(inc)\versiona.inc $(inc)\dosmac.inc	      \
     $(inc)\bpb.inc	 $(inc)\buffer.inc   $(inc)\sysvar.inc	      \
     $(inc)\vector.inc	 $(inc)\mult.inc     $(inc)\dirent.inc	      \
     $(inc)\dpb.inc	 $(inc)\curdir.inc   $(inc)\cpmfcb.inc	      \
     $(inc)\find.inc	 $(inc)\pdb.inc      $(inc)\exe.inc	      \
     $(inc)\sf.inc	 $(inc)\arena.inc    $(inc)\intnat.inc	      \
     $(inc)\mi.inc	 $(inc)\filemode.inc $(inc)\error.inc	      \
     $(inc)\syscall.inc 					      \
     makefile
     echo " touch $(inc)\dossym.inc "

ifssess.obj: ifssess.asm $(inc)\ifssym.inc	   ifsfsym.inc	      \
     $(inc)\dossym.inc	 $(inc)\devsym.inc   $(inc)\dosseg.asm	      \
     makefile

ifsdir.obj: ifsdir.asm	 $(inc)\ifssym.inc	    ifsfsym.inc       \
     $(inc)\dossym.inc	 $(inc)\devsym.inc   $(inc)\dosseg.asm	      \
     makefile

ifsfile.obj: ifsfile.asm $(inc)\ifssym.inc	   ifsfsym.inc	      \
     $(inc)\dossym.inc	 $(inc)\devsym.inc   $(inc)\dosseg.asm	      \
     makefile	 $(inc)\doscntry.inc

ifshand.obj: ifshand.asm $(inc)\ifssym.inc	   ifsfsym.inc	      \
     $(inc)\dossym.inc	 $(inc)\devsym.inc   $(inc)\dosseg.asm	      \
     makefile

ifsdev.obj:  ifsdev.asm  $(inc)\ifssym.inc	    ifsfsym.inc       \
     $(inc)\dossym.inc	 $(inc)\devsym.inc   $(inc)\dosseg.asm	      \
     makefile

ifsutil.obj: ifsutil.asm $(inc)\ifssym.inc	    ifsfsym.inc       \
     $(inc)\dossym.inc	 $(inc)\devsym.inc   $(inc)\dosseg.asm	      \
     $(inc)\bugtyp.asm						      \
     makefile

ifserror.obj: ifserror.asm $(inc)\ifssym.inc	     ifsfsym.inc      \
     $(inc)\dossym.inc	 $(inc)\devsym.inc   $(inc)\dosseg.asm	      \
     ifsfunc.ctl  ifsfunc.cla  ifsfunc.cl1  ifsfunc.cl2 	      \
     makefile

ifsfdos.obj:  ifsfdos.asm $(inc)\ifssym.inc	    ifsfsym.inc       \
     $(inc)\dossym.inc	 $(inc)\devsym.inc   $(inc)\dosseg.asm	      \
     $(inc)\msdata.asm	 $(inc)\bugtyp.asm   $(inc)\sysmsg.inc	      \
     $(inc)\psdata.inc	 $(inc)\msgserv.asm	  ifsparse.inc	      \
     $(inc)\parse.asm						      \
     makefile

ifsinit.obj:  ifsinit.asm $(inc)\ifssym.inc	    ifsfsym.inc       \
     $(inc)\dossym.inc	 $(inc)\devsym.inc   $(inc)\dosseg.asm	      \
     $(inc)\msdata.asm	 $(inc)\bugtyp.asm   $(inc)\sysmsg.inc	      \
     $(inc)\psdata.inc	 $(inc)\msgserv.asm	  ifsparse.inc	      \
     $(inc)\parse.asm						      \
     ifsfunc.ctl  ifsfunc.cla  ifsfunc.cl1  ifsfunc.cl2 	      \
     makefile

$(inc)\nibdos.obj:
	cd $(inc)
	$(make)
	cd $(here)

$(inc)\const2.obj:
	cd $(inc)
	$(make)
	cd $(here)

$(inc)\msdata.obj:
	cd $(inc)
	$(make)
	cd $(here)	

$(inc)\mstable.obj:
	cd $(inc)
	$(make)
	cd $(here)	                                  	       

$(inc)\msdosme.obj:
	cd $(inc)
	$(make)
	cd $(here)

$(dos)\msdisp.obj:
	cd $(dos)
	$(make)
	cd $(here)

$(dos)\mscode.obj:
	cd $(dos)
	$(make)
	cd $(here)                                     	     

ifsflink.obj: ifsflink.asm					      \
     $(inc)\dossym.inc						      \
     makefile

ifsfunc.exe: ifssess.obj ifsdir.obj  ifsfile.obj  ifshand.obj	      \
	     ifsdev.obj  ifsutil.obj ifserror.obj ifsfdos.obj	      \
	     ifsinit.obj					      \
	     $(inc)\nibdos.obj	$(inc)\const2.obj  $(inc)\msdata.obj \
	     $(inc)\mstable.obj  $(dos)\msdisp.obj		     \
	     $(dos)\mscode.obj  $(inc)\msdosme.obj		     \
	     ifsflink.obj  makefile	ifsfunc.lnk
     link @ifsfunc.lnk

