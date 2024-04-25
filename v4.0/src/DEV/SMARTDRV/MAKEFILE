# rules and dependencies follow
#
# use microsoft make to build
#
# set up build environment - include and library for c
#

all: smartdrv.sys

smartdrv.obj: smartdrv.asm mi.asm loadall.asm \
    syscall.asm emm.asm above.asm \
    devsym.asm
	masm smartdrv.asm;

smartdrv.exe: smartdrv.obj
	link smartdrv,,smartdrv/M;

smartdrv.sys: smartdrv.exe
	exe2bin smartdrv smartdrv.sys
