.xlist
include version.inc
include cmacros.inc
.list

sBegin  code
assumes cs,code

;
; c = IToupper (c, routine);
;
;       c is char to be converted
;       routine is case map call in international table
;

cProc   IToupper,<PUBLIC>
parmW   c
parmD   routine
cBegin
        mov     ax,c
        or      ah,ah
        jnz     donothing
        cmp     al,'a'
        jb      noconv
        cmp     al,'z'
        ja      noconv
        sub     al,20H
noconv:
        call    routine
donothing:
cEnd


;Get_Lbtbl
;
;       Get pointer to LBTBL from DOS if we are running on a version
;       of DOS which supports it.  If not, initialize the table with
;       a pointer to a local "default" table with KANJI lead bytes.
;
;Input: word pointer to LONG "Lbtbl"
;Output: long initialized to Lead byte pointer
;

cProc   get_lbtbl,<PUBLIC> 
                                
parmW   pointer_to_table                        
                                
;	on entry, low word of DWORD pointer has offset of
;	a default table of lead bytes defined within the C program
;	If function 63 is supported, the DWORD pointer to DOS'
;	table will be placed here instead.
cBegin
        push    si
        push    di
        mov     bx,pointer_to_table     ;get pointer
	mov	si,[bx]			;default table pointer in DS:SI
        push    es
	push	ds
        mov     ax,6300h                ;make Get Lead Byte call
        int     21h
        mov     ss:[bx],si		;si didn't change if non ECS dos
        mov     ss:[bx+2],ds            ;store segment
	pop	ds
	pop	es
        pop     di
        pop     si
cEnd       


;
; test_ECS(char,DWORD_prt)      test the char to find out if it is
;                               a valid lead byte using passed DWORD
; Input: char                   PTR to the Lead Byte table.
;        DWORD PTR to table
; Output: AX=FFFF (is_lead)     Lead byte table may be default in 
;         AX=0    (not_lead)    program or ECS table in DOS when
;                               running on a version which supports it.
;
cProc   test_ECS,<PUBLIC>  ;test for lead byte  ;if Lead, then
                                                ; return AX=Is_lead
                                                ; else 
                                                ; return AX=FALSE
Is_lead         EQU     0FFFFH
Not_lead        EQU     0

parmW   char
parmD   pointer         ;DWORD PTR to Lead Byte Table
cBegin 
        mov     ax,char
        xchg    ah,al
        push    SI
        push    DS
        LDS     SI,pointer
ktlop:
        lodsb
        or      al,al
        jz      notlead
        cmp     al,ah
        ja      notlead
        lodsb
        cmp     ah,al
        ja      ktlop
        mov     ax,Is_lead
notl_exit:
        pop     ds
        pop     si
        jmp     cexit
notlead:
        mov     ax,not_lead
        jmp     notl_exit
cexit:
cEnd




sEnd

end
