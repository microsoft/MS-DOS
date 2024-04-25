

;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;   Title:    MEMM - MICROSOFT Expanded Memory Manager 386
;
;   Module:   DRIVER.STR - MS-DOS Device Driver structures
;
;   Version:  0.02
;
;   Date:     June 25,1986
;
;   Author:
;
;******************************************************************************
;
;   Change log:
;
;     DATE    REVISION			DESCRIPTION
;   --------  --------	-------------------------------------------------------
;   06/25/86  Original
;   06/28/86  0.02	Name change from MEMM386 to MEMM
;
;******************************************************************************
ifndef INC_LIST
.xlist
endif

;
;    Device driver header structure
;
DEVICE_HEADER		STRUC
DEV_PTR 		DD		0
DEV_ATTR		DW		0
STRAT_PTR		DW		0
INT_PTR 		DW		0
DEV_NAME		DB		"        "
DEVICE_HEADER		ENDS
DEV_OFF 		EQU		WORD PTR DEV_PTR
DEV_SEG 		EQU		WORD PTR DEV_PTR+2
;
;    Device driver request header structure
;
REQUEST_HEADER		STRUC
HDR_LEN 		DB		0
UNIT_CODE		DB		0
COMMAND_CODE		DB		0
STATUS_WORD		DW		0
RES_AREA		DB		0,0,0,0,0,0,0,0
OP_DATA 		DB		0
REQUEST_HEADER		ENDS
;
;    Initialize command request header structure
;
INIT_HEADER		STRUC
			DB		13 DUP (?)
NUM_UNITS		DB		0
BRK_ADDR		DD		0
ARG_PTR 		DD		0
DRV_NUM 		DB		0
INIT_HEADER		ENDS
BRK_OFF 		EQU		WORD PTR BRK_ADDR
BRK_SEG 		EQU		WORD PTR BRK_ADDR+2
ARG_OFF 		EQU		WORD PTR ARG_PTR
ARG_SEG 		EQU		WORD PTR ARG_PTR+2
;
;    Media check request header structure
;
MEDIA_HEADER		STRUC
			DB		13 DUP (?)
MEDIA_BYTE		DB		0
RET_BYTE		DB		0
VOL_PTR 		DD		0
MEDIA_HEADER		ENDS
VOL_OFF 		EQU		WORD PTR VOL_PTR
VOL_SEG 		EQU		WORD PTR VOL_PTR+2
;
;    Build BPB request header structure
;
BPB_HEADER		STRUC
			DB		13 DUP (?)
BPB_DESC		DB		0
BPB_TRANS		DD		0
TABLE_PTR		DD		0
BPB_HEADER		ENDS
BPB_OFF 		EQU		WORD PTR BPB_TRANS
BPB_SEG 		EQU		WORD PTR BPB_TRANS+2
TABLE_OFF		EQU		WORD PTR TABLE_PTR
TABLE_SEG		EQU		WORD PTR TABLE_PTR+2
;
;    Input/output request header structure
;
IO_HEADER		STRUC
			DB		13 DUP (?)
IO_DESC 		DB		0
IO_TRANS		DD		0
IO_COUNT		DW		0
IO_START		DW		0
VOL_ID			DD		0
IO_HEADER		ENDS
IO_OFF			EQU		WORD PTR IO_TRANS
IO_SEG			EQU		WORD PTR IO_TRANS+2
ID_OFF			EQU		WORD PTR VOL_ID
ID_SEG			EQU		WORD PTR VOL_ID+2
;
;   Device driver BIOS Parameter Block (BPB) structure
;
BPB_BLOCK		STRUC
BYTES_PER_SECTOR	DW		0
SECTORS_PER_ALLOC	DB		0
RES_SECTORS		DW		0
NUM_FATS		DB		0
ROOT_DIR_ENTRIES	DW		0
NUMBER_OF_SECTORS	DW		0
MEDIA_DESC		DB		0
SECTORS_PER_FAT 	DW		0
BPB_BLOCK		ENDS
;
;   Device driver BIOS Parameter option block structure
;
BPB_OPTION		STRUC
SECTORS_PER_TRACK	DW		0
NUMBER_OF_HEADS 	DW		0
HIDDEN_SECTORS		DW		0
BPB_OPTION		ENDS

.list	; end of DRIVER.STR
