	PAGE	90,132			;A2
	TITLE	GRTABHAN - INTERRUPT HANDLER FOR INT 2FH, GRAFTABL LOADED
;****************** START OF SPECIFICATIONS *****************************
; MODULE NAME: GRTABHAN.SAL

; DESCRIPTIVE NAME: For GRAFTABL, this is the Multiplexor Interrupt Handler

;FUNCTION: This module contains the Interrupt Handler that will be hooked
;	    into the INT 2FH vector.  When invoked with AL=0, it responds
;	    that GRAFTABL is loaded by changing AL to contain hex FF.  If
;	    option AL=1 specified, it puts into the vector at DS:[BX] the
;	    pointer to the previously loaded table.

; NOTES:
;	 This module should be processed with the SALUT preprocessor:

;		SALUT GRTABHAN

;	 To assemble these modules, the alphabetical or sequential
;	 ordering of segments may be used.

;	 For LINK instructions, refer to the PROLOG of the main module,
;	 GRTAB.SAL.  This module, containing a resident interrupt handler,
;	 should be first in the list of .OBJ to be linked.

;	 At the time this handler code is made resident, the loader, GRTAB,
;	 made certain instruction modifications.  PATCH_OFF and PATCH_SEG
;	 are the immediate word fields of two move word immediate to
;	 storage type of instructions.	The loaded Revised these to
;	 contain the offset and the segid respectively of where the
;	 resident font table would be that is to stay resident.

;	 Also at load time, GRTAB made another instruction modification by
;	 changing the JUMP DUMMY instruction's DWORD immediate field to
;	 contain the vector pointing to the previous owner of the
;	 Multiplexor Interrupt Vector.

; ENTRY POINT: There are two entry points: one, from DOS at 100H, is
;	    END_PSP.  The jump instruction there has nothing to do with
;	    the interrupt handler, but merely jumps to the GRTAB module to
;	    what is effectively the real DOS entry point, ENTRY_POINT.

;	    The other is where the interrupt vector will be set to point,
;	    the entry point to the interrupt handler code:  HANDLER.

;	    For the rest of this module description, the HANDLER entry
;	    point conditions are being described.

; INPUT: AH = Multiplexor Number.  I do nothing if this is not my own.
;	      The value of the Multiplexor Number is defined in the EQU:
;	      MY_MULTIPLEXOR_NUMBER as being the value, B0H.
;	 AL = Function Request.  There are two functions recognized:
;		    0 = "GET INSTALLED STATE"
;		    1 = "WHERE ARE YOU?"
;			 and DS:BX points to vector to receive pointer
;			 to the previously installed GRAFTABL table.
;		    If Function request is not '1', it is assumed to be '0'.

; EXIT-NORMAL: If the proper multiplexor number is presented, respond with
;	       AH = 0FFH, otherwise, pass control to previous owner
;	       of this interrupt.

; EXIT-ERROR: None

; INTERNAL REFERENCES:
;    ROUTINES: none

;    DATA AREAS:
;	   PUBLIC symbols:
;	 PREV_OWN      Far jump direct to previous owner of interrupt 2FH.
;	 PATCH_OFF     Offset portion of vector pointing to loaded char cable.
;	 PATCH_SEG     Segment portion of vector pointing to loaded char table.
;	 HANDLER       Entry point pointed to by the vector at interrupt 2FH.
;	 HANDLER_SIZE  Location of the end of the resident code portion of the
;		   interrupt 2FH handler, including the 60H bytes left of
;		   the PSP, so this offset is relative to the start of the PSP
;		   after the code has been relocated downward into the PSP.
;	 MPEXNUM       The byte containing the value defined
;		   as being the id checked for when INT 2FH is called used
;		   to identify this GRAFTABL member of the multiplexor chain.
;

; EXTERNAL REFERENCES:
;    ROUTINES: none

;    DATA AREAS: none

;****************** END OF SPECIFICATIONS *****************************
	IF1
	    %OUT    COMPONENT=GRAFTABL, MODULE=GRTABHAN.SAL...
	ENDIF
;		    $SALUT (4,21,25,41)
		    HEADER <MACRO DEFINITIONS, STRUC DEFINITIONS, EQUATES>
		    INCLUDE PATHMAC.INC ;AN006;
HEADER		    MACRO TEXT
.XLIST
		    SUBTTL TEXT
.LIST
		    PAGE
		    ENDM
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
VECTOR		    STRUC
VECOFF		    DW	?		;OFFSET PORTION OF VECTOR POINTER
VECSEG		    DW	?		;SEGMENT PORTION OF VECTOR POINTER
VECTOR		    ENDS
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
;		DEFINITION OF FUNCTIONS TO BE REQUESTED OF INT 2FH
GET_INST_STATE	    EQU 0		;FUNCTION = "GET INSTALLED STATE"
WHERE_R_U	    EQU 1		;FUNCTION = "WHERE ARE YOU?"
					; REQUESTS VECTOR OF LOADED TABLE BE
					; PUT IN VECTOR POINTED TO BY DS:[BX]
RES_FUNC	    EQU 0F8H		;RESERVED FUNCTIONS IN RANGE OF F8 TO FF, IGNORE

;		OTHER EQUATES
PATCHED 	    EQU 0		;DUMMY VALUE, TO BE REPLACED AT EXECUTION TIME
INSTALLED	    EQU 0FFH		;RESPONSE, INDICATES THIS HANDLER IS INSTALLED
MY_MULTIPLEX_NUMBER EQU 0B0H		;THE UNIQUE IDENTIFICATION NUMBER ASSIGNED
					; TO "GRAFTABL" FOR INT 2FH
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
DUMMY_SEG	    SEGMENT AT 0
DUMMY		    LABEL FAR		;NOTHING HERE REALLY, ONLY
					; USED TO MAKE MASM GENERATE A FAR CALL DIRECT
					; THE ABSOLUTE VECTOR IN THAT INS WILL BE PATCHED

DUMMY_SEG	    ENDS
; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
		    HEADER <DOS ENTRY POINT>
CSEG		    SEGMENT PARA PUBLIC
;THIS SEGMENT IS ALIGNED ON PARA SINCE IT IS THE START OF THE LOAD MODULE,
; WHICH IS ON A PARA BOUNDARY ANYWAY.  THIS MODULE IS PADDED AT THE END
; TO A MULTIPLE OF 16 BYTES, SO THE NEXT SEGMENT WILL ALSO START
; ON A PARA BOUNDARY, WHICH WILL BE THE US CHARACTER SET TABLE.

		    ASSUME CS:CSEG

		    EXTRN ENTRY_POINT:NEAR

		    ORG 60H
		    PUBLIC MOV_DEST
MOV_DEST	    LABEL BYTE		;WHERE THIS INTERRUPT HANDLER
					; WILL BE MOVED TO, FOLLOWED BY THE 1K TABLE.
		    ORG 100H
		    PUBLIC END_PSP	;BEGINNING HERE, THIS WILL BE MOVED TO "MOV_DEST"
END_PSP 	    EQU $		;ENTRY POINT FROM DOS
		    JMP ENTRY_POINT	;INIT THE INT HANDLER, SET UP CHAR TABLES
					; THIS JUMP TARGET IS DEFINED
					;  IN THE GRTAB.SAL MODULE
;		AREAS TO BE PATCHED WITHIN THIS MODULE

		    PUBLIC PREV_OWN	;PATCH IS IN JMP INSTR TO PREVIOUS OWNER
;THE ABOVE PATCH IS FIXED BY THE GRTAB.SAL MODULE, JUST BEFORE ALTERING THE 2FH VECTOR

		    PUBLIC PATCH_OFF	;OFFSET PORTION OF VECTOR POINTING TO LOADED CHAR TABLE
		    PUBLIC PATCH_SEG	;SEGMENT PORTION OF VECTOR POINTING TO LOADED CHAR TABLE
;THE ABOVE TWO PATCHES ARE FIXED BY THE GRTAB.SAL MODULE, AT THE VERY BEGINNING.

;THIS NEXT ONE BYTE FIELD SHOULD BE KEPT AS THE BYTE JUST PREVIOUS TO THE
;INTERRUPT HANDLER ENTRY POINT AT "HANDLER".
		    PUBLIC MPEXNUM
MPEXNUM 	    DB	MY_MULTIPLEX_NUMBER ;PATCHING THIS ONE BYTE WILL CHANGE FOR ALL THE VALUE
		    HEADER <MULTIPLEXOR INTERRUPT HANDLER>
;CONDITIONS OF REGS AT ENTRY TO HANDLER:
;INPUT: AH = MULTIPLEXOR NUMBER.  I DO NOTHING IF THIS IS NOT MY OWN.
;	AL = FUNCTION REQUEST.	THERE ARE TWO FUNCTIONS RECOGNIZED:
;		   0 = "GET INSTALLED STATE"
;		   1 = "WHERE ARE YOU?"
;			AND DS:BX POINTS TO VECTOR TO RECEIVE POINTER
;			TO THE PREVIOUSLY INSTALLED GRAFTABL TABLE.
;		   IF FUNCTION REQUEST IS NOT '1', IT IS ASSUMED TO BE '0'.

		    PUBLIC HANDLER
HANDLER 	    PROC FAR		;INTERRUPT HANDLER ENTRY POINT
; $SALUT (4,3,9,41)
  PATHLABL GRTABHAN			;AN006;
  CMP	AH,MPEXNUM			;IS THIS MULTIPLEXOR REQUEST IS FOR ME?
; $IF	E				;IF MY MULTIPLEX NUMBER IS CALLED
  JNE $$IF1
      CMP   AL,RES_FUNC 		;IF IN RANGE F8-FF, DO NOTHING, JUST RETURN
;     $IF   B
      JNB $$IF2
	  CMP	AL,WHERE_R_U		;IF REQUEST FOR "WHERE ARE YOU?"
;	  $IF	E
	  JNE $$IF3
					;FOR THIS REQUEST, DS:BX POINTS TO A VECTOR
					; WHICH IS TO RECEIVE THE POINTER TO
					; WHERE THE ORIGINAL TABLE WAS LOADED

					;PASS OFFSET OF WHERE TABLE IS
	      MOV   [BX].VECOFF,PATCHED ; TO FIRST WORD OF RESPONSE AREA
PATCH_OFF     EQU   WORD PTR $-2	;THE ACTUAL VALUE OF THE IMMEDIATE IS PATCHED IN

					;PASS SEGID OF WHERE TABLE IS
	      MOV   [BX].VECSEG,PATCHED ; TO SECOND WORD OF RESPONSE AREA
PATCH_SEG     EQU   WORD PTR $-2	;THE ACTUAL VALUE OF THE IMMEDIATE IS PATCHED IN
;	  $ENDIF
$$IF3:
	  MOV	AL,INSTALLED		;SAY "INSTALLED"
;     $ENDIF
$$IF2:
      IRET				;RETURN TO INTERRUPT INVOKER
; $ENDIF
$$IF1:
;SINCE THE MULTIPLEX NUMBER IS FOR SOMEBODY ELSE, PASS THE CALL ON TO PREVIOUS OWNER
JMPREV: 				;REFERENCED WHEN PATCHING OUT "DUMMY"
  JMP	DUMMY				;CHAIN ON TO THE PREVIOUS OWNER
					; OF THE VECTOR AT 1FH*4.
					; USAGE OF "DUMMY" HERE IS JUST A PLACE-HLDER
					; WHICH WILL BE REPLACED DURING EXECUTION OF LOADER
  PATHLABL GRTABHAN			;AN006;
;=================================================================
  HEADER <POINTERS TO PREVIOUS OWNER, INSTRUCTION MODIFICATION>
;	     $SALUT (4,14,20,41)
PREV_OWN     EQU   DWORD PTR JMPREV+1	;REFERENCED DURING REPLACEMENT OF "HANDLER"
					; IN THE ABOVE JMP INSTRUCTION
HANDLER      ENDP
	     IF    ($-CSEG) MOD 16	;IF NOT ALREADY ON 16 BYTE BOUNDARY
		 ORG   ($-CSEG)+16-(($-CSEG) MOD 16) ;ADD PADDING TO GET TO 16 BYTE BOUNDARY
	     ENDIF
HANDLER_SIZE EQU   ($-CSEG)-(END_PSP-CSEG) ;MARK THE END OF RESIDENT EXECUTABLE ;AN000;
	     PUBLIC HANDLER_SIZE	; PORTION, NOT INCLUDING THE PSP	;AN000;
CSEG	     ENDS
	     END   END_PSP
