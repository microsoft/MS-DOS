#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

map	=..\..\mapper

all: replace.exe

replace.ctl: replace.skl \
  $(msg)\$(COUNTRY).msg  \
  makefile

_msgret.obj: _msgret.asm \
  $(inc)\msgserv.asm    \
  $(inc)\sysmsg.inc     \
  replace.ctl           \
  replace.cla           \
  replace.cl1           \
  replace.cl2           \
  replace.skl

_parse.obj: _parse.asm  \
  $(inc)\parse.asm      \
  $(inc)\psdata.inc

_replace.obj: _replace.asm

replace.obj: replace.c  \
  makefile           \
  replacep.h            \
  $(hinc)\comsub.h

replace.exe: replace.obj \
  _replace.obj          \
  $(map)\mapper.lib     \
  $(inc)\comsubs.lib    \
  _msgret.obj           \
  _parse.obj            \
  replace.lnk
    link @replace.lnk
