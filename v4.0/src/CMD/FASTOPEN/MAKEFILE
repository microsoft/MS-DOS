#************************** makefile for cmd\... ***************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: fastopen.exe

fastopen.ctl: fastopen.skl  makefile  $(msg)\$(COUNTRY).msg

fastopen.obj: fastopen.asm $(inc)\fastopen.inc \
	makefile

fastseek.obj: fastseek.asm $(inc)\fastopen.inc \
	makefile

fastinit.obj: fastinit.asm $(inc)\dossym.inc $(inc)\fastopen.inc \
	makefile

fastp.obj: fastp.asm \
	makefile \
	$(inc)\psdata.inc \
	$(inc)\parse.asm

fastsm.obj: fastsm.asm \
	makefile \
	$(inc)\versiona.inc \
	$(inc)\copyrigh.inc \
	$(inc)\sysmsg.inc \
	$(inc)\msgserv.asm \
	fastopen.ctl \
	fastopen.cl1 \
	fastopen.cl2 \
	fastopen.cla \

fastopen.exe: fastopen.obj \
	fastopen.lnk \
	fastseek.obj \
	fastinit.obj \
	fastp.obj \
	fastsm.obj
	link @fastopen.lnk
