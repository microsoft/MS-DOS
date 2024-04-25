#************************** makefile for cmd\append ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: edlin.com

edlin.ctl:      edlin.skl   \
                $(msg)\$(COUNTRY).msg    \
                makefile


edlin.obj:      edlin.asm edlequ.asm edlstdsw.inc makefile  \
                $(inc)\dossym.inc \
                $(inc)\dosmac.inc $(inc)\bpb.inc $(inc)\buffer.inc \
                $(inc)\sysvar.inc $(inc)\mult.inc $(inc)\dirent.inc \
                $(inc)\dpb.inc $(inc)\curdir.inc $(inc)\cpmfcb.inc \
                $(inc)\find.inc $(inc)\pdb.inc $(inc)\sf.inc $(inc)\arena.inc \
                $(inc)\intnat.inc $(inc)\error.inc $(inc)\syscall.inc

edlcmd1.obj:    edlcmd1.asm edlequ.asm edlstdsw.inc makefile  \
                $(inc)\dossym.inc \
                $(inc)\dosmac.inc $(inc)\bpb.inc $(inc)\buffer.inc \
                $(inc)\sysvar.inc $(inc)\mult.inc $(inc)\dirent.inc \
                $(inc)\dpb.inc $(inc)\curdir.inc $(inc)\cpmfcb.inc \
                $(inc)\find.inc $(inc)\pdb.inc $(inc)\sf.inc $(inc)\arena.inc \
                $(inc)\intnat.inc $(inc)\error.inc $(inc)\syscall.inc

edlcmd2.obj:    edlcmd2.asm edlequ.asm edlstdsw.inc makefile  \
                $(inc)\dossym.inc \
                $(inc)\dosmac.inc $(inc)\bpb.inc $(inc)\buffer.inc \
                $(inc)\sysvar.inc $(inc)\mult.inc $(inc)\dirent.inc \
                $(inc)\dpb.inc $(inc)\curdir.inc $(inc)\cpmfcb.inc \
                $(inc)\find.inc $(inc)\pdb.inc $(inc)\sf.inc $(inc)\arena.inc \
                $(inc)\intnat.inc $(inc)\error.inc $(inc)\syscall.inc

edlmes.obj:     edlmes.asm $(inc)\sysmsg.inc  makefile  \
                edlin.ctl \
                edlin.cla \
                edlin.clb \
                edlin.cl1 \
                edlin.cl2 \

edlparse.obj:   edlparse.asm $(inc)\parse.asm  makefile

edlin.com:      edlin.obj edlcmd1.obj edlcmd2.obj edlmes.obj edlparse.obj \
                edlin.lnk  makefile
        link @edlin.lnk
        convert edlin.exe
        del edlin.exe
