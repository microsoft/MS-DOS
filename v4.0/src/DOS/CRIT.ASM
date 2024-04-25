;	SCCSID = @(#)crit.asm	1.1 85/04/10
TITLE CRIT - Critical Section Routines
NAME  CRIT
;
; Critical Section Routines
;
;   Critical section handlers
;
;   Modification history:
;
;       Created: ARR 30 March 1983
;

.xlist
;
; get the appropriate segment definitions
;
include dosseg.asm

CODE    SEGMENT BYTE PUBLIC  'CODE'
	ASSUME  SS:NOTHING,CS:DOSGROUP

.xcref
INCLUDE DOSSYM.INC
.cref
.list

	I_need  User_In_AX,WORD
	i_need  CurrentPDB,WORD
if debug
	I_need  BugLev,WORD
	I_need  BugTyp,WORD
include bugtyp.asm
endif

Break   <Critical section handlers>

;
;   Each handler must leave everything untouched; including flags!
;
;   Sleaze for time savings:  first instruction is a return.  This is patched
;   by the sharer to be a PUSH AX to complete the correct routines.
;
Procedure   EcritDisk,NEAR
	public  EcritMem
	public  EcritSFT
ECritMEM    LABEL   NEAR
ECritSFT    LABEL   NEAR
	RET
;       PUSH    AX
	fmt     TypSect,LevReq,<"PDB $x entering $x">,<CurrentPDB,sect>
	MOV     AX,8000h+critDisk
	INT     int_ibm
	POP     AX
	return
EndProc EcritDisk

Procedure   LcritDisk,NEAR
	public  LcritMem
	public  LcritSFT
LCritMEM    LABEL   NEAR
LCritSFT    LABEL   NEAR
	RET
;       PUSH    AX
	fmt     TypSect,LevReq,<"PDB $x entering $x">,<CurrentPDB,sect>
	MOV     AX,8100h+critDisk
	INT     int_ibm
	POP     AX
	return
EndProc LcritDisk

Procedure   EcritDevice,NEAR
	RET
;       PUSH    AX
	fmt     TypSect,LevReq,<"PDB $x entering $x">,<CurrentPDB,sect>
	MOV     AX,8000h+critDevice
	INT     int_ibm
	POP     AX
	return
EndProc EcritDevice

Procedure   LcritDevice,NEAR
	RET
;       PUSH    AX
	MOV     AX,8100h+critDevice
	INT     int_ibm
	POP     AX
	return
EndProc LcritDevice

CODE    ENDS
    END
