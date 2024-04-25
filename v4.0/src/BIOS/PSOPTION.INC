;*******************************************************************
; Parser Options set for IBMBIO SYSCONF module
;*******************************************************************
;
;**** Default assemble swiches definition **************************

IFNDEF	FarSW
FarSW	equ	0	; Near call expected
ENDIF

IFNDEF	DateSW
DateSW	equ	0	; Check date format
ENDIF

IFNDEF	TimeSW
TimeSW	equ	0	; Check time format
ENDIF

IFNDEF	FileSW
FileSW	equ	1	; Check file specification
ENDIF

IFNDEF	CAPSW
CAPSW	equ	0	; Perform CAPS if specified
ENDIF

IFNDEF	CmpxSW
CmpxSW	equ	0	; Check complex list
ENDIF

IFNDEF	NumSW
NumSW	equ	1	; Check numeric value
ENDIF

IFNDEF	KeySW
KeySW	equ	0	; Support keywords
ENDIF

IFNDEF	SwSW
SwSW	equ	1	; Support switches
ENDIF

IFNDEF	Val1SW
Val1SW	equ	1	; Support value definition 1
ENDIF

IFNDEF	Val2SW
Val2SW	equ	0	; Support value definition 2
ENDIF

IFNDEF	Val3SW
Val3SW	equ	1	; Support value definition 3
ENDIF

IFNDEF	DrvSW
DrvSW	equ	1	; Support drive only format
ENDIF

IFNDEF	QusSW
QusSW	equ	0	; Support quoted string format
ENDIF

