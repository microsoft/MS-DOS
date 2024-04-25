#************************** makefile for mapper ***************************

msg	=..\messages
dos	=..\dos
inc	=..\inc
hinc	=..\h

#
#######################	dependencies begin here. #########################
#

all: mapper.lib

chdir.obj:  chdir.asm  makefile  macros.inc

getver.obj: getver.asm makefile  macros.inc

f_first.obj: f_first.asm makefile  macros.inc  find.inc

set_tod.obj: set_tod.asm makefile  macros.inc

write.obj:  write.asm makefile  macros.inc

beep.obj:   beep.asm makefile  macros.inc

mkdir.obj:  mkdir.asm makefile  macros.inc

exit.obj:   exit.asm makefile  macros.inc

delete.obj: delete.asm makefile  macros.inc

getcntry.obj: getcntry.asm  makefile	macros.inc

f_close.obj: f_close.asm  makefile  macros.inc  find.inc

open.obj:   open.asm  makefile  macros.inc

read.obj:   read.asm  makefile  macros.inc

rmdir.obj:  rmdir.asm  makefile  macros.inc

qcurdir.obj: qcurdir.asm  makefile  macros.inc

qcurdsk.obj: qcurdsk.asm  makefile  macros.inc

qverify.obj: qverify.asm  makefile  macros.inc

qfilemod.obj: qfilemod.asm makefile  macros.inc

sverify.obj: sverify.asm  makefile  macros.inc

sfilemod.obj: sfilemod.asm makefile  macros.inc

lseek.obj:  lseek.asm makefile  macros.inc

sfileinf.obj: sfileinf.asm makefile  macros.inc

close.obj:   close.asm makefile  macros.inc

allocseg.obj: allocseg.asm makefile  macros.inc

freeseg.obj: freeseg.asm  makefile  macros.inc

sel_disk.obj: sel_disk.asm makefile  macros.inc

qfsinfo.obj: qfsinfo.asm  makefile  macros.inc

f_next.obj: f_next.asm	makefile  macros.inc	find.inc

getmsg.obj: getmsg.asm	makefile  macros.inc

get_tod.obj: get_tod.asm  makefile  macros.inc

charin.obj: charin.asm makefile  macros.inc

flushbuf.obj: flushbuf.asm  makefile	macros.inc

devconfg.obj: devconfg.asm  makefile	macros.inc

reallseg.obj: reallseg.asm  makefile	macros.inc

putmsg.obj: putmsg.asm	makefile  macros.inc

execpgm.obj: execpgm.asm  makefile  macros.inc

qhandtyp.obj: qhandtyp.asm  makefile	macros.inc

cwait.obj:  cwait.asm  makefile  macros.inc

kbdgstat.obj: kbdgstat.asm  makefile	macros.inc

kbdsstat.obj: kbdsstat.asm makefile  macros.inc

casemap.obj: casemap.asm  makefile  macros.inc

dbcs.obj:   dbcs.asm  makefile  macros.inc

ioctl.obj:  ioctl.asm  makefile  macros.inc

sighand.obj: sighand.asm  makefile  macros.inc

error.obj:  error.asm  makefile  macros.inc

setint24.obj:  setint24.asm  makefile macros.inc

qfileinf.obj: qfileinf.asm  makefile	macros.inc

scurpos.obj: scurpos.asm makefile  macros.inc

scrollup.obj: scrollup.asm  makefile	macros.inc

wchstra.obj: wchstra.asm  makefile  macros.inc

scntry.obj: scntry.asm	makefile  macros.inc

setfsinf.obj: setfsinf.asm makefile  macros.inc

gmachmod.obj: gmachmod.asm makefile  macros.inc

mapper.lib: makefile chdir.obj getver.obj f_first.obj set_tod.obj \
	    write.obj beep.obj mkdir.obj exit.obj delete.obj getcntry.obj \
	    f_close.obj open.obj read.obj rmdir.obj qcurdir.obj qcurdsk.obj \
	    qverify.obj qfilemod.obj sverify.obj sfilemod.obj lseek.obj \
	    sfileinf.obj close.obj allocseg.obj freeseg.obj sel_disk.obj \
	    qfsinfo.obj f_next.obj getmsg.obj get_tod.obj charin.obj \
	    flushbuf.obj devconfg.obj reallseg.obj putmsg.obj execpgm.obj \
	    qhandtyp.obj cwait.obj kbdgstat.obj kbdsstat.obj casemap.obj \
	    dbcs.obj ioctl.obj sighand.obj error.obj setint24.obj \
	    qfileinf.obj scurpos.obj scrollup.obj wchstra.obj scntry.obj \
	    setfsinf.obj gmachmod.obj
	    del  mapper.lib
	    lib  @mapper.lbr
