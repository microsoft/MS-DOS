
/*----------------------------
/* SOURCE FILE NAME:   RTOLD.C
/*----------------------------
/*  0 */

#include "rt.h"
#include "rt1.h"
#include "rt2.h"
#include "restpars.h"                                                    /*;AN000;4*/
#include "string.h"
#include "dos.h"                                                      /*;AN000;2*/
#include "comsub.h"             /* common subroutine def'n */
#include "doscalls.h"
#include "error.h"

extern BYTE rtswitch;
extern BYTE control_flag;
extern BYTE control_flag2;
extern BYTE far *buf_pointer;
extern unsigned src_file_handle;
extern struct FileFindBuf filefindbuf;
extern struct  subst_list sublist;				      /*;AN000;6 Message substitution list */

/*****************  START OF SPECIFICATION  *********************************/
/*									    */
/*  SUBROUTINE NAME :  search_src_disk_old				    */
/*									    */
/*  DESCRIPTIVE NAME : For old format only, search the entire disk for	    */
/*		       matching files.					    */
/*									    */
/*  FUNCTION: Using find first and find next to find all the files	    */
/*	      which match the filename specified in the input		    */
/*	      cammand line.						    */
/*									    */
/*	      Whenever there is a file found, subroutine filespecmatch	    */
/*	      is called to match the file path, and file extension.	    */
/*	      If file path and file extension match the specification,	    */
/*	      subroutine switchmatch is called to match the file	    */
/*	      attributes, file modes, time, and date, then file sequence    */
/*	      number is checked.					    */
/*									    */
/*	      If the file matches all the specification, subroutine	    */
/*	      restore_a_file is called to actually restore the file.	    */
/*									    */
/*									    */
/********************** END OF SPECIFICATIONS *******************************/
void search_src_disk_old(dinfo,finfo,dheadold,dheadnew,fheadnew, /* wrw! */
		    srcd,destd,buf_size,dnumwant,
		    inpath,infname,infext,infspec,td)

     struct disk_info *dinfo;
     struct file_info *finfo;
     struct disk_header_old *dheadold;
     struct file_header_new far *fheadnew;
     struct disk_header_new far *dheadnew;
     BYTE   srcd;
     BYTE   destd;
     unsigned long buf_size;
     unsigned int *dnumwant;
     unsigned char *inpath;
     unsigned char *infname;
     unsigned char *infext;
     unsigned char *infspec;
     struct timedate *td;

{
     BYTE outstring[MAXPATH+MAXFSPEC];
     WORD    file_seq_num=1;
     WORD    first_file_on_diskette = TRUE;
     WORD    first_time_in_loop = TRUE;
     WORD return_code;
     DWORD partsize;
     unsigned int control_bufsize;
     BYTE temp_fname[MAXFNAME];
     BYTE temp_path[MAXPATH];
     WORD  temp_dirhandle;


    /*declaration for dosfindfirst */
    unsigned	dirhandle = 0xffff;	    /* directory handle 	    */
    unsigned	search_cnt = 1; 	    /* # of entries to find	    */
    unsigned	buf_len = sizeof(struct FileFindBuf);
    BYTE search_string[MAXPATHF+2];
    WORD retcode;
    /*end decleration for ffirst and fnext*/
    union REGS qregs;						      /*;AN000;8*/
    int    x;							      /*;AN000;8*/

/*************************************************************************/
/*  FIND THE FIRST FILE ON SOURCE					 */
/*************************************************************************/
  search_string[0] = srcd;
  search_string[1] = ':';
  search_string[2] = NULLC;
  strcat(search_string, infname);
  strcat(search_string, ".*");

retcode =				/* Find the 1st filename that	*/
  DOSFINDFIRST( 			/*   matches specified file spec*/
     ( char far * ) search_string,	/* File path name		*/
     ( unsigned far * ) &dirhandle,	/* Directory search handle	*/
     (unsigned) NOTV,			 /* Search attribute		*/
     (struct FileFindBuf far *) &filefindbuf,
     buf_len,				/* Result buffer length 	*/
     ( unsigned far * ) &search_cnt,	/* Number of entries to find	*/
     ( DWORD) 0
  );


/*************************************************************************/
/*  IF CANNOT FIND ANY FILES ON SOURCE, RETURN				 */
/*************************************************************************/
  if (retcode != 0)
     return;




/*************************************************************************/
/* start DO loop to find next until no more file found			 */
/*************************************************************************/
do
{
	/*if the directory found is a subdirectory, find next one*/
	if((retcode = filefindbuf.attributes & 0x0010) != 0x0010)
	{
	   /* SKIP BACKUPID */
	  if (strcmp(filefindbuf.file_name,BACKUPID) != 0)
	  {
	       if (first_time_in_loop == FALSE)
		 DOSCLOSE(src_file_handle);
	       else
		 first_time_in_loop = FALSE;

	       /*************************************************************************/
	       /*check_flheader_old: open and read file header, 			*/
	       /*************************************************************************/
	       strcpy(temp_fname,filefindbuf.file_name);
	       retcode = check_flheader_old( finfo, temp_fname,
		     filefindbuf.write_date, filefindbuf.write_time,
		     filefindbuf.attributes, filefindbuf.file_size,
		     file_seq_num, srcd, destd, infspec, inpath, dnumwant);

	    if (retcode == 0) {

	       /*************************/
	       /* SKIP SYSTEM FILES	*/
	    if ((set_reset_test_flag(&control_flag2,CPPC,TEST) == FALSE) &&
	       (strcmp(finfo->fname,"IBMBIO.COM")==0 ||
		strcmp(finfo->fname,"IBMDOS.COM")==0 ||
		strcmp(finfo->fname,"COMMAND.COM")==0 ))
	    {}
	    else {

	       /*************************************************************************/
	       /*if there is any switches set in the input line 			*/
	       /*switchmatch (this subroutine search the hard disk for the dest 	*/
	       /*************************************************************************/
	    if ((set_reset_test_flag(&control_flag,SWITCHES,TEST) == FALSE) ||
	       (set_reset_test_flag(&control_flag,SWITCHES,TEST) == TRUE &&
	       ((retcode = switchmatch(finfo, srcd, destd, td)) == TRUE) )) {

	       /*************************************************************************/
	       /*if dnum in fheadold.disknum is not 1 and is not in sequence, error    */
	       /*************************************************************************/
	    if (set_reset_test_flag(&control_flag2,OUTOF_SEQ,TEST) == TRUE &&
	       first_file_on_diskette == TRUE && finfo->dnum != 1)
	    {}
	    else
	    {
		if (finfo->dnum != 1 || finfo->dnum != file_seq_num)
		{
		   display_it(FILE_SEQUENCE_ERROR,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
		   unexperror(FILESEQERROR);
		}
		   /*endif*/
	       /*************************************************************************/
	       /* output msg to indicate which file is to be restored			*/
	       /*************************************************************************/
		/*outstring = inpath\infspec*/
		strcpy(outstring,finfo->path);
		if (strlen(finfo->path) != 1 )
		   strcat(outstring,"\\");

		strcat(outstring,finfo->fname);
		x = strlen(outstring);
		outstring[x] = CR;						  /*;AN000;6*/
		outstring[x+1] = LF;						  /*;AN000;6*/
		outstring[x+2] = NUL;						  /*;AN000;6*/
		qregs.x.ax = 0x4000;						  /*;AN000;6*/
		qregs.x.bx = 0x0001;						  /*;AN000;6*/
		qregs.x.cx = (WORD)strlen(outstring);				  /*;AN000;6*/
		qregs.x.dx = (unsigned int)&outstring[0];			  /*;AN000;6*/
		intdos(&qregs,&qregs);						  /*;AN000;6*/


	       /*************************************************************************/
	       /* call restore_a_file to restore the file				*/
	       /*************************************************************************/
		restore_a_file(finfo,dinfo,buf_size,&control_bufsize,
			  fheadnew,dheadold,dheadnew,
			  srcd,destd,inpath,infname,infspec,dnumwant,&dirhandle);

	       first_file_on_diskette = FALSE;

	       /*************************************************************************/
	       /* if the file just restored is a split file, and last file, exit loop	*/
	       /*************************************************************************/
	       if (set_reset_test_flag(&control_flag,SPLITFILE,TEST)==TRUE)
	       {
		  set_reset_test_flag(&control_flag,SPLITFILE,RESET);

		  if (dirhandle == 0xffff)
		    break;
		  else
		  {
		    retcode = 0;
		    continue;
		  }
	       } /*end of if file splitted*/


	    } /*end of if disk and file out of sequence*/
	    } /*end of switch match fail*/
	    } /*end of PC/DOS and it is system files*/
	    } /*end of if check file header is ok */
	  } /*end of if file name is not BACKUPID*/
	} /*end of if the directory found is a subdirectory*/

	    search_cnt = 1;

	    retcode =
	      DOSFINDNEXT
		(dirhandle,
		 (struct FileFindBuf far *)&filefindbuf,
		 buf_len,
		 (unsigned far *)&search_cnt
		);

}
while(retcode == 0);	/* END MAIN DO LOOP */

DOSCLOSE(src_file_handle);
/*************************************************************************/
/* if error during findnext, error exit 				 */
/*************************************************************************/
    if (retcode != ERROR_NO_MORE_FILES && retcode != 0)
    {
      com_msg(retcode);
      unexperror(retcode);
    }


    if (dirhandle != 0xffff)
    {
       if ((retcode = DOSFINDCLOSE(dirhandle)) != 0)
       {
	 com_msg(retcode);
	 unexperror(retcode);
       }
    }


return;
} /*end of subroutine*/
