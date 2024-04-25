
CONST	SEGMENT PUBLIC PARA 'DATA'
	EXTRN	STACKMES:byte
	EXTRN	BADVER:byte, BADDRV_ARG:word, INVPATH_ARG:word
	EXTRN	FILE_ARG:word
	EXTRN	BADCD_ARG:word, BADSUBDIR:byte
	EXTRN	no_mem_arg:word 						;an030;bgb
	EXTRN	BADRDMES:byte
	EXTRN	BADDRVM:byte
	EXTRN	BADIDBYT:byte
	EXTRN	OPNERR_ARG:word, NOEXT_ARG:word, EXTENT_ARG:word
	EXTRN	IDMES_ARG:WORD
	EXTRN	ORPH_ARG:WORD
	EXTRN	FILE_ARG1:WORD, FILE_ARG2:WORD
	EXTRN	badrw_num:word, BADRW_STR:WORD, BLOCK_NUM:WORD
	EXTRN	FATAL_ARG1:WORD, FATAL_ARG2:WORD
	EXTRN	FATmsg2:word							;an024;bgb
	EXTRN	BADSW_ARG:WORD, DSKSPC:WORD				     ;an049;bgb
	EXTRN	HIDMES:WORD, DIRMES:WORD, FILEMES:WORD, ORPHMES2:WORD
	EXTRN	ORPHMES3:WORD, BADSPC:WORD, FRESPC:WORD
	EXTRN	FREMEM:WORD, REPORT_ARG:WORD, CRLF_ARG:WORD
	EXTRN	RARG1:WORD, RARG3:WORD, ORPHCNT:WORD
	EXTRN	NO_NET_ARG:byte, MONTAB:BYTE,  SubstErr:BYTE
	EXTRN	ExitStatus:Byte,Badr_Arg:Byte					;an000;bgb
	EXTRN	Sublist_msg_Idmes:word						;an000;bgb
	extrn	msgserialnumber:byte						;an000;bgb
	extrn	psp_segment:word						;an000;bgb;an034;bgb
										;an000;bgb
	PUBLIC	SWITCHAR
	PUBLIC	TCHAR
	PUBLIC	HECODE
	PUBLIC	conbuf
	PUBLIC	DOTMES
	PUBLIC	NOISY
	PUBLIC	DOTENT
	PUBLIC	HAVFIX
	PUBLIC	DOFIX
	PUBLIC	DIRBUF
	PUBLIC	PARSTR, DDOTENT, NUL, ERRSUB, SECONDPASS, ALLFILE
	PUBLIC	ORPHFCB, ORPHEXT, HIDCNT, HIDSIZ, FILCNT, FILSIZ, DIRCNT
	PUBLIC	DIRSIZ, DIRTYFAT, CROSSCNT, BADSIZ, ORPHSIZ, LCLUS
	PUBLIC	USERDIR, FRAGMENT, ALLDRV, FIXMFLG, DIRCHAR
	PUBLIC	BIGFAT, EOFVAL, BADVAL,CHAIN_END
	PUBLIC	fTrunc,Volnam
	PUBLIC	temp_dd 						   ;an049;bgb

DIRBUF	LABEL	BYTE			;Entry buffer for searches
VOLID	DB	-1,0,0,0,0,0,8		;Volume ID FCB
VOLNAM	DB	0,"???????????"
	DB	25 DUP(0)

ALLFILE DB	-1			;Extended FCB indicator
	DB	0,0,0,0,0		;reserved bytes
	DB	1EH	;attribute byte 0001-1110 hidden, system, label, subdir
ALLDRV	DB	0			;default drive
	DB	"???????????"           ;any file name
	DB	25 DUP (?)

ORPHFCB DB	0,"FILE0000"
ORPHEXT DB	"CHK"
	DB	25 DUP (?)

fcb_copy db	32 dup (?)

;Non-message data

pFileName   DW	?			; pointer
SWITCHAR DB	"/"
ROOTSTR LABEL	BYTE	;use this to change dir to the root
DIRCHAR DB	"\"
NUL	DB	0
PARSTR	DB	"..",0
DOTMES	DB	".",0
DOTENT	DB	".          "
DDOTENT DB	"..         "
HECODE	DB	?
FIXMFLG DB	0			;Flag for printing fixmes
ERRSUB	DW	0			;Flag for bad subdir error
FRAGMENT DB	0			;Flag for extent processing
DIR_FIX  DB	0			;Flag for changing dir back to users'
DIRTYFAT DB	0			;Dirty flag for FAT
;
;note - all these fields that count allocation units can remain the same,
;	because the total au's are always less than 64k (1 word).
; looks like the number of files and directories should change, though.
DIRCNT	dd	0			;# directories				;an049;bgb
DIRSIZ	dw	0			;# alloc units in dirs			;an049;bgb
FILCNT	dd	0			;# reg files
FILSIZ	dw	0			;# alloc units in reg files
HIDCNT	dd	0			;# hidden files
HIDSIZ	dw	0			;# alloc units in hid files
BADSIZ	dw	0			;# alloc units in bad sectors
ORPHSIZ dw	0			;# alloc units in orphan files
LCLUS	dw	0			;# alloc units in lost clusters
DISPFLG DB	0			;used by number routines
CROSSCNT dd	0			;# crosslinked files (first pass)
;end of display fields
;
temp_dd    dd	0		    ;temporary double word field for orphcnt;an049;bgb
SECONDPASS DB	0			;Pass flag
HAVFIX	DB	0			;non zero if any fixes
DOFIX	DB	0			;flag for F switch
NOISY	DB	0			;flag for V switch
BIGFAT	DB	0			;0=12 bit FAT, NZ=16bit FAT
EOFVAL	DW	0FF8H			;0FF8 for 12 bit FAT,0FFF8 for 16 bit
CHAIN_END DW	0FFFH			;0FFF for 12 bit FAT,0FFFF for 16 bit	;AN000;
BADVAL	DW	0FF7H			;0FF7 for 12 bit FAT,0FFF7 for 16 bit

mon_name db	3 dup (?),0
TCHAR	DB	'a'
USERDIR DB	"\",0                   ;Users current dir for drive
	DB	(DIRSTRLEN-1) DUP (?)
CONBUF	DB	15,0			;Input buffer
	DB	15 DUP (?)

fTrunc	DB	FALSE			; TRUE => couldn't chdir, no freeing.

badread db	"   File allocation table bad",0
CONST	ENDS








DATA	SEGMENT PUBLIC PARA 'DATA'
	PUBLIC	THISDPB,DOTSNOGOOD,NUL_ARG,STACKLIM,ZEROTRUNC
	PUBLIC	NAMBUF,SRFCBPT,fatmap,ISCROSS,MCLUS,CSIZE,SSIZE
	PUBLIC	DSIZE,ARG1,ARG_BUF,ERRCNT,USERDEV,SECBUF
	PUBLIC	HARDCH,CONTCH,PATH_NAME,TMP_SPC,mem_size
	public	Read_Write_Relative,Transrc, fatcnt, fattbl_seg 		;an000;bgb
	public	firstfat, fatsiz, secs_per_64k, paras_per_fat, sec_count	;an000;bgb
	public	firstsec							;an047;bgb
	public	dirsec								;an047;bgb
     public    root_entries						       ;an047;bgb
	public	paras_per_64k, save_drive					;an000;bgb
	public	sernum								;an000;bgb;an024;bgb
ifdef	fsexec									;an038;bgb
	public	exec_path							;an038;bgb;an000;bgb;an027;bgb
	public	exec_block							;an038;bgb;an000;bgb;an027;bgb
	public	path_string							;an038;bgb;an000;bgb;an027;bgb
endif										;an038;bgb
	public	end_of_fatmap							;an000;bgb;an030;bgb
	public	DBCS_VECTOR							;an055;bgb
	public	DBCS_VECTOR_off 						;an055;bgb
	public	DBCS_VECTOR_seg 						;an055;bgb

DBCS_VECTOR DB 0
DBCS_VECTOR_off dw 0
DBCS_VECTOR_seg dw 0

ifdef	fsexec									;an038;bgb
Exec_Block Exec_Block_Parms <>							;an038;bgb;an027;bgb
EXEC_Path db	66 dup(0)							;an038;bgb;an027;bgb
;These next two should stay togather						;an027;bgb
; ---------------------------------------					;an027;bgb
Path_String db	"PATH="                         ;                               ;an027;bgb
Len_Path_String equ $ - Path_String		;				;an027;bgb;AN000;
;----------------------------------------					;an027;bgb
endif										;an038;bgb
										;an038;bgb;an027;bgb
										;an027;bgb
;These should stay togather							;an027;bgb
; ---------------------------------------					;an027;bgb
						;				;an027;bgb
Search_Chkdsk db "KSDKHC"                       ;                               ;an027;bgb
Len_Search_Chkdsk equ $ - Search_Chkdsk 	;				;an027;bgb
Search_Chkdsk_End equ $-1							;an027;bgb
						;				;an027;bgb
;----------------------------------------					;an027;bgb
save_drive	db	0   ;determines whether drive specified is valid
firstfat	dw	0   ;sector number of fat     ;an005;bgb
firstsec	dw	0   ;sector number of data area 			;an047;bgb
dirsec		dw	0   ;sector number of dir  area 			;an047;bgb
root_entries   dw   0	;number of entries in root dir				;an047;bgb
fattbl_seg	dw	0   ;segment of the fat-table ;an005;bgb
sec_count	dw	0  ;sectors / 64k
secs_per_64k	dw	0			   ;an005;bgb
paras_per_64k	dw	0			   ;an005;bgb
fatsiz		dw	0			   ;an005;bgb
paras_per_fat	dw	0			   ;an005;bgb
fatcnt		db	2			;number of fats on disk 		;an005;bgb
HARDCH	dd	?			;Pointer to real INT 24 handler
CONTCH	DD	?			;Pointer to real INT 23 handler
THISDPB DD	?			;Pointer to drive DPB
USERDEV DB	?			;Users current device
CSIZE	DB	?			;Sectors per cluster 1-256
SSIZE	DW	?			;bytes per sector 1-64k
DSIZE	DW	?			;# alloc units on disk
MCLUS	DW	?			;DSIZE + 1
NAMBUF	DB	14 DUP (?)		;Buffer
DOTSNOGOOD DB	?			;. or .. error flag
ZEROTRUNC DB	?			;Trimming flag
ISCROSS DB	?			;Crosslink flag
OLDCLUS DW	?
SRFCBPT DW	?
fatmap	DW	?			;segment of fatmap table		;an005;bgb
end_of_fatmap dw ?			;last mem segment used			;an030;bgb
SECBUF	DW	?			;Offset of sector buffer (in ram)
ERRCNT	DB	?			;Used by FATread and write
PATH_NAME DB	128 DUP(0)
FNAME_LEN DW	128
NUL_ARG DB	?
ARG1	DW	?
ARG2	DW	?
ARG3	DW	?


;
; The following is used as a PRINTF buffer and also as the source/destination
; for a name trans
;
ARG_BUF DB	256 DUP (?)
TMP_SPC DB	128 DUP (?)
mon	dw	?
day	dw	?
year	dw	?
mem_size  dw	?
;;;TRANSRC DB	   "A:CON",0,0                     ; Device so we don't hit the drive
TRANSRC DB	"A:\",0,0                     ; Device so we don't hit the drive
Read_Write_Relative	Relative_Sector_Buffer <>  ;				;AN000;

STACKLIM DW	?			;Stack growth limit
INTERNATVARS	internat_block <>
		DB	(internat_block_max - ($ - INTERNATVARS)) DUP (?)


;	      Structure for Get_Media_Id					;an024;bgb
SerNumBuf	   Label Byte	   ;AN000;S GENERIC_IOCTL buffer		;an024;bgb
		   dw	0	   ;AN000;S Info level (set on input)		;an024;bgb
SerNum		   dd	0	   ;AN000;S Serial #				;an024;bgb
		   db	11 DUP(' ') ;AN000;S Volume label                       ;an024;bgb
		   db	8 DUP(' ') ;AN000;S File system type                    ;an024;bgb
DATA	ENDS

										;an000;bgb
										;an000;bgb
lastseg SEGMENT PUBLIC PARA 'LAST'                                              ;an000;bgb
 public fattbl									;an000;bgb
fattbl	db	0   ;this is the last thing in the pgm				;an000;bgb;an005;bgb
lastseg ends	    ;this is where the fat is put in ram			;an000;bgb

