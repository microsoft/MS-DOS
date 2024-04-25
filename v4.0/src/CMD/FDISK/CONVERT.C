
#include "fdisk.h"                                                      /* AN000 */
#include "subtype.h"                                                    /* AN000 */
#include "dos.h"                                                        /* AN000 */
#include "extern.h"                                                     /* AN000 */
#include "string.h"
#include "ctype.h"


/******************************************************************************/
/*Routine name:  MBYTES_TO_CYLINDERS                                          */
/******************************************************************************/
/*                                                                            */
/*Description:   This routine will take input of MBtes and                    */
/*               convert it to cylinders rounding up to the next largest      */
/*               cylinder boundry.  Rounding up is done to make sure the      */
/*               requester is getting at least what he asked for to the       */
/*               next cylinder boundry.                                       */
/*                                                                            */
/*Called Procedures:    none                                                  */
/*                                                                            */
/*                                                                            */
/*Change History: Created        5/30/87         DRM                          */
/*                                                                            */
/*Input: Input                                                                */
/*                                                                            */
/*Output: Cylinders_out                                                       */
/*                                                                            */
/******************************************************************************/


unsigned  mbytes_to_cylinders(mbytes_in,which_disk)                     /* AN004 */

XFLOAT          mbytes_in;                                              /* AN000 */
char            which_disk;                                             /* AN004 */



BEGIN                                                                   /* AN000 */

unsigned        cylinders_out;                                          /* AN000 */
unsigned long   cylinders_out1;                                         /* AN000 */
unsigned long   number_of_sectors;                                      /* AN000 */
unsigned long   number_of_tracks;                                       /* AN000 */
unsigned long   divide_by;                                              /* AN000 */

           /* If trying to create a 3.30 compatible 32 MB partition */
           /* Set the 32mb limit - round down                       */
           if (mbytes_in == (XFLOAT)32)
               BEGIN
               cylinders_out1 = ul(DOS_MAX - max_sector[which_disk]);           /* AN004 */
               divide_by = ul((max_head[which_disk]) * ul(max_sector[which_disk])); /* AN004 */
               cylinders_out = u(cylinders_out1 / divide_by);                   /* AN000 */
               END
           else
               BEGIN
               number_of_sectors = ul(((mbytes_in * ONE_MEG)/BYTES_PER_SECTOR)); /* AN000 */
               if (((int)(mbytes_in * ONE_MEG) % BYTES_PER_SECTOR) != (int)0)    /* AN000 */
                 number_of_sectors++;                                            /* AN000 */
               number_of_tracks = ul((number_of_sectors / max_sector[which_disk]));  /* AN004 */
               if (((int)number_of_sectors % max_sector[which_disk]) != (int)0)  /* AN004 */
                  number_of_tracks++;                                            /* AN000 */
               cylinders_out = u((number_of_tracks / max_head[which_disk]));     /* AN004 */
               if (((int)number_of_tracks % max_head[which_disk]) != (int)0)     /* AN004 */
                  cylinders_out++;                                          /* AN000 */
               END

           return(cylinders_out);                                       /* AN000 */
END                                                                     /* AN000 */



/*  */
/*******************************************************************************/
/*Routine name:  CYLINDERS_TO_MBYTES                                           */
/*******************************************************************************/
/*                                                                             */
/*Description:   This routine will take input of cylinders and convert         */
/*               it to MBytes.                                                 */
/*                                                                             */
/*                                                                             */
/*Called Procedures:                                                           */
/*                                                                             */
/*                                                                             */
/*Change History: Created        5/16/87         DRM                           */
/*                                                                             */
/*Input: Cylinders_in                                                          */
/*                                                                             */
/*Output: MBytes_out                                                           */
/*                                                                             */
/*                                                                             */
/*                                                                             */
/*******************************************************************************/

XFLOAT     cylinders_to_mbytes(cylinders_in,which_disk)                 /* AN004 */

unsigned        cylinders_in;                                           /* AN000 */
char            which_disk;                                             /* AN004 */

BEGIN                                                                   /* AN000 */

unsigned         mbytes_out;                                            /* AN000 */
unsigned long    number_of_bytes;                                       /* AN000 */
unsigned long    number_of_sectors;                                     /* AN000 */
unsigned long    number_of_tracks;                                      /* AN000 */
unsigned long    bytes_in_one_sector;                                   /* AN004 */

     bytes_in_one_sector = BYTES_PER_SECTOR;                            /* AN004 */
     number_of_tracks = (ul(cylinders_in) * ul(max_head[which_disk]));  /* AN004 */
     number_of_sectors = (number_of_tracks * ul(max_sector[which_disk])); /* AN004 */
     number_of_bytes = (ul(number_of_sectors) * ul(bytes_in_one_sector)); /* AN004 */
     mbytes_out =  f(number_of_bytes / ONE_MEG);                        /* AN000 */
     if ((number_of_bytes % ONE_MEG) >= (ONE_MEG / 2)) mbytes_out++;    /* AN000 */
     return(mbytes_out);                                                /* AN000 */

END                                                                     /* AN000 */




/*  */
/*******************************************************************************/
/*Routine name:  CYLINDERS_TO_PERCENT                                          */
/*******************************************************************************/
/*                                                                             */
/*Description:   This routine will take input of cylinders and convert         */
/*               it to Percent.                                                */
/*                                                                             */
/*                                                                             */
/*Called Procedures:                                                           */
/*                                                                             */
/*                                                                             */
/*Change History: Created        5/16/87         DRM                           */
/*                                                                             */
/*Input: Cylinders_in                                                          */
/*                                                                             */
/*Output: percent_out                                                          */
/*                                                                             */
/*                                                                             */
/*                                                                             */
/*******************************************************************************/

unsigned  cylinders_to_percent(cylinders_in,total_cylinders)            /* AN000 */

unsigned      cylinders_in;                                             /* AN000 */
unsigned      total_cylinders;                                          /* AN000 */

BEGIN                                                                   /* AN000 */

unsigned      percentage_out;                                           /* AN000 */
double        large_number;                                             /* AN000 */

     /* This is the same as (cyl_in / tot_cyl) * 100 to get the percentage */
     /* because * 100 is really 100/1 which is (cyl_in*100)/(tot_cyl*1).   */

     if (total_cylinders == 0)
         percentage_out = 0;
     else
         BEGIN
         large_number = (double)((long)cylinders_in * 100l);            /* AN000 */
         percentage_out = u(large_number / total_cylinders);            /* AN000 */
         END
     /* this should round up to the next percent if more than .5 percent */
     if (((cylinders_in * 100) % total_cylinders) >= (total_cylinders / 2))
       percentage_out++;                                                /* AN000 */
     if (percentage_out > u(100)) percentage_out = u(100);              /* AN000 */
     return(percentage_out);                                            /* AN000 */
END                                                                     /* AN000 */



/*  */
/******************************************************************************/
/*Routine name:  PERCENT_TO_CYLINDERS                                         */
/******************************************************************************/
/*                                                                            */
/*Description:   This routine will take input of percentage and               */
/*               convert it to cylinders rounding up to the next largest      */
/*               cylinder boundry.  Rounding up is done to make sure the      */
/*               requester is getting at least what he asked for to the       */
/*               next cylinder boundry.                                       */
/*                                                                            */
/*Called Procedures:    none                                                  */
/*                                                                            */
/*                                                                            */
/*Change History: Created        5/30/87         DRM                          */
/*                                                                            */
/*Input: Input                                                                */
/*                                                                            */
/*Output: Cylinders_out                                                       */
/*                                                                            */
/******************************************************************************/


XFLOAT percent_to_cylinders(percent_in,total_cylinders)                 /* AN000 */

unsigned     percent_in;                                                /* AN000 */
XFLOAT       total_cylinders;                                           /* AN000 */


BEGIN                                                                   /* AN000 */

        XFLOAT       cylinders_out;                                     /* AN000 */
#if IBMCOPYRIGHT
        cylinders_out = ((percent_in * total_cylinders) / 100);         /* AN000 */
#else
        cylinders_out = (unsigned)((ul(percent_in) * ul(total_cylinders)) / 100);
#endif
        if (((percent_in * total_cylinders) % 100) != u(0))             /* AN000 */
           cylinders_out++;                                             /* AN000 */
        return(cylinders_out);                                          /* AN000 */
END                                                                     /* AN000 */






/*  */
/*******************************************************************************/
/*Routine name:  DOS_UPPER                                                     */
/*******************************************************************************/
/*                                                                             */
/*Description:   This routine will uppcase a character using get country       */
/*               information (65H) with the capitalize single character        */
/*               call (20H).                                                   */
/*                                                                             */
/*Called Procedures:                                                           */
/*                                                                             */
/*                                                                             */
/*                                                                             */
/*Change History: Updated        5/31/87         DRM                           */
/*                                                                             */
/*Input: drive_value                                                           */
/*                                                                             */
/*Output: input_value                                                          */
/*                                                                             */
/*******************************************************************************/

char dos_upper(drive_value)                                             /* AN000 */

char drive_value;                                                       /* AN000 */

BEGIN                                                                   /* AN000 */

          char output;                                                  /* AN000 */

            regs.x.ax = (unsigned)CAPCHAR;   /* Get extended country information - AN000 */
            regs.h.dl = (unsigned char)drive_value;     /* Move input_value to register DL  - AN000 */
            int86((int)INT21,&regs,&regs);                              /* AN000 */
            output  = (char)regs.h.dl;                                  /* AN000 */

#ifdef DEBUG
            output = toupper(drive_value);
#endif

            return(output);                                             /* AN000 */
END                                                                     /* AN000 */





/*  */
/*******************************************************************************/
/*Routine name:  CHECK_YN_INPUT                                                  */
/*******************************************************************************/
/*                                                                             */
/*Description:   Get single character input, which must be a country           */
/*               dependent (Y/N).  Will be verified using new uppercase table  */
/*               function calls.  Will accept default value.                   */
/*                                                                             */
/*Called Procedures:                                                           */
/*                                                                             */
/*                                                                             */
/*                                                                             */
/*Change History: Updated        5/31/87         DRM                           */
/*                                                                             */
/*Input: input_value                                                           */
/*                                                                             */
/*Output: input                                                                */
/*        valid_input                                                          */
/*                                                                             */
/*******************************************************************************/

char check_yn_input(input_value)                                        /* AN000 */

         char   input_value;                                            /* AN000 */

BEGIN
         char   input;                                                  /* AN000 */

         /* Get extended country information */
         regs.x.ax = (unsigned)CAP_YN;                                  /* AN000 */
         /* Move input_value to register DL  */
         regs.h.dl = (unsigned char)input_value;                        /* AN000 */
         int86((int)INT21,&regs,&regs);                                 /* AN000 */

         /* check carry flag for error */
         if ((regs.x.cflag & CARRY_FLAG) == CARRY_FLAG)                 /* AN000 */
         /* input will be 0 for NO and 1 for YES in AX */
            input = c(NO_GOOD);    /* input will equal not 0 or 1 */    /* AN000 */
         else                                                           /* AN000 */
            input = c(regs.x.ax);                                       /* AN000 */

#ifdef DEBUG

        input = NO_GOOD;
        if ( (input_value == (char) 'Y') || (input_value == (char) 'y') ) input = c(1);
        if ( (input_value == (char) 'N') || (input_value == (char) 'n') ) input = c(0);

#endif

         return(input);                                                 /* AN000 */
END                                                                     /* AN000 */




/*  */
/*******************************************************************************/
/*Routine name:  GET_FS_AND_VOL                                                */
/*******************************************************************************/
/*                                                                             */
/*Description:   This routine will invoke INT21 44h (Block Generic IOCTL       */
/*               Subfunction) call to get volume label and file system type.   */
/*                                                                             */
/*Called Procedures:                                                           */
/*                                                                             */
/*Change History: Created        6/01/87         DRM                           */
/*                                                                             */
/*Input: input_drive                                                           */
/*                                                                             */
/*Output: pointer to dx register                                               */
/*                                                                             */
/*******************************************************************************/

FLAG get_fs_and_vol(input_drive)                                        /* AN000 */

          char input_drive;                                             /* AN000 */

BEGIN                                                                   /* AN000 */

          char output;

          /* Set up registers for Generic IOCTL INT21 (44h) get media ID */
          regs.x.ax = u(GENERIC_IOCTL);                                 /* AN000 */
          regs.h.bh = uc(ZERO);                                         /* AN000 */
          regs.h.bl = (((unsigned char)input_drive - 'A') + 1);        /* AN000 */
          regs.x.cx = u(GET_MEDIA_ID);                                  /* AN000 */
          regs.x.dx = (unsigned)&dx_buff;                               /* AN000 */
          segread(&segregs);
          intdosx(&regs,&regs,&segregs);                                /* AN000 */

          /* see if carry flag was zero or one */
          if ((regs.x.cflag & CARRY_FLAG) == CARRY_FLAG)                /* AN000 */
             output = FALSE;                                            /* AN000 */
          else                                                          /* AN000 */
             output = TRUE;                                             /* AN000 */

          return(output);                                               /* AN000 */
                                                                        /* AN000 */
END



/*  */
/*******************************************************************************/
/*Routine name:  GET_VOLUME_STRING                                             */
/*******************************************************************************/
/*                                                                             */
/*Description:   This routine will invoke INT21 4Eh (Find First Matching File) */
/*               and return the disk volume label.                             */
/*                                                                             */
/*Called Procedures:                                                           */
/*                                                                             */
/*Change History: Created        6/01/87         DRM                           */
/*                                                                             */
/*Input: input_drive                                                           */
/*                                                                             */
/*Output: volume_out                                                           */
/*                                                                             */
/*******************************************************************************/
void get_volume_string(input_drive,vol_label_addr)                      /* AN000 */
        char input_drive;                                               /* AN000 */
        char *vol_label_addr;                                           /* AN000 */
BEGIN                                                                   /* AN000 */

          char  first_string[13];                                       /* AC000 */
          char  find_first_buffer[50];                                  /* AN000 */
          unsigned i,j;                                                 /* AC000 */

          /* clear out any garbage in volume label field */
          for (i = u(0); i < u(12); i++)                                /* AN015 */
              BEGIN                                                     /* AN015 */
                  vol_label_addr[i] = u(0);                             /* AN015 */
              END                                                       /* AN015 */

          /* Point the DTA to our buffer so we can get the FindFirst output */
          regs.h.ah = uc(0x1A);                                         /* AN000 */
          regs.x.dx = (unsigned)&find_first_buffer[0];                      /* AN000 */
          segread(&segregs);
          intdosx(&regs,&regs,&segregs);                                /* AN000 */

          /* Find the first volume id */
          first_string[0] = input_drive;       /* Find the vol label  -   AN000 */
          first_string[1] = (char) '\0';
          strcat(first_string,FILE_NAME);                               /* AN000 */
          regs.h.ah = uc(FIND_FIRST_MATCH);                             /* AN000 */
          regs.x.cx = u(VOL_LABEL);                                     /* AN000 */
          regs.x.dx = (unsigned)&first_string[0];                           /* AN000 */
          intdos(&regs,&regs);                                /* AN000 */

/* AC000 The following is modified to take care of "." in the middle of the */
/*name */

          if ((regs.x.cflag & CARRY_FLAG) != CARRY_FLAG)                /* AN000 AC015 */
            BEGIN                                                       /* AN000 */
            for (i=j=u(0); i < strlen (&find_first_buffer[30]) ; i++)   /* AN000 */
                BEGIN                                                   /* AN000 */
                if (find_first_buffer[30+i] != PERIOD)                  /* AN003 */
                        vol_label_addr[i-j] = find_first_buffer[30+i];  /* AN000 */
                else                                                    /* AN000 */
                        j = u(1);                                       /* AN000 */
                END                                                     /* AN000 */
            END                                                         /* AN000 */
          return;                                                       /* AN000 */
END                                                                     /* AN000 */


/*  */
/*******************************************************************************/
/*Routine name:  CHECK_FORMAT                                                  */
/*******************************************************************************/
/*                                                                             */
/*Description:   This routine will invoke INT21 44h (Block Generic IOCTL       */
/*               Subfunction) call to see if the drive has been previously     */
/*               formatted by using a undocumented call.                       */
/*                                                                             */
/*Called Procedures:                                                           */
/*                                                                             */
/*Change History: Created        2/07/88         DRM                           */
/*                                                                             */
/*Input: input_drive                                                           */
/*                                                                             */
/*Output: pointer to dx register                                               */
/*                                                                             */
/*******************************************************************************/

FLAG check_format(input_drive)                                          /* AN002 */

          char input_drive;                                             /* AN002 */

BEGIN                                                                   /* AN002 */

          char formatted;                                               /* AN002 */

          /* Set up registers for Generic IOCTL INT21 (44h) check media  */
          regs.x.ax = u(GENERIC_IOCTL);                                 /* AN002 */
          regs.h.bh = uc(ZERO);                                         /* AN002 */
          regs.h.bl = (((unsigned char)input_drive - 'A') + 1);         /* AN002 */
          regs.x.cx = u(SPECIAL_FUNCTION);                              /* AN002 */
          regs.x.dx = (unsigned)&disk_access;                           /* AN002 */
          segread(&segregs);                                            /* AN002 */
          intdosx(&regs,&regs,&segregs);                                /* AN002 */

          /* see if buffer returned good or not */
          if (disk_access.dac_access_flag == ZERO)                      /* AN002 */
             formatted = FALSE;                                         /* AN002 */
          else                                                          /* AN002 */
             formatted = TRUE;                                          /* AN002 */

          return(formatted);                                            /* AN002 */

END                                                                     /* AN002 */



