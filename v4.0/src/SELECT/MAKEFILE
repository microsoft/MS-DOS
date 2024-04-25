#
###### Make file for SELECT.EXE, SELECT.DAT, SELECT.COM, SELECT.HLP #####
#

msg	=..\messages
dos	=..\dos
inc	=..\inc
hinc	=..\h
shell	=..\shell
cas	=..\shell\cassfar
make	=nmake
here	=..\..\select

#
#######################	dependencies begin here. #########################
#

all: select.exe select.dat select.com select.hlp

#
############################ Make SELECT.EXE #############################
#

select.ctl: select.skl $(msg)\$(COUNTRY).msg

select0.obj: select0.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc  \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc     \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc  \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc    \
             select.ctl macros8.inc pcequate.inc 

select1.obj: select1.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc  \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc     \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc  \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc    \
             macros8.inc pcequate.inc 

select2.obj: select2.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc   \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc      \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc   \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc     \
             macros8.inc pcequate.inc 

select2a.obj: select2a.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc      \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc   \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc     \
             macros8.inc pcequate.inc 

select3.obj: select3.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc   \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc      \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc   \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc     \
             macros8.inc pcequate.inc 

select4.obj: select4.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc   \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc      \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc   \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc     \
             macros8.inc pcequate.inc 

select5.obj: select5.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc   \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc      \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc   \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc     \
             macros8.inc pcequate.inc 

select5a.obj: select5a.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc      \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc   \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc     \
             macros8.inc pcequate.inc 

select6.obj: select6.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc   \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc      \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc   \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc     \
             macros8.inc pcequate.inc 

select7.obj: select7.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc   \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc      \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc   \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc     \
             macros8.inc pcequate.inc 

select8.obj: select8.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc   \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc      \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc   \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc     \
             macros8.inc pcequate.inc 

select9.obj: select9.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc   \
             panel.mac select.inc pan-list.inc castruc.inc macros.inc      \
             macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc   \
             macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc     \
             macros8.inc pcequate.inc 

gen_coms.obj: gen_coms.asm $(inc)\struc.inc $(inc)\sysmsg.inc casextrn.inc \
              panel.mac select.inc pan-list.inc castruc.inc macros.inc     \
              macros2.inc macros3.inc macros4.inc macros5.inc macros6.inc  \
              macros7.inc mac_equ.inc ext.inc varstruc.inc rout_ext.inc    \
              macros8.inc pcequate.inc 

mparse.obj: mparse.asm $(inc)\parse.asm data.mac 

initmem.obj: initmem.asm $(inc)\struc.inc macros.inc macros2.inc macros3.inc \
             macros4.inc macros5.inc macros6.inc macros7.inc macros8.inc \
	     mac_equ.inc 

input.obj:    input.asm pcequate.inc 

routines.obj: routines.asm $(inc)\struc.inc mac_equ.inc varstruc.inc ext.inc \
              macros.inc macros2.inc macros3.inc macros4.inc macros5.inc     \
              macros6.inc macros7.inc macros8.inc pan-list.inc panel.mac


routine2.obj: routine2.asm $(inc)\struc.inc mac_equ.inc ext.inc varstruc.inc \
              macros.inc macros2.inc macros3.inc macros4.inc macros5.inc     \
              macros6.inc macros7.inc macros8.inc 

var.obj:  var.asm $(inc)\sysmsg.inc sel_file.inc varstruc.inc 

prn_def.obj: prn_def.asm $(inc)\struc.inc macros.inc macros2.inc macros3.inc \
             macros4.inc macros5.inc macros6.inc macros7.inc macros8.inc \
	     mac_equ.inc 

scn_parm.obj: scn_parm.asm $(inc)\struc.inc ext.inc macros.inc macros2.inc   \
              macros3.inc macros4.inc macros5.inc macros6.inc macros7.inc    \
              macros8.inc mac_equ.inc 

s_disply.obj: s_disply.asm $(inc)\struc.inc 

mod_copy.obj: mod_copy.asm $(inc)\struc.inc dos.equ xcopy.equ dosfiles.inc  \
              macros.inc macros2.inc macros3.inc macros4.inc macros5.inc    \
              macros6.inc macros7.inc pan-list.inc macros8.inc mac_equ.inc \
	      xmainmsg.equ panel.mac casextrn.inc 

bridge.obj: bridge.asm $(inc)\casvar.inc $(inc)\casrn.inc 

caservic.obj: caservic.asm $(inc)\casvar.inc $(inc)\casrn.inc pan-list.inc \
	      select.inc castruc.inc data.mac panel.mac macros.inc \
	      $(inc)\struc.inc pcequate.inc mac_equ.inc 

ckdisp.obj: ckdisp.asm $(inc)\struc.inc 

intvec.obj: intvec.asm $(inc)\struc.inc mac_equ.inc pan-list.inc \
            panel.mac macros.inc varstruc.inc ext.inc casextrn.inc \
            macros8.inc 

asm2c.obj : asm2c.asm 

get_stat.obj : get_stat.c get_stat.h extern.h 

int13.obj : int13.c 

global.obj : global.c 

..\cmd\fdisk\bootrec.obj:
		cd ..\cmd\fdisk
		$(make) bootrec.obj
		cd ..\..\select

bootrec.obj : ..\cmd\fdisk\bootrec.obj
             copy ..\cmd\fdisk\bootrec.obj

selquit.obj : selquit.asm panel.mac pcequate.inc pan-list.inc castruc.inc   \
              ext.inc $(inc)\struc.inc macros.inc macros2.inc macros3.inc   \
              macros4.inc macros5.inc macros6.inc macros7.inc macros8.inc \
	      mac_equ.inc 

selchild.obj : selchild.asm pcequate.inc castruc.inc macros.inc macros2.inc  \
               macros3.inc macros4.inc macros5.inc macros6.inc macros7.inc   \
               macros8.inc mac_equ.inc 

services.obj : services.asm pcequate.inc castruc.inc $(inc)\casvar.inc \
	       macros.inc macros2.inc macros3.inc macros4.inc macros5.inc \
	       macros6.inc macros7.inc macros8.inc mac_equ.inc 

get_help.obj : get_help.asm 

selserv.obj : selserv.asm 

services.lib : selquit.obj selchild.obj services.obj get_help.obj selserv.obj
               
        lib services.lib -+ selquit;
        lib services.lib -+ selchild;
        lib services.lib -+ services;
        lib services.lib -+ get_help;
        lib services.lib -+ selserv;

select.exe: select0.obj select1.obj select2.obj select2a.obj select3.obj \
      select4.obj select5.obj select6.obj select7.obj select8.obj select9.obj \
      routines.obj routine2.obj gen_coms.obj intvec.obj select5a.obj \
      ckdisp.obj scn_parm.obj prn_def.obj var.obj caservic.obj input.obj \
      initmem.obj mparse.obj mod_copy.obj s_disply.obj bridge.obj \
      asm2c.obj get_stat.obj global.obj int13.obj bootrec.obj select5a.obj \
      services.lib
        link /noe @select.lnk
# The "/noe" is so symbols defined in source files supercede library routines

#
#######################  make select.com #####################
#

sstub.obj: sstub.asm $(inc)\sysmsg.inc select.ctl 

select.com: sstub.obj
        link sstub;
        exe2bin sstub.exe select.com

#
#######################  make select.dat ####################
#


panel.inf: USA.inf 
        copy USA.inf panel.inf

panels.obj: panels.asm sel-pan.inc pan-list.inc panel.inf 

colors.obj: colors.asm sel-pan.inc 

scroll.obj: scroll.asm sel-pan.inc panel.inf 

sel-pan.obj: sel-pan.asm $(inc)\casvar.inc sel-pan.inc 

sel-pan.exe: sel-pan.obj panels.obj colors.obj scroll.obj
        link @sel-pan.lnk

select.dat: sel-pan.exe
	exe2bin sel-pan.exe sel-pan.dat
	compress

#
######################  make select.hlp #####################
#

#$(shell)\shellhlp\asc2hlp.exe : 
#				cd $(shell)\shellhlp
#				$(make) asc2hlp.exe
#				cd $(here)

select.hlp: USA.txt
        erase select.hlp
	attrib -R USA.txt
        asc2hlp USA.txt select.hlp
	attrib +R USA.txt
			    	
		
