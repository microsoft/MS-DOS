/*  */
/*									    */
/****************************************************************************/
/* Declare Global variables						   */
/****************************************************************************/
/*									    */



extern	char	cur_disk;						/* ;AN000; */
extern	FLAG	good_disk[2];						/* ;AN000; */
extern	unsigned char	 number_of_drives;				/* ;AN000; */
extern	FLAG	reboot_flag;						/* ;AN000; */
extern	char	errorlevel;						/* ;AN000; */
extern	char	max_partition_size;					/* ;AN000; */
extern	char	sort[24];						/* ;AN000; */
extern	FLAG	no_fatal_error; 					/* ;AC000; */
extern	char	valid_input;						/* ;AN000; */
extern	unsigned char	video_mode;					/* ;AN000; */
extern	unsigned char	display_page;					/* ;AN000; */

extern	unsigned	total_disk[2];					/* ;AN000; */
extern	XFLOAT		total_mbytes[2];				/* ;AN000; */
extern	unsigned char	max_sector[2];					/* ;AN000; */
extern	unsigned char	max_head[2];					/* ;AN000; */
extern	unsigned	required_cyls[2];				/* ;AN000; */

extern	unsigned       input_row;					/* ;AN000; */
extern	unsigned       input_col;					/* ;AN000; */
extern	char	       insert[800];					/* ;AC000; */
extern	char	       *pinsert;					/* ;AN000; */

extern unsigned char   master_boot_record[2][512];			/* ;AN000; */
extern unsigned char   boot_record[512];				/* ;AN000; */

extern	FLAG		next_letter;					/* ;AN000; */
extern	FLAG		primary_flag;					/* ;AN000; */
extern	FLAG		extended_flag;					/* ;AN000; */
extern	FLAG		logical_flag;					/* ;AN000; */
extern	FLAG		disk_flag;					/* ;AN000; */
extern	unsigned	primary_buff;					/* ;AN000; */
extern	unsigned	extended_buff;					/* ;AN000; */
extern	unsigned	logical_buff;					/* ;AN000; */
extern	char		cur_disk_buff;					/* ;AN000; */
extern	unsigned long	NOVAL;						/* ;AN000; */
extern	char		next_letter;					/* ;AN000; */


/*  */
/*									    */
/****************************************************************************/
/* Define Global structures						    */
/****************************************************************************/
/*									    */

extern	struct entry part_table[2][4];					/* ;AN000; */
extern	struct entry ext_table[2][24];					/* ;AN000; */
extern	struct freespace free_space[24];				/* ;AN000; */
extern	struct KeyData *input_data;					/* ;AN000; */
extern	struct dx_buffer_ioctl dx_buff; 				/* ;AN000; */
extern	struct SREGS segregs;						/* ;AN000; */
extern	struct subst_list sublist;					/* ;AN000; */

/*									    */
/****************************************************************************/
/* Define UNIONS							    */
/****************************************************************************/
/*									    */

extern	union REGS regs;						/* ;AN000; */

extern	char		*format_string; 				/* ;AN000; */
extern	char far	*fat12_String;					/* ;AN000; */
extern	char far	*fat16_String;					/* ;AN000; */
extern	char far	*hilda_string;					/* ;AN000; */
