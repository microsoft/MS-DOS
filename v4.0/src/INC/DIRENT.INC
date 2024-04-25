;	SCCSID = @(#)dirent.asm 1.1 85/04/10
;	SCCSID = @(#)dirent.asm 1.1 85/04/10
Break <Directory entry>

;
;	+---------------------------+
;	|  (12 BYTE) filename/ext   |	    0	    0
;	+---------------------------+
;	|     (BYTE) attributes     |	    11	    B
;	+---------------------------+
;	|    (10 BYTE) reserved     |	    12	    C
;	+---------------------------+
;	| (WORD) time of last write |	    22	    16
;	+---------------------------+
;	| (WORD) date of last write |	    24	    18
;	+---------------------------+
;	|   (WORD) First cluster    |	    26	    1A
;	+---------------------------+
;	|     (DWORD) file size     |	    28	    1C
;	+---------------------------+
;
;   First byte of filename  = E5 -> free directory entry
;			    = 00 -> end of allocated directory
;   Time:   Bits 0-4=seconds/2, bits 5-10=minute, 11-15=hour
;   Date:   Bits 0-4=day, bits 5-8=month, bits 9-15=year-1980
;

dir_entry   STRUC
dir_name    DB	    11 DUP (?)		; file name
dir_attr    DB	    ?			; attribute bits
dir_codepg  dw	    ?			; code page DOS 4.00
dir_extcluster dw   ?			; extended attribute starting cluster
dir_attr2   db	    ?			; reserved
dir_pad     DB	    5  DUP (?)		; reserved for expansion
dir_time    DW	    ?			; time of last write
dir_date    DW	    ?			; date of last write
dir_first   DW	    ?			; first allocation unit of file
dir_size_l  DW	    ?			; low 16 bits of file size
dir_size_h  DW	    ?			; high 16 bits of file size
dir_entry   ENDS

attr_read_only	    EQU      1h
attr_hidden	    EQU      2h
attr_system	    EQU      4h
attr_volume_id	    EQU      8h
attr_directory	    EQU     10h
attr_archive	    EQU     20h
attr_device	    EQU     40h 	; This is a VERY special bit.
					;   NO directory entry on a disk EVER
					;   has this bit set. It is set non-zero
					;   when a device is found by GETPATH

attr_all	    EQU     attr_hidden+attr_system+attr_directory
					; OR of hard attributes for FINDENTRY

attr_ignore	    EQU     attr_read_only+attr_archive+attr_device
					; ignore this(ese) attribute(s) during
					; search first/next

attr_changeable     EQU     attr_read_only+attr_hidden+attr_system+attr_archive
					; changeable via CHMOD
