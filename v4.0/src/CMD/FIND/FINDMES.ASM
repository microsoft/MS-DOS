      title   FIND Messages

Message macro	sym,text
public	sym,sym&_len
sym	db  text
sym&_len db  $-sym
endm

CR	equ	0dh			;A Carriage Return
LF	equ	0ah			;A Line Feed

code	segment public

	PUBLIC	heading
	message heading,<CR,LF,"---------- ">

code	ends
	end
