#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: filesys.exe

filesys.ctl:    filesys.skl             \
                $(msg)\$(COUNTRY).msg   \
                makefile

_msgret.obj:    _msgret.asm             \
                filesys.ctl             \
                makefile                \
                $(inc)\msgserv.asm      \
                $(inc)\sysmsg.inc

_parse.obj:     _parse.asm              \
                makefile                \
                $(inc)\PARSE.ASM        \
                $(inc)\PSDATA.INC

filesys.obj:    filesys.c parse.h

filesys.exe:    filesys.obj             \
                _parse.obj              \
                _msgret.obj
        link filesys+ _parse+ _msgret; /NOI

