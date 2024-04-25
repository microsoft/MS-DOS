;J.K. This is a temporary version of EMS function definitions needed for
;IBMBIO SYSINIT.

EMS_INT 	equ	67h	;interrupt vector designated for EMS.

EMS_STATUS	equ	40h	;status of memery manager
EQ_PAGES	equ	42h	;get number of unallocated & total pages
E_GET_HANDLE	equ	43h	;allocate pages
EMAP_L_TO_P	equ	44h	;Map logical to physical page
EMAP_STATE	equ	4Fh	;Mapping status
    GET_MAP_STATE     equ    00h
    GET_MAP_SIZE      equ    02h
    SET_MAP_STATE     equ    01h
EDE_ALLOCATE	equ	45h	;deallocate pages
EMS_VERSION	equ	46h	;Get EMM version number
GET_PAGE_FRAME	equ	58h	;Get page frame address
    GET_PAGEFRAME_TAB equ 00H
    GET_NUM_PAGEFRAME equ 01H
EMS_HANDLE_NAME equ	53h
    SET_HANDLE_NAME equ  01h

IBM_PAGE_ID	equ	255	;Physical page id that will be used by
				;IBMBIO and IBMDOS for buffer manipulation.

;MAX_NUM_PAGEFRAME equ	 12	;maximum number of page frames IBMBIO can
				;handle

MAX_NUM_PAGEFRAME equ	 64	;maximum number of page frames MSBIO can
				;handle

EMSVERSION	equ	40h	;4.0

