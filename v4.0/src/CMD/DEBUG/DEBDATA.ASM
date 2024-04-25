	   PAGE    60,132 ;
	   TITLE DEBDATA.SAL - PC DOS
;======================= START OF SPECIFICATIONS =========================
;
; MODULE NAME: DEBDATA.SAL
;
; DESCRIPTIVE NAME: DATA SEGMENT VALUE DEFINITION
;
; FUNCTION: PROVIDES ALL DATA SEGMENT DEFINITIONS.
;
; ENTRY POINT: NA
;
; INPUT: ANY VALUE IN DATA SEGMENT
;
; EXIT NORMAL: NA
;
; EXIT ERROR: NA
;
; INTERNAL REFERENCES: NA
;
; EXTERNAL REFERENCES: NA
;
; NOTES: THIS MODULE IS TO BE PREPPED BY SALUT WITH THE "PR" OPTIONS.
;	 LINK DEBUG+DEBCOM1+DEBCOM2+DEBCOM3+DEBASM+DEBUASM+DEBERR+
;	      DEBCONST+DEBDATA+DEBMES
;
; REVISION HISTORY:
;
;	AN000	VERSION 4.00 - REVISIONS MADE RELATE TO THE FOLLOWING:
;
;				- IMPLEMENT DBCS HANDLING	DMS:6/17/87
;				- IMPLEMENT MESSAGE RETRIEVER	DMS:6/17/87
;				- > 32 MB SUPPORT		DMS:6/17/87
;
; COPYRIGHT: "MS DOS DEBUG UTILITY"
;	     "VERSION 4.00 (C) COPYRIGHT 1988 Microsoft"
;	     "LICENSED MATERIAL - PROPERTY OF Microsoft  "
;
;======================= END OF SPECIFICATIONS ===========================

	   IF1
	       %OUT COMPONENT=DEBUG, MODULE=DEBDATA
	   ENDIF
.XLIST
.XCREF
	   INCLUDE DOSSYM.INC
	   INCLUDE DEBEQU.ASM
	   INCLUDE DPL.ASM
.LIST
.CREF
CODE	   SEGMENT PUBLIC BYTE
CODE	   ENDS

CONST	   SEGMENT PUBLIC BYTE
CONST	   ENDS

DATA	   SEGMENT PUBLIC BYTE
DATA	   ENDS

CSTACK	   SEGMENT STACK
CSTACK	   ENDS

DG	   GROUP CODE,CONST,CSTACK,DATA

DATA	   SEGMENT PUBLIC BYTE
	   PUBLIC PARITYFLAG,XNXOPT,XNXCMD,SWITCHAR,EXTPTR,HANDLE,TRANSADD
	   PUBLIC PARSERR,ASMADD,DISADD,DISCNT,ASMSP,INDEX,DEFDUMP,DEFLEN
	   PUBLIC REGSAVE,SEGSAVE,OFFSAVE,TEMP,BUFFER,BYTCNT,OPCODE,AWORD
	   PUBLIC REGMEM,MIDFLD,MODE,NSEG,BRKCNT,TCOUNT,ASSEM_CNT
	   PUBLIC ASSEM1,ASSEM2,ASSEM3,ASSEM4,ASSEM5,ASSEM6,BYTEBUF,BPTAB
	   PUBLIC DIFLG,SIFLG,BXFLG,BPFLG,NEGFLG,NUMFLG,MEMFLG,REGFLG
	   PUBLIC MOVFLG,TSTFLG,SEGFLG,LOWNUM,HINUM,F8087,DIRFLG,DATAEND
	   PUBLIC BEGSEG,CREATE_LONG,ARG_BUF_INDEX
	   PUBLIC FILEEND,FILESTRT,SSINTSAV,BPINTSAV
	   PUBLIC FZTRACE, PREV24, FIN24

	   public rel_read_write_tab		;an000;relative read/write
						;      table
	   public rel_low_sec			;an000;sector add. low word
	   public rel_high_sec			;an000;sector add. high word
	   public rel_sec_num			;an000;# of sectors to access
	   public rel_rw_add			;an000;transfer address

	   public lbtbl 			;an000;lead byte table pointer

	public xm_page				;an000;
	public xm_log				;an000;
	public xm_phy				;an000;
	public xm_handle			;an000;
	public xm_handle_ret			;an000;
	public xm_page_cnt			;an000;
	public xm_handle_pages_buf		;an000;
	public xm_frame 			;an000;
	public xm_deall_han			;an000;
	public xm_alloc_pg			;an000;
	public xm_total_pg			;an000;
	public xm_han_total			;an000;
	public xm_han_alloc			;an000;

;=========================================================================
; REL_READ_WRITE_TAB : This table provides the new generic IOCTL primitive
;		       read/write with its values.
;
;	Date	  : 6/17/87
;=========================================================================

REL_READ_WRITE_TAB	label	dword		;an000;relative read/write
						;      table
	rel_low_sec	dw	?		;an000;sector add. low word
	rel_high_sec	dw	?		;an000;sector add. high word
	rel_sec_num	dw	?		;an000;# of sectors to write
	rel_rw_add	dd	?		;an000;holds the segment
						;      & offset of the
						;      transfer address

;=========================================================================

lbtbl		dd	?			;an000;lead byte table pointer

	xm_page        db   ?			;an000;page count to allocate
	xm_log	       db   ?			;an000;log. page to map
	xm_phy	       db   ?			;an000;phy. page to map
	xm_deall_han   dw   ?			;an000;handle to deallocate
	xm_handle      dw   ?			;an000;handle to map
	xm_handle_ret  dw   ?			;an000;handle created


	xm_page_cnt    dw   ?			;an000;current page count

	xm_handle_pages_buf db	 1024 dup(0)	;an000;hold handle pages

	xm_frame	dw  ?			;an000;holds frame segment

	xm_alloc_pg	dw  ?			;an000;active page count

	xm_total_pg	dw  ?			;an000;total possible page cnt.

	xm_han_total	dw  ?			;an000;total possible handles

	xm_han_alloc	dw  ?			;an000;handles allocated

	   IF	IBMVER
	       PUBLIC OLD_MASK
OLD_MASK       DB   ?
	   ENDIF
PREV24	   DD	?			; prevvious INT 24 handler
FIN24	   DB	0			; TRUE => in the process of cleaning up
FZTRACE    DB	0			; TRUE => in a Ztrace
FILEEND    DW	?			; ARR 2.4
FILESTRT   DW	?			; ARR 2.4
SSINTSAV   DD	?			; ARR 2.4
BPINTSAV   DD	?			; ARR 2.4

PARITYFLAG DB	0

PUBLIC	   SAVESTATE
SAVESTATE  DPL	<>			; storage for extended error info

XNXOPT	   DB	?			; AL OPTION FOR DOS COMMAND
XNXCMD	   DB	?			; DOS COMMAND FOR OPEN_A_FILE TO PERFORM
SWITCHAR   DB	?			; CURRENT SWITCH CHARACTER
EXTPTR	   DW	?			; POINTER TO FILE EXTENSION
HANDLE	   DW	?			; CURRENT HANDLE
TRANSADD   DD	?			; TRANSFER ADDRESS

PARSERR    DB	?
ASMADD	   DB	4 DUP (?)
DISADD	   DB	4 DUP (?)
DISCNT	   DW	?
ASMSP	   DW	?			; SP AT ENTRY TO ASM
INDEX	   DW	?
DEFDUMP    DB	4 DUP (?)
DEFLEN	   DW	?
REGSAVE    DW	?
SEGSAVE    DW	?
OFFSAVE    DW	?

;Do NOT move this dword variable - it sets up a long call for
;a Create_process_data_block call issued in DEBUG
CREATE_LONG LABEL DWORD
	   DW	100H
BEGSEG	   DW	?

; The following data areas are destroyed during hex file read
TEMP	   DB	4 DUP(?)
BUFFER	   LABEL BYTE
BYTCNT	   DB	?
ARG_BUF_INDEX DW ?
OPCODE	   DW	?
AWORD	   DB	?
REGMEM	   DB	?
MIDFLD	   DB	?
MODE	   DB	?
NSEG	   DW	?
BRKCNT	   DW	?			; Number of breakpoints
TCOUNT	   DW	?			; Number of steps to trace
ASSEM_CNT  DB	?			; preserve order of assem_cnt and assem1
ASSEM1	   DB	?
ASSEM2	   DB	?
ASSEM3	   DB	?
ASSEM4	   DB	?
ASSEM5	   DB	?
ASSEM6	   DB	?			; preserve order of assemx and bytebuf
BYTEBUF    DB	BUFLEN	DUP (?) 	; Table used by LIST
BPTAB	   DB	BPLEN	DUP (?) 	; Breakpoint table
DIFLG	   DB	?
SIFLG	   DB	?
BXFLG	   DB	?
BPFLG	   DB	?
NEGFLG	   DB	?
NUMFLG	   DB	?			; ZERO MEANS NO NUMBER SEEN
MEMFLG	   DB	?
REGFLG	   DB	?
MOVFLG	   DB	?
TSTFLG	   DB	?
SEGFLG	   DB	?
LOWNUM	   DW	?
HINUM	   DW	?
F8087	   DB	?
DIRFLG	   DB	?
	   DB	BUFFER+BUFSIZ-$ DUP (?)

DATAEND    LABEL WORD

DATA	   ENDS
	   END
