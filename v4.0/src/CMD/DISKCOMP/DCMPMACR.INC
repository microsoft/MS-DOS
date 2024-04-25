	IF1				;AN000;
	    %OUT INCLUDING DCMPMACR.INC...;AN000;
	ELSE				;AN000;
;	    %OUT INCLUDING DCMPMACR.INC...
	ENDIF				;AN000;
;***************************************************************************;
;			     MACRO DEFINITION				    ;
;***************************************************************************;

HEADER	MACRO	TEXT		       ;;AN000;
.XLIST				       ;;AN000;
	SUBTTL	&TEXT		       ;;AN000;
.LIST				       ;;AN000;
	PAGE			       ;;AN000;
	ENDM			       ;;AN000;
;  =  =  =  =  =  =  =	=  =
DOSCALL 			   MACRO FUNC,SUBFUNC  ;;AN000;
				   IFNB <FUNC> ;;AN000;IS THERE ANY PARMS AT ALL?
				   IFNB <SUBFUNC> ;;AN000;
				   MOV AX,(FUNC SHL 8)+SUBFUNC ;;AN000;FUNC TO AH,SUBFUNC TO AL
				   ELSE    ;;AN000;SINCE THERE IS NO SUBFUNC
				   MOV AH,FUNC ;;AN000;
				   ENDIF   ;;AN000;
				   ENDIF   ;;AN000;
				   INT 21H ;;AN000;
				   ENDM    ;;AN000;
;  =  =  =  =  =  =  =	=  =
PRINT	MACRO	MESSAGE 		   ;;AN000;
				   MOV	   DI,OFFSET MESSAGE ;;AC000;
				   CALL    SENDMSG ;;AC000;
	ENDM					   ;;AN000;
;  =  =  =  =  =  =  =	=  =
.xlist						   ;AN000;
;INPUT	 MACRO	 MESSAGE
;				    PRINT   MESSAGE
;				    CALL PROMPT
;	 ENDM
.list						   ;AN000;
;	       $SALUT (0,16,22,36)
MY_TRACKLAYOUT MACRO		   ;;AN000;
	       LOCAL CSECT_F	   ;;AN000;
CSECT_F        DW    0		   ;;AN000;# OF SECTORS IN A TRACK. Currently 18 is max.
				   ;;  THE REST IS FOR FUTURE MEDIA
	       DW    1		   ;;AN000;1 ST SECTOR
	       DW    512	   ;;AN000;# OF BYTES
	       DW    2		   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    3		   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    4		   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    5		   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    6		   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    7		   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    8		   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    9		   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    10 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    11 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    12 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    13 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    14 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    15 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    16 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    17 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    18 	   ;;AN000;
	       DW    512	   ;;AN000;CURRENTLY 18 SECTORS/TRACK IS MAXIMUM
	       DW    19 	   ;;AN000;BELOW IS FOR THE FUTURE MEDIA.
	       DW    512	   ;;AN000;
	       DW    20 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    21 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    22 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    23 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    24 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    25 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    26 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    27 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    28 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    29 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    30 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    31 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    32 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    33 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    34 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    35 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    36 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    37 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    38 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    39 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    40 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    41 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    42 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    43 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    44 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    45 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    46 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    47 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    48 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    49 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    50 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    51 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    52 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    53 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    54 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    55 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    56 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    57 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    58 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    59 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    60 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    61 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    62 	   ;;AN000;
	       DW    512	   ;;AN000;
	       DW    63 	   ;;AN000;
	       DW    512	   ;;AN000;
	       ENDM								;AN000;
