;
;Equates for FASTSEEK.
;
;FASTSEEK flags
;
FS_begin      equ    00000001B
FS_end	      equ    11111110B
FS_insert     equ    00000010B
FS_no_insert  equ    11111101B

;FASTSEEK EXTENT CACHING Subfunctions
FSEC_open	equ	11
FSEC_close	equ	12
FSEC_delete	equ	13
FSEC_lookup	equ	14
FSEC_insert	equ	15
FSEC_truncate	equ	16
;
;Equates used in DOS.


;
