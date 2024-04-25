#************************* makefile for cmd\join ************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h
map	=..\..\mapper
here	=..\cmd\join	  # This is the path from INC or MAP dir's to here.
make	=nmake -i

#
#######################	dependencies begin here. #########################
#

all: join.exe

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

join.ctl: join.skl      \
  $(msg)\$(COUNTRY).msg \
  makefile

_msgret.obj: _msgret.asm \
  $(inc)\msgserv.asm    \
  $(inc)\sysmsg.inc     \
  join.ctl              \
  join.cla              \
  join.cl1              \
  join.cl2              \
  join.skl

_parse.obj: _parse.asm  \
  $(inc)\parse.asm      \
  $(inc)\psdata.inc

join.obj: join.c        \
  makefile              \
  joinpars.h            \
  $(hinc)\cds.h          \
  $(hinc)\jointype.h     \
  $(hinc)\sysvar.h

join.exe: join.obj      \
  $(inc)\errtst.obj     \
  $(inc)\sysvar.obj     \
  $(inc)\cds.obj        \
  $(inc)\dpb.obj        \
  $(map)\mapper.lib     \
  $(inc)\comsubs.lib    \
  _msgret.obj           \
  _parse.obj		\
  join.lnk
    link @join.lnk
