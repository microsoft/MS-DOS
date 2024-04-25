
/*------------------------------
/* SOURCE FILE NAME: rtfile1.c
/*------------------------------
/*  0 */

#include "rt.h"
#include "rt1.h"
#include "rt2.h"
#include "restpars.h"                                                 /*;AN000;4*/
#include "direct.h"
#include "string.h"
#include "dos.h"                                                      /*;AN000;2*/
#include "comsub.h"             /* common subroutine def'n */
#include "doscalls.h"
#include "error.h"

char ext_attrib_buff[4086];					      /*;AN000;3*/

extern BYTE rtswitch;
extern BYTE control_flag;
extern BYTE control_flag2;
extern unsigned dest_file_handle;
extern unsigned src_file_handle;
extern BYTE far *buf_pointer;
extern BYTE dest_file_spec[MAXFSPEC+3];
extern struct FileFindBuf filefindbuf;

extern struct file_header_new far *fheadnew;   /*;AN000;3 */

/****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  open_dest_file
/*
/*  DESCRIPTIVE NAME : open the destination file and build a path to it
/*		       if necessary.
/*
/*  FUNCTION:  Try to change the current directory of the destination disk
/*	       to be the one the file is to be restored.  If not able to
/*	       do it because the directory does not exist, call
/*	       build_path_create_file subroutine to build path,
/*	       create the destination file and return a handle on it.
/*	       If file can not be created, find out whether it is caused
/*	       by file sharing error, or caused by disk full.
/*
/*
/********************** END OF SPECIFICATIONS ******************************/
WORD open_dest_file(finfo,destd)
struct file_info *finfo;
BYTE destd;
{
    BYTE  fname[MAXFSPEC+2];
    BYTE  path_to_be_chdir[MAXPATH+2];
    WORD  rc;

    WORD retcode;

    /*declaration for dosfindfirst */
    unsigned	dirhandle = 0xffff;
    unsigned	attribute = NOTV;
    unsigned	search_cnt = 1;
    unsigned	buf_len = sizeof(struct FileFindBuf);
    BYTE search_string[MAXPATHF+2];
    /*end decleration for ffirst and fnext*/

   /*************************************************************************
   /*if current directory is not where the file wants to be restored and
   /* (the file is not to be restored in root or the current directory is
   /* not root).  This is to avoid building path if the the current
   /* directory already got updated to be the right directory (in dorestore),
   /* or both current directory and the requested directory are root
   /* directory
   /**************************************************************************/

   if (strcmp(finfo->path,finfo->curdir)!=0)
    {
		/* Change to finfo->path. If error, create the directory */
      strcpy(finfo->curdir,finfo->path);
      path_to_be_chdir[0] = destd;
      path_to_be_chdir[1] = ':';
      path_to_be_chdir[2] = NULLC;
      strcat(path_to_be_chdir,finfo->curdir);
      if(chdir(path_to_be_chdir)!=0)
       {
	 build_path_create_file(finfo->path,destd,finfo->fflag,finfo->ea_offset);  /*;AC000;3*/
	 if (dest_file_handle != NULLC)
	  return(TRUE);
       }
    }

   /* Current directory is the one where files are to be restored to*/

      retcode = create_the_file(finfo->fflag,finfo->ea_offset);  /*;AN000;3*/

      if (retcode == NOERROR)
       return(TRUE);

	/*----------------------------------------*/
	/*-  There was an error creating target  -*/
	/*-  file. Reset attribute and try again -*/
	/*----------------------------------------*/
      retcode =
       DOSSETFILEMODE
	(
	  (char far *)&dest_file_spec[0],
	  (unsigned) 0x00,
	  (DWORD) 0
	);

      retcode = create_the_file(finfo->fflag,finfo->ea_offset);  /*;AN000;3*/

   if (retcode == NOERROR)
    return(TRUE);
   else
    return(FALSE);					/*;AC000;p1102*/


} /*end of subroutine*/
/****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  build_path_create_file
/*
/*  DESCRIPTIVE NAME : Build path for the destination file, and create
/*		       the file in the current direactory.
/*
/*  FUNCTION:  Rebuild the path of the file about to be restored by
/*	       recreating all subdirectories needed to complete the path.
/*	       Then chdir to the one which is to reside and create the
/*	       file.
/*
/********************* END OF SPECIFICATIONS ********************************/
void build_path_create_file(in_path,destd,fflag,ea_offset)
BYTE *in_path;
BYTE destd;
BYTE fflag;						/*;AN000;3*/
DWORD ea_offset;					/*;AN000;3*/
{
    WORD  array[20];
    int   i,j;
    BYTE  path[MAXPATH+2];
    WORD  retcode;
    BYTE cant_make = FFALSE;			/*;AN000;10*/

    path[0] = destd;
    path[1] = ':';
    path[2] = NULLC;
    strcat(path,in_path);
    i = strlen(path);
    j = -1;

    /* Create the path for destination file */
    /*Loop until mkdir(path) is successful*/

    while (mkdir(path) && !cant_make)				     /*;AC000;10*/
     {
	 /*scan path backward until find a \ */
	 for (; path[i] != '\\'; i--)
	 if (i < 0)
	   { display_it(FILE_CREATION_ERROR,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	     display_it(PRESS_ANY_KEY,STND_ERR_DEV,0,ANY_KEY_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;9*/
	     cant_make = TTRUE; 				     /*;AN000;10*/
	     break;						     /*;AN000;10*/
	   }

	 /*obtain the last subdir from the path */
	 path[i] = NULLC;
	 j++;
	 /*save the location of the last \ in an array of \ locations */
	 array[j] = i;
     }

    /*loop through the array of \ locations*/
    i = j;
    for (;;)
     {
       if (i >= 0 && !cant_make)				     /*;AC000;10*/
	 {
	   path[array[i]] = '\\';
	   if (mkdir(path))
	    { display_it(FILE_CREATION_ERROR,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);/*;AN000;6*/
	      display_it(PRESS_ANY_KEY,STND_ERR_DEV,0,ANY_KEY_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;9*/
	      cant_make = TTRUE;				     /*;AN000;10*/
	      break;						     /*;AN000;10*/
	    }
	   --i;
	 }
	else
	  break;
     } /*end for loop */

    chdir(path);						      /*;AN000;3*/
    retcode = create_the_file(fflag,ea_offset); 		      /*;AN000;3*/

  return;	  /* wrw! */

}

/********************************************************/
/*
/*  SUBROUTINE NAME: create_the_file
/*
/*  DESCRIPTIVE NAME :	Create the target file.
/*			Use DOS 4.00 Extended Create Function 6C00h
/*			Remember to handle Extended Attributes!
/*
/********************************************************/
#define EXTENDEDOPEN 0x6c00					      /*;AN000;3*/
WORD create_the_file(fflag,ea_offset)				      /*;AN000;3*/
BYTE	fflag;							      /*;AN000;3*/
DWORD	ea_offset;						      /*;AN000;3*/
{								      /*;AN000;3*/
	WORD	action; 					      /*;AN000;3*/
	WORD	retcode;					      /*;AN000;3*/
	union REGS reg; 					      /*;AN000;3*/
	struct parm_list ea_parmlist;				      /*;AN000;3 Parameter list for extended open*/

	if ((fflag & EXT_ATTR_FLAG) == EXT_ATTR_FLAG)		      /*;AN000;3*/
	  read_the_extended_attributes(ea_offset);		      /*;AN000;3*/

	ea_parmlist.ext_attr_addr = (DWORD)(char far *)&ext_attrib_buff[0];/*;AN000;3*/
	ea_parmlist.num_additional = 0; 			      /*;AN000;3*/

	retcode = NOERROR;					      /*;AN000;3*/
	reg.x.ax = EXTENDEDOPEN;	      /* Function */	      /*;AN000;3*/
	reg.x.bx = 0x2011;		      /* Mode */	      /*;AN000;3*/
	reg.x.bx = 0x0081;		      /* Mode */	      /*;AN000;3*/
	reg.x.cx = 0;			      /* Attribute */	      /*;AN000;3*/
	reg.x.dx = 0x112;		      /* Flag */	      /*;AN000;3*/

	reg.x.si = (WORD)&dest_file_spec[0];  /* Filename */	      /*;AN000;3*/

	if ((fflag & EXT_ATTR_FLAG) == EXT_ATTR_FLAG)		      /*;AN000;3*/
	  reg.x.di = (WORD)&ea_parmlist;	/* Parmlist */	      /*;AN000;3*/
	 else
	  reg.x.di = 0xffff;			/* No parmlist */     /*;AN000;3*/

	intdos(&reg,&reg);					      /*;AN000;3*/
	if (reg.x.cflag & CARRY)     /* If there was an error	      /*;AN000;3*/
	 retcode = reg.x.ax;		  /*  then set return code    /*;AN000;3*/

	dest_file_handle = reg.x.ax;				      /*;AN000;3*/

	return(retcode);					      /*;AN000;3*/
}								      /*;AN000;3*/
/********************************************************/
/*
/*  SUBROUTINE NAME: read_the_extended_attributes
/*
/*  DESCRIPTIVE NAME :	reads in the extended attributes
/*
/********************************************************/
void read_the_extended_attributes(ea_offset)			      /*;AN000;3*/
DWORD	ea_offset;						      /*;AN000;3*/
{								      /*;AN000;3*/
	WORD	ea_len; 					      /*;AN000;3*/
	DWORD	file_position;					      /*;AN000;3*/
	WORD	read_count;					      /*;AN000;3*/
	WORD	retcode;					      /*;AN000;3*/
			/*******************************/
			/* Seek to Extended Attributes */
	retcode =						      /*;AN000;3*/
	  DOSCHGFILEPTR 					      /*;AN000;3*/
	   (							      /*;AN000;3*/
	    src_file_handle,		     /* Handle */	      /*;AN000;3*/
	    ea_offset,			     /* New location */       /*;AN000;3*/
	    (BYTE)0,			     /* MOVE METHOD */	      /*;AN000;3*/
	    (DWORD far *)&file_position 			      /*;AN000;3*/
	   );							      /*;AN000;3*/

			/*************************************/
			/* Read in Extended Attribute length */
	retcode =					  /*;AN000;3*/
	 DOSREAD					  /*;AN000;3*/
	  (						  /*;AN000;3*/
	    src_file_handle,				  /*;AN000;3*/
	    (char far *)&ea_len,			  /*;AN000;3*/
	    (unsigned short)2,				  /*;AN000;3*/
	    (unsigned far *)&read_count 		  /*;AN000;3*/
	   );						  /*;AN000;3*/

			/***********************************/
			/* Read in the Extended Attributes */
	retcode =					  /*;AN000;3*/
	 DOSREAD					  /*;AN000;3*/
	  (						  /*;AN000;3*/
	    src_file_handle,				  /*;AN000;3*/
	    (char far *)&ext_attrib_buff[0],		  /*;AN000;3*/
	    (unsigned short)ea_len,			  /*;AN000;3*/
	    (unsigned far *)&read_count 		  /*;AN000;3*/
	   );						  /*;AN000;3*/

	return; 						      /*;AN000;3*/
}								      /*;AN000;3*/

/****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  set_attributes_and_close
/*
/*  DESCRIPTIVE NAME :	Set the file attributes and close the file
/*
/*  FUNCTION: Set the attributes and last write date/time of the file just
/*	      restored to be like those of the backup file.
/*
/********************* END OF SPECIFICATIONS ********************************/
int set_attributes_and_close(finfo,destd)
struct file_info *finfo;
BYTE destd;
{
   struct FileStatus fileinfo_buf;
   WORD destdnum;
   WORD buflen = sizeof(struct FileStatus);

   WORD retcode;

   destdnum = destd - 'A' + 1;

   /************************************************************************/
   /* call DosQFileInfo: Request date and time of the dest file 	   */
   /************************************************************************/
   retcode = DOSQFILEINFO (
       (unsigned)dest_file_handle,	/* File handle */
       (unsigned)1,			/* File info data required */
       (char far *)&fileinfo_buf,	/* File info buffer */
       (unsigned)buflen);		/* File info buffer size */

   /*if fail, unexperror "file creation error"*/
   if (retcode != NOERROR)
    { display_it(FILE_CREATION_ERROR,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);     /*;AN000;6*/
      usererror(retcode);
    }
   /************************************************************************/
   /* call DosSetFileInfo: Set date and time in dest file as the same date */
   /* and time in finfo 						   */
   /************************************************************************/
   fileinfo_buf.write_date = finfo->fdate;
   fileinfo_buf.write_time = finfo->ftime;
   retcode = DOSSETFILEINFO (
       (unsigned)dest_file_handle,	/* File handle */
       (unsigned)1,			/* File info data required */
       (char far *)&fileinfo_buf,	/* File info buffer */
       (unsigned)buflen);		/* File info buffer size */

   /*if fail, unexperror "file creation error"*/
   if (retcode != NOERROR)
    { display_it(FILE_CREATION_ERROR,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);     /*;AN000;6*/
      usererror(retcode);
    }

   /******************************************************************/
   /*close dest file						     */
   /******************************************************************/
   DOSCLOSE(dest_file_handle);

   /******************************************************************/
   /*DosSetFileMode to set file attrib of d:infspec(from input line) */
   /*to be the attrib in finfo structure			     */
   /******************************************************************/
   finfo->attrib = finfo->attrib & 0xffdf;
   retcode =
    DOSSETFILEMODE
     (
      (char far *)dest_file_spec,
      (unsigned) finfo->attrib, (DWORD) 0
     );


   /******************************************************************/
   /*reset flag PARTIAL 					     */
   /******************************************************************/
   set_reset_test_flag(&control_flag,PARTIAL,RESET);

return(0);	/* wrw! */

} /*end of subroutine*/

/****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  dos_write_error
/*
/*  DESCRIPTIVE NAME : Determine the cause of the error during
/*		       DOS write, and output message according to it.
/*
/*  FUNCTION:  If error returned from get free space of the disk
/*	       is caused by disk full, a message "target disk is
/*	       full" is output to the user.
/*	       Otherwise, the error is caused by other reason, and
/*	       a message "file creation error" is output to the user.
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
int dos_write_error(buf_size,destd)
DWORD buf_size;
BYTE destd;
{
   DWORD free_space;
   WORD drive_num;
   struct fsinfo *fsinfo_buf;

   WORD retcode;

   /******************************************************************/
   /*DosQFsinfo: get free space in the hard disk		     */
   /******************************************************************/
   drive_num = destd - 'A' + 1;
   retcode = DOSQFSINFO
      ((unsigned)drive_num,	      /* Drive number - 0=default, 1=A, etc */
       (unsigned)1,		      /* File system info required */
       (char far *)fsinfo_buf,	      /* File system info buffer */
       (unsigned)FSINFO_BYTES	      /* File system info buffer size */
      );


   free_space = fsinfo_buf->sectors_per_alloc_unit *
		fsinfo_buf->available_alloc_unit *
		fsinfo_buf->bytes_per_sector;


   /******************************************************************/
   /*if the free space left is less than buffer size for file read   */
   /* and write, output msg "target is full", and "file creation     */
   /* error", otherwise, output "file creation error".               */
   /******************************************************************/
   if ( free_space < buf_size)
    { display_it(TARGET_IS_FULL,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);	     /*;AN000;6*/

      /*close dest file*/
      DOSCLOSE(dest_file_handle);

      if ((retcode = DOSDELETE((char far *)&dest_file_spec[0],
	 (DWORD)0)) != 0)
       {
	 /*set file mode to 0*/
	 retcode =
	   DOSSETFILEMODE
	    (
	     (char far *)&dest_file_spec[0],
	     (unsigned) 0x00,
	     (DWORD)0
	    );

	 /* delete the partially completed destination file*/
	 retcode = DOSDELETE((char far *) dest_file_spec,(DWORD)0);
       }

      display_it(LAST_FILE_NOT_RESTORED,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);  /*;AN000;6*/
      usererror(TARGETFULL);
   }
   else
    { display_it(FILE_CREATION_ERROR,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);     /*;AN000;6*/
      usererror(CREATIONERROR);
    }
   /*endif*/

	return(0);	/* wrw! */

}/*end of subroutine*/
