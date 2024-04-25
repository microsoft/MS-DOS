/*  0 */
/*---------------------------------------------------------
/*-
/*- RESTORE Utility include file RT1.H
/*-
/*---------------------------------------------------------*/

/****************************************************************************/
/* This file contains equates for structure definitions used in RESTORE     */
/* utility.								    */
/****************************************************************************/

/***************************************************************************/
/*    dheadnew - structure of disk header in CONTROL.xxx,		   */
/*		 used for new format only				   */
/***************************************************************************/
struct disk_header_new
 {
   BYTE  dhlength;	   /* length, in byte , of disk header*/
   BYTE  id[8]; 	   /* identifies disk as a backup     */
   BYTE  sequence;	   /* backup diskette sequence num    */
			   /*	 (binary 1-255) 	      */
   BYTE  command[128];	   /* save area for command line      */
			   /*	  parameters.		      */
   BYTE  lastdisk;	   /* 0ffh if last targert 0 otherwise*/
 };


/***************************************************************************/
/*    dirblk - structure of directory blocks in CONTROL.xxx,		   */
/*		 used for new format only				   */
/***************************************************************************/
struct dir_block
 {
   BYTE dblength;	  /* length, in bytes, of dir block */
   BYTE path[63];
			  /* ascii path of this directory,  */
			  /* drive letter omitted	    */
   WORD  numentry;	  /* num of filenames currently in list*/
   DWORD nextdb;	  /* offset of next directory block  */
 };			  /* =0xffff if last dir block	     */


/***************************************************************************/
/*    fheadnew - structure of file header in CONTROL.xxx,		   */
/*		 used for new format only				   */
/***************************************************************************/
#define EXT_ATTR_FLAG	4					      /*;AN000;3*/

struct file_header_new
 {
   BYTE   fhlength;	/* Length, in bytes, of file header */
   BYTE   fname[12];	/* ASCII file name (from directory)*/
   BYTE   flag; 	/* bit 0=1 if last part of file */
			/* bit 1=1 if it is backed  up successfully */
			/* ;AN000;3 bit 2=1 if Extended Attributes are backed up (New for DOS4.00) */
   DWORD  flength;	/* Total length of the file (from directory) */
   WORD   fsequenc;	/* Sequence #, for files that span */
   DWORD  offset;	/* Offset in BACKUP.xxx where this segment begins */
   DWORD  partsize;	/* Length of part of file on current target */
   WORD   attrib;	/* File attribute (from directory) */
   WORD   ftime;	/* Time when file was last Revised (from directory)*/
   WORD   fdate;	/* Date when file was last Revised (from directory)*/
   DWORD  FH_EA_offset; /*;AN000;3 Offset in BACKUP.xxx where extended attrib begin */
 };

/*----------------------------------*/
/*-  EXTENDED OPEN PARAMETER LIST  -*/
/*----------------------------------*/
#define EXTATTBUFLEN 4086					      /*;AN000;3*/
 struct parm_list						      /*;AN000;3*/
  {								      /*;AN000;3*/
    DWORD	ext_attr_addr;					      /*;AN000;3*/
    WORD	num_additional; 				      /*;AN000;3*/
  };								      /*;AN000;3*/










/**************************************************************************/
/*    Fheadold - structure of file header, used for old format only.	  */
/*		 There are 128 bytes totally in file header of the old	  */
/*		 format backup disk.  Only the first 85 bytes contains	  */
/*		 meaningful information.				  */
/*		This is the structure attached to the beginning of every  */
/*		file backed up with DOS 2.0 through 3.2 inclusive.	  */
/**************************************************************************/
struct file_header_old
 {
   BYTE headflg;	 /* 0FFh is last sequence of file, 00h if not last*/
   BYTE disknum[2];	 /* file sequence number */
   BYTE fill1[2];	 /* not used */
   BYTE wherefrom [78];  /* asciiz path and name without drive letter*/
   unsigned  pathlen;	 /* length of previous field, not used in this program*/
   char garbage[50];	 /* Filler     */
 };




/***************************************************************************/
/*    dheadold - structure of disk informtion, used by old format only.    */
/*		 There are 128 bytes totally in disk header of the old	   */
/*		 format backup disk.  Only the first 7 bytes contains	   */
/*		 meaningful information.				   */
/*		This is the BACKUPID.@@@ file				   */
/***************************************************************************/

struct disk_header_old
 {
   BYTE  diskflag;	/* 0FFh if last disk, 00h if not last disk. */
			/* initialize it to 0FFh when BACKUP.@@@ is created,*/
			/* and zero it out when the disk is full */
   BYTE  disknum[2];	/* Sequence number of the disk.  Least significant*/
			/* byte first. */
   BYTE  diskyear[2];	/* Year, LSB first. */
   BYTE  diskday;	/* Month (1 byte) and day (1 byte). */
   BYTE  diskmonth;	/* Month (1 byte) and day (1 byte). */
 };


/***************************************************************************/
/*    timedate- structure of buffer to hold time and date data		  */
/***************************************************************************/
struct timedate {
   unsigned int  earlier_hour;
   unsigned int  earlier_minute;
   unsigned int  earlier_second;
   unsigned int  later_hour;
   unsigned int  later_minute;
   unsigned int  later_second;
   unsigned int  before_year;
   unsigned int  before_month;
   unsigned int  before_day;
   unsigned int  after_year;
   unsigned int  after_month;
   unsigned int  after_day;
};
/***************************************************************************/
/*    fsinfo - structure of buffer returned from dosqsinfo		 */
/***************************************************************************/
struct fsinfo { 		     /* file system information 	   */
  unsigned long file_system_id;      /* file system ID			4  */
  unsigned long sectors_per_alloc_unit;  /* sectors per allocation unit 4  */
  unsigned long number_of_alloc_unit;	 /* number of allocation unit	4  */
  unsigned long available_alloc_unit;	 /* available allocatuib unit	4  */
  unsigned	bytes_per_sector;    /* number of bytes per sectors	2  */
};				     /*     total byte size = 18	 */

#define FSINFO_BYTES  sizeof(struct fsinfo)  /* total # of bytes for BPB */

/***************************************************************************/
/*  internat - structure of buffer returned from get country information   */
/***************************************************************************/
struct internat {
unsigned       country_code;	/* country code 	       */
unsigned       code_page;	/* country code page	       */
unsigned       dtformat;	/* time date format	       */
				/* 0-usa 1-eur 2-jap	       */
BYTE  currency_sym,    /* Currency Symbol 5 bytes     */
		r1,
		r2,
		r3;
BYTE   r4;		/* null terminated	       */
BYTE   thous_sep,	/* Thousands separator 2 bytes */
		r5;		 /* null terminated		*/
BYTE   decimal_sep,	/* Decimal separator 2 bytes   */
		r6;		 /* null terminated		*/
BYTE   datesep, 	/* Date separator 2 bytes      */
		r7;		 /* null terminated		*/
BYTE   timesep, 	/* Time separator 2 bytes      */
		r8;		 /* null terminated		*/
BYTE   bit_field;	/* Bit values		       */
				 /*  Bit 0 = 0 if currency symbol first */
				 /*	   = 1 if currency symbol last	*/
			   /* Bit 1= 0 if No space after currency symbol*/
			   /*	   = 1 if space after currency symbol	*/
BYTE currency_cents;  /* Number of places after currency dec point*/
BYTE tformat;	      /* 1 if 24 hour time, 0 if 12 hour time	  */
unsigned long map_call;        /* Address of case mapping call (DWORD)	   */
			       /* in real mode compatibility API	   */
BYTE data_sep,	      /* Data list separator character		  */
	      r9;	       /* null terminated	      */
unsigned      ra[ 5 ];	       /* reserved		      */
} ;


/***************************************************************************/
/*    Finfo  - structure of file information, used for both old format and */
/*	       new format.  It contains the information which is common    */
/*	       between new and old.					   */
/***************************************************************************/
struct file_info
  {
    BYTE  fname[MAXFSPEC+1];	/* ASCII, filename and file extension.*/
    BYTE  path[MAXPATH+1];	/* ASCII, file path, always started with \ */
				/* and not end with \ */
    BYTE  fflag;		/* last disk in case of file expanded */
				/* bit 0 = 1 if last part of file		   */
				/* In old format file header, its 0ffh if last.  */
				/* The old format has to be converted into bit0=1.*/
    unsigned dnum;		/* sequence number of the file.  For file that span */
    unsigned attrib;		/* file attribute */
    unsigned ftime;		/* time when the file was created  */
    unsigned fdate;		/* date when the file was created  */
    unsigned long  partsize;	/* part size of the file   */
    unsigned long  offset;	/* offset of the file in backup.xxx  */
    BYTE curdir[MAXPATH];	/* current directory of the destination disk.*/
				/* The current directory usually is maintained to be*/
				/* the directory that reside the file to be restored*/
    DWORD  ea_offset; /*;AN000;3 Offset in BACKUP.xxx where extended attrib begin */
};

/****************************************************************************/
/*    dfinfo  - destination file information, if the destination file	    */
/*		is exist. Structure of file information, used for both old  */
/*		format and new format.	It contains the information which is*/
/*		common between new and old.				    */
/****************************************************************************/
struct dfile_info {
BYTE fname[12]; 	 /* ASCII, filename and file extension.*/
BYTE path[64];		 /* ASCII, file path, always started with \ and */
			 /* not end with \ */
BYTE fflag;		 /* last disk in case of file expanded */
			 /* bit 0 = 1 if last part of file		    */
			 /* In old format file header, its 0ffh if last.  */
			 /* The old format has to be converted into bit0=1.*/
unsigned short dnum;	 /* sequence number of the file.  For file that span */
unsigned attrib;	 /* file attribute */
unsigned ftime; 	 /* time when the file was created  */
unsigned fdate; 	 /* date when the file was created  */
BYTE *curdir;		 /* current directory of the destination disk.	  */
		   /* The current directory usually is maintained to be */
		   /* the directory that reside the file to be restored */
};

/***************************************************************************/
/*    dinfo  - structure of disk information, used for both old format and */
/*	       new format.  It contains the information which is common    */
/*	       between new and old.					   */
/***************************************************************************/
struct disk_info {
BYTE dflag;	/* last backup disk or not */
			/* Its 0ffh if last.  00h otherwise */
BYTE disknum;  /* sequence number of the file.	For file that span */
};
 struct subst_list							/*;AN000;6 */
  {									/*;AN000;6 */
    BYTE	sl_size1;      /* Size of List */			/*;AN000;6 */
    BYTE	zero1;	       /* Reserved */				/*;AN000;6 */
    char far   *value1;        /* Time, date, or ptr to data item*/	/*;AN000;6 */
    BYTE	one;	       /* n of %n */				/*;AN000;6 */
    BYTE	flags1;        /* Data Type flags */			/*;AN000;6 */
    BYTE	max_width1;    /* Maximum FIELD width */		/*;AN000;6 */
    BYTE	min_width1;    /* Minimum FIELD width */		/*;AN000;6 */
    BYTE	pad_char1;     /* Character for pad FIELD */		/*;AN000;6 */

    BYTE	sl_size2;      /* Size of List */			/*;AN000;6 */
    BYTE	zero2;	       /* Reserved */				/*;AN000;6 */
    char far   *value2;        /* Time; date; or ptr to data item*/	/*;AN000;6 */
    BYTE	two;	       /* n of %n */				/*;AN000;6 */
    BYTE	flags2;        /* Data Type flags */			/*;AN000;6 */
    BYTE	max_width2;    /* Maximum FIELD width */		/*;AN000;6 */
    BYTE	min_width2;    /* Minimum FIELD width */		/*;AN000;6 */
    BYTE	pad_char2;     /* Character for pad FIELD */		/*;AN000;6 */
  };									/*;AN000;6 */

