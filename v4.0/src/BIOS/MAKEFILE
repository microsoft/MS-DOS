#************************** makefile for bios ***************************

dest	=io
msg	=..\messages
dos	=..\dos
inc	=..\inc
hinc	=..\h

#
#######################	dependencies begin here. #########################
#

all: $(dest).sys

msbio.cl1: msbio.skl \
	$(msg)\$(COUNTRY).msg

msload.obj: msload.asm \
	makefile \
	msbio.cl1 \
	$(inc)\bootform.inc \
	$(inc)\versiona.inc \
	msload.inc

msload.com: msload.obj
	link msload.obj,msload,,;
	exe2bin msload.exe msload.com

msbio1.obj: msbio1.asm \
	makefile \
   	msbdata.inc \
	msgroup.inc \
	jumpmac.inc \
	pushpop.inc \
	$(inc)\devsym.inc \
	msdskpr.inc \
	msmacro.inc

mscon.obj: mscon.asm \
	makefile \
	msgroup.inc \
	jumpmac.inc \
	msmacro.inc

msaux.obj: msaux.asm \
	makefile \
	msgroup.inc \
	jumpmac.inc \
	msmacro.inc

mslpt.obj: mslpt.asm \
	makefile \
	msgroup.inc \
	msequ.inc \
	$(inc)\msbds.inc \
	msmacro.inc \
	$(inc)\devsym.inc \
	$(inc)\ioctl.inc $(inc)\bpb.inc

msclock.obj: msclock.asm \
	makefile \
	msgroup.inc \
	msmacro.inc

msdisk.obj: msdisk.asm \
	makefile \
	msgroup.inc \
	msequ.inc \
	$(inc)\msbds.inc \
	pushpop.inc \
	msmacro.inc \
	$(inc)\devsym.inc \
	msdskpr.inc \
	msioctl.inc $(inc)\ioctl.inc $(inc)\bpb.inc

msinit.obj: msinit.asm \
	makefile \
	msgroup.inc \
	msdskpr.inc  \
	msequ.inc $(inc)\msbds.inc \
	$(inc)\cputype.inc \
	msmacro.inc   \
	readcloc.inc  \
	clocksub.inc   \
	msextrn.inc


sysinit1.obj: sysinit1.asm \
	makefile \
	msstack.inc \
	msbio.cl4 \
	msbio.cl5 \
	stkinit.inc \
	devmark.inc \
	$(inc)\smifssym.inc \
	$(inc)\devsym.inc \
	$(inc)\ioctl.inc \
	$(inc)\cputype.inc \
	$(inc)\smdossym.inc $(inc)\dosmac.inc $(inc)\bpb.inc $(inc)\buffer.inc \
	$(inc)\sysvar.inc $(inc)\vector.inc $(inc)\dirent.inc \
	$(inc)\dpb.inc $(inc)\curdir.inc \
	$(inc)\pdb.inc $(inc)\exe.inc $(inc)\sf.inc $(inc)\arena.inc \
	$(inc)\intnat.inc $(inc)\mi.inc \
	$(inc)\syscall.inc


sysconf.obj: sysconf.asm \
	makefile \
	psoption.inc \
	devmark.inc \
	$(inc)\psdata.inc \
	$(inc)\parse.asm \
	$(inc)\smifssym.inc \
	$(inc)\devsym.inc \
	$(inc)\ioctl.inc \
	$(inc)\smdossym.inc $(inc)\dosmac.inc $(inc)\bpb.inc $(inc)\buffer.inc \
	$(inc)\sysvar.inc $(inc)\vector.inc $(inc)\dirent.inc \
	$(inc)\dpb.inc $(inc)\curdir.inc \
	$(inc)\pdb.inc $(inc)\exe.inc $(inc)\sf.inc $(inc)\arena.inc \
	$(inc)\intnat.inc $(inc)\mi.inc \
	$(inc)\syscall.inc

sysinit2.obj: sysinit2.asm \
	makefile \
	devmark.inc \
	$(inc)\copyrigh.inc \
	$(inc)\smifssym.inc \
	$(inc)\devsym.inc \
	$(inc)\ioctl.inc \
	$(inc)\smdossym.inc $(inc)\dosmac.inc $(inc)\bpb.inc $(inc)\buffer.inc \
 	$(inc)\sysvar.inc $(inc)\vector.inc $(inc)\dirent.inc \
	$(inc)\dpb.inc $(inc)\curdir.inc \
	$(inc)\pdb.inc $(inc)\exe.inc $(inc)\sf.inc $(inc)\arena.inc \
	$(inc)\intnat.inc $(inc)\mi.inc \
	$(inc)\syscall.inc

sysimes.obj: sysimes.asm \
	makefile \
	msmacro.inc \
	msbio.cl3 \
	msequ.inc $(inc)\msbds.inc

msbio2.obj: msbio2.asm \
	makefile \
	msgroup.inc \
	msequ.inc \
	$(inc)\msbds.inc \
	$(inc)\devsym.inc \
	pushpop.inc \
	msmacro.inc \
	msbio.cl2 \
	ms96tpi.inc msvolid.inc

mshard.obj:  mshard.asm $(inc)\postequ.inc $(inc)\dseg.inc

$(dest).sys: msbio.cl1 msbio1.obj mscon.obj  msaux.obj \
	mslpt.obj msclock.obj msdisk.obj msbio2.obj \
	msinit.obj mshard.obj sysinit1.obj sysconf.obj \
	sysinit2.obj sysimes.obj \
	msload.com \
	makefile
	link @msbio.lnk
	exe2bin msbio.exe msbio.bin <locscr
	copy /b msload.com+msbio.bin $(dest).sys
	del msbio.bin
	del msbio.exe

