
#include "dos.h"                                                        /* AN000 */
#include "fdisk.h"                                                      /* AN000 */
#include "subtype.h"                                                    /* AN000 */
#include "extern.h"                                                     /* AN000 */


/*  */
void write_info_to_disk()

BEGIN

char            i;
unsigned char   j;
unsigned        extended_location;
char            extended_index;
char            temp;
char            first_found;
char            changed_flag;
char            temp_disk;


        temp = c(NUL);                                                  /* AN009 */
        temp_disk = cur_disk;
        /* See if need to update the master boot record */
        for (j = uc(0); j < number_of_drives; j++)                      /* AC000 */
           BEGIN

            /* Save disk number */
            cur_disk = ((char)(j));

            /* See if there were any errors on that drive */
            if (good_disk[j])
               BEGIN
                for (i=c(0); i < c(4); i++)                             /* AC000 */
                   BEGIN
                    if (part_table[j][i].changed)
                       BEGIN
                        write_master_boot_to_disk(j);
                        break;
                       END
                   END
                /* See if the extended partition exists - if not, don't fool with the logical*/
                /* drives - there is nothing to point to thier structures. Otherwise you get into */
                /* a chicken and the egg situation, where you are trying to write out 'deletes' of */
                /* the logical drive based on the start of the extended partition, but there isn't one */
                /* because it has already been deleted already. Bad things happen - PTM P941  */

                if (find_partition_type(uc(EXTENDED)));                 /* AC000 */
                   BEGIN
                    /* See if any extended partitions need to be updated */
                    changed_flag = FALSE;

                    for (i=c(0);i <c(23); i++)                          /* AC000 */
                       BEGIN
                        if (ext_table[j][i].changed)
                           BEGIN
                            changed_flag = TRUE;
                            break;
                           END
                       END
                    if (changed_flag)
                       BEGIN
                        /* First,get them in order - drive letters are assigned in the order */
                        /* that they exist on the disk */
                        sort_ext_table(c(23));                          /* AC000 */

                        for (i=c(0);i < c(23); i++)                     /* AC000 */

                           BEGIN
                            /* If there is a valid drive existing, write it out */
                            if (ext_table[j][sort[i]].sys_id != uc(0))  /* AC000 */
                               BEGIN
                                write_ext_boot_to_disk(i,j);
                               END
                           END

                        /* Find start of extended partition */
                        extended_index = find_partition_location(uc(EXTENDED));     /* AC000 */
                        extended_location = part_table[j][extended_index].start_cyl;

                        /* See if the first entry in EXTENDED DOS partition will be written out */
                        /* Need to find the first drive in the sorted list */
                        for (i=c(0);i < c(23); i++)                     /* AC000 */
                           BEGIN
                            if (ext_table[j][sort[i]].sys_id != uc(0))  /* AC000 */
                               BEGIN
                                temp = sort[i];
                                break;
                               END
                           END
                        /* See if drive written out */
                        if ((temp != c(NUL)) &&
                            (extended_location != ext_table[j][temp].start_cyl))   /* AC009 */
                           BEGIN
                            /* If not, make a special case and go do it */
                            /* Use the 24 entry in the array to set up a dummy entry */
                            /* This one isn't used for anything else */
                            /* Indicate this is special by passing along a deleted entry - the subroutine will catch it and handle correctly */
                            ext_table[j][23].sys_id = uc(0);            /* AC000 */
                            ext_table[j][23].start_cyl = part_table[j][extended_index].start_cyl;
                            ext_table[j][23].start_head = uc(0);        /* AC000 */
                            ext_table[j][23].start_sector = uc(1);      /* AC000 */

                            /* Write out our modified first location - only pointer info will be sent to the disk*/
                            write_ext_boot_to_disk(c(23),j);            /* AC000 */
                           END
                       END
                   END
               END
           END
        cur_disk = temp_disk;
        return;
END

/*  */
char write_master_boot_to_disk(disk)

unsigned char   disk;

BEGIN

unsigned        char i;
unsigned        j;
unsigned        x;
unsigned        temp;
unsigned long   long_temp;
unsigned        index;
char            location;
unsigned        byte_temp;

        /* Clean out the boot_record */
        for (j=u(0);j < u(BYTES_PER_SECTOR); j++)                       /* AC000 */
           BEGIN
            boot_record[j] = uc(0);                                     /* AC000 */
           END

        /* Copy the master boot record to boot_record */
        for (j=u(0); j < u(BYTES_PER_SECTOR); j++)                      /* AC000 */
           BEGIN
            boot_record[j] = master_boot_record[disk][j];
           END

        /* Copy the partition tables over - only bother with the changed ones */
        for (i=uc(0); i < uc(4); i++)                                   /* AC000 */
           BEGIN
            index = ((unsigned)i)*16;
            if (part_table[disk][i].changed)
               BEGIN
                /* Get boot ind */
                boot_record[0x1BE+(index)] = part_table[disk][i].boot_ind;

                /* Start head */
                boot_record[0x1BF+(index)] = part_table[disk][i].start_head;

                /* Start sector - scramble it to INT 13 format*/
                boot_record[0x1C0+(index)] = (part_table[disk][i].start_sector & 0x3F)  |
                                               ((unsigned char)((part_table[disk][i].start_cyl/256) << 6));

                /* Start cyl - scramble it to INT 13 format*/
                boot_record[0x1C1+(index)] = ((unsigned char)(part_table[disk][i].start_cyl%256));

                /* System id */
                boot_record[0x1C2+(index)]= part_table[disk][i].sys_id;

                /* End head */
                boot_record[0x1C3+(index)] = part_table[disk][i].end_head;

                /* End sector - scramble it to INT 13 format*/
                boot_record[0x1C4+(index)] = (part_table[disk][i].end_sector & 0x3F)  |
                                                ((unsigned char)((part_table[disk][i].end_cyl/256) << 6));

                /* End cyl - scramble it to INT 13 format*/
                boot_record[0x1C5+(index)] = ((unsigned char)(part_table[disk][i].end_cyl%256));

                /* Relative sectors */
                long_temp = part_table[disk][i].rel_sec;
                boot_record[0x1C9+(index)] = uc((long_temp >> 24));                     /* AC000 */
                boot_record[0x1C8+(index)] = uc(((long_temp & 0x00FF0000l) >> 16));     /* AC000 */
                boot_record[0x1C7+(index)] = uc(((long_temp & 0x0000FF00l) >> 8));      /* AC000 */
                boot_record[0x1C6+(index)] = uc((long_temp & 0x000000FFl));             /* AC000 */


                /* Number of sectors */
                long_temp = part_table[disk][i].num_sec;
                boot_record[0x1CD+(index)] = uc(long_temp >> 24);                       /* AC000 */
                boot_record[0x1CC+(index)] = uc((long_temp & 0x00FF0000l) >> 16);       /* AC000 */
                boot_record[0x1CB+(index)] = uc((long_temp & 0x0000FF00l) >> 8);        /* AC000 */
                boot_record[0x1CA+(index)] = uc(long_temp & 0x000000FFl);               /* AC000 */
              END
           END
        boot_record[510] = uc(0x55);                                    /* AC000 */
        boot_record[511] = uc(0xAA);                                    /* AC000 */

        return(write_boot_record(u(0),disk));                           /* AC000 */
END

/*  */
char write_ext_boot_to_disk(entry,disk)

char entry;
unsigned char disk;
BEGIN

char            i;
unsigned        j;
unsigned long   long_temp;
unsigned        index;
char            location;
char            next_drive;
char            pointer;
char            write;

        /* Clean out the boot_record */
        for (j=u(0);j < u(BYTES_PER_SECTOR); j++)                       /* AC000 */
           BEGIN
            boot_record[j] = uc(0);                                     /* AC000 */
           END

        /* First - setup the logical devices */
        /* See if it has been deleted - if so, leave entries as zero */
        /* Otherwise - go unscramble everything out of the arrays */

        if (ext_table[disk][sort[entry]].sys_id != uc(0))               /* AC000 */
           BEGIN
            /* Get boot ind */
            boot_record[0x1BE] = ext_table[disk][sort[entry]].boot_ind;

            /* Start head */
            boot_record[0x1BF] = ext_table[disk][sort[entry]].start_head;

            /* Start sector - scramble it to INT 13 format*/
           boot_record[0x1C0] = (ext_table[disk][sort[entry]].start_sector & 0x3F) |
                    ((ext_table[disk][sort[entry]].start_cyl/256) << 6);

            /* Start cyl - scramble it to INT 13 format*/
            boot_record[0x1C1] = ((unsigned char)(ext_table[disk][sort[entry]].start_cyl%256));

            /* System id */
            boot_record[0x1C2]= ext_table[disk][sort[entry]].sys_id;

            /* End head */
            boot_record[0x1C3] = ext_table[disk][sort[entry]].end_head;

            /* End sector - scramble it to INT 13 format*/
            boot_record[0x1C4] = (ext_table[disk][sort[entry]].end_sector & 0x3F) |
                  ((ext_table[disk][sort[entry]].end_cyl/256) << 6);

            /* End cyl - scramble it to INT 13 format*/
            boot_record[0x1C5] = ((unsigned char)(ext_table[disk][sort[entry]].end_cyl%256));

            /* Relative sectors */
            long_temp = ext_table[disk][sort[entry]].rel_sec;
            boot_record[0x1C9] = uc((long_temp >> 24));                 /* AC000 */
            boot_record[0x1C8] = uc(((long_temp & 0x00FF0000l) >> 16)); /* AC000 */
            boot_record[0x1C7] = uc(((long_temp & 0x0000FF00l) >> 8));  /* AC000 */
            boot_record[0x1C6] = uc((long_temp & 0x000000FFl));         /* AC000 */

            /* Number of sectors */
            long_temp = ext_table[disk][sort[entry]].num_sec;
            boot_record[0x1CD] = uc((long_temp >> 24));                 /* AC000 */
            boot_record[0x1CC] = uc(((long_temp & 0x00FF0000l) >> 16)); /* AC000 */
            boot_record[0x1CB] = uc(((long_temp & 0x0000FF00l) >> 8));  /* AC000 */
            boot_record[0x1CA] = uc((long_temp & 0x000000FFl));         /* AC000 */
           END

        /* set up pointer to next logical drive unless this is # 23 */
        if (entry != c(22))                                             /* AC000 */
           BEGIN
           /* Find the drive to be pointed to */
           pointer = entry+1;

           /* Handle the special case of a deleted or empty first entry in partition*/
           if (entry == c(23))                                          /* AC000 */
              BEGIN
               pointer = c(0);                                          /* AC000 */
              END
           for (i = pointer; i <c(23); i++)                             /* AC000 */
              BEGIN
               next_drive = ((char)(INVALID));

               /* Go look for the next valid drive */
               if (ext_table[disk][sort[i]].sys_id != uc(0))            /* AC000 */
                  BEGIN
                   next_drive = sort[i];
                   break;
                  END
              END
            if (next_drive != ((char)(INVALID)))
               BEGIN
                /* Get boot ind */
                boot_record[0x1CE] = uc(0);                             /* AC000 */

                /* Start head */
                boot_record[0x1CF] = uc(0);                             /* AC000 */

                /* Start sector - scramble it to INT 13 format*/
                boot_record[0x1D0] = uc(0x01) | ((ext_table[disk][next_drive].start_cyl/256) << 6);  /* AC000 */


                /* System id */
                boot_record[0x1D2]= uc(EXTENDED);                       /* AC000 */

                /* End head */
                boot_record[0x1D3] = uc(max_head[disk] -1);             /* AC004 */

                /* End sector - scramble it to INT 13 format*/
                boot_record[0x1D4] =(max_sector[disk] & 0x3F) | ((ext_table[disk][next_drive].end_cyl/256) << 6);


                /* Start cyl - scramble it to INT 13 format*/
                boot_record[0x1D1] = ((unsigned char)(ext_table[disk][next_drive].start_cyl%256));

                /* End cyl - scramble it to INT 13 format*/
                boot_record[0x1D5] = ((unsigned char)(ext_table[disk][next_drive].end_cyl%256));

                /* Relative sectors - this is from the front of the extended volume */
                /* Find the extended partition */
                location = find_partition_location(uc(EXTENDED));
                long_temp = ((unsigned long)(ext_table[disk][next_drive].start_cyl - part_table[disk][location].start_cyl))
                              * max_head[disk] *  max_sector[disk];
                boot_record[0x1D9] = uc((long_temp >> 24));                   /* AC000 */
                boot_record[0x1D8] = uc(((long_temp & 0x00FF0000l) >> 16));   /* AC000 */
                boot_record[0x1D7] = uc(((long_temp & 0x0000FF00l) >> 8));    /* AC000 */
                boot_record[0x1D6] = uc((long_temp & 0x000000FFl));           /* AC000 */

                /* Number of sectors in the next volume*/
                long_temp = ((unsigned long)(ext_table[disk][next_drive].end_cyl - ext_table[disk][next_drive].start_cyl+1))
                            * max_head[disk] * max_sector[disk];
                boot_record[0x1DD] = uc((long_temp >> 24));                   /* AC000 */
                boot_record[0x1DC] = uc(((long_temp & 0x00FF0000l) >> 16));   /* AC000 */
                boot_record[0x1DB] = uc(((long_temp & 0x0000FF00l) >> 8));    /* AC000 */
                boot_record[0x1DA] = uc((long_temp & 0x000000FFl));           /* AC000 */
               END
           END
        boot_record[510] = uc(0x55);                                    /* AC000 */
        boot_record[511] = uc(0xAA);                                    /* AC000 */

        /* Write the boot record out */
        if (entry != c(23))                                             /* AC000 */
           BEGIN
            write = write_boot_record(ext_table[disk][sort[entry]].start_cyl,disk);
           END
         else
            BEGIN
             /* Write the special case of the first entry only having a pointer */
             write = write_boot_record(ext_table[disk][23].start_cyl,disk);
            END
         return(write);
END




