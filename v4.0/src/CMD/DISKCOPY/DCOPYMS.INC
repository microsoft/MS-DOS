;:util DISKCOPY 	    ;utility name
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
;:def 2 CR,LF
;
;:use 3 PARSE10 	    ;CR,LF,"Invalid parameter",CR,LF
;
;:def 4 "Do not specify filename(s)",CR,LF
;"Command Format: DISKCOPY d: d: [/1]",CR,LF
;;
;:def 5 CR,LF,"Invalid drive specification",CR,LF
;"Specified drive does not exist",CR,LF
;"or is non-removable",CR,LF
;
;:def 6 CR,LF,"Cannot DISKCOPY to or from",CR,LF
;"a network drive",CR,LF
;
;:def 7 CR,LF,"Formatting while copying",CR,LF
;
;:def 8 CR,LF,"Insert SOURCE diskette in drive %1:",CR,LF
;
;:def 9 CR,LF,"Insert TARGET diskette in drive %1:",CR,LF
;
;:def 10 "Make sure a diskette is inserted into",CR,LF
;"the drive and the door is closed",CR,LF
;
;:def 11 CR,LF,"Target diskette may be unusable",CR,LF
;
;:def 12 CR,LF,"Target diskette unusable",CR,LF
;
;:use 13 EXTEND21	    ;CR,LF,Drive not ready",CR,LF
;
;:use 14 EXTEND19  ;CR,LF,"Attempt to write to write-protected diskette",CR,LF
;
;:use 15 COMMON28	    ;CR,LF,"Press any key to continue . . .",CR,LF
;
;:def 16 CR,LF,"Copy another diskette (Y/N)? "
;
;:def 17 CR,LF,"Copying %1 tracks",CR,LF
;"%2 Sectors/Track, %3 Side(s)",CR,LF
;
;:def 18 CR,LF,"Drive types or diskette types",CR,LF
;"not compatible",CR,LF
;
;:def 19 CR,LF,"Unrecoverable read error on drive %1",CR,LF
;"Side %2, track %3",CR,LF
;
;:def 20 CR,LF,"Unrecoverable write error on drive %1",CR,LF
;"Side %2, track %3",CR,LF
;
;:def 21 CR,LF,"Copy process ended",CR,LF
;
;:def 22 CR,LF,"SOURCE diskette bad or incompatible"
;
;:def 23 CR,LF,"TARGET diskette bad or incompatible"
;
;:use 25 EXTEND8	    ;CR,LF,"Insufficient memory",CR,LF
;
;:use 26 COMMON36	    ;"Volume Serial Number is %1-%2",CR,LF
;
;:end
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	IF1							  ;AN000;
	    %OUT    COMPONENT=DISKCOPY, MODULE=DCOPYMS.INC...	  ;AN000;
	ENDIF							  ;AN000;
;	    $SALUT (0,13,18,22) ;				  ;AN000;
;THIS MODULE IS INCLUDED IN DCOPYSM.SAL.
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
	    HEADER <MESSAGE DESCRIPTORS FOR SPECIFIC MESSAGES> ;AN000;

FOUR_SUBS   EQU  4   ;AN000;FOUR VARIABLES IN ONE MSG
PC_ID_4     EQU  4   ;AN000;IDENTIFIES FOURTH REPLACEMENT PARM
LETTER_A    EQU  "A" ;AN000;DEFAULT DRIVE ID
PAD_0	    EQU  "0" ;AN001;PAD CHAR FOR NUMERIC FIXED LEN FIELD
FILL_OFF    EQU  0   ;AN000;TO BE FILLED IN WITH OFFSET TO DATA
FILL_SEG    EQU  0   ;AN000;TO BE FILLED IN WITH THE COMMON SEG ID
		     ; SINCE A .COM FILE CANNOT HAVE
		     ; SEGMENT FIXUP RECORDS

;		DOS FUNCTIONS REFERENCED:
CLEAR_BUF   EQU  0C0H ;AN007;CLEAR KEYBOARD BUFFER BEFORE INPUT
KEY_IN	    EQU  08H ;AN000;WAIT FOR STD INPUT, NO ECHO
		     ;OUTPUT: AL = CHAR FROM KEYBOARD
		     ;CTL-BREAK IS CHECKED FOR

KEY_IN_ECHO EQU  01H ;AN000;WAIT FOR STD INPUT, ECHO RESPONSE
		     ;OUTPUT: AL = CHAR FROM KEYBOARD
		     ;CTL-BREAK IS CHECKED FOR

SUBLIST_PARSE  SUBLIST <,,FILL_OFF,FILL_SEG,PC_ID_0,SF_BITS <SF_LEFT,,SF_ASCIIZ,SF_CHAR>,MAX_0,MIN_1,PAD_BLK> ;AN003;
	PUBLIC SUBLIST_PARSE	   ;AN003;

;		THE NEXT GROUP ARE ADDITIONAL CLASS "A" MESSAGES
;		SPECIFICALLY DEFINED FOR THE DISKCOPY UTILITY

		     ;CR,LF
MSGNUM_CR_LF  MSG_DESC <2> ;AN000;
	    PUBLIC MSGNUM_CR_LF ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Invalid parameter",CR,LF
MSGNUM_INVALID_PARM MSG_DESC <3> ;AN000;
	    PUBLIC MSGNUM_INVALID_PARM ;AN000;
; = = = = = = = = = = = = = = = =
		     ; "Do not specify filename(s)",CR,LF
		     ; "Command Format: DISKCOPY d: d: [/1]",CR,LF
MSGNUM_INVALID_PARM2 MSG_DESC <4> ;AN000;
	    PUBLIC MSGNUM_INVALID_PARM2 ;AN000;
; = = = = = = = = = = = = = = = =
		     ;:def 5 CR,LF,"Invalid drive specification",CR,LF
		     ;"Specified drive does not exist",CR,LF
		     ;"or is non-removable",CR,LF
MSGNUM_INVALID_DRV MSG_DESC <5> ;AN000;
	    PUBLIC MSGNUM_INVALID_DRV ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Cannot DISKCOPY to or from",CR,LF
		     ;"a network drive",CR,LF
MSGNUM_DRV_REDIRECTED MSG_DESC <6> ;AN000;
	    PUBLIC MSGNUM_DRV_REDIRECTED ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Formatting while copying",CR,LF
MSGNUM_FORMATTING MSG_DESC <7> ;AN000;
	    PUBLIC MSGNUM_FORMATTING ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Insert SOURCE diskette in drive %1:",CR,LF
MSGNUM_LOAD_SOURCE MSG_DESC <8,,SUBLIST_8,ONE_SUBS> ;AN000;
	    PUBLIC MSGNUM_LOAD_SOURCE ;AN000;

SUBLIST_8  SUBLIST <,,ASCII_DRV1_ID,FILL_SEG,PC_ID_1,SF_BITS<SF_LEFT,,SF_CH,SF_CHAR>,MAX_0,MIN_1> ;AN000;
	    PUBLIC SUBLIST_8 ;AN000;

ASCII_DRV1_ID DB LETTER_A - BYTE;AN000;
	    PUBLIC ASCII_DRV1_ID ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Insert TARGET diskette in drive %1:",CR,LF
MSGNUM_LOAD_TARGET MSG_DESC <9,,SUBLIST_9,ONE_SUBS> ;AN000;
	    PUBLIC MSGNUM_LOAD_TARGET ;AN000;

SUBLIST_9  SUBLIST <,,ASCII_DRV2_ID,FILL_SEG,PC_ID_1,SF_BITS<SF_LEFT,,SF_CH,SF_CHAR>,MAX_0,MIN_1> ;AN000;
	    PUBLIC SUBLIST_9 ;AN000;

ASCII_DRV2_ID DB LETTER_A - BYTE ;AN000;A:=1, B:=1, ETC
	    PUBLIC ASCII_DRV2_ID ;AN000;
; = = = = = = = = = = = = = = = =
		     ;:def 10 "Make sure a diskette is inserted into",CR,LF
		     ;"the drive and the door is closed",CR,LF
MSGNUM_CLOSE_DOOR MSG_DESC <10> ;AN004;
	    PUBLIC MSGNUM_CLOSE_DOOR ;AN004;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Target diskette may be unusable",CR,LF
MSGNUM_TARGET_MB_UNUSABLE MSG_DESC <11> ;AN000;
	    PUBLIC MSGNUM_TARGET_MB_UNUSABLE ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Target diskette unusable",CR,LF
MSGNUM_TARGET_UNUSABLE MSG_DESC <12> ;AN000;
	    PUBLIC MSGNUM_TARGET_UNUSABLE ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Drive not ready - %0",CR,LF
MSGNUM_GET_READY MSG_DESC <13,,SUBLIST_13,ONE_SUBS> ;AN000;
	    PUBLIC MSGNUM_GET_READY ;AN000;

SUBLIST_13  SUBLIST <,,DRIVE_LETTER,FILL_SEG,PC_ID_0,SF_BITS<SF_LEFT,,SF_ASCIIZ,SF_CHAR>,MAX_0,MIN_1> ;AN000;
	    PUBLIC SUBLIST_13 ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Attempt to write to write-protected diskette",CR,LF
MSGNUM_WRITE_PROTECT MSG_DESC <14> ;AN000;
	    PUBLIC MSGNUM_WRITE_PROTECT ;AN000;
; = = = = = = = = = = = = = = = =
		     ;"Press any key to continue . . .",CR,LF
MSGNUM_STRIKE MSG_DESC <15,,,,(CLASS_A SHL 8) OR (CLEAR_BUF + KEY_IN)> ;AN007;
	    PUBLIC MSGNUM_STRIKE ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Copy another diskette (Y/N)? "
		     ; AND READ RESPONSE TO AL
		     ; (EVENTUALLY EXPECTED IN "USER_INPUT")
MSGNUM_COPY_ANOTHER MSG_DESC <16,,,,(CLASS_A SHL 8) OR (CLEAR_BUF + KEY_IN_ECHO)> ;AN007;
	    PUBLIC MSGNUM_COPY_ANOTHER ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Copying %1 tracks",CR,LF
		     ;"%2 Sectors/Track, %3 Side(s)",CR,LF
MSGNUM_COPYING MSG_DESC <17,,SUBLIST_17A,THREE_SUBS> ;AN000;
	    PUBLIC MSGNUM_COPYING ;AN000;

SUBLIST_17A SUBLIST <,,MSG_TRACKS,FILL_SEG,PC_ID_1,SF_BITS<SF_LEFT,,SF_WORD,SF_UN_BD>,MAX_0,MIN_1> ;AN000;
SUBLIST_17B SUBLIST <,,MSG_SECTRK,FILL_SEG,PC_ID_2,SF_BITS<SF_LEFT,,SF_WORD,SF_UN_BD>,MAX_0,MIN_1> ;AN000;
SUBLIST_17C SUBLIST <,,MSG_SIDES,FILL_SEG,PC_ID_3,SF_BITS<SF_LEFT,,SF_WORD,SF_UN_BD>,MAX_0,MIN_1> ;AN000;
	    PUBLIC SUBLIST_17A ;AN000;
	    PUBLIC SUBLIST_17B ;AN000;
	    PUBLIC SUBLIST_17C ;AN000;

MSG_TRACKS  DW	 0   ;AN000;NUMBER OF TRACKS
MSG_SECTRK  DW	 0   ;AN000;NUMBER OF SECTORS PER TRACK
MSG_SIDES   DW	 0   ;AN000;NUMBER OF SIDES
	    PUBLIC MSG_TRACKS ;AN000;
	    PUBLIC MSG_SECTRK ;AN000;
	    PUBLIC MSG_SIDES ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Drive types or diskette types",CR,LF
		     ;"not compatible",CR,LF
MSGNUM_NOT_COMPATIBLE MSG_DESC <18> ;AN000;
	    PUBLIC MSGNUM_NOT_COMPATIBLE ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Unrecoverable read error on drive %1",CR,LF
		     ;"Side %2, track %3",CR,LF
MSGNUM_HARD_ERROR_READ MSG_DESC <19,,SUBLIST_19C,THREE_SUBS> ;AN000;
	    PUBLIC MSGNUM_HARD_ERROR_READ ;AN000;

		     ;CR,LF,"Unrecoverable write error on drive %1",CR,LF
		     ;"Side %2, track %3",CR,LF
MSGNUM_HARD_ERROR_WRITE MSG_DESC <20,,SUBLIST_19C,THREE_SUBS> ;AN000;
	    PUBLIC MSGNUM_HARD_ERROR_WRITE ;AN000;

SUBLIST_19C SUBLIST <,,DRIVE_LETTER,FILL_SEG,PC_ID_1,SF_BITS<SF_LEFT,,SF_ASCIIZ,SF_CHAR>,MAX_0,MIN_1> ;AN000;
SUBLIST_19D SUBLIST <,,ERROR_SIDE_NUMBER,FILL_SEG,PC_ID_2,SF_BITS<SF_LEFT,,SF_WORD,SF_UN_BD>,MAX_0,MIN_1> ;AN000;
SUBLIST_19E SUBLIST <,,ERROR_TRACK_NUMBER,FILL_SEG,PC_ID_3,SF_BITS<SF_LEFT,,SF_WORD,SF_UN_BD>,MAX_0,MIN_1> ;AN000;
	    PUBLIC SUBLIST_19C ;AN000;
	    PUBLIC SUBLIST_19D ;AN000;
	    PUBLIC SUBLIST_19E ;AN000;

DRIVE_LETTER DB  LETTER_A,":",NULL ;AN000;
	    PUBLIC DRIVE_LETTER ;AN000;

ERROR_SIDE_NUMBER DW ? ;AN000;
	    PUBLIC ERROR_SIDE_NUMBER ;AN000;

ERROR_TRACK_NUMBER DW ? ;AN000;
	    PUBLIC ERROR_TRACK_NUMBER ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Copy process ended",CR,LF
MSGNUM_FATAL_ERROR MSG_DESC <21> ;AN000;
	    PUBLIC MSGNUM_FATAL_ERROR ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"SOURCE diskette bad or incompatible"
MSGNUM_BAD_SOURCE  MSG_DESC <22> ;AN000;
	    PUBLIC MSGNUM_BAD_SOURCE ;AN000;

; = = = = = = = = = = = = = = = =
		     ;CR,LF,"TARGET diskette bad or incompatible"
MSGNUM_BAD_TARGET MSG_DESC <23> ;AN000;
	    PUBLIC MSGNUM_BAD_TARGET ;AN000;
; = = = = = = = = = = = = = = = =
		     ;CR,LF,"Insufficient memory",CR,LF
MSGNUM_UNSUF_MEMORY MSG_DESC <25> ;AN000;
	    PUBLIC MSGNUM_UNSUF_MEMORY ;AN000;
; = = = = = = = = = = = = = = = =
		     ;"Volume Serial Number is %1-%2"
MSGNUM_SERNO MSG_DESC <26,,SUBLIST_26A,TWO_SUBS> ;AN001;
	    PUBLIC MSGNUM_SERNO ;AN001;

SUBLIST_26A  SUBLIST <,,FILL_OFF,FILL_SEG,PC_ID_1,SF_BITS<SF_RIGHT,,SF_WORD,SF_UN_BH>,DWORD,DWORD,PAD_0> ;AN001;
SUBLIST_26B  SUBLIST <,,FILL_OFF,FILL_SEG,PC_ID_2,SF_BITS<SF_RIGHT,,SF_WORD,SF_UN_BH>,DWORD,DWORD,PAD_0> ;AN001;
	    PUBLIC SUBLIST_26A,SUBLIST_26B ;AN001;
; = = = = = = = = = = = = = = = =
;end of DCOPYMS.INC
