#*************************** Makefile for DOS ***************************

msg	=..\messages
inc	=..\inc
hinc	=..\hinc
make	=nmake -i
dos	=.

#
###################### Dependencies begin here ##########################
#

all: msdos.sys

msdos.cl1: msdos.skl \
	$(msg)\$(COUNTRY).msg 

dossym.inc: $(inc)\dosmac.inc $(inc)\bpb.inc \
    $(inc)\buffer.inc $(inc)\sysvar.inc $(inc)\vector.inc \
    $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc $(inc)\curdir.inc \
    $(inc)\cpmfcb.inc $(inc)\find.inc $(inc)\pdb.inc $(inc)\exe.inc \
    $(inc)\sf.inc $(inc)\arena.inc $(inc)\intnat.inc $(inc)\mi.inc \
    $(inc)\filemode.inc $(inc)\error.inc $(inc)\syscall.inc
	echo "touch dossym.inc; files that are in ..\inc"

$(inc)\nibdos.obj: 
	cd ..\inc
	$(make)
	cd ..\dos		   

$(inc)\const2.obj: 
	cd ..\inc
	$(make)
	cd ..\dos	   

$(inc)\msdata.obj: 
	cd ..\inc
	$(make)
	cd ..\dos	   
		   
$(inc)\mstable.obj:
	cd ..\inc
	$(make)
	cd ..\dos	   
		   
$(inc)\msdosme.obj:
	cd ..\inc
	$(make)
	cd ..\dos

msdisp.obj: msdisp.asm mssw.asm disp.asm \
	     $(inc)\dossym.inc $(inc)\dosseg.asm

mscode.obj: mscode.asm mssw.asm ms_code.asm \
	     $(inc)\dossym.inc $(inc)\dosseg.asm $(inc)\devsym.inc

time.obj: time.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
	  $(inc)\devsym.inc

getset.obj: getset.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

parse.obj: parse.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

misc.obj: misc.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\bugtyp.asm

misc2.obj: misc2.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\bugtyp.asm

crit.obj: crit.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\bugtyp.asm

cpmio.obj: cpmio.asm $(inc)\dosseg.asm \
    $(inc)\dossym.inc \
    $(inc)\devsym.inc \
    kstrin.asm strin.asm

cpmio2.obj: cpmio2.asm $(inc)\dosseg.asm \
    $(inc)\dossym.inc $(inc)\devsym.inc

fcbio.obj: fcbio.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\sf.inc $(inc)\fastopen.inc

fcbio2.obj: fcbio2.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

search.obj: search.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

path.obj: path.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

ioctl.obj: ioctl.asm $(inc)\ioctl.inc $(inc)\dosseg.asm \
    $(inc)\dossym.inc $(inc)\devsym.inc

delete.obj: delete.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\sf.inc $(inc)\fastxxxx.inc $(inc)\fastopen.inc

rename.obj: rename.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\sf.inc

finfo.obj: finfo.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

dup.obj: dup.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

create.obj: create.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

open.obj: open.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\fastopen.inc

dinfo.obj: dinfo.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
   $(inc)\devsym.inc $(inc)\bugtyp.asm $(inc)\buffer.inc

isearch.obj: isearch.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

abort.obj: abort.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\sf.inc

close.obj: close.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\buffer.inc

dircall.obj: dircall.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\buffer.inc $(inc)\fastopen.inc

disk.obj: disk.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

disk2.obj: disk2.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\buffer.inc

disk3.obj: disk3.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

dir.obj: dir.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
	 $(inc)\buffer.inc $(inc)\fastopen.inc

dir2.obj: dir2.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
	  $(inc)\buffer.inc $(inc)\fastopen.inc

dev.obj: dev.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

mknode.obj: mknode.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc  $(inc)\buffer.inc $(inc)\fastopen.inc \
    $(inc)\filemode.inc

rom.obj: rom.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc  $(inc)\buffer.inc

fcb.obj: fcb.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

msctrlc.obj: msctrlc.asm mssw.asm ctrlc.asm \
    $(inc)\dosseg.asm $(inc)\dossym.inc $(inc)\devsym.inc \
    $(inc)\bugtyp.asm

fat.obj: fat.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\buffer.inc $(inc)\curdir.inc

buf.obj: buf.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\buffer.inc

proc.obj: proc.asm \
    $(inc)\dosseg.asm $(inc)\dossym.inc $(inc)\devsym.inc \
    $(inc)\curdir.inc \
    exec.asm

alloc.obj: alloc.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

srvcall.obj: srvcall.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

util.obj: util.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

macro.obj: macro.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc  $(inc)\curdir.inc

macro2.obj: macro2.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\curdir.inc

handle.obj: handle.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\bugtyp.asm

file.obj: file.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\bugtyp.asm $(inc)\fastopen.inc \
    $(inc)\filemode.inc

lock.obj: lock.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

share.obj: share.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc

extattr.obj: extattr.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\ea.inc $(inc)\buffer.inc

ifs.obj: ifs.asm $(inc)\dosseg.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc $(inc)\doscntry.inc $(inc)\buffer.inc

msdos.sys: msdos.cl1 $(inc)\nibdos.obj $(inc)\const2.obj  \
    $(inc)\msdata.obj mscode.obj $(inc)\msdosme.obj time.obj getset.obj \
    parse.obj misc.obj misc2.obj crit.obj cpmio.obj cpmio2.obj \
    $(inc)\mstable.obj msdisp.obj fcbio.obj fcbio2.obj \
    search.obj path.obj ioctl.obj delete.obj rename.obj finfo.obj \
    dup.obj create.obj open.obj dinfo.obj isearch.obj buf.obj \
    abort.obj close.obj dircall.obj disk.obj disk2.obj disk3.obj dir.obj \
    dir2.obj dev.obj mknode.obj rom.obj fcb.obj msctrlc.obj fat.obj \
    proc.obj alloc.obj srvcall.obj util.obj macro.obj macro2.obj ifs.obj \
    handle.obj file.obj lock.obj share.obj extattr.obj \
    makefile msdos.lnk
	link @msdos.lnk
	exe2bin msdos.exe msdos.sys
	del msdos.exe
