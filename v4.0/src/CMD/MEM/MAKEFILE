#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h
lib     =..\..\lib

#
#######################	dependencies begin here. #########################
#

all: mem.exe


mem.ctl:        mem.skl                         \
                $(msg)\$(COUNTRY).msg makefile

_parse.obj:     _parse.asm                      \
                makefile                         \
                $(inc)\parse.asm                \
                $(inc)\psdata.inc

_msgret.obj:    _msgret.asm                     \
                makefile                         \
                mem.ctl                         \
                $(inc)\msgserv.asm              \
                $(inc)\sysmsg.inc

mem.obj:        mem.c                           \
                msgdef.h                        \
                $(hinc)\copyrigh.h

mem.exe:        mem.obj  _msgret.obj _parse.obj
                        link mem+_msgret+_parse,,,$(lib)\mem;


