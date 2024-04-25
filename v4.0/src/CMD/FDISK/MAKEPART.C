
#include "dos.h"                                                        /* AN000 */
#include "fdisk.h"                                                      /* AN000 */
#include "extern.h"                                                     /* AN000 */
#include "subtype.h"                                                    /* AN000 */
#include "string.h"                                                     /* AN000 */

/*  */

void make_partition(size,free_pointer,bootable,type)

unsigned        size;
char            free_pointer;
unsigned char   bootable;
char            type;

BEGIN

char table_pointer;
unsigned i;
unsigned char   temp;
unsigned long   total_sectors;

    /* Find a free spot to put it in */
    table_pointer = find_free_partition();

    if (table_pointer != ((char)(NOT_FOUND)))
        BEGIN
        /* found a free partition, now lets go fill it up */

        /* Do we need to make it active? */
        if (bootable == ((unsigned char)(ACTIVE)))
            BEGIN

            /* Go clear out a previously active one */
            for (i=u(0); i <u(4); i++)                                  /* AC000 */
                BEGIN
                if (part_table[cur_disk][i].boot_ind == uc(0x80))       /* AC000 */
                    BEGIN
                    part_table[cur_disk][i].changed = TRUE;
                    part_table[cur_disk][i].boot_ind = uc(0);           /* AC000 */
                    END
                END

                /* Now mark the new one active */
                part_table[cur_disk][table_pointer].boot_ind = uc(0x80); /* AC000 */
            END
        else
            BEGIN
            /* Mark it as not active, leaving the others alone */
            part_table[cur_disk][table_pointer].boot_ind = uc(0);       /* AC000 */
            END

            /* Go get the start cylinder */
            part_table[cur_disk][table_pointer].start_cyl = free_space[free_pointer].start;

            /* Setup end cylinder */
            part_table[cur_disk][table_pointer].end_cyl = part_table[cur_disk][table_pointer].start_cyl + size - 1;

            /* Start sector is always 1 */
            part_table[cur_disk][table_pointer].start_sector = uc(1);   /* AC000 */

            /* End sector is always the last sector */
            part_table[cur_disk][table_pointer].end_sector = max_sector[cur_disk];

            /* End head is always the last head */
            part_table[cur_disk][table_pointer].end_head = uc(max_head[cur_disk] -1);      /* AC004 */

            /* Start head is always 0 unless this is track 0 - then it is 1 */
            temp = uc(0);                                               /* AC000 */
            if (part_table[cur_disk][table_pointer].start_cyl == u(0))  /* AC000 */
                BEGIN
                temp = uc(1);                                           /* AC000 */
                END
            part_table[cur_disk][table_pointer].start_head = temp;

            /* Figure out the total number of sectors */
            /* Total sectors in partition =                    */
            /* [(end_cyl - start_cyl)*(max_sector)*(max_head)] */
            /* - [start_head * max_sector]                     */
            /* Note: This is assuming a track or cylinder aligned partition */

            /* First - get the total size in Cylinders assuming head 0 start*/
            total_sectors = ((unsigned long)(part_table[cur_disk][table_pointer].end_cyl -
                              part_table[cur_disk][table_pointer].start_cyl+1));

            /* Now multiply it by the number of sectors and heads per track */
            total_sectors = total_sectors * max_sector[cur_disk] * max_head[cur_disk];

            /* This will give us the total of sectors if it is cyl aligned */
            /* Now, if it isn't aligned on head 0, we need to subtract off */
            /* the skipped tracks in the first cylinder  */

            /* Because the head is zero based, we can get the total number of */
            /* skipped sectors by multipling the head number by sectors per track */
            total_sectors = total_sectors - ((unsigned long)part_table[cur_disk][table_pointer].start_head) *
                              max_sector[cur_disk];
            part_table[cur_disk][table_pointer].num_sec = total_sectors;

            /* Get the relative sector */
            /* Figure out the total number of sectors */
            /* Total sectors before partition =                */
            /* (start_cyl)*(max_sector)*(max_head)]            */
            /* + [start_head * max_sector]                     */
            /* Note: This is assuming a track or cylinder aligned partition */

            /* Start cyl will work because it is zero based */
            total_sectors = ((unsigned long)part_table[cur_disk][table_pointer].start_cyl);

            /* Get sectors up to head 0 of the partition */
            total_sectors = total_sectors * max_sector[cur_disk] * max_head[cur_disk];

            /* Because the head is zero based, we can get the total number of */
            /* skipped sectors by multipling the head number by sectors per track */
            total_sectors = total_sectors + ((unsigned long)part_table[cur_disk][table_pointer].start_head) *
                              max_sector[cur_disk];

            /* Save it! */
            part_table[cur_disk][table_pointer].rel_sec = total_sectors;

            /* Setup the system id byte */
            if (type == ((char)(EXTENDED)))
                BEGIN
                temp = uc(EXTENDED);                                    /* AC000 */
                END
            else
                BEGIN
                if (type == ((char)(PRIMARY)))
                    BEGIN
                    /* Always set to 06h - let format worry about setting to correct value */
                    temp = uc(DOSNEW);                                  /* AC000 */                            /*  AN000  */
                    END
                else
                    BEGIN
                    internal_program_error();
                    END
                END

            /* We got the sys id, now put it in */
            part_table[cur_disk][table_pointer].sys_id = temp;

            /* Set the changed flag */
            part_table[cur_disk][table_pointer].changed = TRUE;

            /* Set the mbytes used */
            part_table[cur_disk][table_pointer].mbytes_used =
                cylinders_to_mbytes(size,cur_disk);                     /* AN004 */

            /* Set the percent used */
            part_table[cur_disk][table_pointer].percent_used =
                cylinders_to_percent(((part_table[cur_disk][table_pointer].end_cyl-part_table[cur_disk][table_pointer].start_cyl)+1),
                total_disk[cur_disk]);                                  /* AN000 */
        END
        else

            BEGIN
            /* This should not have happened */
            internal_program_error();
            return;
            END

        return;
END


/*  */
char make_volume(size,free_pointer)

unsigned    size;
char   free_pointer;

BEGIN

char table_pointer;
unsigned i;
unsigned ext_part_num;                                                  /* AN000 */
unsigned char   temp;
unsigned long   total_sectors;

        /* Find a free spot to put it in */
        table_pointer = find_free_ext();

        if (table_pointer != ((char)(NOT_FOUND)))
           BEGIN
            /* found a free partition, now lets go fill it up */


            /* This can never be marked active */
            ext_table[cur_disk][table_pointer].boot_ind = uc(0);        /* AC000 */


            /* Go get the start cylinder */
            ext_table[cur_disk][table_pointer].start_cyl = free_space[free_pointer].start;

            /* Setup end cylinder */
            ext_table[cur_disk][table_pointer].end_cyl = ext_table[cur_disk][table_pointer].start_cyl + size - 1;

            /* Start sector is always 1 */
            ext_table[cur_disk][table_pointer].start_sector = uc(1);    /* AC000 */

            /* End sector is always the last sector */
            ext_table[cur_disk][table_pointer].end_sector = max_sector[cur_disk];

            /* End head is always the last head */
            ext_table[cur_disk][table_pointer].end_head = uc(max_head[cur_disk]-1);  /* AC004 */

              /* Start head is always 1 - NOTE: This is a shortcut for PC-DOS */
              /* If this is being modified for IFS drivers this may not be the */
              /* the case - use caution */
              ext_table[cur_disk][table_pointer].start_head = uc(1);    /* AC000 */

              /* Figure out the total number of sectors */
              /* Total sectors in partition =                    */
              /* [(end_cyl - start_cyl)*(max_sector)*(max_head)] */
              /* - [start_head * max_sector]                     */
              /* Note: This is assuming a track or cylinder aligned partition */

              /* First - get the total size in Cylinders assuming head 0 start*/
              total_sectors = ((unsigned long)(ext_table[cur_disk][table_pointer].end_cyl -
                 ext_table[cur_disk][table_pointer].start_cyl+1));

              /* Now multiply it by the number of sectors and heads per track */
              total_sectors = total_sectors * max_sector[cur_disk] * max_head[cur_disk];

              /* This will give us the total of sectors if it is cyl aligned */
              /* Now, if it isn't aligned on head 0, we need to subtract off */
              /* the skipped tracks in the first cylinder  */

              /* Because the head is zero based, we can get the total number of */
              /* skipped sectors by multipling the head number by sectors per track */
              total_sectors = total_sectors - ((unsigned long)(ext_table[cur_disk][table_pointer].start_head *
                                 max_sector[cur_disk]));

              ext_table[cur_disk][table_pointer].num_sec = total_sectors;

              /* Get the relative sector */
              /* Figure out the total number of sectors */
              /* Total sectors before partition = max_sector     */
              /* NOTE: Again, this is a PC-DOS 3.30 shortcut - by definition */
              /* a logical drive always starts on head 1, so there is always */
              /* one tracks worth of sectors before it. Hence, max_sector */

              /* Save it! */
              ext_table[cur_disk][table_pointer].rel_sec = ((unsigned long)(max_sector[cur_disk]));

              /* Setup the system id byte */
              /* Set to 06h - format will fix later on */
              temp = uc(DOSNEW);                                         /* AC000 */                                    /*  AN000  */

               /* We got the sys id, now put it in */
               ext_table[cur_disk][table_pointer].sys_id = temp;

               /* Set the changed flag */
               ext_table[cur_disk][table_pointer].changed = TRUE;

               /* Set the mbytes used */
               ext_table[cur_disk][table_pointer].mbytes_used =
                   cylinders_to_mbytes(size,cur_disk);                   /* AN004 */

               /* find the number of the extended partiton to figure out percent */
               ext_part_num = find_partition_location(uc(EXTENDED));              /* AN000 */

               /* Set the percent used */
               ext_table[cur_disk][table_pointer].percent_used =
                   cylinders_to_percent(((ext_table[cur_disk][table_pointer].end_cyl-ext_table[cur_disk][table_pointer].start_cyl)+1),
                   ((part_table[cur_disk][ext_part_num].end_cyl-part_table[cur_disk][ext_part_num].start_cyl)+1));      /* AN000 */

                /* set the system to unknown and volume label to blanks */
                strcpy(ext_table[cur_disk][table_pointer].system,NOFORMAT);     /* AN000 */
                strcpy(ext_table[cur_disk][table_pointer].vol_label,NOVOLUME);  /* AN000 */

           END
        else

           BEGIN
            /* This should not have happened */
            internal_program_error();
           END

        return(table_pointer);
END

