#************************* Makefile for Display ***************************

inc	=..\..\inc
msg	=..\..\messages
dos	=..\..\dos
hinc	=..\..\h
make	=nmake

#
######################## Dependencies Begin Here ##########################

all: display.sys ega.cpi lcd.cpi

display.ctl:    display.skl $(msg)\$(COUNTRY).msg

display.obj: display.asm makefile \
        macros.inc  \
        def-equ.inc \
        int2fcom.inc \
        int10com.inc \
        cps-func.inc \
        write.inc    \
        f-parser.inc

init.obj: init.asm makefile \
          macros.inc \
          def-equ.inc \
          $(inc)\sysmsg.inc \
          $(inc)\versiona.inc \
          display.ctl \
          tables.inc

parser.obj: parser.asm makefile \
        def-equ.inc  \
        $(inc)\struc.inc \
        $(inc)\parse.asm

display.sys: display.obj init.obj parser.obj display.lnk makefile zero.dat
        link @display.lnk
        exe2bin display.exe display.sys < zero.dat
        del display.exe

ega.cpi:
	cd ega
	$(make)
	cd ..

lcd.cpi:
	cd lcd
	$(make)
	cd ..


