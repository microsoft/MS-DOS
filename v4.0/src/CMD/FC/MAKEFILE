#**     makefile for fc

DEST	=fc
MSG	=messages

#	Path Definitions

BIOS	=..\..\BIOS
BOOT	=..\..\BOOT
dos	=..\..\DOS
inc	=..\..\INC
hinc	=..\..\h
H	=..\..\H

#	List of object files required

OBJ	= fc.obj \
	  error.obj \
	  fgetl.obj \
	  getl.obj \
	  itoupper.obj \
	  $(inc)\kstring.obj \
	  maxmin.obj \
	  move.obj \
	  ntoi.obj \
	  string.obj \
	  update.obj \
	  xtab.obj \
	  messages.obj

#       Rules and Dependencies follow

all:	$(DEST).exe

$(inc)\printf.obj: $(inc)\printf.asm

$(inc)\kstring.obj: $(inc)\kstring.c $(hinc)\internat.h

getl.obj: getl.asm $(inc)\cmacros.inc $(inc)\version.inc

itoupper.obj: itoupper.asm  $(inc)\cmacros.inc $(inc)\version.inc

maxmin.obj: maxmin.asm $(inc)\cmacros.inc $(inc)\version.inc

$(MSG).obj: $(MSG).asm

move.obj: move.asm $(inc)\cmacros.inc $(inc)\version.inc

string.obj: string.asm $(inc)\cmacros.inc $(inc)\version.inc

xtab.obj: xtab.asm $(inc)\cmacros.inc $(inc)\version.inc

error.obj: error.c tools.h ttypes.h

$(DEST).obj: $(DEST).c $(DEST).h tools.h ttypes.h

fgetl.obj: fgetl.c tools.h ttypes.h

ntoi.obj: ntoi.c tools.h ttypes.h

update.obj: update.c tools.h ttypes.h

$(DEST).exe: $(OBJ) $(DEST).lnk
	$(link) @$(DEST).lnk;
