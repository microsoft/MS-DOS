;	SCCSID = @(#)readclock.asm	1.2 85/07/25
;************************************************************************
;
;   read_real_date reads real-time clock for date and returns the number
;   of days elapsed since 1-1-80 in si
;
read_real_date: 		;mjb002
	assume	ds:code,es:nothing
	PUSH	AX
	PUSH	CX
	PUSH	DX
	XOR	AH,AH			; throw away clock roll over  ;3.30*
	INT	1AH						      ;3.30*
	POP	DX
	POP	CX
	POP	AX

	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	MOV	CS:DAYCNT2,1	 ;MJB002 REAL TIME CLOCK ERROR FLAG (+1 DA;3.30Y)
	mov	ah,4		;mjb002 read date function code       ;3.30*
	int	1ah		;mjb002 read real-time clock	      ;3.30*
	jnc	read_ok 	;mjb002 jmp success
	jmp	r_d_ret 	;mjb002 jmp error
read_ok:			;mjb002 ******* get bcd values in binary *****
	mov	byte ptr bin_date_time+0,ch  ;mjb002 store as hex value
	mov	byte ptr bin_date_time+1,cl  ;mjb002 ...
	mov	byte ptr bin_date_time+2,dh  ;mjb002 ...
	mov	byte ptr bin_date_time+3,dl  ;mjb002 ...
	MOV	CS:DAYCNT2,2	 ;MJB002 READ OF R-T CLOCK SUCCESSFUL	  ;3.30
	call	bcd_verify	;mjb002 verify bcd values in range
	jc	r_d_ret 	;mjb002 jmp some value out of range
	MOV	CS:DAYCNT2,3	 ;MJB002 READ OF R-T CLOCK SUCCESSFUL	  ;3.30
	call	date_verify	;mjb002 verify date values in range
	jc	r_d_ret 	;mjb002 jmp some value out of range
	MOV	CS:DAYCNT2,0	 ;MJB002 VERIFY SUCCESSFUL		  ;3.30;3.30
	call	in_bin		;mjb002 convert date to binary
				;mjb002 ******* years since 1-1-80 *********
	mov	al,byte ptr bin_date_time+1  ;mjb002 get years into century
	cbw				     ;mjb002
	cmp	byte ptr bin_date_time+0,20  ;mjb002 20th century?
	jnz	century_19		     ;mjb002 jmp no
	add	ax,100		;mjb002 add in a century
century_19:			;mjb002
	sub	ax,80		;mjb002 subtract off 1-1-80
	mov	cl,4		;mjb002 leap year every 4
	div	cl		;mjb002 al= # leap year blocks, ah= remainder
	mov	bl,ah		;mjb002 save odd years
	cbw			;mjb002 zero ah
	mov	cx,366+3*365	;mjb002 # of days in leap year blocks
	mul	cx		;mjb002 dx:ax is result
	MOV	CS:DAYCNT2,AX	 ;MJB002 SAVE COUNT OF DAYS		  ;3.30
	mov	al,bl		;mjb002 get odd years count
	cbw			;mjb002
	or	ax,ax		;mjb002 is ax= 0?
	jz	leap_year	;mjb002 jmp if none
	mov	cx,365		;mjb002 days in year
	mul	cx		;mjb002 dx:ax is result
	ADD	CS:DAYCNT2,AX	 ;MJB002 ADD ON DAYS IN ODD YEARS	  ;3.30
	jmp	short leap_adjustment	;mjb002 account for leap year
leap_year:			;mjb002 possibly account for a leap day
	cmp	byte ptr bin_date_time+2,2   ;mjb002 is month february
	jbe	no_leap_adjustment  ;mjb002 jan or feb. no leap day yet.
leap_adjustment:		;mjb002 account for leap day
	INC	CS:DAYCNT2	 ;MJB002 ...				  ;3.30
no_leap_adjustment:		;mjb002 ******* get days of month *******
	mov	cl,byte ptr bin_date_time+3    ;mjb002 ...
	xor	ch,ch		;mjb002
	dec	cx		;mjb002 because of offset from day 1, not day 0
	ADD	CS:DAYCNT2,CX	 ;MJB002 ******* GET DAYS IN MONTHS PRECEE;3.30DING *****
	mov	cl,byte ptr bin_date_time+2   ;mjb002 get month
	xor	ch,ch		;mjb002
	dec	cx		;mjb002 january starts at offset 0
	shl	cx,1		;mjb002 word offset
	mov	si,offset month_table	;mjb002 beginning of month_table
	add	si,cx		;mjb002 point into month table
	mov	ax,word ptr [si];mjb002 get # days in previous months
	ADD	CS:DAYCNT2,AX	 ;MJB002 ...				  ;3.30
r_d_ret:			;mjb002
	MOV	SI,CS:DAYCNT2	 ;MJB002 RESULT IN SI			  ;3.30
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	ret			;mjb002

r_t_retj:
	xor	cx,cx
	xor	dx,dx
	jmp	r_t_ret
;
; Read_Real_Time reads the time from the RTC. on exit, it has the number of
; ticks (at 18.2 ticks per sec.) in CX:DX.
;
Read_Real_Time:
	mov	ah,2						      ;3.30*
	int	1AH						      ;3.30*
	jc	r_t_retj
oktime:
	mov	byte ptr bin_date_time,ch	; hours
	mov	byte ptr bin_date_time+1,cl	; minutes
	mov	byte ptr bin_date_time+2,dh	; seconds
	mov	byte ptr bin_date_time+3,0	; unused for time
	call	bcd_verify
	jc	r_t_retj
	call	time_verify
	jc	r_t_retj
	call	in_bin
	MOV	ch,byte ptr bin_date_time
	MOV	cl,byte ptr bin_date_time+1
	MOV	dh,byte PTR bin_date_time+2
	MOV	dl,byte PTR bin_date_time+3
	message ftestinit,<"Read Time   ">
	mnum	ftestinit,cx
	message ftestinit,<"  ">
	mnum	ftestinit,dx
	message ftestinit,<cr,lf>
; get time in ticks in CX:DX
	CALL	word ptr cs:TimeToTicks 	;3.30
	message ftestinit,<"Conv Time   ">
	mnum	ftestinit,cx
	message ftestinit,<"  ">
	mnum	ftestinit,dx
	message ftestinit,<cr,lf>
r_t_ret:
	ret

;
;   in_bin converts bin_date_time values from bcd to bin
;
in_bin: 				     ;mjb002
	assume	ds:code,es:nothing
	mov	al,byte ptr bin_date_time+0  ; century or hours
	call	bcd_to_bin		     ; ...
	mov	byte ptr bin_date_time+0,al  ;
	mov	al,byte ptr bin_date_time+1  ; years or minutes
	call	bcd_to_bin		     ; ...
	mov	byte ptr bin_date_time+1,al  ;
	mov	al,byte ptr bin_date_time+2  ; months or seconds
	call	bcd_to_bin		     ; ...
	mov	byte ptr bin_date_time+2,al  ;
	mov	al,byte ptr bin_date_time+3  ; days (not used for time)
	call	bcd_to_bin		     ; ...
	mov	byte ptr bin_date_time+3,al  ;
	ret				     ;
;
;   bcd_to_bin converts two bcd nibbles in al (value <= 99.) to
;   a binary representation in al
;   ah is destroyed
;
bcd_to_bin:			;mjb002
	assume	ds:nothing,es:nothing
	mov	ah,al		;mjb002 copy bcd number to ah
	and	ax,0f00fh	;mjb002 clear unwanted nibbles
	mov	bl,al		;mjb002 save units place
	xchg	ah,al		;mjb002 10's place to al
	xor	ah,ah		;mjb002 ah not wanted
	mov	cl,4		;mjb002 shift count
	shr	ax,cl		;mjb004 swap nibbles
	mov	cl,10		;mjb002 convert al to ...
	mul	cl		;mjb002 ... its binary value
	add	al,bl		;mjb002 add in units
	ret			;mjb002
