#************************* Makefile for Printer ***************************

inc	=..\..\inc
msg	=..\..\messages
dos	=..\..\dos
hinc	=..\..\h
make	=nmake

#
######################## Dependencies Begin Here ##########################
#

all: printer.sys 5202.cpi

printer.ctl:	printer.skl $(msg)\$(COUNTRY).msg

cpspm10.obj:	cpspm10.asm cpspequ.inc

cpsfont3.obj:	cpsfont3.asm cpspequ.inc

prtint2f.obj:	prtint2f.asm cpspequ.inc $(inc)\struc.inc

cpspi07.obj:	cpspi07.asm cpspequ.inc \
		$(inc)\sysmsg.inc printer.ctl \
		$(inc)\versiona.inc

parser.obj:	parser.asm cpspequ.inc $(inc)\parse.asm \
		$(inc)\struc.inc

printer.sys:	cpspm10.obj cpsfont3.obj parser.obj cpspi07.obj prtint2f.obj
	link	@printer.lnk
	exe2bin printer.exe printer.sys < zero.dat
	del	printer.exe

5202.cpi:
	cd 5202
	$(make)
	cd ..


