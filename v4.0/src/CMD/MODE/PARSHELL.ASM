
PRINTF_CODE SEGMENT PUBLIC

ASSUME CS:PRINTF_CODE,DS:PRINTF_CODE,ES:PRINTF_CODE,SS:PRINTF_CODE

FARSW	 EQU   0	   ;CALL parser by near call
DATESW	 EQU   0	   ;NO date checking code
TIMESW	 EQU   0	   ;NO time checking code
FILESW	 EQU   1	   ;have to check for font file name
CAPSW	 EQU   0	   ;don't have to display file names
CMPXSW	 EQU   1	   ;have complex list in codepage syntax
DRVSW	 EQU   0	   ;just a drive is never legal
QUSSW	 EQU   0	   ;quoted string is not legal
NUMSW	 EQU   1	   ;need to check a numeric value occaisionally
KEYSW	 EQU   1	   ;oodles of keywords to check
SWSW	 EQU   1	   ;/status
VAL1SW	 EQU   1	   ;handle numeric ranges
VAL2SW	 EQU   1	   ;handle list of numbers
VAL3SW	 EQU   1	   ;handle list of strings
BASESW	 EQU   1	   ;use DS addressability for PSDATA.INC variables
;INCSW	  EQU	1

INCLUDE  PARSE.ASM

PUBLIC	 SYSPARSE

PRINTF_CODE ENDS

END
