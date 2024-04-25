/* 0 */

/************************************************************
/*
/* UTILITY NAME:      BACKUP.COM
/*
/* SOURCE FILE NAME:  BACKUP.C
/*
/* DESCRIPTIVE NAME:
/*	      DOS  Backup Utility Program
/*
/* STATUS:    BACKUP utility, DOS Version 4.00
/*	      Written using the C programming language.
/*
/*
/* COMPILER/LINKER INVOCATION:
/*
/*	cc /AS /Os /Zep /W3 /DLINT_ARGS /UDEBUG backup.c;
/*	link backup,,,mapper+comsubs
/*
/*   Note: You MUST(!) use the PACKED option (/Zp) to make sure data structures
/*	   are not aligned !!!
/*
/* FUNCTION:
/*     BACKUP will back up files from one disk(ette) to another. Accepts
/*     global characters, other parameters are defined to allow a more
/*     restrictive BACKUP procedure.  Compacts data into one large file and
/*     a control file containing directory information. Allows FORMATTING
/*     target diskette, intelligent error recovery, and proper handling of
/*     file sharing and sharing errors. Optionally creates a log file for
/*     tracking purposes.  Sets errorlevels on termination to indicate
/*     result.
/*
/* RESTRICTIONS:
/*     The BACKUP Utility program will be version checked to run ONLY on
/*     DOS version 4.00.  BACKUP performs a file by file backup using the
/*     DOS file system, ie. it is not an image type backup.
/*
/*
/* SYNTAX:
/*
/*    BACKUP [d:][path] filename [.ext]] d: [/S] [/F[:size]]
/*    [/L[:fn]] [/M] [/A] [T:hh:mm:ss] [/D:mm-dd-yy]
/*
/*     [/F[:size]] undocumented
/*
/*   SOURCE HISTORY:
/*
/*	New for DOS 3.3 and OS/2
/*
/*	Modification History:
/*
/*	 ;AN000; Code added in DOS 4.0
/*		6-05-87   RW
/*		 ;AN000;1  No BACKUP of SYSTEM files
/*		 ;AN000;2  Support for APPEND /X deactivation
/*		 ;AN000;3  Support for Extended Attributes
/*		 ;AN000;4  Support for PARSE service routines
/*		 ;AN000;5  Support for code page file tags
/*		 ;AN000;6  Support for MESSAGE retriever
/*		 ;AN000;7  Allow logfile to go on BACKUP target drive
/*		 ;AN000;8  Eliminate double prompting on single diskette drive systems
/*		 ;AN000;9  Put error message in logfile on share error
/*		 ;AN000;10 Make diskette formatting the default (DCR 177)
/*		 ;AN000;d178 DCR 178  Find FORMAT.COM before beginning
/*		 ;AN001; DCR 434 - Allow /F:size to specify format size
/*		 ;AN002; Don't use "C" routines to find PATH in environment
/*		 ;AN003; Make BACKUP handle UNC format returned from XLAT
/*		 ;AN004; Add CR, LF to end of command line (p3646)
/*		 ;AN005; Make sure no bogus BACKUP and CONTROL files are left in case of error exit
/*		 ;AN006; Make sure we don't try to BACKUP logfile
/*		 ;AN007; Make sure ABORT responses to critical errors are aborted
/*		 ;AN008; Make PARSE errors messages display the offending parameter
/*		 ;AN009; Fix parser
/*		 ;AN010; Don't find FORMAT.COM on target drive
/*		 ;AN011; Make BACKUP handle disk full properly on fixed disk
/*****************************************************************

				/* "C" supplied include files */
#include <process.h>
#include <malloc.h>
#include <direct.h>		/*;AN000;*/
#include <string.h>
#include <dos.h>
#include <stdlib.h>		/*;AN000;d178*/

#include <doscalls.h>		/* OS/2 Include file */

#include "backup.h"             /* BACKUP structures, defines, ...*/
#include "backpars.h"           /* DEFINEs and STRUCTs for the DOS Parse service routines */

#include <version.h>			/* symbol defns to determine degree of compatibility */

      /**********************************/
      /*	DATA STRUCTURES 	*/
      /**********************************/
	WORD		rc;		/* Return code from DOS calls */

	unsigned	selector;	/* Kinda like a segment address */

	struct	node	*curr_node;	/* Pointer to "node" structure for the */
					/* directory currently being processed */

	struct	node	*last_child;	/* Pointer to "node" structure for the */
					/* last directory discovered in the    */
					/* directory currently being processed */

	struct	subst_list sublist;		/*;AN000;6 Message substitution list */

	struct	p_parms 	parms;		/*;AN000;4 Parser data structure */
	struct	p_parmsx	parmsx; 	/*;AN000;4 Parser data structure */
	struct	p_pos_blk	pos1;		/*;AN000;4 Parser data structure */
	struct	p_pos_blk	pos2;		/*;AN000;4 Parser data structure */
	struct	p_sw_blk	sw1;		/*;AN000;4 Parser data structure */
	struct	p_sw_blk	sw2;		/*;AN000;4 Parser data structure */
	struct	p_sw_blk	sw3;		/*;AN000;4 Parser data structure */
	struct	p_sw_blk	sw4;		/*;AN000;4 Parser data structure */
	struct	p_sw_blk	sw5;		/*;AN001;DCR 434 Parser data structure */

	struct	p_result_blk	pos_buff;	/*;AN000;4 Parsr data structure */
	struct	switchbuff	sw_buff;	/*;AN000;4 Parsr data structure */
	struct	timebuff	time_buff;	/*;AN000;4 Parsr data structure */
	struct	datebuff	date_buff;	/*;AN000;4 Parsr data structure */
	struct	val_list_struct  value_list;	/*;AN001;DCR 434*/
	struct	val_table_struct value_table;	/*;AN001;DCR 434*/
	char	curr_parm[128]; 		/*;AN009; Current parameter being parsed*/

	DWORD	noval = 0;			/*;AN000;4 Value list for PARSR */

	struct	FileFindBuf dta;		/* Return area for Find First/Next*/
	struct	FileFindBuf *dta_addr;		/* Pointer to above */
	union	REGS inregs, outregs;		/*;AN000;2 Register set */

      /**********************************/
      /*	DATA AREAS		*/
      /**********************************/
	WORD	dirhandle;			/* Dirhandle field, for Find First, Find Next */
	BYTE	dirhandles_open = FALSE;	/* Flag indicating at least 1 open dirhandle */

	WORD	def_drive;			/* Storage for default drive (1=A,2=B,...) */
	BYTE	src_drive_letter;		/* ASCII drive letter, source drive */
	BYTE	tgt_drive_letter;		/* ASCII drive letter, target drive */
	BYTE	src_def_dir[PATHLEN+20];	/* default dir on source, drive letter omitted */

	BYTE	src_drive_path_fn[PATHLEN+20];	/* D:\path\fn - The fully qualified spec to be backed up*/
	BYTE	src_drive_path[PATHLEN+20];	/* D:\path - Fully qualified drive and path to be backed up */
	BYTE	src_fn[PATHLEN];		/* fn - File spec to be backed up. Set to *.* if no filespec entered. */
	BYTE	ext[3]; 			/* Filename extension */

	WORD	files_backed_up = 0;		/* Counter for number files backed up on current target */
	BYTE	diskettes_complete = 0; 	/* Number of diskettes already filled and complete */
	DWORD	curr_db_begin_offset;		/* Offset within the control file of the current Directory Block */
	DWORD	curr_fh_begin_offset;		/* Offset within the control file of the current File Header */
	WORD	handle_source  = 0xffff;	/* Handle for source file */
	WORD	handle_target  = 0xffff;	/* Handle for target file */
	WORD	handle_control = 0xffff;	/* Handle for control file */
	WORD	handle_logfile = 0xffff;	/* Handle for log file */
	DWORD	part_size;			/* Number of bytes from a file on the disk (for files that span) */
	DWORD	cumul_part_size;		/* Number of bytes from all disks for a particular file */

	BYTE	logfile_path[PATHLEN+20];	/* D:\path\filename - drive,path, and name */
	BYTE	format_path[PATHLEN+20];	/*;AN000;d178 Full path to FORMAT.COM */
	BYTE	format_size[128];		/*;AN001;DCR 434 If user enters "/F:size" this will be "size" */

      /**********************************/
      /*     PROGRAM CONTROL FLAGS	*/
      /**********************************/
	BYTE	do_subdirs = FALSE;		/* User parameters, /S */
	BYTE	do_add = FALSE; 		/* User parameters, /A */
	BYTE	do_modified = FALSE;		/* User parameters, /M */
	BYTE	do_format_parms = FALSE;	/* User parameters, /F ;AN000;d177 */
	BYTE	do_logfile = FALSE;		/* User parameters, /L */
	BYTE	do_time = FALSE;		/* User parameters, /T */
	BYTE	do_date = FALSE;		/* User parameters, /D */

	BYTE	buffers_allocated = FALSE;	/* Indicates if file buffers were allocated */
	BYTE	curr_dir_set = FALSE;		/* Indicates if the current directory on source was changed */
	BYTE	def_drive_set = FALSE;		/* Indicates if the default drive was changed */

	BYTE	control_opened = FALSE; 	/* Indicates if file opened or not */
	BYTE	logfile_opened = FALSE; 	/*;AN000;7  Indicates if logfile file is opened */
	BYTE	source_opened = FALSE;		/* Indicates if file opened or not */
	BYTE	target_opened = FALSE;		/* Indicates if file opened or not */

	BYTE	doing_first_target = TRUE;	/* Indicates that first target is being processed */
	BYTE	got_first_target = FALSE;	/* Indicates that first target is being processed */

	BYTE	source_removable;		/* Indicates if the source drive is removable */
	BYTE	target_removable;		/* Indicates if the target drive is removable */

	BYTE	file_spans_target;		/* Indicates that first target is being processed */
	BYTE	disk_full = FALSE;		/* Flag indicating the disk is full */
	BYTE	logfile_on_target = FALSE;	/*;AN000;7 Flag telling if user wants logfile on target drive */
	BYTE	got_path_validity = FALSE;	/*;AN000;4 Flag indicating we have not verified input path*/
	BYTE	checking_target = FALSE;	/*;AN007;  Indicates if we are checking target diskette to determine if it is formatted */

	BYTE	new_directory = TRUE;		/* Indicates that file to be backed up is in a different directory */
	BYTE	found_a_file = FALSE;		/* Indicates if a file was found to be backed up */
	BYTE	back_it_up = FALSE;		/* Indicates if a file was found and conforms to specified parameters */    char author[45]="  Program Author: W. Russell Whitehead  ";
      /**********************************/
      /*     EXTENDED ATTRIBUTES	*/
      /**********************************/
/*EAEA	BYTE	ext_attrib_flg = FALSE; 	/*;AN000;3 Indicates there are extended attributes*/
/*EAEA	WORD	ext_attrib_len; 		/*;AN000;3 Length of extended attributes*/
/*EAEA	BYTE	ext_attrib_buff[EXTATTBUFLEN];	/*;AN000;3 Buffer for extended attributes*/
	BYTE	ext_attrib_buff[3];		/*;AN000;3 Buffer for extended attributes*/
	struct	parm_list ea_parmlist;		/*;AN000;3 Parameter list for extended open*/

      /**********************************/
      /*     APPEND STUFF		*/
      /**********************************/
	BYTE	append_indicator = 0xff;	/*;AN000;2 Indicates if support for APPEND /X is active */
	WORD	original_append_func;		/*;AN000;2 APPEND functions on program entry, restored on program exit */

      /**********************************/
      /*	 OTHER STUFF		*/
      /**********************************/
	BYTE	span_seq_num;			/* Counter indicating which part of a spanning file is on current target */

	WORD	data_file_alloc_size = 0xffff;	/* Number of paragraphs to initially try to allocate for data file */

	DWORD	data_file_tot_len = 0;		/* Storage area for data file current length */
	DWORD	ctl_file_tot_len = 0;		/* Storage area for control file current length on the disk */

	WORD	ctry_date_fmt;
	BYTE	ctry_time_fmt;
	WORD	ctry_date_sep;
	WORD	ctry_time_sep;

	WORD	user_specified_time = 0;	/* Time user entered in response to /T parameter */
	WORD	user_specified_date = 0;	/* Date user entered in response to /T parameter */

	BYTE	return_code = RETCODE_NO_ERROR; /* Save area for DOS ErrorLevel */

/*************************************************/
/*
/* SUBROUTINE NAME:	main
/*
/* FUNCTION:
/*
/*	Backs up files from source to target drive
/*
/***************************************************/
main(argc,argv)
int	argc;
char	*argv[];
{
	init(); 				/*;AN000;6 Mundane initializization of data structures, */
						/*	   check DOS version,preload messages */
	def_drive = get_current_drive();	/* Save default drive number*/
	check_drive_validity(argc,argv);	/* Check for validity of input drive(s) */
	get_drive_types();			/* Find out if source and target are removable */
	get_country_info();			/* Get country dependent information */
	parser(argc,argv);			/*;AN000;4 Parse input line, init switches and flags*/
	check_path_validity(argv);		/*;AN000;4 Verify that the source filespec is valid */
	if (target_removable)			/*;AN000;d178 If target drive is diskette */
	  find_format();			/*;AN000;d178 Find FORMAT.COM and build path to it*/
	save_current_dirs();			/* Save default directories on def drive, source and target */
	alloc_buffer(); 			/* Allocate IO buffer */
	check_appendX();			/*;AN000;2 Check APPEND /X status, turn off if active */
	set_vectors();				/* Set vectors for Int 23h and 24h */
	do_backup();				/* Do the BACKUP */

	return(0);
}	/* end main */

/*************************************************/
/*
/* SUBROUTINE NAME:	init
/*
/* FUNCTION:
/*	Preload messages
/*	Check DOS version
/*	Mundane initializization of data structures
/*
/**************************************************/
void	init()					/*;AN000;6*/
{						/*;AN000;6*/

	/**********************************/
	/**	PRELOAD MESSAGES	 **/
	/**********************************/
	sysloadmsg(&inregs,&outregs);		/*;AN000;6 Preload messages, check DOS version */

	if (outregs.x.cflag & CARRY)		/*;AN000;6 If there was an error */
	{					/*;AN000;6*/
	   sysdispmsg(&outregs,&outregs);	/*;AN000;6 Display the error message (Use OUTREGS as input*/
	   return_code = RETCODE_ERROR; 	/*;AN000;6 Set the return code */
	   terminate(); 			/*;AN000;6 and terminate */
	}					/*;AN000;6*/

	/**********************************/
	/**   SETUP MESSAGE SUBST LIST	 **/
	/**********************************/
	sublist.sl_size1= SUBLIST_SIZE; 	/*;AN000;6 Initialize subst list for message retriever*/
	sublist.sl_size2= SUBLIST_SIZE; 	/*;AN000;6*/
	sublist.one = 1;			/*;AN000;6*/
	sublist.two = 2;			/*;AN000;6*/
	sublist.zero1 = 0;			/*;AN000;6*/
	sublist.zero2 = 0;			/*;AN000;6*/

	ext_attrib_buff[0] = 0; 		/*;AN000;3*/
	ext_attrib_buff[1] = 0; 		/*;AN000;3*/

	date_buff.month = 0;			/*;AN000;3*/
	date_buff.day	= 0;			/*;AN000;3*/
	date_buff.year	= 0;			/*;AN000;3*/

	time_buff.hours   = 0;			/*;AN000;3*/
	time_buff.minutes = 0;			/*;AN000;3*/
	time_buff.seconds = 0;			/*;AN000;3*/
	time_buff.hundreds= 0;			/*;AN000;3*/

	dta_addr = (struct FileFindBuf *)&dta;	/* Get address of FindFile buffer */

	return; 				/*;AN000;6*/
}						/*;AN000;6*/


/*************************************************/
/*
/* SUBROUTINE NAME:	parser
/*
/* FUNCTION:
/*
/*	Parse the command line
/*
/**************************************************/
void	parser(argc,argv)					      /*;AN000;4*/
int	argc;							      /*;AN000;4*/
char	*argv[];						      /*;AN000;4*/
{								      /*;AN000;4*/
	char	cmd_line[128];					      /*;AN000;4*/
	char	not_finished = TRUE;				      /*;AN000;4*/
	int	x;						      /*;AN000;4*/

	parse_init();		/* Initialize parser data structures*//*;AN000;4*/

		/* Copy command line parameters to local area */
	cmd_line[0] = NUL;					      /*;AN000;4*/
	for (x=1; x<=argc; x++) 				      /*;AN000;4*/
	{							      /*;AN000;4*/
	 strcat(cmd_line,argv[x]);				      /*;AN000;4*/
	 if (x != argc) strcat(cmd_line," ");                         /*;AN000;4*/
	}							      /*;AN000;4*/

	strcat(cmd_line,"\r");  /*;AN004;*/

	inregs.x.si = (WORD)&cmd_line[0]; /*DS:SI points to cmd line*//*;AN000;4*/



	while (not_finished)					      /*;AN000;4 For all strings in command line */
	 {							      /*;AN000;4*/
	  inregs.x.dx = 0;					      /*;AN000;4 RESERVED */
	  inregs.x.di = (WORD)&parms;	    /*ES:DI*/		      /*;AN000;4 address of parm list */

	  parse(&inregs,&outregs);				      /*;AN000;4 Call DOS SYSPARSE service routines*/

	  x=0;			/* Save the parsed parameter */       /*;AN009;*/
	  for (inregs.x.si; inregs.x.si<outregs.x.si; inregs.x.si++)  /*;AN009;*/
	   {							      /*;AN009;*/
	     curr_parm[x] = *(char *)inregs.x.si;		      /*;AN009;*/
	     x++;						      /*;AN009;*/
	   }							      /*;AN009;*/

	  curr_parm[x] = NUL;					      /*;AN009;*/

	  inregs = outregs;					      /*;AN000;4 Reset registers*/

	  if (outregs.x.ax!=(WORD)NOERROR)			      /*;AN000;4*/
	   {							      /*;AN000;4*/
	    if (outregs.x.ax!=(WORD)EOL)			      /*;AN000;4*/
	      parse_error(outregs.x.ax,outregs.x.dx);		      /*;AN000;4*//*;AN008;*/
	    not_finished = FALSE;				      /*;AN000;4*/
	   }							      /*;AN000;4*/

	  if (not_finished)					      /*;AN000;4 If there was not an error*/
	    {							      /*;AN000;4*/
	       if (outregs.x.dx == (WORD)&sw_buff)		      /*;AN000;4*/
		process_switch();				      /*;AN000;4 Its a switch*//*;AN008;*/

	       if (outregs.x.dx == (WORD)&time_buff)		      /*;AN000;4*/
		{						      /*;AN000;4 Its a TIME parameter*/
		 if (do_time)					      /*;AN000;4*/
		   parse_error(outregs.x.ax,outregs.x.dx);	      /*;AN000;4*//*;AN008;*/

		 check_time(time_buff.hours,time_buff.minutes,time_buff.seconds,time_buff.hundreds);/*;AN000;4*/
		 time_buff.seconds = time_buff.seconds / 2;	      /*;AN000;4 See "NOTE FROM PARSER SUBROUTINE" in backup.h */
		 user_specified_time = (time_buff.hours*0x800) + (time_buff.minutes*32) + time_buff.seconds;/*;AN000;4 TIME bit format hhhhhmmmmmmxxxxx */
		}						      /*;AN000;4*/

	       if (outregs.x.dx == (WORD)&date_buff)		      /*;AN000;4*/
		{						      /*;AN000;4*/
		 if (do_date)					      /*;AN000;4*/
		   parse_error(outregs.x.ax,outregs.x.dx);	      /*;AN000;4*//*;AN008;*/

		 check_date(date_buff.year,date_buff.month,date_buff.day);/*;AN000;4*/
		 user_specified_date = ((date_buff.year-1980)*512) + (date_buff.month*32) + (date_buff.day); /*;AN000;4 DATE bit format yyyyyyymmmmddddd */
		}						      /*;AN000;4*/

	    } /* end not_finished */				      /*;AN000;4*/

	 }  /* end WHILE */					      /*;AN000;4*/

	if (strlen(argv[1]) >= 5)				      /*;AN000;p2592*/
	 check_for_device_names(argv);				      /*;AN000;p2592*/

	return; 						      /*;AN000;4 Return to caller*/
}	/* end parser */					      /*;AN000;4*/
/*************************************************/
/*
/* SUBROUTINE NAME:	parse_error
/*
/* FUNCTION:
/*
/*	There was a parse error.  Display appropriate
/*	error message and terminate.
/*
/**************************************************/
void	parse_error(ax,dx)					      /*;AN000;4*/
WORD	ax;							      /*;AN000;4*/
WORD	dx;							      /*;AN000;4*/
{								      /*;AN000;4*/
	sublist.value1 = &curr_parm[0]; 			      /*;AN008;*/
	sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;	      /*;AN008;*/
	sublist.pad_char1 = ' ';                                      /*;AN008;*/
	sublist.one = 0;					      /*;AN008;*/
	sublist.max_width1 = (BYTE)strlen(curr_parm);		      /*;AN008;*/
	sublist.min_width1 = sublist.max_width1;		      /*;AN008;*/

	if (dx == (WORD)&time_buff)				      /*;AN000;4*/
	  display_it(INV_TIME,STDERR,1,NOWAIT,(BYTE)UTIL_MSG);	      /*;AN000;4*/
	 else							      /*;AN000;4*/
	  if (dx == (WORD)&date_buff)				      /*;AN000;4*/
	    display_it(INV_DATE,STDERR,1,NOWAIT,(BYTE)UTIL_MSG);      /*;AN000;4*/
	   else 						      /*;AN000;4*/
	    display_it (ax,STDERR,1,NOWAIT,(BYTE)PARSEERROR);	     /*;AN000;6*/

	return_code = RETCODE_ERROR;				      /*;AN000;4*/
	clean_up_and_exit();					      /*;AN000;4*/

	return; 						      /*;AN000;4*/
}	/* end parse_error */					      /*;AN000;4*/

/*************************************************/
/*
/* SUBROUTINE NAME:	check_date
/*
/* FUNCTION:
/*
/*	A date parameter was entered. Validate it
/*
/**************************************************/
void	check_date(year,month,day)				      /*;AN000;4*/
WORD	year;							      /*;AN000;4*/
BYTE	month;							      /*;AN000;4*/
BYTE	day;							      /*;AN000;4*/
{								      /*;AN000;4*/
	if (year > 2099 || year < 1980) 			      /*;AC000;4*/
	  error_exit(INV_DATE); 				      /*;AC000;4*/

	if (month > 12 || month < 1)				      /*;AC000;4*/
	  error_exit(INV_DATE); 				      /*;AC000;4*/

	if (day > 31 || day  < 1)				      /*;AC000;4*/
	  error_exit(INV_DATE); 				      /*;AC000;4*/

		/* Verify day not greater then 30 if Apr,Jun,Sep,Nov */
	if ((day>30) && (month==4 || month==6 || month==9 || month==11))/*;AC000;4*/
	  error_exit(INV_DATE); 				      /*;AC000;4*/

	if (month == 2) 		/* Deal with February */      /*;AC000;4*/
	 {							      /*;AC000;4*/
	   if (day >  29)		/*  if Feb 30 or above */     /*;AC000;4*/
	    error_exit(INV_DATE);	/*   then Bad Date */	      /*;AC000;4*/

	   if ((year % 4) != 0) 	/* If not a leap year */      /*;AC000;4*/
	     if (day >	28)		/*  if Feb 29 or above */     /*;AC000;4*/
	      error_exit(INV_DATE);	/*   then Bad Date */	      /*;AC000;4*/
	 }							      /*;AC000;4*/

	 do_date = TRUE;					      /*;AN000;4*/

	return; 						      /*;AN000;4*/
}	/* end check_date */					      /*;AN000;4*/

/*************************************************/
/*
/* SUBROUTINE NAME:	check_time
/*
/* FUNCTION:
/*
/*	A time parameter was entered. Validate it
/*
/**************************************************/
void	check_time(hours,minutes,seconds,hundreds)		      /*;AN000;4*/
BYTE	hours;							      /*;AN000;4*/
BYTE	minutes;						      /*;AN000;4*/
BYTE	seconds;						      /*;AN000;4*/
BYTE	hundreds;						      /*;AN000;4*/
{								      /*;AN000;4*/
	if (hours > 23 || hours < 0)				      /*;AC000;4*/
	 error_exit(INV_TIME);					      /*;AC000;4*/

	if (minutes >= 60 || minutes < 0)			      /*;AC000;4*/
	 error_exit(INV_TIME);					      /*;AC000;4*/

	if (seconds >= 60 || seconds < 0)			      /*;AC000;4*/
	 error_exit(INV_TIME);					      /*;AC000;4*/

	if (hundreds > 99 || hundreds < 0)			      /*;AC000;4*/
	 error_exit(INV_TIME);					      /*;AC000;4*/

	do_time = TRUE; 					      /*;AN000;4*/

	return; 						      /*;AN000;4*/
}	/* end check_time */					      /*;AN000;4*/

/*************************************************/
/*
/* SUBROUTINE NAME:	parse_init
/*
/* FUNCTION:
/*
/*	Initialize the parser data structures
/*
/**************************************************/
void	parse_init()						/*;AN000;4*/
{		/* Initialize PARMS data structure */		/*;AN000;4*/
	parms.parmsx_ptr = (WORD)&parmsx;			/*;AN000;4*/
	parms.p_num_extra = 1;					/*;AN000;4*/
	parms.p_len_extra_delim = 1;				/*;AN000;4*/
	parms.p_extra_delim[0] = ';';                           /*;AN000;4*/
	parms.p_extra_delim[1] = NUL;				/*;AN000;4 */

		/* Initialize PARMSX data structure */
	parmsx.p_minpos= 2;					/*;AN000;4*/
	parmsx.p_maxpos= 2;					/*;AN000;4*/
	parmsx.pos1_ptr= (WORD)&pos1;				/*;AN000;4*/
	parmsx.pos2_ptr= (WORD)&pos2;				/*;AN000;4*/
	parmsx.num_sw  = 5;					/*;AN000;4*/
	parmsx.sw1_ptr = (WORD)&sw1;				/*;AN000;4*/
	parmsx.sw2_ptr = (WORD)&sw2;				/*;AN000;4*/
	parmsx.sw3_ptr = (WORD)&sw3;				/*;AN000;4*/
	parmsx.sw4_ptr = (WORD)&sw4;				/*;AN000;4*/
	parmsx.sw5_ptr = (WORD)&sw5;				/*;AN001;DCR 434*/
	parmsx.num_keywords = 0;				/*;AN000;4*/

		/* Initialize POS1 data structure */
	pos1.match_flag = FILESPEC;				/*;AN000;4*/
	pos1.function_flag = 0; 				/*;AN000;4*/
	pos1.result_buf = (WORD)&pos_buff;			/*;AN000;4*/
	pos1.value_list = (WORD)&noval; 			/*;AN000;4*/
	pos1.nid = 0;						/*;AN000;4*/

		/* Initialize POS2 data structure */
	pos2.match_flag = DRIVELETTER;				/*;AN000;4*/
	pos2.function_flag = 0; 				/*;AN000;4*/
	pos2.result_buf = (WORD)&pos_buff;			/*;AN000;4*/
	pos2.value_list = (WORD)&noval; 			/*;AN000;4*/
	pos2.nid = 0;						/*;AN000;4*/

		/* Initialize SW1 data structure */
	sw1.p_match_flag = 0;					/*;AN000;4*/
	sw1.p_function_flag = 0;				/*;AN000;4*/
	sw1.p_result_buf = (WORD)&sw_buff;			/*;AN000;4*/
	sw1.p_value_list = (WORD)&noval;			/*;AN000;4*/
	sw1.p_nid = 4;						/*;AN000;4*/
	strcpy(sw1.switch1,"/S");                               /*;AN000;4*/
	strcpy(sw1.switch2,"/M");                               /*;AN000;4*/
	strcpy(sw1.switch3,"/A");                               /*;AN000;4*/

		/* Initialize SW2 data structure */
	sw2.p_match_flag = DATESTRING;				/*;AN000;4*/
	sw2.p_function_flag = 0;				/*;AN000;4*/
	sw2.p_result_buf = (WORD)&date_buff;			/*;AN000;4*/
	sw2.p_value_list = (WORD)&noval;			/*;AN000;4*/
	sw2.p_nid = 1;						/*;AN000;4*/
	strcpy(sw2.switch1,"/D");                               /*;AN000;4*/

		/* Initialize SW3 data structure */
	sw3.p_match_flag = TIMESTRING;				/*;AN000;4*/
	sw3.p_function_flag = 0;				/*;AN000;4*/
	sw3.p_result_buf = (WORD)&time_buff;			/*;AN000;4*/
	sw3.p_value_list = (WORD)&noval;			/*;AN000;4*/
	sw3.p_nid = 1;						/*;AN000;4*/
	strcpy(sw3.switch1,"/T");                               /*;AN000;4*/

		/* Initialize SW4 data structure */
	sw4.p_match_flag = SSTRING + OPTIONAL;			/*;AN000;4*/
	sw4.p_function_flag = CAP_FILETABLE;			/*;AN000;4*/
	sw4.p_result_buf = (WORD)&sw_buff;			/*;AN000;4*/
	sw4.p_value_list = (WORD)&noval;			/*;AN000;4*/
	sw4.p_nid = 1;						/*;AN000;4*/
	strcpy(sw4.switch1,"/L");                               /*;AN000;4*/

		/* Initialize SW5 data structure */
	sw5.p_match_flag = SSTRING + OPTIONAL;			   /*;AN001;DCR 434*/
	sw5.p_function_flag = CAP_CHARTABLE;			   /*;AN001;DCR 434*/
	sw5.p_result_buf = (WORD)&sw_buff;			   /*;AN001;DCR 434*/
	sw5.p_value_list = (WORD)&value_list;			   /*;AN001;DCR 434*/
	sw5.p_nid = 1;						   /*;AN001;DCR 434*/
	strcpy(sw5.switch1,"/F");                                  /*;AN001;DCR 434*/

		/* Initialize value list data structure */
	value_list.nval = 3;					   /*;AN001;DCR 434*/
	value_list.num_ranges  = 0;				   /*;AN001;DCR 434*/
	value_list.num_choices = 0;				   /*;AN001;DCR 434*/
	value_list.num_strings = 27;				   /*;AN001;DCR 434*/
	value_list.val01 = (WORD)&value_table.val01[0]; 	   /*;AN001;DCR 434*/
	value_list.val02 = (WORD)&value_table.val02[0]; 	   /*;AN001;DCR 434*/
	value_list.val03 = (WORD)&value_table.val03[0]; 	   /*;AN001;DCR 434*/
	value_list.val04 = (WORD)&value_table.val04[0]; 	   /*;AN001;DCR 434*/
	value_list.val05 = (WORD)&value_table.val05[0]; 	   /*;AN001;DCR 434*/
	value_list.val06 = (WORD)&value_table.val06[0]; 	   /*;AN001;DCR 434*/
	value_list.val07 = (WORD)&value_table.val07[0]; 	   /*;AN001;DCR 434*/
	value_list.val08 = (WORD)&value_table.val08[0]; 	   /*;AN001;DCR 434*/
	value_list.val09 = (WORD)&value_table.val09[0]; 	   /*;AN001;DCR 434*/
	value_list.val10 = (WORD)&value_table.val10[0]; 	   /*;AN001;DCR 434*/
	value_list.val11 = (WORD)&value_table.val11[0]; 	   /*;AN001;DCR 434*/
	value_list.val12 = (WORD)&value_table.val12[0]; 	   /*;AN001;DCR 434*/
	value_list.val13 = (WORD)&value_table.val13[0]; 	   /*;AN001;DCR 434*/
	value_list.val14 = (WORD)&value_table.val14[0]; 	   /*;AN001;DCR 434*/
	value_list.val15 = (WORD)&value_table.val15[0]; 	   /*;AN001;DCR 434*/
	value_list.val16 = (WORD)&value_table.val16[0]; 	   /*;AN001;DCR 434*/
	value_list.val17 = (WORD)&value_table.val17[0]; 	   /*;AN001;DCR 434*/
	value_list.val18 = (WORD)&value_table.val18[0]; 	   /*;AN001;DCR 434*/
	value_list.val19 = (WORD)&value_table.val19[0]; 	   /*;AN001;DCR 434*/
	value_list.val20 = (WORD)&value_table.val20[0]; 	   /*;AN001;DCR 434*/
	value_list.val21 = (WORD)&value_table.val21[0]; 	   /*;AN001;DCR 434*/
	value_list.val22 = (WORD)&value_table.val22[0]; 	   /*;AN001;DCR 434*/
	value_list.val23 = (WORD)&value_table.val23[0]; 	   /*;AN001;DCR 434*/
	value_list.val24 = (WORD)&value_table.val24[0]; 	   /*;AN001;DCR 434*/
	value_list.val25 = (WORD)&value_table.val25[0]; 	   /*;AN001;DCR 434*/
	value_list.val26 = (WORD)&value_table.val26[0]; 	   /*;AN001;DCR 434*/
	value_list.val27 = (WORD)&value_table.val27[0]; 	   /*;AN001;DCR 434*/

		/* Initialize FORMAT value table */
	strcpy(value_table.val01,"160");                           /*;AN001;DCR 434*/
	strcpy(value_table.val02,"160K");                          /*;AN001;DCR 434*/
	strcpy(value_table.val03,"160KB");                         /*;AN001;DCR 434*/
	strcpy(value_table.val04,"180");                           /*;AN001;DCR 434*/
	strcpy(value_table.val05,"180K");                          /*;AN001;DCR 434*/
	strcpy(value_table.val06,"180KB");                         /*;AN001;DCR 434*/
	strcpy(value_table.val07,"320");                           /*;AN001;DCR 434*/
	strcpy(value_table.val08,"320K");                          /*;AN001;DCR 434*/
	strcpy(value_table.val09,"320KB");                         /*;AN001;DCR 434*/
	strcpy(value_table.val10,"360");                           /*;AN001;DCR 434*/
	strcpy(value_table.val11,"360K");                          /*;AN001;DCR 434*/
	strcpy(value_table.val12,"360KB");                         /*;AN001;DCR 434*/
	strcpy(value_table.val13,"720");                           /*;AN001;DCR 434*/
	strcpy(value_table.val14,"720K");                          /*;AN001;DCR 434*/
	strcpy(value_table.val15,"720KB");                         /*;AN001;DCR 434*/
	strcpy(value_table.val16,"1200");                          /*;AN001;DCR 434*/
	strcpy(value_table.val17,"1200K");                         /*;AN001;DCR 434*/
	strcpy(value_table.val18,"1200KB");                        /*;AN001;DCR 434*/
	strcpy(value_table.val19,"1.2");                           /*;AN001;DCR 434*/
	strcpy(value_table.val20,"1.2M");                          /*;AN001;DCR 434*/
	strcpy(value_table.val21,"1.2MB");                         /*;AN001;DCR 434*/
	strcpy(value_table.val22,"1440");                          /*;AN001;DCR 434*/
	strcpy(value_table.val23,"1440K");                         /*;AN001;DCR 434*/
	strcpy(value_table.val24,"1440KB");                        /*;AN001;DCR 434*/
	strcpy(value_table.val25,"1.44");                          /*;AN001;DCR 434*/
	strcpy(value_table.val26,"1.44M");                         /*;AN001;DCR 434*/
	strcpy(value_table.val27,"1.44MB");                        /*;AN001;DCR 434*/

	return; 						/*;AN000;4*/
}								/*;AN000;4*/
/*************************************************/
/*
/* SUBROUTINE NAME:	find_format
/*
/* FUNCTION:
/*
/*	Search for the FORMAT utility.	If found, then
/*	build a full path to it from the root. If not
/*	found, tell the user and terminate.
/*
/***************************************************/
void find_format()						      /*;AN000;d178*/
{								      /*;AN000;d178*/
	BYTE	found_it= FALSE;				      /*;AN000;d178*/
	BYTE	no_more = FALSE;				      /*;AN000;d178*/
	int	findex,pindex;					/*;AN002;*/
	BYTE	done = FALSE;					/*;AN002;*/
	char	path[130];					/*;AN002;*/

			/*******************************/
			/* First try current directory */
	format_path[0] = '.';                                         /*;AN000;d178*/
	format_path[1] = NUL;					      /*;AN000;d178*/

			/* Build full path */
	xlat(format_path,format_path);				      /*;AN000;d178*/

			/* If at root, remove trailing backslash */
	if (strlen(format_path)==3 && format_path[1]==':')            /*;AN000;p1900*/
	 format_path[2] = NUL;					      /*;AN000;p1900*/

	strcat(format_path,"\\FORMAT.COM");                           /*;AN000;d178*/

			/* Now look for it */
	if (format_path[0] == tgt_drive_letter) 		      /*;AN010;*/
	 if (target_removable)					      /*;AN010;*/
	  format_path[0] = NUL; 				      /*;AN010;*/

	if (exist(format_path)) 				      /*;AN000;d178*/
	  found_it = TRUE;					      /*;AN000;d178*/
	 else							      /*;AN000;d178*/
	  {
	    get_path(path);					      /*;AN002;*/

	    if (strlen(path)==0  ||  path[0]==NUL)		      /*;AN002;*/
	     error_exit(CANT_FIND_FORMAT);			      /*;AN002;*/
	  }

	pindex = 0;
	while (!found_it && path[pindex] != NUL)
	 {
	   for (findex=0; path[pindex]!=NUL && path[pindex]!=';'; pindex++) /*;AN002;*/
	    {							      /*;AN002;*/
	      format_path[findex] = path[pindex];		      /*;AN002;*/
	      findex++; 					      /*;AN002;*/
	    }							      /*;AN002;*/

	   if (path[pindex]==';')
	    pindex++;

	   format_path[findex] = NUL;				      /*;AN002;*/

	   xlat(format_path,format_path);			      /*;AN002;*/

	   if (strlen(format_path)==3 && format_path[1]==':')         /*;AN000;p1900*/
	    format_path[2] = NUL;				      /*;AN000;p1900*/

	   strcat(format_path,"\\FORMAT.COM");                        /*;AN000;d178*/

	   if (format_path[0] == tgt_drive_letter)		      /*;AN010;*/
	    if (target_removable)				      /*;AN010;*/
	     format_path[0] = NUL;				      /*;AN010;*/

	   if (exist(format_path))				      /*;AN000;d178*/
	     found_it = TRUE;					      /*;AN000;d178*/
	 }							      /*;AN000;d178*/

	if (!found_it)						      /*;AN000;d178*/
	 error_exit(CANT_FIND_FORMAT);				      /*;AN000;d178*/

	return; 						      /*;AN000;d178*/
}								      /*;AN000;d178*/
/*************************************************/
/*
/* SUBROUTINE NAME:	get_path
/*
/* FUNCTION:
/*	Finds the environment pointer in the PSP, and
/*	searches the envirnment for a PATH statement.
/*	If found, copies it to the buffer address passed in.
/*
/***************************************************/
void get_path(p)						/*;AN002;*/
char *p;							/*;AN002;*/
{								/*;AN002;*/
	char	far * env_ptr;					/*;AN002;*/
	WORD	env_seg;					/*;AN002;*/
	BYTE	got_path = FALSE;				/*;AN002;*/
	BYTE	done = FALSE;					/*;AN002;*/
	union	REGS xregs;					/*;AN002;*/
	char	path[130];					/*;AN002;*/

			/* First find PSP */
	xregs.x.ax = 0x6200;	    /* Get PSP Address */	/*;AN002;*/
	intdos(&xregs,&xregs);	    /* Returned in BX */	/*;AN002;*/

			/* Build pointer to env ptr from PSP+2c */
	env_ptr = far_ptr(xregs.x.bx,0x2c);			/*;AN002;*/
	env_seg = *(WORD far *)env_ptr; 			/*;AN002;*/
	env_ptr = far_ptr(env_seg,0);				/*;AN002;*/
	*p = NUL;						/*;AN002;*/

			/* Search for PATH in the environment */
	while (!done)						/*;AN002;*/
	  {							/*;AN002;*/
	   if							/*;AN002;*/
	      (*env_ptr     == 'P' &&                           /*;AN002;*/
	       *(env_ptr+1) == 'A' &&                           /*;AN002;*/
	       *(env_ptr+2) == 'T' &&                           /*;AN002;*/
	       *(env_ptr+3) == 'H' &&                           /*;AN002;*/
	       *(env_ptr+4) == '='                              /*;AN002;*/
	      ) 						/*;AN002;*/
	     {							/*;AN002;*/
	      done = TRUE;					/*;AN002;*/
	      got_path = TRUE;					/*;AN002;*/
	     }							/*;AN002;*/
	    else						/*;AN002;*/
	     if (*env_ptr == NUL  && *(env_ptr+1) == NUL)	/*;AN002;*/
	      done = TRUE;					/*;AN002;*/

	   if (!done)						/*;AN002;*/
	    env_ptr++;						/*;AN002;*/
	  }							/*;AN002;*/

			/* Copy path to desired buffer */
	if (got_path)						/*;AN002;*/
	 {							/*;AN002;*/
	   env_ptr += 5;       /* Skip over "PATH=" */          /*;AN002;*/
	   for (; *env_ptr!=NUL; env_ptr++)			/*;AN002;*/
	    {							/*;AN002;*/
	      *p = *env_ptr;					/*;AN002;*/
	      p++;						/*;AN002;*/
	    }							/*;AN002;*/

	   *p = NUL;						/*;AN002;*/
	 }							/*;AN002;*/

	return; 						/*;AN002;*/
}								/*;AN002;*/

/*************************************************/
/*
/* SUBROUTINE NAME:	xlat
/*
/* FUNCTION:
/*
/*	Performs name translate function.  Calls DOS function
/*	call 60h to build full path from root using the "src"
/*	passed in, places resultant path at "tgt".
/*
/***************************************************/
void xlat(tgt,src)						     /*;AN000;*/
char * tgt;							     /*;AN000;*/
char * src;							     /*;AN000;*/
{								     /*;AN000;*/
	union	REGS xregs;

	xregs.x.ax = 0x6000;		     /* Name Xlat*/	     /*;AN000;*/
	xregs.x.bx = 0; 		     /* Drive*/ 	     /*;AN000;*/
	xregs.x.si = (WORD)src; 	     /* Source*/	     /*;AN000;*/
	xregs.x.di = (WORD)tgt; 	     /* Target*/	     /*;AN000;*/
	intdos(&xregs,&xregs);		     /* Blammo!*/	     /*;AN000;*/

	return; 						     /*;AN000;*/
}								     /*;AN000;*/
/*************************************************/
/*
/* SUBROUTINE NAME:	check_drive_validity
/*
/* FUNCTION:
/*
/*	Verify that at least the target drive letter is
/*	is entered. Verify that they are valid drives.
/*
/***************************************************/
void check_drive_validity(argc,argv)
int	argc;
char	*argv[];
{
	char	*t;
	int	i;
	BYTE	specified_drive;

	if (argc < 2)
	  error_exit(NO_SOURCE);

	  /*********************/
	  /* Verify the source */
	  /*********************/
	*argv[1] = (BYTE)com_toupper(*argv[1]);


	t = argv[1];
	t++;
	if (*t == ':')          /* Check specified source drive */    /*;AC000;p2671*/
	  {							      /*;AN000;p2671*/
	   if (*argv[1] < 'A')                                        /*;AN000;p2671*/
	    error_exit(INV_DRIVE);				      /*;AN000;p2671*/
	   if (*argv[1] > 'Z')                                        /*;AN000;p2671*/
	    error_exit(INV_DRIVE);				      /*;AN000;p2671*/
	    src_drive_letter = *argv[1];			      /*;AN000;p2671*/
	  }			/* Use default drive for source */    /*;AN000;p2671*/
	 else							      /*;AN000;p2671*/
	  src_drive_letter = (BYTE)def_drive + 'A' - 1;               /*;AN000;p2671*/

	  /*********************/
	  /* Verify the target */
	  /*********************/
	if (argc < 3 )
	  error_exit(NO_TARGET);

	*argv[2] = (BYTE)com_toupper(*argv[2]);

	if (*argv[2] < 'A')
	 error_exit(INV_DRIVE);
	if (*argv[2] > 'Z')
	 error_exit(INV_DRIVE);

				/* Verify drive letter followed by ":" */
	t = argv[2];
	t++;
	if (*t != ':')
	 error_exit(NO_TARGET);

				/* Make sure drive letters are different */
	if (src_drive_letter == *argv[2])			     /*;AN000;p2671*/
	  error_exit(SRC_AND_TGT_SAME);

				/* Is source a valid drive? */
	specified_drive = src_drive_letter - 'A' + 1;
	set_default_drive(specified_drive);
	if (get_current_drive() != specified_drive)
	 error_exit(INV_DRIVE);

				/* Is target a valid drive? */
	specified_drive = *argv[2] - 'A' + 1;
	set_default_drive(specified_drive);
	if (get_current_drive() != specified_drive)
	 error_exit(INV_DRIVE);

	set_default_drive(def_drive);		/* Reset default drive to original one */
	def_drive_set = FALSE;

	tgt_drive_letter = *argv[2];

	return;
}	/* end check_drive_validity */

/*************************************************/
/*
/* SUBROUTINE NAME:	check_for_device_names
/*
/* FUNCTION:
/*
/*	Make sure user not trying to restore a reserved device name
/*
/**************************************************/
#define INVPARM 10						      /*;AN000;4*/
void check_for_device_names(argv)				      /*;AN000;p2592*/
char	*argv[];						      /*;AN000;p2592*/
{								      /*;AN000;p2592*/
	union REGS qregs;					      /*;AN000;p2592*/
	char target[128];					      /*;AN000;p2592*/
	char *t;						      /*;AN000;p2592*/

#define CAPITALIZE_STRING 0x6521				      /*;AN000;p2592*/

	qregs.x.ax = CAPITALIZE_STRING; 			      /*;AN000;p2592*/
	qregs.x.dx = (WORD)argv[1];				      /*;AN000;p2592*/
	strcpy(target,argv[1]); 				      /*;AN000;p2592*/
	qregs.x.cx = strlen(target);				      /*;AN000;p2592*/
	intdos(&qregs,&qregs);					      /*;AN000;p2592*/
	strcpy(target,argv[1]); 				      /*;AN000;p2592*/

	for (t=&target[0]; *t!=NUL; t++)
	 if							      /*;AN000;p2592*/
	  ( strcmp(t,"LPT1")==0   ||                                  /*;AN000;p2592*/
	    strcmp(t,"LPT2")==0   ||                                  /*;AN000;p2592*/
	    strcmp(t,"PRN")==0    ||                                  /*;AN000;p2592*/
	    strcmp(t,"CON")==0    ||                                  /*;AN000;p2592*/
	    strcmp(t,"NUL")==0    ||                                  /*;AN000;p2592*/
	    strcmp(t,"AUX")==0    ||                                  /*;AN000;p2592*/
	    strcmp(t,"LPT1:")==0  ||                                  /*;AN000;p2592*/
	    strcmp(t,"LPT2:")==0  ||                                  /*;AN000;p2592*/
	    strcmp(t,"PRN:")==0   ||                                  /*;AN000;p2592*/
	    strcmp(t,"CON:")==0   ||                                  /*;AN000;p2592*/
	    strcmp(t,"NUL:")==0   ||                                  /*;AN000;p2592*/
	    strcmp(t,"AUX:")==0                                       /*;AN000;p2592*/
	  )							      /*;AN000;p2592*/
	 {							      /*;AN000;p2592*/
	   sublist.value1 = (char far *)t;			      /*;AN000;p2592*/
	   sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;	      /*;AN000;p2592*/
	   sublist.one = 0;					      /*;AN000;p2592*/
	   sublist.max_width1 = (BYTE)strlen(t);		      /*;AN000;p2592*/
	   sublist.min_width1 = sublist.max_width1;		      /*;AN000;p2592*/

	   display_it (INVPARM,STDERR,1,NOWAIT,(BYTE)PARSEERROR);     /*;AN000;p2592*/
	   return_code = RETCODE_ERROR; 			      /*;AN000;4*/
	   clean_up_and_exit(); 				      /*;AN000;4*/
	 }							      /*;AN000;p2592*/


	return; 						      /*;AN000;p2592*/
}								      /*;AN000;p2592*/


/*************************************************/
/*
/* SUBROUTINE NAME:	check_path_validity
/*
/* FUNCTION:
/*
/*	Verify that the path entered by the user exists.
/*	Build a full path from the root, place it in
/*	src_drive_path.  Extract filespec and place it
/*	in user_filespec.
/*
/***************************************************/
void check_path_validity(argv)
char	*argv[];
{
	WORD	dhandle;
	char	temppath[PATHLEN+20];
	char	temppath2[PATHLEN+20];
	char	globals = FALSE;
	int	x;						/*;AN000;p2943*/
	char	*foo,*foo2;					/*;AN003;*/
	union	REGS   qregs;					/*;AC000;8*/

	strcpy(src_drive_path_fn,argv[1]);		/* Copy argv[1] to string area */

	for (x=0; x<strlen(src_drive_path_fn); x++)	/*;AN000;p2943*/
	  if (src_drive_path_fn[x] == BACKSLASH)	/*;AN000;p2943*/
	   if (src_drive_path_fn[x+1] == BACKSLASH)	/*;AN000;p2943*/
	    error_exit(INV_PATH);			/*;AN000;p2943*/

	if (strlen(src_drive_path_fn) == 2)		/* If only a drive letter entered, make it d:*.*   */
	 if (src_drive_path_fn[1] == ':')               /*;AN000;p2671*/
	  strcat(src_drive_path_fn,"*.*");

	if (src_drive_path_fn[strlen(src_drive_path_fn)-1] == BACKSLASH)/*;AN000;p2671*/
	  strcat(src_drive_path_fn,"*.*");              /*;AN000;p2671*/

	xlat(src_drive_path_fn,src_drive_path_fn);	/*;AN000;p2671*/

		/* Handle UNC format  ( \\srv\name\path\path\file ) (Remote drive) */
	if (src_drive_path_fn[0] == BACKSLASH)		/*;AN003;*/
	 if (src_drive_path_fn[1] == BACKSLASH) 	/*;AN003;*/
	  {						/*;AN003;*/
	   foo = strchr(src_drive_path_fn+3,BACKSLASH); /*;AN003;*/
	   if (foo == NUL)				/*;AN003;*/
	    error_exit(INV_PATH);			/*;AN003;*/

	   foo2 = foo + 1;				/*;AN003;*/
	   foo = strchr(foo2,BACKSLASH);		/*;AN003;*/
	   if (foo == NUL)				/*;AN003;*/
	    error_exit(INV_PATH);			/*;AN003;*/

	   sprintf(src_drive_path_fn,"%c:%s",src_drive_letter,foo);  /*;AN003;*/
	  }						/*;AN003;*/

				/* See if there are global characters specified */
	if (com_strchr(src_drive_path_fn,'?') != NUL)
	  globals = TRUE;
	 else
	  if (com_strchr(src_drive_path_fn,'*') != NUL)
	   globals = TRUE;


	 if (src_drive_path_fn[3] == BACKSLASH)     /*	Don't let user entered d:\\ */
	  if (src_drive_path_fn[2] == BACKSLASH)
	   error_exit(INV_PATH);

	if (source_removable)		/* If backing up from a diskette */
	 {
	  display_msg(INSERTSOURCE);	/* Ask user for diskette and wait for input*/
	/*wait_for_keystroke(); 	/* Let user "Strike any key when ready" */
	 }


				/* If single drive system, eliminates double prompting */
				/* for user to "Insert diskette for drive %1" */
	qregs.x.ax = SETLOGICALDRIVE;				      /*;AN000;8*/
	qregs.h.bl = src_drive_letter - 'A' + 1;                      /*;AN000;8*/
	intdos(&qregs,&qregs);					      /*;AN000;8*/

	find_first			/* Check for Invalid Path */
	 (				/* Also figure out if it is file or directory */
	  &src_drive_path_fn[0],
	  &dhandle,
	  dta_addr,
	  (SUBDIR + SYSTEM + HIDDEN)
	 );

	if (rc != NOERROR)		/* If there was an error */
	 if (rc == 3)			/* If it was Path Not Found */
	  error_exit(INV_PATH); 	/* Terminate */

	if (rc == NOERROR)
	 findclose(dhandle);

	if ((dta.attributes & SUBDIR) == SUBDIR) /* If they entered a subdirectory name, */
	  if (dta.file_name[0] != '.')           /* add to the end of it "\*.*"     */
	   if (!globals)			 /* But only if there are no global chars */
	    strcat(src_drive_path_fn,"\\*.*");


			/************************/
			/* Build src_drive_FN  **/
	strcpy(src_drive_path,src_drive_path_fn);

					/* Remove last BACKSLASH to get the pathname */
	foo = com_strrchr(src_drive_path,BACKSLASH);

	if (foo != NUL)
	 if ((foo - src_drive_path) > 2)
	  *foo = NUL;
	  else
	    {	       /* foo must = 2 */
	      foo++;
	      *foo = NUL;
	    }

			/************************/
			/* Build   src_fn      **/
	foo = com_strrchr(src_drive_path_fn,BACKSLASH); 	/*;AN000;p2341*/

	if (foo == NUL) 					/*;AN000;p2341*/
	  foo = &src_drive_path_fn[2];				/*;AN000;p2341*/
	 else							/*;AN000;p2341*/
	  foo++;	   /* Skip over last non-DBCS char */	/*;AN000;p2341*/

	strcpy(src_fn,foo);					/*;AN003;*/

	got_path_validity = TRUE;		/*;AN000;4*/

	return;
}	/* end check_path_validity */

/*************************************************/
/*
/* SUBROUTINE NAME:	alloc_buffers
/*
/* FUNCTION:
/*	Attempt to allocate a (64k-1) buffer. If
/*	fails, decrement buff size by 512 and keep
/*	trying. If can't get at least a 2k buffer,
/*	give up.
/*
/***************************************************/
void alloc_buffer()
{
	alloc_seg();

	while ((rc != NOERROR) && (data_file_alloc_size > 2048))
	 {
	  data_file_alloc_size = data_file_alloc_size - 512;
	  alloc_seg();
	 }

	if (rc == NOERROR  &&  data_file_alloc_size > 2048)
	  buffers_allocated = TRUE;
	 else
	  error_exit(INSUFF_MEMORY);

	return;
}

/*************************************************/
/*
/* SUBROUTINE NAME:	process_switch
/*
/* FUNCTION:
/*
/*	Identify the parameter and set program control
/*	flags as appropriate.
/*
/***************************************************/
void process_switch()						      /*;AN000;4*/
{								      /*;AN000;4*/
	char	far * y;					      /*;AN000;4*/
	int	i = 0;						      /*;AN000;4*/
	char	temp_str[PATHLEN+20];				      /*;AN000;7*/

   if (sw_buff.sw_synonym_ptr == (WORD)&sw1.switch1[0])    /*  /S  */ /*;AN000;4 /S */
    {								      /*;AN000;4*/
     do_subdirs=TRUE;						      /*;AN000;4*/
    }								      /*;AN000;4*/

   if (sw_buff.sw_synonym_ptr == (WORD)&sw5.switch1[0])    /*  /F */  /*;AN001;DCR 434 /F */
    {								      /*;AN001;DCR 434*/
     if (!target_removable)					      /*;AN001;DCR 434*/
      error_exit(CANT_FORMAT_HARDFILE); 			      /*;AN001;DCR 434*/

     do_format_parms=TRUE;					      /*;AN001;DCR 434*/
     format_size[0] = ' ';      /* Can't do STRCPY during PARSE */    /*;AN001;DCR 434*/
     format_size[1] = '/';                                            /*;AN001;DCR 434*/
     format_size[2] = 'F';                                            /*;AN001;DCR 434*/
     format_size[3] = ':';                                            /*;AN001;DCR 434*/
     format_size[4] = NUL;					      /*;AN001;DCR 434*/

     i = 4;		      /* Copy size */			      /*;AN001;DCR 434*/
     for (y=(char *)sw_buff.sw_string_ptr; *y!=NUL; y++)	      /*;AN001;DCR 434*/
      { 							      /*;AN001;DCR 434*/
       format_size[i] = (BYTE)*y;				      /*;AN001;DCR 434*/
       i++;							      /*;AN001;DCR 434*/
      } 							      /*;AN001;DCR 434*/

				/* Handle case where user only enters /F */
     if (
	 format_size[4] == NUL	||				      /*;AN001;DCR 434*/
	 format_size[4] < '0'   ||                                    /*;AN001;DCR 434*/
	 format_size[4] > '9'                                         /*;AN001;DCR 434*/
	)							      /*;AN001;DCR 434*/
      format_size[0] = NUL;					      /*;AN001;DCR 434*/

    }								      /*;AN001;DCR 434*/

   if (sw_buff.sw_synonym_ptr == (WORD)&sw1.switch2[0])    /*  /M */  /*;AN000;4 /M */
    {								      /*;AN000;4*/
      do_modified=TRUE; 					      /*;AN000;4*/
    }								      /*;AN000;4*/

   if (sw_buff.sw_synonym_ptr == (WORD)&sw1.switch3[0])    /*  /A */  /*;AN000;4 /A */
    {								      /*;AN000;4*/
      do_add=TRUE;						      /*;AN000;4*/
    }								      /*;AN000;4*/

   if (sw_buff.sw_synonym_ptr == (WORD)&sw4.switch1[0])    /*  /L */  /*;AN000;4 /L */
     {								      /*;AN000;4*/
       do_logfile = TRUE;					      /*;AN000;4*/
       i = 0;			/* Copy filespec */		      /*;AN000;4*/
       for (y=(char far *)sw_buff.sw_string_ptr; *y!=NUL; y++)	      /*;AN000;4*/
	{							      /*;AN000;4*/
	 temp_str[i] = (BYTE)*y;				      /*;AN000;4*/
	 i++;							      /*;AN000;4*/
	}							      /*;AN000;4*/

       temp_str[i] = NUL;					      /*;AN000;4*/

       if (strlen(temp_str) == 0)	/* Use default logfile? */    /*;AN000;7 Is default logfile?*/
	 sprintf(temp_str,"%c:\\BACKUP.LOG",src_drive_letter);        /*;AN000;7*/

       xlat(logfile_path,temp_str);				      /*;AN000;7*/

       if ((BYTE)logfile_path[0] == tgt_drive_letter)		      /*;AN000;7*/
	logfile_on_target = TRUE;				      /*;AN000;7*/
     }								      /*;AN000;4*/

    return;							      /*;AN000;4*/
}     /* end process_switch */					      /*;AN000;4*/


/*************************************************/
/*
/* SUBROUTINE NAME:	save_current_dirs
/*
/* FUNCTION:
/*
/*	Save the current directory on default drive.
/*	Later when we terminate we must restore it.
/*
/***************************************************/
void save_current_dirs()
{

	src_def_dir[0] = BACKSLASH;
	get_current_dir(src_drive_letter -'A'+1,&src_def_dir[1]);

	return;
}	/* end save_current_dirs */
/*************************************************/
/*
/* SUBROUTINE NAME:	open_logfile
/*
/* FUNCTION:
/*	User specified the /L parameter for a BACKUP
/*	log file. First try to open it. If it doesn't
/*	exist then create it.
/*
/***************************************************/
void open_logfile()
{
	int	x;					/*;AN000;7*/

	handle_logfile =				/*;AN000;5*/
	 extended_open					/*;AN000;5*/
	  (OPEN_IT,					/* Flag;AN000;5*/
	   0,						/* attr;AN000;5*/
	   (char far *)logfile_path,			/* path;AN000;5*/
	   (WORD)(DENYWRITE+WRITEACCESS)		/* mode;AN000;5*/
	  );						/*;AN000;5*/

	if (rc == NOERROR)
	   lseek(handle_logfile,EOFILE,(DWORD)0);
	 else				/* If you didn't, create the file */
	   handle_logfile =		      /*;AN000;5*/
	    extended_open		      /*;AN000;5*/
	     ( CREATE_IT,		      /*;AN000;5*/
	       (WORD)ARCHIVE,		      /*;AN000;5*/
	       (char far *)logfile_path,      /*;AN000;5*/
	       (WORD)(WRITEACCESS)	      /*;AN000;5*/
	     ); 			      /*;AN000;5*/

	if (rc != NOERROR)		/* Terminate if can't open logfile */
	 error_exit(CANT_OPEN_LOGFILE);

	display_msg(LOGGING);		/* Tell user where we are logging */

	datetime();			/* Put date and time of BACKUP in logfile */

	logfile_opened = TRUE;		/*;AN000;7 The logfile is open */

	return;
}	/* end open_logfile */

/*************************************************/
/*
/* SUBROUTINE NAME:	set_vectors
/*
/* FUNCTION:
/*	Hook control break and critical vector to
/*	allow BACKUP to gracefully terminate.
/*
/***************************************************/
void set_vectors()
{

	setsignal(ACTIONHOOK,CTRLC);			/* Handle CTRL_C */
	setsignal(ACTIONHOOK,CTRLBREAK);		/* Handle CTRL_BREAK */
	set_int24_vector();				/*;AN000; Set Critical error vector (int 24h) */

	return;
}	/* end set_vectors */

/*************************************************/
/*
/* SUBROUTINE NAME:	check_appendX
/*
/* FUNCTION:
/*	Check APPEND /X status.  If it is not active,
/*	do nothing. If it is active, then turn it off
/*	and set flag indicating that we must reset it later.
/*
/***************************************************/
void check_appendX()				/*;AN000;2*/
{						/*;AN000;2*/
	union REGS gregs;			/*;AN000;2 Register set */

	gregs.x.ax = INSTALL_CHECK;		/*;AN000;2 Get installed state*/
	int86(0x2f,&gregs,&gregs);		/*;AN000;2*/

		/*****************************************************/
		/*  1) See if append is active
		/*  2) If so, figure out if DOS or PCNET version
		/*****************************************************/
	if (gregs.h.al == 0)			/*;AN000;2 Zero if not installed*/
	  append_indicator = NOT_INSTALLED;	/*;AN000;2 */
	 else					/*;AN000;2 See which APPEND it is*/
	   {					/*;AN000;2*/
	    gregs.x.ax = GET_APPEND_VER;	/*;AN000;2*/
	    int86(0x2f,&gregs,&gregs);		/*;AN000;2*/

	    if (gregs.h.al == (BYTE)-1) 	/*;AN000;2 -1 if DOS version*/
	     append_indicator = DOS_APPEND;	/*;AN000;2*/
	    else				/*;AN000;2*/
	     append_indicator = NET_APPEND;	/*;AN000;2*/
	   }					/*;AN000;2*/

		/*****************************************************/
		/*  If it is the DOS append
		/*    1) Get the current append functions (returned in BX)
		/*    2) Reset append with /X support off
		/*****************************************************/
	if (append_indicator == DOS_APPEND)	/*;AN000;2*/
	 {					/*;AN000;2*/
	    gregs.x.ax = GET_STATE;		/*;AN000;2 Get active APPEND functions*/
	    int86(0x2f,&gregs,&gregs);		/*;AN000;2*/
	    original_append_func = gregs.x.bx;	/*;AN000;2*/

	    gregs.x.ax = SET_STATE;		/*;AN000;2*/
	    gregs.x.bx = gregs.x.bx & (!APPEND_X_BIT);	/*;AN000;2*/
	    int86(0x2f,&gregs,&gregs);		/*;AN000;2*/

	 }					/*;AN000;2*/

	return; 				/*;AN000;2*/
}						/*;AN000;2*/

/*************************************************/
/*
/* SUBROUTINE NAME:	get_drive_types
/*
/* FUNCTION:
/*	For the source and target drives, figure out
/*	if they are removable or not.
/*
/***************************************************/
void get_drive_types()	/* Check if the source and target drive are removable*/
{
#define REMOVABLE 0

	WORD	drivehandle;
	char	drive_spec[3];

				/* Check Source drive */
	drive_spec[0] = src_drive_letter;
	drive_spec[1] = ':';
	drive_spec[2] = NUL;

			/* Device open, source drive */
	drivehandle = handle_open(drive_spec,OPENDASD+DENYNONE) 	  ;

			/* Now see if it is removable */
	if (ioctl(drivehandle) == REMOVABLE)
	   source_removable = TRUE;
	 else
	   source_removable = FALSE;

	close_file(drivehandle);

				/* Check Target drive */
	drive_spec[0] = tgt_drive_letter;
	drive_spec[1] = ':';
	drive_spec[2] = NUL;

	drivehandle = handle_open(drive_spec,OPENDASD+DENYNONE) 	  ;

	if (ioctl(drivehandle) == REMOVABLE)
	   target_removable = TRUE;
	 else
	   target_removable = FALSE;

	close_file(drivehandle);

	return;
}	/* end get_drive_types */

/*************************************************/
/*
/* SUBROUTINE NAME:	do_backup
/*
/* FUNCTION:
/*
/*	BACKUP all files that should be backed up
/*
/***************************************************/
void do_backup()
{
	set_default_dir();		/* Set default dir to one where source files are */

	find_first_file();		/* Find first file to be backed up */
	if (back_it_up) 		/* If you found one.... */
	 {				/*  then */
	   get_first_target();		/*   get the first diskette (or last if /A specified!) */
	   do				/*   Repeat this */
	    {
	      open_source_file();	/*	Open the file we found */
	      if (source_opened)	/*	If succeessful open of source */
		do_copy();		/*	Copy it to the target drive. Handle files that span diskettes. */
	      find_next_file(); 	/*	Search for another file */
	    }
	   while (back_it_up);		/*   While there are file to back up */
	   display_msg(CRLF);
	 }
       else				/* otherwise */
	 {
	   display_msg(NONEFNDMSG);
	   return_code = RETCODE_NO_FILES;/* there were no files to be backed up */
	 }

	clean_up_and_exit();

	return;
}	/* end do_backup */
/*************************************************/
/*
/* SUBROUTINE NAME:	find_first_file
/*
/* FUNCTION:
/*
/*	Find the first file conforming to user entered spec.
/*	If necessary, look on other directory levels also.
/*
/***************************************************/
void find_first_file()
{
	char loop_done = FALSE;

	back_it_up = FALSE;		/* Havn't found a file yet ! */
	find_the_first();		/* Sets the "found_a_file" flag */

	if (found_a_file)		/* If you find a file, do this stuff */
	 do
	  {
	    if (found_a_file)		/* If you got one, then */
	      see_if_it_should_be_backed_up(); /* Check it against user entered parameters */

	    if (!back_it_up)		/* If it shouldn't be processed... */
	       find_the_next(); 	/*  then find another (sets the "found_a_file" flag) */
	     else
	       loop_done = TRUE;	/* Otherwise your done here */

	    if (!found_a_file)		/* Don't remove this ! */
	      loop_done = TRUE; 	/* This has gotta stay ! */
	  }
	 while (!loop_done);

	 return;
}	/* end find_first_file */

/***********************************************/
/*
/* SUBROUTINE NAME:	find_next_file
/*
/* FUNCTION:
/*
/*	Find the next file conforming to user entered spec
/*
/************************************************/
void find_next_file()
{
	char loop_done = FALSE;

	back_it_up = FALSE;

	do
	 {
	  find_the_next();
	  if (found_a_file)
	    {
	      see_if_it_should_be_backed_up();
	      if (back_it_up)
	       loop_done = TRUE;
	    }
	   else
	    loop_done = TRUE;
	 }
	while (!loop_done);

	return;
}	/* end find_next_file */

/***********************************************/
/*
/* SUBROUTINE NAME:	find_the_first
/*
/* FUNCTION:
/*
/*	Find the first file conforming to user entered spec.
/*	Searches in current directory, if one not found then
/*	goes to the next level and repeats.
/*
/************************************************/
void find_the_first()
{
	char loop_done = FALSE;
	char file_spec[PATHLEN];

	found_a_file = FALSE;
	sprintf(file_spec,"%c:%s",src_drive_letter,src_fn);

	do
	 {
	  find_first			/* Find file conforming to user-entered file spec */
	   (
	    &file_spec[0],
	    &dirhandle,
	    dta_addr,
	    (SYSTEM + HIDDEN)
	   );

	  if (rc == NOERROR)
	   {				/* If no error */
	     found_a_file = TRUE;	/* then we found a file */
	     loop_done = TRUE;		/* and we are done here */
	   }
	   else 			/* If there was an error */
	     if (do_subdirs)		/*  and if user said /S  */
	      {
		change_levels();	/* Change DIR (Sets NewDirectory if level changed) */
		if (!new_directory)	/* If there ain't none */
		 loop_done = TRUE;	/* then were done */
	      }
	      else
	       loop_done = TRUE;
	 }
	while (!loop_done);

	return;
}	/* end find_the_first */
/*************************************************/
/*
/* SUBROUTINE NAME:	find_the_next
/*
/* FUNCTION:
/*
/*	Find the next file conforming to user entered spec
/*
/***************************************************/
void find_the_next()
{
	char loop_done = FALSE;

	found_a_file = FALSE;

	find_next(dirhandle,dta_addr);

	if (rc == NOERROR)
	 {
	   found_a_file = TRUE;
	   loop_done = TRUE;
	 }
	 else
	  do
	   {
	     if (do_subdirs)
	      {
		change_levels();    /* Change DIR to next dir level */
		if (!new_directory)		    /* If we were successful */
		  loop_done = TRUE;		    /* Then indicate that fact */
		 else				    /* otherwise */
		  {
		    find_the_first();		    /* Look for first file at this level */
		    loop_done = TRUE;
		  }
	      }
	     else
	      loop_done = TRUE;
	   }
	  while (!loop_done);

	return;
}	/* end find_the_next */

/*************************************************/
/*
/* SUBROUTINE NAME:	change_levels
/*
/* FUNCTION:
/*	Change directory to next one in the linked list
/*	of directories to be processed.
/*
/***************************************************/
void change_levels()
{
	new_directory = FALSE;
	remove_node();
	return;
}	/* end change_levels */

/*************************************************/
/*
/* SUBROUTINE NAME:	alloc_node
/*
/* FUNCTION:
/*	Allocates a node for the linked list of subdirectories
/*	to be processed.
/*
/***************************************************/
struct node * alloc_node(path_len)
unsigned int path_len;
{
	struct node *pointer;
	unsigned int malloc_size;

	malloc_size = (unsigned int) (sizeof(struct node far *) + path_len + 2);
#if defined(DEBUG)
	printf("\nMALLOCING NODE, SIZE=%04Xh...",malloc_size);
#endif

	pointer = (struct node *)malloc(malloc_size);

#if defined(DEBUG)
	if (pointer != NUL)
	  printf("SUCCESSFUL, PTR=%u",(unsigned)pointer);
	 else
	   printf("ERROR, PTR=%u",(unsigned)pointer);
#endif

	if (pointer == NUL)
	   error_exit(INSUFF_MEMORY);
	 else
	   return(pointer);

}	/* end alloc_node */


/*************************************************/
/*
/* SUBROUTINE NAME:	alloc_first_node
/*
/* FUNCTION:
/*
/*	Allocate the first node in the linked list.
/*
/***************************************************/
void alloc_first_node()
{
#if defined(DEBUG)
printf("\nINSERTING FIRST NODE=%s",src_drive_path);
#endif

	curr_node = alloc_node(strlen(src_drive_path+1));
	last_child = curr_node;
	strcpy(curr_node->path,src_drive_path);
	curr_node->np = NUL;

	return;
}	/* end alloc_first_node */


/*************************************************/
/*
/* SUBROUTINE NAME:	insert_node
/*
/* FUNCTION:
/*
/*	Insert next node in the linked list of subdirectories
/*	to be processed.
/*
/***************************************************/
void insert_node(path_addr)
char *path_addr;
{
	struct node *temp;		/* temporary pointer to a node */
	struct node *newnode;		/* same thing */

#if defined(DEBUG)
printf("\nINSERTING NODE=%s",*path_addr);
#endif
	temp = last_child->np;
	newnode = alloc_node(strlen(path_addr));
	last_child->np = newnode;
	newnode->np = temp;
	strcpy(newnode->path,path_addr);
	last_child = newnode;

	return;
}	/* end insert_node */

/*************************************************/
/*
/* SUBROUTINE NAME:	remove_node
/*
/* FUNCTION:
/*	CHDIR to the next level to be processed.
/*	Release the node for that directory
/*
/***************************************************/
void remove_node()
{
	struct node *temp;

	temp = curr_node;
	last_child = curr_node->np;
	if (curr_node->np != NUL)
	 {
	   rc = chdir(last_child->path);
	   if (rc == NOERROR)
	    {
	     new_directory = TRUE;
	     strcpy(src_drive_path,last_child->path);

#if defined(DEBUG)
	printf("\nFREE NODE %u",(unsigned)curr_node);
#endif
	     free((char *)curr_node);
	     curr_node = last_child;

	     if (do_subdirs)		   /* Place all subdirs in linked list */
	      find_all_subdirs();
	    }
	 }
	return;
}	/* end remove_node */

/*************************************************/
/*
/* SUBROUTINE NAME:	find_all_subdirs
/*
/* FUNCTION:
/*	User entered "/S" parameter. Search for all
/*	subdirectory entries at this level. Place
/*	them all in the linked list of directories to
/*	be processed.
/***************************************************/
void find_all_subdirs()
{
	WORD	dhandle;
	char	global[6];
	char	full_path[PATHLEN+20];
	struct	FileFindBuf tempdta;

	sprintf(global,"%c:*.*",src_drive_letter);

	find_first		/* Find all subdirectory entries in current directory. */
	 (
	  &global[0],
	  &dhandle,
	  &tempdta,
	  (SUBDIR + SYSTEM + HIDDEN)
	 );

	while (rc == NOERROR)
	  {
	    if ((tempdta.attributes & SUBDIR) == SUBDIR)  /* If its a subdirectory */
	     if (tempdta.file_name[0] != '.')             /* But not "." or ".." */
	      {
		if (src_drive_path[strlen(src_drive_path)-1] != BACKSLASH)
		  sprintf(full_path,"%s\\%s",src_drive_path,tempdta.file_name);
		 else
		  sprintf(full_path,"%s%s",  src_drive_path,tempdta.file_name);

		insert_node((char *)full_path); 	/* Save it in the linked list */
	      }

	    find_next(dhandle,&tempdta);
	  }

	return;
}

/*************************************************/
/*
/* SUBROUTINE NAME:	get_first_target
/*
/* FUNCTION:
/*	We are ready for the target disk. If it is a
/*	diskette, ask user to put one in. Remember
/*	to correctly handle /A if user wants it.
/*
/***************************************************/
void get_first_target()
{
	if (target_removable)
	  get_diskette();
	 else
	  get_hardfile();

	if (do_logfile)
	  open_logfile();	       /*;AN000;7  Open or create logfile*/

	if (!do_add)
	 put_disk_header();

	return;
}	/* end get_first_target */

/*************************************************/
/*
/* SUBROUTINE NAME:	get_next_target
/*
/* FUNCTION:
/*	We are ready for the next target diskette.
/*	Ask user to insert it.	Format if required.
/*	Create files, reset variables.
/*
/***************************************************/
void get_next_target()
{

	doing_first_target = FALSE;
	files_backed_up = 0;
	display_msg(CRLF);

	get_diskette(); 		/* Get it */

	disk_full = FALSE;

	if (do_logfile)
	 {
	  if (logfile_on_target)	/*;AN000;7  and if logfile on the target drive*/
	    open_logfile();		/*;AN000;7   Open or create it*/
	 }

	if (file_spans_target)
	 show_path();	  /* Display to stdout and logfile the full path from root */

	put_disk_header();
	put_new_fh();

	return;
}	/* end get_next_target */

/*************************************************/
/*
/* SUBROUTINE NAME:	see_if_it_should_be_backed_up
/*
/* FUNCTION:
/*	We found a file, its directory information is
/*	at the DTA structure. Don't backup a subdirectory
/*	or volume label. If /M specified, only backup files
/*	with archive bit set. Don't BACKUP 0 length files.
/*	If /D: and/or /T: specified, only backup appropriate files.
/*
/***************************************************/
void see_if_it_should_be_backed_up()
{
	BYTE	temp[PATHLEN+20];	/*;AN006;*/

	back_it_up = TRUE;

	if ((dta.attributes & SUBDIR) == SUBDIR)	/* Is it a directory name ? */
	   back_it_up = FALSE;				/* Indicate that we don't want to back it up */

	if ((dta.attributes & VOLLABEL) == VOLLABEL)	/* Is it a volumelabel ? */
	   back_it_up = FALSE;				/* Indicate that we don't want to back it up */

	if (do_modified)				/* Check ARCHIVE bit */
	 if ((dta.attributes & ARCHIVE) != ARCHIVE)
	   back_it_up = FALSE;

	if (do_time)					/* Check TIME parameter */
	 {
	   if (do_date)
	     {						/* If user entered a date, only files modified */
	       if (dta.write_date == user_specified_date) /* after specified time AND ON THE DATE ENTERED */
		if (dta.write_time < user_specified_time) /* will be processed. Files dated after that will */
		 back_it_up = FALSE;			/* ignore time parm */
	     }
	    else					/* If user entered time with NO DATE PARM, then */
	     if (dta.write_time < user_specified_time)	/* files modifed on or after specified time will be */
	      back_it_up = FALSE;			/* processed, regardless of date */
	 }

	if (do_date)					/* Check DATE parameter */
	 {
	   if (dta.write_date < user_specified_date)
	    back_it_up = FALSE;
	 }

#define SAME 0

	if (strcmp(src_drive_path+2,"\\") == SAME)              /*;AN000;1 If we are processing the root directory */
	  if							/*;AN000;1  and if we are looking at any of these files */
	   (strcmp(dta.file_name,"IBMBIO.COM")  == SAME ||      /*;AN000;1*/
	    strcmp(dta.file_name,"IBMDOS.COM")  == SAME ||      /*;AN000;1*/
#if ! IBMCOPYRIGHT
	    strcmp(dta.file_name,"IO.SYS")      == SAME ||      /*;AN000;1*/
	    strcmp(dta.file_name,"MSDOS.SYS")   == SAME ||      /*;AN000;1*/
#endif
	    strcmp(dta.file_name,"COMMAND.COM") == SAME ||      /*;AN000;1*/
	    strcmp(dta.file_name,"CMD.EXE")     == SAME         /*;AN000;1*/
	   )							/*;AN000;1*/
	  back_it_up = FALSE;					/*;AN000;1  then do not back them up! */



	if (do_logfile) 			/*;AN006;*/
	 {					/*;AN006;*/
	  strcpy(temp,src_drive_path);		/*;AN006;*/

	  if (strlen(temp) == 3)		/*;AN006;*/
	   temp[2] = NUL;			/*;AN006;*/

	  sprintf(temp,"%s\\%s",temp,dta.file_name);    /*;AN006;*/

	  if (strcmp(logfile_path,temp) == SAME)/*;AN006;*/
	    back_it_up = FALSE; 		/*;AN006;*/
	 }					/*;AN006;*/

	return;
}	/* end see_if_it_should_be_backed_up */

/*************************************************/
/*
/* SUBROUTINE NAME:	get_diskette
/*
/* FUNCTION:
/*	Get the diskette from user. If unformatted
/*	and user entered /F, then try to FORMAT it.
/*	Create target files on root of diskette.
/**************************************************/
void get_diskette()
{
	union REGS qregs;					      /*;AN000;8*/

	if (!do_add)
	 {
	   display_msg(INSERTTARGET);
	   display_msg(ERASEMSG);
	 }
	 else
	   if (doing_first_target)
	     display_msg(LASTDISKMSG);
	    else
	     {
	       display_msg(INSERTTARGET);
	       display_msg(ERASEMSG);
	     }

	got_first_target = TRUE;	/*;AN000;*/

      /*wait_for_keystroke();		/* Let user "Strike any key when ready" */

				/* If single drive system, eliminates double prompting */
				/* for user to "Insert diskette for drive %1" */
	qregs.x.ax = SETLOGICALDRIVE;				      /*;AN000;8*/
	qregs.h.bl = tgt_drive_letter - 'A' + 1;                      /*;AN000;8*/
	intdos(&qregs,&qregs);					      /*;AN000;8*/

	if (target_removable)					      /*;AN000;d177*/
	 format_target();

	if (do_add)			/* If we are adding files */
	 if (doing_first_target)	/* and if its the first target */
	  check_last_target();		/* verify that its a valid one */

	display_msg(BUDISKMSG);
	display_msg(SEQUENCEMSG);
	delete_files(ROOTDIR);		/* Delete all files in the root dir of target drive */

	create_target();		/* Create target files */

	return;
}	/* end get_diskette */

/*************************************************/
/*
/* SUBROUTINE NAME:	get_hardfile
/*
/* FUNCTION:
/*	Target is a hardfile. FORMATTING hardfile is
/*	not allowed by BACKUP.	Create target files
/*	in BACKUP directory of disk.
/***************************************************/
void get_hardfile()
{
	char	dirname[15];

	sprintf(dirname,"%c:\\BACKUP\\*.*",tgt_drive_letter);
	if (exist(&dirname[0]))
	  {
	   if (!do_add)
	    {
	     display_msg(FERASEMSG);
	   /*wait_for_keystroke();	/* Let user "Strike any key when ready" */
	    }
	   delete_files(BACKUPDIR);	/* Delete \BACKUP\*.* of target drive if not do_add */
	  }
	 else
	  {
	   sprintf(dirname,"%c:\\BACKUP",tgt_drive_letter);
	   mkdir(dirname);
	  }

	display_msg(BUDISKMSG);
	create_target();

	return;
}	/* end get_hardfile */


/*************************************************/
/*
/* SUBROUTINE NAME:    check_last_target
/*
/* FUNCTION:
/*	User entered /A parameter. Make sure that
/*	we are not adding to a BACKUP diskette created
/*	with the disgusting old BACKUP format.
/*	Make sure there is a BACKUP.xxx and CONTROL.xxx
/*	file out there.  Make sure it was the last target
/*	and get the sequence number.
/***************************************************/
void check_last_target()
{
	WORD	dhandle;
	WORD	bytes_read;
	BYTE	flag;
	char	path[25];
	char	current_file[25];

	struct	FileFindBuf tempdta;

	if (target_removable)		/* Make sure there is no old BACKUP on here */
	  sprintf(path,"%c:\\BACKUPID.@@@",tgt_drive_letter);
	 else
	  sprintf(path,"%c:\\BACKUP\\BACKUPID.@@@",tgt_drive_letter);

	if (exist(path))
	 error_exit(INVTARGET);

	if (target_removable)		/* Build path to control file */
	  sprintf(path,"%c:\\CONTROL.*",tgt_drive_letter);
	 else
	  sprintf(path,"%c:\\BACKUP\CONTROL.*",tgt_drive_letter);

	find_first			/* Find the control file */
	 (
	  &path[0],
	  &dhandle,
	  &tempdta,
	  (SYSTEM + HIDDEN)
	 );

	if (rc != NOERROR)		/* If you got one, then close dirhandle */
	 error_exit(NOTLASTMSG);

	findclose(dhandle);


					/* Add drive letter to control file name */
	sprintf(path,"%c:%s",tgt_drive_letter,tempdta.file_name);

	handle_control =		/* Open the control file;AN000;5*/
	 extended_open					/*;AN000;5*/
	  (OPEN_IT,					/*;AN000;5*/
	   0,						/*;AN000;5*/
	   (char far *)path,				/*;AN000;5*/
	   (WORD)(DENYWRITE+READACCESS) 		/*;AN000;5*/
	  );						/*;AN000;5*/

	if (rc != NOERROR)		/* If can't open it, strange error */
	  error_exit(NOTLASTMSG);

					/* Get diskette sequence number */
	lseek(handle_control,BOFILE,(DWORD)9);
	bytes_read = handle_read(handle_control,1,(char far *)&diskettes_complete);
	diskettes_complete--;		/* This diskette is not longer "complete" */

					/* Seek to DH_LastDisk and read that byte */
	lseek(handle_control,BOFILE,(DWORD)138);	/* Check DH_LastDisk flag in control file */
	bytes_read = handle_read(handle_control,1,(char far *)&flag);

	if (flag != LAST_TARGET)	/* If wasn't last target, terminate */
	  error_exit(NOTLASTMSG);

	close_file(handle_control);	/* Close the control file */
	control_opened = FALSE; 	/*;AN005; And say it isn't open */

	return;
}	/* end check_last_target */
/*************************************************/
/*
/* SUBROUTINE NAME:	format_target
/*
/* FUNCTION:
/*	See if the target is formatted. If not, try
/*	to format it.
/*
/***************************************************/
void format_target()
{
#define HOOK	0
#define UNHOOK	1

	WORD	bfree;
	char	format_parms[35];      /*;AC000;8*/
	WORD	temp_rc;	       /*;AN000;p2631 Return code from DOS calls */

	if (do_add)
	 if (doing_first_target)
	  return;

				/**********************************/
				/* See if diskette is unformatted */
				/**********************************/
	do_dos_error(HOOK);		/* Replace hard error handler */
	rc = NOERROR;			/* Reset return code */
	checking_target = TRUE; 	/*;AN007;*/
	bfree = (WORD)disk_free_space();/* If this generates hard error, then format target */
	checking_target = FALSE;	/*;AN007;*/

	temp_rc = rc;			/*;AN000;p2631*/
	do_dos_error(UNHOOK);		/*;AN000;p2631 Unhook hard error handler */
	rc = temp_rc;			/*;AN000;p2631*/

	if (rc != NOERROR)		/* If there was a hard error... */
	 {				/* Then FORMAT the target */
	   display_msg(CRLF);

	   sprintf(format_parms,"%c:",tgt_drive_letter);

	   if (do_format_parms) 			/*;AN001;DCR 434*/
	    if (format_size[0] != NUL)			/*;AN001;DCR 434*/
	     strcat(format_parms,format_size);		/*;AN001;DCR 434*/

	   strcat(format_parms," /BACKUP /V:BACKUP");   /*;AN000;8*/

	   if (spawnlp(P_WAIT,format_path,"FORMAT",format_parms,NUL) == NOERROR) /*;AC000;d178*/
	     {
	      display_msg(CRLF);			/* Skip a line */
	     }
	    else
	     {
	      display_msg(ERR_EXEC_FORMAT);		/* Display "Error executing FORMAT" */
	      display_msg(INSERTTARGET);		/* And give another chance */
	      display_msg(ERASEMSG);
	    /*wait_for_keystroke(); */
	     }

	 }

	return;
}	/* end format_target */

/*************************************************/
/*
/* SUBROUTINE NAME:	set_default_dir
/*
/* FUNCTION:
/*
/*
/*
/***************************************************/
void set_default_dir()
{
       if (com_strchr(src_drive_path,BACKSLASH) != NUL) /* if there IS a backslash... */
	if (strlen(src_drive_path) >= 3)		/*  if length is greater than 3... */
	 {
	  rc = chdir(src_drive_path);			/*   then change dir to there. */
	  if (rc == NOERROR)
	   {
	     src_drive_path[2] = BACKSLASH;
	     get_current_dir(src_drive_letter-'A'+1,&src_drive_path[3]);
	   }
	    else
	     error_exit(INV_PATH);
	 }

	curr_dir_set = TRUE;

	if (do_subdirs) 		/* If we are processing subdirectories too, */
	 {
	  alloc_first_node();		/* then put current level in linked list */
	  find_all_subdirs();		/* And get all directory entries in that level */
	 }

	return;
}	/* end set_default_dir */

/*************************************************/
/*
/* SUBROUTINE NAME:	label_target_drive
/*
/* FUNCTION:
/*	Create volume label BACKUP.xxx on target
/*	diskette drive.
/*
/***************************************************/
void label_target_drive()	/* Create Volume label BACKUP.XXX on target   */
{

	char	fsbuf[20];
	WORD	handle;

	build_ext(diskettes_complete + 1);

	sprintf(fsbuf,"%c:BACKUP.%s",tgt_drive_letter,ext);

	replace_volume_label(&fsbuf[0]);

	return;
}	/* end label_target_drive */

/*************************************************/
/*
/* SUBROUTINE NAME:	build_ext
/*
/* FUNCTION:
/*
/*
/*
/***************************************************/
void build_ext(num)
int	num;
{
	if (num < 10)
	  sprintf(ext,"00%u",num);
	 else
	  if (num < 100)
	    sprintf(ext,"0%u",num);
	   else
	     sprintf(ext,"%u",num);

	return;
}	/* end build_ext */

/*************************************************/
/*
/* SUBROUTINE NAME:	create_target
/*
/* FUNCTION:
/*
/*
/*
/***************************************************/
void create_target()
{
	char	path[25];

	if (do_add)
	 if (doing_first_target)
	  {
	   open_target();
	   return;
	  }

	build_ext(diskettes_complete + 1);

	if (target_removable)
	  sprintf(path,"%c:\\BACKUP.%s",tgt_drive_letter,ext);
	 else
	   sprintf(path,"%c:\\BACKUP\\BACKUP.%s",tgt_drive_letter,ext);

	handle_target = 			       /*;AN000;5*/
	 extended_open				       /*;AN000;5*/
	  (					       /*;AN000;5*/
	   CREATE_IT,				       /*;AN000;5*/
	   (WORD)ARCHIVE,			       /*;AN000;5*/
	   (char far *)path,			       /*;AN000;5*/
	   (WORD)(READWRITE)			       /*;AN000;5*/
	  );					       /*;AN000;5*/

	if (rc == NOERROR)
	  target_opened = TRUE;
	 else
	  error_exit(INVTARGET);

	if (target_removable)
	  sprintf(path,"%c:\\CONTROL.%s",tgt_drive_letter,ext);
	 else
	   sprintf(path,"%c:\\BACKUP\\CONTROL.%s",tgt_drive_letter,ext);

	handle_control =	/*;AN000;5*/
	 extended_open		/*;AN000;5*/
	  (			/*;AN000;5*/
	   CREATE_IT,		/*;AN000;5*/
	   (WORD)ARCHIVE,	/*;AN000;5*/
	   (char far *)path,	/*;AN000;5*/
	   (WORD)(READWRITE)	/*;AN000;5*/
	  );			/*;AN000;5*/

	if (rc == NOERROR)
	  control_opened = TRUE;
	 else
	  error_exit(INVTARGET);

	data_file_tot_len = (DWORD)0;
	ctl_file_tot_len = (DWORD)0;

	return;
}	/* end create_target */

/*************************************************/
/*
/* SUBROUTINE NAME:	open_target
/*
/* FUNCTION:
/*
/*
/*
/***************************************************/
void open_target()	/* Done only if /A and it is the first target */
{

	char	path[PATHLEN+20];

				 /* Open BACKUP.xxx File */
	build_ext(diskettes_complete+1);

	if (target_removable)
	  sprintf(path,"%c:\\BACKUP.%s",tgt_drive_letter,ext);
	 else
	  sprintf(path,"%c:\\BACKUP\\BACKUP.%s",tgt_drive_letter,ext);

				/* Turn off readonly bit on BACKUP.xxx */
	set_attribute(path,(WORD)(get_attribute(path) & (WORD)READONLYOFF));
				/* Open it */
	handle_target = 		/*;AN000;5*/
	 extended_open			/*;AN000;5*/
	  ( OPEN_IT,			/*;AN000;5*/
	    0,				/*;AN000;5*/
	    (char far *)path,		/*;AN000;5*/
	    (WORD)(DENYALL+READWRITE)	/*;AN000;5*/
	  );				/*;AN000;5*/

	if (rc == NOERROR)
	  target_opened = TRUE;
	 else
	  error_exit(INVTARGET);
				 /* Open CONTROL.xxx File */
	if (target_removable)
	  sprintf(path,"%c:\\CONTROL.%s",tgt_drive_letter,ext);
	 else
	   sprintf(path,"%c:\\BACKUP\\CONTROL.%s",tgt_drive_letter,ext);

	set_attribute(path,(WORD)(get_attribute(path) & (WORD)READONLYOFF));

	handle_control =		/*;AN000;5*/
	 extended_open			/*;AN000;5*/
	  ( OPEN_IT,			/*;AN000;5*/
	    0,				/*;AN000;5*/
	    (char far *)path,		/*;AN000;5*/
	    (WORD)(DENYALL+READWRITE)	/*;AN000;5*/
	  );				/*;AN000;5*/

	if (rc == NOERROR)
	  control_opened = TRUE;
	 else
	  error_exit(INVTARGET);

	data_file_tot_len = (DWORD)lseek(handle_target ,EOFILE,(DWORD)0);
	ctl_file_tot_len =  (DWORD)lseek(handle_control,EOFILE,(DWORD)0);

	return;
}	/* end open_target */

/*************************************************/
/*
/* SUBROUTINE NAME:	delete_files
/*
/* FUNCTION:
/*	Delete all files in the root directory of target
/*	diskette, or in the BACKUP directory of the target
/*	hardfile.  If error occurs deleting file, try to
/*	reset the attribute to 0 and try it again.
/*
/*
/***************************************************/
void delete_files(dirlevel)
char	dirlevel;
{
	BYTE	delete_path[25];
	struct	FileFindBuf tempdta;
	struct	FileFindBuf *tempdta_addr;
	WORD	dhandle;
	BYTE	delete_it;					      /*;AN000;7*/

	if (do_add)			/* Don't delete files if we */
	 if (doing_first_target)	/* are adding files to an existing */
	  return;			/* BACKUP and this is the first target */

	tempdta_addr = (struct FileFindBuf *)&tempdta;

	if (dirlevel == ROOTDIR)
	  sprintf(delete_path,"%c:\\*.*",tgt_drive_letter);
	 else
	  sprintf(delete_path,"%c:\\BACKUP\\*.*",tgt_drive_letter);

	find_first		/* Find a file to delete */
	 (
	  (char *)&delete_path[0],
	  &dhandle,
	  tempdta_addr,
	  (SYSTEM + HIDDEN)
	 );

	while (rc == NOERROR)
	 {
	  delete_it = TRUE;					      /*;AN000;7*/

	  if (dirlevel == ROOTDIR)
	    sprintf(delete_path,"%c:\\%s",tgt_drive_letter,tempdta.file_name);
	   else
	    sprintf(delete_path,"%c:\\BACKUP\\%s",tgt_drive_letter,tempdta.file_name);

	  if (logfile_on_target)				      /*;AN000;7*/
	   if (strcmp(delete_path,logfile_path) == SAME)	      /*;AN000;7*/
	    delete_it = FALSE;					      /*;AN000;7*/

	  if (delete_it == TRUE)				      /*;AN000;7*/
	   {							      /*;AN000;7*/
	     delete(delete_path);

	     if (rc != NOERROR)
	      {
	       set_attribute(delete_path,(WORD)0);
	       delete(delete_path);
	      }
	   }							      /*;AN000;7*/

	  find_next(dhandle,tempdta_addr);
	 }

	return;
}	/* end delete_files */

/*************************************************/
/*
/* SUBROUTINE NAME:	exist
/*
/* FUNCTION:
/*	Does a FIND FIRST of the filespec passed at PATH_ADDR.
/*	If so, returns TRUE, otherwise returns FALSE.
/*
/***************************************************/
WORD exist(path_addr)	     /* Return TRUE if specified epath exists, FALSE other */
char *path_addr;
{
	WORD	dhandle;
	WORD	temprc;
	struct	FileFindBuf tempdta;

	find_first		/* DOS Find First */
	 (
	  path_addr,
	  &dhandle,
	  &tempdta,
	  (SUBDIR + SYSTEM + HIDDEN)
	 );

	temprc = rc;
	if (rc == NOERROR) findclose(dhandle);

	if (temprc != NOERROR)
	  return(FALSE);
	 else
	  return(TRUE);

}	/* end exist */

/*************************************************/
/*
/* SUBROUTINE NAME:	open_source_file
/*
/* FUNCTION:
/*	Try to open the source file at the DTA structure.
/*	If after MAX_RETRY_OPEN_COUNT attempts you cannot
/*	open it, then display an appropriate message and
/*	continue. If it was opened, then get the files
/*	extended attributes.
/*
/***************************************************/
void open_source_file()
{
	int	num_attempts = 0;
	char	done = FALSE;
	char	file_to_be_backup[20];

	source_opened = FALSE;		/* Source is not opened yet */
	file_spans_target = FALSE;	/* File does not spans diskettes */
	span_seq_num = 1;		/* Indicate that this is the first diskette containing part of this file*/
	show_path();			/* Display to stdout/logfile the full path from root */
	sprintf(file_to_be_backup,"%c:%s",src_drive_letter,dta.file_name);

	do
	 {					/*;AN000;5*/	 /* Attempt open */
	   handle_source =			/*;AN000;5*/
	    extended_open			/*;AN000;5*/
	     (					/*;AN000;5*/
	      OPEN_IT,				/*;AN000;5*/
	      0,				/*;AN000;5*/
	      (char far *)file_to_be_backup,	/*;AN000;5*/
	      (WORD)(DENYWRITE+READACCESS)	/*;AN000;5*/
	     ); 				/*;AN000;5*/

	   if (rc != NOERROR)				/* Check for error */
	     {						/* Handle Share Errors */
	       num_attempts++;				/* Increment number of attempts */
	       if (num_attempts == MAX_RETRY_OPEN_COUNT)/* Compare with max number of retries to perform */
		 {
		  file_sharing_error(); 		/*;AN000;9 There was a share error opening the file*/
		  done = TRUE;
		 }
	     }
	    else
	     {
	       source_opened = TRUE;			/* Set flag indicating file is opened */
	       done = TRUE;				/* We are done in this loop */

/*EAEAEAEAEA   get_extended_attributes(handle_source);	/*;AN000;3 Get extended attributes for this file  */

	       put_new_fh();				/* Write the file header to the control file */

/*EAEAEAEAE    if (ext_attrib_flg)			/*;AN000;3 If the file has extended attributes */
/*EAEAEAEAE	write_extended_attributes();		/*;AN000;3then write them to BACKUP file */
	     }
	 }
	while (!done);

	return;
}	/* end open_source_file */

/*************************************************/
/*
/* SUBROUTINE NAME:	file_sharing_error
/*
/* FUNCTION:
/*
/*	Handle the file sharing error that just occurred
/*
/***************************************************/
void file_sharing_error()					      /*;AN000;9*/
{								      /*;AN000;9*/
	union	REGS	reg;					      /*;AN000;9*/

	display_msg(CRLF);
	display_msg(CONFLICTMSG);	      /* Say "Last file not backed */
	return_code = RETCODE_SHARE_ERROR;    /* Set errorlevel */

	if (do_logfile) 					      /*;AN000;9*/
	 {							      /*;AN000;9*/
	   reg.x.ax = LASTNOTBACKUP;				      /*;AN000;9*/
	   reg.x.bx = handle_logfile;				      /*;AN000;9*/
#define MSG_LEN 33						      /*;AN000;9*/
	   reg.x.cx = (WORD)MSG_LEN;				      /*;AN000;9*/
	   update_logfile(&reg,&reg);	/* In source file _msgret.sal /*;AN000;9*/
	 }							      /*;AN000;9*/

	return; 						      /*;AN000;9*/
}								      /*;AN000;9*/

/*************************************************/
/*
/* SUBROUTINE NAME:	far_ptr
/*
/* FUNCTION:
/*
/*
/*
/***************************************************/
char far *far_ptr(seg,off)
WORD	seg;
WORD	off;
{
	char far *p;

	PUT_SEG(p,seg);
	PUT_OFF(p,off);

	return(p);
}

/*************************************************/
/*
/* SUBROUTINE NAME:	do_copy
/*
/* FUNCTION:
/*	Copy the source file to the BACKUP.xxx file
/*	If there are extended attributes, write them
/*	to the BACKUP.xxx file.
/***************************************************/
void do_copy()
{
	WORD	bytes_read;
	WORD	bytes_to_read = data_file_alloc_size; /* Read size = buffer size */
	char	done = FALSE;
	char	file_to_be_backup[20];

	part_size = (DWORD)0;
	cumul_part_size = (DWORD)0;

	if (source_opened)
	 {
	   do
	    {
	      bytes_read =
		handle_read
		 (
		  handle_source,
		  bytes_to_read,
		  far_ptr(selector,0)
		 );

	      if (bytes_read == 0)
	       done = TRUE;
	       else
		write_to_target(bytes_read);

	      if (bytes_read < bytes_to_read)
	       done = TRUE;
	    }
	   while (!done);

	   close_file(handle_source);		/* Close the source file handle */
	   source_opened = FALSE;		/* Indicate that the source is not opened */
	   sprintf(file_to_be_backup,"%c:%s",src_drive_letter,dta.file_name);
	   reset_archive_bit(file_to_be_backup);/* Reset the archive bit on the source file */
	   files_backed_up++;			/* Increment number of files backed up */
	 }

	return;
}	/* end do_copy */

/*************************************************/
/*
/* SUBROUTINE NAME:	write_extended_attributes
/*
/* FUNCTION:
/*	There are extended attributes for the file
/*	just backed up.  Write the length of the
/*	extended attributes to the BACKUP.xxx file,
/*	then write the extended attributes the that file.
/*
/**************************************************/
/*#define WRITE_LENGTH 2
/*
/*void write_extended_attributes()				  /*;AN000;3*/
/*{								  /*;AN000;3*/
/*	  WORD	  written;					  /*;AN000;3*/
/*			  /*******************************************/
/*			  /* Write the length of extended attributes */
/*			  /*******************************************/
/*	  written =
/*	   handle_write
/*	    (
/*	     handle_target,
/*	     WRITE_LENGTH,
/*	     (char far *)&ext_attrib_len
/*	    );							  /*;AN000;3*/
/*
/*	  if (written == WRITE_LENGTH ) 			  /*;AN000;3*/
/*	   data_file_tot_len += WRITE_LENGTH;			  /*;AN000;3*/
/*
/*			  /*********************************/
/*			  /* Write the extended attributes */
/*			  /*********************************/
/*	  written = handle_write(handle_target,ext_attrib_len,(char far *)ext_attrib_buff);  /*;AN000;3*/
/*	  if (written == ext_attrib_len)			  /*;AN000;3*/
/*	   data_file_tot_len += (DWORD)written; 		  /*;AN000;3*/
/*
/*	  ext_attrib_buff[0] = 0;				  /*;AN000;3*/
/*	  ext_attrib_buff[1] = 0;				  /*;AN000;3*/
/*	  return;						  /*;AN000;3*/
/*}								  /*;AN000;3*/

/*************************************************/
/*
/* SUBROUTINE NAME:	show_path
/*
/* FUNCTION:
/*	Display to stdout the full path from root.
/*	If we are logging, put full path there too.
/*
/***************************************************/
void show_path()
{
	char	done_path[PATHLEN+20];
	char	logfile_entry[PATHLEN+22];
	WORD	written = 0;

	if (src_drive_path[strlen(src_drive_path) - 1] != BACKSLASH)
	   sprintf(done_path,"%s\\%s",src_drive_path,dta.file_name);
	  else
	   sprintf(done_path,"%s%s",src_drive_path,dta.file_name);

	done_path[0] = 0xd;
	done_path[1] = 0xa;
				/* Display logfile path on screen */
	handle_write(STDOUT,strlen(done_path),(char far *)&done_path[0]);

	if (do_logfile)
	 {
	   build_ext(diskettes_complete+1);
	   sprintf(logfile_entry,"\15\12%s  %s",ext,&done_path[2]);
	   written = handle_write(handle_logfile,strlen(logfile_entry),(char far *)&logfile_entry[0]);
	   if (written != strlen(logfile_entry) || (rc != NOERROR) )
	    {
	     display_msg(LOGFILE_TARGET_FULL);
	   /*wait_for_keystroke();*/
	     do_logfile = FALSE;
	    }
	 }

	return;
}	/* end show_path */

/*************************************************/
/*
/* SUBROUTINE NAME:	reset_archive_bit
/*
/* FUNCTION:
/*	Sets the attribute of the source file to what
/*	it was before, except the archive bit is reset.
/*
/***************************************************/
void reset_archive_bit(path_addr)
char *path_addr;
#define ARCHIVE_MASK 223
{
	WORD	attrib;

	attrib = get_attribute(path_addr);
	attrib = attrib & (WORD)ARCHIVE_MASK;
	set_attribute(path_addr,attrib);

	return;
}	/* end reset_archive_bit */

/*************************************************/
/*
/* SUBROUTINE NAME:	write_to_target
/*
/* FUNCTION:
/*	Write a specified # of bytes to
/*	target. Handle disk full conditions
/*	and everything else.
/***************************************************/
void write_to_target(bytes_to_write)
WORD bytes_to_write;
{
	WORD	bytes_written;
	WORD	written;

	bytes_written = handle_write(handle_target,bytes_to_write,far_ptr(selector,0));
	written = bytes_written;

	if (bytes_written == bytes_to_write)		/* If we wrote it all... */
	  {
	   part_size += (DWORD)written; 		/* Update size of this part. */
	   cumul_part_size += (DWORD)written;		/* Update size of this part. */
	   data_file_tot_len += (DWORD)written; 	/* Update length of BACKUP.xxx file */
	  }
	 else
	  {
	   written = write_till_target_full(bytes_to_write,0); /* Fill up current target */
	   bytes_written += written;			/* Update # bytes written */
	   part_size += (DWORD)written; 		/* Update size of this part. */
	   cumul_part_size += (DWORD)written;		/* Update size of this part. */
	   data_file_tot_len += (DWORD)written; 	/* Update length of BACKUP.xxx file */
	   close_out_current_target();			/* Update CONTROL.xxx file, close files */
	   get_next_target();				/* Get next diskette from user *
							/* Write rest of buffer */
	   written = handle_write(handle_target,bytes_to_write-bytes_written,far_ptr(selector,bytes_written));
	   bytes_written += written;			/* Update # bytes written */
	   part_size = (DWORD)written;			/* Update size of this part. */
	   cumul_part_size += (DWORD)written;		/* Update size of this part. */
	   data_file_tot_len += (DWORD)written; 	/* Update length of BACKUP.xxx file */
	  }

	return;
}	/* end write_to_target */

/*************************************************/
/*
/* SUBROUTINE NAME:	write_till_target_full
/*
/* FUNCTION:
/*	Find out how much space is left on the disk,
/*	and use it all up.
/*
/***************************************************/
WORD write_till_target_full(bytes_to_write,begin_offset)
WORD bytes_to_write;
WORD begin_offset;
{
	WORD written;
	WORD bfree;

	bfree = (unsigned) disk_free_space();
	written = handle_write(handle_target,bfree,far_ptr(selector,begin_offset));

	return(written);
}	/* end write_till_target_full */

/*************************************************/
/*
/* SUBROUTINE NAME:	close_out_current_target
/*
/* FUNCTION:
/*	Update CONTROL.xxx file, close it, close BACKUP.xxx,
/*	make files READONLY, die if backing up to hardfile.
/*
/***************************************************/
void close_out_current_target()
{
	BYTE   last = LAST_TARGET;	/*;AN011;*/

	disk_full = TRUE;		/* Yes, the disk is full */

	if (part_size != 0)		/* If we wrote something...*/
	{
	   file_spans_target = TRUE;	/* Say "Hey, this file spans diskettes !" */
	   files_backed_up++;		/* Increment number files backed up on this target */
	}

	if (files_backed_up > 0)	/* If we backed up something */
	 update_db_entries(files_backed_up);	/* Increment Num_Entries field in directory block and NextDB field */

	update_fh_entries();		/* Update the fields in file header */

	if (!target_removable)					/*;AN011;*/
	{							/*;AN011;*/
					/* Update DH_LastDisk == LAST_DISK */
	  lseek(handle_control,BOFILE,(DWORD)(DHLENGTH - 1));	/*;AN011;*/
	  handle_write(handle_control,1,(char far *)&last);	/*;AN011;*/
	}							/*;AN011;*/

	if (control_opened)		/* If the control file is open */
	 {
	   close_file(handle_control);	/* Close it */
	   control_opened = FALSE;	/* And say it isn't open */
	 }

	if (target_opened)
	 close_file(handle_target);	/* Close files */

	target_opened  = FALSE; 	/* Indicate that target is not opened */

	if (file_spans_target)		/* If file spans to another diskette */
	 span_seq_num++;		/*  then increment the sequence number */

	mark_files_read_only(); 	/* Set ReadOnly Attribute of BACKUP/CONTROL files */

	if (logfile_on_target)		/*;AN000;7 If logfile resides on target drive */
	{				/*;AN000;7 */
	  close_file(handle_logfile);	/*;AN000;7  Then close it */
	  logfile_opened = FALSE;	/*;AN000;7  and set flag indicating that */
	}				/*;AN000;7 */

	if (!target_removable)		/* If target is a hardfile */
	{
	   display_msg(LASTNOTBACKUP);	/* Say "Last file not backed up */
	   error_exit(FDISKFULLMSG);	/*  then give error message and quit */
	}

	diskettes_complete++;		/* Increment number of diskettes complete */
	return;
}	/* end close_out_current_target */

/*************************************************/
/*
/* SUBROUTINE NAME:	mark_as_not_last_target
/*
/* FUNCTION:
/*	Sets the field in the disk header indicating
/*	this is not the last target
/*
/***************************************************/
void mark_as_not_last_target()
{
	BYTE	last = NOT_LAST_TARGET;
	DWORD	db_offset;
	DWORD	pointer;

				/* Update DH_LastDisk = NOT_LAST_TARGET */
	lseek(handle_control,BOFILE,(DWORD)(DHLENGTH - 1));
	handle_write(handle_control,1,(char far *)&last);

				/* Get first DB_NextDB */
	pointer = lseek(handle_control,BOFILE,(DWORD)(DHLENGTH+66));
	handle_read(handle_control,4,(char far *)&db_offset);

				/* Get offset of last Dir Block */
	while (db_offset != (DWORD)LAST_DB)
	 {
	   pointer = lseek(handle_control,BOFILE,(DWORD)db_offset+66);
	   handle_read(handle_control,4,(char far *)&db_offset);
	 }

				/* Change DB_NextDB field to point to EOF */
	lseek(handle_control,BOFILE,(DWORD)pointer);
	handle_write(handle_control,4,(char far *)&ctl_file_tot_len);

	lseek(handle_control,EOFILE,(DWORD)0);
	return;
}	/* end mark_as_not_last_target */

/*************************************************/
/*
/* SUBROUTINE NAME:	mark_as_last_target
/*
/* FUNCTION:
/*	Sets the field in the disk header indicating
/*	this is the last target.  Also updates the
/*	directory block to indicate the number of
/*	files that are backed up.
/*
/***************************************************/
void mark_as_last_target()
{
	BYTE   last = LAST_TARGET;

				/* Update DH_LastDisk == LAST_DISK */
	lseek(handle_control,BOFILE,(DWORD)(DHLENGTH - 1));
	handle_write(handle_control,1,(char far *)&last);

				/* Update DB_NumEntries == FILES_BACKED_UP */
	lseek(handle_control,BOFILE,(DWORD)(curr_db_begin_offset + 64));
	handle_write(handle_control,2,(char far *)&files_backed_up);

				/* Update FH Entries */
	update_fh_entries();

	return;
}	/* end mark_as_last_target */

/*************************************************/
/*
/* SUBROUTINE NAME:	update_db_entries
/*
/* FUNCTION:
/*
/*
/*
/***************************************************/
void update_db_entries(entries)
WORD	entries;
{
	lseek(handle_control,BOFILE,(DWORD)(curr_db_begin_offset+64));

					/* Update DB_num_entries */
	handle_write(handle_control,2,(char far *)&entries);

	if (!disk_full) 		/* Update DB_NextDB only if we are not at the end of a disk */
	  handle_write(handle_control,4,(char far *)&ctl_file_tot_len);

	lseek(handle_control,EOFILE,(DWORD)0);

	return;
}	/* end update_db_entries */

/*************************************************/
/*
/* SUBROUTINE NAME:	update_fh_entries
/*
/* FUNCTION:
/*	Update following fields in Current File Header:
/*
/*	FH_Flags: Indicate file successfully processed.
/*		  Indicate if this is last part or not.
/*
/*	FH_PartSize: Indicate number of bytes written
/*
/***************************************************/
void update_fh_entries()
{
	BYTE	flag;

	if (!file_spans_target)
	  flag = (BYTE)(LASTPART + SUCCESSFUL);
	 else
	  flag = (BYTE)(NOTLASTPART + SUCCESSFUL);

/*EAEA	if (ext_attrib_flg)			/*;AN000;3 If there are extended attributes */
/*EAEA	 if (span_seq_num == 1) 		/*;AN000;3  If its the first part of file */
/*EAEA	  flag += EXT_ATTR;			/*;AN000;3   set flag indicating extended attributes exist */

	if (!target_removable)				/*;AN011;*/
	 if (disk_full) 				/*;AN011;*/
	 {						/*;AN011;*/
	   flag = (BYTE)(LASTPART + NOTSUCCESSFUL);	/*;AN011;*/
	 }						/*;AN011;*/

						/* Go to FLAG field */
	lseek(handle_control,BOFILE,(DWORD)(curr_fh_begin_offset+13));
						/* Write the FLAG field to control file */
	handle_write(handle_control,1,(BYTE far *)&flag);

						/* Go to PARTSIZE field */
	lseek(handle_control,CURRPOS,(DWORD)10);
					       /* Write the PARTSIZE field to control file */
	handle_write(handle_control,4,(char far *)&part_size);

	lseek(handle_control,EOFILE,(DWORD)0);	/* Go back to end-of-file */

	return;
}	/* end update_fh_entries */

/*************************************************/
/*
/* SUBROUTINE NAME:	mark_files_read_only
/*
/* FUNCTION:
/*	Set the READ-ONLY attribute on BACKUP.xxx and CONTROL.xx
/*
/*
/***************************************************/
void mark_files_read_only()
{
	char path[25];

	build_ext(diskettes_complete + 1);

	if (target_removable)
	 {
	   sprintf(path,"%c:\\CONTROL.%s",tgt_drive_letter,ext);
	   set_attribute(path,(WORD)(ARCHIVE + READONLY));
	   sprintf(path,"%c:\\BACKUP.%s",tgt_drive_letter,ext);
	   set_attribute(path,(WORD)(ARCHIVE + READONLY));
	 }
	else
	 {
	   sprintf(path,"%c:\\BACKUP\\CONTROL.%s",tgt_drive_letter,ext);
	   set_attribute(path,(WORD)(ARCHIVE + READONLY));
	   sprintf(path,"%c:\\BACKUP\\BACKUP.%s",tgt_drive_letter,ext);
	   set_attribute(path,(WORD)(ARCHIVE + READONLY));
	 }

	if (target_removable)
	 label_target_drive();

	return;
}

/*************************************************/
/*
/* SUBROUTINE NAME:	put_disk_header
/*
/* FUNCTION:
/*
/*
/*
/***************************************************/
void put_disk_header()
{
	struct Disk_Header dh;
	int	i;

	dh.DH_Length = DHLENGTH;			/* DH_Length */

	strcpy(dh.DH_Identifier,"BACKUP  ");            /* DH_Identifier */
	dh.DH_Sequence = diskettes_complete + 1;	/* DH_Sequence */
	for (i=0; i<=128; i++) dh.DH_reserved[i] = NUL; /* DH_Reserved */
	dh.DH_LastDisk = NOT_LAST_TARGET;		/* DH_LastDisk - Assume NOT THE LAST TARGET */

	write_to_control_file((char far *)&dh,DHLENGTH);
	put_new_db();

	return;
}	/* end put_disk_header */

/*************************************************/
/*
/* SUBROUTINE NAME:	put_new_db
/*
/* FUNCTION:
/*
/*
/*
/***************************************************/
void put_new_db()
{
	struct	Dir_Block db;
	int	i;

	if (files_backed_up > 0)
	  update_db_entries(files_backed_up);	/* Update entries in previous db */

	curr_db_begin_offset = ctl_file_tot_len;   /* Save this for updating when done with current dir */

	db.DB_Length = DBLENGTH;		 /* LENGTH, IN BYTES, OF DIR BLOCK	       */
	for (i=0; i<=63; i++)
	 db.DB_Path[i]=NUL;			 /* ASCII PATH OF THIS DIRECTORY, DRIVE OMITTED*/

	strcpy(db.DB_Path,&src_drive_path[3]);
	db.DB_NumEntries = 0;			 /* NUM OF FILENAMES CURRENTLY IN LIST	       */
	db.DB_NextDB = (DWORD)LAST_DB;		 /* OFFSET OF NEXT DIRECTORY BLOCK	       */

	write_to_control_file((char far *)&db,DBLENGTH);
	new_directory = FALSE;
	files_backed_up = 0;

	return;
}	/* end put_new_db */

/*************************************************/
/*
/* SUBROUTINE NAME:	put_new_fh
/*
/* FUNCTION:
/*	We are about to backup a file. Write the
/*	file header to the control file.
/*
/***************************************************/
void put_new_fh()
{
	struct	File_Header fh;
	int	i;			/*;AN000;3*/

	if (do_add)			/* If we are adding files */
	 if (doing_first_target)	/*  and it is the last diskette from previous backup */
	  if (files_backed_up == 0)	/*   and we have not backed up ANY yet */
	   mark_as_not_last_target();	/*    then mark this diskette as NOT the last */

	if (new_directory)		/* If this file resides in a different directory */
	 put_new_db();			/*  then create new directory block. */

	curr_fh_begin_offset = ctl_file_tot_len;

	fh.FH_Length = FHLENGTH;		/* LENGTH, IN BYTES, OF FILE HEADER */
	for (i=0; i<=11; i++) fh.FH_FName[i]=NUL; /*;AN000;3*/
	strcpy(fh.FH_FName,dta.file_name);	/* ASCII FILE NAME */

	fh.FH_FLength	= (DWORD)dta.file_size; /* Length of file */
	fh.FH_FSequence = span_seq_num; 	/* Sequence #, for files that span */
	fh.FH_BeginOffset=data_file_tot_len;	/* OFFSET WHERE THIS SEGMENT BEGINS */
	fh.FH_Attribute = dta.attributes;	/* FILE ATTRIBUTE FROM DIRECTORY */
	fh.FH_FTime	= dta.write_time;	/* TIME WHEN FILE WAS LAST MODIFIED */
	fh.FH_FDate	= dta.write_date;	/* DATE WHEN FILE WAS LAST MODIFIED */
/*EAEA	fh.FH_EA_offset = 0;			/*;AN000;3 Otherwise set to zero */
	fh.FH_Flags	= LASTPART + SUCCESSFUL;

/*EAEA	if (ext_attrib_flg)				/*;AN000;3 If there are extended attributes */
/*EAEA	 if (!file_spans_target)			/*;AN000;3*/
/*EAEA	  if (span_seq_num == 1)			/*;AN000;3  If its the first part of file */
/*EAEA	   {						/*;AN000;3*/
/*EAEA	    fh.FH_Flags += EXT_ATTR;			/*;AN000;3  set flag indicating extended attributes exist */
/*EAEA	    fh.FH_EA_offset = data_file_tot_len;	/*;AN000;3 OFFSET WHERE EXTENDED ATTRIBUTES BEGIN */
/*EAEA	    fh.FH_BeginOffset += ext_attrib_len+2;	/*;AN000;3*/
/*EAEA	   }						/*;AN000;3*/

	if (file_spans_target)
	  {
	   fh.FH_PartSize  = (DWORD)(dta.file_size - cumul_part_size);	/*LENGTH OF THIS PART OF FILE */
	   file_spans_target = FALSE;
	  }
	 else
	  fh.FH_PartSize = (DWORD)dta.file_size;/* LENGTH OF THIS PART OF FILE */

	write_to_control_file((char far *)&fh,FHLENGTH);

	return;
}	/* end put_new_fh */

/*************************************************/
/*
/* SUBROUTINE NAME:	write_to_control_file
/*
/* FUNCTION:
/*	Write to the control file and update
/*	counters
/*
/***************************************************/
void write_to_control_file(address,len)
char far * address;
unsigned short len;
{
	WORD written;

	written = handle_write(handle_control,len,address);
	ctl_file_tot_len = ctl_file_tot_len + (DWORD)written;

	return;
}	/* end write_to_control_file */

/*************************************************/
/*
/* SUBROUTINE NAME:	control_break_handler
/*
/* FUNCTION:
/*	Set errorlevel and call routines to
/*	close files and terminate.
/*
/***************************************************/
void control_break_handler()
{
	return_code = RETCODE_CTL_BREAK;
	clean_up_and_exit();
	return;
}


/************************************************************/
/*
/*   SUBROUTINE NAME:	   display_it
/*
/*   SUBROUTINE FUNCTION:
/*	   Display the requested message to the standard output device.
/*
/*   INPUT:
/*	   1) (WORD) Number of the message to be displayed.
/*	   2) (WORD) Handle to be written to.
/*	   3) (WORD) Substitution Count
/*	   4) (WORD) Flag indicating user should "Strike any key..."
/*	   5) (WORD) Num indicating message class
/*
/*   OUTPUT:
/*	   The message corresponding to the requested msg number will
/*	   be written to the requested handle.	If requested, substitution
/*	   text will be inserted as required.  The Substitution List
/*	   is global and, if used, will be initialized by DISPLAY_MSG
/*	   before calling this routine.
/*
/*   NORMAL EXIT:
/*	   Message will be successfully written to requested handle.
/*
/*   ERROR EXIT:
/*	   None.  Note that theoretically an error can be returned from
/*	   SYSDISPMSG, but there is nothing that the application can do.
/*
/*   INTERNAL REFERENCES:
/*	   System Display Message service routine SYSDISPMSG
/*
/*   EXTERNAL REFERENCES:
/*	   None
/*
/************************************************************/
void	display_it(msg_number,handle,subst_count,waitflag,class)/*;AN000;6*/

int	msg_number;			/*;AN000;6*/
WORD	handle; 			/*;AN000;6*/
int	subst_count;			/*;AN000;6*/
BYTE	waitflag;			/*;AN000;6*/
BYTE	class;				/*;AN000;6 1=DOSerror, 2=PARSE,-1=Utility msg*/
{					/*;AN000;6*/
	inregs.x.ax = msg_number;	/*;AN000;6*/
	inregs.x.bx = handle;		/*;AN000;6*/
	inregs.x.cx = subst_count;	/*;AN000;6*/
	inregs.h.dh = class;		/*;AN000;6*/
	inregs.h.dl = (BYTE)waitflag;	/*;AN000;6*/
	inregs.x.si = (WORD)(char far *)&sublist;  /*;AN000;6*/

	sysdispmsg(&inregs,&outregs);	/*;AN000;6*/

	return; 			/*;AN000;6*/
}					/*;AN000;6*/
/*************************************************/
/*
/* SUBROUTINE NAME:	display_msg
/*
/* FUNCTION:
/*	Display the messages referenced by
/*	variable MSG_NUM to either STDOUT or
/*	STDERR. In some cases insert text into
/*	the body of the message.
/*
/***************************************************/

void display_msg(msg_num)
int msg_num;
{

   switch (msg_num)
   {
     case NONEFNDMSG	   : { display_it (msg_num,STDOUT,0,NOWAIT,(BYTE)UTIL_MSG); break; }	  /*;AN000;6*/

     case INSUFF_MEMORY    :							   /*;AN000;6*/
     case ERR_EXEC_FORMAT  :					      /*;AN000;d178*/
     case INV_PATH	   :							   /*;AN000;6*/
     case INV_DATE	   :							   /*;AN000;6*/
     case INV_TIME	   :							   /*;AN000;6*/
     case NO_SOURCE	   :							   /*;AN000;6*/
     case NO_TARGET	   :							   /*;AN000;6*/
     case SRC_AND_TGT_SAME :							   /*;AN000;6*/
     case BAD_DOS_VER	   :							   /*;AN000;6*/
     case INV_DRIVE	   :							   /*;AN000;6*/
     case CANT_OPEN_LOGFILE:							   /*;AN000;6*/
     case INVTARGET	   :							   /*;AN000;6*/
     case NOTLASTMSG	   :							   /*;AN000;6*/
     case CONFLICTMSG	   :							   /*;AN000;6*/
     case CRLF		   :
     case CANT_FIND_FORMAT :
     case LASTNOTBACKUP    :{							   /*;AN000;6*/
			      display_it (msg_num,STDERR,0,NOWAIT,(BYTE)UTIL_MSG); /*;AN000;6*/
			      break;						   /*;AN000;6*/
			    }							   /*;AN000;6*/

     case LOGFILE_TARGET_FULL:{
			       display_it (msg_num,STDERR,0,NOWAIT,(BYTE)UTIL_MSG);/*;AN000;6*/
			       display_it (PRESS_ANY_KEY,STDERR,0,WAIT,(BYTE)UTIL_MSG); /*;AN000;6*/
			       break;
			      }

     case LOGGING	   : {
			       sublist.value1 = (char far *)&logfile_path[0];	    /*;AN000;6*/
			       sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;     /*;AN000;6*/
			       sublist.pad_char1 = ' ';                             /*;AN000;6*/
			       sublist.max_width1 = (BYTE)strlen(logfile_path);     /*;AN000;6*/
			       sublist.min_width1 = sublist.max_width1; 	    /*;AN000;6*/
			       display_it (msg_num,STDOUT,1,NOWAIT,(BYTE)UTIL_MSG); /*;AN000;6*/
			       break;
			     }

     case CANT_FORMAT_HARDFILE :
			    {  sublist.value1 = (char far *)&tgt_drive_letter;	    /*;AN000;6*/
			       sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;     /*;AN000;6*/
			       sublist.pad_char1 = ' ';                             /*;AN000;6*/
			       sublist.max_width1 = 1;				    /*;AN000;6*/
			       sublist.min_width1 = 1;				    /*;AN000;6*/
			       display_it (msg_num,STDERR,1,NOWAIT,(BYTE)UTIL_MSG); /*;AN000;6*/
			       break;
			    }

     case BUDISKMSG	   :							    /*;AN000;6*/
     case FDISKFULLMSG	   :							    /*;AN000;6*/
			    {  sublist.value1 = (char far *)&tgt_drive_letter;	    /*;AN000;6*/
			       sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;     /*;AN000;6*/
			       sublist.pad_char1 = ' ';                             /*;AN000;6*/
			       sublist.max_width1 = 1;				    /*;AN000;6*/
			       sublist.min_width1 = 1;				    /*;AN000;6*/
			       display_it (msg_num,STDERR,1,NOWAIT,(BYTE)UTIL_MSG); /*;AN000;6*/
			       break;
			    }


     case ERASEMSG	   :							    /*;AN000;6*/
     case FERASEMSG	   :							    /*;AN000;6*/
     case LASTDISKMSG	   :							    /*;AN000;6*/
			    {  sublist.value1 = (char far *)&tgt_drive_letter;	    /*;AN000;6*/
			       sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;     /*;AN000;6*/
			       sublist.pad_char1 = ' ';                             /*;AN000;6*/
			       sublist.max_width1 = 1;				    /*;AN000;6*/
			       sublist.min_width1 = 1;				    /*;AN000;6*/
			       display_it (msg_num,STDERR,1,NOWAIT,(BYTE)UTIL_MSG); /*;AN000;6*/
			       display_it (PRESS_ANY_KEY,STDERR,0,WAIT,(BYTE)UTIL_MSG); /*;AN000;6*/
			       break;
			    }


     case INSERTSOURCE	   : {
			       sublist.value1 = (char far *)&src_drive_letter;	    /*;AN000;6*/
			       sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;     /*;AN000;6*/
			       sublist.pad_char1 = ' ';                             /*;AN000;6*/
			       sublist.max_width1 = 1;				    /*;AN000;6*/
			       sublist.min_width1 = 1;				    /*;AN000;6*/
			       display_it (msg_num,STDERR,1,NOWAIT,(BYTE)UTIL_MSG); /*;AN000;6*/
			       display_it (PRESS_ANY_KEY,STDERR,0,WAIT,(BYTE)UTIL_MSG); /*;AN000;6*/
			       break;
			     }


     case SEQUENCEMSG	   : {
			       build_ext(diskettes_complete+1);
			       if (diskettes_complete+1 < 100)
				 {
				  sublist.value1 = (char far *)&ext[1]; 	    /*;AN000;6*/
				  sublist.max_width1 = 2;			    /*;AN000;6*/
				 }
				else
				 {
				  sublist.value1 = (char far *)&ext[0]; 	    /*;AN000;6*/
				  sublist.max_width1 = 3;			    /*;AN000;6*/
				 }
			       sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;     /*;AN000;6*/
			       sublist.pad_char1 = ' ';                             /*;AN000;6*/
			       sublist.min_width1 = sublist.max_width1; 	    /*;AN000;6*/
			       display_it (msg_num,STDOUT,1,NOWAIT,(BYTE)UTIL_MSG); /*;AN000;6*/
			       break;
			     }


     case INSERTTARGET	   : {
			       build_ext(diskettes_complete+1);
			       if (diskettes_complete+1 < 100)
				 {
				  sublist.value1 = (char far *)&ext[1]; 	    /*;AN000;6*/
				  sublist.max_width1 = 2;			    /*;AN000;6*/
				 }
				else
				 {
				  sublist.value1 = (char far *)&ext[0]; 	    /*;AN000;6*/
				  sublist.max_width1 = 3;			    /*;AN000;6*/
				 }

			       sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;     /*;AN000;6*/
			       sublist.pad_char1 = ' ';                             /*;AN000;6*/
			       sublist.min_width1 = sublist.max_width1; 	    /*;AN000;6*/

			       sublist.value2 = (char far *)&tgt_drive_letter;	    /*;AN000;6*/
			       sublist.flags2 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;     /*;AN000;6*/
			       sublist.pad_char2 = ' ';                             /*;AN000;6*/
			       sublist.max_width2 = 1;				    /*;AN000;6*/
			       sublist.min_width2 = 1;				    /*;AN000;6*/

			       display_it (msg_num,STDERR,2,NOWAIT,(BYTE)UTIL_MSG); /*;AN000;6*/
			       break;
			     }

   }

 return;
}	/* end display_msg */

/*************************************************/
/*
/* SUBROUTINE NAME:	error_exit
/*
/* FUNCTION:
/*	Display appropriate error message, set
/*	the return code, and call clean_up_and_exit.
/*
/***************************************************/
void error_exit(error_type)
int	error_type;
{
	display_msg(error_type);
	return_code = RETCODE_ERROR;
	clean_up_and_exit();

	return;
}	/* end error_exit */

/*************************************************/
/*
/* SUBROUTINE NAME:	restore_default_directories
/*
/* FUNCTION:
/*	Restore the original current directory on
/*	the source drive.
/*
/***************************************************/
void restore_default_directories()
{
	char path[PATHLEN+20];

	sprintf(path,"%c:%s",src_drive_letter,src_def_dir);
	chdir(path);

	return;
}	/* end restore_default_directories */

/**************************************************/
/*
/* SUBROUTINE NAME:	clean_up_and_exit
/*
/* FUNCTION:
/*	Update BACKUP and CONTROL files.
/*	Close open files.
/*	Mark BACKUP, CONTROL file read only
/*	Restore default drive and directories
/*	Deallocate buffers
/***************************************************/
void clean_up_and_exit()
{
	char	name[15];		     /*;AN000;p2652*/

	if (source_opened)
	 {
	  close_file(handle_source);
	  source_opened = FALSE;     /* Indicate that source is not opened */
	 }

	if (target_opened)
	 {
	  close_file(handle_target);
	  target_opened  = FALSE;    /* Indicate that target is not opened */
	 }

	if (control_opened)
	 {
	   mark_as_last_target();
	   close_file(handle_control);
	   control_opened = FALSE;	/*;AN005;*/
	   mark_files_read_only();
	 }

	if (logfile_opened)
	 {
	  close_file(handle_logfile);
	  logfile_opened = FALSE;
	 }

	if (files_backed_up == 0  &&  !checking_target) 		/*;AN000;p2652*//*;AN007;*/
	 {								/*;AN005;*/
	   if (!do_add) 						/*;AN000;p2652*/
	    {								/*;AN000;p2652*/
	      if (target_removable  &&	got_first_target)		/*;AN000;p2652*/
		{							/*;AN005;*/
		  build_ext(diskettes_complete + 1);			/*;AN005;*/
		  sprintf(name,"%c:\\BACKUP.%s",tgt_drive_letter,ext);  /*;AN005;*/
		  set_attribute(name,(WORD)0);				/*;AN005;*/
		  delete(name); 					/*;AN005;*/
									/*;AN005;*/
		  sprintf(name,"%c:\\CONTROL.%s",tgt_drive_letter,ext); /*;AN005;*/
		  set_attribute(name,(WORD)0);				/*;AN005;*/
		  delete(name); 					/*;AN005;*/
		}							/*;AN005;*/

	      if (!target_removable)
	       delete_files(BACKUPDIR); 				/*;AN000;p2652*/

	    }								/*;AN000;p2652*/

	   if (!target_removable)					/*;AN005;*/
	    {								/*;AN005;*/
	     sprintf(name,"%c:\\BACKUP",tgt_drive_letter);              /*;AN000;p2652*/
	     rmdir(name);						/*;AN000;p2652*/
	    }								/*;AN005;*/
	 }								/*;AN005;*/

	if (def_drive_set)
	{
	  set_default_drive(def_drive);
	}

	if (curr_dir_set)
	{
	  restore_default_directories();
	}

	if (buffers_allocated)
	 free_seg(selector);

	terminate();

	return;
}	/* end clean_up_and_exit */



/*************************************************/
/*		DOS FAMILY API CALLS		  */
/**************************************************/

WORD handle_open(path_addr,mode)
char	*path_addr;
WORD	mode;
{
	WORD	handle;
	WORD	action;

#if defined(DEBUG)
	printf("\nDOSOPEN FILE=%s, MODE=%04Xh...",path_addr,mode);
#endif

	rc =
	  DOSOPEN
	   (
	    (char far *)path_addr,	/* Path address */
	    (unsigned far *)&handle,	/* Return area for handle */
	    (unsigned far *)&action,	/* Return area for action performed */
	    (DWORD)0,			/* File Size */
	    (WORD)0,			/* File attribute */
	    (WORD)1,			/* Flag: Only open file if it exists */
	    (WORD)mode, 		/* Mode */
	    (DWORD)0			/* Reserved */
	   );

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL, HANDLE=%04Xh",handle);
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return(handle);
}	/* end handle_open */


/*************************************************/
DWORD lseek(handle,method,distance)
WORD	handle;
BYTE	method; 	   /* 0=BOF+Offset, 1=CurrPos+Offset, 2=EOF+Offset */
DWORD	distance;
{
	DWORD	pointer;

#if defined(DEBUG)
	printf("\nDOSCHGFILEPTR HANDLE=%04Xh, METHOD=%02Xh, DIST=%08lXh...",handle,method,distance);
#endif

	rc =
	  DOSCHGFILEPTR
	   (
	    handle,
	    distance,
	    method,
	    (DWORD far *)&pointer
	   );

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL, POINTER=%08lXh",pointer);
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return((DWORD)pointer);
}	/* end lseek */

/*************************************************/
WORD handle_read(handle,length,address)
WORD handle;
WORD length;
char far *address;
{
	WORD	num_read;

#if defined(DEBUG)
	printf("\nDOSREAD HANDLE=%04Xh, BYTES=%04Xh, ADDR(off:seg)=%04X:%04X...",handle,length,address);
#endif

	rc =
	  DOSREAD
	   (
	    handle,
	    address,
	    length,
	    (unsigned far *)&num_read
	   );

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("READ %04Xh",num_read);
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return(num_read);
}	/* end handle_read */
/*************************************************/
WORD handle_write(handle,length,address)
WORD	handle;
WORD	length;
char	far *address;
{
	WORD written;

#if defined(DEBUG)
	printf("\nDOSWRITE HANDLE=%04Xh, BYTES=%04Xh, ADDR(off:seg)=%04X:%04X...",handle,length,address);
#endif

	if (length != 0)
	 rc =
	   DOSWRITE
	    (
	     handle,
	     address,
	     length,
	     (unsigned far *)&written
	    );
	else
	 {
	  written = 0;
	  rc = NOERROR;
	 }

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("WROTE %04Xh",written);
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return(written);
}	/* end handle_write */

/*************************************************/
void close_file(handle) 	     /* Close the file handle specified.	   */
WORD handle;
{
#if defined(DEBUG)
	printf("\nDOSCLOSE HANDLE=%04Xh...",handle);
#endif

	rc = DOSCLOSE(handle);

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL");
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return;
}	/* end close_file */

/*************************************************/
WORD get_attribute(path_addr)
char	*path_addr;
{
	WORD	 attribute;

#if defined(DEBUG)
	printf("\nDOSQFILEMODE %s...",path_addr);
#endif

	rc = DOSQFILEMODE((char far *)path_addr,(unsigned far *)&attribute,(DWORD)0);

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL, ATTRIB=%04Xh",attribute);
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return(attribute);
}

/*************************************************/
void set_attribute(path_addr,attribute)
char	*path_addr;
WORD	attribute;
{
#if defined(DEBUG)
	printf("\nDOSSETFILEMODE FILE=%s, ATTRIB=%04Xh...",path_addr,attribute);
#endif

	rc = DOSSETFILEMODE((char far *)path_addr,attribute,(DWORD)0);

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL");
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return;
}
/*************************************************/
WORD get_current_drive()
{
	WORD  drive;		/* 1=a */
	DWORD drivemap;

#if defined(DEBUG)
	printf("\nDOSQCURDISK DRIVE (1=A)...");
#endif

	rc = DOSQCURDISK
	 (
	  (unsigned far *)&drive,
	  (DWORD far *)&drivemap
	 );

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL, DRIVE=%04Xh",drive);
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return(drive);
}

/*************************************************/
void set_default_drive(drive)	     /* Change the current drive (1=A,2=B) */
WORD drive;
{
#if defined(DEBUG)
	printf("\nDOSSELECTDISK (1=A) TO %04Xh...",drive);
#endif

	rc = DOSSELECTDISK(drive);

	if (rc == NOERROR)
	 def_drive_set = TRUE;

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL");
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return;
}	/* end set_default_drive */

/*************************************************/
void get_current_dir(drive,path_addr)
WORD  drive;			/* 0=default, 1=a, . . . */
char *path_addr;	    /* Pointer to path buffer */
{
	WORD path_buff_len = PATHLEN+20;

#if defined(DEBUG)
	printf("\nDOSQCURDIR DRIVE (0=def) %04Xh...",drive);
#endif

	rc =
	  DOSQCURDIR
	   (
	    drive,
	    (char far *)path_addr,
	    (unsigned far *)&path_buff_len
	   );

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL, CURRENT DIR IS = \\%s",path_addr);
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return;
}	/* end get_current_dir */

/*************************************************/
void find_first(path_addr,dirhandle_addr,dta_address,attrib)
char	 *path_addr;
WORD	 *dirhandle_addr;
struct	 FileFindBuf *dta_address;
WORD	 attrib;
{
	WORD	numentries = 1;
	WORD	temprc;

	*dirhandle_addr = 0xffff;


#if defined(DEBUG)
	printf("\nDOSFINDFIRST DIRH=%04Xh, FILE=%s...",*dirhandle_addr,path_addr);
#endif

	rc =
	  DOSFINDFIRST
	   (
	    (char far *)path_addr,
	    (unsigned far *)dirhandle_addr,
	    attrib,
	    (struct FileFindBuf far *)dta_address,
	    (WORD)(sizeof(struct FileFindBuf)),
	    (unsigned far *)&numentries,
	    (DWORD)0
	   );

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL, NAME=%s, ATTR=%04Xh, SIZE=%08lXh, DIRH=%04Xh",(*dta_address).file_name,(*dta_address).attributes,(*dta_address).file_size,*dirhandle_addr);
	  else
	    printf("ERROR, DIRH=%04Xh, RC=%04Xh",*dirhandle_addr,rc);
#endif

	 if (rc != NOERROR)
	  {
	   temprc=rc;
	   findclose(*dirhandle_addr);
	   rc = temprc;
	  }

	return;
}	/* end find_first */

/*************************************************/
void find_next(dirhandle,dta_address)
WORD	dirhandle;
struct	FileFindBuf *dta_address;
{
	WORD	temprc;
	WORD	numentries = 1;

#if defined(DEBUG)
	printf("\nDOSFINDNEXT, DIRH=%04Xh...",dirhandle);
#endif

	rc =
	  DOSFINDNEXT
	   (
	    dirhandle,
	    (struct FileFindBuf far *)dta_address,
	    (WORD)(sizeof(struct FileFindBuf)+12),
	    (unsigned far *)&numentries
	   );

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL, NAME=%s, DIRH=%04Xh",(*dta_address).file_name,dirhandle);
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	 if (rc != NOERROR)
	   {
	     temprc=rc;
	     findclose(dirhandle);
	     rc = temprc;
	   }

	return;
}	/* end find_next */
/*************************************************/
void findclose(dirhandle)
WORD	dirhandle;
{

#if defined(DEBUG)
	printf("\nDOSFINDCLOSE DIRH=%04Xh...",dirhandle);
#endif

	rc = DOSFINDCLOSE(dirhandle);

	dirhandles_open = FALSE;

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL");
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return;
}	/* end findclose */
/*************************************************/
void delete(path_addr)
char *path_addr;
{
#if defined(DEBUG)
	printf("\nDOSDELETE FILE %s...",path_addr);
#endif

	rc = DOSDELETE((char far *)path_addr,(DWORD)0);

#if defined(DEBUG)
	if (rc == NOERROR)
	  printf("SUCCESSFUL");
	 else
	  printf("ERROR, RC=%04Xh",rc);
#endif

	return;
}	/* end delete */
/*************************************************/
long disk_free_space()
{
	struct	 FSAllocate fsa;

#if defined(DEBUG)
	printf("\nDOSQFSINFO (0=def) DRIVE=%04Xh...",tgt_drive_letter-'A'+1);
#endif

	rc =
	  DOSQFSINFO
	   (
	     (WORD)tgt_drive_letter - 'A' + 1,          /* Drive 0=def, 1=a... */
	     (WORD)1,					/* Level */
	     (char far *)&fsa,				/* Return info */
	     (WORD)(sizeof(struct FSAllocate))		/* Size of return info buffer */
	   );

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL, FREESPACE=%08lXh",fsa.sec_per_unit * fsa.avail_units * fsa.bytes_sec);
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return((DWORD)(fsa.sec_per_unit * fsa.avail_units * fsa.bytes_sec));
}
/*************************************************/
void replace_volume_label(label_addr)
char *label_addr;
{
#if defined(DEBUG)
      printf("\nDOSSETFSINFO (0=def) DRIVE=%04Xh, LEN=%04Xh...",tgt_drive_letter-'A'+1,label_addr[0]);
#endif

      rc = DOSSETFSINFO
       (
	 (WORD)tgt_drive_letter-'A'+1,  /* Drive 0=def, 1=a... */
	 (WORD)2,			/* Level */
	 (char far *)label_addr,	/* Buffer */
	 (WORD)LABELLEN+1		/* Buffer size */
       );

#if defined(DEBUG)
       if (rc == NOERROR)
	 printf("SUCCESSFUL");
	else
	  printf("ERROR, RC=%04Xh",rc);
#endif

	return;
}	/* end replace_volume_label */

/*************************************************/
#define TERMINATE  0x4C00
void terminate()	     /* Terminate process, return errorlevel to DOS	  */
{

	if (append_indicator == DOS_APPEND)	/*;AN000;2 If append /x was reset*/
	 {					/*;AN000;2*/
#if defined(DEBUG)
printf("\nINT2Fh,(SET APPEND) AX=%04Xh TO %04Xh...",SET_STATE,original_append_func);
#endif
	    inregs.x.ax = SET_STATE;		/*;AN000;2*/
	    inregs.x.bx = original_append_func; /*;AN000;2*/
	    int86(0x2f,&inregs,&outregs);	/*;AN000;2*/
	 }					/*;AN000;2*/

	exit(return_code);			/*;AN000;p972*/

	return;
}	/* end terminate */
/*************************************************/
WORD ioctl(devhandle)
WORD	devhandle;
{
#define ISDEVREMOVABL	0x20
#define CATEGORY	8	/*1=serial,3=display,5=printer,8=disk*/

	BYTE	data_area;

#if defined(DEBUG)
	printf("\nDOSDEVIOCTL HANDLE=%04Xh...",devhandle);
#endif

	rc =
	  DOSDEVIOCTL
	   (
	    (char far *)&data_area,	/* Data Area */
	    (char far *)&data_area,	/* Parameter list */
	    (WORD)ISDEVREMOVABL,	/* Device Function = 20 hex */
	    (WORD)CATEGORY,		/* Device Category =  8 hex */
	    (WORD)devhandle		/* Device Handle */
	   );

#if defined(DEBUG)
	 if (rc == NOERROR)
	  printf("SUCCESSFUL, DATA_AREA(0=REMOVABLE) SET TO %02Xh",data_area);
	 else
	  printf("ERROR, RC=%04Xh",rc);
#endif

	return(data_area);
}	/* end IOCTL */

/*************************************************/
void alloc_seg()
{
#if defined(DEBUG)
	printf("\nDOSALLOCSEG SIZE=%04Xh...",data_file_alloc_size);
#endif

	rc =
	  DOSALLOCSEG
	   (
	    (WORD)data_file_alloc_size, /* Bytes to allocate */
	    (unsigned far *)&selector,	/* Address of selector */
	    (WORD)0			/* Share indicator, sez DON'T SHARE */
	   );

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL, SELECTOR=%04Xh, SIZE=%04Xh",selector,data_file_alloc_size);
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return;
}

/*************************************************/
void free_seg(selector)
unsigned selector;
{
#if defined(DEBUG)
	printf("\nDOSFREESEG (%04Xh)...",selector);
#endif

	rc = DOSFREESEG(selector);	/* Address of selector */

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL");
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return;
}

/*************************************************/
void setsignal(action,signum)
WORD	action;
WORD	signum;
{
	DWORD	old_sig_handler;
	WORD	old_sig_action;

#if defined(DEBUG)
	printf("\nDOSSETSIGHANDLER ACTION=%04Xh,SIGNUM=%04Xh...",action,signum);
#endif

	rc =
	  DOSSETSIGHANDLER
	   (
	     (void far *)control_break_handler, /* Signal handler address */
	     (DWORD far *)&old_sig_handler,	/* Address of previous handler */
	     (unsigned far *)&old_sig_action,	/* Address of previous action */
	     action,				/* Indicate request type (2=hook) */
	     signum				/* Signal number */
	   );

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL");
	  else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	return;
}	/* end setsignal */

/*************************************************/
void do_dos_error(flag)
WORD	flag;
{
#if defined(DEBUG)
	printf("\nDOSERROR, FLAG=%04Xh...",flag);
#endif

	rc =  DOSERROR(flag);

#if defined(DEBUG)
	 if (rc == NOERROR)
	   printf("SUCCESSFUL");
	  else
	   printf("ERROR, RC=%04Xh",rc);
#endif

	return;
}
/*************************************************/
void get_country_info()
{
#define USACOUNTRY 1
#define DEFAULT_COUNTRY 0
#define DEFAULT_CODEPAGE 0

	struct	ctry_info_blk buff;
	struct	countrycode ctrystuff;			/* Added for CPDOS 1.1 */
	WORD	data_len;

	ctrystuff.country = (WORD)DEFAULT_COUNTRY;
	ctrystuff.codepage= (WORD)DEFAULT_CODEPAGE;

#if defined(DEBUG)
	printf("\nDOSGETCTRYINFO COUNTRY=%04Xh...",ctrystuff.country);
#endif

	rc =
	  DOSGETCTRYINFO
	   (
	    (unsigned)sizeof(struct ctry_info_blk),	/* Length of return area */
	    (struct countrycode far *)&ctrystuff,	/* Country Code */
	    (char far *)&buff,				/* Return area */
	    (unsigned far *)&data_len			/* Len of returned area */
	   );

#if defined(DEBUG)
	 if (rc == NOERROR)
	    printf("SUCCESSFUL");
	   else
	    printf("ERROR, RC=%04Xh",rc);
#endif

	if (rc == NOERROR)
	 {
	  ctry_date_fmt = buff.date_format;
	  ctry_time_fmt = buff.time_format;
	  ctry_date_sep = buff.date_separator;
	  ctry_time_sep = buff.time_separator;
#if defined(DEBUG)
	  printf("\nDATE SEPERATOR=%c",ctry_date_sep);
	  printf("\nTIME SEPERATOR=%c",ctry_time_sep);
	  printf("\nDATE FORMAT=%u",ctry_date_fmt);
	  printf("\nTIME FORMAT=%u",ctry_time_fmt);
#endif
	 }


	return;
}	/* end get_country_info */

/*************************************************/
void datetime() 		/* Put date and time in logfile */
{
	struct	DateTime buff;
	char	date[12];
	char	time[12];
	char	datetimestring[25];
	WORD	written = 0;

#if defined(DEBUG)
	printf("\nDOSGETDATETIME...");
#endif

	rc = DOSGETDATETIME((struct DateTime far *)&buff);

#if defined(DEBUG)
	 if (rc == NOERROR)
	    printf("SUCCESSFUL");
	   else
	    printf("ERROR, RC=%04Xh",rc);
#endif

					/* Build time string */
	sprintf(time,"%u%c%02u%c%02u",buff.hour,ctry_time_sep,buff.minutes,ctry_time_sep,buff.seconds);

					/* Build date string */
	switch (ctry_date_fmt)
	 {
	   case USA:
	     sprintf(date,"%u%c%02u%c%04u",buff.month,ctry_date_sep,buff.day,ctry_date_sep,buff.year);
	     break;

	   case EUR:
	     sprintf(date,"%u%c%02u%c%04u",buff.day,ctry_date_sep,buff.month,ctry_date_sep,buff.year);
	     break;

	   case JAP:
	     sprintf(date,"%04u%c%02u%c%02u",buff.year,ctry_date_sep,buff.month,ctry_date_sep,buff.day);
	     break;

	   default:
	     break;
	 }

	datetimestring[0] = 0x0d;
	datetimestring[1] = 0x0a;
	sprintf(datetimestring+2,"%s  %s",date,time);

	written = handle_write(handle_logfile,strlen(datetimestring),(char far *)&datetimestring[0]);
	if (written != strlen(datetimestring) || (rc != NOERROR) )
	  {
	   display_msg(LOGFILE_TARGET_FULL);
	/* wait_for_keystroke(); */
	   do_logfile = FALSE;
	  }

	return;
}	/* end datetime */












/*************************************************/
/*void get_extended_attributes(handle)					/*;AN000;3*/
/*WORD handle;								/*;AN000;3*/
/*{									/*;AN000;3*/
/*#if defined(DEBUG)
/*	  printf("\nGET EXTENDED ATTRIBUTE LENGTH...");
/*#endif
/*	  ext_attrib_flg = TRUE;     /*Assume ext attrib exist*/	/*;AN000;3*/
/*
/*					  /* GET EXTENDED ATTRIBUTE LENGTH */
/*	  inregs.x.ax = 0x5702; 					/*;AN000;3*/
/*	  inregs.x.bx = handle; 					/*;AN000;3*/
/*	  inregs.x.cx = 0;						/*;AN000;3*/
/*	  inregs.x.si = 0xffff; 					/*;AN000;3*/
/*	  intdos(&inregs,&outregs);					/*;AN000;3*/
/*
/*#if defined(DEBUG)
/*	  if (outregs.x.cflag & CARRY)
/*	      printf("ERROR, RC=%04Xh",outregs.x.ax);
/*	     else
/*	      printf("SUCCESSFUL, LEN=%04Xh",outregs.x.cx);
/*#endif
/*
/*	  if (!(outregs.x.cflag & CARRY))				/*;AN000;3*/
/*	    ext_attrib_len = outregs.x.cx;				/*;AN000;3*/
/*	   else 							/*;AN000;3*/
/*	    ext_attrib_flg = FALSE;					/*;AN000;3 Set flag indicating no extended attributes*/
/*
/*
/*#if defined(DEBUG)
/*	  printf("\nGET EXTENDED ATTRIBUTES...");
/*#endif
/*
/*					  /* GET EXTENDED ATTRIBUTES */
/*	  if (ext_attrib_flg)
/*	   {								/*;AN000;3*/
/*	     inregs.x.ax = 0x5702;					/*;AN000;3*/
/*	     inregs.x.bx = handle;					/*;AN000;3*/
/*	     inregs.x.cx = outregs.x.cx;				/*;AN000;3*/
/*	     inregs.x.di = (unsigned)&ext_attrib_buff[0];		/*;AN000;3*/
/*	     inregs.x.si = 0xffff;					/*;AN000;3*/
/*	     intdos(&inregs,&outregs);					/*;AN000;3*/
/*
/*	     if (outregs.x.cflag & CARRY)				/*;AN000;3*/
/*	       ext_attrib_flg = FALSE;					/*;AN000;3*/
/*
/*#if defined(DEBUG)
/*	  if (outregs.x.cflag & CARRY)
/*	      printf("ERROR, RC=%04Xh",outregs.x.ax);
/*	     else
/*	      printf("SUCCESSFUL");
/*#endif
/*	   }
/*
/*	  return;							/*;AN000;3*/
/*}	  /* end get_extended_attributes */				/*;AN000;3*/
/**************************************************/
#define EXTENDEDOPEN	0x6c00					      /*;AN000;3*/

WORD extended_open(flag,attr,path_addr,mode)			      /*;AN000;3*/
WORD	flag;							      /*;AN000;3*/
WORD	attr;							      /*;AN000;3*/
char	far *path_addr; 					      /*;AN000;3*/
WORD	mode;							      /*;AN000;3*/
{								      /*;AN000;3*/
	union REGS inreg,outreg;				      /*;AN000;3*/

	ea_parmlist.ext_attr_addr = (DWORD)(char far *)&ext_attrib_buff[0];/*;AN000;3*/
	ea_parmlist.num_additional = 0; 			      /*;AN000;3*/

#if defined(DEBUG)
	if (flag == CREATE_IT) printf("\nEXTENDED OPEN - CREATE, FILE %s...",path_addr);
	 else printf("\nEXTENDED OPEN - OPEN, FILE %s...",path_addr);
#endif

	rc = NOERROR;						      /*;AN000;3*/
	inreg.x.ax = EXTENDEDOPEN;				      /*;AN000;3*/
	inreg.x.bx = mode + NO_INHERIT; 			      /*;AN000;3*/
	inreg.x.cx = attr;					      /*;AN000;3*/
	inreg.x.dx = flag + NO_CP_CHECK;			      /*;AN000;3*/
	inreg.x.si = (WORD)path_addr;				      /*;AN000;3*/

	inreg.x.di = (WORD)&ea_parmlist;			      /*;AN000;3*/

	intdos(&inreg,&outreg); 				      /*;AN000;3*/
	if (outreg.x.cflag & CARRY)	/* If there was an error      /*;AN000;3*/
	 rc = outreg.x.ax;		/*  then set return code      /*;AN000;3*/

#if defined(DEBUG)
	if (outreg.x.cflag & CARRY)
	    printf("ERROR, RC=%04Xh",outreg.x.ax);
	   else
	    printf("SUCCESSFUL, HANDLE=%04Xh",outreg.x.ax);
#endif

	return(outreg.x.ax);					      /*;AN000;3*/
}	/* end extended_open */ 				      /*;AN000;3*/
