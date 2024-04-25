COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEMSUS                                                  *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corp.              *
*                                                                             *
* DESCRIPTIVE NAME: 80386 XMA Emulator messages -- U.S.                       *
*                                                                             *
* STATUS (LEVEL)  : Version (0) Level (1.0)                                   *
*                                                                             *
* FUNCTION        : Include file for U.S. messages for the 80386 XMA Emulator.*
*                   The messages are made PUBLIC so that the initialization   *
*                   module, INDEINI, can access them.                         *
*                                                                             *
* MODULE TYPE     : INC                                                       *
*                                                                             *
* MACROS          : None                                                      *
*                                                                             *
* CONTROL BLOCKS  : None                                                      *
*                                                                             *
* CHANGE ACTIVITY :                                                           *
*                                                                             *
* $MAC(INDEMSUS) COMP(LOAD) PROD(3270PC) :                                    *
*                                                                             *
* $D0=D0004700 410 870722 D : NEW FOR RELEASE 1.1                             *
* $P1=P0000311 410 870804 D : RENAME MODULE'S LIBRARY FILE TYPE TO "INC"      *
* $P2=P0036900 110 870826 D : CHG MSG NO. INDXE003                            *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

;---------------------------------------------------------------------------D0A;
; Declare messages that the emulator will display on the screen.  These     D0A;
; messages are declared with line lengths of 80 bytes to allow for World    D0A;
; Trade translation.  The messages are made public so that other modules    D0A;
; can access them.                                                          D0A;
; Note that the messages are declared 80 bytes long to facilitate world trade translation.             D0A;
;---------------------------------------------------------------------------D0A;
                                                                        ;   D0A
           PUBLIC  WELCOME                                              ;   D0A
           PUBLIC  GOODLOAD                                             ;   D0A
           PUBLIC  NO_80386                                             ;   D0A
           PUBLIC  WAS_INST                                             ;   D0A
                                                                        ;   D0A
CR         EQU     13        ; ASCII for a carriage return              ;  @D0A
LF         EQU     10        ; ASCII for a line feed                    ;  @D0A
                                                                        ;   D0A
WELCOME    DB   "INDXE001 80386 XMA Emulator Version 1.00                                        " ;  @D0A
	   DB   "         (C) Copyright 1988 Microsoft Corporation All rights reserved           " ;  @D0A
           DB   CR,LF,"$"                                               ;  @D0A
                                                                        ;   D0A
GOODLOAD   DB   "INDXE002 80386 XMA Emulator installed                                           " ;  @D0A
           DB   CR,LF,"$"                                               ;  @D0A
                                                                        ;   D0A
NO_80386   DB   "INDXE003 80386 XMA Emulator not installed. This system unit                     " ;  @D0A
           DB   "         is not supported. The 80386 XMA Emulator requires                      " ;  @D0A
           DB   "         an IBM Personal System/2 Model 80.                                     " ;  @D0A
           DB   CR,LF,"$"                                               ;  @D0A
                                                                        ;   D0A
WAS_INST   DB   "INDXE004 80386 XMA Emulator not installed.                                      " ;  @D0A
           DB   "         Protected mode already in use.                                         " ;  @D0A
           DB   CR,LF,"$"                                               ;  @D0A
                                                                        ;   D0A
