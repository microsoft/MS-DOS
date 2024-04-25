PAGE    60,132
TITLE   INDEMAUS - 386 XMA Emulator - Messages

COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEMAUS                                                  *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corp.              *
*                                                                             *
* DESCRIPTIVE NAME: 80386 XMA Emulator messages -- U.S.                       *
*                                                                             *
* STATUS (LEVEL)  : Version (0) Level (1.0)                                   *
*                                                                             *
* FUNCTION        : Declare the U.S. messages for the 80386 XMA Emulator      *
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
* LINKAGE         : The messages are made PUBLIC so that the initialization   *
*                   module, INDEINI, can access them.                         *
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
* $MOD(INDEMAUS) COMP(LOAD) PROD(3270PC) :                                    *
*                                                                             *
* $D0=D0004700 410 870629 D : NEW FOR RELEASE 1.1                             *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

SUBTTL     Messages                                                     ;   D0A
PAGE                                                                    ;   D0A
                                                                        ;   D0A
PROG       SEGMENT PARA PUBLIC  'PROG'                                  ;   D0A
                                                                        ;   D0A
           ASSUME  CS:PROG                                              ;   D0A
           ASSUME  SS:NOTHING                                           ;   D0A
           ASSUME  DS:PROG                                              ;   D0A
           ASSUME  ES:NOTHING                                           ;   D0A
                                                                        ;   D0A
INDEMAUS   LABEL   NEAR                                                 ;   D0A
                                                                        ;   D0A
           INCLUDE INDEMSUS.INC         ; Use the US messages               D0A
                                                                        ;   D0A
PROG       ENDS                                                         ;   D0A
           END                                                          ;   D0A
