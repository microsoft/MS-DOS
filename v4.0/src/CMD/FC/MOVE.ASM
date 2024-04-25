;
; memory routines
;

.xlist
include	version.inc
include cmacros.inc
.list

sBegin	code
assumes cs,code

cProc	Move,<PUBLIC>,<DS,SI,DI>
parmD	src
parmD	dst
parmW	count
cBegin
	mov	cx,count
	jcxz	NoByte			; No characters to move
	les	di,dst			; grab pointers
	lds	si,src
	cld
	mov	ax,ds
	cmp	ax,Seg_dst
	jnz	SimpleMove		; segments are NOT the same, no opt
	cmp	si,di			; is the start of source before dest
	jb	TestMove		; yes, try to optimize

SimpleMove:
	shr	cx,1
	rep	movsw
	jnc	NoByte
	movsb
	jmp	short NoByte

TestMove:
	mov	ax,di
	sub	ax,si			; ax = difference between regions
	cmp	ax,cx			; is difference greater than region?
	jae	SimpleMove		; yes, no optimize
	mov	ax,cx			; optimize by copying down from top
	dec	ax
	add	di,ax
	add	si,ax
	std
	rep	movsb			; no word optimization here

NoByte:
	cld
cEnd

cProc	Fill,<PUBLIC>,<DI>
parmD	dst
parmB	value
parmW	count
cBegin
	cld
	les	di,dst
	mov	al,value
	mov	ah,value
	mov	cx,count
	shr	cx,1
	jcxz	fill1
	rep	stosw
fill1:
	jnc	fill2
	stosb
fill2:
cEnd

sEnd

end
