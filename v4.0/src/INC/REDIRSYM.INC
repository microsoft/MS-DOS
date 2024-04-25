; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;  Redirector MACROS
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

EDW	MACRO	name
	extrn	name:near
	DW	OFFSET	RG:name
ENDM

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

CHECK_DIALECT	  MACRO   name

    IF2 					;AN000; If not defined yet,
       IFNDEF CHECKDIALECT			;AN000;  THEN Extrn
	  Extrn CHECKDIALECT&name:NEAR		;AN000;
       ENDIF					;AN000;
    ENDIF					;AN000;
	CALL	CHECKDIALECT&name		;AN000; Call the appropriate routine

ENDM

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

CallREDIRSub MACRO   name,fn,save,restore	;AN000;
    IF2 					;AN000; If not defined yet,
       IFNDEF REDIRSub&fn			;AN000;  THEN Extrn
	  Extrn REDIRSub&fn:NEAR		;AN000;
       ENDIF					;AN000;
    ENDIF					;AN000;
    IFNB    <save>				;AN000; If not blank
	SaveReg <save>				;AN000;    Save the regs
    ENDIF					;AN000;
	CALL	REDIRSub&fn			;AN000; Call the appropriate routine
    IFNB    <restore>				;AN000; If not blank
	RestoreReg  <restore>			;AN000;    Save the regs
    ENDIF					;AN000;
ENDM						;AN000;

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;  Redirector structures
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	INCLUDE IFSSYM.INC		 ;AN000;
	INCLUDE ERROR.INC		 ;AN000;
	INCLUDE FILEMODE.INC		 ;AN000;

;; CD_FSDA STRUCTURE

   CD_FSDA_OFF	   EQU WORD PTR CD_FSDA        ;AN000;
   CD_FSDA_SEG	   EQU WORD PTR CD_FSDA+2      ;AN000;
   CD_FSDA_FLAGS   EQU WORD PTR CD_FSDA+4      ;AN000;

;; DFL_FSDA STRUCTURE

   DF_FSDA_OFF	   EQU WORD PTR DFL_FSDA        ;AN000;
   DF_FSDA_SEG	   EQU WORD PTR DFL_FSDA+2      ;AN000;
   DF_FSDA_FLAGS   EQU WORD PTR DFL_FSDA+4      ;AN000;

;; SFF_FSDA STRUCTURE

   SFF_FSDA_OFF    EQU WORD PTR SFF_FSDA       ;AN000;
   SFF_FSDA_SEG    EQU WORD PTR SFF_FSDA+2     ;AN000;
   SFF_FSDA_FLAGS  EQU WORD PTR SFF_FSDA+4     ;AN000;

;; IFS Structure fixes

   ifsr_fcn_def    EXECAPI		 ;AN000;
   ifsr_api_def    OPENFILE		 ;AN000;
IFSR_OPENNAME@	=  IFSR_NAME@		 ;AN000;
   ifsr_api_def    SEARCHFILE		 ;AN000;
IFSR_SRCHNAME@	=  IFSR_NAME@		 ;AN000;
   ifsr_api_def    MKDIR		 ;AN000;
IFSR_DIRNAME@	=  IFSR_NAME@		 ;AN000;
   ifsr_api_def    DELFILE		 ;AN000;
IFSR_DELNAME@	=  IFSR_NAME@		 ;AN000;
   ifsr_api_def    FILEATTR		 ;AN000;
IFSR_ATTRNAME@	=  IFSR_NAME@		 ;AN000;

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;  Redirector Equates
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Get_Interrupt_Vector EQU     35H      ;AN000;
Set_Interrupt_Vector EQU     25H      ;AN000;
Deallocate_memory    EQU     49H      ;AN000;

GET_SYS_CONFIG	     EQU     0C000H   ;AN000; INT 15H to get configuration
CONFIG_STRUC	STRUC		      ;AN001;
   LENGTH	DW   ?		      ;AN001;
   MODEL_BYTE	DB   ?		      ;AN001;
CONFIG_STRUC	ENDS		      ;AN001;

LOWEST_386_MODEL     EQU     0F8H     ;AN001;

INCOR_DOS	     EQU     1	      ;AN000;
ALREADY_INST	     EQU     2	      ;AN000;
NOT_INST	     EQU     3	      ;AN000;
NET_NOT_STARTED      EQU     4	      ;AN000;
INSUFF_MEM	     EQU     5	      ;AN000;
BAD_PARM	     EQU     10       ;AN000;
INSUFFICENT_MEM      EQU     76       ;AN001; Extended Error

ONE_REPLACE	     EQU     1	      ;AN000;
SINGLE_COUNT	     EQU     1	      ;AN000;
TESTDIALECT	     =	     0	      ;AN001;

REDIR_INSTALLED      EQU     -1       ;AN000;
REDIR_SYS_INSTALL    EQU     0BF80H   ;AN000; REDIR.SYS 2FH Function number
REDIR_EXE_INSTALL    EQU     0BF00H   ;AN000; REDIR.EXE 2FH Function number

FASSIGN_ON	     EQU     -1       ;AN000;
FASSIGN_OFF	     EQU     0	      ;AN000;
FPRINT_ON	     EQU     -1       ;AN000;
FPRINT_OFF	     EQU     0	      ;AN000;

EXT_ERR_72	     EQU     72       ;AN000;
PSP_ENVIRO_SEG	     EQU     002CH    ;AN000; Offset into the PSP of the Enviroment Segment

PrnIO		     EQU     17H      ; Int vector for Printer IO
PrntScr 	     EQU     05H      ; Int vector for Print Screen
PrnRdrMark	     EQU     2	      ; Mark for port addr

VER12		     EQU     00000010b ;AN001;
VER13		     EQU     00000100b ;AN001;

FIRST_TIME	     EQU     1		 ;AN001;
SECOND_TIME	     EQU     2		 ;AN001;

SHIFT_BY_7	     EQU     7		 ;AN001;

HI_BIT_SHARING_MASK  EQU     1111111101111111b ;AN001; Turns off Hi bit in nibble


;; ###############################################################
;;		MISC.INC
;; ###############################################################

; NETFILE

attr_read_only	       = 00000001b

; NETINIT

IFSR_INVALID_CMD	=   -1							      ;AN000;

; NETUTIL

MACRO_4 	=	4
DATE_TIME	=	0


; NETHAND

LOCK_ALL_OPERS	   =	   0
POS_LEN_PTR_SIZE   =	   8		  ;AN001; 8 bytes for position/length

FIND_BUF    STRUC

find_buf_drive	    DB	?		; drive of search
find_buf_name	    DB	11 DUP (?)	; formatted name
find_buf_sattr	    DB	?		; attribute of search
find_buf_LastEnt    DW	?		; LastEnt
find_buf_DirStart   DW	?		; DirStart
find_buf_NetID	    DB	4 DUP (?)	; Reserved for NET
find_buf_attr	    DB	?		; attribute found
find_buf_time	    DW	?		; time
find_buf_date	    DW	?		; date
find_buf_size_l     DW	?		; low(size)
find_buf_size_h     DW	?		; high(size)
find_buf_pname	    DB	13 DUP (?)	; packed name

FIND_BUF    ENDS

