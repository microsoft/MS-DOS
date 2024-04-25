;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	      ;AN000;
;								      ;AN000;
; MORE STRUC AND EQUATES					      ;AN000;
;								      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	      ;AN000;
;								      ;AN000;
ANSI_GET	EQU    440CH					      ;AN000;
GET_SUBFUNC	EQU    037FH					      ;AN000;
EXTENDED	EQU    0					      ;AN000;
TEXT_MODE	EQU    1					      ;AN000;
MORE_MSG	EQU    2					      ;AN000;
FILE_TYPE_MSG	EQU    4					      ;AN001;
DATA_LENGTH	EQU    14					      ;AN000;
;								      ;AN000;
ANSI_STR    STRUC						      ;AN000;
	    DB	  0						      ;AN000;
	    DB	  0						      ;AN000;
	    DW	  DATA_LENGTH					      ;AN000;
	    DW	  ?						      ;AN000;
D_MODE	    DB	  ?						      ;AN000;
	    DB	  ?						      ;AN000;
	    DW	  ?						      ;AN000;
	    DW	  ?						      ;AN000;
	    DW	  ?						      ;AN000;
	    DW	  ?						      ;AN000;
SCR_ROWS    DW	  ?						      ;AN000;
ANSI_STR    ENDS						      ;AN000;

