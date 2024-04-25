	page	60,132
;			$SALUT (4,25,30,41)
			INCLUDE pridefs.INC

BREAK			<Resident Portion Messages>

;
;	DOS PRINT
;
;	Resident Portion Messages
;
;	02/15/84	MAU	Created as a separate link module
;				from the include file. should
;				always be linked first!!
;
;	05/20/87	FJG	Change format to new Message Service
;				Routines
;

CodeR			Segment public para

			ASSUME CS:CodeR,DS:nothing,ES:nothing,SS:nothing

			public R_MES_BUFF
					;--------------------------------------
					;INT 24 messages A La COMMAND
					;--------------------------------------

R_MES_BUFF		LABEL WORD	; Room is generated for:

			db   512 dup(?) ;  ERR0
					;  ERR1
					;  ERR2
					;  ERR3
					;  ERR4
					;  ERR5
					;  ERR6
					;  ERR7
					;  ERR8
					;  ERR9
					;  ERR10
					;  ERR11
					;  ERR12
					;

CodeR			EndS

			End
