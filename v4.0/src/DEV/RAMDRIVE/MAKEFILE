#**     makefile for Ramdrive

DEST	= ramdrive
MSG	= messages

#       Definitions for assembler

ASM	= masm
AFLAGS	= -Mx -t
AINC	= -I../../inc

#       Definitions for C compiler

CC	= cl
CFLAGS	= -Ox -X -Zlp
CINC	= -I../../h

#	Definitions for linker

LINK	= link

# Dependencies follow

all: ramdrive.sys

ramdrive.obj: ramdrive.asm above.inc loadall.inc emm.inc mi.inc \
	 dirent.inc syscall.inc devsym.inc
	masm $(AFLAGS) $(AINC) ramdrive;

messages.obj:  messages.asm
	masm $(AFLAGS) $(AINC) messages;

ramdrive.sys: ramdrive.obj messages.obj
	link @ramdrive.lnk
	exe2bin ramdrive ramdrive.sys
	del ramdrive.exe
