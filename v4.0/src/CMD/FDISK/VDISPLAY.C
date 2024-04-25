
#include "dos.h"                                                        /* AN000 */
#include "fdisk.h"                                                      /* AN000 */
#include "extern.h"                                                     /* AN000 */
#include "subtype.h"                                                    /* AN000 */
#include "fdiskmsg.h"                                                   /* AN000 */
#include "string.h"
#include "stdio.h"
#include "memory.h"

/*  */
char volume_display()

BEGIN

unsigned    i;
unsigned    x;
char        drive_found;
char        drive_letter;
char        drive_num;
char        temp;
char        first_display;
char        second_display;
char        third_display;
char        fourth_display;
unsigned    insert_offset;

        first_display = FALSE;
        second_display = FALSE;
        third_display = FALSE;
        fourth_display = FALSE;

        /* See what the starting drive letter is */
        drive_letter = c(SEA);                                          /* AC000 */

        /* See if primary on drive 1 */
        temp = cur_disk;
        cur_disk = c(0);                                                /* AC000 */
        if ( (find_partition_type(uc(DOS12))) ||
             (find_partition_type(uc(DOS16))) ||
             (find_partition_type(uc(DOSNEW)))) /* AC000 */
           BEGIN
            /* There is a Primary partition on drive 1, so increment for first logical drive */
                drive_letter++;
           END
         cur_disk = temp;

        /* See if there is a second drive */
        if (number_of_drives == uc(2))                                  /* AC000 */
           BEGIN

            /* Go see if DOS partition on drive 2 */
            temp = cur_disk;
            cur_disk = c(1);                                            /* AC000 */
            if ( (find_partition_type(uc(DOS12))) ||
                 (find_partition_type(uc(DOS16))) ||
                 (find_partition_type(uc(DOSNEW)))) /*AC000*/
                BEGIN

                /* There is a Primary partition on drive 2, so increment for first logical drive */
                drive_letter++;
               END
            /* Are we on drive 2? If so, we got to find all the drives on drive 1 */
            if (temp == c(1))                                           /* AC000 */
               BEGIN
                /* Next, we need to see what is on drive 1 */
                for (i=u(0); i < u(23); i++)                            /* AC000 */
                   BEGIN
                    /* See if there is a logical drive we understand in PC-DOS land */
                    if ( (ext_table[0][i].sys_id == uc(DOS12)) ||
                         (ext_table[0][i].sys_id == uc(DOS16)) ||
                         (ext_table[0][i].sys_id == uc(DOSNEW)) )                    /* AC000  */
                       BEGIN
                        /* Found one, so kick up the first available drive letter */
                        drive_letter++;
                       END
                   END
               END

            /* Reset the cur_drive to where it was */
            cur_disk = temp;
           END




        /* loop thru the partitions, only print stuff if it is there */

        /* Get the drives in order by location on disk */
        sort_ext_table(c(23));                                          /* AC000 */

        /* initialize all the inserts to blanks */
        memset(insert,c(' '),(24*29));

        drive_num = c(0);                                               /* AC000 */
        drive_found = FALSE;
        first_display = TRUE;
        insert_offset = 0;

        for (i=u(0); i < u(23); i++)                                    /* AC000 */
           BEGIN

            /* See if entry exists */
            if ( (ext_table[cur_disk][sort[i]].sys_id == uc(DOS12)) ||
                 (ext_table[cur_disk][sort[i]].sys_id == uc(DOS16)) ||
                 (ext_table[cur_disk][sort[i]].sys_id == uc(DOSNEW)) )  /* AC000  */
               BEGIN

                /* We found one, now get the info */
                drive_found = TRUE;

                /* Get the drive letter - make sure it is Z: or less*/
                /* Put it in the message, and set it up for next time */
                if (drive_letter > c('Z'))
                        ext_table[cur_disk][sort[i]].drive_letter = c(' ');
                   else ext_table[cur_disk][sort[i]].drive_letter = drive_letter;

                insert_offset += sprintf(&insert[insert_offset],"%c%c%-11.11s%4.0d%-8.8s%3.0d%%",
                        ext_table[cur_disk][sort[i]].drive_letter,
                        ( ext_table[cur_disk][sort[i]].drive_letter == c(' ') ) ? ' ' : ':',
                        ext_table[cur_disk][sort[i]].vol_label,
                        ext_table[cur_disk][sort[i]].mbytes_used,
                        ext_table[cur_disk][sort[i]].system,
                        ext_table[cur_disk][sort[i]].percent_used );


                drive_letter++;
                drive_num++;

               END
           END

        /* Display the column of drives */
        if (drive_found)
           BEGIN

            clear_screen(u(2),u(0),u(15),u(79));                    /* AC000 */

            if ( drive_num > 0 )
                BEGIN
                pinsert = &insert[0];
                display(menu_19);
                END

            if ( drive_num > 6 )
                BEGIN
                pinsert = &insert[6*29];
                display(menu_43);
                END

            if ( drive_num > 12 )
                BEGIN
                pinsert = &insert[12*29];
                display(menu_20);
                END

            if ( drive_num > 18 )
                BEGIN
                pinsert = &insert[18*29];
                display(menu_44);
                END
            pinsert = &insert[0];
            END
        else
           BEGIN
            /* Didn't find any */
            if (first_display)
               BEGIN
                /* Wipe out display and put up message */
                clear_screen(u(2),u(0),u(15),u(79));                    /* AC000 */
                display(status_9);
               END
           END
        /* Return the highest drive letter found */
        drive_letter--;
        return(drive_letter);

END

