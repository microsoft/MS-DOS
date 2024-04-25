COM=G:\COMMON
MSG=G:\MESSAGES

#

xmaem.cl1:	xmaem.skl	\
		$(MSG)\$(country).MSG	\
		xmaem.mak
	nosrvbld xmaem.skl $(MSG)\$(country).msg

INDEINI.obj:   INDEINI.ASM
	asm87  INDEINI

INDEEMU.obj:   INDEEMU.ASM
	asm87  INDEEMU

INDEEXC.obj:   INDEEXC.ASM
	asm87  INDEEXC

INDEXMA.obj:   INDEXMA.ASM
	asm87  INDEXMA

INDEDMA.obj:   INDEDMA.ASM
	asm87  INDEDMA

INDEIDT.obj:   INDEIDT.ASM
	asm87  INDEIDT

INDEGDT.obj:   INDEGDT.ASM
	asm87  INDEGDT

INDEI15.obj:   INDEI15.ASM
	asm87  INDEI15

INDEmsg.obj:   INDEmsg.ASM	\
	       xmaem.cl1
	asm87  INDEmsg

INDEpat.obj:   INDEpat.ASM
	asm87  INDEpat


xmaem.sys:  g:\common\setver.bat	\
	    XMAEM.MAK			\
	    INDEINI.asm 		\
	    INDEEMU.asm 		\
	    INDEEXC.asm 		\
	    INDEXMA.asm 		\
	    INDEDMA.asm 		\
	    INDEIDT.asm 		\
	    INDEGDT.asm 		\
	    INDEI15.asm 		\
	    indemaus.asm		\
	    indemsus.inc		\
	    indeovp.mac 		\
	    indeins.mac 		\
	    indedes.mac 		\
	    indemsus.asm		\
	    indemsg.asm 		\
	    indepat.asm 		\
	    indedat.inc 		\
	    indeacc.inc 		\
	    xmaem.arf
	link @xmaem.arf
	tag  xmaem.sys
