#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: exe2bin.exe

exe2bin.ctl : exe2bin.skl makefile \
              $(msg)\$(COUNTRY).msg

e2binit.obj : e2binit.asm  $(inc)\syscall.inc e2bparse.inc  e2bmacro.inc \
              e2bequ.inc  $(inc)\sysmsg.inc  e2btable.inc  exe2bin.ctl   \
              locate.asm $(inc)\dossym.inc $(inc)\dosmac.inc \
              $(inc)\bpb.inc $(inc)\buffer.inc $(inc)\sysvar.inc \
              $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc \
              $(inc)\curdir.inc $(inc)\cpmfcb.inc $(inc)\find.inc \
              $(inc)\pdb.inc $(inc)\sf.inc $(inc)\arena.inc $(inc)\intnat.inc \
              $(inc)\error.inc $(inc)\syscall.inc $(inc)\parse.asm \
              $(inc)\psdata.inc makefile

display.obj : display.asm makefile

exe2bin.exe : display.obj e2binit.obj exe2bin.ctl makefile exe2bin.lnk
         link @exe2bin.lnk
