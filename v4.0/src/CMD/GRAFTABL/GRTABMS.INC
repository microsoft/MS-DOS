;:util GRAFTABL 	    ;utility name					;AN000;
;:class 1		    ;DOS extended errors:
;:class 2		    ;parse errors:
;1  Too many parameters
;2  Required parameter missing
;3  Invalid switch
;4  Invalid keyword
;5  Parameter value not in allowed range
;6  Parameter value not allowed    [parse ret codes 6 and 7]
;7   (undefined)
;8  Parameter format not correct
;9   (undefined)
;10 Invalid parameter		   [no corresponding parse ret code]
;11 Invalid parameter combination  [no corresponding parse ret code]
;;
;:class A		    ;system messages
;:use 1 COMMON1 	    ;MSG 1 is always "Incorrect DOS version"
;;
;;In these next 2 messages, %1 will be replaced with one from list, 4-5,
;; or with one entry of the list at "CPID". (see GRTABMS.INC)
;;
;:def 2 "Active Code Page: %1",CR,LF
;:def 3 "Previous Code Page: %1",CR,LF

;:def 4 "None",NULL
;:def 5 "Non-standard",NULL
;;
;:def 6 CR,LF,"DOS command line parameters supported:",CR,LF,LF
;
;:def 7 "    /STA - Request Status only",CR,LF
;"    ?    - Display this summary of parameters",CR,LF,CR,LF

;:def 8 "    Code Pages available:",CR,LF
;"    437  - USA Graphic Character Set",CR,LF

;:def 9 "    850  - Multi-lingual Graphic Character Set",CR,LF
;"    860  - Portuguese Graphic Character Set",CR,LF

;:def 10 "    863  - Canadian French Graphic Character Set",CR,LF
;"    865  - Nordic Graphic Character Set",CR,LF
;
;
;:end
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	IF1				;AN000;
	    %OUT    COMPONENT=GRAFTABL, MODULE=GRTABMS.INC...;AN000;
	ENDIF				;AN000;
;THIS MODULE IS INCLUDED IN GRTABSM.SAL.
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
SUBLIST_PARSE  SUBLIST <,,FILL_OFF,FILL_SEG,PC_ID_0,SF_BITS <SF_LEFT,,SF_ASCIIZ,SF_CHAR>,MAX_0,MIN_1,PAD_BLK> ;AN003;
	PUBLIC SUBLIST_PARSE	   ;AN003;

;		THE NEXT GROUP ARE ADDITIONAL CLASS "A" MESSAGES
;		SPECIFICALLY DEFINED FOR THE GRAFTABL UTILITY
MSGNUM_ACTIVE  MSG_DESC <2,,SLIST_23,ONE_SUBS> ;AN000;"Active Code Page: %1",CR,LF
	       PUBLIC MSGNUM_ACTIVE						;AN000;

MSGNUM_PREVIOUS MSG_DESC <3,,SLIST_23,ONE_SUBS> ;AN000;"Previous Code Page: %1",CR,LF
	       PUBLIC MSGNUM_PREVIOUS						;AN000;

;BEFORE USING THE NEXT SUBLIST, THE SEG ID OF CPID
;(OR OF "NONE" OR "NON-STANDARD") MUST BE FILLED IN
;SINCE COM FILE CANNOT HAVE SEGMENT FIXUP.

;THIS NEXT SUBLIST IS USED BOTH MY MESSAGE 2 AND MESSAGE 3.

SLIST_23 SUBLIST <,,,,PC_ID_1,SF_BITS <SF_LEFT,,SF_ASCIIZ,SF_CHAR>,MAX_0,MIN_1,PAD_BLK> ;AN000;
	       PUBLIC SLIST_23							;AN000;
;NOTE: IN THE ABOVE SUBLIST, ID=1, THE VECTOR POINTING TO THE MSG NO. 2-3.
;  WILL NEED TO BE PUT INTO THE SUBLIST DURING MESSAGES INITIALIZATION.
;  TO SELECT "None" OR "Non Standard", OR TO POINT TO ELEMENT OF "CPID".

	       PUBLIC CPID,CPID_L						;AN000;
CPID DB "437",NULL                                                              ;AN000;
CPID_L EQU $-CPID ;AN000;NUMBER OF CHARS IN CPID
     DB "850",NULL                                                              ;AN000;
     DB "860",NULL                                                              ;AN000;
     DB "863",NULL                                                              ;AN000;
     DB "865",NULL                                                              ;AN000;

; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
MSGNUM_NONE MSG_DESC <4> ;AN000;"None",NULL
		PUBLIC MSGNUM_NONE						;AN000;

MSGNUM_NSTD MSG_DESC <5> ;AN000;"Non-Standard",NULL
		PUBLIC MSGNUM_NSTD						;AN000;
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

;CR,LF,"DOS command line parameters supported:",CR,LF,LF                        ;AN000;
;"    /STA - Request Status only",CR,LF                                         ;AN000;
;"    ?    - Display this summary of parameters",CR,LF                          ;AN000;
;"    Code Pages available:",CR,LF
;"    437  - USA Graphic Character Set",CR,LF                                   ;AN000;
;"    850  - Multi-lingual Graphic Character Set",CR,LF                         ;AN000;
;"    860  - Portuguese Graphic Character Set",CR,LF                            ;AN000;
;"    863  - Canadian French Graphic Character Set",CR,LF                       ;AN000;
;"    865  - Nordic Graphic Character Set",CR,LF                                ;AN000;

MSGNUM_HELP_TITLE MSG_DESC <6> ;AN000;NO SUBSTITUTIONS
		PUBLIC MSGNUM_HELP_TITLE					;AN000;

MSGNUM_HELP_TITLE7 MSG_DESC <7> ;AN007;NO SUBSTITUTIONS
		PUBLIC MSGNUM_HELP_TITLE7					 ;AN007;

MSGNUM_HELP_TITLE8 MSG_DESC <8> ;AN007;NO SUBSTITUTIONS
		PUBLIC MSGNUM_HELP_TITLE8					 ;AN007;

MSGNUM_HELP_TITLE9 MSG_DESC <9> ;AN007;NO SUBSTITUTIONS
		PUBLIC MSGNUM_HELP_TITLE9					 ;AN007;

MSGNUM_HELP_TITLE10 MSG_DESC <10> ;AN007;NO SUBSTITUTIONS
		PUBLIC MSGNUM_HELP_TITLE10					  ;AN007;

; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
;end of GRTABMS.INC
