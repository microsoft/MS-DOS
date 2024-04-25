;	SCCSID = @(#)parse.asm	1.2 85/07/23
TITLE PARSE - Parsing system calls for MS-DOS
NAME  PARSE
;
; System calls for parsing command lines
;
;   $PARSE_FILE_DESCRIPTOR
;
;   Modification history:
;
;       Created: ARR 30 March 1983
;               EE PathParse 10 Sept 1983
;

.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

CODE    SEGMENT BYTE PUBLIC  'CODE'
	ASSUME  SS:DOSGROUP,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
.cref
.list

BOGUS =FALSE
.lall
	I_Need  chSwitch,BYTE

BREAK <$Parse_File_Descriptor -- Parse an arbitrary string into an FCB>

; Inputs:
;       DS:SI Points to a command line
;       ES:DI Points to an empty FCB
;       Bit 0 of AL = 1 At most one leading separator scanned off
;                   = 0 Parse stops if separator encountered
;       Bit 1 of AL = 1 If drive field blank in command line - leave FCB
;                   = 0  "    "    "     "         "      "  - put 0 in FCB
;       Bit 2 of AL = 1 If filename field blank - leave FCB
;                   = 0  "       "      "       - put blanks in FCB
;       Bit 3 of AL = 1 If extension field blank - leave FCB
;                   = 0  "       "      "        - put blanks in FCB
; Function:
;       Parse command line into FCB
; Returns:
;       AL = 1 if '*' or '?' in filename or extension, 0 otherwise
;       DS:SI points to first character after filename

	procedure   $PARSE_FILE_DESCRIPTOR,NEAR
ASSUME  DS:NOTHING,ES:NOTHING

	invoke  MAKEFCB
	PUSH    SI
	invoke  get_user_stack
	POP     [SI.user_SI]
	return
EndProc $PARSE_FILE_DESCRIPTOR


IF BOGUS
BREAK <$PathParse - Parse a string>

;------------------------------------------------------------------------------
;
; Parse is a string parser.  It copies the next token into a buffer, updates
; the string pointer, and builds a flag word which describes the token.
;
; ENTRY
;       DS:SI - Points to the beginning of the string to be parsed
;       ES:DI - Points to the buffer which will hold the new token
;
; EXIT
;       AX - Flag word
;       DS:SI - String pointer updated to point past the token just found
;       All other registers are unchanged.
;
; All of the isXXXX procedures called by the main routine test a character
; to see if it is of a particular type.  If it is, they store the character
; and return with the ZF set.
;
; CALLS
;       isswit issep ispchr ispsep isinval isdot ischrnull dirdot pasep
;
;
; INTERNAL REGISTER USAGE
;       AH - FF/00  to indicate whether a path token can terminated with a
;            slash or not.
;       AL - Used with lodsb/stosb to transfer and test chars from DS:SI
;       BX - Holds flag word
;       CX - Used with loop/rep and as a work var
;       DX - Used to test the length of names and extensions
;
; EFFECTS
;       The memory pointed to by DI has the next token copied into it.
;
; WARNINGS
;       It is the caller's responsibility to make sure DS:SI does not point
;       to a null string.  If it does, SI is incremented, a null byte is
;       stored at ES:DI, and the routine returns.
;
;------------------------------------------------------------------------------
ParseClassMask          equ     1110000000000000b       ; Token class mask
ParseSwitch             equ     1000000000000000b       ; Switch class
ParseSeparators         equ     0100000000000000b       ; Separator class
ParsePathName           equ     0010000000000000b       ; Path class
ParsePathNameData       equ     0000000000001111b       ; Path token data mask
ParsePathSynErr         equ     0000000000000001b       ; Path has syntax error
ParsePathWild           equ     0000000000000010b       ; Path has wildcards
ParsePathSeparators     equ     0000000000000100b       ; Path has pseparators
ParseInvalidDrive       equ     0000000000001000b       ; Path has invald drive


; Sepchars is a string containing all of the token separator characters
; and is used to test for separators.

Table   segment
Public PRS001S,PRS001E
PRS001S label byte
sepchrs db      9,10,13,' ','+',',',';','='     ; tab cr lf sp + , ; =
seplen  equ     $-sepchrs
PRS001E label byte
table   ends

Procedure $PathParse,NEAR
	assume  ds:nothing,es:nothing
	xor     ah,ah           ; initialize registers and flags
	xor     bx,bx
	cld
	lodsb                   ; used the first byte of the token to
	call    isswit          ; determine its type and call the routine to
	je      switch          ; parse it
	call    issep
	je      separ
	call    ispchr
	je      path
	call    ispsep
	je      path
	call    isdot
	je      path
	call    isinval
	je      inval
	stosb
	jmp     done

inval:  or      bx,ParsePathName        ; an invalid character/path token
	or      bx,ParsePathSynErr      ; was found, set the appropriate
	call    issep                   ; flag bits and parse the rest of
	jne     icont                   ; the token
	dec     di
icont:  dec     si
	jmp     ptosep

switch: mov     bx,ParseSwitch          ; found a switch, set flag and parse
	jmp     ptosep                  ; the rest of it

separ:  mov     bx,ParseSeparators      ; found separator, set flag and parse
seloop: lodsb                           ; everything up to the next non
	call    issep                   ; separator character
	je      seloop
	jmp     bksi

path:   or      bx,ParsePathName        ; found path, set flag
	mov     cx,8                    ; set up to parse a file name
	mov     dx,8
	call    pasep                   ; if the token began with a path
	jne     pcont1                  ; separator or . call rcont which
	not     ah                      ; handles checksfor . and ..
	jmp     rcont
pcont1: cmp     al,'.'
	jne     pcont2
	dec     si
	dec     di
	jmp     rcont
pcont2: cmp     al,'A'                  ; if token may start with a drive
	jge     drive                   ; designator, go to drive. otherwise
	jmp     name1                   ; parse a file name.

drive:  cmp     byte ptr [si],':'       ; if there is a drive designator, parse
	jne     name1                   ; and verify it. otherwise parse a file
	not     ah                      ; name.
	cmp     al,'Z'
	jle     dcont1
	sub     al,' '
dcont1: sub     al,'@'
	invoke  GetthisDrv
	lodsb
	stosb
	jc      dcont2
	jmp     dcont3
dcont2: or      bx,ParseInvalidDrive
dcont3: dec     cx
	lodsb
	call    ispsep
	je      rcont
	dec     si

repeat: mov     al,byte ptr [si-2]      ; repeat and rcont test for //, \\, .,
	call    pasep                   ; and .. and repeatedly calls name
	jne     rcont                   ; and ext until a path token has
	inc     si                      ; been completely parsed.
	jmp     inval
rcont:  call    dirdot
	je      done
	jc      inval
	mov     cx,8
	mov     dx,8
	jmp     name

name1:  dec     cx
name:   lodsb                           ; parse and verify a file name
	call    ispchr
	jne     ncheck
	xor     ah,ah
nloop:  loop    name
	lodsb

ncheck: cmp     ah,0
	jne     ncont
	cmp     cx,dx
	jne     ncont
	jmp     inval
ncont:  call    isdot
	je      ext
	jmp     dcheck

ext:    mov     cx,3                    ; parse and verify a file extension
	mov     dx,3
extl:   lodsb
	call    ispchr
	jne     echeck
eloop:  loop    extl
	lodsb

echeck: cmp     cx,dx
	jne     dcheck
	jmp     inval

dcheck: call    ispsep                  ; do the checks need to make sure
	je      repeat                  ; a file name or extension ended
	call    issep                   ; correctly and checks to see if
	je      bkboth                  ; we're done
	call    ischrnull
	je      done
	jmp     inval

ptosep: lodsb                           ; parse everything to the next separator
	call    issep
	je      bkboth
	call    ischrnull
	je      done
	call    isinval
	jne     ptcont
	or      bx,ParsePathSynErr
ptcont: stosb
	jmp     ptosep

bkboth: dec     di                      ; clean up when the end of the token
bksi:   dec     si                      ; is found, stick a terminating null
done:   xor     al,al                   ; byte at the end of buf, and exit
	stosb
	push    si
	invoke  Get_user_stack
	mov     [si].user_AX,bx
	pop     [si].user_SI
	Transfer sys_ret_ok

Endproc $PathParse

; Is current character the beginning of a switch?

isswit  proc    near
	cmp     al,[chSwitch]
	jne     swret
	stosb
swret:  ret
isswit  endp


; Is the current character a separator?

issep   proc    near
	push    cx
	push    di
	push    es
	mov     cx,cs
	mov     es,cx
	mov     cx,seplen
	mov     di,offset dosgroup:sepchrs
	repne   scasb
	pop     es
	pop     di
	jne     sepret
sepyes: stosb
sepret: pop     cx
	ret
issep   endp


; Is the current character a path character?  If it is a wildcard char too,
;  set that flag.

ispchr  proc    near
	cmp     al,'!'
	je      pcyes
	cmp     al,'#'
	jl      pcret
	cmp     al,'*'
	je      pcwild
	jl      pcyes
	cmp     al,'-'
	je      pcyes
	cmp     al,'0'
	jl      pcret
	cmp     al,'9'
	jle     pcyes
	cmp     al,'?'
	je      pcwild
	jl      pcret
	cmp     al,'Z'
	jle     pcyes
	cmp     al,'^'
	jl      pcret
	cmp     al,'{'
	jle     pcyes
	cmp     al,'}'
	je      pcyes
	cmp     al,'~'
	je      pcyes
	jmp     pcret
pcwild: or      bx,ParsePathWild
pcyes:  stosb
	cmp     al,al
pcret:  ret
ispchr  endp


; Is the current character a path separator?  If so, set that flag after
; storing the byte.

ispsep  proc    near
	call    pasep
	jne     psret
	stosb
	or      bx,ParsePathSeparators
	cmp     al,al
psret:  ret
ispsep  endp


; Set ZF if the character in AL is a path separator.

pasep   proc    near
	cmp     chSwitch,'/'
	je      bkslash
	cmp     al,'/'
	retz
bkslash:cmp     al,'\'
	ret
pasep   endp


; Is the current character invalid?

isinval proc    near
	cmp     al,1
	jl      inret
	cmp     al,8
	jle     inyes
	cmp     al,11
	jl      inret
	cmp     al,13
	jne     incont
	cmp     al,0
	ret
incont: cmp     al,31
	jle     inyes
	cmp     al,'['
	je      inyes
	cmp     al,']'
	je      inyes
	ret
inyes:  cmp     al,al
inret:  ret
isinval endp


; Is the current character a dot?

isdot   proc    near
	cmp     al,'.'
	jne     dotret
	stosb
dotret: ret
isdot   endp


; Is the current character null?  If so, update SI for exiting.

ischrnull  proc    near
	cmp     al,0
	jne     nulret
	dec     si
	cmp     al,al
nulret: ret
ischrnull  endp


; Check for . and ..  Before returning, CF and ZF are set to indicate whether
; the token is invalid (found . or .. followed by an invalid char - CF on),
; we're done (found . or .. followed by null or a separator - ZF on), or the
; token continues (. and .. not found or found and followed by a path
; separator - both flags off).

dirdot  proc    near
	cmp     byte ptr [si], '.'
	jne     diretc
	lodsb
	stosb
	cmp     byte ptr [si],'.'
	jne     dicont
	lodsb
	stosb
dicont: lodsb
	call    ispsep
	je      diretc
	call    issep
	je      dibk
	call    ischrnull
	je      diretd
direti: stc                             ; Invalid return
	ret
dibk:   dec     si
	dec     di
diretd: cmp     al,al                   ; Done return
	ret
diretc: cmp     ah,1                    ; Continue return
	clc
	ret
dirdot  endp
ENDIF

CODE    ENDS
    END
