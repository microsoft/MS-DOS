; define the segment ordering						       ;AN000;bgb
									       ;AN000;bgb
data	segment public para 'DATA'                                             ;AN000;bgb
data	ends ;put this 1st so that the recmsg works			       ;AN000;bgb
									       ;AN000;bgb
code	segment public PARA 'CODE'                                             ;AN000;bgb
code	ends								       ;AN000;bgb
									       ;AN000;bgb
const	segment public para 'const'                                            ;AN000;bgb
const	ends								       ;AN000;bgb
									       ;AN000;bgb
cstack	segment stack word 'stack'                                             ;AN000;bgb
	db	(362 - 80h) + 256 dup (?) ; (362 - 80h) == IBM's ROM requirements ;AN000;bgb
cstack	ends	; (New - Old) == size of growth 				;AN005;bgb
										;AN005;bgb
lastseg segment public para 'last'                                              ;AN005;bgb
lastseg ends			 ;put last because 'table' writes over memory   ;AN005;bgb
										;AN000;bgb
dg	group	data,const,code,cstack,lastseg					;AN000;bgb
	assume	cs:dg,ds:dg,es:dg,ss:CSTACK					;AN000;bgb
