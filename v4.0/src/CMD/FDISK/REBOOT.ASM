
	title	Reboot Support for FDISK

IF1
	%OUT ASSEMBLING: Reboot
	%OUT
ENDIF

ROMDATA segment at 040h
	org	072h
BootType	dw	?
ROMDATA ends

ROMBIOS segment at 0ffffh
	org	0
POR	label	far
ROMBIOS ends

_text	segment byte public 'code'
	assume	cs:_TEXT
	assume	ds:nothing
	assume	es:nothing
	assume	ss:nothing

	public	_reboot
_reboot proc	near

	mov	ax,ROMDATA
	mov	ds,ax
	assume	ds:ROMDATA

	mov	BootType,1234h

	cli
	cld
	jmp	POR

_reboot endp

_text	ends

	end
