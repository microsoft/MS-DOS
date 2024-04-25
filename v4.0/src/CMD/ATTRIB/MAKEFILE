#************************** makefile for cmd\append ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: attrib.exe

attrib.ctl: attrib.skl \
	$(msg)\$(COUNTRY).msg \
	makefile

_parse.obj: _parse.asm \
	$(inc)\parse.asm \
	$(inc)\psdata.inc

_msgret.obj: _msgret.asm \
	$(inc)\msgserv.asm \
	$(inc)\sysmsg.inc  \
	$(inc)\copyrigh.inc \
	attrib.skl \
	attrib.ctl \
	attrib.cl1 \
	attrib.cl2 \
	attrib.cla \
	attrib.clb

attriba.obj: attriba.asm

attrib.obj: attrib.c \
	attrib.h \
	parse.h \
	msgret.h \
	makefile

attrib.exe: attrib.obj \
            attriba.obj \
            _parse.obj \
            _msgret.obj \
            attrib.lnk
      link @attrib.lnk
