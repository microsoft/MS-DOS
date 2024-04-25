#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: graftabl.com

graftabl.ctl: graftabl.skl \
    $(msg)\$(COUNTRY).msg \
    makefile

grtab.obj: grtab.asm \
    makefile

grtabp.obj: grtabp.asm \
    makefile \
    $(inc)\psdata.inc \
    $(inc)\parse.asm

grtabsm.obj: grtabsm.asm \
    makefile \
    $(inc)\copyrigh.inc \
    $(inc)\versiona.inc \
    $(inc)\sysmsg.inc \
    $(inc)\msgserv.asm \
    graftabl.ctl \
    graftabl.cl1 \
    graftabl.cl2 \
    graftabl.cla \
    $(inc)\msghan.inc \
    grtabms.inc

grtabpar.obj: grtabpar.asm \
    makefile

grtabhan.obj: grtabhan.asm \
    makefile

grtabus.obj: grtabus.asm \
    makefile

grtabno.obj: grtabno.asm \
    makefile

grtabpo.obj: grtabpo.asm \
    makefile

grtabcf.obj: grtabcf.asm \
    makefile

grtabml.obj: grtabml.asm \
    makefile

graftabl.com: grtab.obj \
    makefile \
    graftabl.lnk \
    grtabp.obj \
    grtabsm.obj \
    grtabpar.obj \
    grtabhan.obj \
    grtabus.obj \
    grtabno.obj \
    grtabpo.obj \
    grtabcf.obj \
    grtabml.obj
	link @graftabl.lnk
	exe2bin graftabl.exe graftabl.com
	del graftabl.exe
