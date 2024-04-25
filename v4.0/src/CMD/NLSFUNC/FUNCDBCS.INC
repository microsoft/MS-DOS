;; generic ioctl call data "packet" pointed to by DS:DX    =E
PACKET		STRUC	   ;USED BY MINOR CODES: 6AH,4AH,4DH (SELECT, QUERY SELECTED, PREPARE END)  =E
PACKLEN 	DW   0	     ;LENGTH OF PACKET IN BYTES =E	  2/16/KK
PACKCPID	DW   0	   ;CODE PAGE ID	      =E
DBCS_EV 	DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
		DB   0,0   ; 2/16/KK
PACKET		ENDS


STD_CPLENGTH  equ	2
PK	      PACKET <>  ;CNS
