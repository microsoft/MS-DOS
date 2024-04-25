
/*------------------------------
/* SOURCE FILE NAME: RTNEW1.C
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


#define LAST_DIRBLOCK	0xffffffff			     /* !wrw */
BYTE	got_first_fh;					     /* !wrw */

struct dir_block russ_dir_block;	/* Current directory block   /* !wrw */
extern BYTE backup_level;      /* Tells which DOS version made the BACKUP*/  /*;AN000;3*/

struct file_header_new russ_file_header;/* Current file_header	     /* !wrw */
unsigned short tot_num_fh_read_in;	/* Num FH read in so far     /* !wrw */
unsigned short num_fh_in_buffer;	/* Num FH currently in buff  /* !wrw */
unsigned short num_fh_in_buf_processed; /* Number of FH in the buffer that have been processed	  /* !wrw */
struct file_header_new far *fheadnew;	/* Global pointer to FH      /* !wrw */


BYTE fileheader_length; 	/*;AN000;3 Length of a file header */

extern BYTE rtswitch;
extern BYTE control_flag;
extern BYTE control_flag2;
extern char far *control_buf_pointer;
extern unsigned control_file_handle;
extern WORD control_bufsize;				     /* !wrw */


/*   0 */
/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  findfile_new
/*
/*  DESCRIPTIVE NAME : Find a file with matching file name from
/*		       the file CONTROL.xxx.
/*
/*  FUNCTION: For new format only, search through all directory blocks
/*	      and all file headers until a file header with matched file
/*	      path, name and extension is found.   also store information
/*	      into  fhead and finfo if file is found which match the
/*	      filename and file extension specified in the command line.
/*
/*  NOTES: Path name for comparison has to started with \ and end with \.
/*
/********************** END OF SPECIFICATIONS *******************************/
int findfile_new( finfo, found, done_searching, inpath,
	     infspec, dirptr, flptr, numentry, dir_path)

struct file_info  *finfo;
WORD	 *found;
unsigned int *done_searching;
BYTE	 *inpath;
BYTE	 *infspec;
WORD	 far **dirptr;
WORD	 far **flptr;
unsigned int *numentry;
BYTE	 *dir_path;
{
	struct dir_block far *dirblk;
	char temp_path[MAXPATH];
	char temp_fname[MAXFSPEC];
	WORD i;
	WORD rc;


	dirblk = (struct dir_block far *)&russ_dir_block;		     /* !wrw */
	fheadnew = (struct file_header_new far *)&russ_file_header;	     /* !wrw */

	/******************************************************************/
	/* search the directory block for the one that has the right path  */
	/*******************************************************************/
	while ((*done_searching == FALSE) && (*found == FALSE))
	 {
	   temp_path[0] = '\\';
	   for (i = 0; i <= (MAXPATH-2); ++i)
	      temp_path[i+1] = dirblk->path[i];

	   temp_path[MAXPATH-1] = NULLC;

	     /*****************************/
	     /* While path does not match */
	     /*****************************/

	   while (pathmatch(inpath,temp_path) == FALSE)
	    {
	      if (dirblk->nextdb == LAST_DIRBLOCK)			     /* !wrw */
	       {
		 *found = FALSE;
		 *done_searching = TRUE;
		 break;
	       }
	      else
	       {
		 read_in_next_dirblock();				     /* !wrw */
		 temp_path[0] = '\\';
		 for (i = 0; i <= (MAXPATH-2); ++i)
		     temp_path[i+1] = dirblk->path[i];
		 temp_path[MAXPATH-1] = NULLC;
		 continue;
	       }
	      /*end of if not last dirblk*/

	    } /*end while loop, searching for the right path in directory block*/
	   /*if done searching, break out of the big loop to exit*/

	   if (*done_searching == TRUE)
	      break;

	   /***************************************************/
	   /* directory block with correct path has been found*/
	   /***************************************************/

	   /*get the total number of file headers in the directory block*/
	   *numentry = (unsigned int)russ_dir_block.numentry;		     /* !wrw */

	   if (got_first_fh == FALSE)					     /* !wrw */
	    read_in_a_fileheader();		/*####			     /* !wrw */

	   /****************************************************/
	   /* search all the file headers under this directory */
	   /* block to find the one with right file name       */
	   /****************************************************/
	   for (;;)
	    {

	      if ((rc = fheadnew->flag & COMPLETE_BIT) != COMPLETE_BIT)
	       {
		if (*numentry)
		 --(*numentry);
		 if (*numentry==0)
		  {
		    if (dirblk->nextdb == LAST_DIRBLOCK)		     /* !wrw */
		     {
		       *found = FALSE;
		       *done_searching = TRUE;
		       break;  /*exit FOR loop, go back to WHILE loop*/
		     }
		    else
		     {
		       read_in_next_dirblock(); 			     /* !wrw */
		       break;  /*exit FOR loop, go back to WHILE loop*/
		     }
		  }
		 else
		  {
		   read_in_a_fileheader();				     /* !wrw */
		   continue;
		  }
	       }

	      for (i = 0; i <= (MAXFSPEC-2); ++i)
		temp_fname[i] = fheadnew->fname[i];
	      temp_fname[MAXFSPEC-1] = NULLC;

	      if (fspecmatch(infspec,temp_fname)==TRUE)
	       {
		 *found = TRUE;
		 break;
	       }
	      else	 /* This file header is not the right one*/
	       {
		if (*numentry)
		  --(*numentry);
		 if (*numentry == 0)
		  {
		    if (dirblk->nextdb == LAST_DIRBLOCK)
		     {
		       *found = FALSE;
		       *done_searching = TRUE;
		       break;  /*exit FOR loop, go back to WHILE loop*/
		     }
		    else
		     {
		       read_in_next_dirblock(); 		     /* !wrw */
		       break;
		     } /*end of if not last dir block */
		  }
		 else	  /*point to the next file header and loop again*/
		   read_in_a_fileheader();				     /* !wrw */

	       }

	    }	/* end for (;;) loop to search all file headers in a directory block */

	 } /*end of while loop*/



	/*******************************************************************/
	/* if a file is found, save the information in the disk header and */
	/* file header							   */
	/*******************************************************************/
	if (*found == TRUE)
	 {
	      /* Store information from dir blk into finfo */
	      if (strcmp(dir_path,"no path from fnext") == 0)
		  strcpy(finfo->path,temp_path);
	      else
	       {
		 finfo->path[0] = '\\';
		 finfo->path[1] = NULLC;
		 strcat(finfo->path,dir_path);
	       }

	      /*store information from file header into finfo*/
	      for (i = 0; i <= (MAXFSPEC-2); ++i)
		  finfo->fname[i] = fheadnew->fname[i];
	      finfo->fname[MAXFSPEC-1] = NULLC;
	      finfo->fflag = fheadnew->flag;
	      finfo->dnum  = fheadnew->fsequenc;
	      finfo->ftime = fheadnew->ftime;
	      finfo->fdate = fheadnew->fdate;
	      finfo->attrib = fheadnew->attrib;
	      finfo->partsize = fheadnew->partsize;
	      finfo->offset = fheadnew->offset;

	      if ((fheadnew->flag & EXT_ATTR_FLAG) == EXT_ATTR_FLAG)	      /*;AN000;3*/
		finfo->ea_offset = fheadnew->FH_EA_offset;		      /*;AN000;3*/

	      if (*numentry)
	       --(*numentry);

	      if (*numentry == 0)
	       {
		  if (dirblk->nextdb == LAST_DIRBLOCK)
		    *done_searching = TRUE;
		else
		 {
		  read_in_next_dirblock();				     /* !wrw */
		  read_in_a_fileheader();				     /* !wrw */
		  *numentry = dirblk->numentry;
		 }
	       }
	      else
		read_in_a_fileheader(); 				     /* !wrw */

	      *dirptr=(WORD far *)dirblk;
	      *flptr=(WORD far *)fheadnew;

	      return (TRUE);
	  } /*end of if found */
	else
	  return (FALSE);

	return(TRUE);		      /*;AN000;*/
} /*end of subroutine */

/*   0 */
/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  findnext_new
/*
/*  DESCRIPTIVE NAME : For new format only, continue at the point
/*		       findfirst_new or previous findnext_new exit, search
/*		       the entire file of CONTROL.xxx to find matching file
/*		       names.
/*
/*  FUNCTION: Continue at where findfirst_new or previous findnext_new
/*	      stop, search the current directory blocks for the matching
/*	      file path, if fail to find a file, then call findfile to
/*	      search all directory block.
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
int findnext_new(finfo, found, done_searching, in_path,
	     infspec, dirptr, flptr, numentry, dir_path)

struct file_info *finfo;
WORD *found;
unsigned int  *done_searching;
BYTE *in_path;
BYTE *infspec;
WORD far **dirptr;
WORD far **flptr;
unsigned int *numentry;
BYTE *dir_path;
{
	struct dir_block far *dirblk;
	WORD retcode;
	WORD i;
	BYTE temp_fname[MAXFSPEC];
	WORD rc;
	char temp_path[MAXPATH];

	dirblk=(struct dir_block far *)*dirptr;
	fheadnew=(struct file_header_new far *)*flptr;
	strcpy(dir_path,"no path from fnext");

	temp_path[0] = '\\';
	for (i = 0; i <= (MAXPATH-2); ++i)
	    temp_path[i+1] = dirblk->path[i];

	temp_path[MAXPATH-1] = NULLC;

	/****************************************/
	/* Should we process this subdirectory ?*/
	/****************************************/
	if (pathmatch(in_path,temp_path) == TRUE)
	 {

	   /*************************************************/
	   /*complete the scanning current db to find a file*/
	   /*************************************************/
	   for (;;)
	   {
	      if ((rc = fheadnew->flag & COMPLETE_BIT) != COMPLETE_BIT)
	       {
		 if (*numentry)
		   --(*numentry);

		 if (*numentry==0)
		  {
		    if (dirblk->nextdb == LAST_DIRBLOCK)
		     {
		       *found = FALSE;
		       *done_searching = TRUE;
		       break;
		     }
		    else
		     {
		       read_in_next_dirblock(); 		     /* !wrw */
		       break;						     /* !wrw */
		     }
		  }							     /* !wrw */
		 else  /* There are more files from current dirblock. Get them */
		  {							     /* !wrw */
		    read_in_a_fileheader();				     /* !wrw */
		    continue;						     /* !wrw */
		  }
	       }
	      /*endif*/

	      /* If this file header is the right one)*/
	      for (i = 0; i <= (MAXFSPEC-2); ++i)
		  temp_fname[i] = fheadnew->fname[i];

	      temp_fname[MAXFSPEC-1] = NULLC;

	      if (fspecmatch(infspec,temp_fname)==TRUE)
	       {
		 *found = TRUE;
		 for (i = 0; i <= (MAXPATH-2); ++i)
		   dir_path[i] = dirblk->path[i];
		 break;
	       }
	      else	 /*if this file header is not the right one*/
	       {
		 if (*numentry)
		   --(*numentry);
		 if (*numentry == 0)	  /* If no more files in this directory block */
		  {
		    if (dirblk->nextdb == LAST_DIRBLOCK)    /* If this is the last dirblock on current source disk */
		     {
		       *found = FALSE;
		       *done_searching = TRUE;
		       break;
		     }
		    else
		     {
		       read_in_next_dirblock(); 			/* !wrw */
		       break;						/* !wrw */
		     } /*end of if not last dir block */		/* !wrw */
		  }							/* !wrw */
		 else							/* !wrw */
		   read_in_a_fileheader();				/* !wrw */
	       }
	   } /*end loop searching all file headers in dir block */
	 } /*end of if the path match inpath*/

	else
	  *found = FALSE;


	/********************************************************************/
	/* If fail to find a file in the current directory block, call	    */
	/* filefind_new to find next.					    */
	/* If already found or done searching, call findfile_new to store   */
	/* information in finfo and dinfo				    */
	/********************************************************************/

	 *dirptr=(WORD far *)dirblk;
	 *flptr=(WORD far *)fheadnew;

	retcode = findfile_new(finfo,found,done_searching,in_path,infspec,dirptr,
			       flptr,numentry, dir_path);

     return(retcode);
}

/*   0 */
/*****************  START OF SPECIFICATION  ********************************
/*
/*  SUBROUTINE NAME :  findfirst_new
/*
/*  DESCRIPTIVE NAME : For new format only, search the entire file
/*		       of CONTROL.xxx to find matching file names.
/*
/*  FUNCTION: search directory blocks one after the other to find the
/*	      directory block with the matching file path, then search
/*	      the entire directory block to find the file with matching
/*	      file name.
/*
/*
/********************** END OF SPECIFICATIONS *******************************/
int findfirst_new(finfo,found,done_searching,in_path,infspec,dirptr,flptr,numentry,dir_path)

struct file_info *finfo;
WORD	 *found;
unsigned int *done_searching;
BYTE	 *in_path;
BYTE	 *infspec;
WORD	 far **dirptr;
WORD	 far **flptr;
unsigned int *numentry;
BYTE	 *dir_path;
{
	struct dir_block far *dirblk;
	WORD retcode;

	strcpy(dir_path,"no path from fnext");
	dirblk = (struct dir_block far *)&russ_dir_block;		/* !wrw */
	read_in_first_dirblock();					/* !wrw */

	if (got_first_fh == FALSE)				     /* !wrw */
	  read_in_a_fileheader();	     /*###		     /* !wrw */

	*found = FALSE;
	*done_searching = FALSE;
	*dirptr=(WORD far *)dirblk;
	*flptr=(WORD far *)fheadnew;

	retcode = findfile_new(finfo,found,done_searching,in_path,
		  infspec,dirptr,flptr,numentry,dir_path);

	return(retcode);
}	/*end of findfirst_new */




/*   0 */
/*********************************************************************/
/*
/*	SUBROUTINE NAME: read_in_next_dirblock
/*
/*	FUNCTION:
/*		Reads in a directory block
/*		Figures out if it was put there by DOS 3.3 or 4.0
/*********************************************************************/
void read_in_next_dirblock()					     /* !wrw */
{

	WORD retcode;		/* return code save area */	     /* !wrw */
	WORD read_count;	/* num bytes read in	 */	     /* !wrw */
	DWORD file_pointer;	/* current file pointer, returned by lseek  !wrw */

	retcode =						     /* !wrw */
	  DOSCHGFILEPTR 					     /* !wrw */
	   (							     /* !wrw */
	    control_file_handle,	/* Handle */		     /* !wrw */
	    russ_dir_block.nextdb,	/* New location */	     /* !wrw */
	    (BYTE)0,			/* MOVE METHOD */	     /* !wrw */
	    (DWORD far *)&file_pointer				     /* !wrw */
	   );							     /* !wrw */

	retcode =
	  DOSREAD
	   (							     /* !wrw */
	    control_file_handle,				     /* !wrw */
	    (char far *)&russ_dir_block,			     /* !wrw */
	    (unsigned short)DIRBLKLEN,				     /* !wrw */
	    (unsigned far *)&read_count 			     /* !wrw */
	   );							     /* !wrw */
								     /* !wrw */
	if (retcode != NOERROR) 				     /* !wrw */
	 {							     /* !wrw */
	  display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
	  unexperror(NOBACKUPFILE);				     /* !wrw */
	 }

	got_first_fh = FALSE;					     /* !wrw */
	get_fileheader_length();	/*;AN000;3*/

	return; 						     /* !wrw */
}								     /* !wrw */


/*********************************************************************/
/*
/*	SUBROUTINE NAME: read_in_first_dirblock
/*
/*	FUNCTION:
/*		Reads in the first directory block
/*		Figures out if it was put there by DOS 3.3 or 4.0
/*********************************************************************/

void read_in_first_dirblock()					     /* !wrw */
{

WORD retcode;		/* return code save area */	     /* !wrw */
WORD read_count;	/* num bytes read in	 */	     /* !wrw */

   /********************************************************************/
   /* READ DIRECTORY_BLOCK INTO STATIC DATA AREA		       */
   /********************************************************************/

      retcode = DOSREAD(					     /* !wrw */
		  control_file_handle,				     /* !wrw */
		  (char far *)&russ_dir_block,			     /* !wrw */
		  (unsigned short)DIRBLKLEN,			     /* !wrw */
		  (unsigned far *)&read_count			     /* !wrw */
		 );						     /* !wrw */

	if (retcode != 0)					     /* !wrw */
	 {							     /* !wrw */
	  display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
	  unexperror(NOBACKUPFILE);				     /* !wrw */
	 }

	got_first_fh = FALSE;					     /* !wrw */
	get_fileheader_length();	/*;AN000;3*/

 return;	/* end subroutine */				     /* !wrw */
}								     /* !wrw */

/**************************************************************/
/*
/*	SUBROUTINE: get_fileheader_length
/*
/*	FUNCTION:   Gets the length of a file header
/*		    Sets BACKUP_LEVEL to indicate which
/**************************************************************/
void get_fileheader_length()
{
	WORD retcode;			/*;AN000;3*/
	WORD read_count;		/*;AN000;3*/
	DWORD file_position;		/*;AN000;3*/

			/* Save current file pointer */
	retcode =					/*;AN000;3*/
	  DOSCHGFILEPTR 				/*;AN000;3*/
	   (						/*;AN000;3*/
	    control_file_handle,	/* Handle */	/*;AN000;3*/
	    (DWORD)0,			/* New location *//*;AN000;3*/
	    (BYTE)1,			/* MOVE METHOD *//*;AN000;3*/
	    (DWORD far *)&file_position 		/*;AN000;3*/
	   );						/*;AN000;3*/

	if (retcode != 0)				/*;AN000;3*/
	 {						/*;AN000;3*/
	  display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
	  unexperror(NOBACKUPFILE);			/*;AN000;3*/
	 }

			/* Read in file header length*/
      retcode = 					/*;AN000;3*/
       DOSREAD						/*;AN000;3*/
	(						/*;AN000;3*/
	  control_file_handle,				/*;AN000;3*/
	  (char far *)&fileheader_length,		/*;AN000;3*/
	  (unsigned short)2,				/*;AN000;3*/
	  (unsigned far *)&read_count			/*;AN000;3*/
	 );						/*;AN000;3*/

	if (retcode != 0 || read_count != 2)		/*;AN000;3*/
	 {						/*;AN000;3*/
	  display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG); /*;AN000;6*/
	  unexperror(NOBACKUPFILE);			/*;AN000;3*/
	 }

			/* Reset file pointer */
	retcode =					/*;AN000;3*/
	  DOSCHGFILEPTR 				/*;AN000;3*/
	   (						/*;AN000;3*/
	    control_file_handle,	/* Handle */	/*;AN000;3*/
	    file_position,		/* New location *//*;AN000;3*/
	    (BYTE)0,			/* MOVE METHOD *//*;AN000;3*/
	    (DWORD far *)&file_position 		/*;AN000;3*/
	   );						/*;AN000;3*/

	return;
}	/* end get_fileheader_length() */


/*   0 */
/**************************************************************/
/*
/*	SUBROUTINE: read_in_a_fileheader
/*
/*	FUNCTION:   Reads in a file header
/*
/**************************************************************/
void read_in_a_fileheader()					     /* !wrw */
{								     /* !wrw */
WORD retcode;		/* return code save area */	     /* !wrw */
WORD read_count;	/* num bytes read in	 */	     /* !wrw */

   retcode = DOSREAD						     /* !wrw */
     (								     /* !wrw */
      control_file_handle,					     /* !wrw */
      (char far *)&russ_file_header,				     /* !wrw */
      fileheader_length,					     /* !wrw */
      (unsigned far *)&read_count				     /* !wrw */
     ); 							     /* !wrw */

   if (retcode != NOERROR)					     /* !wrw */
    {								     /* !wrw */
      display_it(SOURCE_NO_BACKUP_FILE,STND_ERR_DEV,0,NO_RESPTYPE,(BYTE)UTIL_MSG);   /*;AN000;6*/
      unexperror(NOBACKUPFILE); 				     /* !wrw */
    }								     /* !wrw */

    got_first_fh = TRUE;					     /* !wrw */
    fheadnew = (struct file_header_new far *)&russ_file_header;      /* !wrw */

return; 							     /* !wrw */
}								     /* !wrw */
