#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: tree.com

tree.ctl: tree.skl \
    $(msg)\$(COUNTRY).msg \
    makefile

tree.obj: tree.asm \
    makefile \
    treequ.inc

treesysp.obj: treesysp.asm \
    makefile \
    $(inc)\psdata.inc \
    $(inc)\parse.asm

treesysm.obj: treesysm.asm \
    makefile \
    $(inc)\copyrigh.inc \
    $(inc)\versiona.inc \
    $(inc)\sysmsg.inc \
    $(inc)\msgserv.asm \
    tree.ctl \
    tree.cl1 \
    tree.cl2 \
    tree.cla \
    $(inc)\msghan.inc \
    treems.inc

treepar.obj: treepar.asm \
    makefile

tree.com: tree.obj \
    makefile \
    tree.lnk \
    treesysp.obj \
    treesysm.obj \
    treepar.obj
	link @tree.lnk
	exe2bin tree.exe tree.com
	del tree.exe
