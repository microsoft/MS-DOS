#*********************** Makefile for Display\EGA ************************

inc	=..\..\..\inc
dos	=..\..\..\dos
msg	=..\..\..\messages
hinc	=..\..\..\h

#
######################## Dependencies begin here #########################
#

all: ega.cpi

cpi-head.obj: cpi-head.asm \
              makefile

437-cpi.obj: 437-cpi.asm \
             437-8x16.asm \
             437-8x14.asm \
             makefile      \
             437-8x8.asm

850-cpi.obj: 850-cpi.asm \
             850-8x16.asm \
             850-8x14.asm \
             makefile      \
             850-8x8.asm

860-cpi.obj: 860-cpi.asm \
             860-8x16.asm \
             860-8x14.asm \
             makefile      \
             860-8x8.asm

863-cpi.obj: 863-cpi.asm \
             863-8x16.asm \
             863-8x14.asm \
             makefile      \
             863-8x8.asm

865-cpi.obj: 865-cpi.asm \
             865-8x16.asm \
             865-8x14.asm \
             makefile      \
             865-8x8.asm

copyrigh.obj: copyrigh.asm  $(inc)\copyrigh.inc \
              makefile

ega.cpi: cpi-head.obj 437-cpi.obj 850-cpi.obj 860-cpi.obj \
         863-cpi.obj 865-cpi.obj copyrigh.obj makefile ega.lnk \
         makefile
	       link @ega.lnk
	       exe2bin cpi-head.exe ega.cpi
	       del   cpi-head.exe
