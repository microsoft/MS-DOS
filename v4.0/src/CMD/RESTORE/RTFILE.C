
/*----------------------------
/* SOURCE FILE NAME: rtfile.c
/*----------------------------
/*  0 */

#include "rt.h"
#include "rt1.h"
#include "rt2.h"
#include "restpars.h"                                                 /*;AN000;4*/
#include "string.h"
#include "stdio.h"
#include "dos.h"                                                      /*;AN000;2*/
#include "comsub.h"             /* common subroutine def'n */
#include "doscalls.h"
#include "error.h"

extern BYTE rtswitch;
extern BYTE control_flag;
extern BYTE control_flag2;
extern BYTE filename[12];
extern BYTE far *buf_pointer;
extern char far *control_buf_pointer;
extern unsigned int  done_searching;				     /* !wrw */
extern unsigned int numentry;

unsigned dest_file_handle;
extern unsigned src_file_handle;
extern unsigned control_file_handle;				     /* !wrw */
BYTE dest_file_spec[MAXFSPEC+3];
extern struct FileFindBuf filefindbuf;
extern BYTE src_fname[MAXFNAME];
extern struct  subst_list sublist;				      /*;AN000;6 Message substitution list */

/*****************  START OF SPECIFICATION  *********************************/
/*									    */
/*  SUBROUTINE NAME :  restore_a_file					    */
/*									    */
/*  DESCRIPTIVE NAME : restore a file found onto the destination disk.	    */
/*									    */
/*  FUNCTION: This subroutine call open_dest_file to open the destination   */
/*	      file under the proper path.  If the path is not found, build  */
/*	      the path. 						    */
/*	      It then enter a loop to do reading the source disk and	    */
/*	      writing the destination disk until end of file.  If the file  */
/*	      is so large that it is backed up on more than one disk,	    */
/*	      the user is prompt to insert next diskette.  In this	    */
/*	      situation, the disk is checked for correct sequence number,   */
/*	      and then searched for the file to be continue restoring.	    */
/*	      after the file is completely restored, the time, date, and    */
/*	      attributes of the restored file is set to be the same as	    */
/*	      its original value.					    */
/*									    */
/********************** END OF SPECIFICATIONS *******************************/

void restore_a_file(finfo,dinfo,bufsize,control_bufsize,	 /* wrw! */
	       fheadnew,dheadold,dheadnew,
	       srcd,destd,inpath,infname,infspec,dnumwant,dirhandle)

    struct file_info *finfo;
    struct disk_info *dinfo;
    unsigned long bufsize;
    unsigned int *control_bufsize;
    struct file_header_new far *fheadnew;
    struct disk_header_old *dheadold;
    struct disk_header_new far *dheadnew;
    BYTE   srcd;
    BYTE   destd;
    unsigned char *inpath;
    unsigned char *infname;
    unsigned char *infspec;
    unsigned int  *dnumwant;
    unsigned int *dirhandle;
{
    BYTE c;
    BYTE temp_array1[4];
    BYTE temp_array2[4];
    BYTE temp_fname[MAXFSPEC];
    WORD  action;
    WORD  first_time=TRUE;

 /*declaration for dosfindfirst */
    WORD temp_dirhandle;
    WORD next_dirhandle;
    unsigned	attribute = NOTV;	    /*				    */
    unsigned	search_cnt = 1; 	    /* # of entries to find	    */
    unsigned	buf_len = sizeof(struct FileFindBuf);
    BYTE search_string[MAXPATHF+2];
 /*end decleration for ffirst and fnext*/

    BYTE outstring[MAXPATHF+2];
    WORD   retcode;
    DWORD iterate_num;
    DWORD i;			/* wrw! */
    WORD numread;
    WORD numwrite;
    DWORD int remainder;
    DWORD part_size;
    WORD file_seq_num = 1;  /*when this routine is called, the first
			       part of the file already get check against the
			       file sequence number */
    BYTE   file_tobe_opened[MAXFSPEC+2];
    WORD   found = FALSE;
    WORD   *dirptr;
    WORD   *flptr;
    WORD   read_count;
    DWORD  newptr;
    WORD   next_file_pointer;
    unsigned int dnum;
    DWORD  temp_offset;

    BYTE   my_own_dirpath[MAXPATH];
    int    x;							      /*;AN000;8*/
    union REGS qregs;						      /*;AN000;8*/

	/*build a string of destination file specification*/
	dest_file_spec[0] = destd;
	dest_file_spec[1] = ':';
	dest_file_spec[2] = NULLC;
	strcat(dest_file_spec,finfo->fname);

	/*********************************************************************/
	/* Open destination file, and chdir the the path where the dest file */
	/* going to reside.  If the path is not there, then create the path. */
	/* If file sharing error, exit this routine			     */
	/*********************************************************************/
		/*open_dest_file*/
	retcode=open_dest_file(finfo,destd);

		/*if file sharring error, exit this subroutine*/
	if (retcode == FALSE)
	  display_it(FILE_CREATION_ERROR,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
	 else
	 {
	    /*setflag PARTIAL*/
	    set_reset_test_flag(&control_flag,PARTIAL,SET);

	    /*********************************************************************/
	    /* This loop will be processed once for each part of the source file */
	    /*********************************************************************/
	    for ( ; ; )
	     {

	       /*********************************************************************/
	       /* compare source file size and buf size to determine the	    */
	       /*	    iteration of reading and writing			    */
	       /*********************************************************************/
	       part_size = finfo->partsize;
	       /*if old*/
	       if (set_reset_test_flag(&control_flag,OLDNEW,TEST)==TRUE)
		part_size = part_size - HEADLEN;

	       iterate_num = part_size / bufsize;
	       /*if remain of of filesize/bufsize != 0, add 1 to iterate_num*/
		    remainder = part_size % bufsize;
		    if (remainder > 0)
		       ++iterate_num;

	       /*********************************************************************/
	       /*loop through each of the iteration				    */
	       /*********************************************************************/
	       for (i = 1; i <= iterate_num; ++i)
		{
		   /***************************************************************/
		   /* if old format, read from the beginning of the source file   */
		   /***************************************************************/
		   /*read source file (new and old have different pointer)*/
		   if (set_reset_test_flag(&control_flag,OLDNEW,TEST) == TRUE)
		    {
		      retcode = DOSREAD( src_file_handle,
				(char far *)&buf_pointer[0],
				(unsigned)bufsize,
				(unsigned far *)&numread);

		      if (retcode != 0)
		       {
			com_msg(retcode);
			unexperror(retcode);
		       }
		    }
		   else
		    { /*new format*/
		   /***************************************************************/
		   /* if new format, search backup.xxx for the file to be restored*/
		   /* and read it.						  */
		   /***************************************************************/
		      temp_offset = finfo->offset + bufsize * (i - 1);
		      retcode =
			DOSCHGFILEPTR
			  (src_file_handle,
			   (DWORD) temp_offset,
			   (unsigned) 0,
			   (DWORD far *) &newptr
			  );

		      if (i == iterate_num)
			{
			  part_size = part_size - bufsize * (iterate_num -1);
			  retcode =
			   DOSREAD
			     ( src_file_handle,
			       (char far *)&buf_pointer[0],
			       (unsigned)part_size,
			       (unsigned far *)&numread
			     );
			}
		       else
			{
			  retcode =
			   DOSREAD
			     (src_file_handle,
			      (char far *)&buf_pointer[0],
			      (unsigned)bufsize,
			      (unsigned far *)&numread
			     );

			}  /*end of i == iterate_num */
		}  /*end of new format */

		   /*************************************************************/
		   /* write to dest file					*/
		   /*************************************************************/
		    retcode =
		     DOSWRITE
		       (dest_file_handle,
			(char far *)&buf_pointer[0],
			(unsigned) numread,
			(unsigned far *) &numwrite
		       );

		   /*************************************************************/
		   /*if the num of bytes read != num of bytes write		*/
		   /* call dos_write_error to find out why			*/
		   /*************************************************************/
		   if (numread != numwrite)
		    dos_write_error(bufsize,destd);
	       }
	       /*end iteration loop*/

	       /*****************************************************************/
	       /*if the file is system file, turn RTSYSTEM on			*/
	       /*****************************************************************/
	       if (strcmp(finfo->fname,"IBMBIO.COM")==0 ||
		   strcmp(finfo->fname,"IBMDOS.COM")==0 ||
		   strcmp(finfo->fname,"COMMAND.COM")==0 )
		   set_reset_test_flag(&control_flag2,RTSYSTEM,SET);


	       /*****************************************************************/
	       /*if the source file header indicate that this is the last disk, */
	       /* that is,it is completely copied, then exit the for loop	*/
	       /*****************************************************************/
	       if (set_reset_test_flag(&finfo->fflag,LAST_PART,TEST) == TRUE)
		 break;  /* exit the loop */

	       /*****************************************************************/
	       /*The logic flow come here when the file expanded into next disk.*/
	       /* if old format, close the file handle and find handle		*/
	       /* if new format, close src file 				*/
	       /*****************************************************************/
	       if (set_reset_test_flag(&control_flag,OLDNEW,TEST) == TRUE)
		{ /*close source file*/
		  DOSCLOSE(src_file_handle);

		  if (first_time == TRUE)
		   {  temp_dirhandle = *dirhandle;
		      first_time = FALSE;
		      retcode = DOSFINDCLOSE(temp_dirhandle);
		   }
		}
	       else
		{
		  DOSCLOSE(src_file_handle);
		  DOSCLOSE(control_file_handle);		      /* !wrw */
		  control_file_handle = 0xffff; 		      /* !wrw */
		}

	       /*****************************************************************/
	       /* output message for user to insert another diskette		*/
	       /*	   "strike any key when ready"                          */
	       /*	   with response type 4 (wait for a key to be hit)	*/
	       /*****************************************************************/

		 if (control_file_handle != 0xffff)			      /* !wrw */
		  {							      /* !wrw */
		   DOSCLOSE(control_file_handle);			      /* !wrw */
		   control_file_handle = 0xffff;			      /* !wrw */
		  }							      /* !wrw */

	       printf("\n");
	       temp_array1[0] = (char) (*dnumwant / 10) + '0';
	       temp_array1[1] = (char) (*dnumwant % 10) + '0';
	       temp_array1[2] = NULLC;
	       temp_array2[0] = srcd;
	       temp_array2[1] = NULLC;

	       sublist.value1 = (char far *)temp_array1;	      /*;AN000;6 */
	       sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;       /*;AN000;6 */
	       sublist.max_width1 = (BYTE)strlen(temp_array1);	      /*;AN000;6 */
	       sublist.min_width1 = sublist.max_width1; 	      /*;AN000;6 */

	       sublist.value2 = (char far *)temp_array2;	      /*;AN000;6 */
	       sublist.flags2 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;       /*;AN000;6 */
	       sublist.max_width2 = (BYTE)strlen(temp_array2);	      /*;AN000;6 */
	       sublist.min_width2 = sublist.max_width2; 	      /*;AN000;6 */

	       display_it(INSERT_SOURCE_DISK,STND_ERR_DEV,2,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
	       display_it(PRESS_ANY_KEY,STND_ERR_DEV,0,ANY_KEY_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/

					 /* If single drive system, eliminates double prompting */
					 /* for user to "Insert diskette for drive %1" */
	       qregs.x.ax = SETLOGICALDRIVE;			      /*;AN000;8*/
	       qregs.h.bl = srcd;				      /*;AN000;8*/
	       intdos(&qregs,&qregs);				      /*;AN000;8*/

		/**************************************************/
		/**************************************************/
	       if (set_reset_test_flag(&control_flag,OLDNEW,TEST) == TRUE)
		 check_bkdisk_old(dheadold,dinfo,srcd,dnumwant);
		else
		 check_bkdisk_new(dheadnew,dinfo,srcd,dnumwant,control_bufsize);

	       /*at this point a real backup diskette which is in correct sequence
	       number has been found.  In the case of new format, the file
	       CONTROL.xxx is opened.*/

	       /*****************************************************************/
	       /*increament file sequence number				*/
	       /*****************************************************************/
	       file_seq_num = file_seq_num + 1;

	       /*****************************************************************/
	       /* search the new disk for next part of the file 		*/
	       /*****************************************************************/
	       if (set_reset_test_flag(&control_flag,OLDNEW,TEST) == TRUE)
		{    /**************************************************************/
		     /* if old format,						   */
		     /*DosFindFirst:find the first file on the diskette (non-vol id*/
		     /*entry)							   */
		     /**************************************************************/
		       search_string[0] = srcd;
		       search_string[1] = ':';
		       search_string[2] = NULLC;
		       strcat(search_string, src_fname);

		       next_dirhandle = 0xffff;   /* directory handle		  */

		     retcode =					/* Find the 1st filename that	*/
		       DOSFINDFIRST(				/*   matches specified file spec*/
			  (char far * ) search_string,		/* File path name	  */
			  (unsigned far * ) &next_dirhandle,	/* Directory search    */
			  attribute,				/* Search attribute	  */
			  (struct FileFindBuf far *) &filefindbuf,
			  buf_len,				/* Result buffer length   */
			  (unsigned far * ) &search_cnt,	/* Number of entries to find*/
			  (DWORD) 0
		       );

		     if (retcode != 0)
		      {
			display_it(NOT_ABLE_TO_RESTORE_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
			unexperror(retcode);
		      }


		     /*if the directory found is a subdirectory, find next one*/
		     while((retcode = filefindbuf.attributes & SUBDIR) == SUBDIR)
		     {
			search_cnt = 1;
			retcode = DOSFINDNEXT(next_dirhandle,
			     (struct FileFindBuf far *)&filefindbuf,
			     buf_len,
			     (unsigned far *)&search_cnt);

			if (retcode != 0)
			{
			  display_it(NOT_ABLE_TO_RESTORE_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
			  unexperror(retcode);
			}

		     } /*end while */

		  retcode = DOSFINDCLOSE(next_dirhandle);

		  /*****************************************************************/
		  /* check_flheader_old: open and read file header, check dnum	   */
		  /*	 of the file, and fill fheadold and finfo with correct info*/
		  /*****************************************************************/
		  strcpy(temp_fname,filefindbuf.file_name);
		  retcode =
		   check_flheader_old
		     ( finfo, temp_fname,
		       filefindbuf.write_date, filefindbuf.write_time,
		       filefindbuf.attributes, filefindbuf.file_size,
		       file_seq_num, srcd, destd, infspec, inpath, dnumwant
		     );

		  if (retcode != 0)
		   {
		     display_it(NOT_ABLE_TO_RESTORE_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
		     unexperror(retcode);
		   }

		  /*****************************************************************/
		  /* check file sequence number.				   */
		  /*****************************************************************/
		  if (finfo->dnum != file_seq_num)
		   { display_it(FILE_SEQUENCE_ERROR,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
		     unexperror(FILESEQERROR);
		   }

	       }
	       else
	       { /*new format*/
		  /**********************************************/
		  /*   Find the file on the CONTROL.xxx first	*/
		  /**********************************************/

		  /* findfirst_new on the new diskette using the filename.??? */
		  retcode =
		   findfirst_new
		    ( finfo, &found, &done_searching,
		      finfo->path, finfo->fname, (WORD far **) &dirptr,    /* wrw! */
		      (WORD far **) &flptr, &numentry, my_own_dirpath
		    );							   /* wrw! */

		  while (retcode != 0 )
		   {
		     display_it(NOT_ABLE_TO_RESTORE_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
		     unexperror(CREATIONERROR);
		   }

		  if (finfo->dnum != file_seq_num)
		   { display_it(FILE_SEQUENCE_ERROR,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
		     unexperror(FILESEQERROR);
		   }

		  /**************************************************************/
		  /* open file backup.xxx					*/
		  /**************************************************************/
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
		       ( (char far *)&file_tobe_opened[0],
			 (unsigned far *)&src_file_handle,
			 (unsigned far *)&action,
			 (DWORD)0,		/*file size*/
			 0,			/*file attribute*/
			 0x01,			/*if file exist, open it*/
						/*if file not exist, fail it*/
			 0x00c0,		/*deny write, read only*/
			 (DWORD)0
		       );  /*reserved*/

		    if (retcode != 0)
		     { display_it(NOT_ABLE_TO_RESTORE_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
		       unexperror(retcode);
		     }

	       }
	       /*end of if new format*/

	       /*assume the file to be continue definatly will be found on the
		second diskette because the dnum of the file already gets checked
		in check_bkdisk_old or check_bkdisk_new*/

	       /*set flag to be SPLITFILE*/
	       set_reset_test_flag(&control_flag,SPLITFILE,SET);

	    /*******************************************/
	    /* Display name of file is to be restored  */
	    /*******************************************/
	     /*outstring = inpath\infspec*/
	     strcpy(outstring,finfo->path);
	     if (strlen(finfo->path) != 1 )
		strcat(outstring,"\\");

	     strcat(outstring,finfo->fname);
	     x = strlen(outstring);
	     outstring[x] = CR; 				      /*;AN000;6*/
	     outstring[x+1] = LF;				      /*;AN000;6*/
	     outstring[x+2] = NUL;				      /*;AN000;6*/
	     qregs.x.ax = 0x4000;				      /*;AN000;6*/
	     qregs.x.bx = 0x0001;				      /*;AN000;6*/
	     qregs.x.cx = (WORD)strlen(outstring);		      /*;AN000;6*/
	     qregs.x.dx = (unsigned int)&outstring[0];		      /*;AN000;6*/
	     intdos(&qregs,&qregs);				      /*;AN000;6*/

	     /*loop back to do the read source and write dest until finfo->fflag
	     indicate that this is the last part of file*/
	    }	 /*end of for loop*/

	    /************************************************************************/
	    /*set_attributes_and_close: set the attributes and last write date/time */
	    /*of the file just restore to be like those of the backup file	    */
	    /************************************************************************/
	    set_attributes_and_close(finfo,destd);

	    /************************************************************************/
	    /* If old format and the file split, then find next matching file	    */
	    /************************************************************************/
	    if (set_reset_test_flag(&control_flag,SPLITFILE,TEST)==TRUE &&
		set_reset_test_flag(&control_flag,OLDNEW,TEST) == TRUE)
	     {
	       /*search string used for DisFindFirst = srcd:infname.**/
	       /*DosFindFirst:find the first file on the diskette (non-vol id entry)
		      using the search string*/
		 search_string[0] = srcd;
		 search_string[1] = ':';
		 search_string[2] = NULLC;
		 strcat(search_string, infname);
		 strcat(search_string, ".*");

	       temp_dirhandle = 0xffff;
	       retcode =			       /* Find the 1st filename that */
		 DOSFINDFIRST(			       /*   matches specified file spec*/
		    ( char far * ) search_string,      /* File path name */
		    ( unsigned far * ) &temp_dirhandle, /* Directory search handle*/
		    (unsigned) NOTV,		      /* Search attribute  */
		    (struct FileFindBuf far *) &filefindbuf,
		    buf_len,			       /* Result buffer length	       */
		    ( unsigned far * ) &search_cnt,    /* Number of entries to find    */
		    ( DWORD) 0
		 );

	       /*if not found return*/
		 if (retcode != 0)
		    temp_dirhandle = 0xffff;
		  else
		   {

		     /*if the directory found is a subdirectory, find next one*/
		     while((retcode = filefindbuf.attributes & SUBDIR) == SUBDIR)
		      {
			search_cnt = 1;
			retcode = DOSFINDNEXT(temp_dirhandle,
			     (struct FileFindBuf far *)&filefindbuf,
			     buf_len,
			     (unsigned far *)&search_cnt);
			if (retcode != 0)
			  temp_dirhandle = 0xffff;
		      } /*end while */

		    if(strcmp(filefindbuf.file_name,BACKUPID)==0 ||
		       strcmp(filefindbuf.file_name,src_fname)==0 )
		     {
		       retcode =DOSFINDNEXT(temp_dirhandle,
			   (struct FileFindBuf far *)&filefindbuf,
			   buf_len,
			   (unsigned far *)&search_cnt);

		       if (retcode != 0)
			  temp_dirhandle = 0xffff;

		       else
			{
			  if(strcmp(filefindbuf.file_name,BACKUPID)==0 ||
			     strcmp(filefindbuf.file_name,src_fname)==0 )
			   {
			     retcode =DOSFINDNEXT(temp_dirhandle,
				      (struct FileFindBuf far *)&filefindbuf,
				      buf_len,
				      (unsigned far *)&search_cnt);

			     if (retcode != 0)
				temp_dirhandle = 0xffff;
			   }

			} /*end of the rc is 0 */
		     } /*end of if strcomp is sucessful*/

		   }
		 *dirhandle = temp_dirhandle;

	     }	/*end of if the file was splitted */


	    /****************************************************************/
	    /*set FOUNDFILE flag					    */
	    /****************************************************************/
	    set_reset_test_flag(&control_flag,FOUND,SET);
	 } /* end of if open destination file get file sharing error */

} /*end of restore_a_file subroutine*/
