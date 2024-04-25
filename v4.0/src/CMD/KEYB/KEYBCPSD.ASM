	PAGE	,132
	TITLE	DOS - KEYB Command  -  Copy Shared_Data_Area

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - KEYB Command
;; (C) Copyright 1988 Microsoft
;;
;; File Name:  KEYBCPSD.ASM
;; ----------
;;
;; Description:
;; ------------
;;	 Copies the SHARED_DATA_AREA into a part of memory that
;;	 can be left resident. All relative pointers must already
;;	 be recalculated to this new position.
;;	 THIS FILE MUST BE THE LAST OF THE RESIDENT FILES WHEN KEYB IS LINKED.
;;
;; Documentation Reference:
;; ------------------------
;;	 PC DOS 3.3 Detailed Design Document - May ?? 1986
;;
;; Procedures Contained in This File:
;; ----------------------------------
;;
;; Include Files Required:
;; -----------------------
;;	INCLUDE KEYBSHAR.INC
;;	INCLUDE KEYBCMD.INC
;;	INCLUDE KEYBTBBL.INC
;;
;; External Procedure References:
;; ------------------------------
;;	 FROM FILE  ????????.ASM:
;;	      procedure - description????????????????????????????????
;;
;; Linkage Information:  Refer to file KEYB.ASM
;; --------------------
;;
;; Change History:
;; ---------------
;; PTMP3955 ;AN004;KEYB component to free environment and close handles 0 - 4
;; 3/24/88
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
	PUBLIC	SD_DEST_PTR	       ;;
	PUBLIC	COPY_SD_AREA	       ;;
	PUBLIC	SHARED_DATA	       ;;
				       ;;
	INCLUDE STRUC.INC
	INCLUDE KEYBSHAR.INC	       ;;
	INCLUDE KEYBCMD.INC	       ;;
	INCLUDE KEYBTBBL.INC	       ;;
				       ;;
CODE	SEGMENT PUBLIC 'CODE'          ;;
				       ;;
	ASSUME	CS:CODE,DS:CODE        ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Module: COPY_SD_AREA
;;
;; Description:
;;
;; Input Registers:
;;
;; Output Registers:
;;     N/A
;;
;; Logic:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
SD		EQU   SHARED_DATA      ;;
TSD		EQU  TEMP_SHARED_DATA  ;;
				       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					       ;;
COPY_SD_AREA	PROC   NEAR		       ;;
					       ;;
	REP	MOVS ES:BYTE PTR [DI],DS:[SI]  ;; Copy SHARED_DATA_AREA to

		  push	  ax			  ;AN004;save existing values
		  push	  es			  ;AN004;;
		  xor	  ax,ax 		  ;AN004;clear out ax
		  mov	  ax,cs:[2ch]		  ;AN004;check offset for address containin environ.
		  cmp	  ax,0			  ;AN004;
		  je	  NO_FREEDOM		  ;AN004;
		  mov	  es,ax 		  ;AN004;
		  mov	  ax,4900H		  ;AN004;make the free allocate mem func
		  int	  21h			  ;AN004;;


NO_FREEDOM:
		  pop	  es			  ;AN004;restore existing values
		  pop	  ax			  ;AN004;;

		  push	  ax			  ;AN004;
		  push	  bx			  ;AN004;

						  ;AN004;     ;Terminate and stay resident
	     mov     bx,4			  ;AN004;     ;1st close file handles
	 .REPEAT				  ;AN004;     ;STDIN,STDOUT,STDERR
	     mov  ah,3eh			  ;AN004;     ;
	     int  21h				  ;AN004;     ;
	     dec  bx				  ;AN004;     ;
	.UNTIL <BX eq 0>			  ;AN004;     ;

		 pop	 bx			  ;AN004;
		 pop	 ax			  ;AN004;
						  ;AN004;	 new part of memory
	MOV	BYTE PTR ES:SD.TABLE_OK,1	  ;; Activate processing flag
	INT	21H				  ;; Exit
					       ;;
					       ;;
COPY_SD_AREA	ENDP			       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
 db 'SHARED DATA'                      ;;
SD_DEST_PTR	LABEL	BYTE	       ;;
				       ;;
SHARED_DATA   SHARED_DATA_STR <>       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CODE   ENDS
       END
