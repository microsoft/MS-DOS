PAGE	60,132				   ;AN000;
NAME	SELECT				   ;AN000;
TITLE	INPUT.ASM - DOS SELECT.EXE	   ;AN000;
SUBTTL	input.asm			   ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	INPUT.ASM:  Copyright 1988 Microsoft
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;
DATA	SEGMENT BYTE PUBLIC 'DATA'      ;AN000; Define Dummy data segment
	PUBLIC	WR_ICBVEC		;AN000;
	PUBLIC	KD_BACKSPACE		;AN000;
					;
	INCLUDE PCEQUATE.INC		;AN000;
					;
SND_FREQ       EQU  440 		;AN000;    ;frequency of error beep
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Input Field Control Block Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICBVEC DW DATA,WR_ICB1   ;AN000;ICB	1 segment,offset   STR_DOS_LOC
	DW   DATA,WR_ICB2   ;AN000;ICB	2 segment,offset   STR_EXT_PARMS
	DW   DATA,WR_ICB3   ;AN000;ICB	3 segment,offset   STR_DOS_PATH
	DW   DATA,WR_ICB4   ;AN000;ICB	4 segment,offset   STR_DOS_APPEND
	DW   DATA,WR_ICB5   ;AN000;ICB	5 segment,offset   STR_DOS_PROMPT
	DW   DATA,WR_ICB6   ;AN000;ICB	6 segment,offset   STR_SHELL
	DW   DATA,WR_ICB7   ;AN000;ICB	7 segment,offset   STR_KSAM
	DW   DATA,WR_ICB8   ;AN000;ICB	8 segment,offset   STR_FASTOPEN
	DW   DATA,WR_ICB9   ;AN000;ICB	9 segment,offset   STR_SHARE
	DW   DATA,WR_ICB10  ;AN000;ICB 10 segment,offset   STR_GRAPHICS
	DW   DATA,WR_ICB11  ;AN000;ICB 11 segment,offset   STR_XMAEM
	DW   DATA,WR_ICB12  ;AN000;ICB 12 segment,offset   STR_XMA2EMS
	DW   DATA,WR_ICB13  ;AN000;ICB 13 segment,offset   STR_VDISK
	DW   DATA,WR_ICB14  ;AN000;ICB 14 segment,offset   STR_BREAK
	DW   DATA,WR_ICB15  ;AN000;ICB 15 segment,offset   STR_BUFFERS
	DW   DATA,WR_ICB16  ;AN000;ICB 16 segment,offset   STR_DOS_APPEND_P JW
	DW   DATA,WR_ICB17  ;AN000;ICB 17 segment,offset   STR_FCBS
	DW   DATA,WR_ICB18  ;AN000;ICB 18 segment,offset   STR_FILES
	DW   DATA,WR_ICB19  ;AN000;ICB 19 segment,offset   STR_LASTDRIVE
	DW   DATA,WR_ICB20  ;AN000;ICB 20 segment,offset   STR_STACKS
	DW   DATA,WR_ICB21  ;AN000;ICB 21 segment,offset   STR_VERIFY
	DW   DATA,WR_ICB22  ;AN000;ICB 23 segment,offset   NUM_PRINTER
	DW   DATA,WR_ICB23  ;AN000;ICB 23 segment,offset   NUM_EXT_DISK
	DW   DATA,WR_ICB24  ;AN000;ICB 24 segment,offset   NUM_YEAR
	DW   DATA,WR_ICB25  ;AN000;ICB 25 segment,offset   NUM_MONTH
	DW   DATA,WR_ICB26  ;AN000;ICB 26 segment,offset   NUM_DAY
	DW   DATA,WR_ICB27  ;AN000;ICB 27 segment,offset   NUM_HOUR
	DW   DATA,WR_ICB28  ;AN000;ICB 28 segment,offset   NUM_MINUTE
	DW   DATA,WR_ICB29  ;AN000;ICB 29 segment,offset   NUM_SECOND
	DW   DATA,WR_ICB30  ;AN000;ICB 29 segment,offset   DEF_CP
	DW   DATA,WR_ICB31  ;AN000;ICB 29 segment,offset   SWISS_KEYB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 1   STR_DOS_LOC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB1        DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   8			  ;AN000;**;upper left corner field row
	       DW   33			  ;AN000;**;upper left corner field column
	       DW   40			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   40			     ;AC069;SEH  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_PATH_CHAR_LEN	     ;AN000;length of allow chars
	       DW   WR_PATH_CHAR	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
					     ;
WR_PATH_CHAR  DB   "'",',0-9,,a-z,,A-Z,,�-�, $!"#%&()-.@\`_{}~^,,,' ;AN000;
WR_PATH_CHAR_LEN  EQU ($-WR_PATH_CHAR)	     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 2  STR_EXT_PARMS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB2        DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR+ICB_WHM+ICB_WEN+ICB_WDL+ICB_WAR+ICB_WBS  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   7			  ;AN000;**;upper left corner field row
	       DW   44			  ;AN000;**;upper left corner field column
	       DW   75 ;;AN000;35		  ;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_CHAR_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_CHAR	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 3  STR_DOS_PATH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB3        DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR+ICB_WHM+ICB_WEN+ICB_WDL+ICB_WAR+ICB_WBS  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   8			  ;AN000;**;upper left corner field row
	       DW   30			  ;AN000;**;upper left corner field column
	       DW   40			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_APPEND_CHAR_LEN	      ;AN000;length of allow chars
	       DW   WR_APPEND_CHAR	      ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
					     ;;;
					       ;
WR_APPEND_CHAR	DB   "'",',0-9,,a-z,,A-Z,,�-�, ;$!"#%&()-.:@\`_{}~^,,,' ;AN000;
WR_APPEND_CHAR_LEN  EQU ($-WR_APPEND_CHAR)     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 4  STR_DOS_APPEND
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB4        DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR+ICB_WHM+ICB_WEN+ICB_WDL+ICB_WAR+ICB_WBS  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   12			  ;AN000;**;upper left corner field row
	       DW   30			  ;AN000;**;upper left corner field column
	       DW   40			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_APPEND_CHAR_LEN	      ;AN000;length of allow chars
	       DW   WR_APPEND_CHAR	      ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 5  STR_DOS_PROMPT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB5        DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR+ICB_WHM+ICB_WEN+ICB_WDL+ICB_WAR+ICB_WBS  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   15			  ;AN000;**;upper left corner field row
	       DW   30			  ;AN000;**;upper left corner field column
	       DW   30			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_PROMPT_CHAR_LEN	      ;AN000;length of allow chars
	       DW   WR_PROMPT_CHAR	      ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
					     ;;;;;;;;;;;;;
							 ;
WR_PROMPT_CHAR	DB   "'",',0-9,,a-z,,A-Z,,�-�,\/ $!"#%()*+-.;@`[]_{}~,,,' ;AN000;
WR_PROMPT_CHAR_LEN  EQU ($-WR_PROMPT_CHAR)		 ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 6  STR_SHELL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB6        DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR+ICB_WHM+ICB_WEN+ICB_WDL+ICB_WAR+ICB_WBS  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   8			  ;AN000;**;upper left corner field row
	       DW   38			  ;AN000;**;upper left corner field column
	       DW   15			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_CHAR_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_CHAR	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 7  STR_KSAM
;
;	This field will not be used with the shipped version
;	of SELECT.  
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB7        DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR+ICB_WHM+ICB_WEN+ICB_WDL+ICB_WAR+ICB_WBS  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   7			  ;AN000;**;upper left corner field row
	       DW   36			  ;AN000;**;upper left corner field column
	       DW   40			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_CHAR_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_CHAR	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 8  STR_FASTOPEN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB8        DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR+ICB_WHM+ICB_WEN+ICB_WDL+ICB_WAR+ICB_WBS  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   8			  ;AN000;**;upper left corner field row
	       DW   40			  ;AN000;**;upper left corner field column
	       DW   40			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_CHAR_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_CHAR	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 9  STR_SHARE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB9        DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   8			  ;AN000;**;upper left corner field row
	       DW   36			  ;AN000;**;upper left corner field column
	       DW   40			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   40			     ;AC069;SEH  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_CHAR_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_CHAR	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 10  STR_GRAPHICS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB10       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR+ICB_WHM+ICB_WEN+ICB_WDL+ICB_WAR+ICB_WBS  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   8			  ;AN000;**;upper left corner field row
	       DW   34			  ;AN000;**;upper left corner field column
	       DW   40			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_GRAPHIC_CHAR_LEN        ;AN000;length of allow chars
	       DW   WR_GRAPHIC_CHAR	       ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
WR_GRAPHIC_CHAR  DB   "'",',0-9,,a-z,,A-Z,\ !"#%()*+-.;@`[]_{}~/,,,' ;AN000;
WR_GRAPHIC_CHAR_LEN  EQU ($-WR_GRAPHIC_CHAR)		 ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 11  STR_XMAEM
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB11       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR+ICB_WHM+ICB_WEN+ICB_WDL+ICB_WAR+ICB_WBS  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   8			  ;AN000;**;upper left corner field row
	       DW   36			  ;AN000;**;upper left corner field column
	       DW   40			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_CHAR_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_CHAR	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 12  STR_XMA2EMS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB12       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR+ICB_WHM+ICB_WEN+ICB_WDL+ICB_WAR+ICB_WBS  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   11			  ;AN000;**;upper left corner field row
	       DW   36			  ;AN000;**;upper left corner field column
	       DW   40			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_CHAR_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_CHAR	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 13  STR_VDISK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB13       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   8			  ;AN000;**;upper left corner field row
	       DW   36			  ;AN000;**;upper left corner field column
	       DW   40			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   40			     ;AC069;SEH  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_CHAR_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_CHAR	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 14  STR_BREAK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB14       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;;AN000;;+ICB_CLR  ;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   8			     ;AN000;**;upper left corner field row
	       DW   26			     ;AN000;**;upper left corner field column
	       DW   3			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   3			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ON_OFF_CHAR_LEN	      ;AN000;length of allow chars
	       DW   WR_ON_OFF_CHAR	      ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
WR_ON_OFF_CHAR	DB   ' OFNofn'               ;AN000;
WR_ON_OFF_CHAR_LEN  EQU ($-WR_ON_OFF_CHAR)   ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 15  STR_BUFFERS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB15       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   9			     ;AN000;**;upper left corner field row
	       DW   26			     ;AN000;**;upper left corner field column
	       DW   7			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   7			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_BUFFERS_LEN	     ;AN000;length of allow chars
	       DW   WR_BUFFERS		     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
					     ;
WR_BUFFERS     DB   ' ,0-9,,,,'              ;AN000;
WR_BUFFERS_LEN EQU  $-WR_BUFFERS	     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 16  STR_DOS_APPEND_P   formerly STR_CPSW	   ;AC000;JW
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB16       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR+ICB_WHM+ICB_WEN+ICB_WDL+ICB_WAR+ICB_WBS  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   11			  ;AN000;**;upper left corner field row
	       DW   30			  ;AN000;**;upper left corner field column
	       DW   40			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_CHAR_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_CHAR	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 17  STR_FCBS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB17       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   10	;AC000;JW	     ;**;upper left corner field row
	       DW   26			     ;AN000;**;upper left corner field column
	       DW   7			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   7			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_FCBS_LEN 	    ;AN000;length of allow chars
	       DW   WR_FCBS		    ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
					     ;
WR_FCBS        DB   ' ,0-9,,,,'              ;AN000;
WR_FCBS_LEN    EQU  ($-WR_FCBS) 	     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 18  STR_FILES
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB18       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   11	 ;AC000;JW	     ;**;upper left corner field row
	       DW   26			     ;AN000;**;upper left corner field column
	       DW   3			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   3			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_BUFFERS_LEN	    ;AN000;length of allow chars
	       DW   WR_BUFFERS		    ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 19  STR_LASTDRIVE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB19       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_DEL+ICB_UPC+ICB_CSW  ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   12 ;AC000;JW	     ;**;upper left corner field row
	       DW   26			     ;AN000;**;upper left corner field column
	       DW   1			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   1			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ASCII_CHAR_LEN	     ;AN000;length of allow chars
	       DW   WR_ASCII_CHAR	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
WR_ASCII_CHAR  DB   ' ,a-z,,A-Z,'            ;AN000;
WR_ASCII_CHAR_LEN  EQU ($-WR_ASCII_CHAR)     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 20  STR_STACKS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB20       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		    ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   13	 ;AC000;JW	     ;**;upper left corner field row
	       DW   26			     ;AN000;**;upper left corner field column
	       DW   6			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   6			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_FCBS_LEN 	    ;AN000;length of allow chars
	       DW   WR_FCBS		    ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 21  STR_VERIFY
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB21       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS   ;;AN000;+ICB_CLR	;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   14	;AC000;JW	     ;**;upper left corner field row
	       DW   26			     ;AN000;**;upper left corner field column
	       DW   3			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   3			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ON_OFF_CHAR_LEN	      ;AN000;length of allow chars
	       DW   WR_ON_OFF_CHAR	      ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 22  NUM_PRINTER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB22       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_DEL+ICB_CSW	     ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   6			     ;AN000;**;upper left corner field row
	       DW   50			     ;AN000;**;upper left corner field column
	       DW   1			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   1			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_NUM_PTR_LEN	     ;AN000;length of allow chars
	       DW   WR_NUM_PTR		     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
					     ;
WR_NUM_PTR     DB   ' ,0-7,'                 ;AN000;
WR_NUM_PTR_LEN EQU ($-WR_NUM_PTR)	     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 23  NUM_EXT_DISK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB23       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;AN000;option word one
	       DW   ICB_DEL+ICB_CSW	     ;AN000;option word two
	       DW   0			     ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   5			  ;AN000;**;upper left corner field row
	       DW   55			  ;AN000;**;upper left corner field column
	       DW   1			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_NUM_EXT_LEN	     ;AN000;length of allow chars
	       DW   WR_NUM_EXT		     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
					     ;
WR_NUM_EXT     DB   ' 012'                   ;AN000;
WR_NUM_EXT_LEN EQU ($-WR_NUM_EXT)	     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 24  NUM_YEAR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB24       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;;AN000; +ICB_CLR  ;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   6			     ;AN000;**;upper left corner field row
	       DW   24			     ;AN000;**;upper left corner field column
	       DW   4			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   4			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_NUM_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_NUM	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 25  NUM_MONTH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB25       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS  ;;AN000;+ICB_CLR  ;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   8			     ;AN000;**;upper left corner field row
	       DW   24			     ;AN000;**;upper left corner field column
	       DW   2			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   2			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_NUM_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_NUM	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 26  NUM_DAY
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB26       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS  ;;AN000;+ICB_CLR  ;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   10			     ;AN000;**;upper left corner field row
	       DW   24			     ;AN000;**;upper left corner field column
	       DW   2			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   2			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_NUM_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_NUM	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 27  NUM_HOUR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB27       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS  ;;AN000;+ICB_CLR  ;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   16			     ;AN000;**;upper left corner field row
	       DW   24			     ;AN000;**;upper left corner field column
	       DW   2			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   2			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_NUM_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_NUM	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 28  NUM_MINUTE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB28       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS  ;;AN000;+ICB_CLR  ;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC069;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   18			     ;AN000;**;upper left corner field row
	       DW   24			     ;AN000;**;upper left corner field column
	       DW   2			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   2			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_NUM_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_NUM	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 29  NUM_SECOND
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB29       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS ;;AN000;+ICB_CLR ;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_HOR		     ;AC0O69;SEH ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   20			     ;AN000;**;upper left corner field row
	       DW   24			     ;AN000;**;upper left corner field column
	       DW   2			     ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			     ;AN000;**;cursor character pos in field
	       DW   1			     ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   2			     ;AC069;SEH ;AN000;**;length of input field
	       DW   0			     ;AN000;??;offset of input field
	       DW   0			     ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   0			     ;AN000;length of field's default value
	       DW   0			     ;AN000;offset field's default value
	       DW   0			     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_NUM_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_NUM	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 30 PRIMARY_CP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB30       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS  ;;AN000;+ICB_CLR ;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_WIN  ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   20			  ;AN000;**;upper left corner field row
	       DW   24			  ;AN000;**;upper left corner field column
	       DW   2			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   ICB_DEFBUF30_L+2	     ;AN000;length of field's default value
	       DW   ICB_DEFBUF30	     ;AN000;offset field's default value
	       DW   DATA		     ;AN000;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_NUM_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_NUM	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
					     ;
ICB_DEFBUF30   DW   ICB_DEFBUF30_L	     ;AN000;Define default buffer ASCIIN
	       DB   '850'                    ;AN000;Define default buffer
ICB_DEFBUF30_L EQU  $-ICB_DEFBUF30-2	     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB 31 COUNTRY_LANG
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ICB31       DW   ICB_BEN+ICB_RTA+ICB_LFA+ICB_BKS  ;;AN000;+ICB_CLR ;option word one
	       DW   ICB_INS+ICB_DEL+ICB_HOM+ICB_END+ICB_UPC   ;AN000;option word two
	       DW   ICB_WIN ;AN000;option word three
	       DW   0			     ;AN000;option word four
	       DW   20			  ;AN000;**;upper left corner field row
	       DW   24			  ;AN000;**;upper left corner field column
	       DW   2			  ;AN000;**;number of chars before wrapping
	       DW   1			     ;AN000;color index number assigned
	       DW   0			     ;AN000;default change/minus status
	       DW   1			  ;AN000;**;cursor character pos in field
	       DW   1			  ;AN000;**;NEW ADD Hor scroll support
	       DW   SND_FREQ		     ;AN000;frequency of error beep
	       DW   0			     ;AN000;ASCII code of the key returned
	       DW   0			     ;AN000;length of data entered into fld
	       DW   0			  ;AN000;**;length of input field
	       DW   0			  ;AN000;??;offset of input field
	       DW   0			  ;AN000;??;segment of input field
	       DW   0			     ;AN000;offset of color attribute buffer
	       DW   0			     ;AN000;segment of color attr buffer
	       DW   ICB_DEFBUF31_L+2	  ;AN000;??;length of field's default value
	       DW   ICB_DEFBUF31	  ;AN000;??;offset field's default value
	       DW   DATA		  ;AN000;??;segment field's default value
	       DW   0			     ;AN000;length of return string
	       DW   0			     ;AN000;offset of return string
	       DW   0			     ;AN000;segment of return string
	       DW   WR_ALLOW_NUM_LEN	     ;AN000;length of allow chars
	       DW   WR_ALLOW_NUM	     ;AN000;offset of allow chars
	       DW   DATA		     ;AN000;segment of allow chars
	       DW   0			     ;AN000;length of skip chars
	       DW   0			     ;AN000;offset of skip chars
	       DW   0			     ;AN000;segment of skip chars
	       DW   0			     ;AN000;length of allow once chars
	       DW   0			     ;AN000;offset of allow once chars
	       DW   0			     ;AN000;segment of allow once chars
	       DW   2			     ;AN000;precision of decimal point
	       DW   0			     ;AN000;low numeric range (low intrgr)
	       DW   0			     ;AN000;low numeric range (high intrgr)
	       DW   0			     ;AN000;high numeric range (low intrgr)
	       DW   0			     ;AN000;high numeric range (high intrgr)
	       DW   0			     ;AN000;beginning row of minus and plus
	       DW   0			     ;AN000;beginning col of minus & plus
	       DW   0			     ;AN000;length of minus sign string
	       DW   0			     ;AN000;offset of minus sign string
	       DW   0			     ;AN000;segment of minus sign string
	       DW   0			     ;AN000;length of plus sign string
	       DW   0			     ;AN000;offset of plus sign string
	       DW   0			     ;AN000;segment of plus sign string
					     ;
ICB_DEFBUF31   DW   ICB_DEFBUF31_L	     ;AN000;Define default buffer ASCIIN
	       DB   'SG'                     ;AN000;
ICB_DEFBUF31_L EQU  $-ICB_DEFBUF31-2	     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Table of Key Definitions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
KD_BACKSPACE   DB   8,0 		     ;AN000;ASCII backspace
KD_UNDOKEY     DB   0,59		     ;AN000;ASCII code replace default key
KD_SWCHKEY     DB   0,60		     ;AN000;ASCII code switch char direction
KD_DEL	       DB   0,83		     ;AN000;extended ASCII delete key
KD_CTRLEND     DB   0,117		     ;AN000;extended ASCII Control-End key
KD_HOME        DB   0,71		     ;AN000;extended ASCII home key
KD_END	       DB   0,79		     ;AN000;extended ASCII end key
KD_INS	       DB   0,82		     ;AN000;extended ASCII insert key
KD_LARROW      DB   0,75		     ;AN000;extended ASCII left arrow
KD_RARROW      DB   0,77		     ;AN000;extended ASCII right arrow
KD_UARROW      DB   0,72		     ;AN000;extended ASCII up arrow
KD_DARROW      DB   0,80		     ;AN000;extended ASCII down arrow
KD_MINUS       DB   45,0		     ;AN000;ASCII minus sign
KD_PLUS        DB   43,0		     ;AN000;ASCII plus sign
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Define Buffers and Strings
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_ALLOW_CHAR  DB   ', -�,'                  ;AN000;
WR_ALLOW_CHAR_LEN  EQU ($-WR_ALLOW_CHAR)     ;AN000;
WR_ALLOW_NUM   DB   ' ,0-9,'                 ;AN000;
WR_ALLOW_NUM_LEN   EQU ($-WR_ALLOW_NUM)      ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA	ENDS				     ;AN000;
	END				     ;AN000;
