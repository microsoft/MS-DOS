
/*---------------------------------
/* SOURCE FILE NAME:  RTT3.C
/*---------------------------------
/*  0 */

#include "rt.h"
#include "rt1.h"
#include "rt2.h"
#include "direct.h"
#include "string.h"
#include "dos.h"                                                      /*;AN000;2*/
#include "comsub.h"             /* common subroutine def'n */
#include "doscalls.h"
#include "error.h"
#include "process.h"                                                  /*;AN000;p972*/

extern BYTE filename[12];
extern BYTE destddir[MAXPATH+3];
extern BYTE srcddir[MAXPATH+3];
extern BYTE rtswitch;
extern BYTE control_flag;
extern BYTE control_flag2;
char far *buf_pointer;
char far *control_buf_pointer;
unsigned control_selector;
extern BYTE dest_file_spec[MAXFSPEC];
extern unsigned dest_file_handle;
extern BYTE append_indicator;					      /*;AN000;2*/
extern WORD original_append_func;				      /*;AN000;2*/
extern struct  subst_list sublist;				      /*;AN000;6 Message substitution list */
extern char response_buff[5];					      /*;AN000;6*/
BYTE far *DBCS_ptr;						      /*;AN005;*/
char  got_dbcs_vector = FFALSE; 				      /*;AN005;*/

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  set_reset_test_flag
/*
/*  DESCRIPTIVE NAME :	to set a flag, reset a flag, or test a flag.
/*
/*  FUNCTION: This subroutine is called when there is a need to set
/*	      a flag, reset a flag, or test a flag.
/*  NOTES:
/*
/*  INPUT: (PARAMETERS)
/*	    flag - the flag to be set, reset, or tested.
/*	    targetbt - the target bit to be set, reset, or tested.
/*	    choice - = 1 if want to set
/*		     = 2 if want to reset
/*		     = 3 if want to test
/*
/********************* END OF SPECIFICATIONS ********************************/
int set_reset_test_flag(flag,targetbt,choice)

     BYTE *flag;	/*the flag to be tested against*/
     BYTE targetbt;	/*the byte to be tested   */
     int choice;
{
     BYTE temp;


switch (choice) {
case SET:
	    *flag = *flag | targetbt;
	    break;

case RESET:
	    *flag = *flag & ~targetbt;
	    break;

case TEST:
	    temp = *flag & targetbt;
	    if (temp == 0) {
	       return(FALSE); /*the tested bit is off*/
	       }
	    else {
	       return(TRUE); /*the tested bit is on */
	       }
	    break;

default:
	    unexperror(UNEXPECTED);
	    break;
} /*end of switch */

	return(FALSE);		/* wrw! */

}
/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  separate
/*
/*  DESCRIPTIVE NAME : Separate the given input string into 3 parts;
/*		       which is the path, filename, file extension, and
/*		       file specification.
/*
/*  FUNCTION: The subroutine searches the input string for the last '\',
/*	      which separates the path and file specification, and then
/*	      searches the file specification for '.', which separates
/*	      the filename and file extension.	Also take care the
/*	      situation of the user enter '.' for file specification.
/*	      This subroutine also validate the file specification
/*	      and each path entered by the user by calling common
/*	      subroutine Comverflnm.
/*
/*  NOTE: The input string must start with '\'
/*	  All the output string are terminated by 00h
/*
/*  INPUT: (PARAMETERS)
/*	   instring - input string to be separated into path, filename,
/*		      and file extension.
/*
/*  OUTPUT:
/*	   path     - output path name, always starts with '\' and not end
/*		      with '\'
/*	   filename - output file name
/*	   fileext  - output file extension
/*	   filespec - output file name and file extension
/*
/********************** END OF SPECIFICATIONS *******************************/
void separate(instring,path,filename,fileext,filespec)
BYTE *instring; 	/* point to beginning of input string */
BYTE *path;		/* point to beginning of path string  */
BYTE *filename; 	/* point to beginning of file name    */
BYTE *fileext;		/* point to beginning of file ext.    */
BYTE *filespec; 	/* point to beginning of file spec    */
{
	BYTE *iptr;	 /* working pointer */
	BYTE *fptr;	 /* working pointer */
	WORD i; 						       /*;AN005;*/

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
		/* Find last non-DBCS backslash character */
/*    fptr = com_strrchr(instring,'\\');                              /*;AN000;p2532*/

      for (							       /*;AN005;*/
	   i=strlen(instring);					       /*;AN005;*/
	   (i>=0) && (!chek_DBCS(instring,i,'\\'));                    /*;AN005;*/
	   i--							       /*;AN005;*/
	  )							       /*;AN005;*/
       {};							       /*;AN005;*/

      fptr = instring + i;					      /*;AN005;*/
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

      if (fptr!=instring || instring[0] == '\\')
      {
	 *fptr = NULLC; 					 /*;AC000;*/
	 strcpy(path, instring);
	 if (path[0] == NULLC)
	   strcpy(path,"\\");
	 *fptr = '\\';
	 ++fptr;
	 strcpy(filespec, fptr);

	 if (filespec[0] == '.' && filespec[1] == NULLC)
	 {
	    strcpy(filename, "*");
	    strcpy(fileext, "*");
	    strcpy(filespec, "*.*");
	 }
	 else
	 {   /*else if filespec is not '.'*/
	    for (iptr = fptr; *iptr!='.' && *iptr != NULLC; ++iptr);

	    if (*iptr == '.')
	    {
		*iptr = NULLC;
		strcpy(filename, fptr);
		*iptr = '.';

	       iptr = iptr+1;
	       strcpy(fileext, iptr);
	    }
	    else
	    {
	       strcpy(filename, filespec);
	       *fileext = NULLC;
	    }

	 }

      }
      else
      {}

      return;
}





/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  initbuf
/*
/*  DESCRIPTIVE NAME : Initialize buffer for reading and writting.
/*
/*  FUNCTION: Allocate up to 64 K bytes buffer for reading and writing
/*	      data, and make sure its size is divisible by the sector
/*	      size of the restore drive.
/*
/*  NOTES:
/*
/********************** END OF SPECIFICATIONS *******************************/

void initbuf(bufsize_long)
    DWORD *bufsize_long;
{
    unsigned bufsize;
    WORD selector;
    WORD retcode;

   bufsize = MAXBUF;  /*64K-1 */
   /*do while allocate bufsize fail, bufsize = bufsize - DOWNSIZE*/
   for (;;) {
	retcode = DOSALLOCSEG( (unsigned ) bufsize,	/*buf length  */
			 ( unsigned far * ) &selector,	/* buf pointer*/
			 ( unsigned) 0 );		/* no sharing */
	if ( retcode != 0)
	{
	    if (bufsize > DOWNSIZE)
		bufsize = bufsize - DOWNSIZE;
	    else
	       break;
	}
	else
	   break;
   }
   if (bufsize != 0 && bufsize <= DOWNSIZE ) {
      display_it(INSUFFICIENT_MEMORY,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
      usererror(INSUFMEM);
    }

    FP_SEG( buf_pointer ) = selector;
    FP_OFF( buf_pointer ) = 0 ;

    if (bufsize == 0)
       *bufsize_long = (DWORD)MAXBUF;
    else
       *bufsize_long = (DWORD)bufsize;
} /*end of subroutine*/

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  init_control_buf
/*
/*  DESCRIPTIVE NAME : Initialize buffer for control.XXX.
/*
/*  FUNCTION: Allocate buffer for reading in control.xxx
/*
/*  OUTPUT:
/*	   control_bufsize - the size of buffer
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
void init_control_buf(control_file_len,control_bufsize) 	   /* !wrw */
    DWORD control_file_len;					   /* !wrw */
    unsigned int  *control_bufsize;				   /* !wrw */
{								   /* !wrw */
    unsigned bufsize;						   /* !wrw */
    WORD retcode;						   /* !wrw */

  bufsize = 3072;						   /* !wrw */


   retcode = DOSALLOCSEG( (unsigned ) bufsize,			     /* !wrw */
			 ( unsigned far * ) &control_selector,	     /* !wrw */
			 ( unsigned) 0 );			     /* !wrw */


   if ( retcode != 0)		/* If there is insufficient memory /* !wrw */
   {								   /* !wrw */
     display_it(INSUFFICIENT_MEMORY,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);      /*;AN000;6*/
     usererror(INSUFMEM);
    }								   /* !wrw */

    FP_SEG( control_buf_pointer ) = control_selector;		   /* !wrw */
    FP_OFF( control_buf_pointer ) = 0 ; 			   /* !wrw */

    *control_bufsize = bufsize; 				   /* !wrw */

} /*end of subroutine*/ 					   /* !wrw */

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  unexperror
/*
/*  DESCRIPTIVE NAME : exit the program because of something really bad
/*		       occures
/*
/*  FUNCTION: Exit the program because of unexpected error
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
void unexperror(retcode)
WORD retcode;
{
     exit_routine(retcode);
     return;
}

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  usererror
/*
/*  DESCRIPTIVE NAME : exit the program because of a user error
/*
/********************** END OF SPECIFICATIONS *******************************/
void usererror(retcode)
WORD retcode;
{
     unexperror(retcode);
     return;
}

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  exit_routine
/*
/*  DESCRIPTIVE NAME : exit the program
/*
/*  FUNCTION: 1. output msg if there is a sharing error.
/*	      2. if PCDOS, convert return codes to error levels
/*	      3. exit the program
/*
/*  NOTES:
/*
/*  INPUT: (PARAMETERS)
/*	 retcode - the reason of error
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
void exit_routine(retcode)
WORD retcode;
{
     union REGS regs;			   /*;AN000;2*/

     chdir (destddir);

     chdir (srcddir);

      /* if flag indicates there is a SHAREERROR */
      if (retcode == NORMAL &&
      set_reset_test_flag(&control_flag,SHARERROR,TEST)==TRUE)
	 retcode = SHARERR;

	 switch(retcode)
	  {
	   case  NORMAL:   retcode = PC_NORMAL;
			   break;
	   case  NOFILES:  retcode = PC_NOFILES;
			   break;
	   case  SHARERR:  retcode = PC_SHARERR;
			   break;
	   case  TUSER:    retcode = PC_TUSER;
			   break;
	   default:	   retcode = PC_OTHER;
			   break;
	  } /* end switch */


	if (append_indicator == DOS_APPEND)	/*;AN000;2 If append /x was reset*/
	 {					/*;AN000;2*/
	    regs.x.ax = SET_STATE;		/*;AN000;2*/
	    regs.x.bx = original_append_func;	/*;AN000;2*/
	    int86(0x2f,&regs,&regs);		/*;AN000;2*/
	 }					/*;AN000;2*/

     exit(retcode);				/*;AN000;p972*/

}
/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  signal_handler_routine
/*
/*  DESCRIPTIVE NAME :	handle the situation that the user terminate
/*			the program by Control-break.
/*
/*  FUNCTION: This subroutine change the directory of the
/*	      destination disk back to the original directory.
/*	      If there is a file in the middle of restoring, close
/*	      the file, deleted the partially restored file, and
/*	      output a message.
/*	      Then exit with error level TUSER.
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
void pascal far signal_handler_routine()
{
   WORD retcode;

   DWORD dw = 0L;	   /* reserved double word*/

   /*change dir to the original directory of the destination disk*/

   /**************************************************************/
   /*if PARTIAL flag is on, close and delete the destination file*/
   /**************************************************************/
   if (set_reset_test_flag(&control_flag,PARTIAL,TEST) == TRUE) {
      /* close the partially completed destination file*/
      DOSCLOSE(dest_file_handle);
      /* delete the partially completed destination file*/
      if ((retcode = DOSDELETE((char far *) dest_file_spec, dw)) != 0) {
	 /*set file mode to 0*/
	 if ((retcode = DOSSETFILEMODE((char far *)dest_file_spec,
	 (unsigned) 0x00, dw)) != 0)
	 {
	    com_msg(retcode);
	    unexperror(retcode);
	 }
	 /* delete the partially completed destination file*/
	 if ((retcode = DOSDELETE((char far *) dest_file_spec, dw)) != 0) {
	    com_msg(retcode);
	    unexperror(retcode);
	 }
      }
      display_it(LAST_FILE_NOT_RESTORED,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);  /*;AN000;6*/
   }
   exit_routine(TUSER);

} /* end of signal_handler*/

/************************************************************/
/*
/*   SUBROUTINE NAME:	   display_it  (added for DOS 4.00)
/*
/*   SUBROUTINE FUNCTION:
/*	   Display the requested message to the standard output device.
/*
/*   INPUT:
/*	   1) (WORD) Number of the message to be displayed.
/*	   2) (WORD) Handle to be written to.
/*	   3) (WORD) Substitution Count
/*	   4) (WORD) Flag indicating user should "Strike any key..."
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
/*
/************************************************************/
#define CLASS		-1	/* Goes in DH register */	      /*;AN000;6*/
#define NUL_POINTER	0	/* Pointer to nothing */	      /*;AN000;6*/

void	display_it(msg_number,handle,subst_count,waitflag,class)      /*;AN000;6*/

WORD	msg_number;						      /*;AN000;6*/
WORD	handle; 						      /*;AN000;6*/
WORD	subst_count;						      /*;AN000;6*/
WORD	waitflag;						      /*;AN000;6*/
BYTE	class;							      /*;AN000;6*/
{								      /*;AN000;6*/
	union REGS reg; 					      /*;AN000;6*/

	reg.x.ax = msg_number;					      /*;AN000;6*/
	reg.x.bx = handle;					      /*;AN000;6*/
	reg.x.cx = subst_count; 				      /*;AN000;6*/
	reg.h.dh = class;					      /*;AN000;6*/
	reg.h.dl = (BYTE)waitflag;				      /*;AN000;6*/
	reg.x.di = (BYTE)&response_buff[0];			      /*;AN000;6*/
	reg.x.si = (WORD)(char far *)&sublist;			      /*;AN000;6*/

	sysdispmsg(&reg,&reg);					      /*;AN000;6*/
	response_buff[0] = reg.h.al;	/* User input */	      /*;AN000;6*/

	return; 						      /*;AN000;6 */
}								      /*;AN000;6 */
/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  com_msg
/*
/*  DESCRIPTIVE NAME : the routine to output a message according to
/*		       the return codes returned from API calls.
/*
/*  FUNCTION: 1. if CP/DOS, then call rctomid
/*
/*  NOTES:
/*
/*  INPUT: (PARAMETERS)
/*	    retcode - return code used to call rctomid
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
void com_msg(retcode)
WORD retcode;
{
	/* Was IF CPDOS */
   display_it(rctomid(retcode),STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);  /*;AN000;6*/

   return;

}
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*									     */
/*     Subroutine Name:      chek_DBCS()				     */
/*									     */
/*	       (Ripped off and Revised from ATTRIB.C)			     */
/*									     */
/*     Subroutine Function:						     */
/*	  Given an array and a position in the array, check if the character */
/*	  is a non-DBCS character.					     */
/*									     */
/*    Input:  array, character position, character			     */
/*									     */
/*    Output: TRUE - if array[position-1] != DBCS character  AND	     */
/*			array[position] == character.			     */
/*	      FALSE - otherwise 					     */
/*									     */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
WORD chek_DBCS(array,position,character)			       /*;AN005;*/
char *array;							       /*;AN005;*/
WORD position;							       /*;AN005;*/
char character; 						       /*;AN005;*/
{								       /*;AN005;*/
   BYTE far *ptr;						       /*;AN005;*/
   WORD i;							       /*;AN005;*/
   char c;							       /*;AN005;*/
   char darray[128];	    /* DBCS array, put "D" in every position*/ /*;AN005;*/
			    /* that corresponds to the first byte   */
			    /* of a DBCS character.		    */
   if (!got_dbcs_vector)					       /*;AN005;*/
     Get_DBCS_vector(); 					       /*;AN005;*/

   for (i=0;i<128;i++)						       /*;AN005;*/
      darray[i] = ' ';                                                 /*;AN005;*/

   /* Check each character, starting with the first in string, for DBCS */
   /* characters and mark each with a "D" in the corresponding darray.  */
   for (i=0;i<position;i++)					       /*;AN005;*/
   {								       /*;AN005;*/
      c = array[i];						       /*;AN005;*/

      /* look thru DBCS table to determine if character is first byte */
      /* of a double byte character				      */
      for (ptr=DBCS_ptr; (WORD)*(WORD far *)ptr != 0; ptr += 2)        /*;AN005;*/
      { 							       /*;AN005;*/

	 /* check if byte is within range values of DOS DBCS table */
	 if (c >= *ptr && c <= *(ptr+1))			       /*;AN005;*/
	 {							       /*;AN005;*/
	    darray[i] = 'D';                                           /*;AN005;*/
	    i++;	   /* skip over second byte of DBCS */	       /*;AN005;*/
	    break;						       /*;AN005;*/
	 }							       /*;AN005;*/
      } 							       /*;AN005;*/
   }								       /*;AN005;*/

   /* if character is not DBCS then check to see if it is == to character */
   if (darray[position-1] != 'D' && character == array[position])      /*;AN005;*/
      return (TTRUE);						       /*;AN005;*/
   else 							       /*;AN005;*/
      return (FFALSE);						       /*;AN005;*/
}								       /*;AN005;*/

/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
/*									     */
/*     Subroutine Name:     Get_DBCS_vector()				     */
/*									     */
/*     Subroutine Function:						     */
/*	  Gets the double-byte table vector.				     */
/*	  Puts it in global variable DBCS_ptr				     */
/*ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
void Get_DBCS_vector()						       /*;AN005;*/
{								       /*;AN005;*/
    union REGS inregs,outregs;					       /*;AN005;*/
    struct SREGS segregs;					       /*;AN005;*/
    char fix_es_reg[2]; 					       /*;AN005;*/
    WORD *ptr;							       /*;AN005;*/
    DWORD far *addr_ptr;					       /*;AN005;*/
    WORD *buffer;						       /*;AN005;*/

		/***********************************/
		/* Allocate a buffer		   */
		/***********************************/
    inregs.x.ax = 0x4800;		/* Allocate */		       /*;AN005;*/
    inregs.x.bx = 1;			/* Num	paragraphs */	       /*;AN005;*/
    intdos(&inregs,&outregs);		/* Int 21h */		       /*;AN005;*/
    buffer = (WORD *)outregs.x.ax;	/* Segment of buffer */        /*;AN005;*/

    inregs.x.ax = 0x6507;      /* get extended country info */	       /*;AN005;*/
    inregs.x.bx = 0xffff;	  /* use active code page */	       /*;AN005;*/
    inregs.x.cx = 5;		  /* 5 bytes of return data */	       /*;AN005;*/
    inregs.x.dx = 0xffff;	  /* use default country */	       /*;AN005;*/
    inregs.x.di = 0;		  /* buffer offset */		       /*;AN005;*/
    segregs.es = (WORD)buffer;	  /* buffer segment */		       /*;AN005;*/
    segregs.ds = (WORD)buffer;	  /* buffer segment */		       /*;AN005;*/
    intdosx(&inregs,&outregs,&segregs); 			       /*;AN005;*/
    strcpy(fix_es_reg,NUL);					       /*;AN005;*/

    outregs.x.di++;		  /* skip over id byte */	       /*;AN005;*/

    /* make a far ptr from ES:[DI] */
    addr_ptr = 0;						       /*;AN005;*/
    ptr = (WORD *)&addr_ptr;					       /*;AN005;*/
    *ptr = (WORD)outregs.x.di;	  /* get offset */		       /*;AN005;*/
    ptr++;							       /*;AN005;*/
    *ptr = (WORD)segregs.es;	  /* get segment */		       /*;AN005;*/
    DBCS_ptr = (BYTE far *)*addr_ptr;				       /*;AN005;*/
    DBCS_ptr += 2;		  /* skip over table length */	       /*;AN005;*/

    /* DBCS_ptr points to DBCS table */
    strcpy(fix_es_reg,NUL);					       /*;AN005;*/
    got_dbcs_vector = TTRUE;					       /*;AN005;*/
    return;							       /*;AN005;*/
}								       /*;AN005;*/

