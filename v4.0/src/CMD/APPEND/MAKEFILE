#************************** makefile for cmd\append ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: append.exe

append.ctl: append.skl $(msg)\$(COUNTRY).msg

append.obj: append.asm appendp.inc $(inc)\parse.asm append.ctl

append.exe: append.obj
        link append;

