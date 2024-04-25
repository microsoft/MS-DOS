
;
page 80,132
;
title CP/DOS DosCaseMap
;
dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing

;**********************************************************************
;*
;*   MODULE:   doscasemap
;*
;*
;*   CALLING SEQUENCE:
;*
;*             PUSH     WORD    Length
;*             PUSH@    DWORD   CountryCode
;*             PUSH@    DWORD   BinaryString
;*             DosCaseMap
;*
;*   MODULES CALLED:  none
;*
;*********************************************************************

        public  doscasemap
        .sall
        include macros.inc

str     struc
old_bp  dw      ?
return  dd      ?
StringPtr       dd      ?       ; binary string pointer
CountryCodePtr  dd      ?       ; country code pointer
StringLength    dw      ?       ; lenght of the string
str     ends

DosCaseMap      proc    far

        Enter  DosCaseMap               ; save registers

; Get the country, so we can then get the country case map stuff

        lds     si,[bp].CountryCodePtr
        mov     ax,ds:[si]

; Note: do the country selection later (maybe never)

        lds     si,[bp].StringPtr
        mov     cx,[bp].StringLength

MapLoop:                                ; convert characters to upper case
        lodsb
        cmp     al,'a'
        jc      ThisCharDone

        cmp     al,'z'+1
        jnc     ThisCharDone

        add     al,'A' - 'a'
        mov     ds:[si-1],al

ThisCharDone:
        loop    MapLoop                 ; loop until string is complete

        MExit                           ; pop registers
        ret     size str - 6            ; return
;
DosCaseMap      endp

dosxxx  ends

        end
