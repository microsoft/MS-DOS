ALLOCATE_START	   DW	     0		;AN000;
					;
DEST		   DB	     0		;AN000;
FILE_NUM	   DW	     0		;AN000;
NUMBER_OF_FILES    DW	     0		;AN000;
TABLE_OFFSET	   DW	     0		;AN000;
PATH_OFFSET	   DW	     0		;AN000;
NOT_FOUND_FLAG	   DB	     0		;AN000;
SP_SAVE 	   DW	     0		;AN000;
					;
EVERYTHING	   DB	     'B:*.*',0  ;AN000;
					;
DOS_FILE_PTR	   DW	     0		;AN000;
BUFFER_START	   DW	     0		;AN000;
					;
B_TARGET	   DB	     'B:\',0    ;AN000;
LENGTH_B_TARGET    EQU	     $-B_TARGET ;AN000;
					;
A_TARGET	   DB	     'A:\',0    ;AN111;JW
LENGTH_A_TARGET    EQU	     $-A_TARGET ;AN111;JW
