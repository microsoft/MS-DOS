comment $
cmacros - assembly macros for interfacing to HHLs
(C)Copyright 1984, 1988 Microsoft Corporation
$
if1
outif MACRO name,defval,onmsg,offmsg
    ifndef name
	ifb <defval>
	    name=0
	else
	    name=defval
	endif
    endif
    if name
	name=1
	ifnb <onmsg>
	    %out ! onmsg
	endif
    else
	ifnb <offmsg>
	    %out ! offmsg
	endif
    endif
endm

error MACRO msg
bug
%out E r r o r ----- msg
ENDM
%out cMacros Version 1.04
outif memS,0,<Small Model>
outif memM,0,<Medium Model>
outif memL,0,<Large Model>
outif memC,0,<Compact Model>
outif memH,0,<Huge Model>
memMOD= memS + memM + memL + memC + memH
if memMOD ne 1
if memMOD eq 0
memS= 1
outif memS,0,<Small Model>
else
error <Must have only 1 memory model selected>
endif
endif
sizeC= memM + memL + memH
sizeD= memL + memC + (memH*2)
outif ?DF,0,<No segments or groups will be defined>
outif ?WIN,0,<Windows Support>
outif ?PLM,0,<PLM calling convention>
endif
 .XCREF
 .XCREF ?N,?AX,?AH,?AL,?BX,?BH
 .XCREF ?BL,?CX,?CH,?CL,?DX,?DH
 .XCREF ?DL,?SI,?DI,?ES,?DS,?BP
 .XCREF ?SP,?SS,?CS
 .XCREF ?RSL,?CPD,?argl,?argc,?BA
 .XCREF ?ACB,???,?PO
 .XCREF ?PAS,?PC
 .XCREF Uconcat,mPush,mPop
 .XCREF ?RI,?pp,?pp1,?al1
 .XCREF ?aD,?AP,?Atal,?pd,?dd,?dd1,?ex1,?cas
 .XCREF ?pg,?pg1,?aloc,?cs1,?cs2
 .XCREF ?lb1,?lblpu
 .XCREF ?DF,?PLM,?WIN,?IA,?PU,?ADJ
 .CREF
?RSL = 0
?CPD = 0
?ArgL = 0
?ArgC = 0
?BA = 0
?ACB = 0
??? = 0
?PO = 0
?PAS = 0
?PC = 0
?IA = 0
?PU = 0
?ADJ = 0
?lblpu = 0
?N = 0000000000000000B
?AX = 0000000000000011B
?AH = 0000000000000001B
?AL = 0000000000000010B
?BX = 0000000000001100B
?BH = 0000000000000100B
?BL = 0000000000001000B
?CX = 0000000000110000B
?CH = 0000000000010000B
?CL = 0000000000100000B
?DX = 0000000011000000B
?DH = 0000000001000000B
?DL = 0000000010000000B
?SI = 0000000100000000B
?DI = 0000001000000000B
?ES = 0000010000000000B
?DS = 0000100000000000B
?BP = 0001000000000000B
?SP = 0010000000000000B
?SS = 0100000000000000B
?CS = 1000000000000000B
uconcat macro n1,n2,o1,o2,p1,p2
n1&n2 o1&o2 p1&p2
endm
mpush macro rV
irp x,<ax,bx,cx,dx,si,di,es,ds,bp,sp,ss,cs>
if rV AND ?&&x
push x
endif
endm
endm
mpop macro rV
irp x,<cs,ss,sp,bp,ds,es,di,si,dx,cx,bx,ax>
if rV AND ?&&x
pop x
endif
endm
endm
SAVE macro rL
?RSL = 0
?RI ?RSL,<rL>
endm
smashes macro n,rL
 .xcref
 .xcref ?SM&n
 .cref
?SM&n = 0
?RI ?SM&n,<rL>
endm
?RI macro n,rL
irp x,<rL>
ifdef ?&&x
n = n or ?&&x
endif
endm
endm
parmB macro nl
?pp <&nL>,<byte>,2,1
endm
parmW macro nl
?pp <&nL>,<word>,2,2
endm
parmD macro nl
ife ?PLM
irp x,<nL>
?pp <&&x>,<DWORD>,0,4
?pp <Off_&&x>,<WORD>,2,2
?pp <Seg_&&x>,<WORD>,2,2
endm
else
irp x,<nL>
?pp <Seg_&&x>,<WORD>,2,2
?pp <Off_&&x>,<WORD>,2,2
?pp <&&x>,<DWORD>,0,4
endm
endif
endm
parmQ macro nl
?pp <&nL>,<QWORD>,8,8
endm
parmT macro nl
?pp <&nL>,<TBYTE>,10,10
endm
if sizeC
parmCP macro nl
parmD <nl>
endm
else
parmCP macro nl
parmW <nl>
endm
endif
if sizeD
parmDP macro nl
parmD <nl>
endm
else
parmDP macro nl
parmW <nl>
endm
endif
?pp macro nL,t,l,s
if ?CPD
 .xcref
ife ?PLM
irp x,<nL>
?pp1 x,<t>,%?PO,%?adj,%(?PO+?adj)
?PO = ?PO + l
 .xcref ?T&&x
?T&&x = s
endm
else
irp x,<nL>
?PO = ?PO + l
?pp1 x,<t>,%?PO,%?adj,%(?PO+?adj)
 .xcref ?T&&x
?T&&x = s
endm
endif
 .cref
else
%out Parm(s) "&nl" declared outside proc def.
endif
endm
?pp1 macro n,t,o,a,b
ife ?PLM
n equ t ptr [bp+b]
else
n equ t ptr [bp+a+?PO-o]
endif
endm
localB macro nL
?aLoc <&nL>,<BYTE ptr>,1,1,0
endm
localW macro nL
?aLoc <&nL>,<WORD PTR>,2,2,1
endm
localD macro nL
irp x,<nL>
?aLoc <Seg_&&x>,<WORD PTR>,2,2,1
?aLoc <Off_&&x>,<WORD PTR>,2,2,1
?aLoc <&&x>,<DWORD PTR>,0,4,1
endm
endm
localQ macro nL
?aLoc <&nL>,<QWORD PTR>,8,8,1
endm
localT macro nL
?aLoc <&nL>,<TBYTE PTR>,10,10,1
endm
if sizeC
localCP macro nL
localD <nL>
endm
else
localCP macro nL
localW <nL>
endm
endif
if sizeD
localDP macro nL
localD <nL>
endm
else
localDP macro nL
localW <nL>
endm
endif
localV macro n,a
?aLoc <&n>,,%(&a),0,1
endm
?aLoc macro nL,t,l,s,a
if ?CPD
 .xcref
??? = ??? + l
if a
??? = ((??? + 1) AND 0FFFEH)
endif
irp x,<nL>
?aL1 x,<t>,%???
 .xcref ?T&&x
?T&&x = s
endm
 .cref
else
%out Locals "&nl" declared outside procedure def.
endif
endm
?aL1 macro n,t,o
if ?IA
n equ t [bp-?IA-o]
else
n equ t [bp-o]
endif
endm
globalB macro n,i,s
?aD <n>,1
?dd n,1,<BYTE>,<DB>,<i>,<s>
endm
globalW macro n,i,s
?aD <n>,2
?dd n,1,<WORD>,<DW>,<i>,<s>
endm
globalD macro n,i,s
?aD <n>,4
?dd n,1,<DWORD>,<DD>,<i>,<s>
endm
globalQ macro n,i,s
?aD <n>,8
?dd n,1,<QWORD>,<DQ>,<i>,<s>
endm
globalT macro n,i,s
?aD <n>,10
?dd n,1,<TBYTE>,<DT>,<i>,<s>
endm
if sizeC
globalCP macro n,i,s
globalD n,<i>,<s>
endm
else
globalCP macro n,i,s
globalW n,<i>,<s>
endm
endif
if sizeD
globalDP macro n,i,s
globalD n,<i>,<s>
endm
else
globalDP macro n,i,s
globalW n,<i>,<s>
endm
endif
staticB macro n,i,s
?aD <n>,1
?dd n,0,<BYTE>,<DB>,<i>,<s>
endm
staticW macro n,i,s
?aD <n>,2
?dd n,0,<WORD>,<DW>,<i>,<s>
endm
staticD macro n,i,s
?aD <n>,4
?dd n,0,<DWORD>,<DD>,<i>,<s>
endm
staticQ macro n,i,s
?aD <n>,8
?dd n,0,<QWORD>,<DQ>,<i>,<s>
endm
staticT macro n,i,s
?aD <n>,10
?dd n,0,<TBYTE>,<DT>,<i>,<s>
endm
if sizeC
staticCP macro n,i,s
staticD n,<i>,<s>
endm
else
staticCP macro n,i,s
staticW n,<i>,<s>
endm
endif
if sizeD
staticDP macro n,i,s
staticD n,<i>,<s>
endm
else
staticDP macro n,i,s
staticW n,<i>,<s>
endm
endif
?dd macro n,p,t,d,i,s
ife ?PLM
n label t
?dd1 _&n,p,<d>,<i>,<s>
else
?dd1 n,p,<d>,<i>,<s>
endif
endm
?dd1 macro n,p,d,i,s
if p
PUBLIC n
endif
ifb <s>
n d i
else
ifb <i>
n d s DUP (?)
else
n d s DUP (i)
endif
endif
endm
externB macro nL
?ex1 <&nL>,1,<BYTE>
endm
externW macro nL
?ex1 <&nL>,2,<WORD>
endm
externD macro nL
?ex1 <&nL>,4,<DWORD>
endm
externQ macro nL
?ex1 <&nL>,8,<QWORD>
endm
externT macro nL
?ex1 <&nL>,10,<TBYTE>
endm
externNP macro nL
?ex1 <&nL>,2,<NEAR>
endm
externFP macro nL
?ex1 <&nL>,4,<FAR>
endm
if sizeC
externP macro nL
?ex1 <&nL>,4,<FAR>
endm
else
externP macro nL
?ex1 <&nL>,2,<NEAR>
endm
endif
if sizeC
externCP macro nL
?ex1 <&nL>,4,<DWORD>
endm
else
externCP macro nL
?ex1 <&nL>,2,<WORD>
endm
endif
if sizeD
externDP macro nL
?ex1 <&nL>,4,<DWORD>
endm
else
externDP macro nL
?ex1 <&nL>,2,<WORD>
endm
endif
?ex1 macro nL,s,d
irp x,<nL>
 .xcref
 .xcref ?T&&x
 .cref
?T&&x = s
ife ?PLM
extrn _&&x:&d
x equ _&&x
else
extrn x:&d
endif
endm
endm
labelB macro nL
?lb1 <&nL>,1,<BYTE>
endm
labelW macro nL
?lb1 <&nL>,2,<WORD>
endm
labelD macro nL
?lb1 <&nL>,4,<DWORD>
endm
labelQ macro nL
?lb1 <&nL>,8,<QWORD>
endm
labelT macro nL
?lb1 <&nL>,10,<TBYTE>
endm
labelNP macro nL
?lb1 <&nL>,2,<NEAR>
endm
labelFP macro nL
?lb1 <&nL>,4,<FAR>
endm
if sizeC
labelP macro nL
?lb1 <&nL>,4,<FAR>
endm
else
labelP macro nL
?lb1 <&nL>,2,<NEAR>
endm
endif
if sizeC
labelCP macro nL
?lb1 <&nL>,4,<DWORD>
endm
else
labelCP macro nL
?lb1 <&nL>,2,<WORD>
endm
endif
if sizeD
labelDP macro nL
?lb1 <&nL>,4,<DWORD>
endm
else
labelDP macro nL
?lb1 <&nL>,2,<WORD>
endm
endif
?lb1 macro nL,s,d
?lblpu = 0
irp x,<nL>
ifidn <x>,<PUBLIC>
?lblpu = 1
else
 .xcref
 .xcref ?T&&x
 .cref
?T&&x = s
ife ?PLM
if ?lblpu
public _&&x
endif
_&&x label &d
x equ _&&x
else
if ?lblpu
public x
endif
x label &d
endif
endif
endm
endm
defB macro nL
?aD <&nL>,1
endm
defW macro nL
?aD <&nL>,2
endm
defD macro nL
?aD <&nL>,4
endm
defQ macro nL
?aD <&nL>,8
endm
defT macro nL
?aD <&nL>,10
endm
if sizeC
defCP macro nL
defD <nL>
endm
else
defCP macro nL
defW <nL>
endm
endif
if sizeD
defDP macro nL
defD <nL>
endm
else
defDP macro nL
defW <nL>
endm
endif
?aD macro nL,s
irp x,<nL>
 .xcref
 .xcref ?T&&x
 .cref
?T&&x = s
endm
endm
regPtr macro n,S,O
 .xcref
 .xcref ?T&n,?SR&n,?OR&n
 .cref
?T&n = 0FFFFH
?SR&n = 0
?RI ?SR&n,<&S>
?OR&n = 0
?RI ?OR&n,<&O>
endm
arg macro aL
irp x,<aL>
?argc = ?argc + 1
?Atal <x>,%?argc
endm
endm
?Atal macro n,i
 .xcref
 .xcref ?ALI&i
 .cref
?ALI&i &macro
?AP n
&endm
endm
?AP macro n
?argl = ?argl + 2
ifdef ?T&n
ife ?T&n-1
push word ptr (n)
exitm
endif
ife ?T&n-2
push n
exitm
endif
ife ?T&n-4
push word ptr (n)+2
push word ptr (n)
?argl = ?argl + 2
exitm
endif
ife ?T&n-8
push word ptr (n)+6
push word ptr (n)+4
push word ptr (n)+2
push word ptr (n)
?argl = ?argl + 6
exitm
endif
ife ?T&n-0FFFFH
mpush %(?SR&n),1
mpush %(?OR&n),1
?argl = ?argl + 2
exitm
endif
ife ?T&n
push word ptr (n)
exitm
endif
endif
push n
endm
ife ?PLM
ccall macro n,a,sleaze
ifnb <a>
Arg <a>
endif
ifdef ?SM&n
?RSL = ?RSL AND ?SM&n
endif
mpush %?RSL
?argl = 0
?ACB = ?argc
rept ?argc
uconcat <?ALI>,%?ACB
uconcat <purge>,,<?ALI>,%?ACB
?ACB = ?ACB - 1
endm
ife ?PLM
ifb <sleaze>
call _&n
else
call n
endif
else
call n
endif
if ?argl
add sp,?argl
endif
mpop %?RSL
?RSL = 0
?argc = 0
?argl = 0
endm
else
ccall macro n,a
ifnb <a>
Arg <a>
endif
ifdef ?SM&n
?RSL = ?RSL AND ?SM&n
endif
mpush %?RSL
?argl = 0
?ACB = 1
rept ?argc
uconcat <?ALI>,%?ACB
uconcat <purge>,,<?ALI>,%?ACB
?ACB = ?ACB + 1
endm
ife ?PLM
call _&n
else
call n
endif
mpop %?RSL
?RSL = 0
?argc = 0
?argl = 0
endm
endif
cProc macro n,cl,s
?pd n,<cl>,<s>,4
endm
?pd macro n,c,a,i
if ?CPD
?UTPE
endif
?CPD = 1
??? = 0
?argc = 0
?BA = 0
?PO = 0
?PU = 0
?IA = 0
?adj = i
?PAS = 0
ifnb <a>
?RI ?PAS,<a>
endif
?PC = sizeC
irp x,<c>
ifidn <x>,<FAR>
?PC = 1
endif
ifidn <x>,<NEAR>
?PC = 0
endif
ifidn <x>,<PUBLIC>
?PU = 1
endif
endm
if ?PC
if ?WIN
?IA = 2
endif
?adj = ?adj + 2
endif
ife ?PLM
ife ?PC
n label near
else
n label far
endif
?pg <_&n>,%?PU,%?PC,%?PAS
else
?pg <n>,%?PU,%?PC,%?PAS
endif
endm
?pg macro n,p,c,a
    .xcref
    cBegin &macro g
	.xcref
	?pg1 <n>,c,a,%?PO
	?CPD = 0
	?argc = 0
	?BA = 1
	??? = (???+1) AND 0FFFEH
	if p
	    PUBLIC n
	endif
	ife c
	    n proc NEAR
	else
	    n proc FAR
	endif
	ifidn <g>,<nogen>
	    if ???+?PO+a
		%out <cBegin - possible invalid use of nogen>
	    endif
	else
	    if ?IA
		mov ax,ds
		nop
		inc bp
		push bp
		mov bp,sp
		push ds
		mov ds,ax
	    else
		push bp
		mov bp,sp
	    endif
	    if ???
		sub sp,???
	    endif
	    mPush a,1
	endif
	.cref
	purge cBegin
    &endm
    ?UTPE &macro
	%out Unterminated Procedure Definition: "&n"
    &endm
endm

?pg1 macro n,c,a,o
    .xcref
    cEnd &macro g
	.xcref
	?BA = 0
	ifidn <g>,<nogen>
	    if o+a
		%out <cEnd - possible invalid use of nogen>
	    endif
	else
	    mPop a,1
	    if ?IA
		sub bp,2
		mov sp,bp
		pop ds
		pop bp
		dec bp
	    else
		mov sp,bp
		pop bp
	    endif
	    ife ?PLM
		ret
	    else
		ret o
	    endif
	endif
	n endp
	.cref
	purge cEnd
    &endm
    .cref
endm

assumes macro s,g
local assumed
assumed = 0
ifidn <code>,<g>
?cas <s>
assumed = 1
endif
ifidn <CODE>,<g>
?cas <s>
assumed = 1
endif
ifidn <data>,<g>
assume s&:dgroup
assumed = 1
endif
ifidn <DATA>,<g>
assume s&:dgroup
assumed = 1
endif
ife assumed
assume s&:&g
endif
endm
if sizeC
?cas macro s
assume s&:_TEXT
endm
else
?cas macro s
assume s&:IGROUP
endm
endif
createSeg macro n,ln,a,co,cl,grp
ifnb <grp>
ifidn <grp>,<IGROUP>
ife sizeC
addSeg IGROUP,n
endif
else
addSeg grp,n
endif
endif
ifnb <cl>
n segment a co '&cl'
else
n segment a co
endif
n ends
?cs1 <n>,<ln>
endm
if1
ASMpass=1
else
ASMpass=2
endif
addSeg macro grp,seg
ifndef def_&grp
def_&grp= 0
endif
if def_&grp ne ASMpass
add_&grp &macro s
in_&grp <seg>,s
&endm
in_&grp &macro sl,s
ifb <s>
grp group sl
else
add_&grp &macro ns
in_&grp <sl,s>,ns
&endm
endif
&endm
def_&grp=ASMpass
else
add_&grp seg
endif
endm
defGrp macro nam
addSeg nam
endm
?cs1 macro n,ln
begin&ln &macro
?cs2 <n>
n segment
&endm
endm

?cs2 macro n
    sEnd &macro
	n ends
    &endm
endm

sBegin macro ln
    begin&ln
endm

ife ?DF
    createSeg _TEXT,code,byte,public,CODE,IGROUP
    createSeg _DATA,data,word,public,DATA,DGROUP
    if ?WIN
	ife sizeC
	    createSeg _INITTEXT,initcode,byte,public,CODE,IGROUP
	    createSeg _INITDATA,initdata,word,public,DATA,DGROUP
	endif
    endif
    ife sizeC
	defGrp IGROUP
    endif
    defGrp DGROUP
    if sizeC
	codeOFFSET equ OFFSET _TEXT:
    else
	codeOFFSET equ OFFSET IGROUP:
    endif
    dataOFFSET equ OFFSET DGROUP:
endif

errnz macro x
    if2
	if x
	    errnz1 <x>,%(x)
	endif
    endif
endm

errnz1 macro x1,x2
    = *ERRNZ* x1 = x2
endm

errn$ macro l,x
    errnz <OFFSET $ - OFFSET l x>
endm
