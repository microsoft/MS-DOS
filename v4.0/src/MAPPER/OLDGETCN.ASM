;
page 60,132
;
title CP/DOS DosGetCtryInfo mapper

Buffer  segment word public 'buffer'
CountryInfo     db      64
Buffer  ends

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
;**********************************************************************
;*
;*   MODULE:   dosgetctryinfo
;*
;*   FILE NAME: dos024.asm
;*
;*   CALLING SEQUENCE:
;*
;*       push      word   data area length
;*       push      word   country code
;*       push@     struc  data area
;*       call      dosgetctryinfo
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=38h, get cntry info
;*
;*********************************************************************
;
            public   dosgetctryinfo
            .sall
            include  macros.inc

;
str         struc
old_bp          dw      ?
return          dd      ?
ReturnLength    dd      ?
BufferPtr       dd      ?
CountryCodePtr  dd      ?
BufferLength    dw      ?
str         ends
;

cntry       struc                       ;country info. sturctrue
ctry_code       dw      ?
code_page       dw      ?
dformat         dw      ?
curr_sym        db      5  dup(?)
thous_sep       db      2  dup(?)
decimal_sep     db      2  dup(?)
date_sep        db      2  dup(?)
time_sep        db      2  dup(?)
bit_field       dw      ?
curr_cents      dw      ?
tformat         dw      ?
map_call        dd      ?
data_sep        dw      ?
ra                      5  dup(?)
cntry       ends
;

Doscntry       struc                       ;country info. sturctrue
 Ddformat         dw      ?
 Dcurr_sym        db      5  dup(?)
 Dthous_sep       db      2  dup(?)
 Ddecimal_sep     db      2  dup(?)
 Ddate_sep        db      2  dup(?)
 Dtime_sep        db      2  dup(?)
 Dbit_field       db      ?
 Dsig_digit       db      ?
 Dtformat         db      ?
 Dmap_call        dd      ?
 Ddata_sep        dw      ?
 DResv                    5  dup(?)
Doscntry       ends


dosgetctryinfo  proc far

        Enter   Dosgetcntryinfo

        lds     si,[bp].CountryCodePtr
        mov     ax,ds:[si]

        cmp     ax,256                ;16 bit country code
        jc      getinfo

        mov     bx,ax                 ;if so, load into bx
        mov     al,0ffH               ;and tell DOS

getinfo:
        mov     dx,seg buffer
        mov     ds,dx
        assume  ds:buffer
        mov     dx,offset buffer:CountryInfo

        mov     ah,38h          ; remember: the al value was set above!!!
        int     21h
        jc      ErrorExit
;
        mov     si,offset buffer:CountryInfo
        les     di,[bp].BufferPtr
        cld                            ;string move op.

        mov     cx,[bp].BufferLength  ;length to move

        rep     movsb                 ;copy all to output area

        mov     cx,[bp].BufferLength  ;was buffer larger than pc-dos gave us?
        sub     cx,34
        jc      NoFillNecessary

        les     di,[bp].BufferPtr
        add     di,34

        mov     al,0                  ;fill with zeroes
        rep     stosb
;
NoFillNecessary:
        sub     ax,ax

ErrorExit:
        Mexit

        ret     size str - 6
;
dosgetctryinfo endp

dosxxx      ends

            end
