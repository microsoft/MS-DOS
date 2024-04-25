/*  0 */
/*---------------------------------------------------------
/*-
/*- RESTORE Utility include file RT.H
/*-
/*---------------------------------------------------------*/


/****************************************************************************/
/* This file contains equates for RESTORE utility			    */
/* The equates for messages can be found in rt2.h			    */
/****************************************************************************/

#define BYTE	unsigned char
#define WORD	unsigned short
#define DWORD	unsigned long

#define NOERROR 0
#define CARRY 0x0001				/*;AN000;*/


/*******************************************/
/*    Lengths of CONTROL.xxx structures    */
/*******************************************/
#define DHEADLEN	     139	/* length of new format disk header */
#define DIRBLKLEN	      70	/* length of new format dir block   */
#define FHEADLEN34	      38	/*;AN000;3 Length of new format file header */ /* !wrw */
#define FHEADLEN33	      34	/* length of DOS 3.3 file header */ /* !wrw */

/****************************************************************************/
/*  The following group of definitions are used to set and test the restore */
/*  switch flags.							    */
/****************************************************************************/

#define PROMPT		 1  /* Prompt user before restoring hidden and	     */
			    /* read-only files. 			     */
#define SUB		 2  /* Restore all subdirectories too		     */
#define BEFORE		 4  /* Only restore files written before a date      */
#define AFTER		 8  /* Only restore files written after a date	     */
#define EARLIER 	16  /* Only restore files written earlier then a time*/
#define LATER		32  /* Only restore files written later than a time  */
#define Revised	64  /* Only restore files that have changed	     */
#define NOTEXIST       128  /* Only restore files that no longer exist on    */
			    /* the destination drive.			     */


/****************************************************************************/
/*  The following group of definitions are used to set and test the	    */
/*  restore control flags:control_flag. 				    */
/****************************************************************************/

#define WILDCARD	 1  /* Wildcards in input filespec		*/
#define OLDNEW		 2  /* indicate old format or new format	*/
#define CREATIT 	 4  /* Restore file does not exist on dest disk */
#define FOUND		 8  /* Found a file to restore			*/
#define SPLITFILE	16  /* File was backed up onto 2 or more disks	*/
#define SWITCHES	32  /* There are switches set			*/
#define SHARERROR	64  /* There is a file not restored due to	*/
			    /* sharing error				*/
#define PARTIAL        128  /* Set if file partially restored		*/

/****************************************************************************/
/*  The following group of definitions are used to set and test the restore */
/*   control flags:control_flag2					    */
/****************************************************************************/

#define SPLITCTL	 1  /* Indicate whether control.xxx is larger	*/
				/* then MAXCTRL 			    */
#define RTSYSTEM	 2  /* The file to be restore is system file	*/
				/* it has to be restored contiguously	    */
#define COUNTRY 	 4  /*when the bit is on, country info is available */
#define CPPC		 8  /* bit = 1 when CP/DOS, otherwise, PC/DOS	    */
#define SRC_HDISK	16  /* bit = 1 when the source disk is harddisk     */
#define TAR_HDISK	32  /* bit = 1 when the target disk is harddisk     */
#define OUTOF_SEQ	64  /* bit = 1 when the disk is out of sequence     */
/****************************************************************************/
/*  Miscelleneous definitions						    */
/****************************************************************************/
#define ON		 1	/* the tested bit is on*/
#define OFF		 0	/* the tested bit is off */

#define BACKUPID    "BACKUPID.@@@"  /* Used to reference that file           */
#define HEADLEN        128	/* Backup file header length		     */
#define MAXARGS 	11	/* Max # of arguments			     */
#define MINARGS 	 1	/* Minimum # of arguments		     */
#define MAXBUF	    0xffff	/* Max size of buf			     */
#define DOWNSIZE       512	/* Amount to decrement memory request size   */
				/* by when doing a series of mallocs.	     */
#define MAXPATH 	65	/* Length of space allocate for path names   */
#define MAXFNAME	 9	/* Max length of file name		     */
#define MAXFEXT 	 4	/* Max length of file extension 	     */
#define MAXFSPEC	13	/* Max length of file spec.		     */
#define MAXPATHF	78	/* Max length of path and file spec	     */
#define MAXYEARLEN	 4	/* Max length of string that represent year  */
#define MAXMONTHLEN	 2	/* Max length of string that represent month */
#define MAXDAYLEN	 2	/* Max length of string that represent day   */
#define MINYEAR       1980	/* Min value of input year		     */
#define MAXYEAR       2079	/* Max value of input year		     */
#define MAXMONTH	12	/* Max value of input year		     */
#define MAXDAY		31	/* Max value of input year		     */
#define MAXHOURLEN	 2	/* Max length of string that represent hour  */
#define MAXMINUTELEN	 2	/* Max length of string that represent minute*/
#define MAXSECONDLEN	 2	/* Max length of string that represent second*/
#define NUL		 0	/* The null character			     */
#define NULLC	    '\000'      /* The null character                        */
#define MAXCTRL       3072	/* size of buffer to contain control.xxx     */
#define BKIDLENG	 7	/* the lenght of old format disk header      */
#define NEWBKIDLENG    139	/* the length of new format disk header      */
#define NOTV	      0x16	/* all file attrs except vol id 	     */
#define ON		 1	/* the tested bit is on*/
#define OFF		 0	/* the tested bit is off */
#define TRUE		 0	/* return code, no error		     */
#define FALSE		 1	/* return code, there is an error	     */
#define TTRUE		 1	/* return code, no error		     */
#define FFALSE		 0	/* return code, there is an error	     */
#define LAST_PART     0x01	/* the flag in finfo->fflag		     */
				/* if on, the file is last part of a file    */
#define COMPLETE_BIT  0x02	/* the complete bit in fheadnew->flag	     */
				/* if on, the file was backed up sucessfully */
#define USA	0
#define EUR	1
#define JAP	2
#define INSTALL_SIGNAL	       2	/* active signal handler routine    */
#define DEACTIVE_SIGNAL        1	/* ignor signals		    */
#define CTRL_C		       1	/* control_c signal		    */
#define CTRL_BREAK	       4	/* control break signal 	    */

/****************************************************************************/
/*   Defines for common subroutines - comgetarg and computmsg		    */
/****************************************************************************/

#define  RESPDATA_SIZE	       1	/* size of the respdata */
#define  STND_IN_DEV	       0	/* standard out device		    */
#define  STND_OUT_DEV	       1	/* standard out device		    */
#define  STND_ERR_DEV	       2	/* standard error device	    */
#define  NO_RESPTYPE	       0	/*response type is no user	    */
					/*interaction			    */
#define  ANY_KEY_RESPTYPE      1	/*response type is ask user to enter*/
					/*any key.			    */
#define  ENTER_Y	       0	/*user enter yes as response	    */
#define  ENTER_N	       1	/*user enter no  as response	    */

/****************************************************************************/
/*   Defines for convert date format					    */
/****************************************************************************/

#define HRSHIFT   11	       /* shift 11 bits to get the value of hour    */
#define HRMASK	0x1F	       /* mask to get the value of hour 	    */
#define MNSHIFT    5	       /* shift 5  bits to get the value of minute  */
#define MNMASK	0x3F	       /* mask to get the value of minute	    */
#define SCMASK	0x1F	       /* mask to get the value of second	    */
#define MOSHIFT    5	       /* shift 5  bits to get the value of month   */
#define MOMASK	0x0F	       /* mask to get the value of month	    */
#define DYMASK	0x1F	       /* shift 9  bits to get the value of day     */
#define YRSHIFT    9	       /* mask to get the value of day		    */
#define YRMASK	0x7F	       /* mask to get the value of year 	    */
#define USA	   0
#define EUR	   1
#define JAP	   2
#define LOYR	1980

/****************************************************************************/
/*  Defines for subroutine set_reset_test_flag				    */
/****************************************************************************/
#define SET	   0
#define RESET	   1
#define TEST	   2

/****************************************************************************/
/*  Defines for file attribut byte					    */
/****************************************************************************/
#define READONLY   1	 /*the file is marked read only 	  */
#define HIDDEN	   2	 /*the file is marked hidden file	  */
#define SYSTEM	   4	 /*the file is marked system file	  */
#define VOLUME	   8	 /*the entry contains a volume label	  */
#define SUBDIR	  16	 /*the entry is a subdirectory name	  */
#define ARCHIVE   32	 /*the archieve bit of the file 	  */

/****************************************************************************/
/*  Defines for PCDOS return levels					    */
/****************************************************************************/

#define PC_NORMAL	  0
					/* Normal completion		  */
#define PC_NOFILES	  1
					/* no fl were found to restore	  */
#define PC_SHARERR	  2
			   /* Some file not restored due to sharing error */
#define PC_TUSER	  3
					/* Terminated by user		  */
#define PC_OTHER	  4
					/* Terminated by user		  */
/****************************************************************************/
/*  Defines for CPDOS return codes					    */
/****************************************************************************/

#define NORMAL	       NO_ERROR
					/* Normal completion */
#define NOFILES        ERROR_FILE_NOT_FOUND
					/* no fl were found to restore */
#define SHARERR        ERROR_SHARING_VIOLATION
			   /* Some file not restored due to sharing error */
#define TUSER	       1026
					/* Terminated by user */
#define INSUFMEM       ERROR_NOT_ENOUGH_MEMORY
					/* insufficient memory */
#define NOBACKUPFILE   1027
					/* source does not contain bk file*/
#define INVALIDPARM    ERROR_INVALID_PARAMETER
					/* invalid parmameter */
#define INVALIDDRIVE   ERROR_INVALID_DRIVE
					/* invalid drive */
#define FILESEQERROR   1028
					/* file seq error */
#define TARGETFULL     ERROR_DISK_FULL
					/* target disk is full */
#define UNEXPECTED	  999
					/* unexpected error */
#define CREATIONERROR  1029
					/* file creation error */
	/************************************************/
	/*    Substitution List for Message Retriever	*/
	/************************************************/
/*-----------------------
; SUBLIST Equates
;------------------------*/
#define SUBLIST_SIZE	11	     /*;AN000;6 */

#define LEFT_ALIGN	      0x0    /*;AN000;6 00xxxxxx  */
#define RIGHT_ALIGN	      0x80   /*;AN000;6 10xxxxxx  */

#define CHAR_FIELD_CHAR       0x0    /*;AN000;6 a0000000  */
#define CHAR_FIELD_ASCIIZ     0x10   /*;AN000;6 a0010000  */

#define UNSGN_BIN_BYTE	      0x11   /*;AN000;6 a0010001 - Unsigned BINary to Decimal CHARacter */
#define UNSGN_BIN_WORD	      0x21   /*;AN000;6 a0100001  */
#define UNSGN_BIN_DWORD       0x31   /*;AN000;6 a0110001  */

#define SGN_BIN_BYTE	      0x12   /*;AN000;6 a0010010 - Signed BINary to Decimal CHARacter */
#define SGN_BIN_WORD	      0x22   /*;AN000;6 a0100010  */
#define SGN_BIN_DWORD	      0x32   /*;AN000;6 a0110010  */

#define BIN_HEX_BYTE	      0x13   /*;AN000;6 a0010011 - Unsigned BINary to Hexidecimal CHARacter */
#define BIN_HEX_WORD	      0x23   /*;AN000;6 a0100011  */
#define BIN_HEX_DWORD	      0x33   /*;AN000;6 a0110011  */


#define DATE_MDY_4	     0x34    /*;AN000;6 MONTH,DAY AND YEAR (4 DIGITS)*/
/*------------------------------------*/
/*-	   MESSAGE CLASSES	     -*/
/*------------------------------------*/
#define EXTENDED	1	/*;AN000;6*/
#define PARSEERROR	2	/*;AN000;6*/
#define UTIL_MSG       -1	/*;AN000;6*/

#define CR		0x0d		/*;AN000;6*/
#define LF		0x0a		/*;AN000;6*/
/*-------------------------------
/*-	INT 21h
/*-------------------------------*/
#define SETLOGICALDRIVE  0x440f 			/*;AN000;8*/

#define INSTALL_CHECK	0xB700			/*;AN000;2*/
#define NOT_INSTALLED 0 			/*;AN000;2*/
#define GET_APPEND_VER	0xB702			/*;AN000;2*/
#define NET_APPEND    1 			/*;AN000;2*/
#define DOS_APPEND    2 			/*;AN000;2*/
#define GET_STATE	0xB706			/*;AN000;2*/
#define SET_STATE	0xB707			/*;AN000;2*/

#define APPEND_X_BIT	0x8000			/*;AN000;2*/

