BREAK	<LOADALL descriptor caches>

DEF_ACCESS	EQU	92H
DEF_LIMIT	EQU	0FFFFH

SEGREG_DESCRIPTOR STRUC
SEG_BASE	DW	?
		DB	?
SEG_ACCESS	DB	DEF_ACCESS
SEG_LIMIT	DW	DEF_LIMIT
SEGREG_DESCRIPTOR ENDS

DTR_DESCRIPTOR STRUC
DTR_BASE	DW	?
		DB	?
		DB	0
DTR_LIMIT	DW	?
DTR_DESCRIPTOR ENDS
;
; 386 Descriptor template
;
desc	struc
lim_0_15	dw	0		; limit bits (0..15)
bas_0_15	dw	0		; base bits (0..15)
bas_16_23	db	0		; base bits (16..23)
access		db	0		; access byte
gran		db	0		; granularity byte
bas_24_31	db	0		; base bits (24..31)
desc	ends

gdt_descriptor	struc
gdt_limit	dw	?
gdt_base_0	dw	?
gdt_base_2	dw	?
gdt_descriptor	ends
