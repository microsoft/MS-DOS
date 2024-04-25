;
; This file contains three macros used in debugging the system.  If the
; variable "itest" (in msbio.asm) is nonzero code is included in the
; modules to print debugging messages.	The level of debugging is controlled
; by the value of the variable fTestBits in msbio.asm.	Specific bits in
; the variable determine which messages to print.  The equ's below tell
; which bits control which funcitons.  For example the fifth bit
; cooresponds to disk activity (see fTestDisk equ below).
;
;   The macros in the file are:
;
;	message    Prints an ascii string on the screen.
;		   Example usage:
;
;		      message fTestDisk, <"Start Disk Write", CR, LF>
;		      message fTestINIT, <"Begin BDS initialization">
;
;
;	MNUM	   Print the value in a register or memory location on
;		   the screen. Value is displayed in hex.
;		   Usage:
;		      MNUM  bitpattern, valueLocation
;
;		   valueLocation is typically a regester:
;
;		      mnum  fTestCom, AX
;		      mnum  fTestDisk, DX
;
;		   ValueLocation can also be a memory location:
;
;		      mnum  fTestINIT, Final_Dos_Location
;
;		   If no valueLocation is given the macro defaults to
;		   the BX register.
;
;	ZWAIT	    Stops the program until any key is pressed.
;
;
;	The three macros preserve all register values.	If "test" is zero
;	defined during assembly then the  marco produce no code.
;

	IF	iTEST							  ;3.30
	   IFNDEF MSGOUT						  ;3.30
		EXTRN	MSGOUT:NEAR,MSGNUM:NEAR 			  ;3.30
	   ENDIF							  ;3.30
	   IFNDEF NUMBUF						  ;3.30
	    EXTRN   NUMBUF:BYTE,DIGITS:BYTE,FTESTBITS:WORD		  ;3.30
	   ENDIF							  ;3.30
	   IFNDEF DUMPBYTES						  ;3.30
		EXTRN	DUMPBYTES:NEAR,OUTCHAR:NEAR,HEX_TO_ASCII:NEAR	  ;3.30
	   ENDIF							  ;3.30



fTestALL    equ     1111111111111111b	; watch everything
fTestHARD   equ     0000000000000001b	; watch hard disk initialization
fTest96     equ     0000000000000010b	; watch 96 tpi activity
FTEST13     EQU     0000000000000100B	; WATCH INT 13 ACTIVITY 	  ;3.30
FTESTCOM    EQU     0000000000001000B	; WATCH PACKET ACTIVITY 	  ;3.30
FTESTINIT   EQU     0000000000010000B	; WATCH INITIALIZATION MESSAGES   ;3.30
FTESTDISK   EQU     0000000000100000B	; WATCH DISK DEVICE DRIVER CALLS  ;3.30
FTESTCON    EQU     0000000001000000B	; WATCH SYSTEM WAIT ACTIVITY IN CO;3.30 NSOLE
FtestClock  equ     0000000010000000b	; wathc clock device  5/2/86  ;3.30


;
; message macro -- see above for description
;

MESSAGE MACRO	Bits,msg
	    LOCAL   A,B 						  ;3.30
	jmp	SHORT b
a:	db	msg,0
b:	push	SI
	push	AX
	mov	AX,Bits
	mov	SI,OFFSET a
	call	MSGOUT
	pop	AX
	pop	SI
endm


;
; mnum macro -- see above for description
;

MNum	MACRO	Bits,num
	push	AX
ifb <num>
	mov	AX,Bits
	call	MSGNUM
else
	push	BX
	mov	BX,num
	mov	AX,Bits
	call	MSGNUM
	pop	BX
endif
	pop	AX
endm


;
; zwait macro -- see above for description
;

ZWAIT	MACRO
	Message fTestALL,<"? ">
	CALL	ZWAITrtn
ENDM

ZWAITrtn:
	pushf				; save the flags
	push	AX			; preserve AX
	xor	AH, AH			; set command to get character ;3.30*
	int	16h			; call rom keyboard routine    ;3.30*
	pop	AX			; restore AX
	popf				; restore the flags
	ret

;Dump_byte dumps the memory contents in hex. 				  ;3.30
;DUMPOFFLABEL should be a label or a variable defined in DUMPSEG.	  ;3.30
DUMP_BYTE	MACRO	DUMPSEG, DUMPOFFLABEL, BYTELENGTH		  ;3.30
	push	es							  ;3.30
	PUSH	DS							  ;3.30
	PUSH	SI							  ;3.30
	PUSH	CX							  ;3.30
									  ;3.30
	MOV	CX, DUMPSEG						  ;3.30
	MOV	DS, CX							  ;3.30
	MOV	SI, OFFSET DUMPOFFLABEL 				  ;3.30
	MOV	CX, BYTELENGTH						  ;3.30
	call	dumpbytes						  ;3.30
									  ;3.30
	POP	CX							  ;3.30
	POP	SI							  ;3.30
	POP	DS							  ;3.30
	pop	es							  ;3.30
	ENDM								  ;3.30
									  ;3.30
;Dump_Byte_Reg dumps the memory contents in hex. -  4/9/86		  ;3.30
;DUMPOFFREG should be a register contains the offset value in DUMPSEG.	  ;3.30
DUMP_BYTE_REG	MACRO	DUMPSEG, DUMPOFFREG, BYTELENGTH 		  ;3.30
	push	es							  ;3.30
	PUSH	DS							  ;3.30
	PUSH	SI							  ;3.30
	PUSH	CX							  ;3.30
									  ;3.30
	MOV	CX, DUMPSEG						  ;3.30
	MOV	DS, CX							  ;3.30
	MOV	SI, DUMPOFFREG						  ;3.30
	MOV	CX, BYTELENGTH						  ;3.30
	call	dumpbytes						  ;3.30
									  ;3.30
	POP	CX							  ;3.30
	POP	SI							  ;3.30
	POP	DS							  ;3.30
	pop	es							  ;3.30
	ENDM								  ;3.30

else
		; if test is not defined then make macro into null statements
Message macro
ENDM

MNUM	macro
ENDM

ZWAIT	macro
ENDM

DUMP_BYTE   MACRO							  ;3.30
	    ENDM							  ;3.30
DUMP_BYTE_REG MACRO							  ;3.30
	    ENDM							  ;3.30
	ENDIF								  ;3.30
									  ;3.30
PATHSTART MACRO INDEX,ABBR						  ;3.30
	IFDEF	PATHGEN 						  ;3.30
	    PUBLIC  ABBR&INDEX&S,ABBR&INDEX&E				  ;3.30
	    ABBR&INDEX&S LABEL	 BYTE					  ;3.30
	ENDIF								  ;3.30
	ENDM								  ;3.30
									  ;3.30
PATHEND MACRO	INDEX,ABBR						  ;3.30
	IFDEF	PATHGEN 						  ;3.30
	    ABBR&INDEX&E LABEL	 BYTE					  ;3.30
	ENDIF								  ;3.30
	ENDM								  ;3.30

