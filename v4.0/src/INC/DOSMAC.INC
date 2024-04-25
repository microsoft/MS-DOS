;	SCCSID = @(#)dosmac.asm	1.1 85/04/10
;	SCCSID = @(#)dosmac.asm	1.1 85/04/10
;
; Macro file for MSDOS.
;

TRUE    EQU 0FFFFh
FALSE   EQU 0

SUBTTL BREAK a listing into pages and give new subtitles
PAGE
BREAK   MACRO   subtitle
	SUBTTL  subtitle
	PAGE
ENDM
.xcref  break

BREAK   <ASMVAR - handle assembly variables once and for all>

AsmVars Macro   varlist
IRP     var,<varlist>
AsmVar  var
ENDM
ENDM

AsmVar  Macro   var
IFNDEF  var
var = FALSE
ENDIF
ENDM

BREAK <I_NEED: declare a variable external, if necessary, and allocate a size>

;
; declare a variable external and allocate a size
;
AsmVar  InstalledData
I_NEED  MACRO   sym,len
IF NOT InstalledData
	DATA    SEGMENT WORD PUBLIC 'DATA'
    IFIDN   <len>,<WORD>
	EXTRN   &sym:WORD
    ELSE
	IFIDN   <len>,<DWORD>
	EXTRN   &sym:DWORD
	ELSE
	EXTRN   &sym:BYTE
	ENDIF
    ENDIF
	DATA    ENDS
ENDIF
ENDM
	.xcref I_need

;
; call a procedure that may be external.  The call will be short.
;
invoke  MACRO   name
.xcref
	IF2
	    IFNDEF name
	EXTRN   name:NEAR
	    ENDIF
	ENDIF
.cref
	CALL    name
ENDM
.xcref  invoke

PAGE
;
; jump to a label that may be external.  The jump will be near.
;
transfer    MACRO   name
.xcref
	IF2
	    IFNDEF name
	EXTRN   name:NEAR
	    ENDIF
	ENDIF
.cref
	JUMP    name
ENDM
.xcref  transfer

;
; get a short address in a word
;
short_addr  MACRO   name
    IFDIF   <name>,<?>
.xcref
	IF2
	    IFNDEF name
	EXTRN   name:NEAR
	    ENDIF
	ENDIF
.cref
	DW  OFFSET DOSGROUP:name
    ELSE
	DW  ?
    ENDIF
ENDM
.xcref  short_addr

;
; get a long address in a dword
;
long_addr   MACRO   name
.xcref
	IF2
	    IFNDEF name
	EXTRN   name:NEAR
	    ENDIF
	ENDIF
.cref
	DD  name
ENDM
.xcref  long_addr

;
; declare a PROC near or far but PUBLIC nonetheless
;
.xcref ?frame
.xcref ?aframe
.xcref ?stackdepth
.xcref ?initstack
?frame        =   0                     ; initial
?aframe       =   0                     ; initial
?stackdepth   =   0                     ; initial stack size
?initstack    =   0                     ; initial stack size

procedure   MACRO   name,distance
	?frame =    0
	?aframe =   2                   ;; remember the pushed BP
	PUBLIC  name
	IF1
	%OUT name... pass 1
	ENDIF
	IF2
	%OUT name... pass 2
	ENDIF
name    PROC    distance
	?initstack    = ?stackdepth     ;; beginning of procedure
ENDM
.xcref  procedure

;
; end a procedure and check that stack depth is preserved
;
EndProc MACRO   name, chk
	IFDIF   <chk>,<NoCheck>       ;; check the stack size
	IF2
	IF ?initstack NE ?stackdepth    ;; is it different?
	%OUT    ***** Possible stack size error in name *****
	ENDIF
	ENDIF
	ENDIF
name    ENDP
ENDM
.xcref  endproc
PAGE
;
; define a data item to be public and of an appropriate size/type
;

I_AM    MACRO   name,size,init
;; declare the object public
	PUBLIC  name
;; declare the type of the object
    IFIDN <size>,<WORD>
name    LABEL WORD
	I_AM_SIZE   =   1
	I_AM_LEN    =   2
    ELSE
	IFIDN <size>,<DWORD>
name    LABEL DWORD
	I_AM_SIZE   =   2
	I_AM_LEN    =   2
	ELSE
	    IFIDN <size>,<BYTE>
name    LABEL BYTE
	I_AM_SIZE   =   1
	I_AM_LEN    =   1
	    ELSE
name    LABEL BYTE
	I_AM_SIZE   =   size
	I_AM_LEN    =   1
	    ENDIF
	ENDIF
    ENDIF
;; if no initialize then allocate blank storage
    IFB <init>
	DB  I_AM_SIZE*I_AM_LEN DUP (?)
    ELSE
IF NOT InstalledData
	IRP itm,<init>
	    IF I_AM_LEN EQ 1
		DB  itm
	    ELSE
		DW  itm
	    ENDIF
	    I_AM_SIZE = I_AM_SIZE - 1
	ENDM
	IF I_AM_SIZE NE 0
	    %out    ***** initialization of name not complete *****
	ENDIF
ELSE
	DB  I_AM_SIZE*I_AM_LEN DUP (?)
ENDIF
    ENDIF
ENDM
.xcref  I_AM
.xcref  I_AM_SIZE
.xcref  I_AM_LEN
I_AM_SIZE   = 0
I_AM_LEN    = 0

PAGE

;
; define an entry in a procedure
;
entry macro name
	PUBLIC  name
name:
endm
.xcref  entry

BREAK <ERROR - store an error code then jump to a label>

error macro code
.xcref
	MOV AL,code
	transfer    SYS_RET_ERR
.cref
ENDM
.xcref  error

BREAK <JUMP - real jump that links up shortwise>
;
; given a label <lbl> either 2 byte jump to another label <lbl>_J
; if it is near enough or 3 byte jump to <lbl>
;

jump    macro lbl
    local a
.xcref

    ifndef lbl&_J                       ;; is this the first invocation
a:      JMP lbl
    ELSE
	IF (lbl&_J GE $) OR ($-lbl&_J GT 126)
a:      JMP lbl                         ;; is the jump too far away?
	ELSE
a:      JMP lbl&_J                      ;; do the short one...
	ENDIF
    ENDIF
    lbl&_j = a
.cref
endm
.xcref  jump

BREAK <RETURN - return from a function>

return  macro x
    local a
.xcref
a:
	RET
ret_l = a
.cref
endm
.xcref  return

BREAK <CONDRET - conditional return>

condret macro   cc,ncc
    local   a
.xcref
.xcref a
.cref
    ifdef   ret_l                       ;; if ret_l is defined
	if (($ - ret_l) le 126) and ($ gt ret_l)
					;;     if ret_l is near enough then
	    a:  j&cc    ret_l           ;;         a: j<CC> to ret_l
	    ret_&cc = a                 ;;         define ret_<CC> to be a:
	    exitm
	endif
    endif
    ifdef   ret_&cc                     ;; if ret_<CC> defined
	if (($ - ret_&cc) le 126) and ($ gt ret_&cc)
					;;     if ret_<CC> is near enough
	    a:  j&cc    ret_&cc         ;;         a: j<CC> to ret_<CC>
	    ret_&cc = a                 ;;         define ret_<CC> to be a:
	    exitm
	endif
    endif
    j&ncc   a                           ;; j<NCC> a:
    return                              ;; return
    a:                                  ;; a:
    ret_&cc = ret_l                     ;; define ret_<CC> to be ret_l
endm
.xcref  condret

BREAK <RETZ - return if zero, links up shortwise if necessary>

retz    macro
    condret z,nz
endm
.xcref  retz

BREAK <RETNZ - return if not zero, links up shortwise if necessary>

retnz   macro
    condret nz,z
endm
.xcref  retnz

BREAK <RETC - return if carry set, links up shortwise if necessary>

retc    macro
    condret c,nc
endm
.xcref  retc

BREAK <RETNC - return if not carry, links up shortwise if necessary>

retnc   macro
    condret nc,c
endm
.xcref  retnc

BREAK <CONTEXT - set the DOS context to a particular register>

context macro   r
	PUSH    SS
	POP     r
	ASSUME  r:DOSGROUP
endm
.xcref  context

BREAK <SaveReg - save a set of registers>

SaveReg MACRO   reglist                 ;; push those registers
IRP reg,<reglist>
	?stackdepth = ?stackdepth + 1
	PUSH    reg
ENDM
ENDM
.xcref  SaveReg

BREAK <RestoreReg - unsave some registers>

RestoreReg  MACRO   reglist             ;; pop those registers
IRP reg,<reglist>
	?stackdepth = ?stackdepth - 1
	POP     reg
ENDM
ENDM
.xcref  RestoreReg

BREAK <Critical section macros>

EnterCrit MACRO section
	Invoke  E&section
ENDM

LeaveCrit MACRO section
	Invoke  L&section
ENDM

Break   <message - display a message>

AsmVars <ShareF,Cargs,Redirector>

if debug
fmt     MACRO   typ,lev,fmts,args
local   a,b,c
	PUSHF
IFNB <typ>
	TEST    BugTyp,typ
	JZ      c
	CMP     BugLev,lev
	JB      c
ENDIF
	PUSH    AX
	PUSH    BP
	MOV     BP,SP
If (not sharef) and (not redirector)
Table   segment
a       db      fmts,0
Table   ends
	MOV     AX,OFFSET DOSGROUP:a
else
	jmp     short b
a       db      fmts,0
if sharef
b:      mov     ax,offset share:a
else
b:      mov     ax,offset netwrk:a
endif
endif
	PUSH    AX
cargs = 2
IRP item,<args>
IFIDN   <AX>,<item>
	MOV     AX,[BP+2]
ELSE
	MOV     AX,item
ENDIF
	PUSH    AX
cargs = cargs + 2
ENDM
	invoke  PFMT
	ADD     SP,Cargs
	POP     BP
	POP     AX
c:
	POPF
ENDM
else
fmt macro
endm
endif

Break   <DOSAssume - validate assumes>

AsmVar  Debug,$temp

IF debug
DOSAssume   Macro   reg,reglist,message
local a,b
    IFIDN <reg>,<CS>
	$temp   =   1
    ELSE
	IFIDN <reg>,<SS>
	    $temp   =   0
	ELSE
	    %out ***** Invalid DOS register reg in DOSAssume *****
	ENDIF
    ENDIF
    IRP r,<reglist>
	IFIDN <r>,<DS>
	    $temp = $temp OR 2
	ELSE
	    IFIDN <r>,<ES>
		$temp = $temp OR 4
	    ELSE
		%out ***** Invalid register reg in DOSAssume *****
	    ENDIF
	ENDIF
    ENDM
	PUSH    AX
	MOV     AX,$temp
	PUSH    AX
IF SHAREF
	MOV     AX,OFFSET a
ELSE
	MOV     AX,OFFSET DOSGroup:a
ENDIF
	PUSH    AX
	Invoke  SegCheck
	POP     AX
IF NOT SHAREF
Table   SEGMENT
a       DB      message,0
Table   ends
ELSE
	JMP     SHORT a
b       DB      message,0
a:
ENDIF
IRP r,<reglist>
    ASSUME  r:DOSGroup
ENDM
ENDM
ELSE
DOSAssume   Macro   reg,reglist,message
IRP r,<reglist>
    ASSUME  r:DOSGroup
ENDM
ENDM
ENDIF

BREAK   <ASSERT - make assertions about registers>

IF DEBUG
Assert  MACRO   kind, objs, message
	LOCAL   a,b
    IFIDN   <kind>,<Z>
	CMP     objs,0
	JZ      a
	fmt <>,<>,<message>
a:
    ELSE
	IFIDN   <kind>,<NZ>
	CMP     objs,0
	JNZ     a
	fmt <>,<>,<message>
a:
	ELSE
    PUSH    AX
	    IRP obj,<objs>
	PUSH    obj
	    ENDM
	    IF SHAREF
    MOV     AX,OFFSET b
	    ELSE
    MOV     AX,OFFSET DOSGroup:b
	    ENDIF
    PUSH    AX
	    IFIDN   <kind>,<ISBUF>
	Invoke  BUFCheck
	    ENDIF
	    IFIDN   <kind>,<ISSFT>
	Invoke  SFTCheck
	    ENDIF
	    IFIDN   <kind>,<ISDPB>
	Invoke  DPBCheck
	    ENDIF
    POP     AX
	    IF SHAREF
    JMP SHORT a
b   DB  Message,0
a:
	    ELSE
Table   segment
b   db  Message,0
Table   ends
	    ENDIF
	ENDIF
    ENDIF
ENDM
ELSE
Assert  Macro
ENDM
ENDIF

Break   <CallInstall - hook to installable pieces>

CallInstall MACRO   name,mpx,fn,save,restore
IF Installed
    IFNB    <save>
	SaveReg <save>
    ENDIF
	MOV     AX,(mpx SHL 8) + fn
	INT     2Fh
    IFNB    <restore>
	RestoreReg  <restore>
    ENDIF
ELSE
	Invoke  name
ENDIF
ENDM

Break   <Stack frame manipulators>

localvar    macro   name,length
local   a
	ifidn   <length>,<BYTE>
	    ?frame =  ?frame + 1
	    a = ?frame
	    name EQU  BYTE PTR [BP-a]
	else
	    ifidn   <length>,<WORD>
		?frame =  ?frame + 2
		a = ?frame
		name EQU  WORD PTR [BP-a]
	    else
		ifidn   <length>,<DWORD>
		    ?frame =  ?frame + 4
		    a = ?frame
		    name EQU  DWORD PTR [BP-a]
		    name&l EQU  WORD PTR [BP-a]
		    name&h EQU  WORD PTR [BP-a+2]
		else
		    ?frame =  ?frame + length
		    a = ?frame
		    name EQU  BYTE PTR [BP-a]
		endif
	    endif
	endif
endm

enter   macro
	push    bp
	mov     bp,sp
	sub     sp,?frame
endm

leave   macro
	mov     sp,bp
	pop     bp
endm

Argvar  macro   name,length
local   a
	ifidn   <length>,<BYTE>
	    a = ?aframe
	    ?aframe =  ?aframe + 1
	    name EQU  BYTE PTR [BP+a]
	else
	    ifidn   <length>,<WORD>
		a = ?aframe
		?aframe =  ?aframe + 2
		name EQU  WORD PTR [BP+a]
	    else
		ifidn   <length>,<DWORD>
		    a = ?aframe
		    ?aframe =  ?aframe + 4
		    name EQU  DWORD PTR [BP+a]
		    name&l EQU  WORD PTR [BP+a]
		    name&h EQU  WORD PTR [BP+a+2]
		else
		    a = ?aframe
		    ?aframe =  ?aframe + length
		    name EQU  BYTE PTR [BP+a]
		endif
	    endif
	endif
endm

BREAK   <errnz - generate compilation errors>

errnz   macro   x
if x NE 0
    %out ***** FATAL error: x <> 0
foobar
endif
endm
