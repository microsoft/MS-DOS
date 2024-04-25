;;
;;  Long Conditional Jump Macros
;;
lja		macro	Farlabel
		local	Nearlabel
		jna	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljae		macro	Farlabel
		local	Nearlabel
		jnae	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljb		macro	Farlabel
		local	Nearlabel
		jnb	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljc		macro	Farlabel
		local	Nearlabel
		jnc	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljbe		macro	Farlabel
		local	Nearlabel
		jnbe	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
lje		macro	Farlabel
		local	Nearlabel
		jne	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljz		macro	Farlabel
		local	Nearlabel
		jnz	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljg		macro	Farlabel
		local	Nearlabel
		jng	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljge		macro	Farlabel
		local	Nearlabel
		jnge	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljl		macro	Farlabel
		local	Nearlabel
		jnl	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljle		macro	Farlabel
		local	Nearlabel
		jnle	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljnc		macro	Farlabel
		local	Nearlabel
		jc	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljne		macro	Farlabel
		local	Nearlabel
		je	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljnz		macro	Farlabel
		local	Nearlabel
		jz	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljno		macro	Farlabel
		local	Nearlabel
		jo	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
ljo		macro	Farlabel
		local	Nearlabel
		jno	Nearlabel
		jmp	Farlabel
Nearlabel:
		endm
