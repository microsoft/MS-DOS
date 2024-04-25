;
; blindingly fast assembly help for Z
;

.xlist
include	version.inc
include cmacros.inc
.list

sBegin  data
assumes ds,data

bufstart    dd     ?
staticW bufsrc,?
staticW buflen,?
staticW buflength,?
staticW buffh,?
globalB fGetlCR,?
bufpos      dd      ?

sEnd
sBegin code

assumes cs,code

;
; getlpos returns current seek position in file
;
cProc   getlpos,<PUBLIC>
cBegin
        mov     dx,word ptr bufpos+2
        mov     ax,word ptr bufpos
cEnd

;
; getlinit (buf, len, fh) initializes the getl routine for buffer buf and fh fh
;
cProc   getlinit,<PUBLIC>
parmD   buf
parmW   len
parmW   fh
cBegin
        mov     ax,off_buf
        mov     word ptr bufstart,ax
        mov     ax,seg_buf
        mov     word ptr bufstart+2,ax
        mov     ax,fh
        mov     buffh,ax
        mov     ax,len
        mov     buflength,ax
        mov     buflen,0
        mov     word ptr bufpos,0
        mov     word ptr bufpos+2,0
        mov     fGetlCR,0
cEnd

;
; getl (dst, len) returns TRUE if a line was read.
;
cProc   getl,<PUBLIC>,<DS,SI,DI>
parmW   dst
parmW   dstlen
cBegin
        assumes ss,data
        cld
        push    ds
        pop     es
        mov     ds,word ptr bufstart+2
        assumes ds,nothing
        mov     si,bufsrc
        mov     di,dst
        mov     cx,buflen
        mov     dx,dstlen
        dec     dx                  ; room for NUL at end
        jcxz    fill

movc:   lodsb                       ; get a byte
        cmp     al,13               ; is it special?
        jbe     spec                ; yes, go handle special case
stoc:   stosb                       ; put character in buffer
        dec     dx                  ; one less space in buffer
endl:   loopnz  movc                ; go back for more characters
        jnz     fill                ; no more characters => go fill buffer
                                    ; cx = 0, buflen = length moved
fin:    dec     cx
fin1:   xor     ax,ax
        stosb
        mov     bufsrc,si           ; length moved = buflen - cx
        xchg    buflen,cx
        sub     cx,buflen
        add     word ptr bufpos,cx
        adc     word ptr bufpos+2,0
        not     ax
        jmp     short getldone

fill:
        mov     cx, buflen          ; add length moved to bufpos
        add     word ptr bufpos,cx
        adc     word ptr bufpos+2,0
        push    dx
        mov     dx,word ptr bufstart
        mov     cx,buflength
        mov     bx,buffh
        mov     ah,3Fh
        int     21h
        mov     cx,ax
        mov     buflen,ax
        mov     si,dx
        pop     dx
        or      ax,ax
        jnz     movc
; if we've stored chars then terminate line else return with 0
        cmp     di,dst
        jnz     fin1
        jmp     short getldone

setnz:  or      al,1
        mov     fGetlCR,-1              ; indicate we've seen a CR
        jmp     endl

spec:   jz      setnz
        cmp     al,10
        jz      fin
        cmp     al,9
        jnz     stoc
        push    cx
        mov     ax,di
        sub     ax,dst
        and     ax,7
        mov     cx,8
        sub     cx,ax
        cmp     cx,dx
        jbe     ok
        mov     cx,dx
ok:     sub     dx,cx
        mov     al," "
        rep     stosb
        pop     cx
        jmp     endl

getldone:
cEnd

sEnd

end
