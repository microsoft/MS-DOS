

	page 58,132
;******************************************************************************
	TITLE	EXTPOOL -  MODULE to manage a pool of extended memory
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:	EXTPOOL - Manage a pool of extended memory.
;
;   Version:	0.01
;
;   Date:	Sep 1, 1988
;
;   Author:	ISP (ISP)
;
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;******************************************************************************
;   Functional Description:
;
;   "Fixit Orders"  Crisis mode file.  We need to ship data structures up hi.
;    So at init time we get a pool of extended memory and manage it for the
;    fixit routine.  Services provided include initialise, allocate and
;    blkmov to the memory.
;
;******************************************************************************
.lfcond
.386p

	page
;******************************************************************************
;		P U B L I C   D E C L A R A T I O N S
;******************************************************************************
	public	    pool_initialise
	public	    get_buffer

	page
;******************************************************************************
;			L O C A L   C O N S T A N T S
;******************************************************************************
;

;******************************************************************************
;			INCLUDE FILES
;******************************************************************************
    include  vdmseg.inc     ; segment definitions

	page
;******************************************************************************
;			E X T E R N A L    R E F E R E N C E S
;******************************************************************************
;
;
	page
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************

;*************************************************************************
;
; DATA
;
;*************************************************************************

LAST   SEGMENT

ext_start   dw	    0000h	    ; start of the pool of extended memory
	    dw	    0010h	    ; 24 bit address

ext_size    dw	    0		    ; size
	    dw	    0		    ;

LAST   ENDS

;*************************************************************************
;
; CODE
;
;*************************************************************************
LAST   SEGMENT
assume	cs:LAST, DS:DGROUP, ES:DGROUP


;******************************************************************************
;*** Pool Initialise *** Give this memory manager the memory it is to play    ;
;			 with.						      ;
;									      ;
;   INPUTS:  AX = start offset of the extended memory in K		      ;
;	     CX = size of the memory					      ;
;									      ;
;   OUTPUTS: None							      ;
;									      ;
;   USES:    None							      ;
;									      ;
;   AUTHOR:  ISP (ISP) Sep 1, 1988			      ;
;									      ;
;*****************************************************************************;

Pool_Initialise     proc    near
;
	push	dx
	push	cx
	push	ax
;
	push	cx		     ; save size of memory
	xor	dx,dx
	mov	cx,1024
	mul	cx	    ; dx:ax size in bytes offset from 1M
;
	add	ax,cs:[ext_start]    ; add it to 1M
	adc	dx,cs:[ext_start+2]  ;
;
	mov	cs:[ext_start],ax    ;
	mov	cs:[ext_start+2],dx  ;
;
	pop	ax		    ; get size into ax
	xor	dx,dx		    ;
	mul	cx
;
	mov	cs:[ext_size],ax
	mov	cs:[ext_size+2],dx
;
	pop	ax
	pop	cx
	pop	dx
;
	ret
;
Pool_Initialise     endp



;******************************************************************************
;***Get buffer*** Give some poor beggar the memory he is asking for	      ;
;									      ;
;   INPUTS:  cx = size of buffer required in bytes								;
;									      ;
;   OUTPUTS: DX:AX = address of buffer					      ;
;	     cx = size allocated
;									      ;
;   USES:    None							      ;
;									      ;
;   AUTHOR:  ISP (ISP) Sep 1, 1988			      ;
;									      ;
;*****************************************************************************;

Get_Buffer	    proc    near
;
    ;
    ; assume that the memory is present, put start address in dx:ax
    ;
	mov	dx,cs:[ext_start+2]
	mov	ax,cs:[ext_start]
    ;
    ; then proceed to determine if it really exists
    ;
	push	eax
	xor	eax,eax
	mov	ax,cx
	cmp	eax, dword ptr cs:[ext_size]
	ja	no_mem
    ;
    ; it does exist, adjust the size and the start address
    ;
	sub	dword ptr cs:[ext_size],eax
	add	dword ptr cs:[ext_start],eax
;
	pop	eax
	clc
	ret

no_mem:
	pop	eax
	stc
	ret
Get_buffer	    endp

LAST   ENDS
	end
