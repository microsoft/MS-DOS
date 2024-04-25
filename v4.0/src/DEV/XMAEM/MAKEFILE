#************************ makefile for dev\xmaem************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: xmaem.sys

xmaem.ctl:     xmaem.skl $(msg)\$(COUNTRY).msg makefile
		nosrvbld xmaem.skl $(msg)\$(COUNTRY).msg

INDEINI.obj:   INDEINI.ASM

INDEEMU.obj:   INDEEMU.ASM

INDEEXC.obj:   INDEEXC.ASM

INDEXMA.obj:   INDEXMA.ASM

INDEDMA.obj:   INDEDMA.ASM

INDEIDT.obj:   INDEIDT.ASM

INDEGDT.obj:   INDEGDT.ASM

INDEI15.obj:   INDEI15.ASM

INDEmsg.obj:   INDEmsg.ASM xmaem.ctl

INDEpat.obj:   INDEpat.ASM

xmaem.sys:  makefile			\
	    xmaem.ctl			\
	    INDEINI.obj 		\
	    INDEEMU.obj 		\
	    INDEEXC.obj 		\
	    INDEXMA.obj 		\
	    INDEDMA.obj 		\
	    INDEIDT.obj 		\
	    INDEGDT.obj 		\
	    INDEI15.obj 		\
	    indemaus.obj		\
	    indemsus.inc		\
	    indeovp.mac 		\
	    indeins.mac 		\
	    indedes.mac 		\
	    indemsg.obj 		\
	    indepat.obj 		\
	    indedat.inc 		\
	    indeacc.inc 		\
	    xmaem.lnk
	link @xmaem.lnk
