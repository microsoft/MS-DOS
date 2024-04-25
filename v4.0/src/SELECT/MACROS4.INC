;;****************************************************************************
;;     Assembler MACROS for use with SELECT.
;;     File: MACROS4.INC
;;     Latest Change Date: July 16, 1987
;;
;; These macros define powerful assembler verbs neccessary for SELECT.
;;
;; Note: Many of the macros make use of an ASCII-N string for passing
;;	 parameters.  The string is defined below.
;;		   DW  count
;;		   DB  "string_variable",?
;;
;;	 COUNT is the length of the string and is a word.
;;	 It is necessary to follow the string with at least one byte for the
;;	 purpose of changing the ASCII-N string to an ASCII-Z string.
;;
;;****************************************************************************
page					;;AN000;
;;****************************************************************************
;;
;;   GET_DATE: Get the current system date.
;;
;;   SYNTAX:  GET_DATE	var_year, var_month, var_day
;;
;;   INPUT:   NONE
;;
;;   OUTPUT:  CY = 0: CURRENT SYSTEM DATE IS 1/1/80
;;	      CY = 1: CURRENT SYSTEM DATE IS NOT 1/1/80
;;		      VAR_YEAR	- SYSTEM YEAR	      (16 BITS)
;;		      VAR_MONTH - SYSTEM MONTH	     (16 BITS)
;;		      VAR_DAY	- SYSTEM DAY	     (16 BITS)
;;
;;   OPERATION:  DOS function call 2Ah is performed to get the current
;;		 system date.  If the system date is not 1/1/80, the
;;		 carry flag is set.
;;
;;****************************************************************************
GET_DATE	MACRO	VAR_YEAR, VAR_MONTH, VAR_DAY ;;AN000;

	MOV	AH,2AH			;;AN000; get time dos interrupt
	DOSCALL 			;;AN000;
	MOV	VAR_YEAR, CX		;;AN000; Save the date.
	MOV	CH,0			;;AN000; Clear the byte
	MOV	CL,DH			;;AN000;
	MOV	VAR_MONTH, CX		;;AN000;
	MOV	CL,DL			;;AN000;
	MOV	VAR_DAY, CX		;;AN000;
	.IF < VAR_YEAR EQ 1980 > AND	;;AN000; See if it is the base year.
	.IF < DX EQ 0101H>		;;AN000; i.e. 1/1/80
	   CLC				;;AN000; Yes it is.
	.ELSE				;;AN000;
	   STC				;;AN000;
	.ENDIF				;;AN000;

	ENDM				;;AN000;
;;****************************************************************************
;;
;;   GET_TIME: Get current system time.
;;
;;   SYNTAX:  GET_TIME	var_hour, var_minutes, var_seconds
;;
;;   INPUT:   None.
;;
;;   OUTPUT:  VAR_HOUR	  - SYSTEM HOUR 	 (16 BITS)
;;	      VAR_MINUTES - SYSTEM MINUTES	 (16 BITS)
;;	      VAR_SECONDS - SYSTEM SECONDS	 (16 BITS)
;;
;;   OPERATION:  DOS function call 2Ch is performed to get the current
;;	 system time.
;;
;;
;;****************************************************************************
GET_TIME   MACRO	VAR_HOUR, VAR_MINUTES, VAR_SECONDS ;;AN000;


	MOV	AH,2CH			;;AN000; get time dos interrupt
	DOSCALL 			;;AN000;

	MOV	AH, 0			;;AN000;
	MOV	AL, CH			;;AN000;
	MOV	VAR_HOUR, AX		;;AN000;
	MOV	AL, CL			;;AN000;
	MOV	VAR_MINUTES, AX 	;;AN000;
	MOV	AL, DH			;;AN000;
	MOV	VAR_SECONDS, AX 	;;AN000;


	ENDM				;;AN000;
;;************************************************************************;;
;;   SET_DATE: Sets the system date
;;
;;   SYNTAX:  SET_DATE	var_year, var_month, var_day
;;
;;   INPUT:   var_year	- 1980 - 2099		 ( 16 bits )
;;	      var_month - 1 - 12		 ( 16 bits )
;;	      var_day	- 1 - 31		 ( 16 bits )
;;
;;   OUTPUT:  CY = 0: SUCCESSFUL
;;	      CY = 1: ERROR - Date is not valid
;;
;;   OPERATION:  DOS function call 2Bh is performed to set the system date.
;;	 If the date is not valid, the carry flag is set.
;;
;;************************************************************;;
SET_DATE   MACRO	VAR_YEAR, VAR_MONTH, VAR_DAY ;;AN000;
	MOV	CX, VAR_YEAR		;;AN000;
	MOV	AX, VAR_MONTH		;;AN000;
	MOV	DH, AL			;;AN000;
	MOV	AX, VAR_DAY		;;AN000;
	MOV	DL, AL			;;AN000;
	MOV	AH,2BH			;;AN000; set date dos interrupt
	DOSCALL 			;;AN000;
	.IF < ZERO AL > 		;;AN000;
	   CLC				;;AN000;
	.ELSE				;;AN000;
	   STC				;;AN000;
	.ENDIF				;;AN000;
	ENDM				;;AN000;
;;****************************************************************************
;;
;;   SET_TIME: Sets the current system time.
;;
;;   SYNTAX:  SET_TIME	var_hour, var_minutes, var_seconds
;;
;;   INPUT:   var_hour	  = 0 - 23		 ( 16 BITS )
;;	      var_minutes = 0 - 59		 ( 16 BITS )
;;	      var_seconds = 0 - 59		 ( 16 BITS )
;;	      hundredth   = Assumed to be zero
;;
;;   OUTPUT:  CY = 0: SUCCESSFUL
;;	      CY = 1: Error - Date is not valid
;;
;;   OPERATION:  DOS function call 2Dh is performed to set the current system
;;		 time.	If the time is not valid, the carry flag will be set.
;;
;;****************************************************************************
SET_TIME   MACRO	VAR_HOUR, VAR_MINUTES, VAR_SECONDS ;;AN000;

	MOV	AX, VAR_HOUR		;;AN000;
	MOV	CH, AL			;;AN000;
	MOV	AX, VAR_MINUTES 	;;AN000;
	MOV	CL, AL			;;AN000;
	MOV	AX, VAR_SECONDS 	;;AN000;
	MOV	DH, AL			;;AN000;
	MOV	DL, 0			;;AN000; Hundredths of seconds is 0
	MOV	AH,2DH			;;AN000; set time dos interrupt
	DOSCALL 			;;AN000;
	.IF < ZERO AL > 		;;AN000;
	   CLC				;;AN000;
	.ELSE				;;AN000;
	   STC				;;AN000;
	.ENDIF				;;AN000;
	ENDM				;;AN000;
;;****************************************************************************
;;
;;   CHECK_TIME_CHANGE: Check if user entered time is different from the
;;		 specified system time.
;;
;;   SYNTAX:  CHECK_TIME_CHANGE: var_u_hour, var_u_min, var_u_sec,
;;				 var_s_hour, var_s_min, var_s_sec
;;
;;   INPUT:   var_u_hour = User specified hour		 ( 16 bits )
;;	      var_u_min  = User specified minutes	 ( 16 bits )
;;	      var_u_sec  = User specified seconds	 ( 16 bits )
;;	      var_s_hour = System hour			 ( 16 bits )
;;	      var_s_min  = System min			 ( 16 bits )
;;	      var_s_sec  = System sec			 ( 16 bits )
;;
;;   OUTPUT:  CY = 0: User specified time is the same as the system time.
;;	      CY = 1: User specified time is different from the system time.
;;
;;   OPERATION:  The user time and system time are compared and the carry
;;		 flag is updated as specified above.
;;
;;************************************************************************;;
CHECK_TIME_CHANGE	MACRO	VAR_U_HOUR, VAR_U_MIN, VAR_U_SEC, VAR_S_HOUR, VAR_S_MIN, VAR_S_SEC ;;AN000;
	 LOCAL	   EXIT_CHECK_TIME_CHANGE ;;AN000;
	 MOV  AX, VAR_S_HOUR		;;AN000;
	.IF < VAR_U_HOUR EQ AX >	;;AN000;
	      MOV  AX, VAR_S_MIN	;;AN000;
	     .IF < VAR_U_MIN  EQ AX >	;;AN000;
		   MOV	AX, VAR_S_SEC	;;AN000;
		  .IF < VAR_U_SEC  EQ AX > ;;AN000;
		       CLC		;;AN000;
		       JMP   EXIT_CHECK_TIME_CHANGE;AN000;
		   .ENDIF		;;AN000;
	      .ENDIF			;;AN000;
	 .ENDIF 			;;AN000;
	 STC				;;AN000;
EXIT_CHECK_TIME_CHANGE: 		;;AN000;
	ENDM					;;AN000;
;;****************************************************************************
;;
;;   CHECK_DATE_CHANGE: Check if user entered date is different from the
;;		 specified system date.
;;
;;   SYNTAX:  CHECK_DATE_CHANGE: var_u_year, var_u_month, var_u_day,
;;				 var_s_year, var_s_month, var_s_day
;;
;;   INPUT:   var_u_year   = User specified year	   ( 16 bits )
;;	      var_u_month  = User specified month	   ( 16 bits )
;;	      var_u_day    = User specified day 	   ( 16 bits )
;;	      var_s_year   = System year		   ( 16 bits )
;;	      var_s_month  = System month		   ( 16 bits )
;;	      var_s_day    = System day 		   ( 16 bits )
;;
;;   OUTPUT:  CY = 0: User specified date is the same as the system date.
;;	      CY = 1: User specified date is different from the system date.
;;
;;   OPERATION:  The user date and system date are compared and the carry
;;		 flag is updated as specified above.
;;
;;************************************************************************;;
CHECK_DATE_CHANGE	MACRO	VAR_U_YEAR, VAR_U_MONTH, VAR_U_DAY, VAR_S_YEAR, VAR_S_MONTH, VAR_S_DAY ;;AN000;
	 LOCAL	   EXIT_CHECK_DATE_CHANGE	;;AN000;
	 MOV  AX, VAR_S_YEAR			;;AN000;
	.IF < VAR_U_YEAR  EQ AX >		;;AN000;
	      MOV  AX, VAR_S_MONTH		;;AN000;
	      .IF < VAR_U_MONTH EQ AX > 	;;AN000;
		   MOV	AX, VAR_S_DAY		;;AN000;
		   .IF < VAR_U_DAY   EQ AX >	;;AN000;
		       CLC			;;AN000;
		       JMP   EXIT_CHECK_DATE_CHANGE ;;AN000;
		   .ENDIF			;;AN000;
	      .ENDIF				;;AN000;
	 .ENDIF 				;;AN000;
	STC					;;AN000;
EXIT_CHECK_DATE_CHANGE: 			;;AN000;
	ENDM					;;AN000;
;;****************************************************************************
;;
;;   SET_FILE_DATE_TIME:  Set a files date and time.
;;
;;   SYNTAX:  SET_FILE_DATE_TIME  file_handle, var_hour, var_minutes, var_seconds
;;				  var_year, var_month, var_day
;;
;;   INPUT:
;;	 file_handle = The handle of the file to set the time/date of.
;;	 var_hour    = 0 - 23			 ( 16 bits )
;;	 var_minutes = 0 - 59			 ( 16 bits )
;;	 var_seconds = 0 - 59			 ( 16 bits )
;;	 var_year    = 1980 - 2099		 ( 16 bits )
;;	 var_month   = 1 - 12			 ( 16 bits )
;;	 var_day     = 1 - 31			 ( 16 bits )
;;
;;   OUTPUTS:
;;	 CY = 0: Success
;;	 CY = 1: Error - Date/Time format is invalid
;;
;;   OPERATION:  The data and time values are converted to internal formats
;;	 defined below and DOS function call 57h is performed to set the
;;	 files date and time.
;;
;;
;;	 The internal time format is:
;;		 bits	 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
;;			 h  h  h  h  h	m  m  m  m  m  m  x  x	x  x  x
;;
;;		 h - Binary number of hours   ( 0 - 23 )
;;		 m - Binary number of minutes ( 0 - 59 )
;;		 x - Binary number of two second increments
;;
;;	 The internal date format is:
;;		 bits	 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
;;			 y  y  y  y  y	y  y  m  m  m  m  d  d	d  d  d
;;
;;		 y - 0 - 119 ( 1980 - 2099 )
;;		 m - 1 - 31
;;		 d - 1 - 31
;;
;;****************************************************************************
SET_FILE_DATE_TIME	MACRO	FILE_HANDLE, VAR_HOUR, VAR_MINUTES, VAR_SECONDS, VAR_YEAR, VAR_MONTH, VAR_DAY ;;AN000;
    CALL HOOK_INT_24				;;AN000;
	;;
	;; Handle the file's time first
	;;
	MOV	BX, VAR_SECONDS 	;;AN000; Get the number of seconds
	SHR	BX, 1			;;AN000; Need the number of 2 seconds
	MOV	AX, VAR_MINUTES 	;;AN000; Get the number of minutes
	MOV	CL, 5			;;AN000;
	SHL	AX, CL			;;AN000; Least significant bit #5
	OR	BX, AX			;;AN000;
	MOV	AX, VAR_HOUR		;;AN000; Get the number of hours
	XCHG	AH, AL			;;AN000;
	MOV	CL, 3			;;AN000;
	SHL	AX, CL			;;AN000; Put hours at bit #11
	OR	BX, AX			;;AN000;
	;;
	;; Handle the file's date now
	;;
	MOV	DX, VAR_DAY		;;AN000; Get the day.
	MOV	AX, VAR_MONTH		;;AN000;
	MOV	CL, 5			;;AN000;
	SHL	AX, CL			;;AN000; Least significant month bit #5
	OR	DX, AX			;;AN000;
	MOV	AX, VAR_YEAR		;;AN000; Get the year (1980 - 2099)
	SUB	AX, 1980		;;AN000; Put in the range 0 - 119
	XCHG	AL, AH			;;AN000;
	SHL	AX, 1			;;AN000;
	OR	DX, AX			;;AN000;

	MOV	CX, BX			;;AN000;
	MOV	BX, FILE_HANDLE 	;;AN000;
	MOV	AX, 5701H		;;AN000;
	DOSCALL 			;;AN000;
	CALL  RESTORE_INT_24		;;AN000;

	ENDM				;;AN000;
;;************************************************************************;;
;;
;;   CHECK_CLOCK:  Check if the real time clock is operating.
;;
;;   SYNTAX:  CHECK_CLOCK
;;
;;   INPUT:
;;	 None.
;;
;;   OUTPUT:
;;	 CY = 0: Real time clock is operating
;;	 CY = 1: Real time clock is not operating
;;
;;   OPERATION:  A call to the real time clock services (INT 1Ah, AH = 02h)
;;	 is performed to get the real time clock.  If the clock is operating,
;;	 the time is returned in the registers and CF = 0 is returned. If the
;;	 clock is not operating, CF = 1 is returned.
;;
;;	 Since the older machines may not have the clock services interrupt,
;;	 the registers are set to zero before the call is made and checked for
;;	 non-zero on return.
;;
;;****************************************************************************
CHECK_CLOCK	MACRO		;;AN000;
	MOV	CX, 0		;;AN000; Zero the registers for later comparison
	MOV	DX, 0		;;AN000;
	MOV	AH, 02		;;AN000;
	INT	1AH		;;AN000; Time of day service routine
	.IF < ZERO CX > AND	;;AN000; If CX and DH are zero, clock is not there.
	.IF < ZERO DH > 	;;AN000;
	   STC			;;AN000;
	.ELSE			;;AN000;
	   CLC			;;AN000; The clock is there!
	.ENDIF			;;AN000;

	ENDM			;;AN000;
INCLUDE  MACROS5.INC		;;AN000;
