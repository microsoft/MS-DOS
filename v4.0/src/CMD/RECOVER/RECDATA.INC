
 data	 segment PUBLIC para 'DATA'      ;AC000;bgb
;*****************************************************************************
; Data Area
;*****************************************************************************
;
lastchar      dw 0								;an024;bgb
lastbs	      dw 0								;an024;bgb
fndback       dw 0	    ;point to where backslash found
old_subdir    db 64 dup(0) ;current sub directory
new_subdir    db 64 dup(0) ;new     sub directory
paras_per_64k dw 0
paras_per_fat dw 0
secs_per_64k  dw 0
sec_count     dw 0
sixteen     dw	   16			; mul ax for 32 bytes / fat entry
exit_sw     dw	    ?			; loop exit switch			;AN000;bgb
exit_sw2    dw	    ?			; loop exit switch			;AN000;bgb
old_drive     db 0			;original drive to restore to		;an008;bgb
drvlet	    db	    'A: ',13,10,13,10,0         ;                               ;AN000;
rec_num     dw	    ?				;				;AN000;
x_value_lo  dw	?				;				;AN000;
x_value_hi  dw	?				;				;AN000;
y_value_lo  dw	?				;				;AN000;
y_value_hi  dw	?				;				;AN000;
DRVLET1     db	    "A",0
;
 HEADER  DB	 "Vers 2.00"
;-----------------------------------------------------------------------;
 Prompted db	 0			 ; TRUE => prompt has already been done
 hardch  dd	 ?			 ; saved int 24 vector
 the_root db	 0			 ; root directory flag
 fudge	 db	 0			 ; directory changed flag
 user_drive db	 0
 drive	 db	 0
 dirchar db	 "/",0
 userdir db	 "/",0
	 db	 (dirstrlen) dup(0)
 fname_buffer db 128 dup(0)

found	db	no
done	db	no
PSP_Segment dw	0
ExitStatus db	0			;Errorlevel code		;AN000;

					;
BPB_Buffer A_DeviceParameters <>	;				;AN000;

TranSrc db	"A:\",0                 ;                               ;AN000;

Data_Start_Low dw ?			;				;AN000;
Data_Start_High dw ?			;				;AN000;

INT_23_Old_Off dw ?			;				;AN000;
INT_23_Old_Seg dw ?			;				;AN000;
INT_24_Old_Off dw ?			;				;AN000;
INT_24_Old_Seg dw ?			;				;AN000;


Command_Line_Buffer db 128 dup(0)	;				;AN000;
Fatal_Error db	0			;				;AN000;

Command_Line db NO			;				;AN000;

;These should stay together			;				;an022;bgb
; ---------------------------------------	;  ;				;an022;bgb
ifdef fsexec									;an022;bgb
 FS_String_Buffer db 13 dup(" ")         ;                            ;AN000;    ;an022;bgb
 FS_String_End db "REC.EXE",0            ;                            ;AN000;    ;an022;bgb
;----------------------------------------	;				;an022;bgb
 FS_Not_Fat db	 0			 ;				 ;AN000;;an022;bgb
FAT12_String db "FAT12   "              ;
FAT16_String db "FAT16   "              ;

Media_ID_Buffer Media_ID <>		;				;AN000;
endif										;an022;bgb

Append	db	0			;


dirent	db	'FILE0000REC'
	db	21 dup (00)

fcb_copy db	32 dup (?)

filcnt	dw	0000
fatcnt	db	00
fatnum	db	00
fatsiz	dw	0000
firfat	dw	0000
fatptr	dw	0000
secall	dw	0000			; sectors per cluster
target	dw	0000
maxent	dw	0000
firrec	dw	0000
firdir	dw	0000
bytes_per_sector  dw	  0000
secsiz	dw	0000
siztmp	dw	0000
	dw	0000
filsiz	dw	0000
	dw	0000 ;carry noted here - 2 bytes after filsiz
MaxClus DW	0
lastfat dw	0000
;
dbcs_sw 	    db	    0 ;zero if not dbcs - one if dbcs found	       ;an024;bgb
DBCS_Vector	    db	    0
DBCS_Vector_Off     dw	    0
DBCS_Vector_Seg     dw	    0
Read_Write_Relative Relative_Sector_Buffer  <>
Drive_Letter_Msg db "A:",0                      ;Drive for exec fail message

ifdef fsexec									;an022;bgb
;Exec_Block	 Exec_Block_Parms <>						;an022;bgb
;EXEC_Path	 db    66 dup(0)						;an022;bgb
;These next two should stay together
; ---------------------------------------
;Path_String db  "PATH="                         ;                               ;an022;bgb
;Len_Path_String equ 5			 ; length of path= string   ;AN000;bgb	 ;an022;bgb
endif										;an022;bgb
						;
;----------------------------------------
driveLetter db	"X",":",0


						;				;     ;
;----------------------------------------

;Path_SI dw	 0
;Env_DS  dw	 0
table	dw	offset dg:fattbl	  ;AC000;bgb
data	ends


;*****************************************************************************
; LAST DATA AREA
; this data area writes over ram, so leave it at the very end of the pgm.
;*****************************************************************************
lastseg  segment PUBLIC para 'last'      ;AC000;bgb
	assume	ds:dg
fattbl	db	0			  ;AC000;bgb
lastseg ends			  ;AN000;bgb

;
data	segment public para 'DATA'      ;AC000;bgb
;******************************************************************************
; Public Data
;******************************************************************************
 public header, prompted, hardch, the_root, fudge, user_drive, drive, dirchar	;AN000;bgb
 public userdir, fname_buffer, found, done, driveletter, psp_segment, exitstatus ;AN000;bgb
 public drvlet, bpb_buffer, transrc, data_start_low, data_start_high,		;AN000;bgb
 public int_23_old_off, int_23_old_seg, int_24_old_off, int_24_old_seg, append	;AN000;bgb
 public command_line_buffer, command_line_length, fatal_error, command_line,	;AN000;bgb
ifdef fsexec									;an022;bgb
 public fs_string_buffer, fs_string_end, len_fs_string_end, fs_not_fat, 	;an022;bgb;AN000;bgb
 public fat12_string, fat16_string, len_fs_id_string, media_id_buffer,		;an022;bgb;AN000;bgb
 public exec_block, exec_path, path_string ;AN000;bgb				;an022;bgb
 public len_path_string 							;an022;bgb;AN011;bgb
 endif										;an022;bgb
 public dirent, fcb_copy, filcnt, fatcnt, fatnum, fatsiz, firfat, fatptr ;AN000;bgb
 public secall, target, maxent, firrec, firdir, secsiz, siztmp, filsiz, maxclus ;AN000;bgb
 public lastfat, table, fattbl, dbcs_vector, dbcs_vector_off, dbcs_vector_seg	;AN000;bgb
 public read_write_relative, drive_letter_msg ;AN000;bgb			;an022;bgb
 public drvlet1, rec_num, x_value_lo, x_value_hi, y_value_lo, y_value_hi
 public bytes_per_sector, exit_sw, exit_sw2, paras_per_fat, secs_per_64k
 public sec_count, paras_per_64k
data	ends ;put this 1st so that the recmsg works
