;Parser INPUT PARM LIST Structure


 NLS_PARMS	label  word
      dw	NLS_PARMSX
      db	0	  ;no extra delimiters

 NLS_PARMSX	label  word
      db	0,1	  ;Min 0 - no path
			  ;Max 1 - path
      dw	NLS_POS1

 NLS_POS1	label  word
      dw	0201h	 ;File spec (optional)
      dw	0001h	 ;Cap result by file
      dw	Res_Valptr   ;tbl
      dw	NoVal	     ;no value list
      db	0	     ;no switch or
			     ;keyword synonyms


NOVAL label word
      db	0

    RES_VALPTR	label word

      RES_TYPE	 db	?	;Result_type
      RES_ITAG	 db	0	;Matched item tag
      RES_SYN	 dw	0	;synonym returned
      RES_POFF	 dw	0	;drive type or beginning of string
      RES_PSEG	 dw	0	;may be string

