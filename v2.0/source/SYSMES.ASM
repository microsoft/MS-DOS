   TITLE Message file for MS-DOS SYS Program

FALSE   EQU     0
TRUE    EQU     NOT FALSE

        INCLUDE DOSSYM.ASM

Message MACRO   label,text
        PUBLIC  label,label&Len
label       DB  text
label&Len   DW  $-label
ENDM


IBMJAPVER EQU   FALSE

CONST   SEGMENT PUBLIC BYTE

; only this message must be terminated with a $
        PUBLIC  BadVer
BADVER  DB      "Incorrect DOS version",13,10,"$"

        IF      IBMJAPVER
        Message BadDisk,<"Destination disk cannot be booted">
        ENDIF

        Message BadDrv,<"Invalid drive specification">
        Message BadParm,<"Invalid parameter">
        Message NoDest,<"No room for system on destination disk">
        Message BadSiz,<"Incompatible system size">
        Message Done,<"System transferred">

        PUBLIC  GetSys,SysDrv,GetSysLen
GETSYS      DB      "Insert system disk in drive "
SYSDRV      DB      "A",13,10
            DB      "and strike any key when ready",13,10
GetSysLen   DW  GetSysLen-GetSys

CONST   ENDS

DATA    SEGMENT BYTE PUBLIC
DATA    ENDS

CODE    SEGMENT
DG      GROUP   CODE,CONST,DATA
        ASSUME  CS:DG,DS:DG,ES:DG,SS:DG

CODE    ENDS
        END

