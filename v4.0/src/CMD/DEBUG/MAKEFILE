#************************** makefile for cmd\append ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: debug.com

debug.ctl: debug.skl   \
                $(msg)\$(COUNTRY).msg          \
                makefile

debug.obj:      debug.asm $(inc)\dossym.inc $(inc)\dosmac.inc \
                $(inc)\bpb.inc $(inc)\buffer.inc $(inc)\sysvar.inc \
                $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc \
                $(inc)\curdir.inc $(inc)\cpmfcb.inc $(inc)\find.inc \
                $(inc)\pdb.inc $(inc)\sf.inc \
                $(inc)\arena.inc $(inc)\intnat.inc \
                $(inc)\error.inc $(inc)\syscall.inc debequ.asm makefile

debcom1.obj:    debcom1.asm $(inc)\dossym.inc $(inc)\dosmac.inc \
                $(inc)\bpb.inc $(inc)\buffer.inc $(inc)\sysvar.inc \
                $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc \
                $(inc)\curdir.inc $(inc)\cpmfcb.inc $(inc)\find.inc \
                $(inc)\pdb.inc $(inc)\sf.inc \
                $(inc)\arena.inc $(inc)\intnat.inc \
                $(inc)\error.inc $(inc)\syscall.inc debequ.asm makefile

debcom2.obj:    debcom2.asm $(inc)\dossym.inc $(inc)\dosmac.inc \
                $(inc)\bpb.inc $(inc)\buffer.inc $(inc)\sysvar.inc \
                $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc \
                $(inc)\curdir.inc $(inc)\cpmfcb.inc $(inc)\find.inc \
                $(inc)\pdb.inc $(inc)\sf.inc \
                $(inc)\arena.inc $(inc)\intnat.inc \
                $(inc)\error.inc $(inc)\syscall.inc debequ.asm makefile

debcom3.obj:    debcom3.asm $(inc)\dossym.inc $(inc)\dosmac.inc \
                $(inc)\bpb.inc $(inc)\buffer.inc $(inc)\sysvar.inc \
                $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc \
                $(inc)\curdir.inc $(inc)\cpmfcb.inc $(inc)\find.inc \
                $(inc)\pdb.inc $(inc)\sf.inc \
                $(inc)\arena.inc $(inc)\intnat.inc \
                $(inc)\error.inc $(inc)\syscall.inc debequ.asm makefile

debasm.obj:     debasm.asm $(inc)\dossym.inc $(inc)\dosmac.inc \
                $(inc)\bpb.inc $(inc)\buffer.inc $(inc)\sysvar.inc \
                $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc \
                $(inc)\curdir.inc $(inc)\cpmfcb.inc $(inc)\find.inc \
                $(inc)\pdb.inc $(inc)\sf.inc \
                $(inc)\arena.inc $(inc)\intnat.inc \
                $(inc)\error.inc $(inc)\syscall.inc debequ.asm makefile

debuasm.obj:    debuasm.asm $(inc)\dossym.inc $(inc)\dosmac.inc \
                $(inc)\bpb.inc $(inc)\buffer.inc $(inc)\sysvar.inc \
                $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc \
                $(inc)\curdir.inc $(inc)\cpmfcb.inc $(inc)\find.inc \
                $(inc)\pdb.inc $(inc)\sf.inc \
                $(inc)\arena.inc $(inc)\intnat.inc \
                $(inc)\error.inc $(inc)\syscall.inc debequ.asm makefile

deberr.obj:     deberr.asm $(inc)\dossym.inc $(inc)\dosmac.inc \
                $(inc)\bpb.inc $(inc)\buffer.inc $(inc)\sysvar.inc \
                $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc \
                $(inc)\curdir.inc $(inc)\cpmfcb.inc $(inc)\find.inc \
                $(inc)\pdb.inc $(inc)\sf.inc \
                $(inc)\arena.inc $(inc)\intnat.inc \
                $(inc)\error.inc $(inc)\syscall.inc debequ.asm makefile

debconst.obj:   debconst.asm $(inc)\dossym.inc $(inc)\dosmac.inc \
                $(inc)\bpb.inc $(inc)\buffer.inc $(inc)\sysvar.inc \
                $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc \
                $(inc)\curdir.inc $(inc)\cpmfcb.inc $(inc)\find.inc \
                $(inc)\pdb.inc $(inc)\sf.inc \
                $(inc)\arena.inc $(inc)\intnat.inc \
                $(inc)\error.inc $(inc)\syscall.inc debequ.asm makefile

debdata.obj:    debdata.asm $(inc)\dossym.inc $(inc)\dosmac.inc \
                $(inc)\bpb.inc $(inc)\buffer.inc $(inc)\sysvar.inc \
                $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc \
                $(inc)\curdir.inc $(inc)\cpmfcb.inc $(inc)\find.inc \
                $(inc)\pdb.inc $(inc)\sf.inc \
                $(inc)\arena.inc $(inc)\intnat.inc \
                $(inc)\error.inc $(inc)\syscall.inc debequ.asm makefile

debems.obj:     debems.asm debequ.asm makefile

debmes.obj:     debmes.asm $(inc)\msgserv.asm $(inc)\sysmsg.inc \
        debug.ctl \
        debug.cla \
        debug.clb \
        debug.clc \
        debug.cld \
        debug.cl1 \
        debug.cl2 \
        makefile

debug.com:      debug.obj debcom1.obj debcom2.obj debcom3.obj debems.obj \
                debasm.obj debuasm.obj deberr.obj debconst.obj debdata.obj \
                debmes.obj debug.lnk makefile
        link @debug.lnk
        convert debug.exe
        del debug.exe
