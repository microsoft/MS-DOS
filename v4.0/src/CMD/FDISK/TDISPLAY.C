
#include "dos.h"                                                        /* AN000 */
#include "fdisk.h"                                                      /* AN000 */
#include "extern.h"                                                     /* AN000 */
#include "subtype.h"                                                    /* AN000 */
#include "fdiskmsg.h"                                                   /* AN000 */
#include "stdio.h"
#include "string.h"
#include "memory.h"

/*  */
char table_display()

BEGIN


unsigned    i;
unsigned    x;
unsigned    io;
char       *ThisPartitionType;
char        ThisPartitionLetter[3];
FLAG        partition_found;
char        partition_num;

     /* initialize all the inserts to blanks */
     memset(insert,c(' '),4*21);
     io = u(0);

     /* Sort the partitions */
     sort_part_table(c(4));                                             /* AC000 */

     /* loop thru the partitions, only print stuff if it is there */
     partition_found = FALSE;
     partition_num = c(0);                                              /* AC000 */

     for (i=u(0); i < u(4); i++)                                        /* AC000 */
         BEGIN

         if (part_table[cur_disk][sort[i]].sys_id != uc(0))             /* AC000 */
             BEGIN

             partition_found = TRUE;

             strcpy(ThisPartitionLetter,"  ");
             switch(part_table[cur_disk][sort[i]].sys_id)
                 BEGIN
                 case DOSNEW:                                           /* AN000 */
                 case DOS16:
                 case DOS12:
                     ThisPartitionType = DOS_part;
                     part_table[cur_disk][sort[i]].drive_letter = table_drive_letter();         /* AN000 */
                     sprintf(ThisPartitionLetter,"%c%c",
                             part_table[cur_disk][sort[i]].drive_letter,
                             ( part_table[cur_disk][sort[i]].drive_letter == c(' ') ) ? ' ' : ':');
                     break;
                 case EXTENDED:
                     ThisPartitionType = EXTENDED_part;
                     break;
                 case BAD_BLOCK:
                     ThisPartitionType = BAD_BLOCK_part;
                     break;
                 case XENIX1:
                     ThisPartitionType = XENIX_part;
                     break;
                 case XENIX2:
                     ThisPartitionType = XENIX_part;
                     break;
                 case PCIX:
                     ThisPartitionType = PCIX_part;
                     break;
                 default:
                     ThisPartitionType = NON_DOS_part;
                     break;
                 END

             io += sprintf(&insert[io],"%-2.2s%c%c%-7.7s%4.0d%3.0d%%",
                        ThisPartitionLetter,
                        partition_num+'1',
                        (part_table[cur_disk][sort[i]].boot_ind == uc(0x80)) ? 'A' : ' ',
                        ThisPartitionType,
                        part_table[cur_disk][sort[i]].mbytes_used,
                        part_table[cur_disk][sort[i]].percent_used);

             partition_num++;

             END

         END

    /* Do a clearscreen to erase previous data */
    clear_screen(u(8),u(0),u(12),u(79));                               /* AC000 */

    if (partition_found) display(menu_14);
                    else display(status_8);

    /* Return true if partitions exist, false otherwise */
    if (partition_found) return(TRUE);

    return(FALSE);

END

/*  */
char table_drive_letter()

BEGIN
char drive_letter;

      /* Put in drive letter in display */
      if (cur_disk == c(0))                                             /* AC000 */
         BEGIN
          /* There is a primary partition on 80h, so drive C: */
          drive_letter = c('C');                                        /* AC000 */
         END
      else
         BEGIN
          /* We are on drive 81h, so assume D: */
          drive_letter = c('D');                                        /* AC000 */

          /* See if primary exists on 80h drive */
          /* First, set cur_drive to 0 */
          cur_disk = c(0);                                              /* AC000 */

          /* Check for primary on drive 80h */
          if (!(find_partition_type(uc(DOS12)) || find_partition_type(uc(DOS16)) || find_partition_type(uc(DOSNEW)))) /* AC000 */
             BEGIN
              drive_letter = c('C');                                    /* AC000 */
             END
          /* restore cur_disk to normal */
          cur_disk = c(1);                                              /* AC000 */
         END
      return(drive_letter);
END
