/*0  */
/*-----------------------------------------------------------
/*-
/*- FILE:     BACKUP.H
/*-
/*- PURPOSE: For the BACKUP utility, this file has the required
/*-	     BACKUP defines, message numbers, structures,
/*-	     and subroutine declarations.
/*-
/*---------------------------------------------------------*/

/*----------------------
/*- Utility #DEFINES...
/*----------------------*/

#define DHLENGTH 139	/* Length, in bytes, of a Disk Header */
#define DBLENGTH  70	/* Length, in bytes, of a Directory Block */
#define FHLENGTH  34	/* Length, in bytes, of a File Header */

#define BYTE	unsigned char
#define WORD	unsigned short
#define DWORD	unsigned long

#define NOERROR 0
#define NUL 0

#define FALSE	0
#define TRUE	!FALSE

#define BACKSLASH   0x5c

#define READONLYOFF 254 	/* bit mask, will be ANDed with current attribute to turn off readonly bit */

#define READONLY    0x01	/* File Attributes */
#define HIDDEN	    0x02
#define SYSTEM	    0x04
#define VOLLABEL    0x08
#define SUBDIR	    0x10
#define ARCHIVE     0x20

#define DENYALL     0x10	/* Sharing Mode */
#define DENYWRITE   0x20
#define DENYREAD    0x30
#define DENYNONE    0x40

#define READACCESS  0x00	/* Access Modes */
#define WRITEACCESS 0x01
#define READWRITE   0x02


#define NO_CP_CHECK 0x100	       /*;AN000;5*/

#define SYNCHRONOUS 0x4000	/* OS/2 File Write-Through */
#define NOTSYNCHRONOUS 0x0000	/* OS/2 File Write-Through */
#define OPENDASD    0x8000	/* OS/2 Open a DASD device */
#define OPEN_IT    0x01 		/*;AN000;5*/
#define CREATE_IT  0x12 		/*;AN000;5*/

#define NO_INHERIT	0x80	    /* Inheritance bit */

#define STDIN	    0x00	/* Predefined handles */
#define STDOUT	    0x01
#define STDERR	    0x02

#define BOFILE	0		/* LSEEK move methods */
#define CURRPOS 1
#define EOFILE	2

#define GET	0		/* CHMOD functions */
#define SET	1

#define SSTRING       0x2000	/*;AN000;4  Parser Match Flags */
#define DATESTRING    0x1000	/*;AN000;4*/
#define TIMESTRING    0x0800	/*;AN000;4*/
#define FILESPEC      0x0200	/*;AN000;4*/
#define DRIVELETTER   0x0100	/*;AN000;4*/
#define OPTIONAL      0x0001	/*;AN000;4*/

#define CAP_FILETABLE 0x0001	/*;AN000;4  Parser Function flag*/
#define CAP_CHARTABLE 0x0002	/*;AN000;4  Parser Function flag*/

#define LABELLEN 11

#define SETLOGICALDRIVE 0x440F		/*;AN000;8 */


/*--------APPEND FUNCTIONS-----------*/
#define INSTALL_CHECK	0xB700			/*;AN000;2*/
#define NOT_INSTALLED 0 			/*;AN000;2*/
#define GET_APPEND_VER	0xB702			/*;AN000;2*/
#define NET_APPEND    1 			/*;AN000;2*/
#define DOS_APPEND    2 			/*;AN000;2*/
#define GET_STATE	0xB706			/*;AN000;2*/
#define SET_STATE	0xB707			/*;AN000;2*/

#define APPEND_X_BIT	0x8000			/*;AN000;2*/



#define ACTIONHOOK	2
#define CTRLC		1
#define CTRLBREAK	4

#define EOL	       -1		/*;AN000;4*/
#define QUOTED_STRING	9		/*;AN000;4*/
#define RET_DATE	7		/*;AN000;4*/
#define RET_TIME	8		/*;AN000;4*/

#define CPSW_ACTIVE 1			/*;AN000;3*/
#define CPSW_NOTACTIVE 0		/*;AN000;3*/
#define GET_CPSW 0x3303 		/*;AN000;3*/

#define CARRY 0x0001			/*;AN000;*/
/***********************************/
/* Utility-specific definitions    */
/***********************************/

#define ROOTDIR    0
#define BACKUPDIR  1

#define PUT_SEG(fp,seg)  (*((unsigned *)&(fp)+1)) = (unsigned) seg
#define PUT_OFF(fp,off)  (*((unsigned *)&(fp))) = (unsigned) off

#define MAXMSGLEN	     160
#define PATHLEN 	      64
#define MAX_RETRY_OPEN_COUNT   5

#define RETCODE_NO_ERROR      0 	/* Errorlevels */
#define RETCODE_NO_FILES      1
#define RETCODE_SHARE_ERROR   2
#define RETCODE_CTL_BREAK     3
#define RETCODE_ERROR	      4

/************************************************/
/*	NOTE FROM PARSER SUBROUTINE !!!!!	*/
/************************************************/
/* The SECONDS bits in the DOS Directory are in */
/*  2-second increments. Therefore, div by 2,	*/
/*  take the integer portion and use in search. */
/* Note that files can be backed up that were	*/
/* modified 1 second before the time that a user*/
/* enters, which is better than not backing up	*/
/* a file that was modified at exactly that time*/
/************************************************/

/*-------------------------------------------*/
/*------	 BACKUP messages     --------*/
/*-------------------------------------------*/
#define BAD_DOS_VER	      1 	/*;AN000;6*/
#define INSUFF_MEMORY	      2 	/*;AN000;6*/

#define INV_DRIVE	      6 	/*;AN000;6*/
#define INV_DATE	      7 	/*;AN000;6*/
#define INV_TIME	      8 	/*;AN000;6*/

#define INV_PATH	     11 	/*;AN000;6*/
#define NO_SOURCE	     12 	/*;AN000;6*/
#define NO_TARGET	     13 	/*;AN000;6*/
#define SRC_AND_TGT_SAME     14 	/*;AN000;6*/
#define ERR_EXEC_FORMAT      15 	/*;AN000;6*/
#define CANT_FIND_FORMAT     16 	/*;AN000;d178*/
#define CANT_OPEN_LOGFILE    17 	/*;AN000;6*/
#define LOGGING 	     18 	/*;AN000;6*/
#define NOTLASTMSG	     19 	/*;AN000;6*/
#define ERASEMSG	     20 	/*;AN000;6*/
#define FERASEMSG	     21 	/*;AN000;6*/
#define BUDISKMSG	     22 	/*;AN000;6*/
#define SEQUENCEMSG	     23 	/*;AN000;6*/
#define NONEFNDMSG	     24 	/*;AN000;6*/
#define INSERTSOURCE	     25 	/*;AN000;6*/
#define INSERTTARGET	     26 	/*;AN000;6*/
#define CONFLICTMSG	     27 	/*;AN000;6*/
#define LASTDISKMSG	     28 	/*;AN000;6*/
#define INVTARGET	     29 	/*;AN000;6*/
#define LASTNOTBACKUP	     30 	/*;AN000;6*/
#define FDISKFULLMSG	     31 	/*;AN000;6*/
#define LOGFILE_TARGET_FULL  32 	/*;AN000;6*/
#define PRESS_ANY_KEY	     33 	/*;AN000;6*/
#define CRLF		     34 	/*;AN000;6*/
#define CANT_FORMAT_HARDFILE 35 	/*;AN000;/*

/*------------------------------------*/
/*-	   MESSAGE CLASSES	     -*/
/*------------------------------------*/
#define EXTENDED	1		/*;AN000;6*/
#define PARSEERROR	2		/*;AN000;6*/
#define UTIL_MSG       -1		/*;AN000;6*/

#define NOWAIT	0			/*;AN000;6*/
#define WAIT	0xc8			/*;AN000;6*/


/*-------------------------------------------------------------*/
/*-   CONTROL BLOCK FOR EACH BACKUP DISKETTE		       */
/*-------------------------------------------------------------*/
/*-   THIS STRUCTURE WILL MAKE UP THE FIRST DH_DHLength BYTES  */
/*-   OF THE control.xxx FILE ON THE BACKUP TARGET.	       */
/*-   IT IDENTIFIES THE DISK AS BEING A BACKUP, AND INCLUDES   */
/*-   DISKETTE SEQUENCE NUMBER AND A FLAG INDICATING IF THIS   */
/*-   IS THE LAST TARGET.				       */
/*-------------------------------------------------------------*/

#define LAST_TARGET	0xFF
#define NOT_LAST_TARGET 0x00

struct Disk_Header
  {
    BYTE  DH_Length;		/* Length, in bytes, of disk header */
    BYTE  DH_Identifier[8];	/* Identifies disk as a backup */
    BYTE  DH_Sequence;		/* Backup diskette seq num (1-255) */
    BYTE  DH_reserved [128];	/* Save area for nothing */
    BYTE  DH_LastDisk;		/* Indicates if this is last target */
				/* 0xFF if last target, 0 otherwise */
  };


/*----------------------------------------------------------------------*/
/*-   DIRECTORY BLOCK							*/
/*----------------------------------------------------------------------*/
/*- THIS STRUCTURE IS WRITTEN TO THE control.xxx FILE AT LEAST ONCE	*/
/*- FOR EACH SUBDIRECTORY, INCLUDING THE ROOT, BACKED UP. IT CONTAINS	*/
/*- THE PATH TO THAT DIRECTORY, THE NUMBER OF FILES FROM THAT		*/
/*- DIRECTORY THAT ARE BACKED UP ON CURRENT TARGET, AND THE OFFSET	*/
/*- OF THE NEXT DIRECTORY BLOCK ON THAT DISKETTE, IF ONE EXISTS.	*/
/*- IF THERE ARE NO OTHER DIRECTORY BLOCKS, IT EQUALS 0xffffffff.	*/
/*----------------------------------------------------------------------*/
#define LAST_DB 0xFFFFFFFF

struct Dir_Block
  {
    BYTE  DB_Length;		/* Length, in bytes, of dir block */
    BYTE  DB_Path[63];
				/* ASCII path of this directory, */
				/* drive letter omitted */
    WORD  DB_NumEntries;	/* Num of filenames currently in list*/
    DWORD DB_NextDB;		/* Offset of next directory block */
  };				/* =0xffffffff if there are no more*/
				/* on current target */

/*--------------------------------------------------------------------*/
/*-   CONTROL BLOCK FOR EACH BACKED-UP FILE			      */
/*--------------------------------------------------------------------*/
/*- THIS STRUCTURE WILL BE REPEATED AFTER THE DIRECTORYBLOCK ONCE     */
/*- FOR EACH FILE BACKED UP FROM THAT DIRECTORY. IT CONTAINS THE      */
/*- FILENAME, DIRECTORY INFORMATION, AND OTHER NECESSARY INFORMATION. */
/*--------------------------------------------------------------------*/
#define NOTLASTPART    0
#define LASTPART       1

#define NOTSUCCESSFUL  0
#define SUCCESSFUL     2

#define EXT_ATTR       4	/*;AN000;3*/

struct File_Header
 {
    BYTE   FH_Length;		/* Length, in bytes, of file header */
    BYTE   FH_FName[12];	/* ASCII file name (from directory)*/
    BYTE   FH_Flags;		/* bit 0=1 if last part of file */
				/* bit 1=1 if it is backed  up successfully */
				/* bit 2=1 if Extended Attributes are backed up (New for DOS4.00) ;AN000;3*/
    DWORD  FH_FLength;		/* Total length of the file (from directory) */
    WORD   FH_FSequence;	/* Sequence #, for files that span */
    DWORD  FH_BeginOffset;	/* Offset in BACKUP.xxx where this segment begins */
    DWORD  FH_PartSize; 	/* Length of part of file on current target */
    WORD   FH_Attribute;	/* File attribute (from directory) */
    WORD   FH_FTime;		/* Time when file was last modified (from directory)*/
    WORD   FH_FDate;		/* Date when file was last modified (from directory)*/
  };

/*--------------------------------------------------------------------*/
/*-   THIS IS THE STRUCTURE THAT IS USED IN THE LINKED LIST OF	      */
/*-   DIRECTORIES THAT NEED TO BE PROCESSED (if /S option specified)  */
/*--------------------------------------------------------------------*/
 struct node
  {
    struct node   *np;
    char	  path[PATHLEN+15];
  };


/*--------------------------------------------------------------------*/
/*-   THIS IS THE STRUCTURE THAT IS USED BY THE DOS FUNCTION	      */
/*-   "RETURN COUNTRY INFORMATION"                                    */
/*--------------------------------------------------------------------*/
 struct ctry_info_blk
  {
    WORD	country_code;
    WORD	code_page;
    WORD	date_format;
#define USA	0
#define EUR	1
#define JAP	2
    BYTE	currency_symbol[5];
    WORD	thousands_separator;
    WORD	decimal_Separator;
    WORD	date_separator;
    WORD	time_separator;
    BYTE	currency_format;
    BYTE	num_sig_dec_dig_in_currency;
    BYTE	time_format;
    DWORD	case_map_call;
    WORD	data_list_separator;
    WORD	reserved[5];
  };

/*------------------------------------------------------------------------*/
/*-   THIS STRUCTURE IS USED BY THE DOS MESSAGE HANDLER SERVICE ROUTINES -*/
/*------------------------------------------------------------------------*/

	/************************************************/
	/*    Substitution List for Message Retriever	*/
	/************************************************/
/*-----------------------
; SUBLIST Equates
;------------------------*/
#define SUBLIST_SIZE	11	     /*;AN000;6*/

#define LEFT_ALIGN	      0x0    /*;AN000;600xxxxxx  */
#define RIGHT_ALIGN	      0x80   /*;AN000;610xxxxxx  */

#define CHAR_FIELD_CHAR       0x0    /*;AN000;6a0000000  */
#define CHAR_FIELD_ASCIIZ     0x10   /*;AN000;6a0010000  */

#define UNSGN_BIN_BYTE	      0x11   /*;AN000;6a0010001 - Unsigned BINary to Decimal CHARacter */
#define UNSGN_BIN_WORD	      0x21   /*;AN000;6a0100001  */
#define UNSGN_BIN_DWORD       0x31   /*;AN000;6a0110001  */


/*---------------------------------------------*/
/*-  Message substitution list structure      -*/
/*---------------------------------------------*/
 struct subst_list						      /*;AN000;6*/
  {								      /*;AN000;6*/
    BYTE	sl_size1;      /* Size of List */		      /*;AN000;6*/
    BYTE	zero1;	       /* Reserved */			      /*;AN000;6*/
    char far   *value1;        /* Time, date, or ptr to data item*/   /*;AN000;6*/
    BYTE	one;	       /* n of %n */			      /*;AN000;6*/
    BYTE	flags1;        /* Data Type flags */		      /*;AN000;6*/
    BYTE	max_width1;    /* Maximum FIELD width */	      /*;AN000;6*/
    BYTE	min_width1;    /* Minimum FIELD width */	      /*;AN000;6*/
    BYTE	pad_char1;     /* Character for pad FIELD */	      /*;AN000;6*/

    BYTE	sl_size2;      /* Size of List */		      /*;AN000;6*/
    BYTE	zero2;	       /* Reserved */			      /*;AN000;6*/
    char far   *value2;        /* Time; date; or ptr to data item*/   /*;AN000;6*/
    BYTE	two;	       /* n of %n */			      /*;AN000;6*/
    BYTE	flags2;        /* Data Type flags */		      /*;AN000;6*/
    BYTE	max_width2;    /* Maximum FIELD width */	      /*;AN000;6*/
    BYTE	min_width2;    /* Minimum FIELD width */	      /*;AN000;6*/
    BYTE	pad_char2;     /* Character for pad FIELD */	      /*;AN000;6*/
  };								      /*;AN000;6*/

/*----------------------------------*/
/*-  EXTENDED OPEN PARAMETER LIST  -*/
/*----------------------------------*/
#define EXTATTBUFLEN 4086					      /*;AN000;3*/
 struct parm_list						      /*;AN000;3*/
  {								      /*;AN000;3*/
    DWORD	ext_attr_addr;					      /*;AN000;3*/
    WORD	num_additional; 				      /*;AN000;3*/
    BYTE	id_io_mode;					      /*;AN000;3*/
    WORD	io_mode;					      /*;AN000;3*/
  };								      /*;AN000;3*/

/*  */
/*----------------------------------------------------*/
/*-	SUBROUTINE DECLARATIONS 		     -*/
/*----------------------------------------------------*/
	int cdecl	sprintf(char *, char *, ...);
	int cdecl	 printf(char *,...);

	void	alloc_buffer(void);
	void	alloc_first_node(void);
	struct	node * alloc_node(unsigned int);
	void	check_appendX(void);				      /*;AN000;2*/
	void	alloc_seg(void);
	void	build_ext(int);
	void	change_levels(void);
	void	check_date(WORD,BYTE,BYTE);			      /*;AN000;4*/
	void	check_DOS_version(void);
	void	check_drive_validity(int,char * []);
	void	check_for_device_names(char * []);		      /*;AN000;p2592*/
	void	check_last_target(void);
	void	check_path_validity(char * []);
	void	check_time(BYTE,BYTE,BYTE,BYTE);		      /*;AN000;4*/
	void	clean_up_and_exit(void);
	void	close_file(WORD);
	void	close_out_current_target(void);
	void	control_break_handler(void);
	void	create_target(void);
	void	datetime(void);
	void	delete(char *);
	void	delete_files(char);
	long	disk_free_space(void);
	void	display_it(int,WORD,int,BYTE,BYTE);		      /*;AN000;6*/
	void	display_msg(int);
	void	do_backup(void);
	void	do_copy(void);
	void	do_dos_error(WORD);
	extern unsigned far pascal set_int24_vector(void);	      /*;AN000;*/
	void	error_exit(int);
	WORD	exist(char *);
	WORD	extended_open(WORD,WORD,char far *,WORD);	      /*;AN000;5*/
	void	file_sharing_error(void);			      /*;AN000;9*/
	char	far * far_ptr(WORD,WORD);
	void	findclose(WORD);
	void	find_all_subdirs(void);
	void	find_first(char *,WORD *,struct FileFindBuf *,WORD);
	void	find_first_file(void);
	void	find_format(void);				      /*;AN000;d178*/
	void	find_next(WORD,struct FileFindBuf *);
	void	find_next_file(void);
	void	find_the_first(void);
	void	find_the_next(void);
	void	format_target(void);
	void	free_seg(unsigned);
	WORD	get_attribute(char  *);
	void	get_current_dir(WORD,char *);
	WORD	get_current_drive(void);
	void	get_country_info(void);
	void	get_diskette(void);
	void	get_drive_types(void);
	void	get_extended_attributes(WORD);			      /*;AN000;3 */
	void	get_first_target(void);
	void	get_hardfile(void);
	void	get_next_target(void);
	void	get_path(char *);				       /*;AN002;*/
	WORD	handle_open(char *,WORD);
	WORD	handle_read(WORD,WORD,char far *);
	WORD	handle_write(WORD,WORD,char far *);
	void	init(void);					/*;AN000;6*/
	void	insert_node(char *);
	WORD	ioctl(WORD);
	void	label_target_drive(void);
	DWORD	lseek(WORD,BYTE,DWORD);
	int	main(int, char * []);
	void	mark_as_last_target(void);
	void	mark_as_not_last_target(void);
	void	mark_files_read_only(void);
	void	open_logfile(void);
	void	open_source_file(void);
	void	open_target(void);
	void	parser(int,char * []);				/*;AN000;4*/
	void	parse_error(WORD,WORD); 			/*;AN000;4*//*;AN008;*/
	void	parse_init(void);				/*;AN000;4*/
	void	process_switch(void);				/*;AN000;4*//*;AN008;*/
	void	put_disk_header(void);
	void	put_new_db(void);
	void	put_new_fh(void);
	void	remove_last_backslash_from_BDS(void);
	void	remove_node(void);
	void	replace_volume_label(char *);
	void	reset_archive_bit(char *);
	void	restore_default_directories(void);
	void	save_current_dirs(void);
	void	see_if_it_should_be_backed_up(void);
	void	set_attribute(char *,WORD);
	void	set_vectors(void);			/*;AN000;*/
	void	set_default_dir(void);
	void	set_default_drive(WORD);
	void	setsignal(WORD,WORD);
	void	show_path(void);
	char	*strcat(char *,const char *);			/* */
	size_t	strlen(const char *);				/* */
	char	*strcpy(char *, const char *);			/* */
	char	*strncpy(char *, const char *, unsigned int);	/* */
	int	strncmp(const char *,const char *,unsigned int);/* */
	int	strcmp(const char *,const char *);		/* */
	void	terminate(void);
	void	update_db_entries(WORD);
	void	update_fh_entries(void);
/*****	void	write_extended_attributes(void);		/*;AN000;3*/
	WORD	write_till_target_full(WORD,WORD);
	void	write_to_control_file(char far *,WORD);
	void	write_to_target(WORD);
	void	xlat(char *,char *);				/*;AN000;*/

extern	void	sysloadmsg(union REGS *, union REGS *); 	/*;AN000;6*/
extern	void	update_logfile(union REGS *, union REGS *);	/*;AN000;9*/
extern	void	sysdispmsg(union REGS *, union REGS *); 	/*;AN000;6*/
extern	void	parse	  (union REGS *, union REGS *); 	/*;AN000;4*/

/*-------------------------------*/
/*-	From COMSUB.H		 */
/*-------------------------------*/

/*   convert character to uppercase */
extern int com_toupper(
   unsigned char );	      /* character to be converted to uppercase */


/*   search the first occurrence of a character in a string */
extern char *com_strchr(
   unsigned char *,	      /* a source string */
   unsigned char );	      /* a character to be searched */

/*   search the last charater occurrence in a string */
extern unsigned char
*com_strrchr(
   unsigned char *,	      /* source string */
   unsigned char );	     /* target string */
