;
page 60,132
;
title CP/DOS DosGetCtryInfo mapper

Buffer  segment word public 'buffer'
CountryInfo     db      64
Buffer  ends

dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;**********************************************************************
;*
;*   MODULE:   dosgetctryinfo
;*
;*   FUNCTION:get country information
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

            public   dosgetctryinfo
            .sall
            include  macros.inc


str         struc
old_bp          dw      ?
return          dd      ?
ReturnLength    dd      ?
BufferPtr       dd      ?
CountryCodePtr  dd      ?
BufferLength    dw      ?
str         ends


cntry       struc                       ;country info. sturctrue
ctry_code       dw      ?
code_page       dw      ?
dformat         dw      ?
curr_sym        db      5  dup(?)
thous_sep       dw      ?
decimal_sep     dw      ?
date_sep        dw      ?
time_sep        dw      ?
bit_field       db      ?
curr_cents      db      ?
tformat         db      ?
map_call        dd      ?
data_sep        dw      ?
ra              db      5  dup(?)
cntry       ends


Doscntry       struc                       ;country info. sturctrue
 Ddformat         dw      ?
 Dcurr_sym        db      5  dup(?)
 Dthous_sep       dw      ?
 Ddecimal_sep     dw      ?
 Ddate_sep        dw      ?
 Dtime_sep        dw      ?
 Dbit_field       db      ?
 Dsig_digit       db      ?
 Dtformat         db      ?
 Dmap_call        dd      ?
 Ddata_sep        dw      ?
 DResv            db      5  dup(?)
Doscntry       ends


dosgetctryinfo  proc far

        Enter   Dosgetcntryinfo       ; save registers

        lds     si,[bp].CountryCodePtr
        mov     ax,ds:[si]            ; get country code pointer

        cmp     ax,256                ; 16 bit country code
        jc      getinfo

        mov     bx,ax                 ; if so, load into bx
        mov     al,0ffH               ; and tell DOS it is get country

getinfo:
        mov     dx,seg buffer
        mov     ds,dx
        assume  ds:buffer
        mov     dx,offset buffer:CountryInfo

        mov     ah,38h          ; remember: the al value was set above!!!
        int     21h             ; get country information
        jc      ErrorExit

        mov     si,offset buffer:CountryInfo     ;pointer to DOS cntry infor
        les     di,[bp].BufferPtr                ;pointer to return data area

        mov     ax,[si].ddformat                 ;copy date format
        mov     es:[di].dformat,ax
        mov     ax,[si].ddate_sep                ;copy date seperator
        mov     es:[di].date_sep,ax
        mov     ax,[si].dtime_sep                ;copy time separator
        mov     es:[di].time_sep,ax
        mov     al,[si].dtformat                 ;copy time format
        mov     es:[di].tformat,al

        mov     cx,[bp].BufferLength  ;was buffer larger than pc-dos gave us?
        sub     cx,34
        jc      NoFillNecessary       ; no fill necessary

        les     di,[bp].BufferPtr     ; else fill the remaining area
        add     di,34                 ;   with zeros
        mov     al,0
        rep     stosb

NoFillNecessary:
        sub     ax,ax                 ; set good return code

ErrorExit:
        Mexit                         ; pop registers

        ret     size str - 6          ; return

dosgetctryinfo endp

dosxxx      ends

            end
