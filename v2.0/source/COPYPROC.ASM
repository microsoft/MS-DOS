TITLE   COPYRPOC             ;Procedures called by COPY

        INCLUDE COMSW.ASM

.xlist
.xcref
        INCLUDE DOSSYM.ASM
        INCLUDE DEVSYM.ASM
        INCLUDE COMSEG.ASM
.list
.cref

        INCLUDE COMEQU.ASM

DATARES SEGMENT PUBLIC
DATARES ENDS

TRANDATA        SEGMENT PUBLIC

        EXTRN   OVERWR:BYTE,FULDIR:BYTE,LOSTERR:BYTE
        EXTRN   DEVWMES:BYTE,INBDEV:BYTE,NOSPACE:BYTE

TRANDATA        ENDS

TRANSPACE       SEGMENT PUBLIC

        EXTRN   CFLAG:BYTE,NXTADD:WORD,DESTCLOSED:BYTE
        EXTRN   PLUS:BYTE,BINARY:BYTE,ASCII:BYTE,FILECNT:WORD
        EXTRN   WRITTEN:BYTE,CONCAT:BYTE,DESTBUF:BYTE,SRCBUF:BYTE
        EXTRN   SDIRBUF:BYTE,DIRBUF:BYTE,DESTFCB:BYTE,MELCOPY:BYTE
        EXTRN   FIRSTDEST:BYTE,DESTISDIR:BYTE,DESTSWITCH:WORD
        EXTRN   DESTTAIL:WORD,DESTINFO:BYTE,INEXACT:BYTE
        EXTRN   DESTVARS:BYTE,SRCINFO:BYTE,RDEOF:BYTE
        EXTRN   USERDIR1:BYTE,NOWRITE:BYTE
        EXTRN   SRCHAND:WORD,CPDATE:WORD,CPTIME:WORD
        EXTRN   SRCISDEV:BYTE,BYTCNT:WORD,TPA:WORD,TERMREAD:BYTE
        EXTRN   DESTHAND:WORD,DESTISDEV:BYTE,DIRCHAR:BYTE

TRANSPACE       ENDS

TRANCODE        SEGMENT PUBLIC BYTE

        PUBLIC  SEARCH,SEARCHNEXT,DOCOPY,CLOSEDEST,FLSHFIL,SETASC
        PUBLIC  BUILDNAME,COPERR

        EXTRN   PRINT:NEAR,BUILDPATH:NEAR,RESTUDIR1:NEAR
        EXTRN   COMPNAME:NEAR,ENDCOPY:NEAR

ASSUME  CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING


SEARCHNEXT:
        MOV     AH,DIR_SEARCH_NEXT
        TEST    [SRCINFO],2
        JNZ     SEARCH                  ; Do serach-next if ambig
        OR      AH,AH                   ; Reset zero flag
        return
SEARCH:
        PUSH    AX
        MOV     AH,SET_DMA
        MOV     DX,OFFSET TRANGROUP:DIRBUF
        INT     int_command             ; Put result of search in DIRBUF
        POP     AX                      ; Restore search first/next command
        MOV     DX,FCB
        INT     int_command             ; Do the search
        OR      AL,AL
        return

DOCOPY:
        mov     [RDEOF],0               ; No EOF yet
        mov     dx,offset trangroup:SRCBUF
        mov     ax,OPEN SHL 8
        INT     int_command
        retc                            ; If open fails, ignore
        mov     bx,ax                   ; Save handle
        mov     [SRCHAND],bx            ; Save handle
        mov     ax,(FILE_TIMES SHL 8)
        INT     int_command
        mov     [CPDATE],dx             ; Save DATE
        mov     [CPTIME],cx             ; Save TIME
        mov     ax,(IOCTL SHL 8)
        INT     int_command             ; Get device stuff
        and     dl,devid_ISDEV
        mov     [SRCISDEV],dl           ; Set source info
        jz      COPYLP                  ; Source not a device
        cmp     [BINARY],0
        jz      COPYLP                  ; ASCII device OK
        mov     dx,offset trangroup:INBDEV  ; Cannot do binary input
        jmp     COPERR

COPYLP:
        mov     bx,[SRCHAND]
        mov     cx,[BYTCNT]
        mov     dx,[NXTADD]
        sub     cx,dx                   ; Compute available space
        jnz     GOTROOM
        call    FLSHFIL
        CMP     [TERMREAD],0
        JNZ     CLOSESRC                ; Give up
        mov     cx,[BYTCNT]
GOTROOM:
        push    ds
        mov     ds,[TPA]
ASSUME  DS:NOTHING
        mov     ah,READ
        INT     int_command
        pop     ds
ASSUME  DS:TRANGROUP
        jc      CLOSESRC                ; Give up if error
        mov     cx,ax                   ; Get count
        jcxz    CLOSESRC                ; No more to read
        cmp     [SRCISDEV],0
        jnz     NOTESTA                 ; Is a device, ASCII mode
        cmp     [ASCII],0
        jz      BINREAD
NOTESTA:
        MOV     DX,CX
        MOV     DI,[NXTADD]
        MOV     AL,1AH
        PUSH    ES
        MOV     ES,[TPA]
        REPNE   SCASB                   ; Scan for EOF
        POP     ES
        JNZ     USEALL
        INC     [RDEOF]
        INC     CX
USEALL:
        SUB     DX,CX
        MOV     CX,DX
BINREAD:
        ADD     CX,[NXTADD]
        MOV     [NXTADD],CX
        CMP     CX,[BYTCNT]             ; Is buffer full?
        JB      TESTDEV                 ; If not, we may have found EOF
        CALL    FLSHFIL
        CMP     [TERMREAD],0
        JNZ     CLOSESRC                ; Give up
        JMP     SHORT COPYLP

TESTDEV:
        cmp     [SRCISDEV],0
        JZ      CLOSESRC                ; If file then EOF
        CMP     [RDEOF],0
        JZ      COPYLP                  ; On device, go till ^Z
CLOSESRC:
        mov     bx,[SRCHAND]
        mov     ah,CLOSE
        INT     int_command
        return

CLOSEDEST:
        cmp     [DESTCLOSED],0
        retnz                           ; Don't double close
        MOV     AL,BYTE PTR [DESTSWITCH]
        CALL    SETASC                  ; Check for B or A switch on destination
        JZ      BINCLOS
        MOV     BX,[NXTADD]
        CMP     BX,[BYTCNT]             ; Is memory full?
        JNZ     PUTZ
        call    TRYFLUSH                ; Make room for one lousy byte
        jz      NOCONC
CONCHNG:                                ; Concat flag changed on us
        stc
        return
NOCONC:
        XOR     BX,BX
PUTZ:
        PUSH    DS
        MOV     DS,[TPA]
        MOV     WORD PTR [BX],1AH       ; Add End-of-file mark (Ctrl-Z)
        POP     DS
        INC     [NXTADD]
        MOV     [NOWRITE],0             ; Make sure our ^Z gets written
        MOV     AL,[WRITTEN]
        XOR     AH,AH
        ADD     AX,[NXTADD]
        JC      BINCLOS                 ; > 1
        CMP     AX,1
        JZ      FORGETIT                ; WRITTEN = 0 NXTADD = 1 (the ^Z)
BINCLOS:
        call    TRYFLUSH
        jnz     CONCHNG
        cmp     [WRITTEN],0
        jz      FORGETIT                ; Never wrote nothin
        MOV     BX,[DESTHAND]
        MOV     CX,[CPTIME]
        MOV     DX,[CPDATE]
        CMP     [INEXACT],0             ; Copy not exact?
        JZ      DODCLOSE                ; If no, copy date & time
        MOV     AH,GET_TIME
        INT     int_command
        SHL     CL,1
        SHL     CL,1                    ; Left justify min in CL
        SHL     CX,1
        SHL     CX,1
        SHL     CX,1                    ; hours to high 5 bits, min to 5-10
        SHR     DH,1                    ; Divide seconds by 2 (now 5 bits)
        OR      CL,DH                   ; And stick into low 5 bits of CX
        PUSH    CX                      ; Save packed time
        MOV     AH,GET_DATE
        INT     int_command
        SUB     CX,1980
        XCHG    CH,CL
        SHL     CX,1                    ; Year to high 7 bits
        SHL     DH,1                    ; Month to high 3 bits
        SHL     DH,1
        SHL     DH,1
        SHL     DH,1
        SHL     DH,1                    ; Most sig bit of month in carry
        ADC     CH,0                    ; Put that bit next to year
        OR      DL,DH                   ; Or low three of month into day
        MOV     DH,CH                   ; Get year and high bit of month
        POP     CX                      ; Get time back
DODCLOSE:
        MOV     AX,(FILE_TIMES SHL 8) OR 1
        INT     int_command             ; Set date and time
        MOV     AH,CLOSE
        INT     int_command
        INC     [FILECNT]
        INC     [DESTCLOSED]
RET50:
        CLC
        return

FORGETIT:
        MOV     BX,[DESTHAND]
        CALL    DODCLOSE                ; Close the dest
        MOV     DX,OFFSET TRANGROUP:DESTBUF
        MOV     AH,UNLINK
        INT     int_command             ; And delete it
        MOV     [FILECNT],0             ; No files transferred
        JMP     RET50

TRYFLUSH:
        mov     al,[CONCAT]
        push    ax
        call    FLSHFIL
        pop     ax
        cmp     al,[CONCAT]
        return

FLSHFIL:
; Write out any data remaining in memory.
; Inputs:
;       [NXTADD] = No. of bytes to write
;       [CFLAG] <>0 if file has been created
; Outputs:
;       [NXTADD] = 0

        MOV     [TERMREAD],0
        cmp     [CFLAG],0
        JZ      NOTEXISTS
        JMP     EXISTS
NOTEXISTS:
        call    BUILDDEST               ; Find out all about the destination
        CALL    COMPNAME                ; Source and dest. the same?
        JNZ     PROCDEST                ; If not, go ahead
        CMP     [SRCISDEV],0
        JNZ     PROCDEST                ; Same name on device OK
        CMP     [CONCAT],0              ; Concatenation?
        MOV     DX,OFFSET TRANGROUP:OVERWR
        JZ      COPERRJ                 ; If not, overwrite error
        MOV     [NOWRITE],1             ; Flag not writting (just seeking)
PROCDEST:
        mov     ax,(OPEN SHL 8) OR 1
        CMP     [NOWRITE],0
        JNZ     DODESTOPEN              ; Don't actually create if NOWRITE set
        mov     ah,CREAT
        xor     cx,cx
DODESTOPEN:
        mov     dx,offset trangroup:DESTBUF
        INT     int_command
        MOV     DX,OFFSET TRANGROUP:FULDIR
        JC      COPERRJ
        mov     [DESTHAND],ax           ; Save handle
        mov     [CFLAG],1               ; Destination now exists
        mov     bx,ax
        mov     ax,(IOCTL SHL 8)
        INT     int_command             ; Get device stuff
        mov     [DESTISDEV],dl          ; Set dest info
        test    dl,devid_ISDEV
        jz      EXISTS                  ; Dest not a device
        mov     al,BYTE PTR [DESTSWITCH]
        AND     AL,ASWITCH+BSWITCH
        JNZ     TESTBOTH
        MOV     AL,[ASCII]              ; Neither set, use current setting
        OR      AL,[BINARY]
        JZ      EXSETA                  ; Neither set, default to ASCII
TESTBOTH:
        JPE     EXISTS                  ; Both are set, ignore
        test    AL,BSWITCH
        jz      EXISTS                  ; Leave in cooked mode
        mov     ax,(IOCTL SHL 8) OR 1
        xor     dh,dh
        or      dl,devid_RAW
        mov     [DESTISDEV],dl          ; New value
        INT     int_command             ; Set device to RAW mode
        jmp     short EXISTS

COPERRJ:
        jmp     SHORT COPERR

EXSETA:
; What we read in may have been in binary mode, flag zapped write OK
        mov     [ASCII],ASWITCH         ; Set ASCII mode
        or      [INEXACT],ASWITCH       ; ASCII -> INEXACT
EXISTS:
        cmp     [NOWRITE],0
        jnz     NOCHECKING              ; If nowrite don't bother with name check
        CALL    COMPNAME                ; Source and dest. the same?
        JNZ     NOCHECKING              ; If not, go ahead
        CMP     [SRCISDEV],0
        JNZ     NOCHECKING              ; Same name on device OK
; At this point we know in append (would have gotten overwrite error on first
; destination create otherwise), and user trying to specify destination which
; has been scribbled already (if dest had been named first, NOWRITE would
; be set).
        MOV     DX,OFFSET TRANGROUP:LOSTERR ; Tell him he's not going to get it
        CALL    PRINT
        MOV     [NXTADD],0              ; Set return
        INC     [TERMREAD]              ; Tell Read to give up
RET60:
        return

NOCHECKING:
        mov     bx,[DESTHAND]           ; Get handle
        XOR     CX,CX
        XCHG    CX,[NXTADD]
        JCXZ    RET60                   ; If Nothing to write, forget it
        INC     [WRITTEN]               ; Flag that we wrote something
        CMP     [NOWRITE],0             ; If NOWRITE set, just seek CX bytes
        JNZ     SEEKEND
        XOR     DX,DX
        PUSH    DS
        MOV     DS,[TPA]
ASSUME  DS:NOTHING
        MOV     AH,WRITE
        INT     int_command
        POP     DS
ASSUME  DS:TRANGROUP
        MOV     DX,OFFSET TRANGROUP:NOSPACE
        JC      COPERR                  ; Failure
        sub     cx,ax
        retz                            ; Wrote all supposed to
        test    [DESTISDEV],devid_ISDEV
        jz      COPERR                  ; Is a file, error
        test    [DESTISDEV],devid_RAW
        jnz     DEVWRTERR               ; Is a raw device, error
        cmp     [INEXACT],0
        retnz                           ; INEXACT so OK
        dec     cx
        retz                            ; Wrote one byte less (the ^Z)
DEVWRTERR:
        MOV     DX,OFFSET TRANGROUP:DEVWMES
COPERR:
        CALL    PRINT
        inc     [DESTCLOSED]
        cmp     [CFLAG],0
        jz      ENDCOPYJ                ; Never actually got it open
        MOV     bx,[DESTHAND]
        MOV     AH,CLOSE                ; Close the file
        INT     int_command
        MOV     DX,OFFSET TRANGROUP:DESTBUF
        MOV     AH,UNLINK
        INT     int_command             ; And delete it
        MOV     [CFLAG],0
ENDCOPYJ:
        JMP   ENDCOPY


SEEKEND:
        xor     dx,dx                   ; Zero high half of offset
        xchg    dx,cx                   ; cx:dx is seek location
        mov     ax,(LSEEK SHL 8) OR 1
        INT     int_command             ; Seek ahead in the file
        cmp     [RDEOF],0
        retz
; If a ^Z has been read we must set the file size to the current
; file pointer location
        MOV     AH,WRITE
        INT     int_command             ; CX is zero, truncates file
        return

SETASC:
; Given switch vector in AX,
;       Set ASCII switch if A is set
;       Clear ASCII switch if B is set
;       BINARY set if B specified
;       Leave ASCII unchanged if neither or both are set
; Also sets INEXACT if ASCII is ever set. AL = ASCII on exit, flags set
        AND     AL,ASWITCH+BSWITCH
        JPE     LOADSW                  ; PE means both or neither are set
        PUSH    AX
        AND     AL,BSWITCH
        MOV     [BINARY],AL
        POP     AX
        AND     AL,ASWITCH
        MOV     [ASCII],AL
        OR      [INEXACT],AL
LOADSW:
        MOV     AL,[ASCII]
        OR      AL,AL
        return

BUILDDEST:
        cmp     [DESTISDIR],-1
        jnz     KNOWABOUTDEST           ; Already done the figuring
        MOV     DI,OFFSET TRANGROUP:USERDIR1
        mov     bp,offset trangroup:DESTVARS
        call    BUILDPATH
        call    RESTUDIR1

; Now know all about the destination

KNOWABOUTDEST:
        xor     al,al
        xchg    al,[FIRSTDEST]
        or      al,al
        jnz     FIRSTDST
        jmp     NOTFIRSTDEST
FIRSTDST:
        mov     si,[DESTTAIL]           ; Create an FCB of the original DEST
        mov     di,offset trangroup:DESTFCB
        mov     ax,PARSE_FILE_DESCRIPTOR SHL 8
        INT     int_command
        mov     ax,word ptr [DESTBUF]   ; Get drive
        cmp     ah,':'
        jz      DRVSPEC4
        mov     al,'@'
DRVSPEC4:
        MOV     CL,[ASCII]              ; Save current ASCII setting
        sub     al,'@'
        mov     [DESTFCB],al
        mov     al,[DESTINFO]
        mov     ah,[SRCINFO]
        and     ax,0202H
        or      al,al
        jz      NOTMELCOPY
        cmp     al,ah
        jnz     NOTMELCOPY
        cmp     [PLUS],0
        jz      NOTMELCOPY
        inc     [MELCOPY]               ; ambig source, ambig dest, and pluses
        xor     al,al
        jmp     short SETCONC

NOTMELCOPY:
        xor     al,2                    ; al=2 if unambig dest, =0 if ambig dest
        and     al,ah
        shr     al,1                    ; al=1 if unambig dest AND ambig sorce
                                        ;   Implies concatination
SETCONC:
        or      al,[PLUS]               ; al=1 if concat
        mov     [CONCAT],al
        shl     al,1
        shl     al,1
        mov     [INEXACT],al            ; Concat -> inexact copy
        cmp     [BINARY],0
        jnz     NOTFIRSTDEST            ; Binary explicitly given, all OK
        mov     [ASCII],al              ; Concat -> ASCII
        or      cl,cl
        jnz     NOTFIRSTDEST            ; ASCII flag set before, DATA read correctly
        or      al,al
        JZ      NOTFIRSTDEST            ; ASCII flag did not change states
; At this point there may already be binary read data in the read buffer.
; We need to find the first ^Z (if there is one) and trim the amount
; of data in the buffer correctly.
        MOV     CX,[NXTADD]
        JCXZ    NOTFIRSTDEST            ; No data, everything OK
        MOV     AL,1AH
        PUSH    ES
        XOR     DI,DI
        MOV     ES,[TPA]
        REPNE   SCASB                   ; Scan for EOF
        POP     ES
        JNZ     NOTFIRSTDEST            ; No ^Z in buffer, everything OK
        DEC     DI                      ; Point at ^Z
        MOV     [NXTADD],DI             ; New buffer
NOTFIRSTDEST:
        mov     bx,offset trangroup:DIRBUF+1    ; Source of replacement chars
        cmp     [CONCAT],0
        jz      GOTCHRSRC               ; Not a concat
        mov     bx,offset trangroup:SDIRBUF+1   ; Source of replacement chars
GOTCHRSRC:
        mov     si,offset trangroup:DESTFCB+1   ; Original dest name
        mov     di,[DESTTAIL]           ; Where to put result

BUILDNAME:
        mov     cx,8
BUILDMAIN:
        lodsb
        cmp     al,"?"
        jnz     NOTAMBIG
        mov     al,byte ptr [BX]
NOTAMBIG:
        cmp     al,' '
        jz      NOSTORE
        stosb
NOSTORE:
        inc     bx
        loop    BUILDMAIN
        mov     cl,3
        cmp     byte ptr [SI],' '
        jz      ENDDEST                 ; No extension
        mov     al,'.'
        stosb
BUILDEXT:
        lodsb
        cmp     al,"?"
        jnz     NOTAMBIGE
        mov     al,byte ptr [BX]
NOTAMBIGE:
        cmp     al,' '
        jz      NOSTOREE
        stosb
NOSTOREE:
        inc     bx
        loop    BUILDEXT
ENDDEST:
        xor     al,al
        stosb                           ; NUL terminate
        return

TRANCODE    ENDS
            END
                                        