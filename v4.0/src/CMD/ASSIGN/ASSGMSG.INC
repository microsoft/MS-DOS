BADDOS equ 1
STAT   equ 2
PARSE01 equ 01
PARSE02 equ 02
PARSE03 equ 03
PARSE04 equ 04
PARSE05 equ 05
PARSE06 equ 06
PARSE07 equ 07
PARSE08 equ 08
PARSE09 equ 09
PARSE10 equ 10

OLD_DRV   db 0,0
NEW_DRV   db 0,0

FLAG1  equ LEFT_ALIGN+CHAR_FIELD_ASCIIZ

;******************************************************************************
;		VALUES FOR THE MSG_DESC CONTROL BLOCK
ONE_SUBS       EQU   1		   ;ONE VARIABLE FIELD IN MESSAGE
TWO_SUBS       EQU   2		   ;TWO VARIABLE FIELDS IN MESSAGE
THREE_SUBS     EQU   3		   ;THREE VARIABLE FIELDS IN MESSAGE
CLASS_1        EQU   EXT_ERR_CLASS ;CLASS 1 (DOS EXTENDED ERRORS)
CLASS_2        EQU   PARSE_ERR_CLASS ;CLASS 2 (PARSE ERRORS)
CLASS_A        EQU   UTILITY_MSG_CLASS ;CLASS A TYPE MESSAGE

;THIS MESSAGE DESCRIPTOR CONTROL BLOCK IS GENERATED, ONE PER MESSAGE,
;TO DEFINE THE SEVERAL PARAMETERS THAT ARE EXPECTED TO BE PASSED IN
;CERTAIN REGISTERS WHEN THE SYSDISPMSG FUNCTION IS TO BE INVOKED.

MSG_DESC	  STRUC
MSG_NUM 	  DW	0	   ;MESSAGE NUMBER (TO AX)
MSG_HAND	  DW	0	    ;HANDLE OF OUTPUT DEVICE (TO BX)
MSG_SUBLIST	  DW	0	   ;POINTER TO SUBLIST (TO SI)
MSG_COUNT	  DW	0	   ;SUBSTITUTION COUNT (TO CX)
MSG_CLASS	  DB	0	   ;MESSAGE CLASS (IN HIGH BYTE, TO DH)
				   ; LOW BYTE HAS 0 (FUNCTION "NO INPUT", TO DL)
MSG_DESC	  ENDS
;		VALUES FOR THE SUBLIST CONTROL BLOCK
PC_ID_0        EQU   0		   ;ID OF " - " TRAILER TO MESSAGE
PC_ID_1        EQU   1		   ;ID OF PERCENT VARIABLE FIELD
PC_ID_2        EQU   2		   ;ID OF PERCENT VARIABLE FIELD
PC_ID_3        EQU   3		   ;ID OF PERCENT VARIABLE FIELD
MAX_0	       EQU   0		   ;MAXIMUM WIDTH OF STRING FIELD (0=NO LIMIT)
MIN_1	       EQU   1		   ;MINIMUM WIDTH OF STRING FIELD
;Message SUB-LIST
 SUBLIST1 LABEL   DWORD  ;PARM LIST
      ;(Original %1: set to %2:)
      DB  11	     ;PARMLIST size
      DB  0	     ;reserved
      DW  OLD_DRV    ;; ptr to data
SEG_1 DW  ?
      DB  1	     ;; n of %n
      DB  FLAG1      ;; data type
      DB  max_0      ;;max width
      DB  min_1      ;;min width
      DB  PAD_CHAR   ;;char defined to be space

DRV_LETS  LABEL WORD
;Message SUB-LIST2
 SUBLIST2 LABEL   DWORD  ;PARM LIST
      ;(File not found - 'PATH_SPEC')
      DB  11	     ;PARMLIST size
      DB  0	     ;reserved
      DW  NEW_DRV    ;; ptr to data - offset
SEG_2 DW  ?	     ;; ptr to data
      DB  2	     ;; n of %n
      DB  FLAG1      ;; data type
      DB  max_0      ;;max width
      DB  min_1      ;;min width
      DB  PAD_CHAR   ;;char defined to be space

