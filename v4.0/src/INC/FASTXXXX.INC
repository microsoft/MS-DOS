; Fastxxx equates
FastOpen_ID	   equ	   1
FastSeek_ID	   equ	   2
Fast_yes	   equ	   10000000B	 ; fastxxx flag

;Structure definitions
;
Fasttable_Entry  struc			 ; Fastxxx  Entry pointer in DOS
Fast_Entry_Num	    dw	    2		 ; number of entries
FastOpen_Seek	    dd	    ?		 ; fastopen & fastseek entry address
Fasttable_Entry  ends
;
