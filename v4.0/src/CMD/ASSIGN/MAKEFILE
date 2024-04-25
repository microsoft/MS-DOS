#************************** makefile for cmd\assign ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: assign.com

assign.ctl: assign.skl \
	$(msg)\$(COUNTRY).msg \
	makefile

assgparm.obj: assgparm.asm \
	$(inc)\psdata.inc \
	$(inc)\parse.asm \
	makefile

assgmain.obj: assgmain.asm \
	$(inc)\dosmac.inc \
	$(inc)\sysvar.inc \
	$(inc)\mult.inc \
	$(inc)\pdb.inc \
	$(inc)\syscall.inc \
	$(inc)\msgserv.asm \
	$(inc)\sysmsg.inc \
	assgparm.inc \
	assgmsg.inc \
	assign.ctl \
	assign.cla \
	assign.cl1 \
	assign.cl2 \
	$(inc)\curdir.inc \
	makefile

assign.com: assgmain.obj assgparm.obj
	link assgmain.obj+assgparm.obj,assign,,;
	exe2bin assign.exe  assign.com
	del assign.exe
