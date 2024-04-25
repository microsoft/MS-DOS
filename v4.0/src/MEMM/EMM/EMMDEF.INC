;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    CEMM.EXE - COMPAQ Expanded Memory Manager 386 Driver
;		EMMLIB.LIB - Expanded Memory Manager Library
;
;   Module:   EMMDEF.INC - defines for EMM code.
;
;   Version:  0.04
;
;   Date:     June 21, 1986
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   06/21/86  Original
;   06/25/86  0.02	Changed HANDLE_CNT to 255 to match LIM spec (SBP).
;   06/28/86  0.02	Name change from CEMM386 to CEMM (SBP).
;   07/06/86  0.04	Changed save area struct (SBP).
;   05/25/88            Changed to meet LIM 4.0 Spec (PC)
;******************************************************************************
ifndef	INC_LIST
.xlist
endif

;******************************************************************************
;	G E N E R A L	D E F I N E S
;******************************************************************************
EMM_PAGE_CNT	= 2048			; maximum of 2048 EMM pages (32MB)
HANDLE_CNT	= 255			; maximum of 255 EMM handles
FRS_COUNT	= 16			; number of 'Fast Register Sets'

EMM32_PHYS_PAGES = 4				; page frame contains 4 pages
;
; The 0 to 1M contains 64 physical pages.  Of these we are not mapping anything
; between E000 and FFFF, 0000 and 4000.  So the Maximum physcial pages we can
; get for mapping is 40.

TOT_PHYS_PAGES	equ	64
MAX_PHYS_PAGES	equ	40			; Life, the Universe
						; and Everything
PAGE_SIZE	= 1000h
;
; Of the above mappable pages the regions C000h to Dfffh have to be searched
; for the mappable pages.
;
ABOVE_CONV_STRT_SEG equ 0C000h
ABOVE_CONV_STRT_PG  equ ABOVE_CONV_STRT_SEG SHR 10
;
ABOVE_CONV_END_SEG  equ 0DC00h
ABOVE_CONV_END_PG   equ ABOVE_CONV_END_SEG SHR	10
;
MAX_ABOVE_CONV_PAGES	EQU 8
;
; Also the system memory mappable region starts at 4000h
;
CONV_STRT_SEG	    equ 4000h
CONV_STRT_PG	    equ CONV_STRT_SEG SHR 10
;
NUM_CONV_PGS	    equ (0A000h -4000h) SHR 10
;
; During init we keep track of mappable pages with an array of mappable_segs
;

PAGE_MAPPABLE	    equ     0FFh		    ;
PAGE_NOT_MAPPABLE   equ       0h		    ;


NULL_PAGE	= 0FFFFh
NULL_HANDLE	= 00FFFh


;
; Flags for memory move/xchg
;
Source_GT_Dest_Flag = 80h		; Source > Destination for copy / xchg
Overlap_Flag	    = 40h		; Copy overlapping memory
Backward_Copy_Flag  = 20h		; copy is going to be backward
;
; Flags for PFlag use in Alter Map and Jump
;
PFLAG_VM		= 0002h		; VM bit in High word of EFLAG
PFLAG_VIRTUAL		= 0020h		; wheather it's call from virtual or proected mode
PFLAG_PATCH_CS_IP	= 0008h		; Tell Protected mode dispatch to
					; patch new CS:IP onto it's return address
;******************************************************************************
;	S T A T U S   D E F I N E S
;******************************************************************************
OK			=	0
EMM_SW_MALFUNCTION	=	80h
EMM_HW_MALFUNCTION	=	81h
INVALID_HANDLE		=	83h
INVALID_FUNCTION	=	84h
NO_MORE_HANDLES 	=	85h
SAVED_PAGE_DEALLOC	=	86h
NOT_ENOUGH_EXT_MEM	=	87h
NOT_ENOUGH_FREE_MEM	=	88h
ZERO_PAGES		=	89h
LOG_PAGE_RANGE		=	8Ah
PHYS_PAGE_RANGE 	=	8Bh
SAVE_AREA_FULL		=	8Ch
MAP_PREV_SAVED		=	8Dh
NO_MAP_SAVED		=	8Eh
INVALID_SUBFUNCTION	=	8Fh

; LIM 4.0 extras

VALID_OVERLAP		=	92h
INSUFFICIENT_EMM_PAGES	=	93h
CONVENTIONAL_EMM_OVERLAP=	94h
INVALID_OFFSET		=	95h
INVALID_REGION_LENGTH	=	96h
OVERLAPPING_EXCHANGE	=	97h
INVALID_MEMORY_TYPE	=	98h
FRSETS_UNSUPPORTED	=	99h
INVALID_FRSET		=	9Ah
NO_MORE_FRSETS		=	9Bh
FRSET_NON_ZERO		=	9Ch
FRSET_UNDEFINED 	=	9Dh
FRSET_NO_DMA		=	9Eh
FRSET_INVALID_DMA	=	9Fh
HANDLE_NAME_NOT_FOUND	=      0A0h
DUPLICATE_HANDLE_NAME	=      0A1h
INVALID_WRAPAROUND	=      0A2h
SOURCE_CORRUPTED	=      0A3h
ACCESS_DENIED		=      0A4h


;******************************************************************************
;	GET/SET PAGE MAP SUBFUNCTION CODES
;******************************************************************************
GSPM_GET	equ	0
GSPM_SET	equ	1
GSPM_GETSET	equ	2
GSPM_SIZE	equ	3

;
; OSEnabled Values
;
OS_IDLE 	equ	0
OS_ENABLED	equ	1
OS_DISABLED	equ	2

;******************************************************************************
;	 S T R U C T U R E S
;******************************************************************************

;
;  stack frame after pushad on real/virtual mode entry
;
r67_Frame	struc
rDI	dd	?
rSI	dd	?
rBP	dd	?
rSP	dd	?
rBX	dd	?
rDX	dd	?
rCX	dd	?
rAX	dd	?
retaddr dw	?
rCS	dw	?
PFlag	dw	?
rDS	dw	?
rES	dw	?
rGS	dw	?
rFS	dw	?
r67_Frame	ends


;
; for _handle_table
;
HandleTable_struc	struc
ht_index	dw	NULL_PAGE	; index into emm_page for handle's pgs
ht_count	dw	0		; number of emm_pages for this handle
HandleTable_struc	ends

;
; for _save_area
;
SaveMap_struc	struc
s_handle	dw	NULL_HANDLE				; owning handle
s_map		dw	EMM32_PHYS_PAGES dup (NULL_PAGE)	; EMM page #s
SaveMap_struc	ends

;
; structure linking segment with physical page number
;
Mappable_Page	struc
mappable_seg	dw	?
mappable_pg	dw	?
Mappable_Page	ends

;
; Get Partial Page Map
;
gppm_struc	struc
gppm_count	dw	?
gppm_segs	dw	?
gppm_struc	ends

;
; Structures used as arguments to Map Handle Array function
;

; For subfunction 0:
mha_array0	struc
mha0_log_pg	dw	?
mha0_phys_pg	dw	?
mha_array0	ends

; For subfunction 1:
mha_array1	struc
mha1_log_pg	dw	?
mha1_seg	dw	?
mha_array1	ends

; Used by Map and Jump and Map and Call -- Identical to mha_array0 and 1
log_phys_map_struct  struc
log_page_number      dw ?
phys_page_number_seg dw ?
log_phys_map_struct  ends

; Map and Jump structure
maj_struct	struc
maj_target_address   dd ?
maj_log_phys_map_len db ?
maj_map_address      dd ?
maj_struct	ends

; Map and Call structure
mac_struct	struc
mac_target_address   dd ?
mac_new_page_map_len db ?
mac_new_map_address  dd ?
mac_old_page_map_len db ?
mac_old_map_address  dd ?
mac_reserved         dw 4 dup (?)
mac_struct	ends

; Move / Exchange memory structure
mem_memory_descriptor_struct	struc
mem_memory_type      db ?
mem_handle	     dw ?
mem_initial_offset   dw ?
mem_initial_seg_page dw ?
mem_memory_descriptor_struct	ends


mem_struct	struc
mem_region_length   dd	?
mem_source	    db	(SIZE mem_memory_descriptor_struct) dup (?)
mem_dest	    db	(SIZE mem_memory_descriptor_struct) dup (?)
mem_struct	ends

;
; Fast Register Set Description
;
FRS_struc	struc
FRS_Window	dw	MAX_PHYS_PAGES dup (NULL_PAGE)	; emm page numbers
FRS_alloc	dw	0				; Is this set allocated
FRS_struc	ends

	page
;****************************************************************************
;
;   Dword_Align -- Aligns code to dword boundry by inserting nops
;
;****************************************************************************

Dword_Align MACRO Seg_Name
IF (($ - OFFSET Seg_Name:0) MOD 4)
	db	90h		     ;; Nop in code / else byte of 90h in data
	Dword_Align Seg_Name
ENDIF
	    ENDM

	page
;***********************************************
;
; Validate_Handle - check the handle in DX
;
;	ENTRY:	Handle as per LIM4.0 spec. in DX
;
;	EXIT:	If the handle is invalid jump To Death_Label, otherwise,
;		EDX points to the _handle_table entry for the handle
;
;	USES:	EDX
;
;***********************************************
Validate_Handle MACRO	Death_Label

	cmp	dx, [_handle_table_size]	;Q: handle in range ?
	jae	Death_Label			;  N: go to error label
	shl	dx, 2				;  Y: convert handle to
	add	dx, offset _handle_table	;     pointer
	xchg	bx, dx
	cmp	[bx.ht_index], NULL_PAGE	;Q: is this handle active ?
	xchg	bx, dx
	je	Death_Label			;  N: return error

	ENDM

;***********************************************
;
; Handle2HandlePtr - convert the handle in DX to
;		points into handle_table
;
;	ENTRY:	Handle as per LIM4.0 spec. in DX
;
;	EXIT:	EDX points to the _handle_table entry for the handle
;
;	USES:	EDX
;
;***********************************************
Handle2HandlePtr MACRO

	shl	dx, 2				;  Y: convert handle to
	add	dx, offset _handle_table	;     pointer

	ENDM

.list		; end of EMMDEF.INC



