PSP	segment public	para 'DUMMY'                                            ;an000;bgb
PSP	ends									;an000;bgb
										;an000;bgb
data	segment public para 'DATA'                                              ;an000;bgb
data	ends									;an000;bgb
										;an000;bgb
CONST	SEGMENT PUBLIC para 'DATA'                                              ;an000;bgb
CONST	ENDS									;an000;bgb
										;an000;bgb
code	segment public para 'CODE'                                              ;an000;bgb
code	ends									;an000;bgb
										;an000;bgb
cstack	 segment para stack 'STACK'                                             ;an000;bgb
cstack	 ends									;an000;bgb
										;an000;bgb
lastseg segment public para 'LAST'                                              ;an000;bgb;AN000;bgb
lastseg ends			 ;this is a pointer to the end of the pgm     ;A;an000;bgbN000;bgb
										;an000;bgb;AN000;bgb
DG	GROUP	data,const,code,CSTACK,lastseg					;an000;bgb
assume	cs:dg,ds:dg,ss:dg,es:dg 						;an000;bgb
