;	SCCSID = @(#)curdir.asm 1.1 85/04/10
;	SCCSID = @(#)curdir.asm 1.1 85/04/10
BREAK <Current directory list structure>
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
; CDS items are used bu the internal routines to store cluster numbers and ;
; network identifiers for each logical name.  The ID field is used dually, ;
; both as net ID and for a cluster number for local devices.  In the case  ;
; of local devices, the cluster number will be -1 if there is a potential  ;
; of the disk being changed or if the path must be recracked.  The END	   ;
; field is the location of the end of the definition.  No .. is allowed    ;
; past this point							   ;

DIRSTRLEN	EQU	64+3		; Max length in bytes of directory strings
TEMPLEN 	EQU	DIRSTRLEN*2

curdir_list	STRUC
curdir_text	DB	DIRSTRLEN DUP (?)   ; text of assignment and curdir
curdir_flags	DW	?		; various flags
curdir_devptr	DD	?		; local pointer to DPB or net device
curdir_ID	DW	?		; cluster of current dir (net ID)
		DW	?
curdir_user_word DW	?
curdir_end	DW	?		; end of assignment
curdir_type	DB	?		; IFS drive (2=ifs, 4=netuse)
curdir_ifs_hdr	DD	?		; Ptr to File System Header
curdir_fsda	DB	2 DUP (?)	; File System Dependent Data Area
curdir_list	ENDS

curdirLen	EQU	Size curdir_list	; Needed for screwed up
						; ASM87 which doesn't allow
						; Size directive as a macro
						; argument
curdir_netID	EQU	DWORD PTR curdir_ID

;Flag word masks
curdir_isnet	EQU	1000000000000000B
curdir_isifs	EQU	1000000000000000B	; DOS 4.00
curdir_inuse	EQU	0100000000000000B
curdir_splice	EQU	0010000000000000B
curdir_local	EQU	0001000000000000B
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
