;
; xenix file calls for MSDOS
;

INCLUDE DOSSEG.ASM

IFNDEF  KANJI
KANJI   EQU     0       ;FALSE
ENDIF

CODE    SEGMENT BYTE PUBLIC  'CODE'
        ASSUME  SS:DOSGROUP,CS:DOSGROUP

.xlist
.xcref
INCLUDE DOSSYM.ASM
INCLUDE DEVSYM.ASM
.cref
.list

TITLE   XENIX - IO system to mimic UNIX
NAME    XENIX

        i_need  NoSetDir,BYTE
        i_need  CURDRV,BYTE
        i_need  IOCALL,BYTE
        i_need  IOMED,BYTE
        i_need  IOSCNT,WORD
        i_need  IOXAD,DWORD
        i_need  DIRSTART,WORD
        i_need  ATTRIB,BYTE
        i_need  THISFCB,DWORD
        i_need  AuxStack,BYTE
        i_need  Creating,BYTE
        i_need  ThisDRV,BYTE
        i_need  NAME1,BYTE
        i_need  LastEnt,WORD
        i_need  ThisDPB,DWORD
        i_need  EntLast,WORD
        i_need  CurrentPDB,WORD
        i_need  sft_addr,DWORD              ; pointer to head of table
        i_need  CURBUF,DWORD                ; pointer to current buffer
        i_need  DMAADD,DWORD                ; pointer to current dma address

BREAK <Local data>

CODE        ENDS
DATA        SEGMENT BYTE PUBLIC 'DATA'


PushSave    DW      ?
PushES      DW      ?
PushBX      DW      ?

xenix_count     DW      ?

DATA        ENDS
CODE        SEGMENT BYTE PUBLIC 'CODE'


BREAK <get_sf_from_sfn - translate a sfn into sf pointer>
;
; get_sf_from_sfn
; input:    AX has sfn (0 based)
;           DS is DOSGROUP
; output:   JNC <found>
;               ES:DI is sf entry
;           JC  <error>
;               ES,DI indeterminate
;
        procedure   get_sf_from_sfn,NEAR
        ASSUME  DS:DOSGROUP,ES:NOTHING
        PUSH    AX                      ; we trash AX in process
        LES     DI,[sft_addr]

get_sfn_loop:
        CMP     DI,-1                   ; end of chain of tables?
        JZ      get_sf_invalid          ; I guess so...
        SUB     AX,ES:[DI].sft_count    ; chop number of entries in this table
        JL      get_sf_gotten           ; sfn is in this table
        LES     DI,ES:[DI].sft_link     ; step to next table
        JMP     get_sfn_loop

get_sf_gotten:
        ADD     AX,ES:[DI].sft_count    ; reset to index in this table
        PUSH    BX
        MOV     BX,SIZE sf_entry
        MUL     BL                      ; number of bytes offset into table
        POP     BX
        ADD     AX,sft_table            ; offset into sf table structure
        ADD     DI,AX                   ; offset into memory
        CLC
        JMP     SHORT get_sf_ret

get_sf_jfn_invalid:
get_sf_invalid:
        STC

get_sf_jfn_ret:
get_sf_ret:
        POP     AX                      ; remember him?
        RET
get_sf_from_sfn ENDP

BREAK <get_sf_from_jfn - translate a jfn into sf pointer>
;
; get_sf_from_jfn
; input:    BX is jfn 0 based
;           DS is DOSGROUP
; output:   JNC <found>
;               ES:DI is sf entry
;           JC  <error>
;               ES,DI is indeterminate
;
        procedure   get_sf_from_jfn,NEAR
        ASSUME  DS:DOSGROUP,ES:NOTHING
        PUSH    AX                      ; save him
        invoke  get_jfn_pointer
        JC      get_sf_jfn_invalid
        MOV     AL,ES:[DI]              ; get sfn
        CMP     AL,0FFh                 ; is it free?
        JZ      get_sf_jfn_invalid      ; yep... error
        XOR     AH,AH
        invoke  get_sf_from_sfn         ; check this sfn out...
        JMP     SHORT get_sf_jfn_ret    ; condition codes are properly set

get_sf_from_jfn ENDP

BREAK <get_jfn_pointer - map a jfn into a pointer to jfn>
;
; get_jfn_pointer
; input:    BX is jfn
;           DS is DOSGROUP
; output:   JNC <found>
;               ES:DI is pointer to jfn
;           JC  <bad jfn>
;
        procedure   Get_jfn_pointer,NEAR
        ASSUME  DS:DOSGROUP,ES:NOTHING
        CMP     BX,FilPerProc
        JAE     get_jfn_bad
        MOV     ES,[CurrentPDB]
        MOV     DI,BX
        ADD     DI,PDB_JFN_Table
        CLC
        RET

get_jfn_bad:
        STC
        RET
get_jfn_pointer ENDP


BREAK <$Close - release a handle>
;
;   Assembler usage:
;           MOV     BX, handle
;           MOV     AH, Close
;           INT     int_command
;
;   Error return:
;           AX = error_invalid_handle
;
        procedure   $Close,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING

        context DS

        invoke  get_jfn_pointer         ; get jfn loc
        JNC     close_jfn
close_bad_handle:
        error   error_invalid_handle

close_jfn:
        MOV     AL,BYTE PTR ES:[DI]
        CMP     AL,0FFh
        JE      close_bad_handle
        MOV     BYTE PTR ES:[DI],0FFh;
        XOR     AH,AH
        invoke  get_sf_from_sfn
        JC      close_bad_handle
        PUSH    ES
        POP     DS
        ASSUME  DS:NOTHING
        DEC     [DI].sf_ref_count       ; no more reference
        LEA     DX,[DI].sf_fcb
;
; need to restuff Attrib if we are closing a protected file
;
        TEST    [DI.sf_fcb.fcb_DevID],devid_file_clean+devid_device
        JNZ     close_ok
        PUSH    WORD PTR [DI].sf_attr
        invoke  MOVNAMENOSET
        POP     BX
        MOV     [Attrib],BL
        invoke  FCB_CLOSE_INNER
        CMP     AL,0FFh                 ; file not found error?
        JNZ     close_ok
        error   error_file_not_found
close_ok:
        transfer    SYS_RET_OK

$Close  ENDP


BREAK <PushDMA, PopDMA, ptr_normalize - set up local dma and save old>
; PushDMA
; input:    DS:DX is DMA
; output:   DS:DX is normalized , ES:BX destroyed
;           [DMAADD] is now set up to DS:DX
;           old DMA is pushed

        procedure   PushDMA,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING

        MOV     PushES,ES
        MOV     PushBX,BX
        POP     PushSave
        LES     BX,DWORD PTR [DMAADD]   ; get old dma
        PUSH    ES
        PUSH    BX
        PUSH    PushSave
        invoke  ptr_normalize           ; get new dma
        MOV     WORD PTR [DMAADD],DX    ; save IT!
        MOV     WORD PTR [DMAADD+2],DS
        MOV     ES,PushES
        MOV     BX,PushBX
        RET
PushDMA ENDP

; PopDMA
; input:    old DMA under ret address on stack
; output:   [DMAADD] set to old version and stack popped
        procedure   PopDMA,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING

        POP     PushSave
        POP     WORD PTR [DMAADD]
        POP     WORD PTR [DMAADD+2]
        PUSH    PushSave
        RET
PopDMA  ENDP

; ptr_normalize
; input:    DS:DX is a pointer
; output:   DS:DX is normalized (DX < 10h)
        procedure   ptr_normalize,NEAR
        PUSH    CX                      ; T1 = CX
        PUSH    DX                      ; T2 = DX
        MOV     CL,4
        SHR     DX,CL                   ; DX = (DX >> 4)    (using CX)
        MOV     CX,DS
        ADD     CX,DX
        MOV     DS,CX                   ; DS = DS + DX      (using CX)
        POP     DX
        AND     DX,0Fh                  ; DX = T2 & 0Fh
        POP     CX                      ; CX = T1

;       PUSH    AX
;       PUSH    DX
;       MOV     AX,DS
;       PUSH    CX
;       MOV     CL,4
;       SHR     DX,CL                   ; get upper part of dx
;       POP     CX
;       ADD     AX,DX                   ; add into seg address
;       MOV     DS,AX
;       POP     DX
;       AND     DX,0Fh                  ; save low part
;       POP     AX

        RET
ptr_normalize   ENDP

BREAK <$Read - Do file/device I/O>
;
;   Assembler usage:
;           LDS     DX, buf
;           MOV     CX, count
;           MOV     BX, handle
;           MOV     AH, Read
;           INT     int_command
;         AX has number of bytes read
;   Errors:
;           AX = read_invalid_handle
;              = read_access_denied
;

        procedure   $Read,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING

        invoke  PushDMA
        CALL    IO_setup
        JC      IO_err
        CMP     ES:[DI].sf_mode,open_for_write
        JNE     read_setup
IO_bad_mode:
        MOV     AL,read_access_denied
IO_err:
        invoke  PopDMA
        transfer    SYS_RET_ERR

read_setup:
        invoke  $FCB_RANDOM_READ_BLOCK  ; do read
IO_done:
        invoke  get_user_stack          ; get old frame
        MOV     AX,[SI].user_CX         ; get returned CX
        MOV     CX,xenix_count
        MOV     [SI].user_CX,CX         ; stash our CX
        invoke  PopDMA                  ; get old DMA
        transfer    SYS_RET_OK
$Read   ENDP

BREAK <$Write - Do file/device I/O>
;
;   Assembler usage:
;           LDS     DX, buf
;           MOV     CX, count
;           MOV     BX, handle
;           MOV     AH, Write
;           INT     int_command
;         AX has number of bytes written
;   Errors:
;           AX = write_invalid_handle
;              = write_access_denied
;

        procedure   $Write,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING

        invoke  PushDMA
        CALL    IO_setup
        JC      IO_err
        CMP     ES:[DI].sf_mode,open_for_read
        JE      IO_bad_mode
        invoke  $FCB_RANDOM_WRITE_BLOCK ; do write
        JMP     IO_done

$write  ENDP

IO_setup:
        ASSUME  DS:NOTHING,ES:NOTHING
        context DS
        MOV     xenix_count,CX
        invoke  Get_sf_from_jfn
        ; ES:DI is sf pointer
        MOV     AL,read_invalid_handle          ;Assume an error
        MOV     CX,xenix_count
        LEA     DX,[DI].sf_fcb
        PUSH    ES
        POP     DS
        ASSUME  DS:NOTHING
        RET

BREAK <$LSEEK - set random record field>
;
;   Assembler usage:
;           MOV     DX, offsetlow
;           MOV     CX, offsethigh
;           MOV     BX, handle
;           MOV     AL, method
;           MOV     AH, LSeek
;           INT     int_command
;         DX:AX has the new location of the pointer
;   Error returns:
;           AX = error_invalid_handle
;              = error_invalid_function
        procedure   $LSEEK,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        CMP     AL,3
        JB      lseek_get_sf
        error   error_invalid_function

lseek_get_sf:
        context DS
        invoke  get_sf_from_jfn
        PUSH    ES
        POP     DS
        ASSUME  DS:NOTHING
        JC      lseek_bad
;
; don't seek device
;
        TEST    [DI.sf_fcb+fcb_devid],devid_device
        JZ      lseek_dispatch
        XOR     AX,AX
        XOR     DX,DX
        JMP     SHORT lseek_ret
lseek_dispatch:
        DEC     AL
        JL      lseek_beginning
        DEC     AL
        JL      lseek_current
; move from end of file
; first, get end of file
        XCHG    AX,DX               ; AX <- low
        XCHG    DX,CX               ; DX <- high
        ASSUME  DS:NOTHING
        ADD     AX,[DI+sf_fcb+fcb_FILSIZ]
        ADC     DX,[DI+sf_fcb+fcb_FILSIZ+2]
        JMP     SHORT lseek_ret

lseek_beginning:
        XCHG    AX,DX               ; AX <- low
        XCHG    DX,CX               ; DX <- high

lseek_ret:
        MOV     WORD PTR [DI+sf_fcb+fcb_RR],AX
        MOV     WORD PTR [DI+sf_fcb+fcb_RR+2],DX
        invoke  get_user_stack
        MOV     [SI.user_DX],DX
        MOV     [SI.user_AX],AX
        transfer    SYS_RET_OK

lseek_current:
; ES:DI is pointer to sf... need to invoke  set random record for place
        XCHG    AX,DX               ; AX <- low
        XCHG    DX,CX               ; DX <- high
        ADD     AX,WORD PTR [DI+sf_fcb+fcb_RR]
        ADC     DX,WORD PTR [DI+sf_fcb+fcb_RR+2]
        JMP     lseek_ret

lseek_bad:
        error   error_invalid_handle
$lseek  ENDP


BREAK <$IOCTL - return/set device dependent stuff>
;
;   Assembler usage:
;           MOV     BX, Handle
;           MOV     DX, Data
;
;       (or LDS     DX,BUF
;           MOV     CX,COUNT)
;
;           MOV     AH, Ioctl
;           MOV     AL, Request
;           INT     21h
;
;   Error returns:
;           AX = error_invalid_handle
;              = error_invalid_function
;              = error_invalid_data

        procedure   $IOCTL,NEAR
        ASSUME  DS:NOTHING,ES:NOTHING
        MOV     SI,DS                   ;Stash DS for calls 2,3,4 and 5
        context DS
        CMP     AL,3
        JA      ioctl_check_block       ;Block device
        PUSH    DX
        invoke  get_sf_from_jfn
        POP     DX                      ;Restore DATA
        JNC     ioctl_check_permissions ; have valid handle
        error   error_invalid_handle

ioctl_check_permissions:
        CMP     AL,2
        JAE     ioctl_control_string
        CMP     AL,0
        MOV     AL,BYTE PTR ES:[DI+sf_fcb+fcb_devid]
        JZ      ioctl_read              ; read the byte
        OR      DH,DH
        JZ      ioctl_check_device      ; can I set with this data?
        error   error_invalid_data      ; no DH <> 0

ioctl_check_device:
        TEST    AL,devid_ISDEV          ; can I set this handle?
        JZ      ioctl_bad_fun           ; no, it is a file.
        MOV     BYTE PTR ES:[DI+sf_fcb+fcb_devid],DL
        transfer    SYS_RET_OK

ioctl_read:
        XOR     AH,AH
        TEST    AL,devid_ISDEV          ; Should I set high byte
        JZ      ioctl_no_high           ; no
        LES     DI,DWORD PTR ES:[DI+sf_fcb+fcb_FIRCLUS]  ;Get device pointer
        MOV     AH,BYTE PTR ES:[DI.SDEVATT+1]   ;Get high byte
ioctl_no_high:
        invoke  get_user_stack
        MOV     DX,AX
        MOV     [SI.user_DX],DX
        transfer    SYS_RET_OK

ioctl_control_string:
        TEST    BYTE PTR ES:[DI+sf_fcb+fcb_devid],devid_ISDEV   ; can I?
        JZ      ioctl_bad_fun           ; no, it is a file.
        LES     DI,DWORD PTR ES:[DI+sf_fcb+fcb_FIRCLUS]  ;Get device pointer
        XOR     BL,BL           ; Unit number of char dev = 0
        JMP     SHORT ioctl_do_string

ioctl_check_block:
        DEC     AL
        DEC     AL                      ;4=2,5=3,6=4,7=5
        CMP     AL,3
        JBE     ioctl_get_dev

        MOV     AH,1
        SUB     AL,4                    ;6=0,7=1
        JZ      ioctl_get_status
        MOV     AH,3
        DEC     AL
        JNZ     ioctl_bad_fun

ioctl_get_status:
        PUSH    AX
        invoke  GET_IO_FCB
        POP     AX
        JC      ioctl_acc_err
        invoke  IOFUNC
        MOV     AH,AL
        MOV     AL,0FFH
        JNZ     ioctl_status_ret
        INC     AL
ioctl_status_ret:
        transfer SYS_RET_OK

ioctl_bad_fun:
        error   error_invalid_function

ioctl_acc_err:
        error   error_access_denied

ioctl_get_dev:
        PUSH    CX
        PUSH    DX
        PUSH    AX
        PUSH    SI              ;DS in disguise
        MOV     AL,BL           ;Drive
        invoke  GETTHISDRV
        JC      ioctl_bad_drv
        invoke  FATREAD         ;"get" the drive
        MOV     BL,ES:[BP.dpb_UNIT]     ; Unit number
        LES     DI,ES:[BP.dpb_driver_addr]
        CLC                     ;Make sure error jump not taken
ioctl_bad_drv:
        POP     SI
        POP     AX
        POP     DX
        POP     CX
        JC      ioctl_acc_err
ioctl_do_string:
        TEST    ES:[DI.SDEVATT],DEVIOCTL        ;See if device accepts control
        JZ      ioctl_bad_fun                   ;NO
        DEC     AL
        DEC     AL
        JZ      ioctl_control_read
        MOV     [IOCALL.REQFUNC],DEVWRIOCTL
        JMP     SHORT ioctl_control_call
ioctl_control_read:
        MOV     [IOCALL.REQFUNC],DEVRDIOCTL
ioctl_control_call:
        MOV     AL,DRDWRHL
        MOV     AH,BL                           ;Unit number
        MOV     WORD PTR [IOCALL.REQLEN],AX
        XOR     AX,AX
        MOV     [IOCALL.REQSTAT],AX
        MOV     [IOMED],AL
        MOV     [IOSCNT],CX
        MOV     WORD PTR [IOXAD],DX
        MOV     WORD PTR [IOXAD+2],SI
        PUSH    ES
        POP     DS
ASSUME  DS:NOTHING
        MOV     SI,DI                   ;DS:SI -> driver
        PUSH    SS
        POP     ES
        MOV     BX,OFFSET DOSGROUP:IOCALL       ;ES:BX -> Call header
        invoke  DEVIOCALL2
        MOV     AX,[IOSCNT]             ;Get actual bytes transferred
        transfer    SYS_RET_OK

$IOCTL  ENDP

BREAK <File_Times - modify write times on a handle>
;
;   Assembler usage:
;           MOV AH, FileTimes
;           MOV AL, func
;           MOV BX, handle
;       ; if AL = 1 then then next two are mandatory
;           MOV CX, time
;           MOV DX, date
;           INT 21h
;       ; if AL = 0 then CX/DX has the last write time/date
;       ; for the handle.
;
;   Error returns:
;           AX = error_invalid_function
;              = error_invalid_handle
;
procedure   $File_times,near
        CMP     AL,2
        JB      filetimes_ok
        error   error_invalid_function

filetimes_ok:
        PUSH    SS
        POP     DS
        CALL    Get_sf_from_jfn
        JNC     filetimes_disp
        error   error_invalid_handle

filetimes_disp:
        OR      AL,AL
        JNZ     filetimes_set
        MOV     CX,ES:[DI.sf_fcb.fcb_FTIME]
        MOV     DX,ES:[DI.sf_fcb.fcb_FDATE]
        invoke  Get_user_stack
        MOV     [SI.user_CX],CX
        MOV     [SI.user_DX],DX
        transfer    SYS_RET_OK

filetimes_set:
        MOV     ES:[DI.sf_fcb.fcb_FTIME],CX
        MOV     ES:[DI.sf_fcb.fcb_FDATE],DX
        AND     ES:[DI.sf_fcb.fcb_DEVID],NOT devid_file_clean
        transfer    SYS_RET_OK
$file_times ENDP

do_ext

CODE    ENDS
    END
                           