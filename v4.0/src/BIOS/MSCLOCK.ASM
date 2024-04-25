	TITLE MSCLOCK - DOS 3.3
;----------------------------------------------------------------
;								:
;		    CLOCK DEVICE DRIVER 			:
;								:
;								:
;   This file contains the Clock Device Driver. 		:
;								:
;   The routines in this files are:				:
;								:
;	routine 		function			:
;	------- 		--------			:
;	TIM$WRIT		Set the current time		:
;	TIM$READ		Read the current time		:
;	Time_To_Ticks		Convert time to corresponding	:
;				  number of clock ticks 	:
;								:
; The clock ticks at the rate of:				:
;								:
;	1193180/65536 ticks/second (about 18.2 ticks per second):
; See each routine for information on the use.			:
;								:
;----------------------------------------------------------------


	itest=0
	INCLUDE MSGROUP.INC	;DEFINE CODE SEGMENT
	INCLUDE MSMACRO.INC

	EXTRN EXIT:NEAR
;
; DAYCNT is the number of days since 1-1-80.
; Each time the clock is read it is necessary to check if another day has
; passed.  The ROM only returns the day rollover once so if it is missed
; the time will be off by a day.
;
	EXTRN DAYCNT:WORD	;MSDATA

;;Rev 3.30 Modification ------------------------------------------------
; variables for real time clock setting
	public	HaveCMOSClock
HaveCMOSClock	db	0	;set by MSINIT.
	public	base_century
base_century	db	19
	public	base_year
base_year	db	80
	public	month_tab
month_tab	db	31,28,31,30,31,30,31,31,30,31,30,31

; The following are indirect intra-segment call addresses. The
;procedures are defined in MSINIT for relocation.  MSINIT will set these
;address when the relocation is done.
	public	BinToBCD
BinToBCD	dw	0	;should point to Bin_To_BCD proc in MSINIT
	public	DaycntToDay
DaycntToDay	dw	0	;should point to Daycnt_to_day in MSINIT

;********************************************************************
; Indirect call address of TIME_TO_TICKS procedure.
;This will be used by the relocatable portable suspend/resume code.

	public	TimeToTicks
TimeToTicks	dw	Time_To_Ticks

;;End of Modification ------------------------------------------------

;--------------------------------------------------------------------
;
; Settime sets the current time
;
; On entry ES:[DI] has the current time:
;
;	number of days since 1-1-80	(WORD)
;	minutes (0-59)			(BYTE)
;	hours (0-23)			(BYTE)
;	hundredths of seconds (0-99)	(BYTE)
;	seconds (0-59)			(BYTE)
;
; Each number has been checked for the correct range.
;
	PUBLIC TIM$WRIT
TIM$WRIT PROC	NEAR
	ASSUME	DS:CODE
	mov	AX,WORD PTR ES:[DI]
	push	AX		;DAYCNT. We need to set this at the very
				;  end to avoid tick windows.
;;Rev 3.30 Modification
	cmp	HaveCMOSClock, 0
	je	No_CMOS_1
	mov	al,es:[di+3]		;get binary hours
	call	BinToBCD		;convert to BCD
	mov	ch,al			;CH = BCD hours
	mov	al,es:[di+2]		;get binary minutes
	call	BinToBCD		;convert to BCD
	mov	cl,al			;CL = BCD minutes
	mov	al,es:[di+5]		;get binary seconds
	call	BinToBCD		;convert to BCD
	mov	dh,al			;DH = BCD seconds
	mov	dl,0			;DL = 0 (ST) or 1 (DST)
	cli				;turn off timer
	mov	ah,03h			;set RTC time
	int	1Ah			;call rom bios clock routine
	sti

;;End of Modification
No_CMOS_1:
	mov	CX,WORD PTR ES:[DI+2]
	mov	DX,WORD PTR ES:[DI+4]
;;Rev 3.30 Modification
	call	time_to_ticks	; convert time to ticks
				;CX:DX now has time in ticks
	cli			; Turn off timer
	mov	AH, 1		; command is set time in clock
	int	1Ah		; call rom-bios clock routines
	pop	[DAYCNT]
	sti
;CMOS clock -------------------------------------
	cmp	HaveCMOSClock, 0
	je	No_CMOS_2
	call	DaycntToDay	; convert to BCD format
	cli			; Turn off timer
	mov	AH,05h		; set RTC date
	int	1Ah		; call rom-bios clock routines
	sti
;------------------------------------------------

No_CMOS_2:
	jmp	EXIT
TIM$WRIT ENDP
;;End of Modification



;
; convert time to ticks
; input : time in CX and DX
; ticks returned in CX:DX
;
public time_to_ticks
TIME_TO_TICKS PROC NEAR

		; first convert from Hour,min,sec,hund. to
		; total number of 100th of seconds
	mov	AL,60
	mul	CH		;Hours to minutes
	mov	CH,0
	add	AX,CX		;Total minutes
	mov	CX,6000 	;60*100
	mov	BX,DX		;Get out of the way of the multiply
	mul	CX		;Convert to 1/100 sec
	mov	CX,AX
	mov	AL,100
	mul	BH		;Convert seconds to 1/100 sec
	add	CX,AX		;Combine seconds with hours and min.
	adc	DX,0		;Ripple carry
	mov	BH,0
	add	CX,BX		;Combine 1/100 sec
	adc	DX,0

;;Rev 3.30 Modification
;DX:CX IS TIME IN 1/100 SEC
	XCHG	AX,DX
	XCHG	AX,CX		;NOW TIME IS IN CX:AX
	MOV	BX,59659
	MUL	BX		;MULTIPLY LOW HALF
	XCHG	DX,CX
	XCHG	AX,DX		;CX->AX, AX->DX, DX->CX
	MUL	BX		;MULTIPLY HIGH HALF
	ADD	AX,CX		;COMBINE OVERLAPPING PRODUCTS
	ADC	DX,0
	XCHG	AX,DX		;AX:DX=TIME*59659
	MOV	BX,5
	DIV	BL		;DIVIDE HIGH HALF BY 5
	MOV	CL,AL
	MOV	CH,0
	MOV	AL,AH		;REMAINDER OF DIVIDE-BY-5
	CBW
	XCHG	AX,DX		;USE IT TO EXTEND LOW HALF
	DIV	BX		;DIVDE LOW HALF BY 5
	MOV	DX,AX
			; CX:DX is now number of ticks in time
	ret
TIME_TO_TICKS ENDP
;;End of Modification


;
; Gettime reads date and time
; and returns the following information:
;
;	ES:[DI]  =count of days since 1-1-80
;	ES:[DI+2]=hours
;	ES:[DI+3]=minutes
;	ES:[DI+4]=seconds
;	ES:[DI+5]=hundredths of seconds
;
	PUBLIC TIM$READ
TIM$READ PROC	NEAR
				; read the clock
	xor	AH, AH		; set command to read clock
	int	1Ah		; call rom-bios to get time

	or	al,al		; check for a new day
	jz	noroll1 	; if al=0 then don't reset day count
	INC	[DAYCNT]	; CATCH ROLLOVE
noroll1:
	MOV	SI,[DAYCNT]

;
; we now need to convert the time in tick to the time in 100th of
; seconds.  The relation between tick and seconds is:
;
;		 65536 seconds
;	       ----------------
;		1,193,180 tick
;
; To get to 100th of second we need to multiply by 100. The equation is:
;
;	Ticks from clock  * 65536 * 100
;      ---------------------------------  = time in 100th of seconds
;		1,193,180
;
; Fortunately this fromula simplifies to:
;
;	Ticks from clock * 5 * 65,536
;      --------------------------------- = time in 100th of seconds
;		59,659
;
; The calculation is done by first multipling tick by 5. Next we divide by
; 59,659.  In this division we multiply by 65,536 by shifting the dividend
; my 16 bits to the left.
;
; start with ticks in CX:DX
; multiply by 5
	MOV	AX,CX
	MOV	BX,DX
	SHL	DX,1
	RCL	CX,1		;TIMES 2
	SHL	DX,1
	RCL	CX,1		;TIMES 4
	ADD	DX,BX
	ADC	AX,CX		;TIMES 5
	XCHG	AX,DX		
	

; now have ticks * 5 in DX:AX
; we now need to multiply by 65,536 and divide by 59659 d.

	mov	CX,59659	; get divisor
	div	CX
				; DX now has remainder
				; AX has high word of final quotient
	mov	BX,AX		; put high work if safe place
	xor	AX,AX		; this is the multiply by 65536
	div	CX		; BX:AX now has time in 100th of seconds

;
;Rounding based on the remainder may be added here
;The result in BX:AX is time in 1/100 second.
	mov	DX,BX
	mov	CX,200		;Extract 1/100's
;Division by 200 is necessary to ensure no overflow--max result
;is number of seconds in a day/2 = 43200.
	div	CX
	cmp	DL,100		;Remainder over 100?
	jb	NOADJ
	sub	DL,100		;Keep 1/100's less than 100
NOADJ:
	cmc			;If we subtracted 100, carry is now set
	mov	BL,DL		;Save 1/100's
;To compensate for dividing by 200 instead of 100, we now multiply
;by two, shifting a one in if the remainder had exceeded 100.
	rcl	AX,1
	mov	DL,0
	rcl	DX,1
	mov	CX,60		;Divide out seconds
	div	CX
	mov	BH,DL		;Save the seconds
	div	CL		;Break into hours and minutes
	xchg	AL,AH

;Time is now in AX:BX (hours, minutes, seconds, 1/100 sec)

	push	AX
	MOV	AX,SI		; DAYCNT
	stosw
	pop	AX
	stosw
	mov	AX,BX
	stosw
	jmp	EXIT

TIM$READ ENDP
CODE	ENDS
	END
