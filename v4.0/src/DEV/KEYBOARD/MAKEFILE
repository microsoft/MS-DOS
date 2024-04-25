#*************************** Makefile for Bios ************************

msg	=..\..\msg
dos	=..\..\dos
inc	=..\..\inc

#
###################### Dependencies begin here #########################
#

all:           keyboard.sys

kdfnow.obj:    kdfnow.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdffr120.obj:  kdffr120.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdffr189.obj:  kdffr189.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfeof.obj:    kdfeof.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfuk166.obj:  kdfuk166.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfuk168.obj:  kdfuk168.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfit141.obj:  kdfit141.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfit142.obj:  kdfit142.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfge.obj:     kdfge.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfsp.obj:     kdfsp.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfnl.obj:     kdfnl.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfno.obj:     kdfno.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfdk.obj:     kdfdk.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfsg.obj:     kdfsg.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfsf.obj:     kdfsf.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfpo.obj:     kdfpo.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfbe.obj:     kdfbe.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfcf.obj:     kdfcf.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfla.obj:     kdfla.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

kdfsv.obj:     kdfsv.asm keybmac.inc keybshar.inc $(inc)\postequ.inc

keyboard.sys: kdfsp.obj kdfpo.obj kdffr120.obj kdffr189.obj kdfdk.obj \
	      kdfsg.obj kdfge.obj kdfit141.obj kdfit142.obj kdfuk166.obj \
	      kdfsf.obj kdfbe.obj kdfnl.obj    kdfno.obj    kdfcf.obj \
	      kdfla.obj kdfsv.obj kdfeof.obj   kdfnow.obj   kdfuk168.obj
	      link @keyboard.lnk
	      exe2bin keyboard.exe keyboard.sys
	      del keyboard.exe
