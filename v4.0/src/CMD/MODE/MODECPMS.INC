;MODECPMS.INC - INCLUDED IN MODECP.SAL 
 IF1
 %OUT INCLUDE MODECPMS.INC ;DESCRIPTIONS OF MESSAGES
 ENDIF

;$SALUT CP(0,2,9,32)	       ;(set preprocessor columns for indenting)

 EXTRN	CPMSG1:WORD	   ;"Failure to access Codepage Font File",BEEP,CR,LF,EOM

 EXTRN	CPMSG2:WORD	   ;"Failure to OPEN device: %S",CR,LF,EOM
 EXTRN	CPMSGLST2DEV:WORD      ;FILLED IN WITH PTR TO DEVICE NAME

 EXTRN	CPMSG3:WORD	   ;"Missing from font file is either device or codepage",BEEP,CR,LF,EOM

 EXTRN	CPMSG4:WORD	   ;"Font file contents invalid",CR,LF,EOM

 EXTRN	CPMSG5:WORD	   ;"Previously prepared codepage deleted",BEEP,CR,LF,EOM

 EXTRN	CPMSG6:WORD	   ;"Active codepage for %S is %D",CR,LF,EOM
 EXTRN	CPMSGLST6DEV:WORD      ;FILLED IN BY "QUERY" ROUTINE WITH PTR TO DEVICE NAME
 EXTRN	CPMSGLST6CP:WORD       ;FILLED IN BY "QUERY" ROUTINE WITH CODEPAGE ID

 EXTRN	CPMSG7:WORD	   ;"Device %S not prepared",CR,LF,EOM
 EXTRN	CPMSGLST7DEV:WORD      ;FILLED IN BY "QUERY" ROUTINE WITH PTR TO DEVICE NAME

 EXTRN	CPMSG8:WORD	   ;"%s codepages:",CR,LF,EOM
;AC001; EXTRN  CPMSGLST8HD:WORD       ;OFFSET TO "HARDWARE" OR "PREPARED"
 EXTRN	CPMSG8_HW:WORD	       ;message number for "hardware ",EOM
 EXTRN	CPMSG8_PR:WORD	       ;message number for "prepared ",EOM

 EXTRN	CPMSG9:WORD	   ;"  Codepage %d",CR,LF,EOM
 EXTRN	CPMSGLST9CP:WORD       ;FILLED IN BY "QUERY" ROUTINE WITH CODEPAGE ID

 EXTRN	CPMSG10:WORD	   ;"MODE %S Codepage function completed",CR,LF,EOM
;AC001; EXTRN  CPMSGLST10FUN:WORD     ;FILLED IN TO POINT TO:
 EXTRN	CPMSGxx_QUERY:WORD     ;message number for "Query",EOM
 EXTRN	CPMSGxx_PREP:WORD      ;message number for "Prepare",EOM
 EXTRN	CPMSGxx_REFRESH:WORD   ;message number for "Refresh",EOM
 EXTRN	CPMSGxx_SELECT:WORD    ;message number for "Select",EOM

 EXTRN	CPMSG12:WORD	   ;"Current Codepage settings:",CR,LF,EOM

 EXTRN	CPMSG13:WORD	   ;"   %D - %S Codepage",CR,LF,EOM
 EXTRN	CPMSGLST13CP:WORD      ;FILLED IN WITH CODEPAGE ID
;AC001; EXTRN  CPMSGLST13TYP:WORD     ;FILLED IN TO POINT TO:
 EXTRN	CPMSG13_ACT:WORD       ;message number for "Active"
 EXTRN	CPMSG13_SYS:WORD       ;message number for "System"

 EXTRN	CPMSG14:WORD	   ;"  Codepage unprepared",CR,LF,EOM

 EXTRN	CPMSG15:WORD	   ;"Device not supported for Codepage",BEEP,CR,LF,EOM

 EXTRN	CPMSG16:WORD	   ;"No codepage has been selected",BEEP,CR,LF,EOM

 EXTRN	CPMSG17:WORD	   ;"Device error during %S",BEEP,CR,LF,EOM
 EXTRN	CPMSG17_WRIT:WORD      ;message number for "write of font file to device",EOM

 EXTRN	CPMSG18:WORD	   ;"Specified Codepage not prepared",BEEP,CR,LF,EOM

 EXTRN	CPMSG19:WORD	   ;"Current keyboard does not support this Codepage",BEEP,CR,LF,EOM

 EXTRN	CPMSG20:WORD	   ;"Error during read of font file",BEEP,CR,LF,EOM

 EXTRN	CPMSG21:WORD	   ;CR,LF,"Unable to perform REFRESH",BEEP,EOM

;THE FOLLOWING DATA AREAS DEFINING MESSAGES CAN BE FOUND IN "MODEMES.ASM"

;CPMSG1 	DB    "Failure to access Codepage Font File",BEEP,CR,LF,EOM
;CPMSG1     DW	  CPMSG1

;CPMSG2 	DB    "Failure to access device: %S",BEEP,CR,LF,EOM
;CPMSG2     DW	  CPMSG2
;CPMSGLST2DEV	DW    ? 	;FILLED IN WITH PTR TO DEVICE NAME

;CPMSG3 	DB	;"Missing from font file is either device or codepage",BEEP,CR,LF,EOM
;CPMSG3     DW	  CPMSG3

;CPMSG4 	DB    "Font file contents invalid",BEEP,CR,LF,EOM
;CPMSG4     DW	  CPMSG4

;CPMSG5 	DB    "Previous prepared codepage deleted",BEEP,CR,LF,EOM
;CPMSG5     DW	  CPMSG5

;CPMSG6 	DB    "Active codepage for device %S is %D",CR,LF,EOM
;CPMSG6     DW	  CPMSG6
;CPMSGLST6DEV	DW    ? 	;FILLED IN BY "QUERY" ROUTINE WITH PTR TO DEVICE NAME
;CPMSGLST6CP	DW    ? 	;FILLED IN BY "QUERY" ROUTINE WITH CODEPAGE ID

;CPMSG7 	DB    "Device %S not prepared",CR,LF,EOM
;CPMSG7     DW	  CPMSG7
;CPMSGLST7DEV	DW    ? 	;FILLED IN BY "QUERY" ROUTINE WITH PTR TO DEVICE NAME

;CPMSG8 	DB    "%S codepages:",CR,LF,EOM
;CPMSG8     DW	  CPMSG8
;CPMSGLST8HD	DW    ? 	;OFFSET TO "HARDWARE" OR "PREPARED"
;CPMSG8_HW	DB    "hardware",EOM
;CPMSG8_PR	DB    "prepared",EOM

;CPMSG9 	DB    "  Codepage %d",CR,LF,EOM
;CPMSG9     DW	  CPMSG9
;CPMSGLST9CP	DW    ? 	;FILLED IN BY "QUERY" ROUTINE WITH CODEPAGE ID

;CPMSG10	 DB    "MODE %S Codepage function completed",CR,LF,EOM
;CPMSG10     DW    CPMSG10
;CPMSGLST10FUN	 DW    ?	 ;FILLED IN TO POINT TO:
;CPMSG10_QUERY	 DB    "Querry",EOM
;CPMSG10_DES	 DB    "Prepare",EOM
;CPMSG10_SELECT  DB    "Activate",EOM
;CPMSG10_REFRESH DB    "Refresh",EOM
;CPMSG10_GLOBAL  DB    "Global",EOM

;CPMSG11	 DB    "Error %S Global Codepage",CR,LF,EOM
;CPMSG11     DW    CPMSG11
;CPMSGLST11FUN	 DW    ?	;FILLED IN TO POINT TO:
;CPMSG11_SET	 DB    "setting",EOM
;CPMSG11_GET	 DB    "getting",EOM

;CPMSG12	 DB    "Current Codepage settings:",CR,LF,EOM
;CPMSG12     DW    CPMSG12

;CPMSG13	 DB    "   %D - %S Codepage",CR,LF,EOM
;CPMSG13     DW    CPMSG13
;CPMSGLST13CP	 DW    ?	;FILLED IN WITH CODEPAGE ID
;CPMSGLST13TYP	 DW    ?	;FILLED IN TO POINT TO:
;CPMSG13_ACT	 DB    "Active",EOM
;CPMSG13_SYS	 DB    "System",EOM

;CPMSG14	 DB    "  Codepage unprepared",CR,LF,EOM
;CPMSG14     DW    CPMSG14

;CPMSG15	 DB    "Device not supported for Codepage",BEEP,CR,LF,EOM
;CPMSG15     DW    CPMSG15

;CPMSG16	 DB    "No codepage has been selected",BEEP,CR,LF,EOM
;CPMSG16     DW    CPMSG16

;CPMSG17	 DB	"Device error during %S",BEEP,CR,LF,EOM
;CPMSG17     DW     CPMSG17
;CPMSGLST17FUN	 DW	?	;FILLED IN TO POINT TO:
;CPMSG17_QUERY	 DB	"Query",EOM
;CPMSG17_PREP	 DB	"Prepare",EOM
;CPMSG17_REFRESH DB	"Refresh",EOM
;CPMSG17_ACT	 DB	"Activate",EOM

;CPMSG17_WRIT	 DB	"write of font file to device",EOM

;CPMSG18	 DB	"Specified Codepage not prepared",BEEP,CR,LF,EOM
;CPMSG18     DW     CPMSG18

;CPMSG19	 DB	"Current keyboard does not support this Codepage",BEEP,CR,LF,EOM
;CPMSG19     DW     CPMSG19

;CPMSG20	 DB	"Error during read of font file",BEEP,CR,LF,EOM
;CPMSG20     DW     CPMSG20

;CPMSG21	 DB	"Unable to perform REFRESH operation",BEEP,CR,LF,EOM
;CPMSG21     DW     CPMSG21
