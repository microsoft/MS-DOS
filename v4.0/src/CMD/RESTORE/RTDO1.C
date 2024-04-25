
/*-----------------------------
/* SOURCE FILE NAME:  RTDO1.C
/*-----------------------------
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

struct disk_header_new russ_disk_header;			     /* !wrw */
unsigned control_file_handle = 0xffff;				     /* !wrw */

extern BYTE control_flag2;
extern BYTE far *control_buf_pointer;
extern unsigned control_selector;
extern struct FileFindBuf filefindbuf;
extern struct internat ctry;		  /* data area for get country info */
extern struct  subst_list sublist;				      /*;AN000;6 Message substitution list */
/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  check_bkdisk_new
/*
/*  DESCRIPTIVE NAME : For new format only, check to see whether the disk
/*		       is a backup disk, and whether the disk is in right
/*		       sequence.
/*
/*  FUNCTION: The routine does the following:
/*	      1. Find the file CONTROL.xxx.  If the file is not there
/*		 the disk is not a backup disk.
/*	      2. validate the extension of control.xxx
/*	      3. Check the sequence number of the disk to make sure
/*		 its in sequence.
/*	      4. Open the file CONTROL.xxx.
/*	      5. Read the file CONTROL.xxx in.
/*	      6. Fill dinfo with correct information.
/*	      7. Output a message to the screen to confirm that
/*		 the disk is going to be restored.
/*
/*  NOTES:  This subroutine also take care of situation that user
/*	    insert a old format diskette while the RESTORE started with
/*	    new format diskettes.
/*
/*	    When the inserted disk does not contain the file CONTROL.xxx,
/*	    a message "source file does not contains backup files" is
/*	    output to the user.  If the user wants to change diskette
/*	    and try again, next diskette will be read.
/*
/*	    When disk is out of sequence, a 'warning' is given to user,
/*	    if the user still wants to proceed the restoring by doing
/*	    nothing but hit a key, the same diskette will be read again.
/*	    In case of expanded file, another check for dnum of the expand
/*	    file will guarantee the disk in sequence.
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
void check_bkdisk_new(dheadnew, dinfo, srcd, dnumwant,control_bufsize) /* wrw! */

struct disk_header_new far *dheadnew;
struct disk_info *dinfo;
BYTE srcd;
unsigned int *dnumwant;
unsigned int *control_bufsize;
{
     WORD dnumok = FALSE;
     WORD disknum;  /*disk number carried by the file name backup.xxx*/
     BYTE fname_to_be_opened[13];
     WORD numread;
     BYTE temp_array1[4];
     BYTE temp_array2[4];
     BYTE c;
     WORD read_count;
     WORD action;


     /*declaration for dosfindfirst */
     unsigned	 dirhandle = 0xffff;
     unsigned	 attribute = NOTV;
     unsigned	 search_cnt = 1;
     unsigned	 buf_len = sizeof(struct FileFindBuf);
     BYTE search_string[MAXPATHF+2];
     WORD retcode;
     /*end decleration for ffirst and fnext*/
   /*****************************/
   /*search for control.xxx	*/
   /*****************************/
   for (;;)
    {
       /*DosFindFirst, using the filename CONTROL.???*/
	 search_string[0] = srcd;
	 search_string[1] = ':';
	 search_string[2] = NULLC;
	 strcat(search_string, "CONTROL.???");
	 dirhandle = 0xffff;
	 search_cnt = 1;

       retcode =			    /* Find the 1st filename that */
	 DOSFINDFIRST(			    /*	 matches specified fspec*/
	    (char far *)search_string,	    /* File path name*/
	    (unsigned far *)&dirhandle,     /* Directory search handle */
	    attribute,			    /* Search attribute */
	    (struct FileFindBuf far *)&filefindbuf,
	    buf_len,			    /* Result buffer length */
	    (unsigned far *)&search_cnt,    /* Number of entries to find */
	    (DWORD) 0
	 );

       if (retcode != NOERROR)
	 { display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	   usererror(NOBACKUPFILE);
	 }
	else
	 {
	   /*if the directory found is a subdirectory, find next one*/
	   while((retcode = filefindbuf.attributes & SUBDIR) == SUBDIR)
	    {
	      search_cnt = 1;
	      retcode = DOSFINDNEXT(dirhandle,
		     (struct FileFindBuf far *)&filefindbuf,
		     buf_len,
		     (unsigned far *)&search_cnt);
	      if (retcode != 0)
	       { display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
		 usererror(NOBACKUPFILE);
	       }
	    } /*end while */
	 }   /*end of file control.xxx not found*/

       retcode = DOSFINDCLOSE(dirhandle);

   /********************************************************************/
   /* validate the file extension of control.xxx to make sure they are */
   /* three numeric characters					       */
   /********************************************************************/
      if ((filefindbuf.file_name[7] != '.') || (filefindbuf.file_name[8] < '0')  ||
	  (filefindbuf.file_name[8] >  '9') || (filefindbuf.file_name[9] < '0')  ||
	  (filefindbuf.file_name[9] >  '9') || (filefindbuf.file_name[10] < '0') ||
	  (filefindbuf.file_name[10] > '9') || (filefindbuf.file_name[11] != NULLC) )
       { display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	 usererror(NOBACKUPFILE);
       }

   /********************************************************************/
   /* check the disk sequence number of the disk		       */
   /********************************************************************/
      if (dnumok == TRUE)
       {
	 if (disknum != *dnumwant)
	  set_reset_test_flag(&control_flag2,OUTOF_SEQ,SET);
	 dnumok = FALSE;
       }
      else
       {
	 disknum = (filefindbuf.file_name[8]-'0')*100 +
		   (filefindbuf.file_name[9]-'0')*10
		   +filefindbuf.file_name[10]-'0';
	 if (disknum != *dnumwant)
	  {
	    display_it(DISK_OUT_OF_SEQUENCE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	    display_it(PRESS_ANY_KEY,STND_ERR_DEV,0,ANY_KEY_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/

	    /* When disk is out of sequence, a 'warning' is given to user. */
	    /* If the user still wants to proceed the restoring by doing   */
	    /* nothing but hit a key, the same diskette will be read again.*/
	    dnumok = TRUE;

	    continue;
	  } /*endif*/
       } /*endif of dnumok = FALSE*/

   /********************************************************************/
   /* open control.xxx						       */
   /********************************************************************/
      fname_to_be_opened[0] = srcd;
      fname_to_be_opened[1] = ':';
      fname_to_be_opened[2] = NULLC;
      strcat(fname_to_be_opened,filefindbuf.file_name);

      retcode =
       DOSOPEN
	( (char far *)&fname_to_be_opened[0],
	  (unsigned far *)&control_file_handle, 	 /* !wrw */
	  (unsigned far *)&action,
	  (DWORD)0,
	  0,
	  0x01,
	  0x00c0,
	  (DWORD)0
	);

      if (retcode != NOERROR)
       { display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	 usererror(NOBACKUPFILE);
       }

   /********************************************************************/
   /* READ DISK_HEADER INTO STATIC DISKHEADER STRUCTURE    wrw	       */
   /********************************************************************/

      retcode =
	DOSREAD
	 (						      /* !wrw */
	   control_file_handle, 			      /* !wrw */
	   (char far *)&russ_disk_header,		      /* !wrw */
	   (unsigned short)DHEADLEN,			      /* !wrw */
	   (unsigned far *)&read_count			      /* !wrw */
	 );						      /* !wrw */

      if (retcode != NOERROR || (DWORD)read_count != (DWORD)DHEADLEN)	  /* !wrw */
       { display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	 unexperror(NOBACKUPFILE);
       }

   /********************************************************************/
   /* get and store dheadnew information into dinfo		       */
   /********************************************************************/
      dheadnew = (struct disk_header_new far *)&russ_disk_header;    /* !wrw */

      dinfo->disknum = dheadnew->sequence;
      dinfo->dflag = dheadnew->lastdisk;

      /* At this point, the diskette has passed all the checking, and */
      /* should be a ok diskette.   break out of the loop.*/
      break;

    } /*end of "for (;;)" loop */

   /********************************************************************/
   /* output confirm msg "restore file from drive d:"                  */
   /********************************************************************/
   temp_array1[0] = srcd;
   temp_array1[1] = NULLC;

   sublist.value1 = (char far *)temp_array1;			  /*;AN000;6 */
   sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;		  /*;AN000;6 */
   sublist.max_width1 = (BYTE)strlen(temp_array1);		  /*;AN000;6 */
   sublist.min_width1 = sublist.max_width1;			  /*;AN000;6 */

   display_it(RESTORE_FILE_FROM_DRIVE,STND_OUT_DEV,1,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/

   /********************************************************************/
   /* if the source disk is removable, output diskette number also     */
   /********************************************************************/
   if (set_reset_test_flag(&control_flag2,SRC_HDISK,TEST) == FALSE)
    {
     temp_array2[0] = (dinfo->disknum / 10) + '0';
     temp_array2[1] = (dinfo->disknum % 10) + '0';
     temp_array2[2] = NULLC;

     sublist.value1 = (char far *)temp_array2;			      /*;AN000;6*/
     sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;		      /*;AN000;6*/
     sublist.max_width1 = (BYTE)strlen(temp_array2);		      /*;AN000;6*/
     sublist.min_width1 = sublist.max_width1;			      /*;AN000;6*/

     display_it(DISKETTE_NUM,STND_OUT_DEV,1,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
    }

   *dnumwant = dinfo->disknum + 1;

   return;							      /*;AN000;*/
} /*end of subroutine */

/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  check_bkdisk_old
/*
/*  DESCRIPTIVE NAME : For old format only, check to see whether the disk
/*		       is a backup disk, and whether the disk is in right
/*		       sequence.
/*
/*  FUNCTION: The routine does the following:
/*	      1. Open the file BACKUPID.@@@.  If the file is not there,
/*		 the disk is not a backup disk.
/*	      3. Check the sequence number of the disk to make sure
/*		 its in sequence.
/*	      4. Fill dinfo with correct information.
/*	      5. Output a message to the screen to confirm that
/*		 the disk is going to be restored.
/*
/*  NOTES:  This subroutine also take care of situation that user
/*	    insert a new format diskette while the RESTORE started with
/*	    old format diskettes.
/*
/*	    When the inserted disk does not contain the file BACKUP.@@@,
/*	    a message "source file does not contains backup files" is
/*	    output to the user.  If the user wants to change diskette
/*	    and try again, next diskette will be read.
/*
/*	    When disk is out of sequence, a 'warning' is given to user,
/*	    if the user still wants to proceed the restoring by doing
/*	    nothing but hit a key, the same diskette will be read again.
/*	    In case of expanded file, another check for dnum of the expand
/*	    file will guarantee the disk in sequence.
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
void check_bkdisk_old(dheadold, dinfo, srcd, dnumwant) /* wrw! */
     struct disk_header_old *dheadold;
     struct disk_info *dinfo;
     BYTE srcd;
     unsigned int *dnumwant;
{
   WORD retcode;
   WORD action;

     int dnumok = FALSE;
     unsigned file_pointer;
     char fname_to_be_opened[13];
     int numread;
     int dyear;
     int dmonth;
     int dday;
     char temp_array1[4];
     char temp_array2[4];
     BYTE c;

   /********************************************************************/
   /* open and read backupid.@@@.  Store information in backupid.@@@   */
   /* into dinfo						       */
   /********************************************************************/

   for (;;)
    {
      fname_to_be_opened[0] = srcd;
      fname_to_be_opened[1] = ':';
      fname_to_be_opened[2] = NULLC;
      strcat(fname_to_be_opened,BACKUPID);
      retcode =
       DOSOPEN(
	       (char far *)&fname_to_be_opened[0],(unsigned far *)&file_pointer,
	       (unsigned far *)&action,(DWORD)0,0,0x01,0x00c0,(DWORD)0
	      );

      if (retcode != NOERROR)
       { display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	 usererror(NOBACKUPFILE);
       }

      /*read BKIDLENG (7) bytes from the file and store into dheadold*/
      retcode = DOSREAD( file_pointer,
		    (char far *)dheadold,
		    BKIDLENG,
		    (unsigned far *)&numread);
      /*if return code of read indicate less than 11 bytes been read*/
      if (retcode != 0 || numread < BKIDLENG) {
	 /*unexperror "source file does not contains backup files"*/
	 display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	 unexperror(NOBACKUPFILE);
      } /*endif  */
      dinfo->disknum = dheadold->disknum[0] + dheadold->disknum[1] * 10;
      dyear = dheadold->diskyear[0] + dheadold->diskyear[1]*256;
      dinfo->dflag = dheadold->diskflag;

      /*close the file*/
      DOSCLOSE(file_pointer);

   /********************************************************************/
   /* check disk sequence number				       */
   /********************************************************************/
      if (dnumok == TRUE) {
	 if ((WORD)dinfo->disknum != *dnumwant) {
	    set_reset_test_flag(&control_flag2,OUTOF_SEQ,SET);
	 }
	 dnumok = FALSE;
      }
      else {
	 if ((WORD)dinfo->disknum != *dnumwant) {
	    /*When disk is out of sequence, a 'warning' is given to user,
	    if the user still wants to proceed the restoring by doing
	    nothing but hit a key, the same diskette will be read again.*/
	    display_it(DISK_OUT_OF_SEQUENCE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
	    display_it(PRESS_ANY_KEY,STND_ERR_DEV,0,ANY_KEY_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
	    dnumok = TRUE;
	    continue;
	 } /*endif*/
      } /*endif*/

      /*at this point, the diskette has passed all the checking, and
      should be a ok diskette.	 break out of the loop.*/
      break;
   } /*end of loop*/

   /********************************************************************/
   /* output a confirm msg "restoring files from drive d:"             */
   /********************************************************************/
   temp_array1[0] = srcd;
   temp_array1[1] = NULLC;
   sublist.value1 = (char far *)temp_array1;			      /*;AN000;6 */
   sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ;		      /*;AN000;6 */
   sublist.max_width1 = (BYTE)strlen(temp_array1);		      /*;AN000;6 */
   sublist.min_width1 = sublist.max_width1;			      /*;AN000;6 */
   display_it(RESTORE_FILE_FROM_DRIVE,STND_OUT_DEV,1,NO_RESPTYPE,(BYTE)UTIL_MSG);    /*;AN000;6*/

   /********************************************************************/
   /* if the source disk is removable, output msg "diskette xx"        */
   /********************************************************************/
   if (set_reset_test_flag(&control_flag2,SRC_HDISK,TEST) == FALSE)
   {
       temp_array2[0] = (dinfo->disknum / 10) + '0';
       temp_array2[1] = (dinfo->disknum % 10) + '0';
       temp_array2[2] = NULLC;

       sublist.value1 = (char far *)temp_array2;		      /*;AN000;6 */
       sublist.flags1 = LEFT_ALIGN + CHAR_FIELD_ASCIIZ; 	      /*;AN000;6 */
       sublist.max_width1 = (BYTE)strlen(temp_array2);		      /*;AN000;6 */
       sublist.min_width1 = sublist.max_width1; 		      /*;AN000;6 */
       display_it(DISKETTE_NUM,STND_OUT_DEV,1,NO_RESPTYPE,(BYTE)UTIL_MSG);  /*;AN000;6*/
   }

   *dnumwant = dinfo->disknum + 1;
   return;							      /*;AN000;*/
} /*end of subroutine */

