PAGE	60,132
TITLE	INDEMSG - 80386 XMA Emulator - Messages

COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*									      *
* MODULE NAME	  : INDEMSG						      *
*									      *
*		     5669-196 (C) COPYRIGHT 1988 Microsoft Corp.	      *
*									      *
* DESCRIPTIVE NAME: 80386 XMA Emulator messages -- U.S. 		      *
*									      *
* STATUS (LEVEL)  : Version (0) Level (1.10)				      *
*									      *
* FUNCTION	  : Declare the U.S. messages for the 80386 XMA Emulator      *
*									      *
* MODULE TYPE	  : ASM 						      *
*									      *
* REGISTER USAGE  : N/A 						      *
*									      *
* RESTRICTIONS	  : None						      *
*									      *
* DEPENDENCIES	  : None						      *
*									      *
* ENTRY POINT	  : None						      *
*									      *
* LINKAGE	  : The messages are made PUBLIC so that the initialization   *
*		    module, INDEINI, can access them.			      *
*									      *
* INPUT PARMS	  : None						      *
*									      *
* RETURN PARMS	  : None						      *
*									      *
* OTHER EFFECTS   : None						      *
*									      *
* EXIT NORMAL	  : None						      *
*									      *
* EXIT ERROR	  : None						      *
*									      *
* EXTERNAL								      *
* REFERENCES	  : None						      *
*									      *
* SUB-ROUTINES	  : None						      *
*									      *
* MACROS	  : None						      *
*									      *
* CONTROL BLOCKS  : None						      *
*									      *
* CHANGE ACTIVITY :							      *
*									      *
* $MOD(INDEMSG) COMP(LOAD) PROD(3270PC) :				      *
*									      *
* $D0=D0004700 410 870629 D : NEW FOR RELEASE 1.1			      *
* $P1=P0000311 410 870805 D : RENAME MODULE TO INDEMSUS 		      *
* $P2=P0000489 410 871002 D : RENAME MODULE TO INDEMSG. DECLARE MESSAGES HERE.*
* $P3=P0000649 411 880125 D : NEW VERSION OF THE EMULATOR		      *
* $P4=P0000741 411 880203 D : UPDATE COPYRIGHT				      *
* $D1=D0008700 120 880206 D : SUPPORT DOS 4.00 IOCTL CALL		      *
*									      *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

SUBTTL	   Messages							;   D0A
PAGE									;   D0A
									;   D0A
PROG	   SEGMENT PARA PUBLIC	'PROG'                                  ;   D0A
									;   D0A
	   ASSUME  CS:PROG						;   D0A
	   ASSUME  SS:NOTHING						;   D0A
	   ASSUME  DS:PROG						;   D0A
	   ASSUME  ES:NOTHING						;   D0A
									;   D0A
INDEMSG    LABEL   NEAR 						;   D0A
									;   D0A
;---------------------------------------------------------------------------P2A;
; Declare messages that the emulator will display on the screen.  These     P2A;
; messages are declared with line lengths of 80 bytes to allow for World    P2A;
; Trade translation.  The messages are made public so that other modules    P2A;
; can access them.							    P2A;
; Note that the messages are declared 80 bytes long to facilitate world trade translation.	       P2A;
;---------------------------------------------------------------------------P2A;
									;   P2A
	   PUBLIC  WELCOME						;   P2A
	   PUBLIC  GOODLOAD						;   P2A
	   PUBLIC  NO_80386						;   P2A
	   PUBLIC  WAS_INST						;   P2A
	   Public  Small_Parm							;an000; dms;
	   Public  No_Mem							;an000; dms;
									;   P2A
CR	   EQU	   13	     ; ASCII for a carriage return		;  @P2A
LF	   EQU	   10	     ; ASCII for a line feed			;  @P2A
									;   P2A
INCLUDE    xmaem.cl1

PROG	   ENDS 							;   D0A
	   END								;   D0A
