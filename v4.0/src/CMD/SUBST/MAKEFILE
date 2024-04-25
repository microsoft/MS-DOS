#************************ makefile for cmd\subst *************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h
map	=..\..\mapper
here	=..\cmd\subst	  # This is the path from INC or MAP dir's to here.
make	=nmake -i

#
#######################	dependencies begin here. #########################
#

all: subst.exe

$(inc)\errtst.obj:
	cd $(inc)
	$(make)
	cd $(here)

$(inc)\sysvar.obj:
	cd $(inc)
	$(make)
	cd $(here)

$(inc)\cds.obj:
	cd $(inc)
	$(make)
	cd $(here)

$(inc)\dpb.obj:
	cd $(inc)
	$(make)
	cd $(here)

$(inc)\comsubs.lib:
	cd $(inc)
	$(make)
	cd $(here)

$(map)\mapper.lib:
	cd $(map)
	$(make)
	cd $(here)

subst.ctl: subst.skl    \
  $(msg)\$(COUNTRY).msg \
  makefile

_msgret.obj: _msgret.asm \
  $(inc)\msgserv.asm    \
  $(inc)\sysmsg.inc     \
  subst.ctl             \
  subst.cla             \
  subst.cl1             \
  subst.cl2             \
  subst.skl

_parse.obj: _parse.asm  \
  $(inc)\parse.asm      \
  $(inc)\psdata.inc

subst.obj: subst.c      \
  makefile             \
  substpar.h            \
  $(hinc)\cds.h          \
  $(hinc)\jointype.h     \
  $(hinc)\sysvar.h

subst.exe: subst.obj    \
  $(inc)\cds.obj        \
  $(inc)\dpb.obj        \
  $(inc)\errtst.obj     \
  $(inc)\sysvar.obj     \
  $(map)\mapper.lib     \
  $(inc)\comsubs.lib    \
  _msgret.obj           \
  _parse.obj            \
  subst.lnk
    link @subst.lnk
