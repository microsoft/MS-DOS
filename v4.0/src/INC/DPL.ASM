;	SCCSID = @(#)dpl.asm	1.1 85/04/10
;	SCCSID = @(#)dpl.asm	1.1 85/04/10
DPL	STRUC
DPL_AX	DW	?	; AX register
DPL_BX	DW	?	; BX register
DPL_CX	DW	?	; CX register
DPL_DX	DW	?	; DX register
DPL_SI	DW	?	; SI register
DPL_DI	DW	?	; DI register
DPL_DS	DW	?	; DS register
DPL_ES	DW	?	; ES register
DPL_reserved DW ?	; Reserved
DPL_UID DW	?	; User (Machine) ID (0 = local macine)
DPL_PID DW	?	; Process ID (0 = local user PID)
DPL	ENDS
