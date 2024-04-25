
#include "dos.h"                                                        /* ;AN000; */
#include "get_stat.h"                                                   /* ;AN000; */

/*  */
/*									    */
/****************************************************************************/
/* Declare Global variables						   */
/****************************************************************************/
/*									    */



char	cur_disk;							/* ;AN000; */
char	good_disk[2];							/* ;AN000; */
unsigned char	 number_of_drives;					/* ;AN000; */
char	reboot_flag;							/* ;AN000; */
char	errorlevel;							/* ;AN000; */
char	max_partition_size;						/* ;AN000; */
char	sort[24];							/* ;AN000; */
char	no_fatal_error; 						/* ;AN000; */
char	valid_input;							/* ;AN000; */
unsigned char	video_mode;						/* ;AN000; */
unsigned char	display_page;						/* ;AN000; */


unsigned	total_disk[2];						/* ;AN000; */
unsigned	total_mbytes[2];					/* ;AN000; */
unsigned char	max_sector[2];						/* ;AN000; */
unsigned char	max_head[2];						/* ;AN000; */
unsigned	required_cyls[2];					/* ;AN000; */

unsigned       input_row;						/* ;AN000; */
unsigned       input_col;						/* ;AN000; */
char	       insert[800];						/* ;AC000; */
char	       *pinsert = insert;					/* ;AN000; */

extern unsigned char   master_boot_record[2][512];			/* ;AN000; */
unsigned char	boot_record[512];					/* ;AN000; */

char		next_letter;						/* ;AN000; */
char		primary_flag;						/* ;AC000; */
char		extended_flag;						/* ;AC000; */
char		logical_flag;						/* ;AC000; */
unsigned	primary_buff;						/* ;AC000; */
unsigned	extended_buff;						/* ;AC000; */
unsigned	logical_buff;						/* ;AC000; */
char		cur_disk_buff;						/* ;AC000; */
unsigned long	NOVAL = (unsigned long) 0;				/* ;AC000; */


/*  */
/*									    */
/****************************************************************************/
/* Define Global structures						    */
/****************************************************************************/
/*									    */

struct entry part_table[2][4];						/* ;AN000; */
struct entry ext_table[2][24];						/* ;AN000; */
struct freespace free_space[24];					/* ;AN000; */
struct KeyData *input_data;						/* ;AN000; */
struct dx_buffer_ioctl dx_buff; 					/* ;AN000; */
struct SREGS segregs;							/* ;AN000; */

/*									    */
/****************************************************************************/
/* Define UNIONS							    */
/****************************************************************************/
/*									    */

union REGS regs;							/* ;AN000; */


char		*format_string = "NO FORMAT";                           /* ;AN000; */
char far	*fat12_String = "FAT_12";                               /* ;AN000; */
char far	*fat16_String = "FAT_12";                               /* ;AN000; */
char far	*hilda_string = "HILDA";                                /* ;AN000; */
