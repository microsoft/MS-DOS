;
; Macro file for MSDOS.
;

SUBTTL BREAK a listing into pages and give new subtitles
PAGE
BREAK MACRO subtitle
 SUBTTL subtitle
 PAGE
ENDM

BREAK <I_NEED: declare a variable external, if necessary, and allocate a size>

;
; declare a variable external and allocate a size
;
I_NEED MACRO sym,len
 DATA SEGMENT BYTE PUBLIC 'DATA'
 IFIDN <len>,<WORD>
 EXTRN &sym:WORD
 ELSE
 IFIDN <len>,<DWORD>
 EXTRN &sym:DWORD
 ELSE
 EXTRN &sym:BYTE
 ENDIF
 ENDIF
 DATA ENDS
ENDM

;
; call a procedure that may be external. The call will be short.
;
invoke MACRO name
.xcref
 IF2
 IFNDEF name
 EXTRN name:NEAR
 ENDIF
 ENDIF
.cref
 CALL name
ENDM

PAGE
;
; jump to a label that may be external. The jump will be near.
;
transfer MACRO name
.xcref
 IF2
 IFNDEF name
 EXTRN name:NEAR
 ENDIF
 ENDIF
.cref
 JUMP name
ENDM

;
; get a short address in a word
;
short_addr MACRO name
 IFDIF <name>,<?>
.xcref
 IF2
 IFNDEF name
 EXTRN name:NEAR
 ENDIF
 ENDIF
.cref
 DW OFFSET DOSGROUP:name
 ELSE
 DW ?
 ENDIF
ENDM

;
; get a long address in a dword
;
long_addr MACRO name
.xcref
 IF2
 IFNDEF name
 EXTRN name:NEAR
 ENDIF
.cref
 DD name
ENDM

;
; declare a PROC near or far but PUBLIC nonetheless
;
procedure MACRO name,distance
 PUBLIC name
name PROC distance
ENDM

PAGE
;
; define a data item to be public and of an appropriate size/type
;
I_AM MACRO name,size
 PUBLIC name

 IFIDN <size>,<WORD>
name DW ?
 ELSE
 IFIDN <size>,<DWORD>
name DD ?
 ELSE
 IFIDN <size>,<BYTE>
name DB ?
 ELSE
name DB size DUP (?)
 ENDIF
 ENDIF
 ENDIF
ENDM

PAGE
;
; call the macro chain
;
do_ext macro
endm

PAGE

;
; define an entry in a procedure
;
entry macro name
 PUBLIC name
name:
endm

BREAK <ERROR - print a message and then jump to a label>

error macro code
 local a
.xcref
 MOV AL,code
 transfer SYS_RET_ERR
.cref
ENDM

BREAK <JUMP - real jump that links up shortwise>
;
; given a label <lbl> either 2 byte jump to another label <lbl>_J
; if it is near enough or 3 byte jump to <lbl>
;

jump macro lbl
 local a
.xcref
 a:
 ifndef lbl&_J ;; is this the first invocation
 JMP lbl
 ELSE
 IF lbl&_J GE $
 JMP lbl
 ELSE
 IF ($-lbl&_J) GT 126 ;; is the jump too far away?
 JMP lbl
 ELSE ;; do the short one...
 JMP lbl&_J
 ENDIF
 ENDIF
 ENDIF
 lbl&_j = a
.cref
endm

BREAK <RETURN - return from a function>

return macro
 local a
.xcref
a:
 RET
ret_l = a
.cref
endm

BREAK <CONDRET - conditional return>

makelab macro l,cc,ncc
 local a
 j&ncc a ;; j<NCC> a:
 return ;; return
 a: ;; a:
 ret_&cc = ret_l ;; define ret_<CC> to be ret_l
endm

condret macro cc,ncc
 local a,b
 ifdef ret_l ;; if ret_l is defined
 if (($ - ret_l) le 126) and ($ gt ret_l)
 ;; if ret_l is near enough then
 a: j&cc ret_l ;; a: j<CC> to ret_l
 ret_&cc = a ;; define ret_<CC> to be a:
 else
 makelab a,cc,ncc
 endif
 else
 ifdef ret_&cc ;; if ret_<CC> defined
 if (($ - ret_&cc) le 126) and ($ gt ret_&cc)
 ;; if ret_<CC> is near enough
 a: j&cc ret_&cc ;; a: j<CC> to ret_<CC>
 ret_&cc = a ;; define ret_<CC> to be a:
 else
 makelab a,cc,ncc
 endif
 else
 makelab a,cc,ncc
 endif
 endif
endm
;condret macro cc,ncc
; local a,b
; ifdef ret_l ; if ret_l is defined
; if (($ - ret_l) le 126) and ($ gt ret_l)
; ; if ret_l is near enough then
; a: j&cc ret_l ; a: j<CC> to ret_l
; ret_&cc = a ; define ret_<CC> to be a:
; exitm
; endif
; endif
; ifdef ret_&cc ; if ret_<CC> defined
; if (($ - ret_&cc) le 126) and ($ gt ret_&cc)
; ; if ret_<CC> is near enough
; a: j&cc ret_&cc ; a: j<CC> to ret_<CC>
; ret_&cc = a ; define ret_<CC> to be a:
; exitm
; endif
; endif
; j&ncc a ; j<NCC> a:
; return ; return
; a: ; a:
; ret_&cc = ret_l ; define ret_<CC> to be ret_l
;endm
;
BREAK <RETZ - return if zero, links up shortwise if necessary>

retz macro
 condret z,nz
endm

BREAK <RETNZ - return if not zero, links up shortwise if necessary>

retnz macro
 condret nz,z
endm

BREAK <RETC - return if carry set, links up shortwise if necessary>

retc macro
 condret c,nc
endm

BREAK <RETNC - return if not carry, links up shortwise if necessary>

retnc macro
 condret nc,c
endm

BREAK <CONTEXT - set the DOS context to a particular register>

context macro r
 PUSH SS
 POP r
 ASSUME r:DOSGROUP
endm
