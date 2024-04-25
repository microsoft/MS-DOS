;:util TREE			 ;utility name
;:class 1			 ;DOS extended errors
;:class 2			 ;parse errors:
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
;:class A			 ;system messages
;:use 1 COMMON1 	 ;MSG 1 is always "Incorrect DOS version"
;
;:def 2 "Directory PATH listing for Volume %1",CR,LF  ;define message
;:def 3 "Directory PATH listing",CR,LF
;:def 4 "No sub-directories exist",CR,LF,LF
;:use 5 COMMON25	 ;"Invalid path"
;:use 6 COMMON36	 ;"Volume Serial Number is %1-%2",CR,LF
;:def 7 "юдцЁ"            ;"elbo","dash","tee","bar"
;;	 1. NONE OF THE FOUR CAN BE BLANK
;;	 2. EACH OF THE FOUR MUST BE UNIQUE
;;	 3. EACH CHAR MUST BE A SINGLE BYTE (NO DBCS)
;:end
	IF1			   ;AN000;
	    %OUT    COMPONENT=TREE, MODULE=TREEMS.INC...;AN000;
	ENDIF			   ;AN000;
PAD_0	EQU    "0"                 ;AN001;NUMERIC PAD CHARACTER

SUBLIST_PARSE  SUBLIST <,,FILL_OFF,FILL_SEG,PC_ID_0,SF_BITS <SF_LEFT,,SF_ASCIIZ,SF_CHAR>,MAX_0,MIN_1,PAD_BLK> ;AN004;
	PUBLIC SUBLIST_PARSE	   ;AN004;

;		THE NEXT GROUP ARE ADDITIONAL CLASS "A" MESSAGES
;		SPECIFICALLY DEFINED FOR THE TREE UTILITY

MSGNUM_VOL     MSG_DESC <2,,SUBLIST_VOL,ONE_SUBS> ;AN000;"Directory PATH listing for Volume %1"
	PUBLIC MSGNUM_VOL	   ;AN000;

	EXTRN FIX_DTA_FILN:BYTE    ;AN000;ASCIIZ OF VOLUME LABEL STRING
SUBLIST_VOL    SUBLIST <,,FIX_DTA_FILN,FILL_SEG,PC_ID_1,SF_BITS <SF_LEFT,,SF_ASCIIZ,SF_CHAR>,MAX_0,MIN_1,PAD_BLK> ;AN000;
	PUBLIC SUBLIST_VOL	   ;AN000;
; = = = = = = = = = = = = = = = =
MSGNUM_LIST    MSG_DESC <3>	   ;AN000;"Directory PATH listing"
	PUBLIC MSGNUM_LIST	   ;AN000;
; = = = = = = = = = = = = = = = =
MSGNUM_NOSUB   MSG_DESC <4>	   ;AN000;"No sub-directories exist"
	PUBLIC MSGNUM_NOSUB	   ;AN000;
; = = = = = = = = = = = = = = = =
MSGNUM_INVPATH MSG_DESC <5,STDERR,SUBLIST_INVPATH,ONE_SUBS> ;AC014;"Invalid path"
	PUBLIC MSGNUM_INVPATH	   ;AN000;

	EXTRN START_PATH:BYTE	   ;AN014;
SUBLIST_INVPATH SUBLIST <,,START_PATH,FILL_SEG,PC_ID_0,SF_BITS <SF_LEFT,,SF_ASCIIZ,SF_CHAR>,MAX_0,MIN_1,PAD_BLK> ;AN014;
	PUBLIC SUBLIST_INVPATH
; = = = = = = = = = = = = = = = =
MSGNUM_SERNO   MSG_DESC <6,,SUBLIST_6A,TWO_SUBS> ;AN001;"Volume Serial Number is %1-%2",CR,LF
	PUBLIC MSGNUM_SERNO	   ;AN001;
SUBLIST_6A     SUBLIST <,,FILL_OFF,FILL_SEG,PC_ID_1,SF_BITS<SF_RIGHT,,SF_WORD,SF_UN_BH>,DWORD,DWORD,PAD_0> ;AN001;
SUBLIST_6B     SUBLIST <,,FILL_OFF,FILL_SEG,PC_ID_2,SF_BITS<SF_RIGHT,,SF_WORD,SF_UN_BH>,DWORD,DWORD,PAD_0> ;AN001;
	       PUBLIC SUBLIST_6A,SUBLIST_6B ;AN001;
; = = = = = = = = = = = = = = = =
;NOTE: THERE IS NO "MSG_DESC" FOR MESSAGE 7, SINCE THIS IS NEVER DISPLAYED
;AS A MESSAGE, BUT IS REFERENCED ONLY BY SYSGETMSG.
; = = = = = = = = = = = = = = = =
;END OF TREEMS.INC
