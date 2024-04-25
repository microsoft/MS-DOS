#************************** makefile for cmd\append ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: command.com

$(inc)\dossym.inc: $(inc)\dosmac.inc $(inc)\bpb.inc \
    $(inc)\buffer.inc $(inc)\sysvar.inc $(inc)\vector.inc \
    $(inc)\mult.inc $(inc)\dirent.inc $(inc)\dpb.inc $(inc)\curdir.inc \
    $(inc)\cpmfcb.inc $(inc)\find.inc $(inc)\pdb.inc $(inc)\exe.inc \
    $(inc)\sf.inc $(inc)\arena.inc $(inc)\intnat.inc $(inc)\mi.inc \
    $(inc)\filemode.inc $(inc)\error.inc $(inc)\syscall.inc
	echo "touch $(inc)\dossym.inc"

command.ctl: command.skl $(msg)\$(COUNTRY).msg makefile

command1.obj:  command1.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc comsw.asm comequ.asm resmsg.equ \
    envdata.asm

command2.obj:  command2.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc comsw.asm comequ.asm resmsg.equ \
    envdata.asm

copy.obj:  copy.asm comsw.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm

copypr1.obj:  copypr1.asm comsw.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm

copypr2.obj:  copypr2.asm comsw.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm

cparse.obj:  cparse.asm comsw.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm

init.obj:  init.asm $(inc)\dossym.inc $(inc)\devsym.inc \
    comsw.asm comseg.asm comequ.asm resmsg.equ $(inc)\sysmsg.inc \
    $(inc)\msgserv.asm command.ctl

iparse.obj:  iparse.asm comseg.asm $(inc)\parse.asm $(inc)\psdata.inc

parse2.obj:  parse2.asm $(inc)\dossym.inc $(inc)\devsym.inc comsw.asm \
    comseg.asm comequ.asm

path1.obj:  path1.asm $(inc)\dossym.inc $(inc)\devsym.inc comsw.asm \
    comseg.asm comequ.asm

path2.obj:  path2.asm $(inc)\dossym.inc $(inc)\devsym.inc comsw.asm \
    comseg.asm comequ.asm

rdata.obj:  rdata.asm comsw.asm comseg.asm $(inc)\sysmsg.inc \
    $(inc)\msgserv.asm command.cla command.cl3 command.cl4 \
    command.cld command.clc command.cle command.ctl

rucode.obj:  rucode.asm $(inc)\dossym.inc $(inc)\devsym.inc \
    $(inc)\doscntry.inc resmsg.equ $(inc)\sysmsg.inc \
    $(inc)\msgserv.asm comsw.asm comseg.asm comequ.asm command.ctl

tbatch.obj:  tbatch.asm comsw.asm $(inc)\dossym.inc $(inc)\doscntry.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm ifequ.asm

tbatch2.obj:  tbatch2.asm comsw.asm $(inc)\dossym.inc $(inc)\doscntry.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm ifequ.asm

tcmd1a.obj:  tcmd1a.asm comsw.asm $(inc)\dossym.inc $(inc)\ioctl.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm ifequ.asm

tcmd1b.obj:  tcmd1b.asm comsw.asm $(inc)\dossym.inc $(inc)\ioctl.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm ifequ.asm $(inc)\ea.inc

tcmd2a.obj:  tcmd2a.asm comsw.asm $(inc)\dossym.inc $(inc)\ioctl.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm ifequ.asm

tcmd2b.obj:  tcmd2b.asm comsw.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm ifequ.asm

tcode.obj:  tcode.asm comsw.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm ifequ.asm \
    $(inc)\mshalo.asm

tdata.obj:  tdata.asm comsw.asm comseg.asm $(inc)\curdir.inc \
    $(inc)\error.inc ifequ.asm comequ.asm $(inc)\sysmsg.inc \
    $(inc)\msgserv.asm tranmsg.asm command.clf command.cl1 command.cl2 \
    command.ctl  $(inc)\ea.inc

tenv.obj:  tenv.asm comsw.asm $(inc)\dossym.inc $(inc)\devsym.inc \
    comseg.asm comequ.asm ifequ.asm $(inc)\doscntry.inc

tenv2.obj:  tenv2.asm comsw.asm $(inc)\dossym.inc $(inc)\devsym.inc \
    comseg.asm comequ.asm ifequ.asm

tfor.obj:  tfor.asm comsw.asm $(inc)\dossym.inc $(inc)\devsym.inc \
    comseg.asm comequ.asm ifequ.asm fordata.asm

tmisc1.obj:  tmisc1.asm comsw.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm ifequ.asm

tmisc2.obj:  tmisc2.asm comsw.asm $(inc)\dossym.inc $(inc)\ioctl.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm ifequ.asm

tparse.obj:  tparse.asm comseg.asm $(inc)\parse.asm $(inc)\psdata.inc

tpipe.obj:  tpipe.asm comsw.asm $(inc)\dossym.inc \
    $(inc)\devsym.inc comseg.asm comequ.asm ifequ.asm

tprintf.obj:  tprintf.asm comsw.asm $(inc)\dosmac.inc \
    comseg.asm comequ.asm $(inc)\sysmsg.inc $(inc)\msgserv.asm \
    command.ctl

tspc.obj:  tspc.asm comsw.asm $(inc)\dossym.inc comequ.asm \
    ifequ.asm comseg.asm  $(inc)\ea.inc

tucode.obj:  tucode.asm $(inc)\dosmac.inc $(inc)\dossym.inc \
    comsw.asm comseg.asm comequ.asm ifequ.asm

uinit.obj:  uinit.asm comsw.asm comseg.asm ifequ.asm command.clb \
    $(inc)\sysmsg.inc $(inc)\msgserv.asm command.ctl

command.com:  command1.obj command2.obj rucode.obj rdata.obj init.obj iparse.obj \
    uinit.obj tcode.obj tbatch.obj tbatch2.obj tfor.obj tcmd1a.obj tcmd1b.obj \
    tcmd2a.obj tcmd2b.obj tenv.obj tenv2.obj tmisc1.obj tmisc2.obj tpipe.obj \
    parse2.obj path1.obj path2.obj tucode.obj copy.obj copypr1.obj copypr2.obj \
    cparse.obj tparse.obj tprintf.obj tdata.obj tspc.obj
	link @command.lnk
	exe2bin command.exe command.com
	del command.exe
