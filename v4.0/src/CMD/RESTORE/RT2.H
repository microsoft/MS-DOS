/*  0 */
/*---------------------------------------------------------
/*-
/*- RESTORE Utility include file RT2.H
/*-
/*---------------------------------------------------------*/



/*------------------------------------*/
/*	 MESSAGE DEFINITIONS	      */
/*------------------------------------*/
#define INVPARM 10				/* Parse class */     /*;AN000;6*/

#define  INVALID_DOS_VER		1	/*;AN000;6*/
#define  SOURCE_TARGET_SAME		2	/*;AN000;6*/
#define  INVALID_NUM_PARM		3	/*;AN000;6*/
#define  PATH_NOT_FOUND 		5	/*;AN000;6*/
#define  INVALID_DRIVE			6	/*;AN000;6*/
#define  NO_FILE_TO_RESTORE		7	/*;AN000;6*/
#define  INSERT_SOURCE_DISK		8	/*;AN000;6*/
#define  INSERT_TARGET_DISK		9	/*;AN000;6*/
#define  PRESS_ANY_KEY		       10	/*;AN000;6*/
#define  DISK_OUT_OF_SEQUENCE	       11	/*;AN000;6*/
#define  LAST_FILE_NOT_RESTORED        12	/*;AN000;6*/
#define  FILES_WERE_BACKUP_ON	       13	/*;AN000;6*/
#define  SOURCE_NO_BACKUP_FILE	       14	/*;AN000;6*/
#define  INSUFFICIENT_MEMORY	       15	/*;AN000;6*/
#define  FILE_IS_READONLY	       16	/*;AN000;6*/
#define  FILE_SEQUENCE_ERROR	       17	/*;AN000;6*/
#define  FILE_CREATION_ERROR	       18	/*;AN000;6*/
#define  TARGET_IS_FULL 	       19	/*;AN000;6*/
#define  NOT_ABLE_TO_RESTORE_FILE      20	/*;AN000;6*/
#define  RESTORE_FILE_FROM_DRIVE       21	/*;AN000;6*/
#define  FILE_WAS_CHANGED	       22	/*;AN000;6*/
#define  DISKETTE_NUM		       23	/*;AN000;6*/

#define  INV_DATE		       27	/*;AN000;6*/
#define  INV_TIME		       28	/*;AN000;6*/
#define  NO_SOURCE		       29	/*;AN000;6*/
#define  NO_TARGET		       30	/*;AN000;6*/
#define  CRLF			       31	/*;AN000;6*/

#define  FILE_TO_BE_RESTORED	       99	/*;AN000;6*/

/*------------------------------------*/
/*-	   MESSAGE CLASSES	     -*/
/*------------------------------------*/
#define EXTENDED	1					      /*;AN000;6*/
#define PARSEERR	2					      /*;AN000;6*/
#define UTILMSG        -1					      /*;AN000;6*/

/* 0*/
/*----------------------------------*/
/*-    SUBROUTINE DECLARATIONS	    */
/*----------------------------------*/
void   main(int ,char *[0]);
void   set_input_switches(WORD,BYTE * *,WORD *,struct timedate *);
void   verify_input_switches(BYTE *,struct timedate   *);
int    set_reset_test_flag(BYTE *,BYTE ,int );
void   separate(BYTE *,BYTE *,BYTE *,BYTE *,BYTE *);
void   initbuf(DWORD *);
void   init_control_buf(unsigned long ,unsigned int   *);
void   usererror(WORD );
void   unexperror(WORD );
void   exit_routine(WORD );
void   pascal far signal_handler_routine(void );
extern unsigned far pascal set_int24_vector(void);	      /*;AN000;*/
void   com_msg(WORD );
int    checkdosver(void );
void   dorestore(BYTE ,BYTE ,BYTE *,BYTE *,BYTE *,BYTE *,struct timedate *);
void   check_bkdisk_old(struct disk_header_old *,    struct disk_info *,BYTE,unsigned int *);
void   check_bkdisk_new(struct disk_header_new far *,struct disk_info *,BYTE,unsigned int *,unsigned int *);
void   print_info(int ,int ,int);
WORD   pathmatch(BYTE *,BYTE *);
WORD   switchmatch(struct file_info *,BYTE,BYTE,struct timedate *);

int    check_flheader_old(struct file_info *,unsigned char *,unsigned int ,
			  unsigned int ,unsigned int ,unsigned long ,unsigned int ,unsigned char ,
			  unsigned char ,unsigned char *,unsigned char *,unsigned int  *);

int    readonly_or_changed(unsigned int ,unsigned char ,unsigned char	*, unsigned char *);
int    fspecmatch(char *,char *);
WORD   open_dest_file(struct file_info	 *,BYTE );
void   build_path_create_file(BYTE *,BYTE,BYTE,DWORD);		      /*;AC000;3*/
int    set_attributes_and_close(struct file_info *, BYTE);
int    dos_write_error(DWORD ,BYTE );
int    findfile_new(struct file_info *,WORD *,unsigned int *,BYTE *,BYTE *,WORD far * *,WORD far * *,unsigned int *,BYTE *);
int    findnew_new(struct file_info *,WORD *,WORD *,BYTE *,BYTE *, WORD far * *,WORD far * *,WORD *,BYTE *);

 void  search_src_disk_old(struct disk_info *,struct file_info *,struct disk_header_old *,
	     struct disk_header_new far *,struct file_header_new far *,
	     unsigned char,unsigned char,unsigned long,unsigned int *,unsigned char *,unsigned char *,
	     unsigned char *,unsigned char *,struct timedate *);

 void	 search_src_disk_new(struct disk_info *,struct file_info *,struct disk_header_old *,
	     struct disk_header_new far *,struct file_header_new far *,
	     unsigned char,unsigned char,unsigned int *,unsigned long,unsigned char *,unsigned char *,
	     unsigned char *,unsigned int *,struct timedate *);

int    findfirst_new(struct file_info *,WORD *,unsigned int *,BYTE *,BYTE *,WORD far**,WORD far**,unsigned int *,BYTE *);
int    findnext_new (struct file_info *,WORD *,unsigned int *,BYTE *,BYTE *,WORD far**,WORD far**,unsigned int *,BYTE *);

void   restore_a_file(struct file_info *,struct disk_info *,unsigned long,unsigned int *,
	struct file_header_new far *,struct disk_header_old *,struct disk_header_new far *,unsigned char,unsigned char,
	unsigned char *,unsigned char *,unsigned char *,unsigned int *,unsigned int *);

/*----------------------------------------
/*-  ADDED FOR DOS 4.00
/*----------------------------------------*/
int  cdecl	sprintf(char *,const char *, ...);
int  cdecl	printf(const char *,...);
void check_time(BYTE,BYTE,BYTE,BYTE);				      /*;AN000;4*//*;AC002;*/
void check_date(WORD,BYTE,BYTE);				      /*;AN000;4*//*;AC002;*/
void parse_error(WORD,BYTE);					      /*;AN000;4*//*;AC002;*/
void parse_init(void);						      /*;AN000;4*/
void process_switch(unsigned,char *);				      /*;AN000;4*//*;AC002;*/
void check_source_drive(int,char * []); 			      /*;AN000;4*/
void check_target_filespec(int,char * []);			      /*;AN000;4*/
void display_it(WORD,WORD,WORD,WORD,BYTE);			      /*;AN000;6*/
void parse_command_line(int, char * []);			      /*;AN000;4*/
void check_appendX(void);					      /*;AN000;2*/
void	read_in_first_dirblock(void);			     /* !wrw */
void	read_in_a_fileheader(void);			     /* !wrw */
void	read_in_next_dirblock(void);			     /* !wrw */
void	get_fileheader_length(void);				      /*;AN000;3*/
WORD	create_the_file(BYTE,DWORD);				      /*;AN000;3*/
void	read_the_extended_attributes(DWORD);			      /*;AN000;3*/
void	check_for_device_names(char * []);			      /*;AN000;p2591*/
WORD chek_DBCS(char *,WORD,char);				      /*;AN005;*/
void Get_DBCS_vector(void);					      /*;AN005;*/

extern	void	sysloadmsg(union REGS *, union REGS *);   /*_msgret *//*;AN000;6 */
extern	void	sysdispmsg(union REGS *, union REGS *);   /*_msgret *//*;AN000;6 */
extern	void	parse	  (union REGS *, union REGS *);   /* _parse *//*;AN000;4 */

