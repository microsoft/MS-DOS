;:util DISKCOMP 	    ;utility name
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
;
;:use 1 COMMON1 	    ;"Incorrect DOS version"
;
;:use 2 EXTEND8 	    ;"Insufficient memory"
;
;:use 3 PARSE10 	    ;"Invalid parameter"
;;
;:def 4 "Do not specify filename(s)",CR,LF
;"Command format: DISKCOMP d: d: [/1][/8]",LF,CR
;
;:def 5 CR,LF,"Invalid drive specification",CR,LF
;"Specified drive does not exist",CR,LF
;"or is non-removable",CR,LF
;
;:def 6 CR,LF,"Cannot DISKCOMP to or from",CR,LF
;"a network drive",CR,LF
;
;:def 7 CR,LF,"Insert FIRST diskette in drive %1:",CR,LF
;
;:def 8 CR,LF,"Insert SECOND diskette in drive %1:",CR,LF
;
;:def 9 CR,LF,"FIRST diskette bad or incompatible",CR,LF
;
;:def 10 CR,LF,"SECOND diskette bad or incompatible",CR,LF
;
;:use 11 EXTEND21	      ;"Drive not ready"            NOTE CHANGE %1 TO %0
;
;:use 12 COMMON28	      ;"Press any key to continue . . ."
;
;:use 13 EXTEND19  ;CR,LF,"Attempt to write to write-protected diskette",CR,LF
;
;:def 14 CR,LF,"Compare another diskette (Y/N) ?"
;
;:def 15 CR,LF,"Comparing %1 tracks",CR,LF
;"%2 sectors per track, %3 side(s)",CR,LF
;
;:def 16 CR,LF,"Drive types or diskette types",CR,LF
;"not compatible",CR,LF
;
;:def 17 CR,LF,"Unrecoverable read error on drive %2",CR,LF
;"side %3, track %4",CR,LF
;
;:def 18 CR,LF,"Compare error on",CR,LF,"side %3, track %4",CR,LF
;
;:def 19 "Make sure a diskette is inserted into",CR,LF
;"the drive and the door is closed",CR,LF
;
;:def 20 CR,LF,"Compare process ended",CR,LF
;
;:def 21 CR,LF,"Compare OK",CR,LF
;
;:def 22 CR,LF
;:end
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	IF1				;AN000;
	    %OUT    COMPONENT=DISKCOMP, MODULE=DCOMPMS.INC...;AN000;
	ENDIF				;AN000;
;	    $SALUT (0,13,18,22) ;						;AN000;
;THIS MODULE IS INCLUDED IN DCOMPSM.SAL.
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

FOUR_SUBS   EQU  4   ;AN000;FOUR VARIABLES IN ONE MSG
PC_ID_4     EQU  4   ;AN000;IDENTIFIES FOURTH REPLACEMENT PARM
PC_ID_5     EQU  5   ;AN000;IDENTIFIES FIFTH REPLACEMENT PARM
LETTER_A    EQU  "A" ;AN000;DEFAULT DRIVE ID
CLEAR_BUF   EQU  0C0H ;AN006;CLEAR KEYBOARD BUFFER BEFORE INPUT
KEY_IN_ECHO EQU  1   ;AN000;REQUEST KEYBOARD INPUT TO AL, ECHO RESPONSE
KEY_IN	    EQU  8   ;AN000;REQUEST KEYBOARD INPUT TO AL, NO ECHO
FILL_OFF    EQU  0   ;AN000;TO BE FILLED IN WITH OFFSET TO DATA
FILL_SEG    EQU  0   ;AN000;TO BE FILLED IN WITH THE COMMON SEG ID
		     ; SINCE A .COM FILE CANNOT HAVE
		     ; SEGMENT FIXUP RECORDS

SUBLIST_PARSE  SUBLIST <,,FILL_OFF,FILL_SEG,PC_ID_0,SF_BITS <SF_LEFT,,SF_ASCIIZ,SF_CHAR>,MAX_0,MIN_1,PAD_BLK> ;AN003;
	PUBLIC SUBLIST_PARSE	   ;AN003;

;		THE NEXT GROUP ARE ADDITIONAL CLASS "A" MESSAGES
;		SPECIFICALLY DEFINED FOR THE DISKCOMP UTILITY

		     ;"Insufficient memory"
MSGNUM_UNSUF_MEMORY MSG_DESC <2> ;AN000;
	PUBLIC MSGNUM_UNSUF_MEMORY ;AN000;

		     ;CR,LF,"Invalid parameter",CR,LF
MSGNUM_INVALID_PARM MSG_DESC <3> ;AN000;
	PUBLIC MSGNUM_INVALID_PARM ;AN000;

		     ;"Do not specify filename(s)",CR,LF
		     ;"Command format: DISKCOMP d: d: [/1][/8]",CR,LF
MSGNUM_INVALID_PARM2 MSG_DESC <4> ;AN000;
	    PUBLIC MSGNUM_INVALID_PARM2 ;AN000;

; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Invalid drive specification",CR,LF
		     ;"Specified drive does not exist",CR,LF
		     ;"or is non-removable",CR,LF
MSGNUM_INVALID_DRV MSG_DESC <5> ;AN000;
	    PUBLIC MSGNUM_INVALID_DRV ;AN000;

; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Cannot DISKCOMP to or from",CR,LF
		     ;"a network drive",CR,LF
MSGNUM_DRV_REDIRECTED MSG_DESC <6> ;AN000;
	    PUBLIC MSGNUM_DRV_REDIRECTED ;AN000;

; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Insert FIRST diskette in drive %1:",CR,LF
MSGNUM_LOAD_FIRST MSG_DESC <7,,SUBLIST_78,ONE_SUBS> ;AN000;
	    PUBLIC MSGNUM_LOAD_FIRST,SUBLIST_78 ;AN000;

SUBLIST_78  SUBLIST <,,FILL_OFF,FILL_SEG,PC_ID_1,SF_BITS<SF_LEFT,,SF_CH,SF_CHAR>,MAX_0,MIN_1>;AN000;
;THE "FILL" FIELDS NEED TO BE SET TO POINT TO
;"ASCII_DRV1_ID" OR "ASCII_DRV2_ID"(BELOW).

		     ;CR,LF,"Insert SECOND diskette in drive %1:",CR,LF
MSGNUM_LOAD_SECOND MSG_DESC <8,,SUBLIST_78,ONE_SUBS> ;AN000;
	    PUBLIC MSGNUM_LOAD_SECOND ;AN000;

		     ;IF "FIRST" SPECIFIED
ASCII_DRV1_ID DB LETTER_A-BYTE ;AN000;

		     ;IF "SECOND" SPECIFIED
ASCII_DRV2_ID DB LETTER_A-BYTE ;AN000;
	    PUBLIC ASCII_DRV1_ID,ASCII_DRV2_ID ;AN000;

; = = = = = = = = = = = = = = = =
		     ;CR,LF,"FIRST diskette bad or incompatible",CR,LF
MSGNUM_BAD_FIRST  MSG_DESC <9> ;AN000;
	    PUBLIC MSGNUM_BAD_FIRST ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"SECOND diskette bad or incompatible",CR,LF
MSGNUM_BAD_SECOND  MSG_DESC <10> ;AN000;
	    PUBLIC MSGNUM_BAD_SECOND ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,Drive not ready",CR,LF
MSGNUM_GET_READY MSG_DESC <11,,SUBLIST_11,ONE_SUBS> ;AN000;
	    PUBLIC MSGNUM_GET_READY ;AN000;

SUBLIST_11  SUBLIST <,,DRIVE_LETTER,FILL_SEG,PC_ID_0,SF_BITS<SF_LEFT,,SF_ASCIIZ,SF_CHAR>,MAX_0,MIN_1>;AN000;
	    PUBLIC SUBLIST_11 ;AN000;

DRIVE_LETTER DB  LETTER_A,":",NULL ;AN000;
	    PUBLIC DRIVE_LETTER ;AN000;

SKIP_MSG     DB  NULL ;AN000;
	    PUBLIC SKIP_MSG ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Press any key to continue . . .",CR,LF
MSGNUM_STRIKE MSG_DESC <12,,,,(CLASS_A SHL 8) OR (CLEAR_BUF + KEY_IN)> ;AN006;
	    PUBLIC MSGNUM_STRIKE ;AN000;
; = = = = = = = = = = = = = = = =
;		     ;CR,LF,"Attempt to write to write-protected diskette",CR,LF
MSGNUM_WRITE_PROTECT MSG_DESC <13> ;AN000;
	    PUBLIC MSGNUM_WRITE_PROTECT ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Compare another diskette (Y/N) ?"
MSGNUM_COMP_ANOTHER MSG_DESC <14,,,,(CLASS_A SHL 8) OR (CLEAR_BUF + KEY_IN_ECHO)> ;AN006;
	    PUBLIC MSGNUM_COMP_ANOTHER ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Comparing %1 tracks",CR,LF
		     ;"%2 Sectors/Track, %3 Side(s)",CR,LF
MSGNUM_COMPARING MSG_DESC <15,,SUBLIST_15A,THREE_SUBS> ;AN000;
	    PUBLIC MSGNUM_COMPARING ;AN000;

SUBLIST_15A SUBLIST <,,MSG_TRACKS,FILL_SEG,PC_ID_1,SF_BITS<SF_LEFT,,SF_WORD,SF_UN_BD>,MAX_0,MIN_1>;AN000;
SUBLIST_15B SUBLIST <,,MSG_SECTRK,FILL_SEG,PC_ID_2,SF_BITS<SF_LEFT,,SF_WORD,SF_UN_BD>,MAX_0,MIN_1>;AN000;
SUBLIST_15C SUBLIST <,,MSG_SIDES,FILL_SEG,PC_ID_3,SF_BITS<SF_LEFT,,SF_WORD,SF_UN_BD>,MAX_0,MIN_1>;AN000;
	    PUBLIC SUBLIST_15A,SUBLIST_15B,SUBLIST_15C ;AN000;

MSG_TRACKS  DW	 0   ;AN000;NUMBER OF TRACKS
MSG_SECTRK  DW	 0   ;AN000;NUMBER OF SECTORS PER TRACK
MSG_SIDES   DW	 0   ;AN000;NUMBER OF SIDES
	    PUBLIC MSG_TRACKS,MSG_SECTRK,MSG_SIDES ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Drive types or diskette types",CR,LF
		     ;"not compatible",CR,LF
MSGNUM_NOT_COMPATIBLE MSG_DESC <16> ;AN000;
	    PUBLIC MSGNUM_NOT_COMPATIBLE ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Unrecoverable read error on drive %2",CR,LF
		     ;"side %3, track %4",CR,LF
		     ;%2 IS "DRIVE_LETTER", AND
		     ;"MSG_SIDES" AND "MSG_TRACKS" ARE %3 AND %4.
MSGNUM_HARD_ERROR_READ MSG_DESC <17,,SUBLIST_17B,THREE_SUBS> ;AN000;
	    PUBLIC MSGNUM_HARD_ERROR_READ ;AN000;

SUBLIST_17B SUBLIST <,,DRIVE_LETTER,FILL_SEG,PC_ID_2,SF_BITS<SF_LEFT,,SF_ASCIIZ,SF_CHAR>,MAX_0,MIN_1>;AN000;
SUBLIST_17C SUBLIST <,,MSG_SIDES,FILL_SEG,PC_ID_3,SF_BITS<SF_LEFT,,SF_WORD,SF_UN_BD>,MAX_0,MIN_1> ;AN000;
SUBLIST_17D SUBLIST <,,MSG_TRACKS,FILL_SEG,PC_ID_4,SF_BITS<SF_LEFT,,SF_WORD,SF_UN_BD>,MAX_0,MIN_1>;AN000;
	    PUBLIC SUBLIST_17B,SUBLIST_17C,SUBLIST_17D ;AN000;

		     ;CR,LF,"Compare error on",CR,LF
		     ;"side %3, track %4",CR,LF
		     ;"MSG_SIDES" AND "MSG_TRACKS" ARE %3 AND %4.
MSGNUM_HARD_ERROR_COMP MSG_DESC <18,,SUBLIST_17C,TWO_SUBS> ;AN000;
	    PUBLIC MSGNUM_HARD_ERROR_COMP ;AN000;
; = = = = = = = = = = = = = = = =
		     ;:def 19 "Make sure a diskette is inserted into",CR,LF
		     ;"the drive and the door is closed",CR,LF
MSGNUM_CLOSE_DOOR MSG_DESC <19> ;AN004;
	    PUBLIC MSGNUM_CLOSE_DOOR ;AN004;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Compare process ended",CR,LF
MSGNUM_FATAL_ERROR MSG_DESC <20> ;AN000;
	    PUBLIC MSGNUM_FATAL_ERROR ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Compare OK",CR,LF
MSGNUM_COMP_OK MSG_DESC <21> ;AN000;
	    PUBLIC MSGNUM_COMP_OK ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF
MSGNUM_NEWLINE MSG_DESC <22> ;AC007;
	    PUBLIC MSGNUM_NEWLINE ;AN000;
; = = = = = = = = = = = = = = = =
;end of DCOMPMS.INC
