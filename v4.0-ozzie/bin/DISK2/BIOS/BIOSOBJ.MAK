ibmbio.obj:	ibmbio.asm defdbug.inc bugcode.inc
	masm ibmbio;

ibmmtcon.obj:	ibmmtcon.asm ansi.inc defdbug.inc
	masm ibmmtcon;

ibmdsk.obj:	ibmdsk.asm defdbug.inc
	masm ibmdsk;

sysini.obj:	sysini.asm dossym.inc devsym.inc syscalls.inc
	masm sysini;

sysimes.obj:	sysimes.asm
	masm sysimes;

ibmbio.exe:	ibmbio.obj ibmmtcon.obj ibmdsk.obj sysini.obj sysimes.obj
	link ibmbio ibmmtcon ibmdsk sysini sysimes,ibmbio,ibmbio/map;

ibmbio.com:	ibmbio.exe
	exe2bin ibmbio ibmbio.com
