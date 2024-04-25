#************************ Makefile for Country.sys ************************

dos	=..\..\dos
lib	=..\..\lib
inc	=..\..\inc

#
######################## Dependencies begin here ##########################
#

all: country.sys

mkcntry.obj: mkcntry.asm mkcntry.inc

mkcntry.exe: mkcntry.obj
	link mkcntry;

country.sys: mkcntry.exe
	mkcntry
