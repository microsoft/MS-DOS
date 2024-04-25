#************************ Makefile for Display\LCD ************************

inc	=..\..\..\inc
msg	=..\..\..\message
dos	=..\..\..\dos
hinc	=..\..\..\h

#
######################### Dependencies Begin Here #########################
#

all: lcd.cpi

865-cpi.obj:  865-cpi.asm

860-cpi.obj:  860-cpi.asm

437-cpi.obj:  437-cpi.asm

863-cpi.obj:  863-cpi.asm

850-cpi.obj:  850-cpi.asm

copyrigh.obj: copyrigh.asm $(inc)\copyrigh.inc

font-r3.obj:  font-r3.asm

lcd.cpi:  font-r3.obj  437-cpi.obj  850-cpi.obj  860-cpi.obj  \
	  863-cpi.obj  865-cpi.obj  copyrigh.obj lcd.lnk makefile
		link @lcd.lnk
		exe2bin font-r3.exe lcd.cpi
		del font-r3.exe
