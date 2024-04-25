;
;   date_verify loosely checks bcd date values to be in range in bin_date_time
;
date_verify:				    ;
assume	ds:code,es:nothing
	cmp	byte ptr bin_date_time+0,20h  ; century check
	ja	date_error		    ; jmp error
	jz	century_20		    ; jmp in 20th century
	cmp	byte ptr bin_date_time+0,19h  ; century check
	jb	date_error		    ; jmp error
	cmp	byte ptr bin_date_time+1,80h  ; year check
	jb	date_error		    ; jmp error
century_20:				    ;
	cmp	byte ptr bin_date_time+1,99h  ; year check
	ja	date_error		    ; jmp error
	cmp	byte ptr bin_date_time+2,12h  ; month check
	ja	date_error		    ; jmp error
	cmp	byte ptr bin_date_time+2,00h  ; month check
	jbe	date_error		    ; jmp error
	cmp	byte ptr bin_date_time+3,31h  ; day check
	ja	date_error		    ; jmp error
	cmp	byte ptr bin_date_time+3,00h  ; day check
	jbe	date_error		    ; jmp error
	clc				    ; set success flag
	ret				    ;
date_error:				    ;
	stc				    ; set error flag
	ret				    ;

;
; time_verify very loosely checks bcd date values to be in range in bin_date_time
;
time_verify:
assume	ds:code,es:nothing
	cmp	byte ptr bin_date_time+0,24H
	ja	time_error
	cmp	byte ptr bin_date_time+1,59H
	ja	time_error
	cmp	byte ptr bin_date_time+2,59H
	ja	time_error
	clc
	ret
time_error:
	stc
	ret

;
;   bcd_verify checks values in bin_date_time to be valid
;   bcd numerals.  carry set if any nibble out of range
;
bcd_verify:			;
assume	ds:code,es:nothing
	mov	cx,4		; 4 bytes to check
	mov	bx,offset bin_date_time   ;
bv_loop:			;
	mov	al,[bx] 	; get a bcd number (0..99)
	mov	ah,al		;
	and	ax,0f00fh	; 10's place in high ah, 1's in al
	cmp	al,10		; is 1's place in range?
	ja	bv_error	; jmp out of range
	shr	ah,1		; swap nibbles
	shr	ah,1		; ...
	shr	ah,1		; ...
	shr	ah,1		; ...
	and	ah,0fh		; get rid of any erroneous bits
	cmp	ah,10		; is 10's place in range
	ja	bv_error	; jmp out of range
	inc	bx		; next byte
	dec	cx		;
	jnz	bv_loop 	;
	clc			; set success flag
	ret			;
bv_error:			;
	stc			; set error flag
	ret			;
;
; Dos 3.30 - The real time clock structures were moved to msbio2.asm
;
