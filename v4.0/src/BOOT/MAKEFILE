#******************** makefile for boot *****************************

msg	=..\messages
dos	=..\dos
inc	=..\inc
hinc	=..\h

#
#################### dependencies begin here ############################
#

all: msboot.bin

boot.cl1: boot.skl \
	$(msg)\$(COUNTRY).MSG \
	makefile

msboot.obj: msboot.asm boot.cl1

msboot.bin: msboot.obj
	link msboot;
	exe2bin msboot.exe msboot.bin
	dbof msboot.bin boot.inc 7c00 200
	copy boot.inc $(inc)
	del boot.inc
