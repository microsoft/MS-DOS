TITLE  GETSET - GETting and SETting MS-DOS system calls
NAME   GETSET
;
; System Calls which get and set various things
;
; $GET_VERSION
; $GET_VERIFY_ON_WRITE
; $SET_VERIFY_ON_WRITE
; $SET_CTRL_C_TRAPPING
; $INTERNATIONAL
; $GET_DRIVE_FREESPACE
; $GET_DMA
; $SET_DMA
; $GET_DEFAULT_DRIVE
; $SET_DEFAULT_DRIVE
; $GET_INTERRUPT_VECTOR
; $SET_INTERRUPT_VECTOR
; RECSET
; $CHAR_OPER
;
.xlist
;
; get the appropriate segment definitions
;
INCLUDE DOSSEG.ASM

IFNDEF  ALTVECT
ALTVECT EQU     0                       ; FALSE
ENDIF

IFNDEF IBM
IBM EQU 0
ENDIF

CODE    SEGMENT BYTE PUBLIC  'CODE'
        ASSUME  SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.ASM
INCLUDE DEVSYM.ASM
.cref
.list


        i_need  VERFLG,BYTE
        i_need  CNTCFLAG,BYTE
        i_need  DMAADD,DWORD
        i_need  CURDRV,BYTE
        i_need  Current_Country,WORD
        i_need  international_table,BYTE
        i_need  INDOS,BYTE
        i_need  SYSINITVAR,WORD
        i_need  NUMIO,BYTE
        i_need  SWITCH_CHARACTER,BYTE
        i_need  DEVICE_AVAILABILITY,BYTE

USERNUM DW      ?                       ; 24 bit user number
        DB      ?
        IF      IBM
OEMNUM  DB      0                       ; 8 bit OEM number
        ELSE
OEMNUM  DB      0FFH                    ; 8 bit OEM number
        ENDIF

MSVERS  EQU     THIS WORD               ; MS-DOS version in hex for $GET_VERSION
MSMAJOR DB      DOS_MAJOR_VERSION
MSMINOR DB      DOS_MINOR_VERSION


BREAK <$Get_Version -- Return MSDOS version number>
        procedure   $GET_VERSION,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       None
; Function:
;       Return MS-DOS version number
; Outputs:
;       OEM number in BH
;       User number in BL:CX (24 bits)
;       Version number as AL.AH in binary
;       NOTE: On pre 1.28 DOSs AL will be zero

        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     BX,[USERNUM + 2]
        MOV     CX,[USERNUM]
        MOV     AX,[MSVERS]
        invoke  get_user_stack
ASSUME  DS:NOTHING
        MOV     [SI.user_BX],BX
        MOV     [SI.user_CX],CX
        MOV     [SI.user_AX],AX  ; Really only sets AH
        return
$GET_VERSION  ENDP

BREAK <$International - return country-dependent information>
;
; Inputs:
;       DS:DX point to a block
; Function:
;       give users an idea of what country the application is running
; Outputs:
;       AX = number of bytes transferred
;       DS:DX ->+---------------------------------+
;               | WORD Date/time format           |
;               +---------------------------------+
;               | BYTE ASCIZ currency symbol      |
;               +---------------------------------+
;               | BYTE ASCIZ thousands separator  |
;               +---------------------------------+
;               | BYTE ASCIZ decimal separator    |
;               +---------------------------------+

        procedure   $INTERNATIONAL,NEAR
ASSUME  DS:NOTHING,ES:NOTHING
        MOV     BL,AL
        PUSH    DS
        POP     ES
        PUSH    DX
        POP     DI
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        CMP     DI,-1
        JZ      international_set
        OR      BL,BL
        JNZ     international_find
        MOV     SI,[Current_Country]
        MOV     AX,WORD PTR [SI-2]      ; Get size in AL, country code in AH
        MOV     BL,AH                   ; Set country code
        JMP     SHORT international_copy

international_find:
        CALL    international_get
        JNC     international_copy
        error   country_not_found

international_get:
        MOV     SI,OFFSET DOSGROUP:international_table
international_next:
        LODSW                           ; Get size in AL, country code in AH
        CMP     AL,-1
        JNZ     check_code
        STC
RET35:
        RET

check_code:
        CMP     BL,AH
        JZ      RET35                   ; Carry clear
        XOR     AH,AH
        ADD     SI,AX
        JMP     international_next

international_copy:
        MOV     CL,AL
        XOR     CH,CH
        PUSH    DI
        REP     MOVSB
        POP     DI
        MOV     WORD PTR ES:[DI.MAP_CALL + 2],CS   ; Set segment for case map call
international_ok:
        XOR     AX,AX
        MOV     AL,BL           ; Return country code in AX
        transfer SYS_RET_OK

international_set:
        CALL    international_get
        JNC     international_store
        error   country_not_found

international_store:
        MOV     [Current_Country],SI
        JMP     international_ok

$INTERNATIONAL  ENDP

BREAK <$Get_Verify_on_Write - return verify-after-write flag>
        procedure   $GET_VERIFY_ON_WRITE,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       none.
; Function:
;       returns flag
; Returns:
;       AL = value of VERIFY flag

        MOV     AL,[VERFLG]
        return
$GET_VERIFY_ON_WRITE  ENDP

BREAK <$Set_Verify_on_Write - Toggle verify-after-write flag>
        procedure   $SET_VERIFY_ON_WRITE,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       AL = desired value of VERIFY flag
; Function:
;       Sets flag
; Returns:
;       None

        AND     AL,1
        MOV     [VERFLG],AL
        return
$SET_VERIFY_ON_WRITE  ENDP

BREAK <$Set_CTRL_C_Trapping -- En/Disable ^C check in dispatcher>
        procedure   $SET_CTRL_C_TRAPPING,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       AL = 0 read ^C status
;       AL = 1 Set ^C status, DL = 0/1 for ^C off/on
; Function:
;       Enable disable ^C checking in dispatcher
; Outputs:
;       If AL = 0 then DL = 0/1 for ^C off/on

        OR      AL,AL
        JNZ     CTRL_C_set
        invoke  get_user_stack
        MOV     AL,[CNTCFLAG]
        MOV     BYTE PTR [SI.user_DX],AL
        return
CTRL_C_set:
        DEC     AL
        JNZ     bad_val
        AND     DL,01h
        MOV     [CNTCFLAG],DL
        return
bad_val:
        MOV     AL,0FFH
        return
$SET_CTRL_C_TRAPPING ENDP

BREAK <$Get_INDOS_Flag -- Return location of DOS critical-section flag>
        procedure   $GET_INDOS_FLAG,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       None
; Function:
;       Returns location of DOS status for interrupt routines
; Returns:
;       Flag location in ES:BX

        invoke  get_user_stack
        MOV     [SI.user_BX],OFFSET DOSGROUP:INDOS
        MOV     [SI.user_ES],SS
        return
$GET_INDOS_FLAG ENDP

;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        procedure   $GET_IN_VARS,NEAR
; Return a pointer to interesting DOS variables This call is version
; dependent and is subject to change without notice in future versions.
; Use at risk.
        invoke  get_user_stack
        MOV     [SI.user_BX],OFFSET DOSGROUP:SYSINITVAR
        MOV     [SI.user_ES],SS
        return
$GET_IN_VARS    ENDP
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

BREAK <$Get_Drive_Freespace -- Return bytes of free disk space on a drive>
        procedure   $GET_DRIVE_FREESPACE,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DL = Drive number
; Function:
;       Return number of free allocation units on drive
; Outputs:
;       BX = Number of free allocation units
;       DX = Total Number of allocation units on disk
;       CX = Sector size
;       AX = Sectors per allocation unit
;          = -1 if bad drive specified
; This call returns the same info in the same registers (except for FAT pointer)
;      as the old FAT pointer calls

        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     AL,DL
        invoke  GETTHISDRV
        MOV     AX,-1
        JC      BADFRDRIVE
        invoke  FATREAD
        XOR     DX,DX
        MOV     BX,2
        MOV     CX,ES:[BP.dpb_max_cluster]
        DEC     CX
        PUSH    CX              ; Save Total
SCANFREE:
        invoke  UNPACK
        JNZ     NOTFREECLUS
        INC     DX
NOTFREECLUS:
        INC     BX
        LOOP    SCANFREE
        POP     BX              ; Remember Total
        MOV     AL,ES:[BP.dpb_cluster_mask]
        INC     AL
        XOR     AH,AH
        MOV     CX,ES:[BP.dpb_sector_size]
BADFRDRIVE:
        invoke  get_user_stack
ASSUME  DS:NOTHING
        MOV     [SI. user_CX],CX
        MOV     [SI.user_DX],BX
        MOV     [SI.user_BX],DX
        MOV     [SI.user_AX],AX
        return

$GET_DRIVE_FREESPACE ENDP

BREAK <$Get_DMA, $Set_DMA -- Get/Set current DMA address>
        procedure   $GET_DMA,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       None
; Function:
;       Get DISK TRANSFER ADDRESS
; Returns:
;       ES:BX is current transfer address

        MOV     BX,WORD PTR [DMAADD]
        MOV     CX,WORD PTR [DMAADD+2]
        invoke  get_user_stack
        MOV     [SI.user_BX],BX
        MOV     [SI.user_ES],CX
        return
$GET_DMA ENDP

        procedure   $SET_DMA,NEAR   ; System call 26
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DS:DX is desired new disk transfer address
; Function:
;       Set DISK TRANSFER ADDRESS
; Returns:
;       None

        MOV     WORD PTR [DMAADD],DX
        MOV     WORD PTR [DMAADD+2],DS
        return
$SET_DMA  ENDP

BREAK <$Get_Default_DPB,$Get_DPB -- Return pointer to DPB>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;                                                                          ;
        procedure   $GET_DEFAULT_DPB,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DL = Drive number (always default drive for call 31)
; Function:
;       Return pointer to drive parameter table for default drive
; Returns:
;       DS:BX points to the DPB
;       AL = 0 If OK, = -1 if bad drive (call 50 only)

        MOV     DL,0
        entry   $GET_DPB
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        MOV     AL,DL
        invoke  GETTHISDRV
        JC      ISNODRV
        invoke  FATREAD
        invoke  get_user_stack
ASSUME  DS:NOTHING
        MOV     [SI.user_BX],BP
        MOV     [SI.user_DS],ES
        XOR     AL,AL
        return

ISNODRV:
        MOV     AL,-1
        return
$GET_Default_dpb    ENDP
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;


BREAK <$Get_Default_Drive, $Set_Default_Drive -- Set/Get default drive>
        procedure   $GET_DEFAULT_DRIVE,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       None
; Function:
;       Return current drive number
; Returns:
;       AL = drive number

        MOV     AL,[CURDRV]
        return
$GET_DEFAULT_DRIVE  ENDP

        procedure   $SET_DEFAULT_DRIVE,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       DL = Drive number for new default drive
; Function:
;       Set the default drive
; Returns:
;       AL = Number of drives, NO ERROR RETURN IF DRIVE NUMBER BAD

        MOV     AL,[NUMIO]
        CMP     DL,AL
        JNB     RET17
        MOV     [CURDRV],DL
RET17:  return
$SET_DEFAULT_DRIVE  ENDP


BREAK <$Get_Interrupt_Vector - Get/Set interrupt vectors>
        procedure   $GET_INTERRUPT_VECTOR,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       AL = interrupt number
; Function:
;       Get the interrupt vector
; Returns:
;       ES:BX is current interrupt vector

        CALL    RECSET
        LES     BX,DWORD PTR ES:[BX]
        invoke  get_user_stack
        MOV     [SI.user_BX],BX
        MOV     [SI.user_ES],ES
        return
$GET_INTERRUPT_VECTOR ENDP

        procedure   $SET_INTERRUPT_VECTOR,NEAR   ; System call 37
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       AL = interrupt number
;       DS:DX is desired new interrupt vector
; Function:
;       Set the interrupt vector
; Returns:
;       None

        CALL    RECSET
        MOV     ES:[BX],DX
        MOV     ES:[BX+2],DS
        return
$SET_INTERRUPT_VECTOR ENDP

        IF      ALTVECT
VECIN:  ; INPUT VECTORS
        DB      22H             ; Terminate
        DB      23H             ; ^C
        DB      24H             ; Hard error
        DB      28H             ; Spooler
LSTVEC  DB      ?               ; ALL OTHER

VECOUT: ; GET MAPPED VECTOR
        DB      int_terminate
        DB      int_ctrl_c
        DB      int_fatal_abort
        DB      int_spooler
LSTVEC2 DB      ?               ; Map to itself

NUMVEC  =       VECOUT-VECIN
        ENDIF

procedure   RECSET,NEAR

        IF      ALTVECT
        PUSH    SS
        POP     ES
        MOV     [LSTVEC],AL     ; Terminate list with real vector
        MOV     [LSTVEC2],AL    ; Terminate list with real vector
        MOV     CX,NUMVEC       ; Number of possible translations
        MOV     DI,OFFSET DOSGROUP:VECIN ; Point to vectors
        REPNE   SCASB
        MOV     AL,ES:[DI+NUMVEC-1] ; Get translation
        ENDIF

        XOR     BX,BX
        MOV     ES,BX
        MOV     BL,AL
        SHL     BX,1
        SHL     BX,1
        return
recset  ENDP

BREAK <$Char_Oper - hack on paths, switches so that xenix can look like PCDOS>
;
; input:    AL = function:
;                   0 - read switch char
;                   1 - set switch char (char in DL)
;                   2 - read device availability
;                   3 - set device availability (0/FF in DL)
;                       DL = 0 means /DEV/ must preceed device names
;                       DL = Non0 means /DEV/ need not preeceed
; output:   (get) DL - character/flag
;
        procedure $CHAR_OPER,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        PUSH    SS
        POP     DS
ASSUME  DS:DOSGROUP
        OR      AL,AL
        JNZ     char_oper_set_switch
        MOV     DL,[switch_character]
        JMP     SHORT char_oper_ret
char_oper_set_switch:
        DEC     AL
        JNZ     char_oper_read_avail
        MOV     [switch_character],DL
        return
char_oper_read_avail:
        DEC     AL
        JNZ     char_oper_set_avail
        MOV     DL,[device_availability]
        JMP     SHORT char_oper_ret
char_oper_set_avail:
        DEC     AL
        JNZ     char_oper_bad_ret
        MOV     [device_availability],DL
        return
char_oper_bad_ret:
        MOV     AL,0FFh
        return
char_oper_ret:
        invoke  get_user_stack
        MOV     [SI.user_DX],DX
        return
$CHAR_OPER  ENDP

BREAK <$SetDPB - Create a valid DPB from a user-specified BPB>
        procedure   $SETDPB,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

; Inputs:
;       ES:BP Points to DPB
;       DS:SI Points to BPB
; Function:
;       Build a correct DPB from the BPB
; Outputs:
; ES:BP and DS preserved all others destroyed

        MOV     DI,BP
        ADD     DI,2                    ; Skip over dpb_drive and dpb_UNIT
        LODSW
        STOSW                           ; dpb_sector_size
        MOV     DX,AX
        LODSB
        DEC     AL
        STOSB                           ; dpb_cluster_mask
        INC     AL
        XOR     AH,AH
LOG2LOOP:
        TEST    AL,1
        JNZ     SAVLOG
        INC     AH
        SHR     AL,1
        JMP     SHORT LOG2LOOP
SAVLOG:
        MOV     AL,AH
        STOSB                           ; dpb_cluster_shift
        MOV     BL,AL
        MOVSW                           ; dpb_first_FAT Start of FAT (# of reserved sectors)
        LODSB
        STOSB                           ; dpb_FAT_count Number of FATs
        MOV     BH,AL
        LODSW
        STOSW                           ; dpb_root_entries Number of directory entries
        MOV     CL,5
        SHR     DX,CL                   ; Directory entries per sector
        DEC     AX
        ADD     AX,DX                   ; Cause Round Up
        MOV     CX,DX
        XOR     DX,DX
        DIV     CX
        MOV     CX,AX                   ; Number of directory sectors
        INC     DI
        INC     DI                      ; Skip dpb_first_sector
        MOVSW                           ; Total number of sectors in DSKSIZ (temp as dpb_max_cluster)
        LODSB
        MOV     ES:[BP.dpb_media],AL    ; Media byte
        LODSW                           ; Number of sectors in a FAT
        STOSB                           ; dpb_FAT_size
        MUL     BH                      ; Space occupied by all FATs
        ADD     AX,ES:[BP.dpb_first_FAT]
        STOSW                           ; dpb_dir_sector
        ADD     AX,CX                   ; Add number of directory sectors
        MOV     ES:[BP.dpb_first_sector],AX
        SUB     AX,ES:[BP.DSKSIZ]
        NEG     AX                      ; Sectors in data area
        MOV     CL,BL                   ; dpb_cluster_shift
        SHR     AX,CL                   ; Div by sectors/cluster
        INC     AX
        MOV     ES:[BP.dpb_max_cluster],AX
        MOV     ES:[BP.dpb_current_dir],0     ; Current directory is root
        return
$SETDPB ENDP
;                                                                          ;
;            C  A  V  E  A  T     P  R  O  G  R  A  M  M  E  R             ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;

        do_ext

CODE    ENDS
        END
      