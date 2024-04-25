
/*-------------------------------
/* SOURCE FILE NAME:   RTOLD1.C
/*-------------------------------
/*  0 */

#include "rt.h"
#include "rt1.h"
#include "rt2.h"
#include "restpars.h"                                                 /*;AN000;4*/
#include "string.h"
#include "dos.h"                                                      /*;AN000;2*/
#include "comsub.h"             /* common subroutine def'n */
#include "doscalls.h"
#include "error.h"
#include "stdio.h"

extern	BYTE rtswitch;
extern	BYTE control_flag;
extern	BYTE control_flag2;
extern	char far *buf_pointer;
extern	unsigned src_file_handle;
extern	struct FileFindBuf filefindbuf;
extern	struct FileFindBuf dfilefindbuf;
BYTE	src_fname[MAXFNAME];
extern	struct	subst_list sublist;				      /*;AN000;6 Message substitution list */
extern	char response_buff[5];					      /*;AN000;6*/
struct	file_header_old fheadold;				      /*;AN000;*/

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  pathmatch
/*
/*  DESCRIPTIVE NAME : Compare two paths and return TRUE or FALSE
/*		       according to whether they match or not.
/*
/*  NOTES: Global characters * and ? are meaningless in the file path name
/*	   Assume both path pattern and path subject are not end with \
/*
/*  INPUT: (PARAMETERS)
/*	 subject  - the file path to be compared.
/*	 pattern  - the file path to be compared against.
/*
/********************** END OF SPECIFICATIONS *******************************/
WORD pathmatch(patterns,subjects)

BYTE *patterns;  /* the string to be matched with */
BYTE *subjects;  /* the string to be matched */
{
    BYTE *pattern;   /* the working pointer to point to the pattern */
    BYTE *subject;   /* the working pointer to point to the subject */
    int z;

    /*save the pointers to both strings*/
    pattern = patterns;
    subject = subjects;

    /* loop until matched or unmatched is determined */
    for (;;)
    {
	if (*pattern == *subject)
	 {
	  if (*pattern != NULLC)   /* not finish scanning yet*/
	    {
	      pattern+=1;	    /* advance the pointer by 1 */
	      subject+=1;	    /* advance the pointer by 1 */
	      continue; 	    /* continue on comparing again */
	    }
	  else
	    return(TRUE);
	 }
       else
	{   /* if subject is longer than pattern and SUB flag in rtswitches is on  */
	    if (set_reset_test_flag(&rtswitch, SUB, TEST)==TRUE)
	     {
	       if ((*pattern == NULLC && *subject == '\\') ||
		  (patterns[0] == '\\' && patterns[1] == NULLC))
		return(TRUE);
	       else
		return(FALSE);
	     }
	    else
	     return(FALSE);
	}
    }
  return(TRUE); 							/*;AN000;*/
}

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  fspecmatch
/*
/*  DESCRIPTIVE NAME : Compare two file spec. and return TRUE or FALSE
/*		       according to whether they match or not.
/*
/*  FUNCTION: This subroutine compare the file names and file extensions
/*	      to determine whether they are match or not.
/*	      TRUE is returned if they are match, otherwise, FALSE
/*	      is returned.
/*
/*  NOTES: * and ? are acceptable in the file name and file extension.
/*
/********************** END OF SPECIFICATIONS *******************************/
fspecmatch(patterns, subjects)
char *patterns;
char *subjects;
{
	char *pattern;
	char *subject;
	int z;

	pattern = patterns;
	subject = subjects;

	for (;;)
	 {
	  if (*pattern == '*')
	   {
	     /*advance pointer in pattern until find '.' or nullc*/
	     for (;*pattern != '.' && *pattern != NULLC; ++pattern);
	     if (*pattern == NULLC)
	      {

		 /* pattern has no extension, so make sure subject doesn't either */
		 /* find end or '.' in subject */

		 for (;*subject != '.' && *subject != NULLC; ++subject);

		 if (*subject == NULLC || *(subject+1) == '.')
		   return(TRUE);
		  else	/* subject has extension, so return FALSE */
		   return(FALSE);
	      }
	     else
	      {
		if ( *(pattern+1) == '*')
		   return(TRUE);
		 else
		  {
		    /*advance pointer in subject until find '.' or nullc*/
		    for (;*subject != '.' && *subject != NULLC; ++subject);
		    if (*subject == NULLC )
		     {
		      if (*(pattern+1) != NULLC)
			return(FALSE);
		       else
			return(TRUE);
		      }
		     else
		      {
			pattern+=1;
			subject+=1;
			continue;
		      } /*end of if *subject is not NULL*/
		  }  /*end of if *(pattern+1) is not '*' */
	      } /*end of if *pattern == NULLC */
	   }
	  else
	   {
	    if (*pattern == *subject || *pattern == '?')
	     {
		 if (*pattern != NULLC)
		  {
		    pattern+=1;
		    subject+=1;
		    continue;
		  }
		 else
		  return(TRUE);
	     }
	    else
	       if (*pattern == '.' && *(pattern+1) == '*' && *subject == NULLC)
		 return(TRUE);
		else
		 return(FALSE);
	   }

	}    /*end of for loop*/

}  /*end of subroutine */

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  switchmatch
/*
/*  DESCRIPTIVE NAME : Check the file attributes, and/or file modes
/*		       against the switches set in the input command
/*		       line.
/*
/*  FUNCTION: this subroutine search the hard disk for the dest
/*	      file first.  If dest file is found,  the attributs of the
/*	      destination file will be used for checking.
/*
/*	      Check the switches set in the input command line one by
/*	      one, whenever a  switch not match is found, FALSE is returne
/*	      In the case a switch is match, TRUE is not returned until al
/*	      switches is checked.
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
WORD switchmatch(finfo, srcd, destd, td)
struct file_info *finfo;
BYTE srcd;
BYTE destd;
struct timedate *td;
{
     WORD   yy;
     WORD   mm;
     WORD   dd;
     WORD   hh;
     WORD   mn;
     WORD   ss;
     WORD  action;
     unsigned file_pointer;
     WORD retcode;
     int z;

     /*declaration for dosqfileinfo*/
     struct FileStatus fileinfo_buf;
     WORD destdnum;
     WORD buflen = sizeof(struct FileStatus);
     unsigned attributes;

     /*declaration for dosfindfirst */
     unsigned	 ddirhandle = 0xffff;
     unsigned	 attribute = NOTV;
     unsigned	 search_cnt = 1;
     unsigned	 buf_len = sizeof(struct FileFindBuf);
     BYTE search_string[MAXPATHF+2];
     /*end decleration for ffirst and fnext*/

   /***********************************************************************/
   /* Search hard file for the path and name of file about to be restored */
   /* and get the file information of the file on the hard disk 	  */
   /***********************************************************************/
     search_string[0] = destd;
     search_string[1] = ':';
     search_string[2] = NULLC;
     strcat(search_string, finfo->path);
     if (strlen(finfo->path) != 1)
	strcat(search_string, "\\");
     strcat(search_string, finfo->fname);

      retcode = DOSOPEN( (char far *)&search_string[0],
		      (unsigned far *)&file_pointer,
		      (unsigned far *)&action,
		      (DWORD)0,    /*file size*/
		      0,		   /*file attribute*/
		      0x01,		   /*if file exist, open*/
					   /*if file not exist, fail*/
		      0x00c0,		   /*deny write, read write access*/
		      (DWORD)0 );  /*reserved*/
   /***********************************************************************/
   /*if open fail (means the file does not exist on the hard disk), then  */
   /* return true							  */
   /***********************************************************************/
   if (retcode != NOERROR) {
	 /*set flag CREATIT*/
	 set_reset_test_flag(&control_flag,CREATIT,SET);
	 /*return TRUE*/
	 return (TRUE);
   }
   /*********************************************************************/
   /* call DosQFileInfo: Request date and time of the dest file 	*/
   /*********************************************************************/
   retcode = DOSQFILEINFO (
	     (unsigned)file_pointer,	      /* File handle */
	     (unsigned)1,		      /* File info data required */
	     (char far *)&fileinfo_buf,        /* File info buffer */
	     (unsigned)buflen); 	     /* File info buffer size */


   if (retcode != NOERROR) {
	com_msg(retcode);
	unexperror(retcode);
   }

   if ((retcode = DOSQFILEMODE((char far *)&search_string[0],
		  (unsigned far *) &attributes,
		  (DWORD) 0)) !=0) {
	com_msg(retcode);
	unexperror(retcode);
   }


   DOSCLOSE(file_pointer);
   /***********************************************************************/
   /*if NOTEXIST flag is on						  */
   /***********************************************************************/
   if (set_reset_test_flag(&rtswitch,NOTEXIST,TEST) == TRUE) {
	return(FALSE);
   }

   /***********************************************************************/
   /*if BEFORE or AFTER is on, convert date into integer form		  */
   /***********************************************************************/
   if  (set_reset_test_flag(&rtswitch,BEFORE,TEST) == TRUE ||
	set_reset_test_flag(&rtswitch,AFTER,TEST) == TRUE ) {
	/*convert the input date into correct numbers.*/
	/*Both new and old format have date in the form of date returned from*/
	/*ffirst*/
	/*the input date is in the form of: yyyyyyymmmmddddd*/
	 yy =  (fileinfo_buf.write_date >> YRSHIFT & YRMASK) + LOYR;
	 mm =  fileinfo_buf.write_date >> MOSHIFT & MOMASK;
	 dd =  fileinfo_buf.write_date & DYMASK;
   }
   /*endif*/

   /***********************************************************************/
   /*if BEFORE flag is on						  */
   /***********************************************************************/
   if  (set_reset_test_flag(&rtswitch,BEFORE,TEST) == TRUE) {
       if  ( yy > td->before_year ) {
	    return(FALSE);
      }

      if (yy == td->before_year && mm > td->before_month) {
	   return(FALSE);
      }

      if (yy == td->before_year && mm == td->before_month &&
      dd > td->before_day) {
	   return(FALSE);
      }
   }
   /*endif*/

   /***********************************************************************/
   /*if AFTER flag is on						  */
   /***********************************************************************/
   if (set_reset_test_flag(&rtswitch,AFTER,TEST) == TRUE) {
      if (yy < td->after_year ) {
	   return(FALSE);
      }

      if (yy == td->after_year && mm < td->after_month) {
	   return(FALSE);
      }

      if (yy == td->after_year && mm == td->after_month && dd < td->after_day) {
	   return(FALSE);
      }
   }
   /*endif*/

   /***********************************************************************/
   /*if EARLIER or LATER is on, convert date time into integer form	  */
   /***********************************************************************/
   if  (set_reset_test_flag(&rtswitch,EARLIER,TEST) == TRUE ||
	set_reset_test_flag(&rtswitch,LATER,TEST) == TRUE) {
	/* convert the input time into correct numbers. 		  */
	/* Both new and old format have time in the form of date returned */
	/* from ffirst. 						  */
	/* the input time is in the form of: hhhhhmmmmmmsssss		  */
	 hh =  fileinfo_buf.write_time >> HRSHIFT & HRMASK;
	 mn =  fileinfo_buf.write_time >> MNSHIFT & MNMASK;
	 ss =  fileinfo_buf.write_time & SCMASK;
   }
   /*endif*/

   /***********************************************************************/
   /*if EARLIER flag is on						  */
   /***********************************************************************/
   if (set_reset_test_flag(&rtswitch,EARLIER,TEST) == TRUE) {
      if (hh > td->earlier_hour) {
	   return(FALSE);
      }

      if (hh == td->earlier_hour && mn > td->earlier_minute) {
	   return(FALSE);
      }

      if (hh == td->earlier_hour && mn == td->earlier_minute &&
      ss > td->earlier_second) {
	   return(FALSE);
      }
   }
   /*endif*/

   /***********************************************************************/
   /*if LATER flag is on						  */
   /***********************************************************************/
   if  (set_reset_test_flag(&rtswitch,LATER,TEST) == TRUE) {
       if (hh < td->later_hour) {
	   return(FALSE);
       }

       if (hh == td->later_hour && mn < td->later_minute) {
	   return(FALSE);
       }

       if (hh == td->later_hour && mn == td->later_minute &&
       ss < td->later_second) {
	   return(FALSE);
       }
   }
   /*endif*/

   /*************************************************************************/
   /* if Revised flag is on and fileinfo->attrib indicate file has not */
   /* been Revised, return FALSE					    */
   /*************************************************************************/
   if (set_reset_test_flag(&rtswitch,Revised,TEST) == TRUE) {
      if((retcode = attributes & 0x0020) != 0x0020) {
	return(FALSE);
      }
   }
   /*endif*/

   /***********************************************************************/
   /* if PROMPT and fileinfo->file_attrib indicate READONLY, or CHANGED*/
   /***********************************************************************/
      if  ((set_reset_test_flag(&rtswitch,PROMPT,TEST) == TRUE) &&
	  (((retcode = attributes & 0x0001) == 0x0001) ||
	  ((retcode = attributes & 0x0020) == 0x0020) ))
      {
	  /*call subroutine to ask whether the user really wants to restore */
	  retcode = readonly_or_changed(attributes,destd,finfo->fname,finfo->path);
	  if  (retcode == FALSE) {
	      return(FALSE);
	  }
	  /*endif*/
      }
      /*endif*/

   /***********************************************************************/
   /* if pass all the switch testing, return TRUE			  */
   /***********************************************************************/
   return(TRUE);

} /*end of subroutine switch_match */

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  check_flheader_old
/*
/*  DESCRIPTIVE NAME : Check the information in the file header of
/*		       the file to be restored.
/*
/*  FUNCTION: For old format only, Open the file to be restored, get
/*	      header informtion
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
int check_flheader_old
     ( finfo,f_name,f_date,f_time,f_attrib,f_len,
       file_seq_num,srcd,destd,infspec,inpath,dnumwant
     )

     struct file_info *finfo;
     unsigned char *f_name;	   /* name string */
     unsigned f_date;		  /* file's date */
     unsigned f_time;		  /* file's time */
     unsigned f_attrib; 	  /* file's attribute */
     unsigned long f_len;	  /* file length */
     unsigned int  file_seq_num;
     BYTE     srcd;
     BYTE     destd;
     BYTE     *infspec;
     BYTE     *inpath;
     unsigned int  *dnumwant;
{
     WORD  temp_dnumwant;
     WORD  numread;
     WORD  action;
     BYTE file_to_be_opened[15];
     BYTE string_to_be_separate[79];
     BYTE path[65];
     BYTE name[9];
     BYTE ext[4];
     BYTE spec[13];
     WORD  i;		 /*loop counter*/
     WORD retcode;
    int z;

   temp_dnumwant = *dnumwant;	/*to fix a bug that dosread change the
				value of dnumwant */


   /***********************************************************************/
   /*open the file to be restored as deny write and read access 	  */
   /***********************************************************************/
    strcpy(src_fname,f_name);
    file_to_be_opened[0] = srcd;
    file_to_be_opened[1] = ':';
    file_to_be_opened[2] = NULLC;
    strcat(file_to_be_opened,f_name);
    retcode = DOSOPEN( (char far *)&file_to_be_opened[0],
		      (unsigned far *)&src_file_handle,
		      (unsigned far *)&action,
		      (DWORD)0,    /*file size*/
		      0,		   /*file attribute*/
		      0x01,		   /*if file exist, open it*/
					   /*if file not exist, fail it*/
		      0x00c0,		   /*deny write, read only*/
		      (DWORD)0 );  /*reserved*/

    /*if open fail*/
    if (retcode != 0) {
       /****not able to restore the file****/
       display_it(NOT_ABLE_TO_RESTORE_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
       unexperror(retcode);
    }
    /*endif*/

   /***********************************************************************/
   /*read 128 bytes header information from the file into fheadold	  */
   /***********************************************************************/
    retcode = DOSREAD( src_file_handle,
		  (char far *)&fheadold,
		  HEADLEN,
		  (unsigned far *)&numread);
    /*if read fail*/
    if (retcode != 0 )
     {
      display_it(NOT_ABLE_TO_RESTORE_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
      unexperror(retcode);
     }
    /*end of if read fail */

    /*if the number of read is less than HEADLEN, return FALSE */
    if (numread != HEADLEN)
       return(FALSE);

			/* save disk  number */
    finfo->dnum = fheadold.disknum[1]* 10 + fheadold.disknum[0];

   if (fheadold.wherefrom[0] != '\\')
      return(FALSE);
   strcpy(string_to_be_separate,fheadold.wherefrom);
   separate(string_to_be_separate,path,name,ext,spec);

   /***********************************************************************/
   /* match the path and file spec.					  */
   /***********************************************************************/
   if
    (  pathmatch(inpath,path) == FALSE	  ||
       fspecmatch(infspec,spec) == FALSE
    )
    {
     *dnumwant = temp_dnumwant;
     return(FALSE);
    }

   /***********************************************************************/
   /*Store some information from filefindbuf into finfo 		  */
   /***********************************************************************/
       finfo->ftime = f_time;
       finfo->fdate = f_date;
       finfo->attrib = f_attrib;
       finfo->partsize = f_len;

   /***********************************************************************/
   /*Store filename and path information from fheadold into finfo	  */
   /***********************************************************************/
       strcpy(finfo->fname,spec);
       strcpy(finfo->path,path);

   /***********************************************************************/
   /* store some other information from fheadold to finfo		  */
   /***********************************************************************/
       if (fheadold.headflg == 0xff)
	  finfo->fflag= LAST_PART;
       else
	  finfo->fflag= 0;

    *dnumwant = temp_dnumwant;
    return(TRUE);

    /*return nothing*/

} /*end of subroutine*/


/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  readonly_or_changed
/*
/*  DESCRIPTIVE NAME : handle the situration that a read only file
/*		       or is found, or the file has been Revised.
/*
/*  FUNCTION: In the case that a readonly file is found, or the file
/*	      on the destination disk has been Revised since last backup,
/*	      this subroutine output a warning message to the user, and
/*	      prompt for user to enter yes or no depending on whether
/*	      the user wants to proceed restoring the file.
/*
/*
/********************* END OF SPECIFICATIONS ********************************/
#define CHECK_YES_NO	  0x6523				      /*;AN000;6*/
#define YES_NO_RESPTYPE   0xc1					      /*;AN000;6*/
#define YES 1							      /*;AN000;6*/

int readonly_or_changed(attrib,destd,fspec,fpath)

    unsigned attrib;
    unsigned char  destd;
    unsigned char  *fspec;
    unsigned char  *fpath;
{

     union REGS inregs, outregs;				      /*;AN000;6 Register set */
     WORD retcode;

    char file_to_be_chmode[MAXPATHF+2];
    DWORD dw = 0L;
    int z;

     sublist.value1 = (char far *)fspec;			      /*;AN000;6 */
     sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;		      /*;AN000;6 */
     sublist.max_width1 = (BYTE)strlen(fspec);			      /*;AN000;6 */
     sublist.min_width1 = sublist.max_width1;			      /*;AN000;6 */

     /***********************************************************************/
     /* if readonly, output msg and wait for user's prompt                  */
     /***********************************************************************/
     do 							      /*;AN000;6*/
      { 							      /*;AN000;6*/
	if((retcode = attrib & 0x0001) == 0x0001)
	 display_it(FILE_IS_READONLY,STND_ERR_DEV,1,YES_NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
	else
	 display_it(FILE_WAS_CHANGED,STND_ERR_DEV,1,YES_NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/


	inregs.x.ax = (unsigned)CHECK_YES_NO;			      /*;AN000;6*/
	inregs.h.dl = response_buff[0]; 			      /*;AN000;6*/
	int86(0x21,&inregs,&outregs);				      /*;AN000;6*/
	display_it(CRLF,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);   /*;AN000;6*/
      } 							      /*;AN000;6*/
      while (outregs.h.al > 1); 				      /*;AN000;6*/

     /***********************************************************************/
     /* if user's input is 'Y', return TRUE, else return FALSE              */
     /***********************************************************************/
     if (outregs.x.ax == YES)					      /*;AN000;6*/
      { file_to_be_chmode[0] = destd;
	file_to_be_chmode[1] = ':';
	file_to_be_chmode[2] = NULLC;
	strcat(file_to_be_chmode,fpath);
	if (strlen(fpath) != 1)  {
	   strcat(file_to_be_chmode,"\\");
      }
	strcat(file_to_be_chmode,fspec);
	/* change the file attribute to be 0, that is, reset it */
	if ((retcode = DOSSETFILEMODE((char far *)file_to_be_chmode,(unsigned) 0x00, dw)) != 0)
	 {
	    com_msg(retcode);
	    unexperror(retcode);
	 }
	return(TRUE);
     }
     else  {
	return(FALSE);
     }
     /* endif  */
} /* end of subroutine readonly_or_changed */

