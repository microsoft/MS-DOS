TITLE   COMMAND COPY routines.

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
        EXTRN   VERVAL:WORD
DATARES ENDS

TRANDATA        SEGMENT PUBLIC
        EXTRN   BADARGS:BYTE,BADCD:BYTE,BADSWT:BYTE,COPIED_PRE:BYTE
        EXTRN   COPIED_POST:BYTE
        EXTRN   INBDEV:BYTE,OVERWR:BYTE,FULDIR:BYTE,LOSTERR:BYTE
        EXTRN   NOSPACE:BYTE,DEVWMES:BYTE,NOTFND:BYTE
TRANDATA        ENDS

TRANSPACE       SEGMENT PUBLIC
        EXTRN   MELCOPY:BYTE,SRCPT:WORD,MELSTART:WORD,SCANBUF:BYTE
        EXTRN   DESTFCB2:BYTE,SDIRBUF:BYTE,SRCTAIL:WORD,CFLAG:BYTE
        EXTRN   NXTADD:WORD,DESTCLOSED:BYTE,ALLSWITCH:WORD,ARGC:BYTE
        EXTRN   PLUS:BYTE,BINARY:BYTE,ASCII:BYTE,FILECNT:WORD
        EXTRN   WRITTEN:BYTE,CONCAT:BYTE,DESTBUF:BYTE,SRCBUF:BYTE
        EXTRN   SDIRBUF:BYTE,DIRBUF:BYTE,DESTFCB:BYTE,FRSTSRCH:BYTE
        EXTRN   FIRSTDEST:BYTE,DESTISDIR:BYTE,DESTSWITCH:WORD,STARTEL:WORD
        EXTRN   DESTTAIL:WORD,DESTSIZ:BYTE,DESTINFO:BYTE,INEXACT:BYTE
        EXTRN   CURDRV:BYTE,DESTVARS:BYTE,RESSEG:WORD,SRCSIZ:BYTE
        EXTRN   SRCINFO:BYTE,SRCVARS:BYTE,USERDIR1:BYTE,NOWRITE:BYTE
        EXTRN   RDEOF:BYTE,SRCHAND:WORD,CPDATE:WORD,CPTIME:WORD
        EXTRN   SRCISDEV:BYTE,BYTCNT:WORD,TPA:WORD,TERMREAD:BYTE
        EXTRN   DESTHAND:WORD,DESTISDEV:BYTE,DIRCHAR:BYTE
TRANSPACE       ENDS


; **************************************************
; COPY CODE
;

TRANCODE        SEGMENT PUBLIC BYTE

        EXTRN   RESTUDIR:NEAR,CERROR:NEAR,SWITCH:NEAR,DISP32BITS:NEAR
        EXTRN   PRINT:NEAR,TCOMMAND:NEAR,ZPRINT:NEAR,ONESPC:NEAR
        EXTRN   RESTUDIR1:NEAR,FCB_TO_ASCZ:NEAR,CRLF2:NEAR,SAVUDIR1:NEAR
        EXTRN   SETREST1:NEAR,BADCDERR:NEAR,STRCOMP:NEAR,DELIM:NEAR
        EXTRN   UPCONV:NEAR,PATHCHRCMP:NEAR,SCANOFF:NEAR

        EXTRN   CPARSE:NEAR

        EXTRN   SEARCH:NEAR,SEARCHNEXT:NEAR,DOCOPY:NEAR,CLOSEDEST:NEAR
        EXTRN   FLSHFIL:NEAR,SETASC:NEAR,BUILDNAME:NEAR,COPERR:NEAR

        PUBLIC  COPY,BUILDPATH,COMPNAME,ENDCOPY


ASSUME  CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING

DOMELCOPY:
        cmp     [MELCOPY],0FFH
        jz      CONTMEL
        mov     SI,[SRCPT]
        mov     [MELSTART],si
        mov     [MELCOPY],0FFH
CONTMEL:
        xor     BP,BP
        mov     si,[SRCPT]
        mov     bl,'+'
SCANSRC2:
        mov     di,OFFSET TRANGROUP:SCANBUF
        call    CPARSE
        test    bh,80H
        jz      NEXTMEL                 ; Go back to start
        test    bh,1                    ; Switch ?
        jnz     SCANSRC2                ; Yes
        call    SOURCEPROC
        call    RESTUDIR1
        mov     di,OFFSET TRANGROUP:DESTFCB2
        mov     ax,PARSE_FILE_DESCRIPTOR SHL 8
        INT     int_command
        mov     bx,OFFSET TRANGROUP:SDIRBUF + 1
        mov     si,OFFSET TRANGROUP:DESTFCB2 + 1
        mov     di,[SRCTAIL]
        call    BUILDNAME
        jmp     MELDO


NEXTMEL:
        call    CLOSEDEST
        xor     ax,ax
        mov     [CFLAG],al
        mov     [NXTADD],ax
        mov     [DESTCLOSED],al
        mov     si,[MELSTART]
        mov     [SRCPT],si
        call    SEARCHNEXT
        jz      SETNMELJ
        jmp     ENDCOPY2
SETNMELJ:
        jmp     SETNMEL

COPY:
; First order of buisness is to find out about the destination
ASSUME  DS:TRANGROUP,ES:TRANGROUP
        xor     ax,ax
        mov     [ALLSWITCH],AX          ; no switches
        mov     [ARGC],al               ; no arguments
        mov     [PLUS],al               ; no concatination
        mov     [BINARY],al             ; Binary not specifically specified
        mov     [ASCII],al              ; ASCII not specifically specified
        mov     [FILECNT],ax            ; No files yet
        mov     [WRITTEN],al            ; Nothing written yet
        mov     [CONCAT],al             ; No concatination
        mov     [MELCOPY],al            ; Not a Mel Hallerman copy
        mov     word ptr [SCANBUF],ax   ; Init buffer
        mov     word ptr [DESTBUF],ax   ; Init buffer
        mov     word ptr [SRCBUF],ax    ; Init buffer
        mov     word ptr [SDIRBUF],ax   ; Init buffer
        mov     word ptr [DIRBUF],ax    ; Init buffer
        mov     word ptr [DESTFCB],ax   ; Init buffer
        dec     ax
        mov     [FRSTSRCH],al           ; First search call
        mov     [FIRSTDEST],al          ; First time
        mov     [DESTISDIR],al          ; Don't know about dest
        mov     si,81H
        mov     bl,'+'                  ; include '+' as a delimiter
DESTSCAN:
        xor     bp,bp                   ; no switches
        mov     di,offset trangroup:SCANBUF
        call    CPARSE
        PUSHF                           ; save flags
        test    bh,80H                  ; A '+' argument?
        jz      NOPLUS                  ; no
        mov     [PLUS],1                ; yes
NOPLUS:
        POPF                            ; get flags back
        jc      CHECKDONE               ; Hit CR?
        test    bh,1                    ; Switch?
        jz      TESTP2                  ; no
        or      [DESTSWITCH],BP         ; Yes, assume destination
        or      [ALLSWITCH],BP          ; keep tabs on all switches
        jmp     short DESTSCAN

TESTP2:
        test    bh,80H                  ; Plus?
        jnz     GOTPLUS                 ; Yes, not a separate arg
        inc     [ARGC]                  ; found a real arg
GOTPLUS:
        push    SI
        mov     ax,[STARTEL]
        mov     SI,offset trangroup:SCANBUF ; Adjust to copy
        sub     ax,SI
        mov     DI,offset trangroup:DESTBUF
        add     ax,DI
        mov     [DESTTAIL],AX
        mov     [DESTSIZ],cl            ; Save its size
        inc     cx                      ; Include the NUL
        rep     movsb                   ; Save potential destination
        mov     [DESTINFO],bh           ; Save info about it
        mov     [DESTSWITCH],0          ; reset switches
        pop     SI
        jmp     short DESTSCAN          ; keep going

CHECKDONE:
        mov     al,[PLUS]
        mov     [CONCAT],al             ; PLUS -> Concatination
        shl     al,1
        shl     al,1
        mov     [INEXACT],al            ; CONCAT -> inexact copy
        mov     dx,offset trangroup:BADARGS
        mov     al,[ARGC]
        or      al,al                   ; Good number of args?
        jz      CERROR4J                ; no, not enough
        cmp     al,2
        jbe     ACOUNTOK
CERROR4J:
        jmp    CERROR                   ; no, too many
ACOUNTOK:
        mov     bp,offset trangroup:DESTVARS
        cmp     al,1
        jnz     GOT2ARGS
        mov     al,[CURDRV]             ; Dest is default drive:*.*
        add     al,'A'
        mov     ah,':'
        mov     [bp.SIZ],2
        mov     di,offset trangroup:DESTBUF
        stosw
        mov     [DESTSWITCH],0          ; no switches on dest
        mov     [bp.INFO],2             ; Flag dest is ambig
        mov     [bp.ISDIR],0            ; Know destination specs file
        call    SETSTARS
GOT2ARGS:
        cmp     [bp.SIZ],2
        jnz     NOTSHORTDEST
        cmp     [DESTBUF+1],':'
        jnz     NOTSHORTDEST            ; Two char file name
        or      [bp.INFO],2             ; Know dest is d:
        mov     di,offset trangroup:DESTBUF + 2
        mov     [bp.ISDIR],0            ; Know destination specs file
        call    SETSTARS
NOTSHORTDEST:
        mov     di,[bp.TTAIL]
        cmp     byte ptr [DI],0
        jnz     CHKSWTCHES
        mov     dx,offset trangroup:BADCD
        cmp     byte ptr [DI-2],':'
        jnz     CERROR4J               ; Trailing '/' error
        mov     [bp.ISDIR],2           ; Know destination is d:/
        or      [bp.INFO],6
        call    SETSTARS
CHKSWTCHES:
        mov     dx,offset trangroup:BADSWT
        mov     ax,[ALLSWITCH]
        cmp     ax,GOTSWITCH
        jz      CERROR4J                ; Switch specified which is not known

; Now know most of the information needed about the destination

        TEST    AX,VSWITCH              ; Verify requested?
        JZ      NOVERIF                 ; No
        MOV     AH,GET_VERIFY_ON_WRITE
        INT     int_command             ; Get current setting
        PUSH    DS
        MOV     DS,[RESSEG]
ASSUME  DS:RESGROUP
        XOR     AH,AH
        MOV     [VERVAL],AX             ; Save current setting
        POP     DS
ASSUME  DS:TRANGROUP
        MOV     AX,(SET_VERIFY_ON_WRITE SHL 8) OR 1 ; Set verify
        INT     int_command
NOVERIF:
        xor     bp,bp                   ; no switches
        mov     si,81H
        mov     bl,'+'                  ; include '+' as a delimiter
SCANFSRC:
        mov     di,offset trangroup:SCANBUF
        call    CPARSE                  ; Parse first source name
        test    bh,1                    ; Switch?
        jnz     SCANFSRC                ; Yes, try again
        or      [DESTSWITCH],bp         ; Include copy wide switches on DEST
        test    bp,BSWITCH
        jnz     NOSETCASC               ; Binary explicit
        cmp     [CONCAT],0
        JZ      NOSETCASC               ; Not Concat
        mov     [ASCII],ASWITCH         ; Concat -> ASCII copy if no B switch
NOSETCASC:
        push    SI
        mov     ax,[STARTEL]
        mov     SI,offset trangroup:SCANBUF ; Adjust to copy
        sub     ax,SI
        mov     DI,offset trangroup:SRCBUF
        add     ax,DI
        mov     [SRCTAIL],AX
        mov     [SRCSIZ],cl             ; Save its size
        inc     cx                      ; Include the NUL
        rep     movsb                   ; Save this source
        mov     [SRCINFO],bh            ; Save info about it
        pop     SI
        mov     ax,bp                   ; Switches so far
        call    SETASC                  ; Set A,B switches accordingly
        call    SWITCH                  ; Get any more switches on this arg
        call    SETASC                  ; Set
        call    FRSTSRC
        jmp     FIRSTENT

ENDCOPY:
        CALL    CLOSEDEST
ENDCOPY2:
        MOV     DX,OFFSET TRANGROUP:COPIED_PRE
        CALL    PRINT
        MOV     SI,[FILECNT]
        XOR     DI,DI
        CALL    DISP32BITS
        MOV     DX,OFFSET TRANGROUP:COPIED_POST
        CALL    PRINT
        JMP     TCOMMAND                ; Stack could be messed up

SRCNONEXIST:
        cmp     [CONCAT],0
        jnz     NEXTSRC                 ; If in concat mode, ignore error
        mov     dx,offset trangroup:SRCBUF
        call    zprint
        CALL    ONESPC
        mov     dx,offset trangroup:NOTFND
        jmp     COPERR

SOURCEPROC:
        push    SI
        mov     ax,[STARTEL]
        mov     SI,offset trangroup:SCANBUF ; Adjust to copy
        sub     ax,SI
        mov     DI,offset trangroup:SRCBUF
        add     ax,DI
        mov     [SRCTAIL],AX
        mov     [SRCSIZ],cl             ; Save its size
        inc     cx                      ; Include the NUL
        rep     movsb                   ; Save this sorce
        mov     [SRCINFO],bh            ; Save info about it
        pop     SI
        mov     ax,bp                   ; Switches so far
        call    SETASC                  ; Set A,B switches accordingly
        call    SWITCH                  ; Get any more switches on this arg
        call    SETASC                  ; Set
        cmp     [CONCAT],0
        jnz     LEAVECFLAG              ; Leave CFLAG if concatination
FRSTSRC:
        xor     ax,ax
        mov     [CFLAG],al              ; Flag destination not created
        mov     [NXTADD],ax             ; Zero out buffer
        mov     [DESTCLOSED],al         ; Not created -> not closed
LEAVECFLAG:
        mov     [SRCPT],SI              ; remember where we are
        mov     di,offset trangroup:USERDIR1
        mov     bp,offset trangroup:SRCVARS
        call    BUILDPATH               ; Figure out everything about the source
        mov     si,[SRCTAIL]            ; Create the search FCB
        return

NEXTSRC:
        cmp     [PLUS],0
        jnz     MORECP
ENDCOPYJ2:
        jmp     ENDCOPY                 ; Done
MORECP:
        xor     bp,bp                   ; no switches
        mov     si,[SRCPT]
        mov     bl,'+'                  ; include '+' as a delimiter
SCANSRC:
        mov     di,offset trangroup:SCANBUF
        call    CPARSE                  ; Parse first source name
        JC      EndCopyJ2               ; if error, then end (trailing + case)
        test    bh,80H
        jz      ENDCOPYJ2               ; If no '+' we're done
        test    bh,1                    ; Switch?
        jnz     SCANSRC                 ; Yes, try again
        call    SOURCEPROC
FIRSTENT:
        mov     di,FCB
        mov     ax,PARSE_FILE_DESCRIPTOR SHL 8
        INT     int_command
        mov     ax,word ptr [SRCBUF]    ; Get drive
        cmp     ah,':'
        jz      DRVSPEC1
        mov     al,'@'
DRVSPEC1:
        sub     al,'@'
        mov     ds:[FCB],al
        mov     ah,DIR_SEARCH_FIRST
        call    SEARCH
        pushf                           ; Save result of search
        call    RESTUDIR1               ; Restore users dir
        popf
        jz      NEXTAMBIG0
        jmp     SRCNONEXIST             ; Failed
NEXTAMBIG0:
        xor     al,al
        xchg    al,[FRSTSRCH]
        or      al,al
        jz      NEXTAMBIG
SETNMEL:
        mov     cx,12
        mov     di,OFFSET TRANGROUP:SDIRBUF
        mov     si,OFFSET TRANGROUP:DIRBUF
        rep     movsb                   ; Save very first source name
NEXTAMBIG:
        xor     al,al
        mov     [NOWRITE],al            ; Turn off NOWRITE
        mov     di,[SRCTAIL]
        mov     si,offset trangroup:DIRBUF + 1
        call    FCB_TO_ASCZ             ; SRCBUF has complete name
MELDO:
        cmp     [CONCAT],0
        jnz     SHOWCPNAM               ; Show name if concat
        test    [SRCINFO],2             ; Show name if multi
        jz      DOREAD
SHOWCPNAM:
        mov     dx,offset trangroup:SRCBUF
        call    ZPRINT
        call    CRLF2
DOREAD:
        call    DOCOPY
        cmp     [CONCAT],0
        jnz     NODCLOSE                ; If concat, do not close
        call    CLOSEDEST               ; else close current destination
        jc      NODCLOSE                ; Concat flag got set, close didn't really happen
        mov     [CFLAG],0               ; Flag destination not created
NODCLOSE:
        cmp     [CONCAT],0              ; Check CONCAT again
        jz      NOFLUSH
        CALL    FLSHFIL                 ; Flush output between source files on CONCAT
                                        ;  so LOSTERR stuff works correctly
        TEST    [MELCOPY],0FFH
        jz      NOFLUSH
        jmp     DOMELCOPY

NOFLUSH:
        call    SEARCHNEXT              ; Try next match
        jnz     NEXTSRCJ                ; Finished with this source spec
        mov     [DESTCLOSED],0          ; Not created or concat -> not closed
        jmp     NEXTAMBIG               ; Do next ambig

NEXTSRCJ:
        jmp   NEXTSRC



BUILDPATH:
        test    [BP.INFO],2
        jnz     NOTPFILE                ; If ambig don't bother with open
        mov     dx,bp
        add     dx,BUF                  ; Set DX to spec
        mov     ax,OPEN SHL 8
        INT     int_command
        jc      NOTPFILE
        mov     bx,ax                   ; Is pure file
        mov     ax,IOCTL SHL 8
        INT     int_command
        mov     ah,CLOSE
        INT     int_command
        test    dl,devid_ISDEV
        jnz     ISADEV                  ; If device, done
        test    [BP.INFO],4
        jz      ISSIMPFILE              ; If no path seps, done
NOTPFILE:
        mov     dx,word ptr [BP.BUF]
        cmp     dh,':'
        jz      DRVSPEC5
        mov     dl,'@'
DRVSPEC5:
        sub     dl,'@'                  ; A = 1
        call    SAVUDIR1
        mov     dx,bp
        add     dx,BUF                  ; Set DX for upcomming CHDIRs
        mov     bh,[BP.INFO]
        and     bh,6
        cmp     bh,6                    ; Ambig and path ?
        jnz     CHECKAMB                ; jmp if no
        mov     si,[BP.TTAIL]
        cmp     byte ptr [si-2],':'
        jnz     KNOWNOTSPEC
        mov     [BP.ISDIR],2            ; Know is d:/file
        jmp     short DOPCDJ

KNOWNOTSPEC:
        mov     [BP.ISDIR],1            ; Know is path/file
        dec     si                      ; Point to the /
DOPCDJ:
        jmp     short DOPCD

CHECKAMB:
        cmp     bh,2
        jnz     CHECKCD
ISSIMPFILE:
ISADEV:
        mov     [BP.ISDIR],0            ; Know is file since ambig but no path
        return

CHECKCD:
        call    SETREST1
        mov     ah,CHDIR
        INT     int_command
        jc      NOTPDIR
        mov     di,dx
        xor     ax,ax
        mov     cx,ax
        dec     cx
        repne   scasb
        dec     di
        mov     al,[DIRCHAR]
        mov     [bp.ISDIR],2            ; assume d:/file
        cmp     al,[di-1]
        jz      GOTSRCSLSH
        stosb
        mov     [bp.ISDIR],1            ; know path/file
GOTSRCSLSH:
        or      [bp.INFO],6
        call    SETSTARS
        return


NOTPDIR:
        mov     [bp.ISDIR],0            ; assume pure file
        mov     bh,[bp.INFO]
        test    bh,4
        retz                            ; Know pure file, no path seps
        mov     [bp.ISDIR],2            ; assume d:/file
        mov     si,[bp.TTAIL]
        cmp     byte ptr [si],0
        jz      BADCDERRJ2              ; Trailing '/'
        cmp     byte ptr [si],'.'
        jz      BADCDERRJ2              ; If . or .. pure cd should have worked
        cmp     byte ptr [si-2],':'
        jz      DOPCD                   ; Know d:/file
        mov     [bp.ISDIR],1            ; Know path/file
        dec     si                      ; Point at last '/'
DOPCD:
        xor     bl,bl
        xchg    bl,[SI]                 ; Stick in a NUL
        call    SETREST1
        mov     ah,CHDIR
        INT     int_command
        xchg    bl,[SI]
        retnc
BADCDERRJ2:
        JMP     BADCDERR

SETSTARS:
        mov     [bp.TTAIL],DI
        add     [bp.SIZ],12
        mov     ax,('.' SHL 8) OR '?'
        mov     cx,8
        rep     stosb
        xchg    al,ah
        stosb
        xchg    al,ah
        mov     cl,3
        rep     stosb
        xor     al,al
        stosb
        return


COMPNAME:
        PUSH    CX
        PUSH    AX
        MOV     si,offset trangroup:SRCBUF
        MOV     di,offset trangroup:DESTBUF
        MOV     CL,[CURDRV]
        MOV     CH,CL
        CMP     BYTE PTR [SI+1],':'
        JNZ     NOSRCDRV
        LODSW
        SUB     AL,'A'
        MOV     CL,AL
NOSRCDRV:
        CMP     BYTE PTR [DI+1],':'
        JNZ     NODSTDRV
        MOV     AL,[DI]
        INC     DI
        INC     DI
        SUB     AL,'A'
        MOV     CH,AL
NODSTDRV:
        CMP     CH,CL
        jnz     RET81P
        call    STRCOMP
        jz      RET81P
        mov     ax,[si-1]
        mov     cx,[di-1]
        push    ax
        and     al,cl
        pop     ax
        jnz     RET81P                  ; Niether of the mismatch chars was a NUL
; Know one of the mismatch chars is a NUL
; Check for ".NUL" compared with NUL
        cmp     al,'.'
        jnz     CHECKCL
        or      ah,ah
        jmp     short RET81P            ; If NUL return match, else no match
CHECKCL:
        cmp     cl,'.'
        jnz     RET81P                  ; Mismatch
        or      ch,ch                   ; If NUL return match, else no match
RET81P:
        POP     AX
        POP     CX
        return

TRANCODE        ENDS

        END
                                                                                                               