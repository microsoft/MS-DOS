CallInstall MACRO   name,mpx,fn,save,restore
BREAK	MACRO	subtitle
	SUBTTL	subtitle
	PAGE
ENDM
.xcref	break
IF Installed
    IFNB    <save>
	SaveReg <save>
    ENDIF
	MOV	AX,(mpx SHL 8) + fn
	INT	2Fh
    IFNB    <restore>
	RestoreReg  <restore>
    ENDIF
ELSE
	Invoke	name
ENDIF
ENDM

BREAK <SaveReg - save a set of registers>

SaveReg MACRO	reglist 		;; push those registers
IRP reg,<reglist>
	?stackdepth = ?stackdepth + 1
	PUSH	reg
ENDM
ENDM
.xcref	SaveReg

BREAK <RestoreReg - unsave some registers>

RestoreReg  MACRO   reglist		;; pop those registers
IRP reg,<reglist>
	?stackdepth = ?stackdepth - 1
	POP	reg
ENDM
ENDM
.xcref	RestoreReg
