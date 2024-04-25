

	page 58,132
;******************************************************************************
	TITLE	M_STATE:MODULE to establish machine state at emm boot time
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:	MEMM.EXE - MICROSOFT Expanded Memory Manager 386 Driver
;
;   Module:	M_STATE
;
;   Version:	0.01
;
;   Date:	Aug 29,1988
;
;   Author:	ISP (ISP)
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;******************************************************************************
;   Functional Description:
;
;******************************************************************************
.lfcond
.386p

	page
;******************************************************************************
;		P U B L I C   D E C L A R A T I O N S
;******************************************************************************

	public	estb_mach_state

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
_DATA	segment
_DATA	ends

;
LAST	segment
;
	extrn	estb_a20_state:near
;
LAST	ends

	page
;******************************************************************************
;			S E G M E N T	D E F I N I T I O N
;******************************************************************************


;******************************************************************************
;
;	Code Segments
;
;******************************************************************************
;
_TEXT	segment
_TEXT	ends

LAST	segment
	assume	cs:LAST, ds:DGROUP, es:DGROUP

	page
;-----------------------------------------------------------------------;
; estb_mach_state							;
;                                                                       ;
; establishes the state of the machine at memm boot. the only thing we	;
; are concerned about right now is the a20 state which needs to be	;
; preserved via emulation						;
; 									;
; Arguments:                                                            ;
;	nothing 							;
; Returns:                                                              ;
; 	nothing								;
; Alters:                                                               ;
;	flags								;
; Calls:                                                                ;
;	estb_a20_state							;
; History:                                                              ;
;	ISP (isp).					;
;-----------------------------------------------------------------------;
estb_mach_state proc	near
;
	call	estb_a20_state
	ret
;
estb_mach_state endp

LAST	ends				; End of segment
;

	end				; End of module

