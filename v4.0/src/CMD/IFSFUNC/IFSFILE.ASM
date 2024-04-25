        PAGE    ,132                            ;                                       ;AN000;
;       SCCSID = @(#)ifsfile.asm        1.0 87/05/11                                     ;AN000;
TITLE   IFS FILE ROUTINES - Routines for IFS dispatch                                    ;AN000;
NAME    IFSFILE                                                                          ;AN000;
;************************************************************************************
;
; FILE (WFP_START) related Network calls
;
;   IFS_DISK_INFO
;   IFS_SEQ_SET_FILE_ATTRIBUTE
;   IFS_SET_FILE_ATTRIBUTE
;   IFS_SEQ_GET_FILE_INFO
;   IFS_GET_FILE_INFO
;   IFS_SEQ_RENAME
;   IFS_RENAME
;   IFS_SEQ_DELETE
;   IFS_DELETE
;   IFS_SEQ_OPEN
;   IFS_OPEN
;   IFS_SEQ_CREATE
;   IFS_CREATE
;   IFS_SEQ_XOPEN
;   IFS_XOPEN
;   IFS_SEQ_SEARCH_FIRST
;   IFS_SEQ_SEARCH_NEXT
;   IFS_SEARCH_FIRST
;   IFS_SEARCH_NEXT
;   OPEN_CHECK_SEQ
;
; Programming notes:
;   Old redirector segmentation and DOS interface preserved.
;   Routine prologues are accurate for input/output.
;   However, the pseudocode was not kept up to date.
;   Use it for a rough idea of the routine function.
;
; REVISION HISTORY:
;       A000    Original version 4.00 - May 1987
;       A001    PTM 316 - Fix search next drive byte interpretation
;                         Set drive number in DMAADD
;       A002    PTM 845 - Disk info ignored
;       A003    PTM 869 - Lock failure due to sf_ifs_hdr not set
;       A004    DCR 213 - SFT Serial number
;       A005    PTM 849 - Printer open problems
;       A006    PTM 1518- open mode/flag finalized
;       A007    PTM ????- Action Taken not set on Extended open           10/27 FEIGENBAUM
;       A008    PTM ????- Old Open/Creates pass parms list                10/27 FEIGENBAUM
;       A009    PTM 2247- Delete does not return carry on error           11/3  RG
;       A010    PTM 2248- Old Create mode incorrect - must be 2           11/3  RG
;       A011    DCR 285 - Remove Extended Attribute/Lock support           1/88 RG
;       A012    PTM 3968- set sft time/date on create                     3/25/88 RMG
;       A013            - sft analysis changes                            3/25/88 RMG
;       A014    Austin Deviceless Attach problems                         3/28/88 RMG
;       A015    P4392     SFT change - attr_hi gone                       4/19/88 RMG
;       A016    P4801     File size segment not right                     5/10/88 RMG
;       A017    P????     DS not preserved during CALLBACK                5/13/88 RPS
; LOC - 486
;
;************************************************************************************

.xlist                                                                                   ;AN000;
.xcref                                                                                   ;AN000;
INCLUDE IFSSYM.INC                                                                       ;AN000;
INCLUDE IFSFSYM.INC                                                                      ;AN000;
INCLUDE DOSSYM.INC                                                                       ;AN000;
INCLUDE DEVSYM.INC                                                                       ;AN000;
INCLUDE DOSCNTRY.INC
.cref                                                                                    ;AN000;
.list                                                                                    ;AN000;
                                                                                         ;AN000;
AsmVars <IBM, Installed, DEBUG>                                                          ;AN000;
                                                                                         ;AN000;
; then define the base code segment of the ifsfunc support first                         ;AN000;
                                                                                         ;AN000;
IFSSEG  SEGMENT BYTE PUBLIC 'IFSSEG'                                                     ;AN000;
IFSSEG  ENDS                                                                             ;AN000;
                                                                                         ;AN000;
; include the rest of the segment definitions for normal MSDOS                           ;AN000;
                                                                                         ;AN000;
include dosseg.asm                                                                       ;AN000;
                                                                                         ;AN000;
DATA            SEGMENT WORD PUBLIC 'DATA'                                               ;AN000;
        ;DOSGROUP Data                                                                   ;AN000;
        Extrn   REN_WFP:WORD                                                             ;AN000;
        Extrn   WFP_START:WORD                                                           ;AN000;
        Extrn   SATTRIB:BYTE                                                             ;AN000;
        Extrn   ATTRIB:BYTE                                                              ;AN000;
        Extrn   THISCDS:DWORD                                                            ;AN000;
        Extrn   THISSFT:DWORD                                                            ;AN000;
        Extrn   DMAADD:DWORD                                                             ;AN000;
        Extrn   CDSADDR:DWORD                                                            ;AN000;
        Extrn   SAVE_BX:WORD                                                             ;AN000;
        Extrn   SAVE_CX:WORD                                                             ;AN000;
        Extrn   SAVE_DX:WORD                                                             ;AN000;
        Extrn   SAVE_SI:WORD                                                             ;AN000;
        Extrn   SAVE_DI:WORD                                                             ;AN000;
        Extrn   SAVE_DS:WORD                                                             ;AN000;
        Extrn   SAVE_ES:WORD                                                             ;AN000;
        Extrn   Name1:BYTE                                                               ;AN000;
        Extrn   DEVPT:DWORD                                                              ;AN000;
        Extrn   CPSWFLAG:BYTE
        Extrn   COUNTRY_CDPG:BYTE
if debug                                                                                 ;AN000;
        Extrn   BugLev:WORD                                                              ;AN000;
        Extrn   BugTyp:WORD                                                              ;AN000;
        include bugtyp.asm                                                               ;AN000;
endif                                                                                    ;AN000;
DATA            ENDS                                                                     ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
; define our own code segment                                                            ;AN000;
                                                                                         ;AN000;
IFSSEG  SEGMENT BYTE PUBLIC 'IFSSEG'                                                     ;AN000;
        ASSUME  SS:DOSGROUP,CS:IFSSEG                                                    ;AN000;
                                                                                         ;AN000;
        ;IFS Data                                                                        ;AN000;
        Extrn   IFSR:WORD                                                                ;AN000;
        Extrn   IFSDRV:BYTE                                                              ;AN000;
        Extrn   IFSPROC_FLAGS:WORD                                                       ;AN000;
        Extrn   UNC_FS_HDR:DWORD                                                         ;AN000;
        Extrn   THISIFS:DWORD                                                            ;AN000;
        Extrn   THISDFL:DWORD                                                            ;AN000;
        Extrn   DEVICE_CB@_OFFSET:WORD                                                   ;AN000;
        Extrn   SFT_SERIAL_NUMBER:WORD                                                   ;AN004;
        Extrn   fAssign:BYTE                                                             ;AN014;
                                                                                         ;AN000;
BREAK <IFS_DISK_INFO Get disk Info>                                                      ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_DISK_INFO                                                                          ;AN000;
;                                                                                        ;AN000;
; Input:                                                                                 ;AN000;
;       ES:DI -> CDS  (not NULL)                                                         ;AN000;
;       DS    -> DOSGROUP                                                                ;AN000;
; Function:                                                                              ;AN000;
;     Prep IFSRH:                                                                        ;AN000;
;     *  IFSR_LENGTH      DW     48       ; Total length of request                      ;AN000;
;     *  IFSR_FUNCTION    DB      4       ; Execute API function                         ;AN000;
;      + IFSR_RETCODE     DW      ?                                                      ;AN000;
;      + IFSR_RETCLASS    DB      ?                                                      ;AN000;
;        IFSR_RESV1       DB     16 DUP(0)                                               ;AN000;
;     *  IFSR_APIFUNC     DB      2       ; Disk Attributes                              ;AN000;
;      + IFSR_ERROR_CLASS DB      ?                                                      ;AN000;
;      + IFSR_ERROR_ACTION DB     ?                                                      ;AN000;
;      + IFSR_ERROR_LOCUS DB      ?                                                      ;AN000;
;      + IFSR_ALLOWED     DB      ?                                                      ;AN000;
;      + IFSR_I24_RETRY   DB      ?                                                      ;AN000;
;      + IFSR_I24_RESP    DB      ?                                                      ;AN000;
;        IFSR_RESV2       DB      ?                                                      ;AN000;
;     *+ IFSR_DEVICE_CB@  DD      ?       ; Call CDS_TO_CD to convert CDS to CD          ;AN000;
;                                        ; and set this as pointer to it.                ;AN000;
;        IFSR_OPEN_CB@    DD      ?                                                      ;AN000;
;      + IFSR_ALLOCUNITS  DW      number of allocation units                             ;AN000;
;      + IFSR_ALLOCSIZE   DW      allocation unit sectors                                ;AN000;
;      + IFSR_SECTSIZE    DW      sector size                                            ;AN000;
;      + IFSR_AVAILALLOC  DW      free allocation units                                  ;AN000;
;      + IFSR_FSID        DB      file system media id                                   ;AN000;
;        IFSR_RESV3       DB      0                                                      ;AN000;
;                                                                                        ;AN000;
;     CALL routine, CALL_IFS, with pointer to CURDIR_IFSR_HDR                            ;AN000;
;     IF IFSR_RETCODE = 0 THEN                                                           ;AN000;
;        DO                                                                              ;AN000;
;          Call CD_TO_CDS to update CDS                                                  ;AN000;
;          Set:                                                                          ;AN000;
;             DX = IFSR_AVAILALLOC                                                       ;AN000;
;             BX = IFSR_ALLOCUNITS                                                       ;AN000;
;             CX = IFSR_SECTSIZE                                                         ;AN000;
;             AL = IFSR_ALLOCSIZE                                                        ;AN000;
;             AH = IFSR_FSID                                                             ;AN000;
;          Clear carry                                                                   ;AN000;
;        ENDDO                                                                           ;AN000;
;     ELSE DO                                                                            ;AN000;
;            Put error code in AX                                                        ;AN000;
;            Set carry                                                                   ;AN000;
;          ENDDO                                                                         ;AN000;
;     ENDIF                                                                              ;AN000;
;                                                                                        ;AN000;
; Output:                                                                                ;AN000;
;       DX = Number of free allocation units                                             ;AN000;
;       BX = Total Number of allocation units on disk                                    ;AN000;
;       CX = Sector size                                                                 ;AN000;
;       AL = Sectors per allocation unit                                                 ;AN000;
;       AH = Media ID BYTE                                                               ;AN000;
;       Carry set if error                                                               ;AN000;
;                                                                                        ;AN000;
; Regs: Segs and DI preserved, others destroyed                                          ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_DISK_INFO,NEAR                                                   ;AN000;
ASSUME  DS:DOSGROUP,ES:NOTHING                                                           ;AN000;
                                                                                         ;AN000;
        MOV     AX,DI                           ; set ifsDrv for possible I24            ;AN000;
        invoke  IFSDrvFromCDS                                                            ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                   ; define ifsr for diskattr               ;AN000;
        ifsr_api_def  DISKATTR                                                           ;AN000;
        MOV     CS:IFSPROC_FLAGS,ZERO           ;  & processing flags                    ;AN000;
                                                                                         ;AN000;
        PUSH    ES                              ; set ds:si -> cds                       ;AN000;
        POP     DS                                                                       ;AN000;
        MOV     SI,DI                                                                    ;AN000;
                                                                                         ;AN000;
        invoke  PREP_IFSR                       ; init ifsr                              ;AN000;
        SaveReg <DS,SI>                         ; save for cd_to_cds                     ;AN000;
        MOV     CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@                                     ;AN000;
        invoke  CDS_TO_CD                       ; CDS: sets [THISIFS]                    ;AN000;
                                                ;           ES:BX -> IFSRH               ;AN000;
                                                ;           IFSR_DEVICE_CB@              ;AN000;
                                                ;           ds - IFSSEG                  ;AN000;
        MOV     ES:[BX.IFSR_LENGTH],LENGTH_DISKATTR         ; prep IFSRH                 ;AN000;
        MOV     ES:[BX.IFSR_FUNCTION],IFSEXECAPI                                         ;AN000;
        MOV     ES:[BX.IFSR_APIFUNC],IFSDISKATTR                                         ;AN000;
                                                                                         ;AN000;
        invoke  CALL_IFS                        ; call fs with diskattr request          ;AN000;
                                                                                         ;AN000;
        JNC     DA_20                                                                    ;AN000;
        RestoreReg <DI,ES>                      ; error - restore stack                  ;AN000;
        JMP     FA_1000                         ;         go return                      ;AN000;
DA_20:                                                                                   ;AN000;
        MOV     DX,ES:[BX.IFSR_AVAILALLOC]      ; no error - load return regs            ;AN000;
        MOV     CX,ES:[BX.IFSR_SECTSIZE]                                                 ;AN000;
        MOV     AX,ES:[BX.IFSR_ALLOCSIZE]                                                ;AN000;
        MOV     AH,ES:[BX.IFSR_FSID]                                                     ;AN000;
        MOV     BX,ES:[BX.IFSR_ALLOCUNITS]                                               ;AM002;
        RestoreReg <DI,ES>                      ; restore cds into es:di                 ;AN000;
        invoke  CD_TO_CDS                                                                ;AN000;
        CLC                                                                              ;AN000;
        JMP     FA_1000                         ; go ret in file attr routine            ;AN000;
                                                ; since it restores ds-dosgroup          ;AN000;
                                                                                         ;AN000;
EndProc IFS_DISK_INFO                                                                    ;AN000;
                                                                                         ;AN000;
                                                                                        ;AN000;
BREAK <IFS_SEQ_SET_FILE_ATTRIBUTE  - Seq Set File Attributes>                            ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_SEQ_SET_FILE_ATTRIBUTE                                                             ;AN000;
;                                                                                        ;AN000;
; see IFS_GET_FILE_INFO for details                                                      ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_SEQ_SET_FILE_ATTRIBUTE,NEAR                                      ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                                                            ;AN000;
        ifsr_api_def  FILEATTR                                                           ;AN000;
                                                                                         ;AN000;
        PUSH    AX                              ; save file attrs                        ;AN000;
                                                                                         ;AN000;
        invoke  CHECK_SEQ                       ; check if this is unc or ifs device     ;AN000;
        JC      SA_20                           ; cf=0 unc, cf=1 device                  ;AN000;
                                                                                         ;AN000;
        PUSH    CS                              ; get addressability to IFSSEG           ;AN000;
        POP     DS                              ; prep ifsflags for set                  ;AN000;
ASSUME  DS:IFSSEG                                                                        ;AN000;
        MOV     IFSPROC_FLAGS,ZERO                                                       ;AN000;
        JMP     SHORT SFA_20                    ; cont. in ifs_seq_get_fa                ;AN000;
                                                                                         ;AN000;
EndProc IFS_SEQ_SET_FILE_ATTRIBUTE                                                       ;AN000;
                                                                                         ;AN000;
BREAK <IFS_SET_FILE_ATTRIBUTE      - Set File Attributes>                                ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_SET_FILE_ATTRIBUTE                                                                 ;AN000;
;                                                                                        ;AN000;
; see IFS_GET_FILE_INFO for details                                                      ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_SET_FILE_ATTRIBUTE,NEAR                                          ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                                                            ;AN000;
        ifsr_api_def  FILEATTR                                                           ;AN000;
                                                                                         ;AN000;
        PUSH    AX                              ; save file attrs                        ;AN000;
SA_20:                                                                                   ;AN000;
        MOV     CS:IFSPROC_FLAGS,0              ; prep ifsflags                          ;AN000;
        JMP     SHORT FA_20                     ; cont. in ifs_get_file_info             ;AN000;
                                                                                         ;AN000;
EndProc IFS_SET_FILE_ATTRIBUTE                                                           ;AN000;
                                                                                         ;AN000;
BREAK <IFS_SEQ_GET_FILE_INFO       - Seq Get File Attributes>                            ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_SEQ_GET_FILE_ATTRIBUTE                                                             ;AN000;
;                                                                                        ;AN000;
; see IFS_GET_FILE_INFO for details                                                      ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_SEQ_GET_FILE_INFO,NEAR                                           ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                                                            ;AN000;
        ifsr_api_def  FILEATTR                                                           ;AN000;
                                                                                         ;AN000;
        invoke  CHECK_SEQ                       ; check if this is unc or ifs device     ;AN000;
        JC      FA_10                           ; cf=0 unc, cf=1 device                  ;AN000;
                                                                                         ;AN000;
        PUSH    CS                              ; prep ifsflags for get & seq            ;AN000;
        POP     DS                                                                       ;AN000;
ASSUME  DS:IFSSEG                                                                        ;AN000;
        MOV     IFSPROC_FLAGS,ISGET                                                      ;AN000;
                                                                                         ;AN000;
SFA_20:                                                                                  ;AN000;
        OR      IFSPROC_FLAGS,ISSEQ             ; SEQ - UNC                              ;AN000;
        invoke  SET_THISIFS_UNC                 ; set thisifs = unc                      ;AN000;
        invoke  PREP_IFSR                       ; init ifsr                              ;AN000;
        JMP     SHORT FA_200                    ; cont. in ifs_get_file_info             ;AN000;
                                                                                         ;AN000;
EndProc IFS_SEQ_GET_FILE_INFO                                                            ;AN000;
                                                                                        ;AN000;
BREAK <IFS_GET_FILE_INFO           - Get File Attributes>                                ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; GET_FILE_INFO                                                                          ;AN000;
;                                                                                        ;AN000;
; Routines called:  DFL_SINGLE_FILE_CHECK                                                ;AN000;
;                                                                                        ;AN000;
; Inputs:                                                                                ;AN000;
;       [WFP_START] Points to WFP string ("//" must be first 2 chars, NUL                ;AN000;
;               terminated)                                                              ;AN000;
;       [THISCDS] Points to CDS being used                                               ;AN000;
;               (Low word = -1 if NUL CDS (dfl))                                         ;AN000;
;       [SATTRIB] is attribute of search (determines what files may be found)            ;AN000;
;       AX is new attributes to give to file (already checked for bad bits)              ;AN000;
; Function:                                                                              ;AN000;
;                                                                                        ;AN000;
;     IF seq call THEN                                                                   ;AN000;
;        DO                                                                              ;AN000;
;          Set IFS Header pointer to UNC IFS                                             ;AN000;
;          Set IFSR_DEVICE_CB@ = null                                                    ;AN000;
;        ENDDO                                                                           ;AN000;
;     ELSE DO                                                                            ;AN000;
;            IF [THISCDS] .NOT. NULL THEN                                                ;AN000;
;                 CALL CDS_TO_CD                                                         ;AN000;
;            ELSE DO                                                                     ;AN000;
;                   CALL DFL_SINGLE_FILE_CHECK                                           ;AN000;
;                   IF have DFL that supports single file fcns THEN                      ;AN000;
;                      call DFL_TO_DF                                                    ;AN000;
;                   ELSE set error - device not IFS or no single file support            ;AN000;
;                   ENDIF                                                                ;AN000;
;                 ENDDO                                                                  ;AN000;
;            ENDIF                                                                       ;AN000;
;          ENDDO                                                                         ;AN000;
;     IF  no error  THEN                                                                 ;AN000;
;        DO                                                                              ;AN000;
;          Prep IFSRH:                                                                   ;AN000;
;          *  IFSR_LENGTH      DW     66       ; Total length of request                 ;AN000;
;          *  IFSR_FUNCTION    DB      4       ; Execute API function                    ;AN000;
;           + IFSR_RETCODE     DW      ?                                                 ;AN000;
;           + IFSR_RETCLASS    DB      ?                                                 ;AN000;
;             IFSR_RESV1       DB     16 DUP(0)                                          ;AN000;
;          *  IFSR_APIFUNC     DB     15       ; File Attributes - get/set by name       ;AN000;
;           + IFSR_ERROR_CLASS DB      ?                                                 ;AN000;
;           + IFSR_ERROR_ACTION DB     ?                                                 ;AN000;
;           + IFSR_ERROR_LOCUS DB      ?                                                 ;AN000;
;           + IFSR_ALLOWED     DB      ?                                                 ;AN000;
;           + IFSR_I24_RETRY   DB      ?                                                 ;AN000;
;           + IFSR_I24_RESP    DB      ?                                                 ;AN000;
;             IFSR_RESV2       DB      ?                                                 ;AN000;
;          *+ IFSR_DEVICE_CB@  DD      ?       ; CD/DF                                   ;AN000;
;             IFSR_OPEN_CB@    DD      ?                                                 ;AN000;
;          *  IFSR_FUNC        DB      ?       ; 2=get 3=set depends on INT 2FH          ;AN000;
;          *  IFSR_RESV3       DB      ?
;          *  IFSR_SUBFUNC     DB      0       ; in-line parms                           ;AN000;
;          *  IFSR_RESV4       DB      ?
;             IFSR_BUFFER1@    DD      ?       ; not used here
;             IFSR_BUFFER2@    DD      ?       ; not used here
;             IFSR_COUNT       DW      ?       ; not used here
;          *  IFSR_MATCHATTR   DW      ?       ; format 0000000re0advshr                 ;AN000;
;          *  IFSR_NAME@       DD      ?       ; ASCIIZ file name ptr                    ;AN000;
;           + IFSR_SIZE        DD      ?       ; file size                               ;AN000;
;           + IFSR_DATE        DW      ?       ; file date                               ;AN000;
;           + IFSR_TIME        DW      ?       ; file time                               ;AN000;
;          *+ IFSR_ATTR        DW      ?       ; file attribute                          ;AN000;
;                                              ; format 0000000re0advshr                 ;AN000;
;                                              ; Set to AX on set                        ;AN000;
;                                                                                        ;AN000;
;          IF set THEN                                                                   ;AN000;
;             DO                                                                         ;AN000;
;               IFSR_FUNC = 3                                                            ;AN000;
;               IFSR_ATTR = AX                                                           ;AN000;
;             ENDDO                                                                      ;AN000;
;          ELSE IFSR_FUNC = 2                                                            ;AN000;
;          ENDIF                                                                         ;AN000;
;          CALL routine, CALL_IFS, with pointer to IFS Header                            ;AN000;
;          IF IFSR_RETCODE = 0 THEN                                                      ;AN000;
;             DO                                                                         ;AN000;
;               IF cds THEN Call CD_TO_CDS                                               ;AN000;
;               IF dfl THEN Call DF_TO_DFL                                               ;AN000;
;               IF  get THEN                                                             ;AN000;
;                  DO                                                                    ;AN000;
;                    AX = IFSR_ATTR                                                      ;AN000;
;                    CX = IFSR_TIME                                                      ;AN000;
;                    DX = IFSR_DATE                                                      ;AN000;
;                    BX:DI = IFSR_SIZE                                                   ;AN000;
;                  ENDDO                                                                 ;AN000;
;               Clear carry                                                              ;AN000;
;             ENDDO                                                                      ;AN000;
;          ELSE DO                                                                       ;AN000;
;                 AX = IFSR_RETCODE                                                      ;AN000;
;                 Set carry                                                              ;AN000;
;               ENDDO                                                                    ;AN000;
;          ENDIF                                                                         ;AN000;
;        ENDDO                                                                           ;AN000;
;     ELSE Set carry                                                                     ;AN000;
;     ENDIF                                                                              ;AN000;
; Outputs:                                                                               ;AN000;
;       CARRY CLEAR                                                                      ;AN000;
;           AX    = ATTR                                                                 ;AN000;
;           CX    = TIME                                                                 ;AN000;
;           DX    = DATE                                                                 ;AN000;
;           BX:DI = SIZE                                                                 ;AN000;
;       CARRY SET                                                                        ;AN000;
;           AX is error code                                                             ;AN000;
;               error_file_not_found                                                     ;AN000;
;                       Last element of path not found                                   ;AN000;
;               error_path_not_found                                                     ;AN000;
;                       Bad path (not in curr dir part if present)                       ;AN000;
;               error_access_denied                                                      ;AN000;
;                       Attempt to set an attribute which cannot be set                  ;AN000;
;                       (attr_directory, attr_volume_ID)                                 ;AN000;
;               error_sharing_violation                                                  ;AN000;
;                       Sharing mode of file did not allow the change                    ;AN000;
;                       (this request requires exclusive write/read access)              ;AN000;
;                       (INT 24H generated)                                              ;AN000;
;                                                                                        ;AN000;
; Regs: DS preserved, others destroyed                                                   ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_GET_FILE_INFO,NEAR                                               ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                   ; define ifsr for fileattr               ;AN000;
        ifsr_api_def  FILEATTR                                                           ;AN000;
                                                                                         ;AN000;
FA_10:                                                                                   ;AN000;
        MOV     CS:IFSPROC_FLAGS,ISGET          ;  set for get                           ;AN000;
                                                                                         ;AN000;
FA_20:                                                                                   ;AN000;
ASSUME  DS:DOSGROUP,ES:NOTHING                                                           ;AN000;
        CMP     WORD PTR [THISCDS],NULL_PTR     ; determine CDS or DFL                   ;AN000;
        JE      FA_100                                                                   ;AN000;
        LDS     SI,[THISCDS]                                                             ;AN000;
ASSUME  DS:NOTHING                                                                       ;AN000;
        TEST    CS:IFSPROC_FLAGS,ISGET                                                   ;AN000;
        JZ      FA_40                                                                    ;AN000;
        SaveReg <DS,SI>                         ; preserve ds:si -> cds                  ;AN000;
        JMP     SHORT FA_60                                                              ;AN000;
FA_40:                                                                                   ;AN000;
        RestoreReg <AX>                         ; want attr on stack to stay on top      ;AN000;
        SaveReg <DS,SI,AX>                      ; stack - ax,si,ds                       ;AN000;
                                                                                         ;AN000;
FA_60:                                                                                   ;AN000;
        invoke  PREP_IFSR                       ; clear ifsrh                            ;AN000;
        MOV     CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@                                     ;AN000;
        invoke  CDS_TO_CD                       ; CDS: sets [THISIFS]                    ;AN000;
                                                ;           ES:BX -> IFSRH               ;AN000;
                                                ;           IFSR_DEVICE_CB@              ;AN000;
                                                ;           DS - IFSSEG                  ;AN000;
        OR      IFSPROC_FLAGS,ISCDS                                                      ;AN000;
        JMP     FA_200                                                                   ;AN000;
                                                                                         ;AN000;
FA_100:                                                                                  ;AN000;
        invoke  DFL_SINGLE_FILE_CHECK           ; DFL: sets [THISIFS]                    ;AN000;
                                                ;           ES:BX -> IFSRH               ;AN000;
                                                ;           IFSR_DEVICE_CB@              ;AN000;
                                                ;           DS - IFSSEG                  ;AN000;
        JNC     SHORT FA_200                                                             ;AN000;
        MOV     AX,error_invalid_function       ; error - invalid fcn                    ;AN000;
        invoke  SET_EXTERR_INFO                 ;         set error info &               ;AN000;
        JMP     FA_980                          ;         go return                      ;AN000;
                                                                                         ;AN000;
FA_200:                                                                                  ;AN000;
        invoke  DRIVE_FROM_CDS                  ; set IFSDrv for possible I24            ;AN000;
                                                                                         ;AN000;
        MOV     ES:[BX.IFSR_LENGTH],LENGTH_FILEATTR     ; continue prepping ifsr         ;AN000;
        MOV     ES:[BX.IFSR_FUNCTION],IFSEXECAPI                                         ;AN000;
        MOV     ES:[BX.IFSR_APIFUNC],IFSFILEATTR                                         ;AN000;
        TEST    IFSPROC_FLAGS,ISGET                                                      ;AN000;
        JNZ     FA_220                                                                   ;AN000;
        MOV     ES:[BX.IFSR_FUNC],FUNC_SET_BY_NAME                                       ;AN000;
        POP     ES:[BX.IFSR_ATTR]               ; retrieve attr from stack               ;AN000;
        JMP     SHORT FA_240                                                             ;AN000;
FA_220:                                                                                  ;AN000;
        MOV     ES:[BX.IFSR_FUNC],FUNC_GET_BY_NAME ; get file info                       ;AN000;
                                                                                         ;AN000;
FA_240:                                                                                  ;AN000;
        PUSH    DS                              ; save ds - IFSSEG                       ;AN000;
        PUSH    SS                              ; get ds = dosgroup so can access        ;AN000;
        POP     DS                              ; wfp_start, sattrib                     ;AN000;
ASSUME  DS:DOSGROUP                                                                      ;AN000;
                                                                                         ;AN000;
        MOV     SI,[WFP_START]                                                           ;AN000;
        invoke  STRIP_WFP_START                                                          ;AN000;
        MOV     ES:WORD PTR [BX.IFSR_NAME@],SI  ; ifsr_name@                             ;AN000;
        MOV     ES:WORD PTR [BX.IFSR_NAME@+2],DS                                         ;AN000;
        MOV     AL,[SATTRIB]                                                             ;AN000;
        XOR     AH,AH                                                                    ;AN000;
        MOV     ES:[BX.IFSR_MATCHATTR],AX       ; ifsr_matchattr                         ;AN000;
                                                                                         ;AN000;
        POP     DS                              ; restore ds=IFSSEG                      ;AN000;
ASSUME  DS:IFSSEG                                                                        ;AN000;

;************************************************
        invoke  CALL_IFS                        ; call ifs with file attr request        ;AN000;
;************************************************
                                                                                         ;AN000;
        JNC     FA_260                                                                   ;AN000;
        TEST    IFSPROC_FLAGS,ISCDS             ; request failed -                       ;AN000;
        JZ      FA_980                          ; go set carry & return                  ;AN000;
        ADD     SP,4                            ; if cds, restore stack first            ;AN000;
        JMP     FA_980                                                                   ;AN000;
                                                                                         ;AN000;
FA_260:                                         ; request successful                     ;AN000;
        TEST    IFSPROC_FLAGS,ISGET             ; if get - prep return regs with         ;AN000;
        JZ      FA_270                          ; file info                              ;AN000;
        MOV     AX,ES:[BX.IFSR_ATTR]                                                     ;AN000;
        MOV     CX,ES:[BX.IFSR_TIME]                                                     ;AN000;
        MOV     DX,ES:[BX.IFSR_DATE]                                                     ;AN000;
        MOV     DI,ES:WORD PTR [BX.IFSR_SIZE]                                            ;AN000;
        MOV     BX,ES:WORD PTR [BX.IFSR_SIZE+2]                                          ;AC016;
FA_270:                                                                                  ;AN000;
        TEST    IFSPROC_FLAGS,ISCDS             ; if cds - update cds w/cd               ;AN000;
        JZ      FA_280                                                                   ;AN000;
        RestoreReg <DI,ES>                      ; restore cds ptr into es:di             ;AN000;
        invoke  CD_TO_CDS                       ; cd-cds                                 ;AN000;
        JMP     SHORT FA_990                    ; go clc & return                        ;AN000;
FA_280:                                                                                  ;AN000;
        TEST    IFSPROC_FLAGS,ISSEQ                                                      ;AN000;
        JNZ     FA_990                                                                   ;AN000;
        invoke  DF_TO_DFL                       ; update dfl w/df                        ;AN000;
        JMP     SHORT FA_990                                                             ;AN000;
                                                                                         ;AN000;
FA_980:                                                                                  ;AN000;
        STC                                                                              ;AN000;
        JMP     SHORT FA_1000                                                            ;AN000;
FA_990:                                                                                  ;AN000;
        CLC                                                                              ;AN000;
FA_1000:                                                                                 ;AN000;
        PUSH    SS                              ; restore original ds (dosgroup)         ;AN000;
        POP     DS                              ; since this routine preserves ds        ;AN000;
        return                                                                           ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
EndProc IFS_GET_FILE_INFO                                                                ;AN000;
                                                                                         ;AN000;
BREAK <IFS_SEQ_RENAME Rename>                                                            ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_SEQ_RENAME                                                                         ;AN000;
;                                                                                        ;AN000;
; see ifs_rename for details                                                             ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
        procedure   IFS_SEQ_RENAME,NEAR                                                  ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                                                            ;AN000;
        ifsr_api_def  RENFILE                                                            ;AN000;
                                                                                         ;AN000;
        MOV     CS:IFSPROC_FLAGS,ISREN           ; set for rename and cont.              ;AN000;
        JMP     SHORT SD_10                      ; in ifs_seq_delete                     ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
EndProc IFS_SEQ_RENAME                                                                   ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
BREAK <IFS_RENAME Rename>                                                                ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_RENAME                                                                             ;AN000;
;                                                                                        ;AN000;
; Inputs:                                                                                ;AN000;
;       [WFP_START] Points to SOURCE WFP string ("//" must be first 2                    ;AN000;
;               chars, NUL terminated)                                                   ;AN000;
;       [REN_WFP] Points to DEST WFP string ("//" must be first 2                        ;AN000;
;               chars, NUL terminated)                                                   ;AN000;
;       [THISCDS] Points to CDS being used                                               ;AN000;
;       [SATTRIB] Is attribute of search, determines what files can be found             ;AN000;
; Function:                                                                              ;AN000;
;     same processing as delete except for following parms:                              ;AN000;
;          *  IFSR_LENGTH      DB     48                                                 ;AN000;
;          *  IFSR_APIFUNC     DB      7       ; Rename file                             ;AN000;
;          *  IFSR_NAME1@      DD      ?       ; addr of WFP_START                       ;AN000;
;          *  IFSR_NAME2@      DD      ?       ; addr of REN_WFP                         ;AN000;
;                                                                                        ;AN000;
; Outputs:                                                                               ;AN000;
;       CARRY CLEAR                                                                      ;AN000;
;           OK                                                                           ;AN000;
;       CARRY SET                                                                        ;AN000;
;           AX is error code                                                             ;AN000;
;               error_file_not_found                                                     ;AN000;
;                       No match for source, or dest path invalid                        ;AN000;
;               error_not_same_device                                                    ;AN000;
;                       Source and dest are on different devices                         ;AN000;
;               error_access_denied                                                      ;AN000;
;                       Directory specified (not simple rename),                         ;AN000;
;                       Device name given, Destination exists.                           ;AN000;
;                       NOTE: In third case some renames may have                        ;AN000;
;                        been done if metas.                                             ;AN000;
;               error_path_not_found                                                     ;AN000;
;                       Bad path (not in curr dir part if present)                       ;AN000;
;                       SOURCE ONLY                                                      ;AN000;
;               error_sharing_violation                                                  ;AN000;
;                       Deny both access required, generates an INT 24.                  ;AN000;
; DS preserved, others destroyed                                                         ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_RENAME,NEAR                                                      ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                                                            ;AN000;
        ifsr_api_def  RENFILE                                                            ;AN000;
                                                                                         ;AN000;
        MOV     CS:IFSPROC_FLAGS,ISREN          ; set for rename                         ;AN000;
        JMP     SHORT D_20                      ; processing continues in ifs_delete     ;AN000;
                                                                                         ;AN000;
EndProc IFS_RENAME                                                                       ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
BREAK <IFS_SEQ_DELETE Delete>                                                            ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_SEQ_DELETE                                                                         ;AN000;
;                                                                                        ;AN000;
; see ifs_delete for details                                                             ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
        procedure   IFS_SEQ_DELETE,NEAR                                                  ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                                                            ;AN000;
        ifsr_api_def  DELFILE                                                            ;AN000;
                                                                                         ;AN000;
        MOV     IFSPROC_FLAGS,0                 ; Clear IFS processing flags             ;AN000;
SD_10:                                                                                   ;AN000;
        invoke  CHECK_SEQ                       ; check if this is unc or ifs device     ;AN000;
        JC      D_20                            ; cf=0 unc, cf=1 device                  ;AN000;
                                                                                         ;AN000;
SD_20:                                          ; welcome ifs_seq_rename code            ;AN000;
        PUSH    CS                                                                       ;AN000;
        POP     DS                                                                       ;AN000;
ASSUME  DS:IFSSEG                                                                        ;AN000;
        OR      IFSPROC_FLAGS,ISSEQ             ; SEQ - UNC                              ;AN000;
        invoke  SET_THISIFS_UNC                 ;     set [THISIFS] = UNC IFS            ;AN000;
        JMP     SHORT D_30                      ;     cont. in ifs_delete                ;AN000;
                                                                                         ;AN000;
EndProc IFS_SEQ_DELETE                                                                   ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
BREAK <IFS_DELETE Delete>                                                                ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_DELETE                                                                             ;AN000;
;                                                                                        ;AN000;
; Called by:       IFSFUNC Dispatcher                                                    ;AN000;
;                                                                                        ;AN000;
; Routines called: CDS_TO_CD                                                             ;AN000;
;                  CD_TO_CDS   CALL_IFS                                                  ;AN000;
;                                                                                        ;AN000;
; Inputs:                                                                                ;AN000;
;       [WFP_START] Points to WFP string ("//" must be first 2 chars, NUL                ;AN000;
;               terminated)                                                              ;AN000;
;       [THISCDS] Points to CDS being used                                               ;AN000;
;       [SATTRIB] Is attribute of search, determines what files can be found             ;AN000;
; Function:                                                                              ;AN000;
;     IF INT 2FH call .NOT. SEQ version THEN                                             ;AN000;
;        DO                                                                              ;AN000;
;          IF [THISCDS] .NOT. NULL  THEN                                                 ;AN000;
;             DO                                                                         ;AN000;
;                 CALL CDS_TO_CD                                                         ;AN000;
;                 Set IFS_DEVICE_CB@ as pointer to CD                                    ;AN000;
;                 Set IFS_HDR_PTR = CURDIR_IFS_HDR                                       ;AN000;
;             ENDDO                                                                      ;AN000;
;          ELSE DO                                                                       ;AN000;
;                 Set AX = invalid function                                              ;AN000;
;                 Set extended error info                                                ;AN000;
;               ENDDO                                                                    ;AN000;
;          ENDIF                                                                         ;AN000;
;        ENDDO                                                                           ;AN000;
;     ELSE DO                                                                            ;AN000;
;            Set IFS_DEVICE_CB@ to NULL                                                  ;AN000;
;            Set IFS_HDR_PTR = [UNC_FS_HDR]                                              ;AN000;
;          ENDDO                                                                         ;AN000;
;     ENDIF                                                                              ;AN000;
;     IF  no error  THEN                                                                 ;AN000;
;        DO                                                                              ;AN000;
;          Prep IFSRH:                                                                   ;AN000;
;          *  IFSR_LENGTH      DW     44       ; Total length of request                 ;AN000;
;          *  IFSR_FUNCTION    DB      4       ; Execute API function                    ;AN000;
;           + IFSR_RETCODE     DW      ?                                                 ;AN000;
;           + IFSR_RETCLASS    DB      ?                                                 ;AN000;
;             IFSR_RESV1       DB     16 DUP(0)                                          ;AN000;
;          *  IFSR_APIFUNC     DB      6       ; Delete file                             ;AN000;
;           + IFSR_ERROR_CLASS DB      ?                                                 ;AN000;
;           + IFSR_ERROR_ACTION DB     ?                                                 ;AN000;
;           + IFSR_ERROR_LOCUS DB      ?                                                 ;AN000;
;           + IFSR_ALLOWED     DB      ?                                                 ;AN000;
;           + IFSR_I24_RETRY   DB      ?                                                 ;AN000;
;           + IFSR_I24_RESP    DB      ?                                                 ;AN000;
;             IFSR_RESV2       DB      ?                                                 ;AN000;
;          *+ IFSR_DEVICE_CB@  DD      ?       ; CD                                      ;AN000;
;             IFSR_OPEN_CB@    DD      ?                                                 ;AN000;
;          *  IFSR_MATCHATTR   DW      ?       ; attribute - format 00000000e0a00shr     ;AN000;
;          *  IFSR_NAME@       DD      ?       ; filename to delete                      ;AN000;
;                                                                                        ;AN000;
;          Call routine, CALL_IFS, with pointer to CURDIR_IFSR_HDR                       ;AN000;
;          IF IFSR_RETCODE = 0 THEN                                                      ;AN000;
;             DO                                                                         ;AN000;
;               Call CD_TO_CDS or DF_TO_DFL                                              ;AN000;
;               Clear carry                                                              ;AN000;
;             ENDDO                                                                      ;AN000;
;          ELSE DO                                                                       ;AN000;
;                 AX = IFSR_RETCODE                                                      ;AN000;
;                 Set carry                                                              ;AN000;
;               ENDDO                                                                    ;AN000;
;          ENDIF                                                                         ;AN000;
;        ENDDO                                                                           ;AN000;
;     ELSE set carry                                                                     ;AN000;
;     ENDIF                                                                              ;AN000;
;                                                                                        ;AN000;
; Outputs:                                                                               ;AN000;
;       CARRY CLEAR                                                                      ;AN000;
;               OK                                                                       ;AN000;
;       CARRY SET                                                                        ;AN000;
;           AX is error code                                                             ;AN000;
;               error_file_not_found                                                     ;AN000;
;                       Last element of path not found                                   ;AN000;
;               error_path_not_found                                                     ;AN000;
;                       Bad path                                                         ;AN000;
;               error_access_denied                                                      ;AN000;
;                       Attempt to delete device or directory                            ;AN000;
; DS preserved, others destroyed                                                         ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_DELETE,NEAR                                                      ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                                                            ;AN000;
        ifsr_api_def  DELFILE                                                            ;AN000;
                                                                                         ;AN000;
        MOV     CS:IFSPROC_FLAGS,ZERO           ; Clear IFS processing flags             ;AN000;
                                                                                         ;AN000;
D_20:                                           ; (Welcome ifs_ren)                      ;AN000;
ASSUME  DS:DOSGROUP                                                                      ;AN000;
        invoke  DRIVE_FROM_CDS                  ; ds - dosgroup                          ;AN000;
        CMP     WORD PTR [THISCDS],NULL_PTR     ; CDS must not be null                   ;AN000;
        JNE     D_30                                                                     ;AN000;
        MOV     AX,error_invalid_function                                                ;AN000;
        invoke  SET_EXTERR_INFO                                                          ;AN000;
        JMP     FA_980                          ; go up, preserve ds, ret w/carry        ;AN000;
D_30:                                           ; (Welcome seq ren/del code)             ;AN000;
        invoke  PREP_IFSR                       ; zero ifsr, es:bx -> ifsr               ;AN000;
        MOV     SI,[WFP_START]                                                           ;AN000;
        invoke  STRIP_WFP_START                                                          ;AN000;
        TEST    CS:IFSPROC_FLAGS,ISREN                                                   ;AN000;
        JZ      D_40                            ; rename                                 ;AN000;
        MOV     ES:WORD PTR [BX.IFSR_NAME1@],SI ; ifsr_name1@ & 2@                       ;AN000;
        MOV     ES:WORD PTR [BX.IFSR_NAME1@+2],DS                                        ;AN000;
        MOV     SI,[REN_WFP]                                                             ;AN000;
        CMP     BYTE PTR DS:[SI+1],":"                                                   ;AN000;
        JNE     D_36                                                                     ;AN000;
        ADD     SI,2                                                                     ;AN000;
D_36:                                                                                    ;AN000;
        MOV     ES:WORD PTR [BX.IFSR_NAME2@],SI                                          ;AN000;
        MOV     ES:WORD PTR [BX.IFSR_NAME2@+2],DS                                        ;AN000;
        MOV     ES:[BX.IFSR_LENGTH],LENGTH_RENFILE ; ifsr_length                         ;AN000;
        MOV     ES:[BX.IFSR_APIFUNC],IFSRENFILE    ; ifsr_apifunc                        ;AN000;
        JMP     SHORT D_60                                                               ;AN000;
D_40:                                              ; delete                              ;AN000;
        MOV     ES:WORD PTR [BX.IFSR_NAME@],SI     ; ifsr_name@                          ;AN000;
        MOV     ES:WORD PTR [BX.IFSR_NAME@+2],DS                                         ;AN000;
        MOV     ES:[BX.IFSR_LENGTH],LENGTH_DELFILE ; ifsr_length                         ;AN000;
        MOV     ES:[BX.IFSR_APIFUNC],IFSDELFILE    ; ifsr_apifunc                        ;AN000;
D_60:                                                                                    ;AN000;
        MOV     AL,[SATTRIB]                                                             ;AN000;
        XOR     AH,AH                                                                    ;AN000;
        MOV     ES:[BX.IFSR_MATCHATTR],AX          ; ifsr_matchattr                      ;AN000;
        MOV     ES:[BX.IFSR_FUNCTION],IFSEXECAPI   ; ifsr_function                       ;AN000;
                                                                                         ;AN000;
        TEST    CS:IFSPROC_FLAGS,ISSEQ          ; if unc, don't do cds stuff             ;AN000;
        JNZ     D_70                                                                     ;AN000;
        LDS     SI,[THISCDS]                                                             ;AN000;
ASSUME  DS:NOTHING                                                                       ;AN000;
        SaveReg <DS,SI>                         ; preserve ds:si -> cds                  ;AN000;
        MOV     CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@                                     ;AN000;
        invoke  CDS_TO_CD                       ; CDS: sets [THISIFS]                    ;AN000;
                                                ;           ES:BX -> IFSRH               ;AN000;
                                                ;           IFSR_DEVICE_CB@              ;AN000;
                                                ;           ds - IFSSEG                  ;AN000;
                                                                                         ;AN000;
D_70:                                                                                    ;AN000;
        invoke  CALL_IFS                        ; call ifs w/request                     ;AN000;
                                                                                         ;AN000;
        JNC     D_80                                                                     ;AN000;
        TEST    IFSPROC_FLAGS,ISSEQ             ; fs error - restore stack               ;AN000;
        JZ      D_75                            ; if not unc - go ret                    ;AN000;
        JMP     FA_980                                                                   ;AC009;
D_75:                                                                                    ;AN000;
        ADD     SP,4                                                                     ;AN000;
        JMP     FA_980                                                                   ;AC009;
                                                                                         ;AN000;
D_80:                                                                                    ;AN000;
        TEST    IFSPROC_FLAGS,ISSEQ             ; fs successful                          ;AN000;
        JZ      D_90                            ; if seq, just ret                       ;AN000;
        JMP     FA_990                                                                   ;AN000;
D_90:                                           ; else -                                 ;AN000;
        RestoreReg <DI,ES>                      ; restore cds ptr into es:di             ;AN000;
        invoke  CD_TO_CDS                                                                ;AN000;
        JMP     FA_990                          ; go up & ret in fa to preserve ds       ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
EndProc IFS_DELETE                                                                       ;AN000;
                                                                                         ;AN000;
BREAK <IFS_SEQ_OPEN Open>                                                                ;AN000;
;************************************************************************************    ;AN000;
; see IFS_OPEN for details                                                               ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_SEQ_OPEN,NEAR                                                    ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                   ; define ifsr for open/create            ;AN000;
        ifsr_api_def  OPENFILE                                                           ;AN000;
                                                                                         ;AN000;
        PUSH    AX                              ; save access/share byte                 ;AN000;
                                                                                         ;AN000;
        MOV     CS:IFSPROC_FLAGS,ISOLDOPEN      ; remember this is old open              ;AN000;
        JMP     SHORT SXO_10                    ; cont. in ifs_seq_xopen                 ;AN000;
                                                                                         ;AN000;
EndProc IFS_SEQ_OPEN                                                                     ;AN000;
                                                                                         ;AN000;
BREAK <IFS_OPEN Open>                                                                    ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_OPEN                                                                               ;AN000;
;                                                                                        ;AN000;
; Inputs:                                                                                ;AN000;
;       [WFP_START] Points to WFP string ("//" must be first 2 chars, NUL                ;AN000;
;               terminated)                                                              ;AN000;
;       [THISCDS] Points to CDS being used                                               ;AN000;
;       [THISSFT] Points to SFT to fill in if file found                                 ;AN000;
;               (sf_mode field set so that FCB may be detected)                          ;AN000;
;       ES:DI = [THISSFT]                                                                ;AN000;
;       [SATTRIB] Is attribute of search, determines what files can be found             ;AN000;
;       AX is Access and Sharing mode                                                    ;AN000;
;         High NIBBLE of AL (Sharing Mode)                                               ;AN000;
;               sharing_compat     file is opened in compatibility mode                  ;AN000;
;               sharing_deny_none  file is opened Multi reader, Multi writer             ;AN000;
;               sharing_deny_read  file is opened Only reader, Multi writer              ;AN000;
;               sharing_deny_write file is opened Multi reader, Only writer              ;AN000;
;               sharing_deny_both  file is opened Only reader, Only writer               ;AN000;
;         Low NIBBLE of AL (Access Mode)                                                 ;AN000;
;               open_for_read   file is opened for reading                               ;AN000;
;               open_for_write  file is opened for writing                               ;AN000;
;               open_for_both   file is opened for both reading and writing.             ;AN000;
;                                                                                        ;AN000;
;         For FCB SFTs AL should = -1                                                    ;AN000;
;               (not checked)                                                            ;AN000;
; Function:                                                                              ;AN000;
;     see IFS_XOPEN                                                                      ;AN000;
; Outputs:                                                                               ;AN000;
;       sf_ref_count is NOT altered                                                      ;AN000;
;       CARRY CLEAR                                                                      ;AN000;
;           THISSFT filled in.                                                           ;AN000;
;       CARRY SET                                                                        ;AN000;
;           AX is error code                                                             ;AN000;
;               error_file_not_found                                                     ;AN000;
;                       Last element of path not found                                   ;AN000;
;               error_path_not_found                                                     ;AN000;
;                       Bad path                                                         ;AN000;
;               error_access_denied                                                      ;AN000;
;                       Attempt to open read only file for writting, or                  ;AN000;
;                       open a directory                                                 ;AN000;
;               error_sharing_violation                                                  ;AN000;
;                       The sharing mode was correct but not allowed                     ;AN000;
;                       generates an INT 24 on compatibility mode SFTs                   ;AN000;
; Regs: DS preserved, others destroyed                                                   ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_OPEN,NEAR                                                        ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                   ; define ifsr for open/create            ;AN000;
        ifsr_api_def  OPENFILE                                                           ;AN000;
                                                                                         ;AN000;
        PUSH    AX                              ; save access/share mode                 ;AN000;
                                                                                         ;AN000;
        MOV     CS:IFSPROC_FLAGS,ISOLDOPEN      ; set for old open                       ;AN000;
        JMP     SHORT XO_20                     ; Rest of processing in                  ;AN000;
                                                ; extended open routine.                 ;AN000;
EndProc IFS_Open                                                                         ;AN000;
                                                                                         ;AN000;
BREAK <IFS_SEQ_CREATE Open>                                                              ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_SEQ_CREATE                                                                         ;AN000;
;                                                                                        ;AN000;
; see IFS_CREATE for details                                                             ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_SEQ_CREATE,NEAR                                                  ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                   ; define ifsr for open/create            ;AN000;
        ifsr_api_def  OPENFILE                                                           ;AN000;
                                                                                         ;AN000;
        PUSH    AX                              ; save attribute                         ;AN000;
                                                                                         ;AN000;
        MOV     CS:IFSPROC_FLAGS,IsOldCreate + IsCreate ; remember is old create         ;AN012;
        JMP     SHORT SXO_10                    ; cont. in ifs_seq_xopen                 ;AN000;
                                                                                         ;AN000;
EndProc IFS_SEQ_CREATE                                                                   ;AN000;
                                                                                         ;AN000;
BREAK <IFS_CREATE Create>                                                                ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_CREATE                                                                             ;AN000;
;                                                                                        ;AN000;
; Inputs:                                                                                ;AN000;
;       [WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL               ;AN000;
;               terminated)                                                              ;AN000;
;       [CURR_DIR_END] Points to end of Current dir part of string                       ;AN000;
;               ( = -1 if current dir not involved, else                                 ;AN000;
;                Points to first char after last "/" of current dir part)                ;AN000;
;       [THISCDS] Points to CDS being used                                               ;AN000;
;       [THISSFT] Points to SFT to fill in if file created                               ;AN000;
;               (sf_mode field set so that FCB may be detected)                          ;AN000;
;       ES:DI = [THISSFT]                                                                ;AN000;
;       [SATTRIB] Is attribute of search, determines what files can be found             ;AN000;
;       AL is Attribute to create                                                        ;AN000;
;       AH is 0 if CREATE, non zero if CREATE_NEW                                        ;AN000;
; Function:                                                                              ;AN000;
;       See IFS_XOPEN for details                                                        ;AN000;
; Outputs:                                                                               ;AN000;
;       sf_ref_count is NOT altered                                                      ;AN000;
;       CARRY CLEAR                                                                      ;AN000;
;           THISSFT filled in.                                                           ;AN000;
;               sf_mode = sharing_compat + open_for_both for Non-FCB SFT                 ;AN000;
;       CARRY SET                                                                        ;AN000;
;           AX is error code                                                             ;AN000;
;               error_path_not_found                                                     ;AN000;
;                       Bad path (not in curr dir part if present)                       ;AN000;
;               error_access_denied                                                      ;AN000;
;                       Attempt to re-create read only file , or                         ;AN000;
;                       create a second volume id or create a dir                        ;AN000;
;               error_sharing_violation                                                  ;AN000;
;                       The sharing mode was correct but not allowed                     ;AN000;
;                       generates an INT 24                                              ;AN000;
; Regs: DS preserved, others destroyed                                                   ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_CREATE,NEAR                                                      ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                   ; define ifsr for open/create            ;AN000;
        ifsr_api_def  OPENFILE                                                           ;AN000;
                                                                                         ;AN000;
        PUSH    AX                              ; save attribute                         ;AN000;
                                                                                         ;AN000;
        MOV     CS:IFSPROC_FLAGS,ISOLDCREATE    ; remember is old create                 ;AN000;
        JMP     SHORT XO_20                     ; cont. in ifs_xopen                     ;AN000;
                                                                                         ;AN000;
EndProc IFS_Create                                                                       ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
BREAK <IFS_SEQ_XOPEN Open>                                                               ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_SEQ_XOPEN                                                                          ;AN000;
;                                                                                        ;AN000;
; see IFS_XOPEN for details                                                              ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_SEQ_XOPEN,NEAR                                                   ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                   ; define ifsr for open/create            ;AN000;
        ifsr_api_def  OPENFILE                                                           ;AN000;
                                                                                         ;AN000;
        MOV     IFSPROC_FLAGS,0                 ; Clear IFS processing flags             ;AN000;
SXO_10:                                                                                  ;AN000;
        invoke  CHECK_SEQ                       ; check if this is unc or ifs device     ;AN000;
        JC      XO_20                           ; cf=0 unc, cf=1 device                  ;AN000;
                                                                                         ;AN000;
SXO_20:                                                                                  ;AN000;
        PUSH    CS                              ; ds-ifsseg                              ;AN000;
        POP     DS                                                                       ;AN000;
ASSUME  DS:IFSSEG                                                                        ;AN000;
                                                                                         ;AN000;
        OR      IFSPROC_FLAGS,ISSEQ             ; SEQ = UNC                              ;AN000;
        invoke  SET_THISIFS_UNC                 ; set [THISIFS] = UNC IFS                ;AN000;
        invoke  PREP_IFSR                       ; zero out ifsr                          ;AN000;
        JMP     XO_200                          ; cont. in ifs_xopen                     ;AN000;
                                                                                         ;AN000;
EndProc IFS_SEQ_XOPEN                                                                    ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
BREAK <IFS_XOPEN Open>                                                                   ;AN000;
                                                                                         ;AN000;
;************************************************************************************
;
; IFS_XOPEN
;
; Called by:       IFSFUNC dispatcher
;
; Routines called: CALL_IFS    DFL_MATCH
;                  CD_TO_CDS   DFL_TO_DF
;                  CDS_TO_CD   DF_TO_DFL
;                  SFT_TO_SFF
;                  SF_TO_SFT
;
; Inputs:
;       [THISCDS] Set
;       [THISSFT] Set
;       [SAVE_DX] = FLAG: FUNCTION CONTROL, FORMAT=0000000C NNNN EEEE
;                  C 0=VALIDATE CODE PAGE, 1=NO CODE PAGE CHECK
;                  NNNN=DOES NOT EXIST ACTION:  0=FAIL, 1=CREATE
;                  EEEE=EXISTS ACTION        :  0=FAIL, 1=OPEN, 2=REPLACE/OPEN
;       [SAVE_BX] = MODE  OPEN MODE   FORMAT : 0WF00000ISSS0AAA
;                  AAA = ACCESS CODE: 0=READ, 1=WRITE, 2=READ/WRITE
;                                     3=EXECUTE (UNDOCUMENTED)
;                                     7=FCB     (UNDOCUMENTED)
;                  SSS=SHARING MODE : 0=COMPATIBILITY, 1=DENY READ/WRITE
;                                     2=DENY WRITE, 3=DENY READ,
;                                     4=DENY NONE
;                  I 0=PASS HANDLE TO CHILD, 1=NO INHERIT
;                  F 0=INT 24H, 1=RETURN ERROR
;                  ON THIS OPEN AND ANY IO TO THIS HANDLE
;                  W 0=NO COMMIT, 1=AUTO-COMMIT ON WRITE
;       AX        = ATTR  SEARCH/CREATE ATTRIBUTE
;       [SAVE_DS]:[SAVE_SI] = Full path name
;       [SAVE_ES]:[SAVE_DI] = Parameter list
;                             Null list if DI=-1
;
; Function:
;       IF SEQ THEN
;          prep for UNC
;       ELSE DO
;              IF  [THISCDS] .NOT. NULL  THEN
;                 DO
;                   Call CDS_TO_CD
;                   Set IFSR_DEVICE_CB@ as pointer to CD
;                   Set IFS pointer to CURDIR_IFSR_HDR
;                   DFL_FLAG = 0
;                 ENDDO
;              ELSE DO
;                     Call DFL_TO_DF
;                     Set IFSR_DEVICE_CB@ as pointer to DF
;                     Set IFS pointer to DFL_IFSR_HDR
;                     DFL_FLAG = 1
;                   ENDDO
;              ENDIF
;            ENDDO
;       ENDIF
;       Prep IFSRH:
;       *  IFSR_LENGTH      DW     62       ; Request length
;       *  IFSR_FUNCTION    DB      4       ; Execute API function
;        + IFSR_RETCODE     DW      ?
;        + IFSR_RETCLASS    DB      ?
;          IFSR_RESV1       DB     16 DUP(0)
;       *  IFSR_APIFUNC     DB      9       ; Open/Create File
;        + IFSR_ERROR_CLASS DB      ?
;        + IFSR_ERROR_ACTION DB     ?
;        + IFSR_ERROR_LOCUS DB      ?
;        + IFSR_ALLOWED     DB      ?
;        + IFSR_I24_RETRY   DB      ?
;        + IFSR_I24_RESP    DB      ?
;          IFSR_RESV2       DB      ?
;       *+ IFSR_DEVICE_CB@  DD      ?       ; CD/DF
;       *+ IFSR_OPEN_CB@    DD      ?       ; convert SFT to SFF
;                                           ; and set this as pointer to it.
;       *  IFSR_MODE        DW      ?       ; BX - open mode
;       *  IFSR_FLAG        DW      ?       ; AL
;       *  IFSR_CP          DW      ?       ; Global code page
;       *  IFSR_CPSW        DB      0       ; Code page switch flag
;          IFSR_RESV3       DB      0
;       *  IFSR_NAME@       DD      ?       ; ptr to full asciiz filename
;       *  IFSR_PARMS@      DD      ?       ; ES:DI
;       *  IFSR_MATCHATTR   DW      ?       ; CX
;        + IFSR_ACTION      DW      0       ; Action taken code: 1=file opened
;                                           ; 2=file created/opened
;                                           ; 3=file replaced/opened
;
;       CALL routine, CALL_IFS, with IFS pointer
;       IF IFSR_RETCODE = 0 THEN
;          DO
;            IF DFL_FLAG = 0 THEN
;               Call CD_TO_CDS
;            ELSE  Call DF_TO_DFL
;            Call SF_TO_SFT
;            CX = IFSR_ACTION
;          ENDDO
;       ELSE DO   /* error */
;              AX = IFSR_RETCODE
;              Set carry
;            ENDDO
;       ENDIF
;
; Outputs:
;       CX=ACTION TAKEN CODE
;          1 = FILE OPENED
;          2 = FILE CREATED/OPENED
;          3 = FILE REPLACED/OPENED
;       sf_ref_count is NOT altered
;       THISSFT filled in or updated
;       AX set on error:
;               error_file_not_found
;                       Last element of path not found
;               error_path_not_found
;                       Bad path
;               error_access_denied
;                       Attempt to open read only file for writing,
;                       or open a directory
;               error_sharing_violation
;                       The sharing mode was correct but not allowed
;                       generates an INT 24 on compatibility mode SFTs
; DS preserved, others destroyed
;
;************************************************************************************
                                                                                         ;AN000;
        procedure   IFS_XOPEN,NEAR                                                       ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                   ; define ifsr for open/create            ;AN000;
        ifsr_api_def  OPENFILE                                                           ;AN000;
                                                                                         ;AN000;
        PUSH    AX                              ; srch attr/create attr
        MOV     CS:IFSPROC_FLAGS,ZERO           ; Clear IFS processing flags             ;AN000;
        JMP     SHORT XO_25                                                              ;AN008; BAF
                                                                                         ;AN000;
XO_20:                                          ; (welcome all old open/create calls)    ;AN000;
ASSUME  DS:DOSGROUP                                                                      ;AN000;
        MOV     [SAVE_DI],-1                    ; set no parms list on old calls         ;AN008; BAF
XO_25:                                                                                   ;AN008; BAF
        invoke  PREP_IFSR                       ; zero out ifsr                          ;AN000;
        MOV     CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@                                     ;AN000;
                                                                                         ;AN000;
        LEA     SI,COUNTRY_CDPG                 ; load cp and cpsw                       ;AN000;
        MOV     AX,DS:[SI.ccDosCodePage]        ;      |                                 ;AN000;
        MOV     ES:[BX.IFSR_CP],AX              ;      |                                 ;AN000;
        MOV     AL,[CPSWFLAG]                   ;      |                                 ;AN000;
        MOV     ES:[BX.IFSR_CPSW],AL            ;      |                                 ;AN000;

        CMP     WORD PTR [THISCDS],NULL_PTR     ; determine CDS or DFL                   ;AN000;
        JE      XO_100                                                                   ;AN000;
                                                                                         ;AN000;
        LDS     SI,[THISCDS]                    ; cds--cds--cds--cds--cds--cds           ;AN000;
        MOV     AX,SI                           ; set ifsDrv for possible I24            ;AN000;
        invoke  IFSDrvFromCDS                                                            ;AN000;
        RestoreReg <AX>                         ; must have ax 1st on stack              ;AN000;
        SaveReg <DS,SI,AX>                      ; cds ptr, attr                          ;AN000;
XO_60:                                                                                   ;AN000;
        invoke  CDS_TO_CD                       ; CDS: sets [THISIFS]                    ;AN000;
                                                ;           ES:BX -> IFSRH               ;AN000;
                                                ;           IFSR_DEVICE_CB@              ;AN000;
                                                ;           ds - IFSSEG                  ;AN000;
        OR      IFSPROC_FLAGS,ISCDS                                                      ;AN000;
        JMP     SHORT XO_200                    ; go prep IFSRH                          ;AN000;
                                                                                         ;AN000;
XO_100:                                                                                  ;AN000;
        SaveReg <ES>                            ; if deviceless attach, skip device stuff;AN014;
        LES     DI,CS:[THISDFL]                                                          ;AN014;
        CMP     WORD PTR [THISDFL],NULL_PTR                                              ;AN014;
        RestoreReg <ES>                                                                  ;AN014;
        JNE     XO_110                                                                   ;AN014;
        OR      CS:IFSPROC_FLAGS,IsSeq                                                   ;AN014;
        CMP     CS:[fAssign],ZERO
        JNE     XO_200
        ADD     SP,2
        MOV     AX,72
        JMP     XO_120                                                                   ;AN014;
XO_110:                                                                                  ;AN014;
        invoke  DFL_SINGLE_FILE_CHECK           ; DFL: sets [THISIFS]                    ;AN000;
                                                ;           ES:BX -> IFSRH               ;AN000;
                                                ;           IFSR_DEVICE_CB@              ;AN000;
                                                ;           ds - IFSSEG                  ;AN000;
        JNC     XO_200                                                                   ;AN000;
;;;;;;;;TEST    IFSPROC_FLAGS,ISOLDOPEN+ISOLDCREATE     ; new open also pushes ax        ;AD014;
;;;;;;;;JZ      XO_120                          ;  dfl error                             ;AD014;
        ADD     SP,2                            ;  get saved ax off stack if old         ;AN000;
;XO_120:                                                                                 ;AD014;
        MOV     AX,error_invalid_function       ;  set error info and quit               ;AN000;
XO_120:                                                                                  ;AN014;
        invoke  SET_EXTERR_INFO                                                          ;AN000;
        JMP     FA_980                          ; ret up in FA to preserve DS            ;AN000;
                                                                                         ;AN000;
XO_200:                                         ; (welcome seq open/create)              ;AN000;
        Context DS                              ; get addressability to dosgroup         ;AN000;
        invoke  SFT_TO_SFF                      ; SFT: sets IFSR_OPEN_CB@                ;AN000;
                                                ;           ES:BX -> IFSRH               ;AN000;
                                                ;           ds - IFSSEG                  ;AN000;
        MOV     ES:[BX.IFSR_LENGTH],LENGTH_OPENFILE ; prep IFRH                          ;AN000;
        MOV     ES:[BX.IFSR_FUNCTION],IFSEXECAPI                                         ;AN000;
        MOV     ES:[BX.IFSR_APIFUNC],IFSOPENFILE                                         ;AN000;
        POP     AX                              ; restore input AX              ;AN000;
        TEST    IFSPROC_FLAGS,ISOLDOPEN         ; check for old open/create              ;AN000;
        JZ      XO_220                                                                   ;AN000;
;;;;;;  OR      AX,OLDOPEN_MODE                 ; why did I do this???? scrap            ;AD006;

        SaveReg <DS,SI>                         ; old redirector does this               ;AN013;
        Context DS                                                                       ;AN013;
        LDS     SI,[THISSFT]                                                             ;AN013;
        TEST    DS:[SI.SF_MODE],sf_isFCB                                                 ;AN013;
        RestoreReg <SI,DS>                                                               ;AN013;
        JZ      XO_210                                                                   ;AN013;
        MOV     AL,-1                                                                    ;AN013;
XO_210:                                                                                  ;AN013;

        MOV     ES:[BX.IFSR_MODE],AX                                                     ;AN000;
        MOV     ES:[BX.IFSR_FLAG],OLDOPEN_FLAG                                           ;AN000;
        XOR     AH,AH                                                                    ;AN000;
        JMP     SHORT XO_240                                                             ;AN000;
XO_220:                                                                                  ;AN000;
        TEST    IFSPROC_FLAGS,ISOLDCREATE                                                ;AN000;
        JZ      XO_260                                                                   ;AN000;
        MOV     ES:[BX.IFSR_MODE],OLDCREATE_MODE        ; old create                     ;AC006;AC010;
        MOV     ES:[BX.IFSR_FLAG],OLDCREATE_FLAG                                         ;AN000;
        OR      AH,AH                           ; is this create new??                   ;AN000;
        JZ      XO_230                                                                   ;AN000;
        MOV     ES:[BX.IFSR_FLAG],OLDCREATENEW_FLAG                                      ;AN000;
XO_230:                                                                                  ;AN000;
        XCHG    AH,AL                                                                    ;AN000;
XO_240:                                                                                  ;AN000;
        PUSH    SS                              ; get ds = dosgroup so can access        ;AN000;
        POP     DS                              ; wfp_start                              ;AN000;
ASSUME  DS:DOSGROUP                                                                      ;AN000;
        MOV     AL,[SATTRIB]                                                             ;AN000;
        MOV     ES:[BX.IFSR_MATCHATTR],AX                                                ;AN000;
        JMP     SHORT XO_280                    ; go call FS                             ;AN000;
                                                                                         ;AN000;
XO_260:                                         ; -------extended open/create------------;AN000;
        Context DS                              ; set ds-dosgroup                        ;AN000;
;;;;;;;;PUSH    [SAVE_DX]                                                                ;AD012;
;;;;;;;;POP     ES:[BX.IFSR_FLAG]               ; input dx - flag                        ;AD012;
        SaveReg <AX>                            ; check if create, if so set flag        ;AN012;
        MOV     AX,[SAVE_DX]                                                             ;AN012;
        MOV     ES:[BX.IFSR_FLAG],AX
        MOV     AH,AL                                                                    ;AN012;
        AND     AX,0FF0H                                                                 ;AN012;
        CMP     AL,NOTEXIST_ACT_CREATE*16                                                ;AN012;
        RestoreReg <AX>                                                                  ;AN012;
        JNE     XO_270                                                                   ;AN012;
        OR      IFSPROC_FLAGS,IsCreate                                                   ;AN012;
XO_270:                                                                                  ;AN012;

        PUSH    [SAVE_BX]                                                                ;AN000;
        POP     ES:[BX.IFSR_MODE]               ; input bx - mode                        ;AN000;
        XCHG    AH,AL                           ; attr                                   ;AN000;
        MOV     AL,[SATTRIB]                                                             ;AN000;
        MOV     ES:[BX.IFSR_MATCHATTR],AX                                                ;AN000;
;       MOV     DI,[SAVE_DI]                    ; parm list                              ;AD011;
;       CMP     DI,NULL_PTR                     ;  if offset -1, then no parm list       ;AD011;
;       JE      XO_280                          ;    |                                   ;AD011;
;       MOV     ES:WORD PTR[BX.IFSR_PARMS@],DI  ;    |                                   ;AD011;
;       PUSH    [SAVE_ES]                       ;    |                                   ;AD011;
;       POP     ES:WORD PTR[BX.IFSR_PARMS@+2]   ;    |                                   ;AD011;

XO_280:                                                                                  ;AN000;
        MOV     SI,[WFP_START]                                                           ;AN000;
        invoke  STRIP_WFP_START                                                          ;AN000;
        MOV     WORD PTR ES:[BX.IFSR_NAME@],SI                                           ;AN000;
        MOV     WORD PTR ES:[BX.IFSR_NAME@+2],DS                                         ;AN000;
        PUSH    CS                                                                       ;AN000;
        POP     DS                                                                       ;AN000;
ASSUME  DS:IFSSEG                                                                        ;AN000;
                                                                                         ;AN000;
;******************************************************************************          ;AN000;
        invoke  CALL_IFS                        ; call fs with open/create request       ;AN000;
;******************************************************************************          ;AN000;
                                                                                         ;AN000;
        JNC     XO_300                                                                   ;AN000;
        TEST    IFSPROC_FLAGS,ISCDS             ; request FAILED -                       ;AN000;
        JNZ     XO_290                                                                   ;AN000;
        JMP     FA_980                          ;   go up, set carry & return            ;AN000;
XO_290:                                                                                  ;AN000;
        RestoreReg <SI,DS>                      ;   if cds, restore stack first          ;AN000;
        JMP     FA_980                                                                   ;AN000;
                                                                                         ;AN000;
XO_300:                                         ; request SUCCEEDED -                    ;AN000;
        TEST    IFSPROC_FLAGS,ISOLDOPEN+ISOLDCREATE   ; check for old open/create        ;AN007; BAF
        JNZ     XO_310                                                                   ;AN007; BAF
        SaveReg <DS,SI>                                                                  ;AN007; BAF
        CallInstall Get_User_Stack,multDOS,24   ; Set action take back into CX           ;AN007; BAF                                          ;AN000;
ASSUME  DS:DOSGROUP                                                                      ;AN007; BAF
        MOV     AX,ES:[BX.IFSR_ACTION]          ; action take only if Ext Open           ;AN007; BAF
        MOV     DS:[SI].USER_CX,AX                                                       ;AN007; BAF
        RestoreReg <SI,DS>                                                               ;AN007; BAF
ASSUME  DS:IFSSEG                                                                        ;AN007; BAF
XO_310:                                         ; request SUCCEEDED -                    ;AN007; BAF
        MOV     AX,ES:[BX.IFSR_MATCHATTR]                                                ;AN000;
                                                                                         ;AN000;
        invoke  SFF_TO_SFT                      ;   update sft                           ;AN000;
        TEST    IFSPROC_FLAGS,ISCDS                                                      ;AN000;
        JZ      XO_320                                                                   ;AN000;
        RestoreReg <DI,ES>                      ;   cds-restore cds ptr into es:di       ;AN000;
        invoke  CD_TO_CDS                       ;   update cds                           ;AN000;
        JMP     XO_360                                                                   ;AN000;
XO_320:                                                                                  ;AN000;
        TEST    IFSPROC_FLAGS,ISSEQ                                                      ;AN000;
        JZ      XO_340                                                                   ;AN000;
        MOV     DI,NULL_PTR                     ;   set seq devptr to null               ;AN000;
        SaveReg <DI>                            ;   this for sf_devptr                   ;AN000;
        RestoreReg <ES>                                                                  ;AN000;
        JMP     SHORT XO_360                                                             ;AN000;
                                                                                         ;AN000;
XO_340:                                                                                  ;AN000;
        invoke  DF_TO_DFL                       ;   update dfl                           ;AN000;
        LES     DI,[THISDFL]                    ;   this for sf_devptr                   ;AN000;
        XOR     AX,AX                           ;   attr 0 for devices                   ;AN000;
                                                                                         ;AN000;
XO_360:                                                                                  ;AN000;
        Context DS                                                                       ;AN000;
        LDS     SI,[THISSFT]                    ; set some fields in sft                 ;AN000;
        MOV     DS:[SI.sf_attr],AL                                                       ;AN000;
;;;;;;;;MOV     DS:[SI.sf_attr_hi],AH                                                    ;AD015;
        MOV     WORD PTR DS:[SI.sf_devptr],DI                                            ;AN000;
        MOV     WORD PTR DS:[SI.sf_devptr+2],ES                                          ;AN000;
        TEST    CS:IFSPROC_FLAGS,IsCDS + IsSeq  ; let deviceless attach stuff thru here  ;AC014;
        JZ      XO_380                                                                   ;AN000;
        MOV     AL,CS:[IFSDRV]                  ; drive                                  ;AN000;
        AND     AX,devid_file_mask_drive ; Drive in correct bits                         ;AN000;
        OR      AX,sf_isnet + devid_file_clean                                           ;AN000;
        MOV     DS:[SI.sf_flags],AX                                                      ;AN000;
                                                ; now set sf_name to filename in form:   ;AN000;
                                                ; filename ext  (8 char fn spaced out -  ;AN000;
                                                ; 3 char ext spaced out)                 ;AN000;
        SaveReg <CX,DS,SI,DS>                   ; save dssi->sf for later pop & action   ;AN000;
        RestoreReg <ES>                                                                  ;AN000;
        MOV     DI,SI                           ; esdi->sft                              ;AN000;
                                                                                         ;AN000;
        ADD     DI,sf_name                      ; blank out sf_name                      ;AN000;
        SaveReg <DI>                            ;         |                              ;AN000;
        MOV     AX,2020H                        ;         |                              ;AN000;
        MOV     CX,5                            ;         |                              ;AN000;
        CLD                                     ;         |                              ;AN000;
        REP     STOSW                           ;         |                              ;AN000;
        STOSB                                   ;         |                              ;AN000;
        RestoreReg <DI>                         ;         |                              ;AN000;
                                                                                         ;AN000;
        Context DS                                                                       ;AN000;
        MOV     SI,[WFP_START]                  ; dssi->wfp_start                        ;AN000;
        CallInstall DStrlen,multDOS,37          ; get length of full path name (in cx)   ;AN000;
        ADD     SI,CX                           ; mov si to end of name                  ;AN000;
        DEC     SI                              ; si now on null                         ;AN000;
XO_362:                                                                                  ;AN000;
        DEC     SI                              ; mov back one                           ;AN000;
        CMP     BYTE PTR DS:[SI],"\"            ; looking for \ just before fn           ;AN000;
        JNE     XO_362                                                                   ;AN000;
                                                                                         ;AN000;
        INC     SI                              ; si now pointing to 1st char fn         ;AN000;
        MOV     CX,8                            ; esdi -> sf_name                        ;AN000;
XO_364:                                                                                  ;AN000;
        LODSB                                                                            ;AN000;
        STOSB                                                                            ;AN000;
        DEC     CX                                                                       ;AN000;
        CMP     AL,"."                                                                   ;AN000;
        JE      XO_368                                                                   ;AN000;
        OR      AL,AL                                                                    ;AN000;
        JZ      XO_366                                                                   ;AN000;
        JCXZ    XO_369                                                                   ;AN000;
        JMP     SHORT XO_364                                                             ;AN000;
                                                                                         ;AN000;
XO_366:                                                                                  ;AN000;
        MOV     BYTE PTR ES:[DI-1]," "                                                   ;AN000;
        JMP     SHORT XO_378                                                             ;AN000;
                                                                                         ;AN000;
XO_368:                                                                                  ;AN000;
        MOV     BYTE PTR ES:[DI-1]," "                                                   ;AN000;
        ADD     DI,CX                                                                    ;AN000;
XO_369:                                                                                  ;AN000;
        MOV     CX,3                                                                     ;AN000;
XO_370:                                                                                  ;AN000;
        LODSB                                                                            ;AN000;
        STOSB                                                                            ;AN000;
        DEC     CX                                                                       ;AN000;
        OR      AL,AL                                                                    ;AN000;
        JZ      XO_372                                                                   ;AN000;
        JCXZ    XO_378                                                                   ;AN000;
        JMP     SHORT XO_370                                                             ;AN000;
XO_372:                                                                                  ;AN000;
        MOV     BYTE PTR ES:[DI-1]," "                                                   ;AN000;
                                                                                         ;AN000;
XO_378:                                                                                  ;AN000;
        RestoreReg <SI,DS,CX>           ; dssi -> sft, cx=action code                    ;AN000;
        JMP     SHORT XO_500                                                             ;AN000;
                                                                                         ;AN000;
XO_380:                                                                                  ;AN000;
;;;;;;;;TEST    CS:IFSPROC_FLAGS,ISSEQ                                                   ;AD014;
;;;;;;;;JNZ     XO_500                                                                   ;AD014;
        MOV     DS:[SI.sf_flags],sf_isnet+devid_file_clean+sf_net_spool+devid_device     ;AN000;
        SaveReg <CX,DS,SI>                      ; sft ptr, action                        ;AN003;
        invoke  XCHGP                           ; dssi -> dfl, esdi -> sft               ;AN000;
        ADD     DI,sf_name                                                               ;AN000;
        ADD     SI,DFL_DEV_NAME ; Skip over path sep, now pointing to name               ;AN000;
        MOV     CX,4                                                                     ;AN000;
        REP     MOVSW                                                                    ;AN000;
        MOV     AX,2020H                                                                 ;AN000;
        STOSW                                                                            ;AN000;
        STOSB                                                                            ;AN000;
        RestoreReg <SI,DS,CX>                   ; sft ptr, action                        ;AN003/AC005;

XO_500:                                                                                  ;AN000;
        MOV     AX,WORD PTR CS:[THISIFS]        ; set sf_ifs_hdr                         ;AN003;
        MOV     WORD PTR DS:[SI.SF_IFS_HDR],AX                                           ;AN003;
        MOV     AX,WORD PTR CS:[THISIFS+2]                                               ;AN003;
        MOV     WORD PTR DS:[SI.SF_IFS_HDR+2],AX                                         ;AN003;

        MOV     AX,CS:[SFT_SERIAL_NUMBER]       ; give new sft serial number for         ;AN004;
        MOV     DS:[SI.SF_FIRCLUS],AX           ; fcb processing                         ;AN004;
        INC     CS:[SFT_SERIAL_NUMBER]                                                   ;AN004;

        MOV     WORD PTR DS:[SI.SF_POSITION],0                                           ;AN012;
        MOV     WORD PTR DS:[SI.SF_POSITION+2],0                                         ;AN012;

        TEST    CS:IFSPROC_FLAGS,IsCreate       ; if create, set sf time/date            ;AN012;
        JZ      XO_520                                                                   ;AN012;
        push    ds                              ;AN017: SAVE DS   **RPS
        CallInstall DATE16,MultDOS,13                                                    ;AN012;
        pop     ds                              ;AN017: SAVE DS   **RPS
        MOV     DS:[SI.SF_TIME],DX                                                       ;AN012;
        MOV     DS:[SI.SF_DATE],AX                                                       ;AN012;
        MOV     WORD PTR DS:[SI.SF_SIZE],0                                               ;AN012;
        MOV     WORD PTR DS:[SI.SF_SIZE+2],0                                             ;AN012;
XO_520:                                                                                  ;AN012;

        PUSH    SS                              ; Preserve input DS                      ;AN000;
        POP     DS                                                                       ;AN000;
        MOV     AX,(multDOS SHL 8) OR 12                                                 ;AN000;
        INT     2FH                                                                      ;AN000;
                                                                                         ;AN000;
        return                                                                           ;AN000;
                                                                                         ;AN000;
EndProc IFS_XOPEN                                                                        ;AN000;
                                                                                         ;AN000;
BREAK <IFS_SEQ_SEARCH>                                                                   ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_SEQ_SEARCH                                                                         ;AN000;
;                                                                                        ;AN000;
; Inputs:                                                                                ;AN000;
;       [WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL               ;AN000;
;               terminated)                                                              ;AN000;
;       [SATTRIB] Is attribute of search, determines what files can be found             ;AN000;
;       [DMAADD] Points to 53 byte buffer                                                ;AN000;
; Function:                                                                              ;AN000;
; BECAUSE OF THE STRUCTURE OF SEARCH IT MUST BE RELATIVE TO A CDS SESSION                ;AN000;
; Outputs:                                                                               ;AN000;
;       CARRY SET                                                                        ;AN000;
;           AX = error_path_not_found                                                    ;AN000;
; DS preserved, others destroyed                                                         ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_SEQ_SEARCH_FIRST,NEAR                                            ;AN000;
ASSUME  DS:DOSGROUP,ES:NOTHING                                                           ;AN000;
                                                                                         ;AN000;
        MOV     AX,error_path_not_found                                                  ;AN000;
        STC                                                                              ;AN000;
        return                                                                           ;AN000;
                                                                                         ;AN000;
EndProc IFS_SEQ_SEARCH_FIRST                                                             ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_SEQ_SEARCH_NEXT                                                                    ;AN000;
;                                                                                        ;AN000;
; Inputs:                                                                                ;AN000;
;       [DMAADD] Points to 53 byte buffer returned by DOS_SEARCH_FIRST                   ;AN000;
;           (only first 21 bytes must have valid information)                            ;AN000;
; Function:                                                                              ;AN000;
; BECAUSE OF THE STRUCTURE OF SEARCH IT MUST BE RELATIVE TO A CDS SESSION                ;AN000;
; Outputs:                                                                               ;AN000;
;       CARRY SET                                                                        ;AN000;
;           AX = error_no_more_files                                                     ;AN000;
; DS preserved, others destroyed                                                         ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_SEQ_SEARCH_NEXT,NEAR                                             ;AN000;
ASSUME  DS:DOSGROUP,ES:NOTHING                                                           ;AN000;
                                                                                         ;AN000;
        JMP     IFS_SEQ_SEARCH_FIRST                                                     ;AN000;
                                                                                         ;AN000;
EndProc IFS_SEQ_SEARCH_NEXT                                                              ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
BREAK <IFS_SEARCH_FIRST Search for first entry>                                          ;AN000;
                                                                                         ;AN000;
;************************************************************************************
;
; IFS_SEARCH_FIRST
;
; Inputs:
;       [WFP_START] Points to WFP string ("//" must be first 2 chars, NUL
;               terminated)
;       [THISCDS] Points to CDS being used may not be NUL
;       [SATTRIB] Is attribute of search, determines what files can be found
;       [DMAADD] Points to 53 byte buffer
;       DS - dosgroup
;
; Function:
;     Prep IFSRH:
;     *  IFSR_LENGTH      DW     50             ; Request length
;     *  IFSR_FUNCTION    DB      4             ; Execute API function
;      + IFSR_RETCODE     DW      ?
;      + IFSR_RETCLASS    DB      ?
;        IFSR_RESV1       DB     16 DUP(0)
;     *  IFSR_APIFUNC     DB      8             ; Search file
;      + IFSR_ERROR_CLASS DB      ?
;      + IFSR_ERROR_ACTION DB     ?
;      + IFSR_ERROR_LOCUS DB      ?
;      + IFSR_ALLOWED     DB      ?
;      + IFSR_I24_RETRY   DB      ?
;      + IFSR_I24_RESP    DB      ?
;        IFSR_RESV2       DB      ?
;     *+ IFSR_DEVICE_CB@  DD      ?             ; CD
;        IFSR_OPEN_CB@    DD      ?             ; null
;     *  IFSR_SUBFUNC     DB      subfunction   ; 1=first, 2=next
;                                               ; 4=last (CP/DOS only)
;     *  IFSR_RESV3       DB      ?             ; DOS Reserved
;     *+ IFSR_CONTINFO@   DD      continuation info address (always set):
;     *                          DB      8 DUP(?)   ; SEARCH FILE NAME
;     *                          DB      3 DUP(?)   ; SEARCH FILE EXTENSION
;     *                          DB      ?          ; SEARCH ATTRIBUTE
;                                DB      8 DUP(?)   ; FSDA
;                                 DIRECTORY ENTRY
;      +                         DB      8 DUP(?)   ; FOUND FILE NAME
;      +                         DB      3 DUP(?)   ; FOUND FILE EXTENSION
;      +                         DB      ?          ; FOUND ATTRIBUTE LOW  ??? DB/DD
;      +                         DW      ?          ; FILE CODE PAGE (OR 0)
;      +                         DW      ?          ; RESERVED
;      +                         DB      ?          ; FOUND ATTRIBUTE HIGH
;      +                         DB      5  DUP(?)  ; RESERVED
;      +                         DW      ?          ; FILE TIME
;      +                         DW      ?          ; FILE DATE
;      +                         DW      ?          ; MEANING FILE SYSTEM SPECIFIC
;                                                   ; (STARTING CLUSTER IN FAT)
;      +                         DD      ?          ; FILE SIZE
;  following on search first only
;     *  IFSR_MATCHATTR   DW      ; search attribute  ; format 0000000re0advshr
;     *  IFSR_NAME@       DD      ; asciiz name to process
;
;     IF search first THEN
;        DO
;          IFSR_SUBFUNC = 1
;          Get CDS from [THISCDS]
;          Call CDS_TO_CD
;        ENDDO
;     ELSE DO
;            IFSR_SUBFUNC = 2
;            Get CDS from drive byte in DMAADD
;            Call CDS_TO_CD
;          ENDDO
;     ENDIF
;     CALL routine, CALL_IFS, with pointer to CURDIR_IFSR_HDR
;     IF IFSR_RETCODE = 0 THEN
;        DO
;          Call CD_TO_CDS
;          DMAADD = IFSR_CONTINFO
;          Clear carry
;        ENDDO
;     ELSE DO   {error}
;            AX = error code
;            Set carry
;          ENDDO
;     ENDIF
;
; Outputs:
;       CARRY CLEAR
;           The 53 bytes ot DMAADD are filled in as follows:
;
;           Drive Byte (A=1, B=2, ...) High bit = 1   --|
;           11 byte search name with Meta chars in it   |  From
;           Search Attribute Byte, attribute of search  |  Server
;           WORD LastEnt value                          |
;           WORD DirStart ------------------------------|
;           DWORD Local CDS
;           32 bytes of the directory entry found
;       CARRY SET
;           AX = error code
;               error_no_more_files
;                       No match for this file
;               error_access_denied
;                       Device name given
;               error_path_not_found
;                       Bad path
; DS preserved, others destroyed
;
;************************************************************************************
                                                                                         ;AN000;
        procedure   IFS_SEARCH_FIRST,NEAR                                                ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                   ; define ifsr for search                 ;AN000;
        ifsr_api_def  SEARCHFILE                                                         ;AN000;
                                                                                         ;AN000;
        MOV     CS:IFSPROC_FLAGS,ZERO                                                    ;AN000;
        invoke  PREP_IFSR                       ; zero ifsr                              ;AN000;
                                                                                         ;AN000;
ASSUME  DS:DOSGROUP                                                                      ;AN000;
        LES     DI,[DMAADD]                     ; esdi -> dmaadd                         ;AN001;
        LDS     SI,[THISCDS]                    ; dssi -> cds                            ;AN000;

        invoke  DRIVE_FROM_CDS                  ; set ifsdrv (0-based)                   ;AN001;
        MOV     AL,CS:[IFSDRV]                  ; put 1-based drive # in dmaadd          ;AN001;
        INC     AL                                                                       ;AN001;
        OR      AL,80H                          ; turn on ifs indicator                  ;AN001;
        STOSB                                                                            ;AN001;

        SaveReg <DS,SI>                         ; preserve ds:si -> cds                  ;AN000;
        MOV     CS:DEVICE_CB@_OFFSET,IFSR_DEVICE_CB@                                     ;AN000;
        invoke  CDS_TO_CD                       ; CDS: sets [THISIFS]                    ;AN000;
                                                ;           ES:BX -> IFSRH               ;AN000;
                                                ;           IFSR_DEVICE_CB@              ;AN000;
                                                ;           ds - IFSSEG                  ;AN000;
        PUSH    DS                              ; save ds-ifsseg                         ;AN000;
        Context DS                              ; ds-dosgroup                            ;AN000;
                                                                                         ;AN000;
        MOV     SI,[WFP_START]                                                           ;AN000;
        invoke  STRIP_WFP_START                 ; remove leading d:\ if present          ;AN000;
        MOV     ES:WORD PTR[BX.IFSR_NAME@],SI                                            ;AN000;
        MOV     ES:WORD PTR[BX.IFSR_NAME@+2],DS                                          ;AN000;
        MOV     AL,[SATTRIB]                                                             ;AN000;
        XOR     AH,AH                                                                    ;AN000;
        MOV     ES:[BX.IFSR_MATCHATTR],AX                                                ;AN000;
                                                                                         ;AN000;
        POP     DS                                                                       ;AN000;
ASSUME  DS:IFSSEG,ES:IFSSEG                                                              ;AN000;
                                                                                         ;AN000;
        MOV     AL,IFSSEARCH_FIRST                                                       ;AN000;
        JMP     SHORT SN_60                     ; rest of processing is in               ;AN000;
                                                ; search_next routine                    ;AN000;
                                                                                         ;AN000;
EndProc IFS_SEARCH_FIRST                                                                 ;AN000;
                                                                                        ;AN000;
BREAK <IFS_SEARCH_NEXT Search for next>                                                  ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; IFS_SEARCH_NEXT                                                                        ;AN000;
;                                                                                        ;AN000;
; Inputs:                                                                                ;AN000;
;       [DMAADD] Points to 53 byte buffer returned by DOS_SEARCH_FIRST                   ;AN000;
;           (only first 21 bytes must have valid information)                            ;AN000;
; Function:                                                                              ;AN000;
;       Look for subsequent matches                                                      ;AN000;
; Outputs:                                                                               ;AN000;
;       CARRY CLEAR                                                                      ;AN000;
;           The 53 bytes at DMAADD are updated for next call                             ;AN000;
;               (see NET_SEARCH_FIRST)                                                   ;AN000;
;       CARRY SET                                                                        ;AN000;
;           AX = error code                                                              ;AN000;
;               error_no_more_files                                                      ;AN000;
;                       No more files to find                                            ;AN000;
; DS preserved, others destroyed                                                         ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   IFS_SEARCH_NEXT,NEAR                                                 ;AN000;
ASSUME  DS:DOSGROUP,ES:NOTHING                                                           ;AN000;
                                                                                         ;AN000;
        ifsr_fcn_def  EXECAPI                   ; define ifsr for search                 ;AN000;
        ifsr_api_def  SEARCHFILE                                                         ;AN000;
                                                                                         ;AN000;
        MOV     CS:IFSPROC_FLAGS,ZERO           ; clear processing flags                 ;AN000;
        invoke  PREP_IFSR                       ; zero out ifsr                          ;AN000;
                                                                                         ;AN000;
SN_20:                                                                                   ;AN000;
        LDS     SI,[DMAADD]                                                              ;AN000;
        LODSB                                                                            ;AN000;
        AND     AL,NOT 80H                      ; turn off ifs indicator                 ;AN000;
        DEC     AL                              ; make 0-based                           ;AN000;
        MOV     CS:[IFSDRV],AL                  ; set this for possible i24              ;AN000;
        CallInstall GetCDSFromDrv,multDOS,23,AX,AX                                       ;AN000;
ASSUME  DS:NOTHING                                                                       ;AN000;
        JNC     SN_40                                                                    ;AN000;
        MOV     AX,error_invalid_drive          ;   no cds, set error &                  ;AN000;
        invoke  SET_EXTERR_INFO                                                          ;AN000;
        JMP     FA_1000                         ; ret up in FA to preserve DS            ;AN000;
SN_40:                                          ; (welcome lock)                         ;AN000;
        SaveReg <DS,SI>                         ; save cds ptr                           ;AN000;
        invoke  CDS_TO_CD                       ; CDS: sets [THISIFS]                    ;AN000;
                                                ;           ES:BX -> IFSRH               ;AN000;
                                                ;           IFSR_DEVICE_CB@              ;AN000;
                                                ;           ds - IFSSEG                  ;AN000;
        MOV     AL,IFSSEARCH_NEXT               ; start with subfunc=search next         ;AN000;
;       TEST    IFSPROC_FLAGS,ISADD                                                      ;AD011;
;       JZ      SN_60                                                                    ;AD011;
;       INC     AL                              ; inc subfunc to search same             ;AD011;
SN_60:                                                                                   ;AN000;
        MOV     ES:[BX.IFSR_SUBFUNC],AL                                                  ;AN000;
        MOV     ES:[BX.IFSR_LENGTH],LENGTH_SEARCHFILE                                    ;AN000;
        MOV     ES:[BX.IFSR_FUNCTION],IFSEXECAPI                                         ;AN000;
        MOV     ES:[BX.IFSR_APIFUNC],IFSSEARCHFILE                                       ;AN000;
                                                                                         ;AN000;
        PUSH    DS                                                                       ;AN000;
        Context DS                                                                       ;AN000;
        MOV     AX,WORD PTR [DMAADD]                                                     ;AN000;
        INC     AX                                                                       ;AN000;
        MOV     ES:WORD PTR[BX.IFSR_CONTINFO@],AX                                        ;AN000;
        MOV     AX,WORD PTR [DMAADD+2]                                                   ;AN000;
        MOV     ES:WORD PTR[BX.IFSR_CONTINFO@+2],AX                                      ;AN000;
                                                                                         ;AN000;
        POP     DS                                                                       ;AN000;
ASSUME  DS:IFSSEG                                                                        ;AN000;
        invoke  CALL_IFS                        ; call FS                                ;AN000;
        RestoreReg <DI,ES>                      ; restore cds ptr into es:di             ;AN000;
        JC      SN_1000                                                                  ;AN000;
        invoke  CD_TO_CDS                                                                ;AN000;
        CLC                                                                              ;AN000;
                                                                                         ;AN000;
SN_1000:                                                                                 ;AN000;
        JMP     FA_1000                         ; go up & preserve ds, ret               ;AN000;
                                                                                         ;AN000;
EndProc IFS_SEARCH_NEXT                                                                  ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
BREAK <OPEN_CHECK_DEVICE  - check that device to be opened is real>                      ;AN000;
                                                                                         ;AN000;
;************************************************************************************    ;AN000;
;                                                                                        ;AN000;
; CHECK_OPEN_DEVICE                                                                      ;AN000;
;                                                                                        ;AN000;
; Inputs:                                                                                ;AN000;
;       [WFP_START]                                                                      ;AN000;
;                                                                                        ;AN000;
; Function:                                                                              ;AN000;
;                                                                                        ;AN000;
; Outputs:                                                                               ;AN000;
;                                                                                        ;AN000;
;                                                                                        ;AN000;
;                                                                                        ;AN000;
;************************************************************************************    ;AN000;
                                                                                         ;AN000;
        procedure   OPEN_CHECK_DEVICE,NEAR                                               ;AN000;
ASSUME  DS:DOSGROUP,ES:NOTHING                                                           ;AN000;
                                                                                         ;AN000;
        MOV     SI,[WFP_START]                  ; dssi -> path to open                   ;AN000;
;       invoke  PARSE_DEVICE_PATH               ; dssi -> device name (asciiz)           ;AN000;
                                                                                         ;AN000;
        PUSH    SS                              ; Now check if this device is real       ;AN000;
        POP     ES                                                                       ;AN000;
        MOV     DI,OFFSET DOSGROUP:NAME1                                                 ;AN000;
        MOV     CX,4                                                                     ;AN000;
        REP     MOVSW                           ; Transfer name to NAME1                 ;AN000;
        MOV     AX,2020H                                                                 ;AN000;
        STOSW                                                                            ;AN000;
        STOSB                                                                            ;AN000;
                                                                                         ;AN000;
        PUSH    ES                                                                       ;AN000;
        POP     DS                                                                       ;AN000;
ASSUME  DS:DOSGROUP                                                                      ;AN000;
        MOV     [ATTRIB],attr_hidden + attr_system + attr_directory                      ;AN000;
                                ; Must set this to something interesting                 ;AN000;
                                ; to call DEVNAME.                                       ;AN000;
        CallInstall DEVNAME,multDOS,35                                                   ;AN000;
        JNC     OCD_120                                                                  ;AN000;
        MOV     AX,error_file_not_found                                                  ;AN000;
        transfer ifs_980                                                                 ;AN000;
                                                                                         ;AN000;
OCD_120:                                                                                 ;AN000;
        transfer ifs_990                                                                 ;AN000;
                                                                                         ;AN000;
EndProc OPEN_CHECK_DEVICE                                                                ;AN000;
                                                                                         ;AN000;
                                                                                         ;AN000;
IFSSEG  ENDS                                                                             ;AN000;
    END                                                                                  ;AN000;
