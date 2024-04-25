PAGE    60,132
TITLE   INDEPAT - 80386 XMA Emulator - Patch area

COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEPAT                                                   *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corp.              *
*                                                                             *
* DESCRIPTIVE NAME: 80386 XMA Emulator patch area                             *
*                                                                             *
* STATUS (LEVEL)  : Version (0) Level (1.0)                                   *
*                                                                             *
* FUNCTION        : Declare a patch area for the 80386 XMA Emulator           *
*                                                                             *
* MODULE TYPE     : ASM                                                       *
*                                                                             *
* REGISTER USAGE  : N/A                                                       *
*                                                                             *
* RESTRICTIONS    : None                                                      *
*                                                                             *
* DEPENDENCIES    : None                                                      *
*                                                                             *
* ENTRY POINT     : None                                                      *
*                                                                             *
* LINKAGE         : None                                                      *
*                                                                             *
* INPUT PARMS     : None                                                      *
*                                                                             *
* RETURN PARMS    : None                                                      *
*                                                                             *
* OTHER EFFECTS   : None                                                      *
*                                                                             *
* EXIT NORMAL     : None                                                      *
*                                                                             *
* EXIT ERROR      : None                                                      *
*                                                                             *
* EXTERNAL                                                                    *
* REFERENCES      : None                                                      *
*                                                                             *
* SUB-ROUTINES    : None                                                      *
*                                                                             *
* MACROS          : None                                                      *
*                                                                             *
* CONTROL BLOCKS  : None                                                      *
*                                                                             *
* CHANGE ACTIVITY :                                                           *
*                                                                             *
* $MOD(INDEPAT) COMP(LOAD) PROD(3270PC) :                                     *
*                                                                             *
* $P0=P0000489 410 871002 D : NEW FOR WSP VERSION 1.1                         *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

SUBTTL     Patch Area
PAGE

PROG       SEGMENT PARA PUBLIC  'PROG'

           ASSUME  CS:PROG
           ASSUME  SS:NOTHING
           ASSUME  DS:PROG
           ASSUME  ES:NOTHING

           PUBLIC  INDEPAT

INDEPAT    LABEL   NEAR

           DB      512 DUP(0EEH)

PROG       ENDS
           END
