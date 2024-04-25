
GENERIC_IOCTL_P PROC
;ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
;³ This routine handles the Generic IOCTL call.  The EMS device driver        ³
;³ provides an interface through the Generic IOCTL call to allocate pages     ³
;³ for the Workstation Program.  Since WSP needs memory off the 'bottom' of   ³
;³ the XMA card in order to bank switch memory, an IOCTL call is needed to    ³
;³ mark these pages as allocated in the Page Allocation Table.                ³
;³                                                                            ³
;³    The pages for EMS are taken from the linked Page Allocation List.       ³
;³ The PAL is initialized from top down, meaning pages that correspond to     ³
;³ the highest physical addresses on the card are at the beginning of the     ³
;³ free list.  Therefore, WSP needs to get the pages from the end of the      ³
;³ free list.                                                                 ³
;³                                                                            ³
;³    Programs may load before WSP and allocate and deallocate pages.         ³
;³ This will work fine for WSP, since these pages will come from the 'top'    ³
;³ using the standard function 43 allocate call.  It will even work if        ³
;³ an application allocates these bottom pages and then deallocates to        ³
;³ the EMS pool, since the deallocated pages are returned to the top of       ³
;³ the free list and linked in reverse order.  The allocates and deallocates  ³
;³ must, however, occur in a stack (LIFO) order or problems will arise.       ³
;³ For example, suppose the system has 30 EMS pages.  Handle A allocs         ³
;³ 20 pages that come from the 'top' of the memory card.  Handle B then       ³
;³ allocs the bottom 10.  Handle A goes counter to LIFO order and deallocs    ³
;³ its 20.  WSP then issues this generic IOCTL call asking for 20 pages.      ³
;³ The pages are available, but they are not from the bottom physical         ³
;³ blocks on the card.  For this we return error code '91'x (see below).      ³
;³                                                                            ³
;³ The call from WSP's loader will be function 0.  No other functions are     ³
;³ supported at this time.  If an error is encountered, the return code       ³
;³ is set in the request packet, but not the device driver header.  The       ³
;³ header error is set by previous versions of the EMS driver that didn't     ³
;³ handle the IOCTL.                                                          ³
;³                                                                            ³
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;³ On entry: ES:BX -> Device driver request header                            ³
;³                                                                            ³
;³ The IOCTL code will set standard EMS return codes in the packet's function ³
;³ field on exit.  These include:                                             ³
;³      '00'x - Good - Requested pages reserved for WSP                       ³
;³      '80'x - Software malfunction in EMS software                          ³
;³      '84'x - Function code passed is not defined                           ³
;³      '87'x - Insufficient total pages to satisfy request                   ³
;³      '88'x - Insufficient free pages to satisfy request                    ³
;³      '89'x - 0 pages requested                                             ³
;³      '90'x - Parameter list has an invalid length (Not an EMS return code) ³
;³      '91'x - Allocated pages do not correspond to                          ³
;³               the 'bottom' blocks of XMA memory   (Not an EMS return code) ³
;³                                                                            ³
;ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾

GIP     EQU     ES:[DI]               ;Pointer to the Generic IOCTL packet @RH6

GEN_IOCTL_PARM  STRUC                 ;                                    @RH6
GIO_PLEN   DW      ?                  ; Length of the parameter list       @RH6
GIO_FCNRC  DW      ?                  ; Function code on call, ret code on ret
GIO_WSPP   DW      ?                  ; Number of pages to reserve for WSP @RH6
GEN_IOCTL_PARM  ENDS                  ;

GENERIC_IOCTL:                        ;                                    @RH6
        PUSH    ES                    ;Save pointer to the request header
        PUSH    BX
        LES     DI,RH.RH19_RQPK       ;Point ES:DI to the Generic IOCTL    @RH6
                                      ; request packet                     @RH6
        PUSH    CS                    ;Set addressability to our data      @RH6
        POP     DS                    ;                                    @RH6
        XOR     AH,AH                 ;Init upper half of user's ret code  @RH6
                        ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
                        ;³ First insure the parameter list is long enough     ³
                        ;³  to input the number of pages needed by WSP        ³
                        ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
        CMP     GIP.GIO_PLEN,4          ;If the length is 4 bytes then OK  @RH6
        JE      GIO_FCN_CHK             ;Else give invalid len ret code    @RH6
        MOV     AL,90h                  ; and error exit                   @RH6
        JMP     GIP_EXIT                ;                                  @RH6
                        ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
                        ;³ Check for function code 0 (only one available)     ³
GIO_FCN_CHK:            ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
        CMP     GIP.GIO_FCNRC,0         ;                                  @RH6
        JE      GIO_REQNOT0_CHK         ;                                  @RH6
        MOV     AL,EMS_CODE84           ;                                  @RH6
        JMP     GIP_EXIT                ;                                  @RH6
                        ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
                        ;³ Parm list is OK.  Attempt to reserve WSP pages.    ³
GIO_REQNOT0_CHK:        ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
        MOV     BX,GIP.GIO_WSPP         ;BX = requested WSP pages          @RH6
        CMP     BX,0                    ;Check that request was not 0      @RH6
        JNE     GIO_NOT0                ;                                  @RH6
        MOV     AL,EMS_CODE89           ;                                  @RH6
        JMP     GIP_EXIT                ;                                  @RH6

GIO_NOT0:                               ;                                  @RH6
        CMP     BX,TOTAL_EMS_PAGES      ;Check for enough total pages      @RH6
        JNA     GIO_OKTOTAL             ;                                  @RH6
        MOV     AL,EMS_CODE87           ;                                  @RH6
        JMP     GIP_EXIT                ;                                  @RH6

                        ;Note: section is not reentrant.  It is possible    RH8
                        ; that between the time FREE_PAGES is loaded and    RH8
                        ; then changed, an EMS allocate or deallocate       RH8
                        ; could occur and hose this up.  However, since     RH8
                        ; WSP is loading at this point, it is unlikely.     RH8
GIO_OKTOTAL:
        CLI                             ;Don't allow other alloc or deall  @RH8
        CMP     BX,FREE_PAGES           ;Check for enough free pages       @RH6
        JNA     GIO_REMOVE_FREE         ; If not enough pages free then    @RH6
        MOV     AX,FREE_PAGES           ;  return number of free in parm   @RH6
        STI                             ;  list and set ret code           @RH8
        MOV     GIP.GIO_WSPP,AX         ;                                  @RH6
        MOV     AL,EMS_CODE88           ;                                  @RH6
        JMP     GIP_EXIT                ;                                  @RH6

                        ;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
                        ;³ Remove WSP pages from the end of the free list     ³
                        ;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
GIO_REMOVE_FREE:
        SUB     FREE_PAGES,BX
        MOV     CX,FREE_PAGES
        MOV     SI,PAL_FREE_PTR
        STI
        SHL     SI,1

        CMP     CX,0                    ;WSP LEAVE NOTHING FREE?
        JNE     GIO_GET_LAST_FREE       ;YES SET FREE PTR TO NULL
        MOV     PAL_FREE_PTR,PAL_NULL
        JMP     SHORT GIO_MARK_WSP


GIO_GET_LAST_FREE:
        DEC     CX
        CMP     CX,0
        JE      GIO_GOT_LAST_FREE
GIO_LAST_FREE_LOOP:
        MOV     SI,PAGE_LIST_ENTRY      ;BASED OFF SI
        SHL     SI,1
        LOOP    GIO_LAST_FREE_LOOP


GIO_GOT_LAST_FREE:
        MOV     AX,PAGE_LIST_ENTRY      ;STORE OFFSET FOR 1ST WSP
        MOV     PAGE_LIST_ENTRY,PAL_NULL ;THEN MAKE IT END OF FREE LIST
        MOV     SI,AX                   ;RESTORE 1ST WSP (TOP)
        SHL     SI,1

GIO_MARK_WSP:
        MOV     CX,BX                   ;LOOPR FOR WSP PAGES
GIO_WSP_LOOP:
        MOV     AX,PAGE_LIST_ENTRY      ;STORE INDEX OF NEXT
        MOV     PAGE_LIST_ENTRY,WSP_ALLOC ;MARK AS WSP
        MOV     SI,AX                   ;RESTOER INEX OF NEXT
        SHL     SI,1
        LOOP    GIO_WSP_LOOP

        XOR     AX,AX                   ;Set good return code

GIP_EXIT:                                                                                 ;GGA

        MOV     GIP.GIO_FCNRC,AX        ;Store ret code in user's req packet
        POP     BX                      ;Restore for ptr to request header @RH6
        POP     ES                      ;                                  @RH6
        MOV     RH.RHC_STA,STAT_DONE    ; Store done status and good return@RH6
                                        ;   code into request header       @RH6
        RET
GENERIC_IOCTL_P ENDP

