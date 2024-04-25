
/*------------------------------
/* SOURCE FILE NAME:  RTNEW.C
/*------------------------------
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

extern BYTE control_flag;
extern BYTE control_flag2;
extern unsigned far *control_buf_pointer;
extern unsigned control_file_handle;				     /* !wrw */
extern unsigned src_file_handle;
unsigned int done_searching;					     /* !wrw */
unsigned int numentry;
extern struct  subst_list sublist;				      /*;AN000;6 Message substitution list */

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  search_src_disk_new
/*
/*  DESCRIPTIVE NAME : For new format only, search the entire disk for
/*		       matching files.
/*
/*  FUNCTION: Call subroutine findfirst_new and fnext_new to find all the
/*	      files which match the filename and file extension specified
/*	      in the command line.
/*
/*	      Whenever there is a file found, subroutine filematch
/*	      is called to match the file path, and file extension.
/*	      If file path and file extension match the specification,
/*	      subroutine switchmatch is called to match the file
/*	      attributes, file modes, time, and date, then file sequence
/*	      is checked.
/*
/*	      If the file matches all the specification, subroutine
/*	      restore_a_file is called to actually restore the file.
/*
/*
/********************* END OF SPECIFICATIONS ********************************/
void search_src_disk_new(dinfo,finfo,dheadold,dheadnew,fheadnew, /* wrw! */
		    srcd,destd,dnumwant,buf_size,
		    inpath,infname,infspec,control_buf_size,td)

     struct disk_info *dinfo;
     struct file_info *finfo;
     struct disk_header_new far *dheadnew;
     struct file_header_new far *fheadnew;
     struct disk_header_old *dheadold;
     BYTE   srcd;
     BYTE   destd;
     unsigned int  *dnumwant;  /*num of next disk*/
     unsigned long buf_size;
     unsigned *control_buf_size;
     unsigned char *inpath;
     unsigned char *infname;
     unsigned char *infspec;
     struct timedate *td;

{
     BYTE outstring[MAXPATH+MAXFSPEC];
     WORD  file_seq_num = 1;
     WORD  first_file_on_diskette = TRUE;
     BYTE file_tobe_opened[MAXFSPEC+2];
     WORD dnum;
     WORD found = FALSE;
     WORD far *dirptr;
     WORD far *flptr;
     WORD retcode;
     WORD  action;
     BYTE dir_path[MAXPATH];
     unsigned int  my_own_little_dirhandle = 0; 		     /* !wrw */
     union REGS qregs;						      /*;AN000;8*/
     int    x;							      /*;AN000;8*/

     done_searching = FALSE;					     /* !wrw */

   /***********************************************************************/
   /*search the file control.xxx and try to find the file with match file */
   /*name and file path 						  */
   /***********************************************************************/

   retcode = findfirst_new(finfo,&found,&done_searching,inpath,
	     infspec,&dirptr,&flptr,&numentry,dir_path);

   if (retcode != TRUE)
	return;

   /***********************************************************************/
   /*open file backup.xxx						  */
   /***********************************************************************/
     /*the current disk is one less than the disk num wanted*/
     dnum = *dnumwant -1;
     /*make the file name to be opened*/
     file_tobe_opened[0] = srcd;
     file_tobe_opened[1] = ':';
     file_tobe_opened[2] = NULLC;
     strcat(file_tobe_opened,"BACKUP.");
     file_tobe_opened[9] = (char)((dnum / 100) + '0');
     dnum = dnum % 100;
     file_tobe_opened[10] = (char)((dnum / 10) + '0');
     dnum = dnum % 10;
     file_tobe_opened[11] = (char)(dnum + '0');
     file_tobe_opened[12] = NULLC;

     retcode =
       DOSOPEN
	((char far *)&file_tobe_opened[0],
	 (unsigned far *)&src_file_handle,
	 (unsigned far *)&action,
	 (DWORD)0,
	 0,
	 0x01,
	 0x00c0,
	 (DWORD)0
	);


     if (retcode != NOERROR)
      {
	display_it(NOT_ABLE_TO_RESTORE_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);   /*;AN000;6*/
	unexperror(retcode);
      }

   /***********************************************************************/
   /*start loop to find next until no more file found			  */
   /***********************************************************************/
   do
    {
       /******************************************/
       /* if  it is system file, find next one	 */
       /******************************************/
       if
	 (
	   (strcmp(finfo->fname,"IBMBIO.COM")==0  ||
	    strcmp(finfo->fname,"IBMDOS.COM")==0  ||
	    strcmp(finfo->fname,"CMD.EXE")==0     ||
	    strcmp(finfo->fname,"COMMAND.COM")==0
	   )						   /*;AN003;*/
	   && strcmp(finfo->path,"\\")==0                  /*;AN003;*/
	 )
	{	 /*  Do not RESTORE the file */
	}
       else
	{

       /***********************************************************************/
       /*if there are any switches set in the input line, call switch match.   */
       /* if switchmatch returns FALSE, then find next file		      */
       /***********************************************************************/
       if ((set_reset_test_flag(&control_flag,SWITCHES,TEST) == FALSE) ||
	  (set_reset_test_flag(&control_flag,SWITCHES,TEST) == TRUE &&
	  ((retcode = switchmatch(finfo, srcd, destd, td)) == TRUE) ))
	{

	  /***********************************************************************/
	  /* if the diskette is out of sequence, then do not check the sequence  */
	  /* number of the 1st file.  Otherwise, check sequence number		 */
	  /***********************************************************************/
	     if (set_reset_test_flag(&control_flag2,OUTOF_SEQ,TEST) == TRUE &&
		 first_file_on_diskette == TRUE && finfo->dnum != file_seq_num)
	      {
	      }
	     else
	      {
		if (finfo->dnum != file_seq_num)
		 {
		   display_it(FILE_SEQUENCE_ERROR,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);	/*;AN000;6*/
		   unexperror(FILESEQERROR);
		 }

	     /***********************************************************************/
	     /*    msg: output one line of outstring on the screen		    */
	     /* 	     to confirm that a file has been restored sucessfully   */
	     /***********************************************************************/
		strcpy(outstring,finfo->path);
		if (strlen(finfo->path) != 1 )
		   strcat(outstring,"\\");

		strcat(outstring,finfo->fname);
		x = strlen(outstring);
		outstring[x] = CR;				      /*;AN000;6*/
		outstring[x+1] = LF;				      /*;AN000;6*/
		outstring[x+2] = NUL;				      /*;AN000;6*/
		qregs.x.ax = 0x4000;				      /*;AN000;6*/
		qregs.x.bx = 0x0001;				      /*;AN000;6*/
		qregs.x.cx = (WORD)strlen(outstring);		      /*;AN000;6*/
		qregs.x.dx = (unsigned int)&outstring[0];	      /*;AN000;6*/
		intdos(&qregs,&qregs);				      /*;AN000;6*/

	     /***********************************************************************/
	     /* restore the file						    */
	     /***********************************************************************/
		restore_a_file(finfo,dinfo,buf_size,control_buf_size,
			    fheadnew,dheadold,dheadnew,
			    srcd,destd,inpath,infname,infspec,dnumwant,&my_own_little_dirhandle);      /* wrw! */

		first_file_on_diskette = FALSE;

		if (set_reset_test_flag(&control_flag,SPLITFILE,TEST)==TRUE)
		 {
		   set_reset_test_flag(&control_flag,SPLITFILE,RESET);
		   /*do findfirst, the file found should be the splitted file*/

	/*	   retcode=  findfirst_new( finfo, &found, &done_searching, inpath, */
	/*	       infspec, &dirptr, &flptr,&numentry,dir_path );		    */
		 }

	      } /*end of if disk and file out of sequence*/

       } /*end of if switch match is ok */

      } /*end of if root directory and DOS system files */

   /***********************************************************************/
   /* if has not search to the end of the diskette, find next file	  */
   /***********************************************************************/
     if (done_searching == FALSE)
      {
       found = FALSE;
       retcode=  findnext_new(finfo,&found,&done_searching,inpath,infspec,
		   &dirptr,&flptr,&numentry,dir_path );

       }
     else
      break;

    }	/* end do while loop */
   while( retcode == TRUE);

   DOSCLOSE(src_file_handle);

return; 							     /* !wrw */

} /*end of subroutine*/

