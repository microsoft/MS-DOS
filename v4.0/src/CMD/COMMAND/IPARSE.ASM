 page 80,132
;	SCCSID = @(#)iparse.asm 4.1 87/04/28
;	SCCSID = @(#)iparse.asm 4.1 87/04/28
TITLE	COMMAND interface to SYSPARSE

.xlist
.xcref
	INCLUDE comseg.asm		;AN000;
.list
.cref


INIT		SEGMENT PUBLIC PARA	;AN000;

ASSUME	CS:RESGROUP,DS:RESGROUP,ES:NOTHING,SS:NOTHING	;AN000;


;AD054; public	SYSPARSE		;AN000;

	DateSW	equ	0		;AN000; do not Check date format
	TimeSW	equ	0		;AN000; do not Check time format
	CmpxSW	equ	0		;AN000; do not check complex list
	KeySW	equ	0		;AN025; do not support keywords
	Val2SW	equ	0		;AN025; do not Support value definition 2
	Val3SW	equ	0		;AN000; do not Support value definition 3
	QusSW	equ	0		;AN025; do not include quoted string
	DrvSW	equ	0		;AN025; do not include drive only

.xlist
.xcref
;AD054; INCLUDE parse.asm		;AN000;
.list
.cref


INIT	    ends			;AN000;
	    end 			;AN000;
