
/*  */
/*                                                                          */
/****************************************************************************/
/* Declare Global variables                                                */
/****************************************************************************/
/*                                                                          */



extern  char    cur_disk;
extern  FLAG    good_disk[2];
extern  unsigned char    number_of_drives;
extern  FLAG    reboot_flag;
extern  char    errorlevel;
extern  char    max_partition_size;
extern  char    sort[24];
extern  FLAG    no_fatal_error;                                         /* AC000 */
extern  char    valid_input;
extern  unsigned char   video_mode;
extern  unsigned char   display_page;
extern  unsigned char   video_attribute;                                /* AN006 */

extern  unsigned        total_disk[2];                                  /* AN000 */
extern  XFLOAT          total_mbytes[2];                                /* AN000 */
extern  unsigned char   max_sector[2];
extern  unsigned        max_head[2];                                    /* AC004 */
extern  unsigned        required_cyls[2];

extern  unsigned       input_row;
extern  unsigned       input_col;
extern  char           insert[800];                                     /* AC000 */
extern  char           *pinsert;

extern unsigned char   master_boot_record[2][512];
extern unsigned char   boot_record[512];

extern  char            next_letter;                                    /* AN000 */
extern  FLAG            primary_flag;                                   /* AN000 */
extern  FLAG            extended_flag;                                  /* AN000 */
extern  FLAG            logical_flag;                                   /* AN000 */
extern  FLAG            disk_flag;                                      /* AN000 */
extern  FLAG            quiet_flag;                                     /* AN000 */
extern  unsigned        primary_buff;                                   /* AN000 */
extern  unsigned        extended_buff;                                  /* AN000 */
extern  unsigned        logical_buff;                                   /* AN000 */
extern  char            cur_disk_buff;                                  /* AN000 */
extern  unsigned long   NOVAL;                                          /* AN000 */
extern  char            next_letter;                                    /* AN000 */
extern  FLAG            PercentFlag;                                    /* AN000 */

extern  FLAG            mono_flag;                                      /* AN006 */

extern  char            Yes;                                            /* AN012 */
extern  char            No;                                             /* AN012 */

extern  unsigned        Parse_Ptr;                                      /* AN010 */
/*  */
/*                                                                          */
/****************************************************************************/
/* Define Global structures                                                 */
/****************************************************************************/
/*                                                                          */

extern  struct entry part_table[2][4];
extern  struct entry ext_table[2][24];
extern  struct freespace free_space[24];
extern  struct KeyData *input_data;
extern  struct dx_buffer_ioctl dx_buff;                                 /* AN000 */
extern  struct SREGS segregs;
extern  struct subst_list sublist;                                      /* AN000 */
extern  struct diskaccess disk_access;                                  /* AN002 */
extern  struct sublistx sublistp[1];                                    /* AN010 */

/*                                                                          */
/****************************************************************************/
/* Define UNIONS                                                            */
/****************************************************************************/
/*                                                                          */

extern  union REGS regs;

