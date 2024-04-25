;**	DEFDBUG.ASM - Debugging Macro Definitions
;
;
;	DEBUG	n,m,<format string>, <arg list>
;
;

.sall

DEBUG	MACRO	N,M,string,args
 local b,c
 IFDEF DEBUGFLG
  pushf
  DEBUGTST N,M
  jz	b
  push ax
  push bp
  call	c		;; push address of string
  DB	'&string',0
c:	mov	bp,sp
; IFNB	    <args>
 IRP	 Y,<args>
  IFIDN	  <Y>,<ax>
    push 4[bp]
  ELSE
  IFIDN	  <Y>,<AX>
    push 4[bp]
  ELSE
  IFIDN	  <Y>,<bp>
    push 2[bp]
  ELSE
  IFIDN	  <Y>,<BP>
    push 2[bp]
  ELSE
    mov	    ax,Y
    push ax
   ENDIF
   ENDIF
   ENDIF
   ENDIF
 ENDM
; ENDIF
  call	  DPRINTF
  mov	  sp,bp
  pop	  ax		  ;; discard format string offset
  pop	  bp
  pop	  ax
b:	popf
   ENDIF
ENDM




;**	ERRNZ - generate assembly error if arg != 0
;

ERRNZ	MACRO	EXPR
 IF1
  IFE	  expr
  ELSE
  RADIX	  0	  ; CONDITION NOT MET - ERROR
  ENDIF
 ENDIF
	ENDM


;**	DBBEG - Start debugging range
;

DBBEG	MACRO	N,M
 LOCAL	 lab
 IFDEF	 DEBUGFLG
  pushf
  DEBUGTST N,M
  jnz	  lab			  ;; am to do it
  DBJMP	  %DBCNT
lab:
    ENDM



DBJMP	MACRO	N
 jmp DBLAB&N
	ENDM


;**	DEBUGTST - Test Debug Flags
;
;	DEBUGTST   n,m
;
;	Where N and M are bit masks.
;
;	If one or more of the bits in N is set in the high byte
;	of BUGBITS, and one or more of the bits in M is set in
;	the low byte of BUGBITS then clear the Z flag.
;
;	In other words:
;
;	If both masks show a "hit" clear 'Z' else set 'Z'
;
;	USES	FLAGS

DEBUGTST    MACRO   N,M
	LOCAL	A
	test	BYTE PTR BUGBITS,n
	jz	A
	test	BYTE PTR BUGBITS+1,m
A:
	ENDM

DBEND	MACRO
	DBLAB	%DBCNT
DBCNT	=	DBCNT+1
	popf
	ENDM

DBLAB	MACRO	N
DBLAB&N:
	ENDM

  DBCNT = 1
