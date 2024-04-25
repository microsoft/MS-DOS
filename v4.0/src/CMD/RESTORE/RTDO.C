
/*------------------------------------
/* SOURCE FILE NAME: RTDO.C
/*------------------------------------
/*  0 */

#include "rt.h"
#include "rt1.h"
#include "rt2.h"
#include "restpars.h"                                                 /*;AN000;4*/
#include "direct.h"
#include "stdio.h"
#include "string.h"
#include "dos.h"                                                      /*;AN000;2*/
#include "comsub.h"             /* common subroutine def'n */
#include "doscalls.h"
#include "error.h"

BYTE		   *buf_pointer;
unsigned	   control_file_pointer;
unsigned	   src_file_handle;
struct FileFindBuf filefindbuf;
struct FileFindBuf dfilefindbuf;
BYTE	      far  *control_buf_pointer;
unsigned int	   control_bufsize;				       /* !wrw */

extern unsigned    char srcddir[MAXPATH+3];
extern unsigned    char rtswitch;
extern unsigned    char control_flag;
extern unsigned    char control_flag2;
extern unsigned    control_file_handle; 			       /* !wrw */
extern struct	   subst_list sublist;				      /*;AN000;6 Message substitution list */

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  Dorestore
/*
/*  DESCRIPTIVE NAME : Searching all disks and restore the matching files.
/*
/*  FUNCTION: This routine does the following:
/*	      1. Initialize the buffer
/*	      2. Change directory to the one which will hold the first
/*		 files to be restored.
/*	      3. If the source drive is removable
/*		 Ouput the message to the screen for user to insert a
/*		 diskette and hit a key when ready.
/*	      4. If the target drive is removable
/*		 Ouput the message to the screen for user to insert a
/*		 diskette and hit a key when ready.
/*	      5. Check whether the diskette contains old or new data
/*		 format.
/*	      6. ouput "file were backup xx-xx-xx"
/*
/*	      For each diskette, do the following:
/*	      5. Call check_bkdisk_old or check_bkdisk_new to check whethe
/*		 it is a backup diskette and whether it is in correct
/*		 sequence number.
/*	      6. Call search_src_disk_old or search_src_disk_new to search
/*		 the entire diskette to find matching files and
/*		 restore them.
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
void dorestore(srcd,destd,inpath,infname,infext,infspec,dt) /* wrw! */
BYTE srcd;
BYTE destd;
BYTE *inpath;
BYTE *infname;
BYTE *infext;
BYTE *infspec;
struct timedate *dt;
{
    BYTE string[MAXPATH+2];
    struct disk_header_old dheadold;
    struct disk_header_new dheadnew;
    struct file_header_new fheadnew;
    struct disk_info dinfo;
    struct file_info finfo;
    unsigned int  control_bufsize;
    unsigned dirlen = MAXPATH;
    WORD dyear;
    WORD dmonth;
    WORD dday;

    BYTE c;
    BYTE done;							      /*;AN000;p????*/
    BYTE path_to_be_chdir[MAXPATH];
    WORD srcd_num;
    BYTE temp_srcddir[MAXPATH];
    unsigned int dnumwant = 1;
    DWORD bufsize;
    BYTE temp_array1[4];  /*temparary array to build parameters for substitution list */
    BYTE temp_array2[4];

    /*declaration for dosfindfirst */
    unsigned	dirhandle = 1;
    unsigned	attribute = NOTV;
    unsigned	search_cnt = 1; 	    /* # of entries to find */
    unsigned	buf_len = sizeof(struct FileFindBuf);
    BYTE	search_string[MAXPATHF+2];
    WORD retcode;
    /*end decleration for ffirst and fnext*/

    union   REGS   qregs;					      /*;AN000;8*/
    DWORD	date;						      /*;AN000;6*/

   /****************************************************************/
   /* change dest drive directory to the one which will hold the   */
   /* first file to be restored 				   */
   /****************************************************************/
   string[0] = destd;
   string[1] = ':';
   string[2] = NULLC;
   strcat(string,inpath);
   /*if chdir sucessful, save the directory in finfo->curdir*/
   /*if fail, the path is not exist, and needs to be rebuild*/
   if(chdir(string)==0)
      strcpy(finfo.curdir,inpath);

   /*****************************************************************/
   /*if the source disk is hard disk get the current dir of the srcd*/
   /* chdir the source disk to be in \backup directory		    */
   /*****************************************************************/
   /**************************************/
   /* if the source disk is a hard disk  */
   /**************************************/
   /*  save current directory of source disk to be reset back later */
   /*  convert character srcd into integer form  */
   /**************************************/

   srcd_num = (WORD)(srcd - 'A' +1);

   /**************************************/
   /*  get current directory of srcd (DosQCurDir) */
   /**************************************/
   if ((retcode = DOSQCURDIR(srcd_num,(char far *) srcddir,(unsigned far *)&dirlen)) != 0)
     {
      display_it(INVALID_DRIVE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
      usererror(INVALIDDRIVE);
     }

   temp_srcddir[0] = srcd;
   temp_srcddir[1] = ':';
   temp_srcddir[2] = NULLC;
   if (strlen(srcddir) != 1)
       strcat(temp_srcddir,"\\");
   strcat(temp_srcddir,srcddir);
   strcpy(srcddir,temp_srcddir);

   path_to_be_chdir[0] = srcd;
   path_to_be_chdir[1] = ':';
   path_to_be_chdir[2] = NULLC;
   if (set_reset_test_flag(&control_flag2,SRC_HDISK,TEST) == TRUE)
     strcat(path_to_be_chdir,"\\BACKUP");
   else
     strcat(path_to_be_chdir,"\\");

   if(chdir(path_to_be_chdir)!=0)
    { display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
      usererror(NOBACKUPFILE);
    }

   /*****************************************************************/
   /* Identify whether the inserted diskette is a old format backup */
   /* diskette or a new format backup diskette			    */
   /* BACKUP.@@@ or BACKUP.xxx with xxx numeric characters has	    */
   /* to be on the diskette					    */
   /*****************************************************************/
   search_string[0] = srcd;
   search_string[1] = ':';
   search_string[2] = NULLC;
   strcat(search_string, "BACKUP*.???");

		/***********************/
		/* Find the first file */
		/***********************/
	done = FFALSE;						      /*;AN000;p????*/

	retcode =						      /*;AN000;p????*/
	  DOSFINDFIRST						      /*;AN000;p????*/
	   (							      /*;AN000;p????*/
	     (char far *)search_string, 			      /*;AN000;p????*/
	     (unsigned far *)&dirhandle,			      /*;AN000;p????*/
	     attribute, 					      /*;AN000;p????*/
	     (struct FileFindBuf far *)&filefindbuf,		      /*;AN000;p????*/
	     buf_len,						      /*;AN000;p????*/
	     (unsigned far *)&search_cnt,			      /*;AN000;p????*/
	     (DWORD) 0						      /*;AN000;p????*/
	  );							      /*;AN000;p????*/

	if (retcode != NOERROR) 				      /*;AN000;p????*/
	 { display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;p????*/
	   usererror(NOBACKUPFILE);				      /*;AN000;p????*/
	 }							      /*;AN000;p????*/

		/*****************************/
		/*  Skip over subdirectories */
	while((retcode = filefindbuf.attributes & SUBDIR) == SUBDIR)  /*;AN000;p????*/
	 {							      /*;AN000;p????*/
	   search_cnt = 1;					      /*;AN000;p????*/

	   retcode =						      /*;AN000;p????*/
	     DOSFINDNEXT					      /*;AN000;p????*/
	      ( dirhandle,					      /*;AN000;p????*/
		(struct FileFindBuf far *)&filefindbuf, 	      /*;AN000;p????*/
		buf_len,					      /*;AN000;p????*/
		(unsigned far *)&search_cnt			      /*;AN000;p????*/
	      );						      /*;AN000;p????*/

	   if (retcode != NOERROR)				      /*;AN000;p????*/
	    { display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);   /*;AN000;p????*/
	      usererror(NOBACKUPFILE);				      /*;AN000;p????*/
	    }							      /*;AN000;p????*/
	 }							      /*;AN000;p????*/

		/****************************************/
		/*  Loop through looking at file names	*/
		/****************************************/
	 do							       /*;AN000;p????*/
	  {		 /*  Is it old BACKUP ??? */		       /*;AN000;p????*/
	    if (strcmp(filefindbuf.file_name,BACKUPID)==0)	       /*;AN000;p????*/
	      { 						       /*;AN000;p????*/
	       set_reset_test_flag(&control_flag,OLDNEW,SET);	       /*;AN000;p????*/
	       done = TTRUE;					       /*;AN000;p????*/
	      } 						       /*;AN000;p????*/
	     else						       /*;AN000;p????*/
	      { 	 /*  Is it new BACKUP ??? */		       /*;AN000;p????*/
	       if ((filefindbuf.file_name[6] == '.') &&                /*;AN000;p????*/
		   (filefindbuf.file_name[7] >= '0') &&                /*;AN000;p????*/
		   (filefindbuf.file_name[7] <= '9') &&                /*;AN000;p????*/
		   (filefindbuf.file_name[8] >= '0') &&                /*;AN000;p????*/
		   (filefindbuf.file_name[8] <= '9') &&                /*;AN000;p????*/
		   (filefindbuf.file_name[9] >= '0') &&                /*;AN000;p????*/
		   (filefindbuf.file_name[9] <= '9') &&                /*;AN000;p????*/
		   (filefindbuf.file_name[10] == NULLC) )	       /*;AN000;p????*/
		 {						       /*;AN000;p????*/
		   set_reset_test_flag(&control_flag,OLDNEW,RESET);    /*;AN000;p????*/
		   init_control_buf((unsigned long)0,&control_bufsize);/*;AN000;p????*/
		   done = TTRUE;				       /*;AN000;p????*/
		 }						       /*;AN000;p????*/
	      }

	    if (!done)
	      do
	       {							 /*;AN000;p????*/
		 search_cnt = 1;					 /*;AN000;p????*/
		 retcode =						 /*;AN000;p????*/
		   DOSFINDNEXT						 /*;AN000;p????*/
		    ( dirhandle,					 /*;AN000;p????*/
		      (struct FileFindBuf far *)&filefindbuf,		 /*;AN000;p????*/
		      buf_len,						 /*;AN000;p????*/
		      (unsigned far *)&search_cnt			 /*;AN000;p????*/
		    );							 /*;AN000;p????*/

		 if (retcode != NOERROR)			      /*;AN000;p????*/
		  { display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;p????*/
		    usererror(NOBACKUPFILE);			      /*;AN000;p????*/
		  }						      /*;AN000;p????*/

	       } /* end while */				      /*;AN000;p????*/
	       while(filefindbuf.attributes & SUBDIR == SUBDIR);

	  } /* end DO loop */					      /*;AN000;p????*/
	  while (!done);					    /*;AN000;p????*/


   retcode = DOSFINDCLOSE(dirhandle);

   /***************************************/
   /* Display the date of the backup disk */
   /***************************************/
   dyear =  (filefindbuf.write_date >> YRSHIFT & YRMASK) + LOYR;
   dmonth =  filefindbuf.write_date >> MOSHIFT & MOMASK;
   dday =  filefindbuf.write_date & DYMASK;
   date = dyear + (dday*16777216) + (dmonth*65536);		      /*;AN000;6*/

   sublist.value1 = (char far *)date;				      /*;AN000;6*/
   sublist.flags1 = LEFT_ALIGN + DATE_MDY_4;			      /*;AN000;6*/
   sublist.max_width1 = (BYTE)10;				      /*;AN000;6*/
   sublist.min_width1 = sublist.max_width1;			      /*;AN000;6*/
   display_it(FILES_WERE_BACKUP_ON,STND_OUT_DEV,1,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/

   /*****************************************************************/
   /*start a loop to check and restore each diskette		    */
   /*****************************************************************/
   initbuf(&bufsize);						     /* !wrw */

   for (;;)
    {

     /*****************************************************************/
     /* check whether the inserted diskette is a backup diskette      */
     /*****************************************************************/
     /*if old, check_bkdisk_old else check_bkdisk_new*/

     if (set_reset_test_flag(&control_flag,OLDNEW,TEST) == TRUE)
       check_bkdisk_old(&dheadold, &dinfo, srcd, &dnumwant);
      else
       check_bkdisk_new((struct disk_header_new far *)&dheadnew, &dinfo, srcd, &dnumwant,&control_bufsize);

     /*****************************************************************/
     /* At this point a real backup diskette which is in correct sequence number */
     /* has been found.  In the case of new format, the file CONTROL.xxx is open.*/
     /*****************************************************************/
     /* restored the diskette					      */
     /*****************************************************************/

     /*if old*/
     if (set_reset_test_flag(&control_flag,OLDNEW,TEST) == TRUE)
	search_src_disk_old(&dinfo,&finfo,&dheadold,(struct disk_header_new far *)&dheadnew,
		(struct file_header_new far *)&fheadnew,srcd,destd,bufsize,&dnumwant,
		inpath,infname,infext,infspec,dt);
     else
	search_src_disk_new(&dinfo,&finfo,&dheadold,(struct disk_header_new far *)&dheadnew,
		(struct file_header_new far *)&fheadnew,srcd,destd,&dnumwant,bufsize,
		inpath,infname,infspec,&control_bufsize,dt);

     printf("\n");
     set_reset_test_flag(&control_flag2,OUTOF_SEQ,RESET);
     /************************************************************************/
     /*if ( bk disk is not the last one && (the file spec is WILDCARD or file*/
     /*not found yet or SUB flag in rtswitches is on)), then prompt for user */
     /*to insert another diskette and loop again.			     */
     /************************************************************************/
     if ((dinfo.dflag!=0xff) &&
	((set_reset_test_flag(&control_flag,WILDCARD,TEST) == TRUE) ||
	 (set_reset_test_flag(&control_flag,FOUND,TEST) == FALSE) ||
	 (set_reset_test_flag(&rtswitch,SUB,TEST) == TRUE)))
       {
	  /**********************************************************/
	  /* output message for user to insert another diskette and */
	  /*	      "strike any key when ready"                   */
	  /*	      with response type 4 (wait for a key to be hit)  */
	  /**********************************************************/

	  if (control_file_handle != 0xffff)			       /* !wrw */
	   {							       /* !wrw */
	    DOSCLOSE(control_file_handle);			       /* !wrw */
	    control_file_handle = 0xffff;			       /* !wrw */
	   }							       /* !wrw */

	  temp_array1[0] = (char)((dnumwant / 10) + '0');
	  temp_array1[1] = (char)((dnumwant % 10) + '0');
	  temp_array1[2] = NULLC;
	  temp_array2[0] = srcd;
	  temp_array2[1] = NULLC;

	  sublist.value1 = (char far *)temp_array1;		      /*;AN000;6 */
	  sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;	      /*;AN000;6 */
	  sublist.max_width1 = (BYTE)strlen(temp_array1);	      /*;AN000;6 */
	  sublist.min_width1 = sublist.max_width1;		      /*;AN000;6 */

	  sublist.value2 = (char far *)temp_array2;		      /*;AN000;6 */
	  sublist.flags2 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;	      /*;AN000;6 */
	  sublist.max_width2 = (BYTE)strlen(temp_array2);	      /*;AN000;6 */
	  sublist.min_width2 = sublist.max_width2;		      /*;AN000;6 */

	  display_it(INSERT_SOURCE_DISK,STND_ERR_DEV,2,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
	  display_it(PRESS_ANY_KEY,STND_ERR_DEV,0,ANY_KEY_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/

				  /* If single drive system, eliminates double prompting */
				  /* for user to "Insert diskette for drive %1" */
	  qregs.x.ax = SETLOGICALDRIVE; 			      /*;AN000;8*/
	  qregs.h.bl = srcddir[0] - 'A' + 1;                          /*;AN000;8*/
	  intdos(&qregs,&qregs);				      /*;AN000;8*/

	  continue;
       }
      else
      break;

    } /*end of for loop*/


 return;
}								      /*;AN000;*/
