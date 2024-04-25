#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: print.com

print.ctl: print.skl $(msg)\$(COUNTRY).msg

print_r.obj: print_r.asm \
    pridefs.inc print.ctl \
    $(inc)\devsym.inc \
    $(inc)\syscall.inc \
    $(inc)\error.inc \
    $(inc)\sysvar.inc \
    $(inc)\find.inc \
    $(inc)\ea.inc

print_rm.obj: print_rm.asm \
    pridefs.asm print.ctl \
    $(inc)\parse.asm \
    $(inc)\psdata.inc

print_t.obj: print_t.asm \
    pridefs.asm \
    $(inc)\devsym.inc \
    $(inc)\syscall.inc \
    $(inc)\error.inc \
    $(inc)\sysvar.inc \
    $(inc)\find.inc

print_tm.obj: print_tm.asm \
    pridefs.asm print.ctl \
    $(inc)\parse.asm \
    $(inc)\psdata.inc \
    $(inc)\msgserv.asm \
    $(inc)\sysmsg.inc


print.com: print_r.obj \
    print_rm.obj \
    print_t.obj \
    print_tm.obj \
    print.cla
        link @print.lnk
        convert print.exe
        del print.exe
