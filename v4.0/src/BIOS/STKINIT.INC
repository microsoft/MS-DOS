;
;	To follow the standard interrupt sharing scheme, MSSTACK.ASM	       ;3.30
;	has been modified.  This initialization routine also has to	       ;3.30
;	be modified because for the interrupt level 7 and 15, FirstFlag        ;3.30
;	should be set to signal that this interrupt handler is the	       ;3.30
;	first handler hooked to this interrupt vector.			       ;3.30
;	We determine this by looking at the instruction pointed by	       ;3.30
;	this vector.  If it is IRET, then this handler should be the	       ;3.30
;	first one.  In our case, only the interrupt vector 77h is the	       ;3.30
;	interrupt level 15. (We don't hook interrupt level 7.)                 ;3.30
; 9/10/1986 							       ;3.30
;	The followings are mainly due to M.R.T; PTM fix of P886 12/3/86;3.30
;	Some design changes are needed to the above interrupt sharing	       ;3.30
;	method.  The above sharing scheme assumes that 1). Interrupt	       ;3.30
;	sharing is NEVER done on levels that have BIOS support. 2). "Phantom"  ;3.30
;	interrupts would only be generated on levels 7 and 15.		       ;3.30
;	These assumptions are not true any more. We have to use the FirstFlag  ;3.30
;	for EVERY level of interrupt.  We will set the firstFlag on the following;3.30
;	conditions:							       ;3.30
;	 a.	 if the CS portion of the vector is 0000, then "first"         ;3.30
;	 b. else if CS:IP points to valid shared header, then NOT "first"      ;3.30
;	 c. else if CS:IP points to an IRET, then "first"                      ;3.30
;	 d. else if CS:IP points to DUMMY, then "first"                        ;3.30
;	where DUMMY is - the CS portion must be F000, and the IP portion must  ;3.30
;	be equal to the value at F000:FF01. This location is the initial value ;3.30
;	from VECTOR_TABLE for interrupt 7, one of the preserved addresses in all;3.30
;	the BIOSes for all of the machines.				       ;3.30
;									       ;3.30
;	System design group requests BIOS to handle the phantom interrupts.    ;3.30
;									       ;3.30
;	The "Phantom" interrupt is an illegal interrupt such as an interrupt   ;3.30
;	produced by the bogus adapter card even without interrupt request is   ;3.30
;	set.  More specifically, 1). The 8259 has a feature when running in    ;3.30
;	edge triggered mode to latch a pulse and present the interrupt when    ;3.30
;	the processor indicates interrupt acknowledge (INTA).  The interrupt   ;3.30
;	pulse was exist at the time of INTA to get a "phantom" interrupt.      ;3.30
;	2). or, this is caused by adapter cards placing a glitch on the        ;3.30
;	interrupt line. 						       ;3.30
;									       ;3.30
;	To handle those "phantom" interrupts, the main stack code will check   ;3.30
;	the own FirstFlag, and if it is not "first" (which means the forward   ;3.30
;	pointer points to the legal shared interrupt handler), then pass the   ;3.30
;	control.  If it is the first, then the following action should be      ;3.30
;	taken.	We don't have to implement skack logic in this case.           ;3.30
;									       ;3.30
;	To implement this logic, we rather choose a simple method.	       ;3.30
;	If ont of the above "FirstFlag" conditions is met, we are not          ;3.30
;	going to hook this interrupt vector.  The reason is if the original    ;3.30
;	vector points to "IRET" and do nothing, we don't need                  ;3.30
;	to implement the stack logic for it.  This will simplify implementation;3.30
;	while maintaining compatibility with the old version of DOS.	       ;3.30
;	This implies that in the main stack code, there might be a stack code  ;3.30
;	that will never be used, a dead code.				       ;3.30
;									       ;3.30
; 12/3/86								       ;3.30
									       ;3.30
;In - CS, DS -> sysinitseg, ES -> relocated stack code & data.		       ;3.30
									       ;3.30
	PAGE								       ;3.30
	assume  ds:sysinitseg			; sunilp SB340
StackInit	proc near						       ;3.30
									       ;3.30
	PUSH	AX				;SAVE ALL		       ;3.30
	PUSH	DS							       ;3.30
	PUSH	ES							       ;3.30
	PUSH	BX							       ;3.30
	PUSH	CX							       ;3.30
	PUSH	DX							       ;3.30
	PUSH	DI							       ;3.30
	PUSH	SI							       ;3.30
	PUSH	BP							       ;3.30
									       ;3.30
;Currently ES -> stack code area					       ;3.30
	MOV	AX, cs:[STACK_COUNT]		   ;defined in CS	       ;3.30
	MOV	es:[STACKCOUNT], AX		   ;defined in STACK CODE AREA ;3.30
	MOV	AX, [STACK_SIZE]		;in CS			       ;3.30
	MOV	es:[STACKSIZE], AX		   ;			       ;3.30
	MOV	AX, WORD PTR cs:[STACK_ADDR]	   ; OFFSET		       ;3.30
	MOV	WORD PTR es:[STACKS], AX				       ;3.30
	MOV	AX, WORD PTR cs:[STACK_ADDR+WORD]  ; SEGMENT		       ;3.30
	MOV	WORD PTR es:[STACKS+WORD], AX				       ;3.30
									       ;3.30
; INITIALIZE THE DATA FIELDS WITH THE PARAMETERS			       ;3.30
									       ;3.30
; "FIRSTENTRY" WILL ALWAYS BE AT STACKS                                        ;3.30
									       ;3.30
	MOV	BP, word ptr es:STACKS		   ; GET OFFSET OF STACK       ;3.30
	MOV	es:FIRSTENTRY,BP					       ;3.30
									       ;3.30
; THE STACKS WILL ALWAYS IMMEDIATELY FOLLOW THE TABLE ENTRIES		       ;3.30
									       ;3.30
	MOV	AX,ENTRYSIZE						       ;3.30
	MOV	CX,es:STACKCOUNT					       ;3.30
	MUL	CX							       ;3.30
	ADD	AX,BP							       ;3.30
	MOV	es:STACKAT,AX						       ;3.30
	MOV	BX,AX							       ;3.30
	SUB	BX,2							       ;3.30
									       ;3.30
; ZERO THE ENTIRE STACK AREA TO START WITH				       ;3.30
									       ;3.30
	MOV	DI,es:STACKAT						       ;3.30
	MOV	AX,es:STACKSIZE 					       ;3.30
	MUL	CX							       ;3.30
	MOV	CX,AX							       ;3.30
	xor	ax,ax							       ;3.30
	push	es							       ;3.30
	pop	ds				;ds = Relocated stack code seg.;3.30
	assume	ds:nothing						       ;3.30
;Now, DS -> stack code area						       ;3.30
	MOV	ES, word ptr ds:[STACKS+2]	   ; GET SEGMENT OF STACK AREA.;3.30
	CLD								       ;3.30
	REP	STOSB							       ;3.30
									       ;3.30
	MOV	CX, ds:STACKCOUNT					       ;3.30
									       ;3.30
; LOOP FOR "COUNT" TIMES, BUILDING A TABLE ENTRY                               ;3.30
;  cs = sysinitseg, ds = Relocated stack code seg , es = segment of stack space;3.30
;  CX = NUMBER OF ENTRIES						       ;3.30
;  ES:BP => BASE OF STACKS - 2						       ;3.30
;  ES:BX => FIRST TABLE ENTRY						       ;3.30
									       ;3.30
BUILDLOOP:								       ;3.30
	MOV	ALLOCBYTE,FREE						       ;3.30
	MOV	INTLEVEL,AL			;AX = 0 		       ;3.30
	MOV	SAVEDSP,AX						       ;3.30
	MOV	SAVEDSS,AX						       ;3.30
	ADD	BX,ds:STACKSIZE 					       ;3.30
	MOV	NEWSP,BX						       ;3.30
	MOV	ES:[BX],BP						       ;3.30
	ADD	BP,ENTRYSIZE						       ;3.30
									       ;3.30
	LOOP	BUILDLOOP						       ;3.30
									       ;3.30
	SUB	BP,ENTRYSIZE						       ;3.30
	MOV	ds:LASTENTRY,BP 					       ;3.30
	MOV	ds:NEXTENTRY,BP 					       ;3.30
									       ;3.30
	push	ds							       ;3.30
	mov	ax, 0f000h		;loook at the model byte	       ;3.30
	mov	ds, ax							       ;3.30
	cmp	ds:byte ptr [0fffeh], mdl_convert	;convertible?	       ;3.30
	pop	ds							       ;3.30
	jne	Skip_disableNMIS					       ;3.30
									       ;3.30
	MOV	AL,07H				; DISABLE Convertible NMIS	       ;3.30
	OUT	72H,AL							       ;3.30
									       ;3.30
Skip_disableNMIS:							       ;3.30
	XOR	AX,AX							       ;3.30
	MOV	es,AX				;es - SEGID OF VECTOR TABLE AT 0;3.30
	ASSUME	es:NOTHING			;ds - Relocated Stack code segment;3.30
									       ;3.30
	CLI								       ;3.30
									       ;3.30
	IRP	AA,<02,08,09,70>					       ;3.30
									       ;3.30
	MOV	SI,AA&H*4		;PASS WHERE VECTOR IS TO BE ADJUSTED   ;3.30
	mov	di, offset Int19OLD&AA	       ;we have to set OLD&AA for Int19 handler too.;3.30
	MOV	BX,OFFSET OLD&AA	;PASS WHERE TO SAVE ORIGINAL OWNER POINTER;3.30
	MOV	DX,OFFSET INT&AA	;PASS WHERE NEW HANDLER IS	       ;3.30
	CALL	NEW_INIT_LOOP		;ADJUST THE VECTOR TO NEW HANDLER,     ;3.30
					;  SAVING POINTER TO ORIGINAL OWNER    ;3.30
	ENDM								       ;3.30
									       ;3.30
	IRP	AA,<0A,0B,0C,0D,0E,72,73,74,76,77>	;shared interrupts     ;3.30
									       ;3.30
	MOV	SI,AA&H*4		;PASS WHERE VECTOR IS TO BE ADJUSTED   ;3.30
	push	ds			;save relocated stack code segment     ;3.30
	lds	bx, es:[si]		;ds:bx -> original interrupt handler   ;3.30
	push	ds							       ;3.30
	pop	dx			;dx = segment value		       ;3.30

	cmp	dx,0
	jz	int&AA&_first

	cmp	byte ptr ds:[bx],0cfh	;Does vector point to an IRET?
	jz	int&AA&_first

	cmp	word ptr ds:[bx.6],424Bh ;Magic offset (see INT&AA, msstack.inc)
	jz	int&AA&_Not_first

	cmp	dx,0f000h		;ROM BIOS segment
	jnz	int&AA&_Not_first

	push	es
	push	dx
	mov	dx,0f000h
	mov	es,dx
	cmp	bx,word ptr es:0ff01h
       	pop	dx
	pop	es
	jz	int&AA&_first

int&AA&_Not_first:			 ;Not the first. We are going to hook vector.;3.30
	pop	ds							       ;3.30
	mov	di, offset Int19OLD&AA	;we have to set OLD&AA for Int19 handler too.;3.30
	mov	BX, OFFSET OLD&AA	;PASS WHERE TO SAVE ORIGINAL OWNER POINTER;3.30
	MOV	DX, OFFSET INT&AA	;PASS WHERE NEW HANDLER IS	       ;3.30
	CALL	NEW_INIT_LOOP		;ADJUST THE VECTOR TO NEW HANDLER, SAVING;3.30
					;POINTER TO ORIGINAL OWNER.	       ;3.30
	jmp	short int&AA&_end					       ;3.30
int&AA&_first:				 ;the first. Don't have to hook stack code.;3.30
	pop	ds							       ;3.30
int&AA&_end:								       ;3.30
									       ;3.30
	ENDM								       ;3.30
									       ;3.30
	push	ds							       ;3.30
	mov	ax, 0f000h		;loook at the model byte	       ;3.30
	mov	ds, ax							       ;3.30
	cmp	ds:byte ptr [0fffeh], mdl_convert	;PC convertible?	       ;3.30
	pop	ds							       ;3.30
	jne	Skip_EnableNMIS 					       ;3.30
									       ;3.30
	MOV	AL,27H				; ENABLE Convertible NMIS	       ;3.30
	OUT	72H,AL							       ;3.30
									       ;3.30
Skip_EnableNMIS:							       ;3.30
	STI								       ;3.30
	MOV	AX,code 						       ;3.30
	MOV	DS,AX							       ;3.30
	ASSUME	DS:CODE 						       ;3.30
									       ;3.30
;	MOV	SI,OFFSET STKMSG1					       ;3.30
;	CALL	WRMSG							       ;3.30
									       ;3.30
	mov	[INT19SEM],1		; INDICATE THAT INT 19		       ;3.30
					; INITIALIZATION IS COMPLETE	       ;3.30
									       ;3.30
	POP	BP			; RESTORE ALL			       ;3.30
	POP	SI							       ;3.30
	POP	DI							       ;3.30
	POP	DX							       ;3.30
	POP	CX							       ;3.30
	POP	BX							       ;3.30
									       ;3.30
	POP	ES							       ;3.30
	POP	DS							       ;3.30
	assume	ds:sysinitseg						       ;3.30
	POP	AX							       ;3.30
	RET								       ;3.30
STACKINIT	ENDP							       ;3.30
;									       ;3.30
									       ;3.30
NEW_INIT_LOOP PROC NEAR 						       ;3.30
;INPUT: SI=OFSET INTO VECTOR TABLE OF THE PARTICULAR INT VECTOR BEING ADJUSTED ;3.30
;	BX=ds:OFFSET OF OLDxx, WHERE WILL BE SAVED THE POINTER TO ORIGINAL OWNER;3.30
;	DX=ds:OFFSET OF INTxx, THE NEW INTERRUPT HANDLER		       ;3.30
;	di=offset value of Int19OLD&AA variable in BIOS.		       ;3.30
;	es=ZERO, SEGID OF VECTOR TABLE					       ;3.30
;	ds=Relocated Stack code segment 				       ;3.30
									       ;3.30
	MOV	AX,es:[SI+0]	       ;REMEMBER OFFSET IN VECTOR	       ;3.30
	MOV	WORD PTR ds:[BX],AX	  ; TO ORIGINAL OWNER in DS	       ;3.30
	MOV	AX,es:[SI+2]	       ;REMEMBER SEGID IN VECTOR	       ;3.30
	MOV	WORD PTR ds:[BX]+2,AX	  ; TO ORIGINAL OWNER in DS	       ;3.30
	push	ds							       ;3.30
	mov	ax, code						       ;3.30
	mov	ds, ax			;Set Int19OLDxx value in BIOS for      ;3.30
	mov	ax,es:[si+0]		;Int 19 handler 		       ;3.30
	mov	word ptr ds:[di],ax					       ;3.30
	mov	ax,es:[si+2]						       ;3.30
	mov	word ptr ds:[di]+2,ax					       ;3.30
	pop	ds							       ;3.30
									       ;3.30
	MOV	WORD PTR es:[SI+0],DX  ;SET VECTOR TO POINT TO NEW INT HANDLER ;3.30
	MOV	es:[SI+2],ds						       ;3.30
	RET								       ;3.30
NEW_INIT_LOOP ENDP							       ;3.30
									       ;3.30
