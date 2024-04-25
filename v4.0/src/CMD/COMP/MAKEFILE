#************************* makefile for cmd\comp *************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: comp.com

comp.ctl: comp.skl \
    $(msg)\$(COUNTRY).msg \

comp1.obj: comp1.asm \
    makefile

comppar.obj: comppar.asm \
    compeq.inc \
    makefile

compp.obj: compp.asm \
    $(inc)\parse.asm \
    makefile

compsm.obj: compsm.asm \
    $(inc)\copyrigh.inc \
    $(inc)\versiona.inc \
    $(inc)\sysmsg.inc \
    $(inc)\msghan.inc \
    comp.ctl \
    comp.cl1 \
    comp.cl2 \
    comp.cla \
    compms.inc \
    makefile

comp2.obj: comp2.asm \
    compeq.inc \
    makefile

comp.com: comp1.obj \
   comp.lnk \
   comppar.obj \
   compp.obj \
   compsm.obj \
   comp2.obj
        link @comp.lnk
        exe2bin comp.exe comp.com
        del comp.exe
