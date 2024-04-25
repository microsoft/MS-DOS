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
 public fs_string_buffer, fs_string_end, len_fs_string_end, fs_not_fat, 	;AN000;bgb
 public fat12_string, fat16_string, len_fs_id_string, media_id_buffer,		;AN000;bgb
 public dirent, fcb_copy, filcnt, fatcnt, fatnum, fatsiz, firfat, fatptr ;AN000;bgb
 public secall, target, maxent, firrec, firdir, secsiz, siztmp, filsiz, maxclus ;AN000;bgb
 public lastfat, table, fattbl, dbcs_vector, dbcs_vector_off, dbcs_vector_seg	;AN000;bgb
 public read_write_relative, exec_block, exec_path, drive_letter_msg, path_string ;AN000;bgb
 public len_path_string, search_recover, len_search_recover, search_recover_end ;AN000;bgb
 public drvlet1, rec_num, x_value_lo, x_value_hi, y_value_lo, y_value_hi
 public bytes_per_sector, exit_sw, exit_sw2, paras_per_fat
data	ends ;put this 1st so that the recmsg works
;
;
;*****************************************************************************
; Public Data
;*****************************************************************************
;	Public	drvlet
;	Public	rec_num
;	Public	x_value_lo
;	Public	x_value_hi
;	Public	y_value_lo
;	Public	y_value_hi
;	Public	DrvLet1
;public drive_sublist ;AN000;bgb
;public path_si, env_ds
;	Public	FS_String_Buffer
;	Public	Fatal_Error
;	Public	ExitStatus
;	public	call_pars
;	PUBLIC	INT_23,std_printf,	; AC000;SM
;	Public	Read_Write_Relative
;	PUBLIC	filsiz
;	PUBLIC	FATTbl
;	Public	User_Drive
;	Public	Fname_Buffer
;	PUBLIC	Write_Disk,Read_Disk,report
;	Public Drive_Letter_Msg
