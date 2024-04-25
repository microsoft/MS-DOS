
/*-------------------------------
/* SOURCE FILE NAME: restpars.c
/*-------------------------------
/*  0 */
#include "rt.h"
#include "rt1.h"
#include "rt2.h"
#include "restpars.h"                                                 /*;AN000;4*/
#include "direct.h"
#include "string.h"
#include "ctype.h"
#include "dos.h"                                                      /*;AN000;2*/
#include "comsub.h"             /* common subroutine def'n */
#include "doscalls.h"
#include "error.h"

/*=============================*/
extern	BYTE	srcd;						      /*;AN000;4*/
extern	BYTE	destd;						      /*;AN000;4*/
extern	BYTE	inpath	[MAXPATH];				      /*;AN000;*/
extern	BYTE	infname [MAXFNAME];				      /*;AN000;*/
extern	BYTE	infext	[MAXFEXT];				      /*;AN000;*/
extern	BYTE	infspec [MAXFSPEC];				      /*;AN000;*/
/*=============================*/

extern	BYTE destddir[MAXPATH+3];
extern	BYTE srcddir[MAXPATH+3];
extern	BYTE rtswitch;
extern	BYTE control_flag;
extern	BYTE control_flag2;
extern	BYTE filename[12];
extern	unsigned control_file_handle;				      /* !wrw */
extern	struct	subst_list sublist;	   /*;AN000;6Message substitution list */

struct	p_parms 	parms;		   /*;AN000;4 Parser data structure */
struct	p_parmsx	parmsx; 	   /*;AN000;4 Parser data structure */
struct	p_pos_blk	pos1;		   /*;AN000;4 Parser data structure */
struct	p_pos_blk	pos2;		   /*;AN000;4 Parser data structure */
struct	p_sw_blk	sw1;		   /*;AN000;4 /S /P /M /N  data structure */
struct	p_sw_blk	sw2;		   /*;AN000;4 /E: /L:  parser data structure */
struct	p_sw_blk	sw3;		   /*;AN000;4 /B: /A:  parser data structure */
struct	p_result_blk	pos_buff;	   /*;AN000;4 Parser data structure */
struct	switchbuff	sw_buff;	   /*;AN000;4 Parser data structure */
struct	timebuff	time_buff;	   /*;AN000;4 Parser data structure */
struct	datebuff	date_buff;	   /*;AN000;4 Parser data structure */
DWORD	noval;				   /*;AN000;4 Value list for PARSER */
int	parse_count = 1;		   /*;AN000;4*//*;AC002;*/
char	curr_parm[128]; 		   /*;AN004; Current parameter being parsed*/
extern	struct timedate td;

/*************************************************/
/*
/* SUBROUTINE NAME:	parse_command_line
/*
/* FUNCTION:
/*
/*	Parse the RESTORE command line
/*
/**************************************************/
void	parse_command_line(argc,argv)				      /*;AN000;4 */
int	argc;							      /*;AN000;4 */
char	*argv[];						      /*;AN000;4 */
{								      /*;AN000;4 */
#define EOL  -1 						      /*;AN000;4 */
	union REGS inregs, outregs;				      /*;AN000;4 */
	char	cmd_line[128];					      /*;AN000;4 */
	char	not_finished = TTRUE;				      /*;AN000;4 */
	int	x;						      /*;AN000;4 */


		/* Copy command line parameters to local area */
	cmd_line[0] = NUL;					      /*;AN000;4*/
	for (x=1; x<=argc; x++) 				      /*;AN000;4*/
	 {							      /*;AN000;4*/
	  strcat(cmd_line,argv[x]);				      /*;AN000;4*/
	  if (x!=argc) strcat(cmd_line," ");                          /*;AN000;4*/
	 }							      /*;AN000;4*/

	strcat(cmd_line,"\r");             /* Add CR, LF */           /*;AN004;*/

	if (argc-1 < 1) 					      /*;AN000;4*/
	 {							      /*;AC000;4*/
	  display_it(NO_SOURCE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	  usererror(INVALIDPARM);				      /*;AC000;4*/
	 }							      /*;AC000;4*/

	if (argc-1 < 2) 					      /*;AN000;4*/
	 {							      /*;AC000;4*/
	  display_it(NO_TARGET,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	  usererror(INVALIDPARM);				      /*;AC000;4*/
	 }							      /*;AC000;4*/

		/* Check for same source and target drive */
	if (com_toupper(*argv[1]) == com_toupper(*argv[2])	      /*;AN000;4*/
	    && (BYTE)*(argv[1]+1) == ':'                              /*;AN000;4*/
	    && (BYTE)*(argv[1]+2) == NUL			      /*;AN000;4*/
	    && (BYTE)*(argv[2]+1) == ':'                              /*;AN000;4*/
	   )							      /*;AN000;4*/
	 {							      /*;AC000;4*/
	  display_it(SOURCE_TARGET_SAME,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	  usererror(INVALIDPARM);				      /*;AC000;4*/
	 }							      /*;AC000;4*/

		/* Initialize parser data structures */
	parse_init();						      /*;AN000;4*/

	inregs.x.si = (WORD)&cmd_line[0];  /*DS:SI*/		      /*;AN000;4 make DS:SI point to source */
	inregs.x.cx = 0;					      /*;AN000;4*/

		/*********************/
		/* PARSE LOOP !!!!!! */
		/*********************/
	while (not_finished)					      /*;AN000;4 For all strings in command line */
	 {							      /*;AN000;4 */
	  inregs.x.dx = 0;					      /*;AN000;4 RESERVED */
	  inregs.x.di = (WORD)&parms;	/*ES:DI*/		      /*;AN000;4 address of parm list */
	  parse(&inregs,&outregs);				      /*;AN000;4 Call DOS PARSE service routines*/

	  x=0;			/* Save the parsed parameter */       /*;AN004;*/
	  for (inregs.x.si; inregs.x.si<outregs.x.si; inregs.x.si++)  /*;AN004;*/
	   {							      /*;AN004;*/
	     curr_parm[x] = *(char *)inregs.x.si;		      /*;AN004;*/
	     x++;						      /*;AN004;*/
	   }							      /*;AN004;*/

	  curr_parm[x] = NUL;					      /*;AN004;*/

	  inregs = outregs;		/* Reset registers */	      /*;AN000;4 Reset registers*/

					/* Check for PARSE ERROR*/
	  if (outregs.x.ax != (WORD)NOERROR)			      /*;AN000;4*/
	   {							      /*;AN000;4*/
	     if (outregs.x.ax==(WORD)EOL)   /* Was it End of line? */ /*;AN000;4*/
	       not_finished = FFALSE;				      /*;AN000;4*/
	      else
	       {			     /* It was an error */    /*;AN000;4*/
		 not_finished = FFALSE; 			      /*;AN000;4*/
		 parse_error(outregs.x.ax,(BYTE)PARSEERR);	      /*;AN000;4*//*;AC002;*/
	      } 						      /*;AN000;4*/
	   }							      /*;AN000;4*/

	  if (not_finished)	/* Parse was successful !*/	      /*;AN000;4*/
	   {							      /*;AN000;4*/
	     if ( outregs.x.dx == (WORD)&time_buff ||		      /*;AN000;4*/
		  outregs.x.dx == (WORD)&date_buff ||		      /*;AN000;4*/
		  outregs.x.dx == (WORD)&sw_buff		      /*;AN000;4*/
		)						      /*;AN000;4*/
	       process_switch(outregs.x.dx,argv[parse_count]);	      /*;AN000;4*//*;AC002;*/
	   }							      /*;AN000;4*/

	  parse_count++;					      /*;AN000;4*//*;AC002;*/
	 }  /* End WHILE Parse loop */				      /*;AN000;4*/

		/*  Check source and target filespec */
	if (strlen(argv[2]) >= 5)				      /*;AN000;p2591*/
	 check_for_device_names(argv);				      /*;AN000;p2591*/

	check_source_drive(argc,argv);				      /*;AN000;4*/
	check_target_filespec(argc,argv);			      /*;AN000;4*/

	return; 						      /*;AN000;4*/
}	/* end parser */					      /*;AN000;4*/

/*************************************************/
/*
/* SUBROUTINE NAME:	parse_error
/*
/* FUNCTION:
/*
/*	There was a parse error. Display message and die
/*
/**************************************************/
void	parse_error(msg_num,class)				      /*;AN000;4*//*;AC002;*/
WORD	msg_num;						      /*;AN000;4*/
BYTE	class;							      /*;AN000;4*/
{								      /*;AN000;4*/
      sublist.value1 = &curr_parm[0];				      /*;AN002;*/
      sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;		      /*;AN002;*/
      sublist.one = 0;						      /*;AN002;*/
      sublist.max_width1 = (BYTE)strlen(curr_parm);		      /*;AN002;*/
      sublist.min_width1 = sublist.max_width1;			      /*;AN002;*/


      if (msg_num == NO_SOURCE	||  msg_num == NO_TARGET)	      /*;AN000;6*/
       display_it(msg_num,STND_ERR_DEV,0,NO_RESPTYPE,class);	      /*;AN000;6*/
      else							      /*;AN000;6*/
       display_it(msg_num,STND_ERR_DEV,1,NO_RESPTYPE,class);	      /*;AN000;6*/


      usererror(INVALIDPARM);					      /*;AN000;4*//*;AC002;*/
      return;							      /*;AN000;4*/
}								      /*;AN000;4*/

/*************************************************/
/*
/* SUBROUTINE NAME:	check_date
/*
/* FUNCTION:
/*
/*	A date parameter was entered. Validate it
/*
/**************************************************/
void	check_date(year,month,day)				      /*;AN000;4*//*;AC002;*/
WORD	year;							      /*;AN000;4*/
BYTE	month;							      /*;AN000;4*/
BYTE	day;							      /*;AN000;4*/
{								      /*;AN000;4*/
	if (year > 2099 || year < 1980) 			      /*;AC000;4*/
	  parse_error(INV_DATE,(BYTE)UTILMSG);			      /*;AC000;4*//*;AC002;*/

	if (month > 12 || month < 1)				      /*;AC000;4*/
	  parse_error(INV_DATE,(BYTE)UTILMSG);			      /*;AC000;4*//*;AC002;*/

	if (day > 31 || month < 1)				      /*;AC000;4*/
	  parse_error(INV_DATE,(BYTE)UTILMSG);			      /*;AC000;4*//*;AC002;*/

		/* Verify day not greater then 30 if Apr,Jun,Sep,Nov */
	if ((day>30) && (month==4 || month==6 || month==9 || month==11)) /*;AC000;4*/
	  parse_error(INV_DATE,(BYTE)UTILMSG);			      /*;AC000;4*//*;AC002;*/

	if (month == 2) 		/* Deal with February */      /*;AC000;4*/
	 {							      /*;AC000;4*/
	   if (day >  29)		/*  if Feb 30 or above */     /*;AC000;4*/
	    parse_error(INV_DATE,(BYTE)UTILMSG);		      /*;AC000;4*//*;AC002;*/

	   if ((year % 4) != 0) 	/* If not a leap year */      /*;AC000;4*/
	     if (day >	28)		/*  if Feb 29 or above */     /*;AC000;4*/
	      parse_error(INV_DATE,(BYTE)UTILMSG);		      /*;AC000;4*//*;AC002;*/
	 }							      /*;AC000;4*/

	return; 						      /*;AN000;4*/
}								      /*;AN000;4*/
/*************************************************/
/*
/* SUBROUTINE NAME:	check_time
/*
/* FUNCTION:
/*
/*	A time parameter was entered. Validate it
/*
/**************************************************/
void	check_time(hours,minutes,seconds,hundreds)		      /*;AN000;4*//*;AC002;*/
BYTE	hours;							      /*;AN000;4*/
BYTE	minutes;						      /*;AN000;4*/
BYTE	seconds;						      /*;AN000;4*/
BYTE	hundreds;						      /*;AN000;4*/
{								      /*;AN000;4*/

	if (hours > 23 || hours < 0)				      /*;AC000;4*/
	 parse_error(INV_TIME,(BYTE)UTILMSG);			      /*;AC000;4*//*;AC002;*/

	if (minutes >= 60 || minutes < 0)			      /*;AC000;4*/
	  parse_error(INV_TIME,(BYTE)UTILMSG);			      /*;AC000;4*//*;AC002;*/

	if (seconds >= 60 || seconds < 0)			      /*;AC000;4*/
	   parse_error(INV_TIME,(BYTE)UTILMSG); 		      /*;AC000;4*//*;AC002;*/

	return; 						      /*;AN000;4*/
}								      /*;AN000;4*/

/*************************************************/
/*
/* SUBROUTINE NAME:	parse_init
/*
/* FUNCTION:
/*
/*	Initialize the parser data structures
/*
/**************************************************/
#define SSTRING 0x2000			/*;AN000;4*/
#define FILESPEC 0x0200 		/*;AN000;4 */
#define CAP_FILETABLE 0x0001		/*;AN000;4 */
#define DRIVELETTER 0x100;		/*;AN000;4 */
#define DATESTRING 0x1000		/*;AN000;4 */
#define TIMESTRING 0x0800		/*;AN000;4 */

void	parse_init()					/*;AN000;4 */

{		/* Initialize PARMS data structure */	/*;AN000;4 */
	parms.parmsx_ptr = (WORD)&parmsx;		/*;AN000;4 */
	parms.p_num_extra = 1;				/*;AN000;4 */
	parms.p_len_extra_delim = 1;			/*;AN000;4 */
	parms.p_extra_delim[0] = ';';                   /*;AN000;4 */
	parms.p_extra_delim[1] = NUL;			/*;AN000;4 */

		/* Initialize PARMSX data structure */
	parmsx.p_minpos= 2;				/*;AN000;4 */
	parmsx.p_maxpos= 2;				/*;AN000;4 */
	parmsx.pos1_ptr= (WORD)&pos1;			/*;AN000;4 */
	parmsx.pos2_ptr= (WORD)&pos2;			/*;AN000;4 */
	parmsx.num_sw  = 3;				/*;AN000;4 */
	parmsx.sw1_ptr = (WORD)&sw1;			/*;AN000;4 */
	parmsx.sw2_ptr = (WORD)&sw2;			/*;AN000;4 */
	parmsx.sw3_ptr = (WORD)&sw3;			/*;AN000;4 */
	parmsx.num_keywords = 0;			/*;AN000;4 */

		/* Initialize POS1 (Source Drive) data structure */
	pos1.match_flag = FILESPEC;			/*;AN000;4 */
	pos1.function_flag = 0; 			/*;AN000;4 */
	pos1.result_buf = (WORD)&pos_buff;		/*;AN000;4 */
	pos1.value_list = (WORD)&noval; 		/*;AN000;4 */
	pos1.nid = 0;					/*;AN000;4 */

		/* Initialize POS2 (Target FILESPEC) data structure */
	pos2.match_flag = SSTRING;			/*;AN000;4 */
	pos2.function_flag = 0; 			/*;AN000;4 */
	pos2.result_buf = (WORD)&pos_buff;		/*;AN000;4 */
	pos2.value_list = (WORD)&noval; 		/*;AN000;4 */
	pos2.nid = 0;					/*;AN000;4 */

		/* Initialize SW1 data structure */
	sw1.p_match_flag = DATESTRING;			/*;AN000;4 */
	sw1.p_function_flag = 0;			/*;AN000;4 */
	sw1.p_result_buf = (WORD)&date_buff;		/*;AN000;4 */
	sw1.p_value_list = (WORD)&noval;		/*;AN000;4 */
	sw1.p_nid = 2;					/*;AN000;4 */
	strcpy(sw1.switch1,"/B");                       /*;AN000;4 */
	strcpy(sw1.switch2,"/A");                       /*;AN000;4 */

		/* Initialize SW2 data structure */
	sw2.p_match_flag = TIMESTRING;			/*;AN000;4 */
	sw2.p_function_flag = 0;			/*;AN000;4 */
	sw2.p_result_buf = (WORD)&time_buff;		/*;AN000;4 */
	sw2.p_value_list = (WORD)&noval;		/*;AN000;4 */
	sw2.p_nid = 2;					/*;AN000;4 */
	strcpy(sw2.switch1,"/E");                       /*;AN000;4 */
	strcpy(sw2.switch2,"/L");                       /*;AN000;4 */


		/* Initialize SW3 data structure */
	sw3.p_match_flag = 0;				/*;AN000;4 */
	sw3.p_function_flag = 0;			/*;AN000;4 */
	sw3.p_result_buf = (WORD)&sw_buff;		/*;AN000;4 */
	sw3.p_value_list = (WORD)&noval;		/*;AN000;4 */
	sw3.p_nid = 4;					/*;AN000;4 */
	strcpy(sw3.switch1,"/S");                       /*;AN000;4 */
	strcpy(sw3.switch2,"/P");                       /*;AN000;4 */
	strcpy(sw3.switch3,"/M");                       /*;AN000;4 */
	strcpy(sw3.switch4,"/N");                       /*;AN000;4 */

   /*********************************************/
   /* Also initialize all time and date values	*/
   /*********************************************/
	td.earlier_hour = 0;
	td.earlier_minute = 0;
	td.earlier_second = 0;
	td.later_hour = 0;
	td.later_minute = 0;
	td.later_second = 0;
	td.before_year = 0;
	td.before_month = 0;
	td.before_day = 0;
	td.after_year = 0;
	td.after_month = 0;
	td.after_day = 0;

   /**************************************************/
   /* Also initialize the message substitution list  */
   /**************************************************/
	sublist.sl_size1= SUBLIST_SIZE; 	/*;AN000;6*/
	sublist.sl_size2= SUBLIST_SIZE; 	/*;AN000;6*/
	sublist.one = 1;			/*;AN000;6*/
	sublist.two = 2;			/*;AN000;6*/
	sublist.zero1 = 0;			/*;AN000;6*/
	sublist.zero2 = 0;			/*;AN000;6*/
	sublist.pad_char1 = ' ';                /*;AN000;6*/
	sublist.pad_char2 = ' ';                /*;AN000;6*/

	return; 				/*;AN000;4 */
}						/*;AN000;4 */


/*************************************************/
/*
/* SUBROUTINE NAME:	check_for_device_names
/*
/* FUNCTION:
/*
/*	Make sure user not trying to restore a reserved device name
/*
/**************************************************/
void check_for_device_names(argv)				      /*;AN000;p2591*/
char	*argv[];						      /*;AN000;p2591*/
{								      /*;AN000;p2591*/
	union REGS qregs;					      /*;AN000;p2591*/
	char target[128];					      /*;AN000;p2591*/
	char *t;						      /*;AN000;p2591*/

#define CAPITALIZE_STRING 0x6521				      /*;AN000;p2591*/

	qregs.x.ax = CAPITALIZE_STRING; 			      /*;AN000;p2591*/
	qregs.x.dx = (WORD)argv[2];				      /*;AN000;p2591*/
	strcpy(target,argv[2]); 				      /*;AN000;p2591*/
	qregs.x.cx = strlen(target);				      /*;AN000;p2591*/
	intdos(&qregs,&qregs);					      /*;AN000;p2591*/
	strcpy(target,argv[2]); 				      /*;AN000;p2591*/

	for (t=&target[0]; *t!=NUL; t++)
	 if							      /*;AN000;p2591*/
	  ( strcmp(t,"LPT1")==0   ||                                  /*;AN000;p2591*/
	    strcmp(t,"LPT2")==0   ||                                  /*;AN000;p2591*/
	    strcmp(t,"PRN")==0    ||                                  /*;AN000;p2591*/
	    strcmp(t,"CON")==0    ||                                  /*;AN000;p2591*/
	    strcmp(t,"NUL")==0    ||                                  /*;AN000;p2591*/
	    strcmp(t,"AUX")==0    ||                                  /*;AN000;p2591*/
	    strcmp(t,"LPT1:")==0  ||                                  /*;AN000;p2591*/
	    strcmp(t,"LPT2:")==0  ||                                  /*;AN000;p2591*/
	    strcmp(t,"PRN:")==0   ||                                  /*;AN000;p2591*/
	    strcmp(t,"CON:")==0   ||                                  /*;AN000;p2591*/
	    strcmp(t,"NUL:")==0   ||                                  /*;AN000;p2591*/
	    strcmp(t,"AUX:")==0                                       /*;AN000;p2591*/
	  )							      /*;AN000;p2591*/
	 {							      /*;AN000;p2591*/
	   sublist.value1 = (char far *)t;			      /*;AN000;p2591*/
	   sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;	      /*;AN000;p2591*/
	   sublist.one = 0;					      /*;AN000;p2591*/
	   sublist.max_width1 = (BYTE)strlen(t);		      /*;AN000;p2591*/
	   sublist.min_width1 = sublist.max_width1;		      /*;AN000;p2591*/

	   display_it(INVPARM,STND_ERR_DEV,1,NO_RESPTYPE,(BYTE)PARSEERROR);/*;AN000;p2591*/
	   usererror(INVALIDPARM);				      /*;AN000;p2591*/
	 }							      /*;AN000;p2591*/


	return; 						      /*;AN000;p2591*/
}								      /*;AN000;p2591*/

/*************************************************/
/*
/* SUBROUTINE NAME:	check_source_drive
/*
/* FUNCTION:
/*
/*	Verify drive letter and start building srcddir
/*
/**************************************************/
void check_source_drive(argc,argv)		/*;AN000;4*/
int	argc;					/*;AN000;4*/
char	*argv[];				/*;AN000;4*/
{						/*;AN000;4*/
	WORD  retcode;				/*;AC000;*/
	WORD  device_handle;
	WORD  action;
	BYTE  parm;
	BYTE  media_type;
	WORD  dnumwant = 1;
	BYTE  temp_array1[4];
	BYTE  temp_array2[4];
	union REGS qregs;					      /*;AN000;8*/

	*argv[1]=(BYTE)com_toupper(*argv[1]);			      /*;AN000;4*/

	if (							      /*;AN000;4*/
	     *argv[1] < 'A'    ||                                     /*;AN000;4*/
	     *argv[1] > 'Z'    ||                                     /*;AN000;4*/
	     *(argv[1]+1)!=':' ||                                     /*;AN000;4*/
	     *(argv[1]+2)!=NUL					      /*;AN000;4*/
	   )							      /*;AN000;4*/
	  {							      /*;AN000;4*/
	   display_it(INVALID_DRIVE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	   usererror(INVALIDDRIVE);				      /*;AN000;4*/
	  }							      /*;AN000;4*/

	srcd = (BYTE)*argv[1];					      /*;AN000;4*/
	srcddir[0] = srcd;					      /*;AN000;4*/
	srcddir[1] = ':';                                             /*;AN000;4*/
	srcddir[2] = NUL;					      /*;AN000;4*/

   /***********************************************************************/
   /* dosopen to find out whether the src drive exist			  */
   /* and dosdevioctl to find out whether it is a removable drive	  */
   /***********************************************************************/
       retcode =						      /*;AC000;4*/
	 DOSOPEN						      /*;AC000;4*/
	  ( (char far *)&srcddir[0],				      /*;AC000;4*/
	    (unsigned far *)&device_handle,			      /*;AC000;4*/
	    (unsigned far *)&action,				      /*;AC000;4*/
	    (DWORD)0,			/*file size*/		      /*;AC000;4*/
	    0,				/*file attribute*/	      /*;AC000;4*/
	    0x01,			/*if file exist, open it*/    /*;AC000;4*/
					/*if file not exist, fail it*//*;AC000;4*/
	    0x80c2,			/*deny write, read only*/     /*;AC000;4*/
	    (DWORD)0			/*reserved*/		      /*;AC000;4*/
	  );							      /*;AC000;4*/

       if (retcode != NOERROR)					      /*;AC000;4*/
	{							      /*;AC000;4*/
	  display_it(INVALID_DRIVE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	  usererror(INVALIDDRIVE);				      /*;AC000;4*/
	}							      /*;AC000;4*/

     /************************************/			      /*;AC000;4*/
     /* See if source drive is removable */			      /*;AC000;4*/
     /************************************/			      /*;AC000;4*/
      retcode = 						      /*;AC000;4*/
	DOSDEVIOCTL						      /*;AC000;4*/
	 ( (char far *)&media_type,				      /*;AC000;4*/
	   (char far *)&parm,					      /*;AC000;4*/
	   0x20,						      /*;AC000;4*/
	   0x08,						      /*;AC000;4*/
	   device_handle					      /*;AC000;4*/
	 );							      /*;AC000;4*/

      if (retcode != NOERROR)					      /*;AC000;4*/
       { display_it(INVALID_DRIVE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	 usererror(INVALIDDRIVE);				      /*;AC000;4*/
       }							      /*;AC000;4*/

#define REMOVABLE 0						      /*;AC000;4*/
   if (media_type != REMOVABLE) 				      /*;AC000;4*/
      set_reset_test_flag(&control_flag2,SRC_HDISK,SET);	      /*;AC000;4*/

    else	/* Source disk is removable */			      /*;AC000;4*/
     {								      /*;AC000;4*/
	temp_array1[0] = (BYTE)((dnumwant / 10) + '0');               /*;AC000;4*/
	temp_array1[1] = (BYTE)((dnumwant % 10) + '0');               /*;AC000;4*/
	temp_array1[2] = NUL;					      /*;AC000;4*/
	temp_array2[0] = srcd;					      /*;AC000;4*/
	temp_array2[1] = NUL;					      /*;AC000;4*/

	sublist.value1 = (char far *)temp_array1;		      /*;AN000;6*/
	sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;	      /*;AN000;6*/
	sublist.max_width1 = (BYTE)strlen(temp_array1); 	      /*;AN000;6*/
	sublist.min_width1 = sublist.max_width1;		      /*;AN000;6*/

	sublist.value2 = (char far *)temp_array2;		      /*;AN000;6*/
	sublist.flags2 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;	      /*;AN000;6*/
	sublist.max_width2 = (BYTE)strlen(temp_array2); 	      /*;AN000;6*/
	sublist.min_width2 = sublist.max_width2;		      /*;AN000;6*/

	display_it(INSERT_SOURCE_DISK,STND_ERR_DEV,2,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
	display_it(PRESS_ANY_KEY,STND_ERR_DEV,0,ANY_KEY_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/

				/* If single drive system, eliminates double prompting */
				/* for user to "Insert diskette for drive %1" */
	qregs.x.ax = SETLOGICALDRIVE;				      /*;AN000;8*/
	qregs.h.bl = srcddir[0] - 'A' + 1;                            /*;AN000;8*/
	intdos(&qregs,&qregs);					      /*;AN000;8*/

     }								      /*;AC000;4*/
	return; 						      /*;AN000;4*/
}								      /*;AN000;4*/

/*************************************************/
/*
/* SUBROUTINE NAME:	check_target_filespec
/*
/* FUNCTION:
/*
/*	Verify the target filespec.
/*	 1. Validate destination drive, or use default if none specified
/*	 2. Validate path, or use current dir if not specified
/*	 3. Validate the file name
/*
/**************************************************/
void check_target_filespec(argc,argv)				      /*;AN000;4*/
int	argc;							      /*;AN000;4*/
char	*argv[];						      /*;AN000;4*/
{								      /*;AN000;4*/
	WORD  retcode;						      /*;AC000;*/
	WORD  device_handle;
	WORD  action;
	BYTE  parm;
	BYTE  media_type;
	DWORD drive_map;
	BYTE  temp_destddir[MAXPATH+2];
	BYTE  temp_array1[4];
	BYTE  temp_array2[4];
	WORD  default_drive_num;
	WORD  destd_num;
	WORD  dirlen = MAXPATH;
	BYTE  tdestddir[MAXPATH+3];
	BYTE  ttdestddir[MAXPATH+3];
	BYTE  srcf[MAXPATHF];
	BYTE  argv2_has_switch;
	BYTE  search_string[MAXPATHF+2];
	BYTE  tempp[MAXPATH];
	WORD  j,k,z;
	BYTE *c;
	BYTE  backdir;
	WORD  dnumwant = 1;
	union REGS qregs;					      /*;AN000;8*/


	/**************************/
	/*  Uppercase the string  */
	/**************************/
#define CAPITALIZE_STRING 0x6521				      /*;AN000;p????*/

	qregs.x.ax = CAPITALIZE_STRING; 			      /*;AN000;p????*/
	qregs.x.dx = (WORD)argv[2];				      /*;AN000;p????*/
	strcpy(tempp,argv[2]);					      /*;AN000;p????*/
	qregs.x.cx = strlen(tempp);				      /*;AN000;p????*/
	intdos(&qregs,&qregs);					      /*;AN000;p????*/


	/***************************************************/
	/* If no drive letter specified, use current drive */
	/***************************************************/
	if (							      /*;AC000;4*/
	     *(argv[2]+1)!=':' ||                                     /*;AC000;4*/
	     *argv[2] < 'A'    ||                                     /*;AC000;4*/
	     *argv[2] > 'Z'                                           /*;AC000;4*/
	   )							      /*;AC000;4*/
	  {							      /*;AC000;4*/
	   DOSQCURDISK						      /*;AC000;4*/
	    ( (unsigned far *)&default_drive_num,		      /*;AC000;4*/
	      (DWORD far *) &drive_map				      /*;AC000;4*/
	    );							      /*;AC000;4*/
	   destd = (BYTE)(default_drive_num + 'A' - 1);               /*;AC000;4*/
	  }							      /*;AC000;4*/
	 else							      /*;AC000;4*/
	  {	       /* User specified the destination drive*/      /*;AC000;4*/
	    destd = (BYTE)*argv[2];				      /*;AC000;4*/
	    argv[2] = argv[2] + 2;				      /*;AC000;4*/
	  }							      /*;AC000;4*/

	destddir[0] = destd;					      /*;AC000;4*/
	destddir[1] = ':';                                            /*;AC000;4*/
	destddir[2] = NUL;					      /*;AC000;4*/

   /***********************************************************************/
   /* if source drive and destination drive are the same, output error msg*/
   /***********************************************************************/
   if (srcd == destd)						      /*;AC000;4*/
    {								      /*;AC000;4*/
     display_it(SOURCE_TARGET_SAME,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
     usererror(INVALIDPARM);					      /*;AC000;4*/
    }								      /*;AC000;4*/

   /***********************************************************************/
   /* dosopen to find out whether the destination drive is exist	  */
   /* and dosdevioctl to find out whether it is a removable drive	  */
   /***********************************************************************/

       retcode =						      /*;AC000;4*/
	DOSOPEN 						      /*;AC000;4*/
	 ( (char far *)&destddir[0],				      /*;AC000;4*/
	   (unsigned far *)&device_handle,			      /*;AC000;4*/
	   (unsigned far *)&action,				      /*;AC000;4*/
	   (DWORD)0,		/*file size*/			      /*;AC000;4*/
	   0,			/*file attribute*/		      /*;AC000;4*/
	   0x01,		/*if file exist, open it*/	      /*;AC000;4*/
				/*if file not exist, fail it*/	      /*;AC000;4*/
	   0x80c2,		/*deny write, read only*/	      /*;AC000;4*/
	   (DWORD)0		/*reserved*/			      /*;AC000;4*/
	 );							      /*;AC000;4*/

	  if (retcode != NOERROR)/*if open fail*/		      /*;AC000;4*/
	   {							      /*;AC000;4*/
	     display_it(INVALID_DRIVE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	     usererror(INVALIDDRIVE);				      /*;AC000;4*/
	   }							      /*;AC000;4*/

     /************************************/			      /*;AC000;4*/
     /* See if target drive is removable */			      /*;AC000;4*/
     /************************************/			      /*;AC000;4*/
      retcode = 						      /*;AC000;4*/
	DOSDEVIOCTL						      /*;AC000;4*/
	 ( (char far *)&media_type,				      /*;AC000;4*/
	   (char far *)&parm,					      /*;AC000;4*/
	   0x20,						      /*;AC000;4*/
	   0x08,						      /*;AC000;4*/
	   device_handle					      /*;AC000;4*/
	 );							      /*;AC000;4*/

      if (retcode != NOERROR)					      /*;AC000;4*/
       { display_it(INVALID_DRIVE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	 usererror(INVALIDDRIVE);				      /*;AC000;4*/
       }							      /*;AC000;4*/

   if (media_type == REMOVABLE) 				      /*;AC000;4*/
    { temp_array1[0] = destd;					      /*;AC000;4*/
      temp_array1[1] = NUL;					      /*;AC000;4*/
      sublist.value1 = (char far *)temp_array1; 		      /*;AN000;6*/
      sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;		      /*;AN000;6*/
      sublist.max_width1 = (BYTE)strlen(temp_array1);		      /*;AN000;6*/
      sublist.min_width1 = sublist.max_width1;			      /*;AN000;6*/

     display_it(INSERT_TARGET_DISK,STND_ERR_DEV,1,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
     display_it(PRESS_ANY_KEY,STND_ERR_DEV,0,ANY_KEY_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
    }								      /*;AC000;4*/

				/* If single drive system, eliminates double prompting */
				/* for user to "Insert diskette for drive %1" */
   qregs.x.ax = SETLOGICALDRIVE;				      /*;AN000;8*/
   qregs.h.bl = destddir[0] - 'A' + 1;                                /*;AN000;8*/
   intdos(&qregs,&qregs);					      /*;AN000;8*/

   /**********************************************************************/
   /*  save current directory of destination disk to be reset back later */
   /**********************************************************************/

   destd_num = (WORD) (destd - 'A' +1);                               /*;AC000;4*/

   /*  get current directory of destd_num (DosQCurDir) */
   if ((retcode =						      /*;AC000;4*/
	DOSQCURDIR						      /*;AC000;4*/
	 ( destd_num,						      /*;AC000;4*/
	   (char far *) tdestddir,				      /*;AC000;4*/
	   (unsigned far *) &dirlen)				      /*;AC000;4*/
	 ) != 0)						      /*;AC000;4*/
    {								      /*;AC000;4*/
	display_it(INVALID_DRIVE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	usererror(INVALIDDRIVE);				      /*;AC000;4*/
    }								      /*;AC000;4*/

#define BACKSLASH 0x5c

   if (strlen(tdestddir) != 1)					      /*;AC000;4*/
    { strcpy(temp_destddir,"\\");                                     /*;AC000;4*/
      strcat(temp_destddir,tdestddir);				      /*;AC000;4*/
      strcpy(tdestddir,temp_destddir);				      /*;AC000;4*/
    }								      /*;AC000;4*/


   /**********************************************************************/
   /* The next parameter has to be a file name with or without path,	 */
   /* or a switch.  In the case of there is no path, the current path	 */
   /* is used.	In the case of there is no file name, the global file	 */
   /* name *.* is used							 */
   /**********************************************************************/
   /*	argv[2] is a drive spec*/				      /*;AC000;4*/
   if (*(argv[2]+1)==':' && *argv[2] >= 'A' && *argv[2] <= 'Z' && argc!=2)      /*;AC000;4*/
    {								      /*;AN000;6*/
      display_it(INVPARM,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)PARSEERROR);/*;AN000;6*/
      usererror(INVALIDPARM);					      /*;AC000;4*/
    }								      /*;AC000;4*/
   else 							      /*;AC000;4*/
    {  /*if argv[2] is not a drive spec */			      /*;AC000;4*/
       /*if argv[2] started with '/' (is a switch) or there is no argv[i]*/     /*;AC000;4*/
       if (*argv[2] == '/' ||  *argv[2] == NUL || argc ==2)           /*;AC000;4*/
	{  strcpy(srcf,tdestddir);				      /*;AC000;4*/
	   strcat(srcf,"\\*.*");                                      /*;AC000;4*/
	}							      /*;AC000;4*/
       else							      /*;AC000;4*/
	{ /*argv[2] does not started with / */			      /*;AC000;4*/
	   /* find out whether part of argv[2] is switch specification */	/*;AC000;4*/
	   for (k = 0; argv[2][k] != '/' && argv[2][k] != NUL;   ++k);/*;AC000;4*/
	   if (argv[2][k] == '/')                                     /*;AC000;4*/
	    {							      /*;AC000;4*/
	      argv[2][k] = NUL; 				      /*;AC000;4*/
	      argv2_has_switch = TRUE;				      /*;AC000;4*/
	    }							      /*;AC000;4*/

	   /*if argv[2] is \\, invalid parm */			      /*;AC000;4*/
	   if (argv[2][0] == '\\' && argv[2][1] == '\\' || argv[2][0] == ':')   /*;AC000;;4*/
	    {							      /*;AN000;6*/
	      display_it(INVPARM,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)PARSEERROR);/*;AN000;6*/
	      usererror(INVALIDPARM);				      /*;AC000;4*/
	    }							      /*;AC000;4*/

	   /*if argv[2] starts with '\' (it is a complete path)*/     /*;AC000;4*/
	   if (*argv[2] == '\\')                                      /*;AC000;4*/
	     strcpy(srcf,argv[2]);				      /*;AC000;4*/
	   else 						      /*;AC000;4*/
	      /* it is not a complete path, have to put current path in  */	/*;AC000;;4*/
	      /* front of the string to build a complete path */      /*;AC000;4*/
	    {  strcpy(srcf,tdestddir);				      /*;AC000;4*/
	       if (strlen(tdestddir) != 1)			      /*;AC000;4*/
		    strcat(srcf,"\\");                                /*;AC000;4*/
	       strcat(srcf,argv[2]);				      /*;AC000;4*/
	    } /*endif*/ 					      /*;AC000;4*/
	} /*end of argv[2] does not start with '/' */                 /*;AC000;4*/

       j = strlen(srcf);					      /*;AC000;4*/
       z = 0;							      /*;AC000;4*/
       do							      /*;AC000;4*/
	{  for (;srcf[z] != '.' && srcf[z] != NUL;   ++z);            /*;AC000;4*/
	   if (srcf[z] == '.' && srcf[z+1] == '.' &&                  /*;AC000;4*/
	       (srcf[z+2] == '\\' || srcf[z+2] == NUL))               /*;AC000;4*/
	    { backdir = TRUE;					      /*;AC000;4*/
	      break;						      /*;AC000;4*/
	    }							      /*;AC000;4*/
	   z = z+1;						      /*;AC000;4*/
	}							      /*;AC000;4*/
	while (z < j);						      /*;AC000;4*/

       /*validate the path*/					      /*;AC000;4*/
       for (z = j; srcf[z] != '\\'; --z);                             /*;AC000;4*/
       strcpy(tempp,srcf);					      /*;AC000;4*/
       tempp[z] = NUL;						      /*;AC000;4*/

       for (z = 0; tempp[z] != '*' && tempp[z] != NUL;   ++z);        /*;AC000;4*/
       if (tempp[z] == '*' )                                          /*;AC000;4*/
	{  display_it(PATH_NOT_FOUND,STND_ERR_DEV,1,NO_RESPTYPE,(BYTE)UTIL_MSG);     /*;AN000;6*/
	   usererror(INVALIDPARM);				      /*;AC000;4*/
	}							      /*;AC000;4*/

       if (backdir == TRUE)					      /*;AC000;4*/
	{  search_string[0] = destd;				      /*;AC000;4*/
	   search_string[1] = ':';                                    /*;AC000;4*/
	   search_string[2] = NUL;				      /*;AC000;4*/
	   if (srcf[0]	== NUL) 				      /*;AC000;4*/
	      strcat(search_string,"\\");                             /*;AC000;4*/
	   else 						      /*;AC000;4*/
	      strcat(search_string, tempp);			      /*;AC000;4*/

	   if(chdir(search_string)!=0)				      /*;AC000;4*/
	    { sublist.value1 = (char far *)argv[2];		      /*;AN000;6*/
	      sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;	      /*;AN000;6*/
	      sublist.max_width1 = (BYTE)strlen(argv[2]);	      /*;AN000;6*/
	      sublist.min_width1 = sublist.max_width1;		      /*;AN000;6*/
	      display_it(PATH_NOT_FOUND,STND_ERR_DEV,1,NO_RESPTYPE,(BYTE)UTIL_MSG);  /*;AN000;6*/
	      usererror(INVALIDPARM);				      /*;AC000;4*/
	    }							      /*;AC000;4*/

	   dirlen = MAXPATH;					      /*;AC000;4*/
	   if ((retcode = DOSQCURDIR(destd_num, 		      /*;AC000;4*/
	       (char far *) ttdestddir, 			      /*;AC000;4*/
	       (unsigned far *) &dirlen)) != NOERROR)		      /*;AC000;4*/
	    {							      /*;AC000;4*/
	     com_msg(retcode);					      /*;AC000;4*/
	     usererror(retcode);				      /*;AC000;4*/
	    }							      /*;AC000;4*/
	   /* endif */						      /*;AC000;4*/

	   temp_destddir[0] = destd;				      /*;AC000;4*/
	   temp_destddir[1] = ':';                                    /*;AC000;4*/
	   temp_destddir[2] = NUL;				      /*;AC000;4*/
	   strcat(temp_destddir,tdestddir);			      /*;AC000;4*/
	   chdir(temp_destddir);				      /*;AC000;4*/

	   if (strlen(ttdestddir) != 1) 			      /*;AC000;4*/
	    { strcpy(temp_destddir,"\\");                             /*;AC000;4*/
	      strcat(temp_destddir,ttdestddir); 		      /*;AC000;4*/
	      strcpy(ttdestddir,temp_destddir); 		      /*;AC000;4*/
	    }							      /*;AC000;4*/

	   strcat(ttdestddir,"\\");                                   /*;AC000;4*/
	   strcat(ttdestddir,srcf+z+1); 			      /*;AC000;4*/
	   strcpy(srcf,ttdestddir);				      /*;AC000;4*/
	} /*end of if backdir is true */			      /*;AC000;4*/

       /* The documentation says if path is specified, file name has to */
       /* be specified also.  This logic actually allows user to specify*/
       /* path without specify filename, as long as the path end with	*/
       /* '\'.*/
       /*If *srcf ends with '\', add "*.*" to the end*/               /*;AC000;4*/
       j = strlen(srcf);					      /*;AC000;4*/
       if (srcf[j-1] == '\\')                                         /*;AC000;4*/
	   strcat(srcf,"*.*");                                        /*;AC000;4*/
       if (argv2_has_switch == TRUE)				      /*;AC000;4*/
	{  *(argv[2]+k) = '/';                                        /*;AC000;4*/
	   argv[2] = argv[2] + k;				      /*;AC000;4*/
	}   /* end of if argv[2] started with '/' */                  /*;AC000;4*/
   }  /* end of checking for argv[2] */ 			      /*;AC000;4*/

  /**********************************************************************/
  /* add '\' at the beginning of the current destination directory      */
  /**********************************************************************/
   temp_destddir[0] = destd;					      /*;AC000;4*/
   temp_destddir[1] = ':';                                            /*;AC000;4*/
   temp_destddir[2] = NUL;					      /*;AC000;4*/
   strcat(temp_destddir,tdestddir);				      /*;AC000;4*/
   strcpy(destddir,temp_destddir);				      /*;AC000;4*/

   /************************************************************************/
   /* separate the filename for search into prefix(inpath),		   */
   /* filename(infname), and file extension (infext)			   */
   /* Also take care of the situation that user enter '.' only             */
   /* for file spec.							   */
   /************************************************************************/
   separate(srcf,inpath,infname,infext,infspec);		      /*;AC000;4*/
   if (strlen(infname) > MAXFNAME-1 ||				      /*;AC000;4*/
       strlen(infext) > MAXFEXT-1   ||				      /*;AC000;4*/
       strlen(inpath) > MAXPATH-1  ||				      /*;AC000;4*/
       strcmp(infspec,"LPT1")==0   ||                                 /*;AC000;4*/
       strcmp(infspec,"LPT2")==0   ||                                 /*;AC000;4*/
       strcmp(infspec,"PRN")==0    ||                                 /*;AC000;4*/
       strcmp(infspec,"CON")==0    ||                                 /*;AC000;4*/
       strcmp(infspec,"NUL")==0    ||                                 /*;AC000;4*/
       strcmp(infspec,"AUX")==0    ||                                 /*;AC000;4*/
       strcmp(infspec,"LPT1:")==0  ||                                 /*;AC000;4*/
       strcmp(infspec,"LPT2:")==0  ||                                 /*;AC000;4*/
       strcmp(infspec,"PRN:")==0   ||                                 /*;AC000;4*/
       strcmp(infspec,"CON:")==0   ||                                 /*;AC000;4*/
       strcmp(infspec,"NUL:")==0   ||                                 /*;AC000;4*/
       strcmp(infspec,"AUX:")==0 )                                    /*;AC000;4*/
   {								      /*;AC000;4*/
       sublist.value1 = (char far *)&infspec[0];		      /*;AN000;6*/
       sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ; 	      /*;AN000;6*/
       sublist.one = 0; 	/* Yes, this is right */	      /*;AN000;6*/
       sublist.max_width1 = (BYTE)strlen(infspec);		      /*;AN000;6*/
       sublist.min_width1 = sublist.max_width1; 		      /*;AN000;6*/

       display_it(INVPARM,STND_ERR_DEV,1,NO_RESPTYPE,(BYTE)PARSEERROR);/*;AN000;6*/
       usererror(INVALIDPARM);	     /* invalid parm */ 	      /*;AC000;4*/
   }								      /*;AC000;4*/

   /************************************************************************/
   /* set wildcard flag according to whether there is '*' or/and  '?' in   */
   /* file specification						   */
   /************************************************************************/
   c = infspec; 						      /*;AC000;4*/
   while (*c)							      /*;AC000;4*/
    {								      /*;AC000;4*/
      if (*c == '*' || *c == '?')                                     /*;AC000;4*/
       { set_reset_test_flag(&control_flag,WILDCARD,SET);	      /*;AC000;4*/
	 break; 						      /*;AC000;4*/
       }							      /*;AC000;4*/
      else							      /*;AC000;4*/
	c = c+1;						      /*;AC000;4*/
    }								      /*;AC000;4*/


	return; 				/*;AN000;4*/
}						/*;AN000;4*/

/*************************************************/
/*
/* SUBROUTINE NAME:	process_switch
/*
/* FUNCTION:
/*
/*	Identify the switch (/S,/P,/M,/N,/B:,/A:,/E:,/L:)
/*	 entered and handle it
/*
/**************************************************/
void process_switch(buff_addr,ptr)				      /*;AN000;4*//*;AC002;*/
unsigned buff_addr;						      /*;AN000;4*/
char *ptr;							      /*;AN002;*/
{								      /*;AN000;4*/

	if (buff_addr == (unsigned)&sw_buff)			      /*;AN000;4*/
	 {							      /*;AN000;4*/
	   if (sw_buff.sw_synonym_ptr == (WORD)&sw3.switch1[0])       /*;AN000;4   /S */
	   {set_reset_test_flag(&rtswitch, SUB, SET);		      /*;AN000;4*/
	   }

	   if (sw_buff.sw_synonym_ptr == (WORD)&sw3.switch2[0])       /*;AN000;4   /P */
	     {							      /*;AN000;4*/
	      set_reset_test_flag(&rtswitch, PROMPT, SET);	      /*;AN000;4*/
	      set_reset_test_flag(&control_flag, SWITCHES, SET);      /*;AN000;4*/
	     }							      /*;AN000;4*/

	   if (sw_buff.sw_synonym_ptr == (WORD)&sw3.switch3[0])       /*;AN000;4   /M */
	     {							      /*;AN000;4*/
	      set_reset_test_flag(&rtswitch, Revised, SET);	      /*;AN000;4*/
	      set_reset_test_flag(&control_flag, SWITCHES, SET);      /*;AN000;4*/
	     }							      /*;AN000;4*/

	   if (sw_buff.sw_synonym_ptr == (WORD)&sw3.switch4[0])       /*;AN000;4   /N */
	     {							      /*;AN000;4*/
	      set_reset_test_flag(&rtswitch, NOTEXIST, SET);	      /*;AN000;4*/
	      set_reset_test_flag(&control_flag, SWITCHES, SET);      /*;AN000;4*/
	     }							      /*;AN000;4*/
	 }							      /*;AN000;4*/


	if (buff_addr == (unsigned)&time_buff)			      /*;AN000;4*/
	 {							      /*;AN000;4*/
	   check_time(time_buff.hours,time_buff.minutes,time_buff.seconds,time_buff.hundreds);	  /*;AN000;4*//*;AC002;*/

	   if (time_buff.tb_synonym_ptr == (WORD)&sw2.switch1[0])     /*;AN000;4   /E */
	     {							      /*;AN000;4*/
	       td.earlier_hour =   time_buff.hours;		      /*;AN000;4*/
	       td.earlier_minute = time_buff.minutes;		      /*;AN000;4*/
	       td.earlier_second = time_buff.seconds;		      /*;AN000;4*/
	       set_reset_test_flag(&rtswitch, EARLIER, SET);	      /*;AN000;4*/
	       set_reset_test_flag(&control_flag, SWITCHES, SET);     /*;AN000;4*/
	     }							      /*;AN000;4*/

	   if (time_buff.tb_synonym_ptr == (WORD)&sw2.switch2[0])     /*;AN000;4   /L */
	     {							      /*;AN000;4*/
	       td.later_hour =	 time_buff.hours;		      /*;AN000;4*/
	       td.later_minute = time_buff.minutes;		      /*;AN000;4*/
	       td.later_second = time_buff.seconds;		      /*;AN000;4*/
	       set_reset_test_flag(&rtswitch, LATER, SET);	      /*;AN000;4*/
	       set_reset_test_flag(&control_flag, SWITCHES, SET);     /*;AN000;4*/
	     }							      /*;AN000;4*/

	 }							      /*;AN000;4*/


	if (buff_addr == (unsigned)&date_buff)			      /*;AN000;4*/
	 {							      /*;AN000;4*/
	   check_date(date_buff.year,date_buff.month,date_buff.day);	  /*;AN000;4*//*;AC002;*/

	   if (date_buff.db_synonym_ptr == (WORD)&sw1.switch1[0])     /*;AN000;4  /B */
	     {							      /*;AN000;4*/
	       td.before_year =  date_buff.year;		      /*;AN000;4*/
	       td.before_month = date_buff.month;		      /*;AN000;4*/
	       td.before_day =	 date_buff.day; 		      /*;AN000;4*/
	       set_reset_test_flag(&rtswitch, BEFORE, SET);	      /*;AN000;4*/
	       set_reset_test_flag(&control_flag, SWITCHES, SET);     /*;AN000;4*/
	     }							      /*;AN000;4*/

	   if (date_buff.db_synonym_ptr == (WORD)&sw1.switch2[0])     /*;AN000;4  /A */
	     {							      /*;AN000;4*/
	       td.after_year =	date_buff.year; 		      /*;AN000;4*/
	       td.after_month = date_buff.month;		      /*;AN000;4*/
	       td.after_day =	date_buff.day;			      /*;AN000;4*/
	       set_reset_test_flag(&rtswitch, AFTER, SET);	      /*;AN000;4*/
	       set_reset_test_flag(&control_flag, SWITCHES, SET);     /*;AN000;4*/
	     }							      /*;AN000;4*/

	 }							      /*;AN000;4*/

	return; 						      /*;AN000;4*/
}								      /*;AN000;4*/
