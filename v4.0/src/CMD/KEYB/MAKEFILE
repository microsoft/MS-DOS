#************************* Makefile for KEYB *************************

inc	=..\..\inc
msg	=..\..\messages
dos	=..\..\dos
hinc	=..\..\h

#
###################### Dependencies begin here. ######################
#

all: keyb.com

keyb.ctl: keyb.skl $(msg)\$(COUNTRY).msg

keybcmd.obj: keybcmd.asm \
             $(inc)\struc.inc \
             $(inc)\sysmsg.inc \
             $(inc)\versiona.inc \
             keybequ.inc  \
             keybsys.inc  \
             keybi9.inc   \
             keybi9c.inc  \
             keybi2f.inc  \
             keybi48.inc  \
             keybshar.inc \
             keyb.ctl     \
             keyb.cl1     \
             keyb.cl2     \
             keyb.cla     \
             keybdcl.inc  \
             keybtbbl.inc \
             commsubs.inc \
             keybcpsd.inc \
             $(inc)\postequ.inc  \
             $(inc)\dseg.inc

keybtbbl.obj: keybtbbl.asm

commsubs.obj: commsubs.asm

keybi2f.obj: keybi2f.asm

keybi48.obj: keybi48.asm

keyb.obj: keyb.asm

keybcpsd.obj: keybcpsd.asm

keybi9.obj: keybi9.asm

keybi9c.obj: keybi9c.asm

parser.obj:  parser.asm \
             $(inc)\parse.asm \
             $(inc)\struc.inc \
             keybdcl.inc \
             makefile

keyb.com: keyb.obj     \
          parser.obj   \
          keybcmd.obj  \
          keybtbbl.obj \
          commsubs.obj \
          keybi2f.obj  \
          keybi48.obj  \
          keybcpsd.obj \
          keybi9.obj   \
          keybi9c.obj
    link @keyb.lnk
    exe2bin keyb.exe keyb.com
    del keyb.exe
