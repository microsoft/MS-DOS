#************************ makefile for cmd\share *************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h
here	=..\cmd\share	  # This is the path from INC or MAP dir's to here.
make	=nmake -i

#
#######################	dependencies begin here. #########################
#

all: share.exe

msdos.cl1: $(dos)\msdos.skl           \
        $(msg)\$(COUNTRY).msg                  \
        $(dos)\makefile
        copy $(dos)\msdos.skl
        nosrvbld msdos.skl $(msg)\$(COUNTRY).msg


share.ctl: share.skl $(msg)\$(COUNTRY).msg

$(inc)\dossym.inc: $(inc)\dosmac.inc $(inc)\bpb.inc $(inc)\curdir.inc \
                   $(inc)\buffer.inc $(inc)\sysvar.inc $(inc)\vector.inc \
                   $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc \
                   $(inc)\cpmfcb.inc $(inc)\find.inc $(inc)\pdb.inc \
                   $(inc)\exe.inc $(inc)\sf.inc $(inc)\arena.inc \
                   $(inc)\intnat.inc $(inc)\mi.inc $(inc)\filemode.inc \
                   $(inc)\error.inc $(inc)\syscall.inc
	              	   echo " touch dossym.inc "

gshare.obj: gshare.asm $(inc)\dossym.inc $(inc)\mft.inc \
            $(inc)\bugtyp.asm

gshare2.obj: gshare2.asm $(inc)\dossym.inc $(inc)\dosseg.asm $(inc)\mft.inc \
             $(inc)\bugtyp.asm

sharesr.obj: sharesr.asm $(inc)\parse.asm $(inc)\psdata.inc

sharelnk.obj: sharelnk.asm

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

$(inc)\msdosme.obj:
	cd $(inc)
	$(make)
	cd $(here)

share.exe: share.ctl gshare.obj gshare2.obj sharesr.obj $(inc)\nibdos.obj \
           $(inc)\const2.obj $(inc)\msdata.obj $(inc)\msdosme.obj sharelnk.obj \
           share.lnk
           link @share.lnk
