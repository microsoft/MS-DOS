;***************************************************************
;
;       86-DOS FORMAT DISK UTILITY
;
;       This routine formats a new disk,clears the FAT and DIRECTORY
;       then optionally copies the SYSTEM and COMMAND.COM to this
;       new disk
;
;       SYNTAX: FORMAT  [drive][/switch1][/switch2]...[/switch16]
;
;       Regardless of the drive designator , the user will be
;       prompted to insert the diskette to be formatted.
;
;***************************************************************

;Mod to ask for volume ID ARR 5/12/82
; 05/19/82 Fixed rounding bug in CLUSCAL:       ARR
;REV 1.5
;               Added rev number message
;               Added dir attribute to DELALL FCB
;REV 2.00
;               Redone for 2.0
;REV 2.10
;               5/1/83 ARR Re-do to transfer system on small memory systems

FALSE   EQU     0
TRUE    EQU     NOT FALSE

IBMJAPVER EQU   FALSE           ; SET ONLY ONE SWITCH TO TRUE!
IBMVER  EQU     FALSE
MSVER   EQU     TRUE

KANJI   EQU     FALSE

        .xlist
        INCLUDE DOSSYM.ASM
        .list


;FORMAT Pre-defined switches
SYSSW   EQU     1               ; System transfer
VOLSW   EQU     2               ; Volume ID prompt
OLDSW   EQU     4               ; E5 dir terminator


DRNUM   EQU     5CH

RECLEN  EQU     fcb_RECSIZ+7
RR      EQU     fcb_RR+7

;Per system file data structure

FILESTRUC       STRUC
FILE_HANDLE     DW      ?               ; Source handle
FILE_SIZEP      DW      ?               ; File size in para
FILE_SIZEB      DD      ?               ; File size in bytes
FILE_OFFSET     DD      ?               ; Offset in file (partial)
FILE_START      DW      ?               ; Para number of start in buffer
FILE_DATE       DW      ?               ; Date of file
FILE_TIME       DW      ?               ; Time of file
FILE_NAME       DB      ?               ; Start of name
FILESTRUC       ENDS

CODE    SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CODE,DS:CODE,ES:CODE

        ORG     100H

;For OEM module
        PUBLIC          SWITCHMAP,DRIVE
        EXTRN           HARDFLAG:BYTE          ;0 = REMOVABLE MEDIA
        EXTRN           SWITCHLIST:BYTE,FATID:BYTE,FATSPACE:WORD
        EXTRN           STARTSECTOR:WORD,FREESPACE:WORD,INIT:NEAR
        EXTRN           DISKFORMAT:NEAR,BADSECTOR:NEAR,DONE:NEAR
        EXTRN           WRTFAT:NEAR

;For FORMES module
        EXTRN   WAITYN:NEAR,REPORT:NEAR
        PUBLIC  PRINT,CRLF,DISP32BITS,UNSCALE,FDSKSIZ,SECSIZ,CLUSSIZ
        PUBLIC  SYSSIZ,BADSIZ

START:
        JMP     SHORT FSTRT

HEADER  DB      "Vers 2.10"

FSTRT:
        MOV     SP,OFFSET STACK         ;Use internal stack

;Code to print header
;       PUSH    AX
;       MOV     DX,OFFSET HEADER
;       CALL    PRINT
;       POP     AX

DOSVER_HIGH     EQU  020BH   ;2.11 in hex
        PUSH    AX              ;Save DRIVE validity info
        MOV     AH,GET_VERSION
        INT     21H
        XCHG    AH,AL           ;Turn it around to AH.AL
        CMP     AX,DOSVER_HIGH
        JAE     OKDOS
GOTBADDOS:
        MOV     DX,OFFSET BADVER
        MOV     AH,STD_CON_STRING_OUTPUT
        INT     21H
        INT     20H

OKDOS:

        IF      IBMVER                  ; IBM WANTS TO CHECK FOR ASSIGN.COM
        XOR     AX,AX
        MOV     ES,AX
        MOV     BX,ES:[4*21H]
        MOV     ES,ES:[4*21H+2]
        CMP     BX,122H
        JNZ     NO_ASSIGN
        CMP     ES:[109H],0807H
        JNZ     NO_ASSIGN
        CMP     ES:[103H],0201H
        JNZ     RE_ASSIGN
        CMP     ES:[105H],0403H
        JNZ     RE_ASSIGN
        CMP     ES:[107H],0605H
        JZ      NO_ASSIGN
RE_ASSIGN:
        MOV     DX,OFFSET ASGERR
        CALL    PRINT
        JMP     FEXIT2
NO_ASSIGN:
        PUSH    CS
        POP     ES
        ENDIF

        POP     AX

        CMP     AL,0FFH                 ;See if invalid drive specified
        JNZ     DRVGD                   ;If not proceed
        MOV     DX,OFFSET INVDRV        ;Invalid drive message
        CALL    PRINT                   ;Print the message
        JMP     FEXIT2                  ;Exit
DRVGD:
        MOV     AH,GET_DEFAULT_DRIVE    ;Must get the default drive
        INT     21H                     ;Default now in AL
        MOV     DEFALT,AL               ;Save for later
        ADD     AL,"A"
        MOV     [BIODRV],AL
        MOV     [DOSDRV],AL
        MOV     [SYSDRV],AL
        MOV     [COMDRV],AL
        MOV     SI,DRNUM                ;So we can get our parameters
        LODSB                           ;Fetch drive designation
        OR      AL,AL                   ;See if specified
        JNZ     DRVSPEC                 ;If specfied proceed
        MOV     AL,DEFALT
        INC     AL
DRVSPEC:
        DEC     AL                      ;Drive designator now correct
        MOV     BYTE PTR DS:[DRNUM],AL  ;And updated
        MOV     DRIVE,AL                ;Save copy
        MOV     DX,OFFSET INT_23
        MOV     AH,SET_INTERRUPT_VECTOR
        MOV     AL,23H
        INT     21H                     ;Set ^C vector
        ;Get all the swith information from the command line
        XOR     AX,AX
        MOV     AH,CHAR_OPER            ;GET SWITCH CHARACTER
        INT     21H                     ;CALL THE DOS
        MOV     [SWTCH],DL

        XOR     BX,BX                   ;Store switch information in BX
        MOV     SI,81H                  ;Point to the command line buffer
NXTSWT:
        CALL    SCANOFF
        LODSB
        CMP     AL,[SWTCH]
        JZ      GETPARM
        CMP     AL,13
        JZ      SAVSWT
        LODSB                           ;Get next character
        CMP     AL,":"                  ;Is it a drive specifier?
        JNZ     INVALID                 ;No -- invalid parameter
        CMP     BYTE PTR DBLFLG,0       ;Is is the only drive specifier we've seen
        JNZ     INVALID                 ;No -- invalid parameter
        INC     BYTE PTR DBLFLG         ;Yes -- set the flag
        JMP     SHORT NXTSWT
GETPARM:
        LODSB
        ;Convert any lower case input into upper case
        CMP     AL,41H
        JL      GETCHR                  ;Switch is a digit don't try to convert it
        AND     AL,0DFH
GETCHR:
        MOV     CL,SWITCHLIST           ;Number of legal switches
        OR      CL,CL                   ;If it's none we shouldn't be here
        JZ      INVALID                 ;Report the error
        MOV     CH,0
        MOV     DI,1+OFFSET SWITCHLIST  ;Point to the legal switch characters
        REPNE   SCASB
        JNZ     INVALID
        MOV     AX,1
        SHL     AX,CL
        OR      BX,AX                   ;Set the appropriate bit in SWITCHMAP
        JMP     SHORT NXTSWT            ;See if there are anymore

INVALID:
        MOV     DX,OFFSET INVPAR
        CALL    PRINT
        JMP     FEXIT

SCANOFF:
        LODSB
        CMP     AL,20H
        JZ      SCANOFF
        CMP     AL,9
        JZ      SCANOFF
        DEC     SI
        RET

MEMERR:
        MOV     DX,OFFSET MEMEX
        CALL    PRINT
        JMP     FEXIT


SAVSWT:

        IF      IBMVER                  ;/B SWITCH TURNS /8 ON AND /S OFF
        TEST    BX,00100000B
        JZ      NOT_SW_B
        AND     BX,NOT SYSSW            ;TURN OFF /S
        OR      BX,00010000B            ;TURN ON  /8
NOT_SW_B:
        ENDIF

        MOV     SWITCHMAP,BX
        TEST    SWITCHMAP,SYSSW
        JZ      INITCALL
        CALL    SAVUDIRS
        MOV     BX,[FREESPACE]
        ADD     BX,15
        MOV     CL,4
        SHR     BX,CL
        PUSH    CS
        POP     ES
        MOV     AH,SETBLOCK
        INT     21H
        MOV     BX,0FFFFH
        MOV     AH,ALLOC
        INT     21H
        OR      BX,BX
        JZ      MEMERR                  ;No memory
        MOV     [MSIZE],BX
        MOV     AH,ALLOC
        INT     21H
        JC      MEMERR                  ;No memory
        MOV     [MSTART],AX
        MOV     DX,OFFSET SWTCH
        MOV     AH,CHDIR
        INT     21H                     ;Go to root on default drive (source)

RDFRST:
        CALL    READDOS                 ;Read BIOS and DOS
        JNC     INITCALL                ;OK -- read next file
NEEDSYS:
        CALL    SYSPRM                  ;Prompt for system disk
        JMP     RDFRST                  ;Try again

INITCALL:
        CALL    INIT                    ;Let OEM read any files before disk is changed
        JNC     SWITCHCHK
        MOV     DX,OFFSET FRMTERR
        CALL    PRINT
        JMP     FEXIT

SWITCHCHK:
        MOV     DX,SWITCHMAP
        MOV     SWITCHCOPY,DX

SYSLOOP:
        MOV     WORD PTR BADSIZ,0       ;Must intialize for each iteration
        MOV     WORD PTR BADSIZ+2,0
        MOV     WORD PTR SYSSIZ,0
        MOV     WORD PTR SYSSIZ+2,0
        MOV     BYTE PTR DBLFLG,0
        MOV     BYTE PTR CLEARFLG,0
        MOV     DX,SWITCHCOPY
        MOV     SWITCHMAP,DX            ;Restore original Switches
        MOV     AL,DRIVE                ;Fetch drive
        ADD     AL,"A"                  ;(AL)= ASCII designation
        MOV     BYTE PTR SNGDRV,AL      ;Fill out the message
        MOV     BYTE PTR TARGDRV,AL
        MOV     BYTE PTR HRDDRV,AL
        CALL    DSKPRM                  ;Prompt for new disk
        CALL    DISKFORMAT              ;Format the disk
        JNC     GETTRK
FRMTPROB:
        MOV     DX,OFFSET FRMTERR
        CALL    PRINT
        JMP     SHORT SYSLOOP

        ;Mark any bad sectors in the FATs
        ;And keep track of how many bytes there are in bad sectors

GETTRK:
        CALL    BADSECTOR               ;Do bad track fix-up
        JC      FRMTPROB                ;Had an error in Formatting - can't recover
        CMP     AX,0                    ;Are we finished?
        JNZ     TRKFND                  ;No - check error conditions
        JMP     DRTFAT                  ;Yes
TRKFND:
        CMP     BX,STARTSECTOR          ;Are any sectors in the system area bad?
        JGE     CLRTEST
        MOV     DX,OFFSET NOUSE         ;Can't build FATs of Directory
        CALL    PRINT
        JMP     FRMTPROB                ;Bad disk -- try again
CLRTEST:
        MOV     SECTORS,AX              ;Save the number of sectors on the track
        CMP     BYTE PTR CLEARFLG,0     ;Have we already cleared the FAT and DIR?
        JNZ     SYSTEST                 ;Yes - all set
        INC     CLEARFLG                ;Set the flag
        PUSH    BX
        CALL    CLEAR                   ;Fix-up fat and directory
        POP     BX
SYSTEST:
        TEST    SWITCHMAP,SYSSW         ;If system requested calculate size
        JZ      BAD100
        CMP     BYTE PTR DBLFLG,0       ;Have we already calculated System space?
        JNZ     CMPTRKS                 ;Yes -- all ready for the compare
        INC     BYTE PTR DBLFLG         ;No -- set the flag
        CALL    GETSIZE                 ;Calculate the system size
        MOV     DX,WORD PTR SYSSIZ+2
        MOV     AX,WORD PTR SYSSIZ
        DIV     SECSIZ
        ADD     AX,STARTSECTOR
        MOV     SYSTRKS,AX              ;Space FAT,Dir,and system files require
CMPTRKS:
        CMP     BX,SYSTRKS
        JG      BAD100
        MOV     DX,OFFSET NOTSYS        ;Can't transfer a system
        CALL    PRINT
        AND     SWITCHMAP,NOT SYSSW     ;Turn off system transfer switch
        MOV     WORD PTR SYSSIZ+2,0     ;No system to transfer
        MOV     WORD PTR SYSSIZ,0       ;No system to transfer
BAD100:
; BX is the first bad sector #, SECTORS is the number of bad sectors starting
; at BX. This needs to be converted to clusters. The start sector number may
; need to be rounded down to a cluster boundry, the end sector may need to be
; rounded up to a cluster boundry. Know BX >= STARTSECTOR
        SUB     BX,STARTSECTOR          ; BX is now DATA area relative
        MOV     CX,BX
        ADD     CX,SECTORS
        DEC     CX                      ; CX is now the last bad sector #
        MOV     AX,BX
        XOR     DX,DX
        DIV     CLUSSIZ
        MOV     BX,AX                   ; BX is rounded down and converted
                                        ; to a cluster #. Where cluster 0 =
                                        ; first cluster of data. First bad
                                        ; Sector is in cluster BX.
        MOV     AX,CX
        XOR     DX,DX
        DIV     CLUSSIZ
        MOV     CX,AX                   ; CX is rounded up and converted to a
                                        ; to a cluster #. Where cluster 0 =
                                        ; first cluster of data. Last bad
                                        ; Sector is in cluster CX.
        SUB     CX,BX
        INC     CX                      ; CX is number of clusters to mark bad
        ADD     BX,2                    ; Bias start by correct amount since
                                        ; first cluster of data is really
                                        ; cluster 2.
        MOV     AX,CLUSSIZ              ; Sectors/Cluster
        MUL     SECSIZ                  ; Times Bytes/Sector
        MOV     BP,AX                   ; = Bytes/Cluster

; Mark CX clusters bad starting at cluster BX
PACKIT:
        MOV     DX,0FF7H                ;0FF7H indicates a bad sector
        CALL    PACK                    ;Put it in the allocation map
        CMP     DX,DI                   ;Have we already marked it bad?
        JZ      BAD150                  ;if so, don't add it in
        ADD     WORD PTR BADSIZ,BP      ;Add in number of bad bytes
        JNB     BAD150
        INC     WORD PTR BADSIZ+2
BAD150:
        INC     BX                      ;Next cluster
        LOOP    PACKIT                  ;Continue for # of clusters
        JMP     GETTRK

; Inputs:
        ;BX = Cluster number
        ;DX = Data
; Outputs:
        ;The data is stored in the FAT at the given cluster.
        ;SI is destroyed
        ;DI contains the former contents
        ;No other registers affected
PACK:
        PUSH    BX
        PUSH    CX
        PUSH    DX
        MOV     SI,BX
        SHR     BX,1
        ADD     BX,FATSPACE
        ADD     BX,SI
        SHR     SI,1
        MOV     SI,WORD PTR [BX]
        MOV     DI,SI
        JNB     ALIGNED
        MOV     CL,4
        SHL     DX,CL
        SHR     DI,CL
        AND     SI,15
        JMP     SHORT PACKIN

ALIGNED:
        AND     SI,0F000H
PACKIN:
        AND     DI,00FFFH               ;DI CONTAINS FORMER CONTENTS
        OR      SI,DX
        MOV     WORD PTR[BX],SI
        POP     DX
        POP     CX
        POP     BX
        RET

DRTFAT:
        CMP     BYTE PTR CLEARFLG,0
        JNZ     CLEARED
        CALL    CLEAR                   ;Clear the FAT and Dir
        TEST    SWITCHMAP,SYSSW         ;If system requested, calculate size
        JZ      CLEARED
        CMP     BYTE PTR DBLFLG,0       ;Have we already calculated System space?
        JNZ     CLEARED                 ;Yes
        INC     BYTE PTR DBLFLG         ;No -- set the flag
        CALL    GETSIZE                 ;Calculate the system size
CLEARED:
        CALL    WRTFAT
        JNC     FATWRT
        MOV     DX,OFFSET NOUSE
        CALL    PRINT
        JMP     FRMTPROB

FATWRT:

        TEST    SWITCHMAP,SYSSW         ;System desired
        JZ      STATUS
        CALL    WRITEDOS                ;Write the BIOS & DOS
        JNC     SYSOK
        MOV     DX,OFFSET NOTSYS        ;Can't transfer a system
        CALL    PRINT
        MOV     WORD PTR SYSSIZ+2,0     ;No system transfered
        MOV     WORD PTR SYSSIZ,0       ;No system transfered
        JMP     SHORT STATUS

SYSOK:
        MOV     DX,OFFSET SYSTRAN
        CALL    PRINT
STATUS:
        CALL    CRLF
        CALL    VOLID
        MOV     AH,DISK_RESET
        INT     21H
        CALL    DONE                    ;Final call to OEM module
        JNC     REPORTC
        JMP     FRMTPROB                ;Report an error

REPORTC:
        CALL    REPORT

        CALL    MORE                    ;See if more disks to format
        JMP     SYSLOOP                 ;If we returned from MORE then continue

DISP32BITS:
        PUSH    BX
        XOR     AX,AX
        MOV     BX,AX
        MOV     BP,AX
        MOV     CX,32
CONVLP:
        SHL     SI,1
        RCL     DI,1
        XCHG    AX,BP
        CALL    CONVWRD
        XCHG    AX,BP
        XCHG    AX,BX
        CALL    CONVWRD
        XCHG    AX,BX
        ADC     AL,0
        LOOP    CONVLP
        ; Conversion complete. Print 8-digit number with 2 leading blanks.
        MOV     CX,1810H
        XCHG    DX,AX
        CALL    DIGIT
        XCHG    AX,BX
        CALL    OUTWORD
        XCHG    AX,BP
        CALL    OUTWORD
        POP     DX
        CMP     DX,0
        JZ      RET3
        CALL    PRINT
RET3:   RET

OUTWORD:
        PUSH    AX
        MOV     DL,AH
        CALL    OUTBYTE
        POP     DX
OUTBYTE:
        MOV     DH,DL
        SHR     DL,1
        SHR     DL,1
        SHR     DL,1
        SHR     DL,1
        CALL    DIGIT
        MOV     DL,DH
DIGIT:
        AND     DL,0FH
        JZ      BLANKZER
        MOV     CL,0
BLANKZER:
        DEC     CH
        AND     CL,CH
        OR      DL,30H
        SUB     DL,CL
        MOV     AH,STD_CON_OUTPUT
        INT     21H
        RET

CONVWRD:
        ADC     AL,AL
        DAA
        XCHG    AL,AH
        ADC     AL,AL
        DAA
        XCHG    AL,AH
RET2:   RET

UNSCALE:
        SHR     CX,1
        JC      RET2
        SHL     AX,1
        RCL     DX,1
        JMP     SHORT UNSCALE


;******************************************
; Calculate the size in bytes of the system rounded up to sector and
;   cluster boundries, Answer in SYSSIZ

GETSIZE:
        MOV     AX,WORD PTR BIOSSIZB              ;And calculate the system size
        MOV     DX,WORD PTR BIOSSIZB+2
        CALL    FNDSIZ
        MOV     AX,WORD PTR DOSSIZB
        MOV     DX,WORD PTR DOSSIZB+2
        CALL    FNDSIZ
        MOV     AX,WORD PTR COMSIZB
        MOV     DX,WORD PTR COMSIZB+2

;Calculate the number of sectors used for the system
FNDSIZ:
        DIV     SECSIZ
        OR      DX,DX
        JZ      FNDSIZ0
        INC     AX                      ; Round up to next sector
FNDSIZ0:
        PUSH    AX
        XOR     DX,DX
        DIV     CLUSSIZ
        POP     AX
        OR      DX,DX
        JZ      ONCLUS
        SUB     DX,CLUSSIZ
        NEG     DX
        ADD     AX,DX                   ; Round up sector count to cluster
                                        ;       boundry
ONCLUS:
        MUL     SECSIZ                  ; Turn it back into bytes
        ADD     WORD PTR SYSSIZ,AX
        ADC     WORD PTR SYSSIZ+2,DX
        RET

PRINT:  MOV     AH,STD_CON_STRING_OUTPUT             ;Print msg pointed to by DX
        INT     21H
        RET

MORE:   CMP     BYTE PTR [HARDFLAG],0   ;Check if removable media
        JNZ     FEXIT
        CALL    WAITYN                  ;Get yes or no response
        JB      FEXIT                   ;Exit if CF=1
        CALL    CRLF
CRLF:
        MOV     DX,OFFSET CRLFMSG
        CALL    PRINT
        RET

PERROR: CALL    PRINT                   ;Print message and exit
FEXIT:
        CALL    RESTUDIR                ;Restore users dirs
FEXIT2:
        INT     20H

        ;Prompt the user for a system diskette in the default drive
SYSPRM:
        MOV     AH,GET_DEFAULT_DRIVE    ;Will find out the default drive
        INT     21H                     ;Default now in AL
  IF IBMVER OR IBMJAPVER
        MOV     BX,AX
  ENDIF
        ADD     AL,41H                  ;Now in Ascii
        MOV     SYSDRV,AL               ;Text now ok

  IF IBMVER OR IBMJAPVER
        INT     11H                     ;Make sure drive has insertable media
        AND     AL,11000000B
        ROL     AL,1
        ROL     AL,1
        OR      AL,AL
        JNZ     NOTONEDRV
        INC     AL
NOTONEDRV:
        CMP     BL,AL
        JBE     ISFLOPPY
        MOV     AL,"A"
        MOV     BYTE PTR [SYSDRV],AL
        MOV     [BIODRV],AL
        MOV     [DOSDRV],AL
        MOV     [COMDRV],AL
ISFLOPPY:
  ENDIF

        MOV     DX,OFFSET SYSMSG
        CALL    PRINT                   ;Print first line
        CALL    WAITKY                  ;Wait for a key
        CALL    CRLF
        RET

TARGPRM:
        MOV     DX,OFFSET TARGMSG
        CALL    PRINT                   ;Print first line
        CALL    WAITKY                  ;Wait for a key
        CALL    CRLF
        RET

DSKPRM:
        MOV     DX,OFFSET SNGMSG        ;Point to the message
        CMP     BYTE PTR [HARDFLAG],0   ;Check if removable media
        JZ      GOPRNIT
        MOV     DX,OFFSET HRDMSG
GOPRNIT:
        CALL    PRINT                   ;Print the message
        CALL    WAITKY                  ;Wait for space bar
        CALL    CRLF
        CALL    CRLF
        RET

        ;Will wait for any key to be depressed.
WAITKY:
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8) OR STD_CON_INPUT_NO_ECHO
        INT     21H
        MOV     AX,(STD_CON_INPUT_FLUSH SHL 8) + 0
        INT     21H

        return

FDPB:   MOV     DL,DRIVE
        INC     DL
        MOV     AH,GET_DPB
        PUSH    DS
        INT     21H
        INC     AL
        JZ      DRVERR
        MOV     DX,WORD PTR [BX+13]
        DEC     DX
        MOV     AL,BYTE PTR [BX+4]
        INC     AL
        MOV     CX,WORD PTR [BX+2]
        POP     DS
        RET
DRVERR:
        POP     DS
        MOV     DX,OFFSET INVDRV
        JMP     PERROR

        ;Clear the FAT and directory and set Dirty byte in the FAT
CLEAR:
        MOV     AL,FATID
        OR      AL,0F8H                 ;Make sure it's a legal value
        MOV     AH,0FFH
        MOV     DI,FATSPACE
        MOV     WORD PTR[DI],AX
        MOV     BYTE PTR[DI+2],AH
        MOV     AH,DISK_RESET
        INT     21H
        CALL    WRTFAT

        IF      IBMJAPVER
        PUSH    DS
        MOV     DL,[DRIVE]                      ;GET THE DRIVE PARAMETER
        INC     DL
        MOV     AH,32H
        INT     21H

        MOV     DPB_FIRST_ACCESS[BX],-1         ;FORCE MEDIA CHANGE
        POP     DS
        ENDIF

        CALL    FDPB
        MOV     WORD PTR FDSKSIZ,DX
        MOV     SECSIZ,CX
        MOV     AH,0
        MOV     CLUSSIZ,AX
        SHR     DX,1
        JNC     ROUNDED
        INC     DX
ROUNDED:
        ADD     DX,WORD PTR FDSKSIZ
        XOR     AX,AX
        MOV     CX,DX
        MOV     DI,FATSPACE
        ADD     DI,3
        REP     STOSB
        MOV     AH,DISK_RESET
        INT     21H
        CALL    WRTFAT
        MOV     DL,[DRIVE]
        ADD     DL,'A'
        MOV     [ROOTSTR],DL
        MOV     DX,OFFSET ROOTSTR
        MOV     AH,CHDIR
        INT     21H                     ;Go to root on target drive
        MOV     AL,DRIVE
        INC     AL
        MOV     ALLDRV,AL
        MOV     AH,FCB_DELETE
        MOV     DX,OFFSET ALLFILE
        INT     21H

        TEST    SWITCHMAP,OLDSW         ;See if E5 terminated DIR requested
        JZ      RET25
        MOV     AL,DRIVE
        INC     AL
        MOV     BYTE PTR CLEANFILE,AL              ;Get the drive
        MOV     DX,OFFSET CLEANFILE
        MOV     AH,FCB_CREATE
MAKE_NEXT:
        INT     21H
        OR      AL,AL
        JNZ     DELETE_THEM
        INC     BYTE PTR CLNNAM
        CMP     BYTE PTR CLNNAM,"Z" + 1
        JNZ     MAKE_NEXT
        MOV     BYTE PTR CLNNAM,"A"
        INC     BYTE PTR CLNNAM + 1
        CMP     BYTE PTR CLNNAM + 1,"Z" + 1
        JNZ     MAKE_NEXT
        MOV     BYTE PTR CLNNAM + 1,"A"
        INC     BYTE PTR CLNNAM + 2
        JMP     MAKE_NEXT

DELETE_THEM:
        MOV     WORD PTR CLNNAM,"??"
        MOV     BYTE PTR CLNNAM + 2,"?"
        MOV     AH,FCB_DELETE
        INT     21H
RET25:
        RET                             ;And return


;*****************************************
; Process V switch if set

VOLID:
        TEST    [SWITCHMAP],VOLSW
        JNZ     DOVOL
VRET:   CLC
        RET

DOVOL:
        PUSH    CX
        PUSH    SI
        PUSH    DI
        PUSH    ES
        PUSH    DS
        POP     ES
VOL_LOOP:
        MOV     AL,DRIVE
        INC     AL
        MOV     DS:BYTE PTR[VOLFCB+7],AL
        MOV     DX,OFFSET LABPRMT
        CALL    PRINT
        MOV     DX,OFFSET INBUFF
        MOV     AH,STD_CON_STRING_INPUT
        INT     21H
        MOV     DX,OFFSET CRLFMSG
        CALL    PRINT
        MOV     DX,OFFSET CRLFMSG
        CALL    PRINT
        MOV     CL,[INBUFF+1]
        OR      CL,CL
        JZ      VOLRET
        XOR     CH,CH
        MOV     SI,OFFSET INBUFF+2
        MOV     DI,SI
        ADD     DI,CX
        MOV     CX,11
        MOV     AL,' '
        REP     STOSB
        MOV     CX,5
        MOV     DI,OFFSET VOLNAM
        REP     MOVSW
        MOVSB
        MOV     DX,OFFSET VOLFCB
        MOV     AH,FCB_CREATE
        INT     21H
        OR      AL,AL
        JZ      GOOD_CREATE
        MOV     DX,OFFSET INVCHR        ;PRINT INVALID CHARS MESSAGE
        CALL    PRINT
        JMP     VOL_LOOP
GOOD_CREATE:
        MOV     DX,OFFSET VOLFCB
        MOV     AH,FCB_CLOSE
        INT     21H
        CALL    CRLF
VOLRET:
        POP     ES
        POP     DI
        POP     SI
        POP     CX
        RET

;****************************************
;Copy IO.SYS, MSDOS.SYS and COMMAND.COM into data area.
; Carry set if problems

READDOS:
        CALL    TESTSYSDISK
        JNC     RDFILS
        RET

RDFILS:
        MOV     BYTE PTR [FILSTAT],0
        MOV     BX,[BIOSHandle]
        MOV     AX,[MSTART]
        MOV     DX,AX
        ADD     DX,[MSIZE]              ; CX first bad para
        MOV     [BIOSSTRT],AX
        MOV     CX,[BIOSSIZP]
        ADD     AX,CX
        CMP     AX,DX
        JBE     GOTBIOS
        MOV     BYTE PTR [FILSTAT],00000001B     ; Got part of BIOS
        MOV     SI,[MSIZE]
        XOR     DI,DI
        CALL    DISIX4
        MOV     DS,[BIOSSTRT]
ASSUME  DS:NOTHING
        CALL    READFILE
ASSUME  DS:CODE
        JC      CLSALL
        XOR     DX,DX
        MOV     CX,DX
        MOV     AX,(LSEEK SHL 8) OR 1
        INT     21H
        MOV     WORD PTR [BIOSOFFS],AX
        MOV     WORD PTR [BIOSOFFS+2],DX
FILESDONE:
        CLC
CLSALL:
        PUSHF
        CALL    COMCLS
        POPF
        RET

GOTBIOS:
        MOV     BYTE PTR [FILSTAT],00000010B     ; Got all of BIOS
        LES     SI,[BIOSSIZB]
        MOV     DI,ES
        MOV     DS,[BIOSSTRT]
ASSUME  DS:NOTHING
        CALL    READFILE
ASSUME  DS:CODE
        JC      CLSALL
        MOV     BX,[DOSHandle]
        MOV     [DOSSTRT],AX
        CMP     AX,DX                   ; No room left?
        JZ      CLSALL                  ; Yes
        MOV     CX,[DOSSIZP]
        ADD     AX,CX
        CMP     AX,DX
        JBE     GOTDOS
        OR      BYTE PTR [FILSTAT],00000100B     ; Got part of DOS
        SUB     DX,[DOSSTRT]
        MOV     SI,DX
        XOR     DI,DI
        CALL    DISIX4
        MOV     DS,[DOSSTRT]
ASSUME  DS:NOTHING
        CALL    READFILE
ASSUME  DS:CODE
        JC      CLSALL
        XOR     DX,DX
        MOV     CX,DX
        MOV     AX,(LSEEK SHL 8) OR 1
        INT     21H
        MOV     WORD PTR [DOSOFFS],AX
        MOV     WORD PTR [DOSOFFS+2],DX
        JMP     FILESDONE

GOTDOS:
        OR      BYTE PTR [FILSTAT],00001000B     ; Got all of DOS
        LES     SI,[DOSSIZB]
        MOV     DI,ES
        MOV     DS,[DOSSTRT]
ASSUME  DS:NOTHING
        CALL    READFILE
ASSUME  DS:CODE
CLSALLJ: JC     CLSALL
        MOV     BX,[COMHandle]
        MOV     [COMSTRT],AX
        CMP     AX,DX                   ; No room left?
        JZ      CLSALL                  ; Yes
        MOV     CX,[COMSIZP]
        ADD     AX,CX
        CMP     AX,DX
        JBE     GOTCOM
        OR      BYTE PTR [FILSTAT],00010000B     ; Got part of COMMAND
        SUB     DX,[COMSTRT]
        MOV     SI,DX
        XOR     DI,DI
        CALL    DISIX4
        MOV     DS,[COMSTRT]
ASSUME  DS:NOTHING
        CALL    READFILE
ASSUME  DS:CODE
        JC      CLSALLJ
        XOR     DX,DX
        MOV     CX,DX
        MOV     AX,(LSEEK SHL 8) OR 1
        INT     21H
        MOV     WORD PTR [COMOFFS],AX
        MOV     WORD PTR [COMOFFS+2],DX
        JMP     FILESDONE

GOTCOM:
        OR      BYTE PTR [FILSTAT],00100000B     ; Got all of COMMAND
        LES     SI,[COMSIZB]
        MOV     DI,ES
        MOV     DS,[COMSTRT]
ASSUME  DS:NOTHING
        CALL    READFILE
ASSUME  DS:CODE
        JMP     CLSALL

;**************************************************
;Write BIOS DOS COMMAND to the newly formatted disk.

WRITEDOS:
        MOV     CX,BIOSATT
        MOV     DX,OFFSET BIOSFIL
        LES     SI,[BIOSSIZB]
        MOV     DI,ES
        CALL    MAKEFIL
        JNC     GOTNBIO
RET34:  RET

GOTNBIO:
        MOV     [TempHandle],BX
        TEST    BYTE PTR FILSTAT,00000010B
        JNZ     GOTALLBIO
        LES     SI,[BIOSOFFS]
        MOV     DI,ES
        MOV     WORD PTR [IOCNT],SI
        MOV     WORD PTR [IOCNT+2],DI
        MOV     BP,OFFSET BIOSData
        CALL    GOTTARG
        JC      RET34
        JMP     SHORT BIOSDONE

GOTALLBIO:
        LES     SI,[BIOSSIZB]
        MOV     DI,ES
        MOV     DS,[BIOSSTRT]
ASSUME  DS:NOTHING
        CALL    WRITEFILE
ASSUME  DS:CODE
BIOSDONE:
        MOV     BX,[TempHandle]
        MOV     CX,BTIME
        MOV     DX,BDATE
        CALL    CLOSETARG
        MOV     CX,DOSATT
        MOV     DX,OFFSET DOSFIL
        LES     SI,[DOSSIZB]
        MOV     DI,ES
        CALL    MAKEFIL
        JC      RET34

GOTNDOS:
        MOV     [TempHandle],BX
        TEST    BYTE PTR FILSTAT,00001000B
        JNZ     GOTALLDOS
        MOV     BP,OFFSET DOSData
        TEST    BYTE PTR FILSTAT,00000100B
        JNZ     PARTDOS
        MOV     WORD PTR [DOSOFFS],0
        MOV     WORD PTR [DOSOFFS+2],0
        CALL    GETSYS3
RET34J: JC      RET34
        JMP     SHORT DOSDONE

PARTDOS:
        LES     SI,[DOSOFFS]
        MOV     DI,ES
        MOV     WORD PTR [IOCNT],SI
        MOV     WORD PTR [IOCNT+2],DI
        CALL    GOTTARG
        JC      RET34J
        JMP     SHORT DOSDONE

GOTALLDOS:
        LES     SI,[DOSSIZB]
        MOV     DI,ES
        MOV     DS,[DOSSTRT]
ASSUME  DS:NOTHING
        CALL    WRITEFILE
ASSUME  DS:CODE
DOSDONE:
        MOV     BX,[TempHandle]
        MOV     CX,DTIME
        MOV     DX,DDATE
        CALL    CLOSETARG
        MOV     CX,COMATT
        MOV     DX,OFFSET COMFIL
        LES     SI,[COMSIZB]
        MOV     DI,ES
        CALL    MAKEFIL
        JNC     GOTNCOM
RET35:  RET

GOTNCOM:
        MOV     [TempHandle],BX
        TEST    BYTE PTR FILSTAT,00100000B
        JNZ     GOTALLCOM
        MOV     BP,OFFSET COMData
        TEST    BYTE PTR FILSTAT,00010000B
        JNZ     PARTCOM
        MOV     WORD PTR [COMOFFS],0
        MOV     WORD PTR [COMOFFS+2],0
        CALL    GETSYS3
        JC      RET35
        JMP     SHORT COMDONE

PARTCOM:
        LES     SI,[COMOFFS]
        MOV     DI,ES
        MOV     WORD PTR [IOCNT],SI
        MOV     WORD PTR [IOCNT+2],DI
        CALL    GOTTARG
        JC      RET35
        JMP     SHORT COMDONE

GOTALLCOM:
        LES     SI,[COMSIZB]
        MOV     DI,ES
        MOV     DS,[COMSTRT]
ASSUME  DS:NOTHING
        CALL    WRITEFILE
ASSUME  DS:CODE
COMDONE:
        MOV     BX,[TempHandle]
        MOV     CX,CTIME
        MOV     DX,CDATE
        CALL    CLOSETARG
        CMP     BYTE PTR [FILSTAT],00101010B
        JZ      NOREDOS
RDFRST2:
        CALL    READDOS                 ; Start back with BIOS
        JNC     NOREDOS
        CALL    SYSPRM                  ;Prompt for system disk
        JMP     RDFRST2                 ;Try again
NOREDOS:
        CLC
        RET

;*********************************************
; Create a file on target disk
; CX = attributes, DX points to name
; DI:SI is size file is to have
;
;   There is a bug in DOS 2.00 and 2.01 having to do with writes
;   from the end of memory. In order to circumvent it this routine
;   must create files with the length in DI:SI
;
; On return BX is handle, carry set if problem

MAKEFIL:
        MOV     BX,DX
        PUSH    WORD PTR [BX]
        MOV     AL,TARGDRV
        MOV     [BX],AL
        MOV     AH,CREAT
        INT     21H
        POP     WORD PTR [BX]
        MOV     BX,AX
        JC      RET50
        MOV     CX,DI
        MOV     DX,SI
        MOV     AX,LSEEK SHL 8
        INT     21H                     ; Seek to eventual EOF
        XOR     CX,CX
        MOV     AH,WRITE
        INT     21H                     ; Set size of file to position
        XOR     CX,CX
        MOV     DX,CX
        MOV     AX,LSEEK SHL 8
        INT     21H                     ; Seek back to start
RET50:
        RET

;*********************************************
; Close a file on the target disk
; CX/DX is time/date, BX is handle

CLOSETARG:
        MOV     AX,(FILE_TIMES SHL 8) OR 1
        INT     21H
        MOV     AH,CLOSE
        INT     21H
        RET

SAVUDIRS:
        XOR     DL,DL
        MOV     SI,OFFSET USERDIRS
        MOV     BYTE PTR [SI],'\'
        INC     SI
        MOV     AH,CURRENT_DIR
        INT     21H
RET43:  RET


RESTUDIR:
        TEST    SWITCHMAP,SYSSW
        JZ      RET43
        MOV     DX,OFFSET USERDIRS
        MOV     AH,CHDIR
        INT     21H             ; Restore users DIR
        RET

INT_23:
        PUSH    CS
        POP     DS
        JMP     FEXIT

;****************************************
; Transfer system files
; BP points to data structure for file involved
; offset is set to current amount read in
; Start set to start of file in buffer
; TempHandle is handle to write to on target

IOLOOP:
        MOV     AL,[SYSDRV]
        CMP     AL,[TARGDRV]
        JNZ     GOTTARG
        MOV     AH,DISK_RESET
        INT     21H
        CALL    TARGPRM                  ;Get target disk

GOTTARG:
;Enter here if some of file is already in buffer, IOCNT must be set
; to size already in buffer.
        MOV     BX,[TempHandle]
        MOV     SI,WORD PTR [IOCNT]
        MOV     DI,WORD PTR [IOCNT+2]
        MOV     DS,[BP.FILE_START]
ASSUME  DS:NOTHING
        CALL    WRITEFILE               ; Write next part
ASSUME  DS:CODE
        JNC     TESTDONE
        RET

TESTDONE:
        LES     AX,[BP.FILE_OFFSET]
        CMP     AX,WORD PTR [BP.FILE_SIZEB]
        JNZ     GETSYS3
        MOV     AX,ES
        CMP     AX,WORD PTR [BP.FILE_SIZEB+2]
        JNZ     GETSYS3
        RET                             ; Carry clear from CMP

GETSYS3:
;Enter here if none of file is in buffer
        MOV     AX,[MSTART]             ; Furthur IO done starting here
        MOV     [BP.FILE_START],AX
        MOV     AL,[SYSDRV]
        CMP     AL,[TARGDRV]
        JNZ     TESTSYS
        MOV     AH,DISK_RESET
        INT     21H
GSYS:
        CALL    SYSPRM                  ;Prompt for system disk
TESTSYS:
        CALL    TESTSYSDISK
        JC      GSYS
        MOV     BX,[BP.FILE_HANDLE]
        LES     DX,[BP.FILE_OFFSET]
        PUSH    DX
        MOV     CX,ES
        MOV     AX,LSEEK SHL 8
        INT     21H
        POP     DX
        LES     SI,[BP.FILE_SIZEB]
        MOV     DI,ES
        SUB     SI,DX
        SBB     DI,CX                   ; DI:SI is #bytes to go
        PUSH    DI
        PUSH    SI
        ADD     SI,15
        ADC     DI,0
        CALL    DISID4
        MOV     AX,SI
        POP     SI
        POP     DI
        CMP     AX,[MSIZE]
        JBE     GOTSIZ2
        MOV     SI,[MSIZE]
        XOR     DI,DI
        CALL    DISIX4
GOTSIZ2:
        MOV     WORD PTR [IOCNT],SI
        MOV     WORD PTR [IOCNT+2],DI
        MOV     DS,[MSTART]
ASSUME  DS:NOTHING
        CALL    READFILE
ASSUME  DS:CODE
        JNC     GETOFFS
        CALL    CLSALL
        JMP     GSYS
GETOFFS:
        XOR     DX,DX
        MOV     CX,DX
        MOV     AX,(LSEEK SHL 8) OR 1
        INT     21H
        MOV     WORD PTR [BP.FILE_OFFSET],AX
        MOV     WORD PTR [BP.FILE_OFFSET+2],DX
        CALL    CLSALL
        JMP     IOLOOP

;*************************************************
; Test to see if correct system disk. Open handles

TESTSYSDISK:
        MOV     AX,OPEN SHL 8
        MOV     DX,OFFSET BIOSFIL
        INT     21H
        JNC     SETBIOS
CRET12: STC
RET12:  RET

SETBIOS:
        MOV     [BIOSHandle],AX
        MOV     BX,AX
        CALL    GETFSIZ
        CMP     [BIOSSIZP],0
        JZ      SETBIOSSIZ
        CMP     [BIOSSIZP],AX
        JZ      SETBIOSSIZ
BIOSCLS:
        MOV     AH,CLOSE
        MOV     BX,[BIOSHandle]
        INT     21H
        JMP     CRET12

SETBIOSSIZ:
        MOV     [BIOSSIZP],AX
        MOV     WORD PTR [BIOSSIZB],SI
        MOV     WORD PTR [BIOSSIZB+2],DI
        MOV     [BDATE],DX
        MOV     [BTIME],CX
        MOV     AX,OPEN SHL 8
        MOV     DX,OFFSET DOSFIL
        INT     21H
        JNC     DOSOPNOK
        JMP     BIOSCLS

DOSOPNOK:
        MOV     [DOSHandle],AX
        MOV     BX,AX
        CALL    GETFSIZ
        CMP     [DOSSIZP],0
        JZ      SETDOSSIZ
        CMP     [DOSSIZP],AX
        JZ      SETDOSSIZ
DOSCLS:
        MOV     AH,CLOSE
        MOV     BX,[DOSHandle]
        INT     21H
        JMP     BIOSCLS

SETDOSSIZ:
        MOV     [DOSSIZP],AX
        MOV     WORD PTR [DOSSIZB],SI
        MOV     WORD PTR [DOSSIZB+2],DI
        MOV     [DDATE],DX
        MOV     [DTIME],CX
        MOV     AX,OPEN SHL 8
        MOV     DX,OFFSET COMFIL
        INT     21H
        JC      DOSCLS
        MOV     [COMHandle],AX
        MOV     BX,AX
        CALL    GETFSIZ
        CMP     [COMSIZP],0
        JZ      SETCOMSIZ
        CMP     [COMSIZP],AX
        JZ      SETCOMSIZ
COMCLS:
        MOV     AH,CLOSE
        MOV     BX,[COMHandle]
        INT     21H
        JMP     DOSCLS

SETCOMSIZ:
        MOV     [COMSIZP],AX
        MOV     WORD PTR [COMSIZB],SI
        MOV     WORD PTR [COMSIZB+2],DI
        MOV     [CDATE],DX
        MOV     [CTIME],CX
        CLC
        RET

;*******************************************
; Handle in BX, return file size in para in AX
; File size in bytes DI:SI, file date in DX, file
; time in CX.

GETFSIZ:
        MOV     AX,(LSEEK SHL 8) OR 2
        XOR     CX,CX
        MOV     DX,CX
        INT     21H
        MOV     SI,AX
        MOV     DI,DX
        ADD     AX,15           ; Para round up
        ADC     DX,0
        AND     DX,0FH          ; If the file is larger than this
                                ;   it is bigger than the 8086 address space!
        MOV     CL,12
        SHL     DX,CL
        MOV     CL,4
        SHR     AX,CL
        OR      AX,DX
        PUSH    AX
        MOV     AX,LSEEK SHL 8
        XOR     CX,CX
        MOV     DX,CX
        INT     21H
        MOV     AX,FILE_TIMES SHL 8
        INT     21H
        POP     AX
        RET

;********************************************
; Read/Write file
;       DS:0 is Xaddr
;       DI:SI is byte count to I/O
;       BX is handle
; Carry set if screw up
;
; I/O SI bytes
; I/O 64K - 1 bytes DI times
; I/O DI bytes
; DS=CS on output


READFILE:
; Must preserve AX,DX
        PUSH    AX
        PUSH    DX
        PUSH    BP
        MOV     BP,READ SHL 8
        CALL    FILIO
        POP     BP
        POP     DX
        POP     AX
        PUSH    CS
        POP     DS
        RET

WRITEFILE:
        PUSH    BP
        MOV     BP,WRITE SHL 8
        CALL    FILIO
        POP     BP
        PUSH    CS
        POP     DS
        RET

FILIO:
        XOR     DX,DX
        MOV     CX,SI
        JCXZ    K64IO
        MOV     AX,BP
        INT     21H
        JC      IORET
        ADD     DX,AX
        CMP     AX,CX           ; If not =, AX<CX, carry set.
        JNZ     IORET
        CALL    NORMALIZE
K64IO:
        CLC
        MOV     CX,DI
        JCXZ    IORET
        MOV     AX,BP
        INT     21H
        JC      IORET
        ADD     DX,AX
        CMP     AX,CX           ; If not =, AX<CX, carry set.
        JNZ     IORET
        CALL    NORMALIZE
        MOV     CX,DI
K64M1:
        PUSH    CX
        XOR     AX,AX
        OR      DX,DX
        JZ      NORMIO
        MOV     CX,10H
        SUB     CX,DX
        MOV     AX,BP
        INT     21H
        JC      IORETP
        ADD     DX,AX
        CMP     AX,CX           ; If not =, AX<CX, carry set.
        JNZ     IORETP
        CALL    NORMALIZE
NORMIO:
        MOV     CX,0FFFFH
        SUB     CX,AX
        MOV     AX,BP
        INT     21H
        JC      IORETP
        ADD     DX,AX
        CMP     AX,CX           ; If not =, AX<CX, carry set.
        JNZ     IORETP
        CALL    NORMALIZE       ; Clears carry
        POP     CX
        LOOP    K64M1
        PUSH    CX
IORETP:
        POP     CX
IORET:
        RET


;*********************************
; Shift DI:SI left 4 bits
DISIX4:
        MOV     CX,4
SH32:
        SHL     SI,1
        RCL     DI,1
        LOOP    SH32
        RET

;*********************************
; Shift DI:SI right 4 bits
DISID4:
        MOV     CX,4
SH32B:
        SHR     DI,1
        RCR     SI,1
        LOOP    SH32B
        RET

;********************************
; Normalize DS:DX

NORMALIZE:
        PUSH    DX
        PUSH    AX
        SHR     DX,1
        SHR     DX,1
        SHR     DX,1
        SHR     DX,1
        MOV     AX,DS
        ADD     AX,DX
        MOV     DS,AX
        POP     AX
        POP     DX
        AND     DX,0FH                  ; Clears carry
        RET


ROOTSTR DB      ?
        DB      ":"
SWTCH   DB      "/",0
DBLFLG DB       0               ;Initialize flags to zero
CLEARFLG DB     0
DRIVE   DB      0
DEFALT  DB      0               ;Default drive
IOCNT   DD      ?
MSTART  DW      ?               ; Start of sys file buffer (para#)
MSIZE   DW      ?               ; Size of above in paragraphs
TempHandle DW   ?
FILSTAT DB      ?               ; In memory status of files
                                ; XXXXXX00B BIOS not in
                                ; XXXXXX01B BIOS partly in
                                ; XXXXXX10B BIOS all in
                                ; XXXX00XXB DOS not in
                                ; XXXX01XXB DOS partly in
                                ; XXXX10XXB DOS all in
                                ; XX00XXXXB COMMAND not in
                                ; XX01XXXXB COMMAND partly in
                                ; XX10XXXXB COMMAND all in

USERDIRS DB     DIRSTRLEN+3 DUP(?)      ; Storage for users current directory

BIOSData        LABEL   BYTE
BIOSHandle      DW      0
BIOSSIZP        DW      0
BIOSSIZB        DD      ?
BIOSOFFS        DD      ?
BIOSSTRT        DW      ?
BDATE           DW      0               ;IO system date stored here
BTIME           DW      0               ;IO system time stored here

BIOSATT EQU     attr_hidden + attr_system + attr_read_only
BIOSFIL LABEL   BYTE
BIODRV  LABEL   BYTE
        DB      "X:\"
        IF IBMVER OR IBMJAPVER
        DB      "IBMBIO.COM"
        ENDIF
        IF MSVER
        DB      "IO.SYS"
        ENDIF
        DB      0

DOSData         LABEL   BYTE
DOSHandle       DW      0
DOSSIZP         DW      0
DOSSIZB         DD      ?
DOSOFFS         DD      ?
DOSSTRT         DW      ?
DDATE           DW      0               ;DOS date stored here
DTIME           DW      0               ;DOS time

DOSATT  EQU     attr_hidden + attr_system + attr_read_only
DOSFIL  LABEL   BYTE
DOSDRV  LABEL   BYTE
        DB      "X:\"
        IF IBMVER OR IBMJAPVER
        DB      "IBMDOS.COM"
        ENDIF
        IF MSVER
        DB      "MSDOS.SYS"
        ENDIF
        DB      0

COMData         LABEL   BYTE
COMHandle       DW      0
COMSIZP         DW      0
COMSIZB         DD      ?
COMOFFS         DD      ?
COMSTRT         DW      ?
CDATE           DW      0               ;Date of COMMAND
CTIME           DW      0               ;Time of COMMAND

COMATT  EQU     0
COMFIL  LABEL   BYTE
COMDRV  LABEL   BYTE
        DB      "X:\COMMAND.COM",0

VOLFCB  DB      -1,0,0,0,0,0,8
        DB      0
VOLNAM  DB      "           "
        DB      8
        DB      26 DUP(?)

ALLFILE DB      -1,0,0,0,0,0,0FFH
ALLDRV  DB      0,"???????????"
        DB      26 DUP(?)

CLEANFILE DB    0
CLNNAM  DB      "AAAFFFFFFOR"
        DB      26 DUP(?)

SWITCHMAP DW    ?
SWITCHCOPY DW   ?
FAT     DW      ?
        DW      ?
CLUSSIZ DW      ?
SECSIZ  DW      ?
SYSSIZ  DD      ?
FDSKSIZ DD      ?
BADSIZ  DD      ?
SYSTRKS DW      ?
SECTORS DW      ?
INBUFF  DB      80,0
        DB      80 DUP(?)

        DB      100H DUP(?)

STACK   LABEL   BYTE

;For FORMES module

        EXTRN   BADVER:BYTE,SNGMSG:BYTE,SNGDRV:BYTE,HRDMSG:BYTE,HRDDRV:BYTE
        EXTRN   LABPRMT:BYTE,TARGMSG:BYTE,TARGDRV:BYTE
        EXTRN   SYSTRAN:BYTE,CRLFMSG:BYTE,INVCHR:BYTE,INVDRV:BYTE
        EXTRN   SYSMSG:BYTE,SYSDRV:BYTE,FRMTERR:BYTE,NOTSYS:BYTE
        EXTRN   NOUSE:BYTE,MEMEX:BYTE,INVPAR:BYTE

        IF      IBMVER
        EXTRN   ASGERR:BYTE
        ENDIF

CODE    ENDS

        END     START
