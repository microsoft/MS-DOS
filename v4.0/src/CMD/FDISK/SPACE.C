
#include "dos.h"
#include "fdisk.h"
#include "extern.h"
#include "subtype.h"

/*  */
char find_part_free_space(type)

char   type;

BEGIN


char        i;
char        partition_count;
char        last_found_partition;
unsigned    temp;
char        freespace_count;
char        any_partition;
unsigned    temp_size;

        /* Sort the partition table */
        sort_part_table(c(4));                                          /* AC000 */


        /* Intialize free space to zero */
        for (i = c(0); i < c(5); i++)                                   /* AC000 */
           BEGIN
            free_space[i].space = u(0);                                 /* AC000 */
            free_space[i].start = u(0);                                 /* AC000 */
            free_space[i].end = u(0);                                   /* AC000 */
            free_space[i].mbytes_unused = f(0);                         /* AC000 */  /* AN000 */
            free_space[i].percent_unused = u(0);                        /* AC000 */     /* AN000 */
           END

        /* Find space between start of disk and first partition */
        partition_count = c(0);                                         /* AC000 */

        any_partition = FALSE;
        for (i = c(0); i < c(4); i++)                                   /* AC000 */
           BEGIN
            if (part_table[cur_disk][sort[i]].sys_id != uc(0))          /* AC000 */
               BEGIN
                /* Found a partition, get the space */

                free_space[0].start = u(0);                             /* AC000 */

                /* This is a special case - the extended partition can not start */
                /* on cylinder 0 due too its archetecture. Protect against that here */
                if (type == c(EXTENDED))                                /* AC000 */
                   BEGIN
                    free_space[0].start = u(1);                         /* AC000 */
                   END

                /* free space ends before start of next valid partition */
                if (part_table[cur_disk][sort[i]].start_cyl > u(0))     /* AC000 */
                   BEGIN
                    free_space[0].end = part_table[cur_disk][sort[i]].start_cyl-1;
                   END

                free_space[0].space = part_table[cur_disk][sort[i]].start_cyl;
                free_space[0].mbytes_unused =
                    cylinders_to_mbytes(free_space[0].space,cur_disk);  /* AN004 */
                free_space[0].percent_unused = (unsigned)cylinders_to_percent(free_space[0].space,total_disk[cur_disk]); /* AN000 */

                partition_count = i;
                last_found_partition = sort[i];
                any_partition = TRUE;
                break;
               END
           END
        /* See if any partitions were there */
        if (any_partition)
           BEGIN
            /* Look for space between the rest of the partitions */
            freespace_count = c(1);                                     /* AC000 */
            for (i = partition_count+1; i < c(4); i++)                  /* AC000 */
               BEGIN
                if (part_table[cur_disk][sort[i]].sys_id != uc(0))      /* AC000 */
                   BEGIN

                    /* Check to see if more than one partition on a cylinder (i.e. XENIX bad block)  */
                    /* If so, leave the space at zero */

                    if (part_table[cur_disk][sort[i]].start_cyl != part_table[cur_disk][last_found_partition].end_cyl)

                       BEGIN
                        /* No, things are normal */
                        /* Get space between the end of the last one and the start of the next one */
                        free_space[freespace_count].space = part_table[cur_disk][sort[i]].start_cyl
                           - (part_table[cur_disk][last_found_partition].end_cyl+1);

                        temp_size = (part_table[cur_disk][sort[i]].start_cyl -
                             part_table[cur_disk][last_found_partition].end_cyl);

                        if (temp_size != u(0) )                         /* AC000 */
                           BEGIN
                            free_space[freespace_count].space = temp_size - u(1);  /* AC000 */
                           END
                       END

                    free_space[freespace_count].start = part_table[cur_disk][last_found_partition].end_cyl+1;
                    free_space[freespace_count].end = part_table[cur_disk][sort[i]].start_cyl -1;
                    free_space[freespace_count].mbytes_unused =
                         cylinders_to_mbytes(free_space[freespace_count].space,cur_disk); /* AN004 */
                    free_space[freespace_count].percent_unused = (unsigned)
                         cylinders_to_percent(free_space[freespace_count].space,total_disk[cur_disk]);  /* AN000 */



                    /* update the last found partition */
                    last_found_partition = sort[i];
                    freespace_count++;
                   END
               END
            /* Find the space between the last partition and the end of the disk */
            free_space[freespace_count].space = (total_disk[cur_disk]
                                     -  part_table[cur_disk][last_found_partition].end_cyl)-1;
            free_space[freespace_count].start = part_table[cur_disk][last_found_partition].end_cyl+1;
            free_space[freespace_count].end = total_disk[cur_disk]-1;
            free_space[freespace_count].mbytes_unused =
                 cylinders_to_mbytes(free_space[freespace_count].space,cur_disk);    /* AN004 */
            free_space[freespace_count].percent_unused =
                 cylinders_to_percent(free_space[freespace_count].space,total_disk[cur_disk]);                       /* AN000 */
            END
         else
           BEGIN
            /* No partitions found, show entire space as free */
            free_space[0].start = u(0);                                 /* AC000 */

            /* This is a special case - the extended partition can not start */
            /* on cylinder 0 due too its architecture. Protect against that here */
            if (type == c(EXTENDED))                                    /* AC000 */
               BEGIN
                free_space[0].start = u(1);                             /* AC000 */
               END
            free_space[0].end = total_disk[cur_disk]-1;
            free_space[0].space = (free_space[0].end - free_space[0].start)+1;
            free_space[0].mbytes_unused =
                 cylinders_to_mbytes(free_space[0].space,cur_disk);    /* AN004 */
            free_space[0].percent_unused =
                 cylinders_to_percent(free_space[0].space,total_disk[cur_disk]);                       /* AN000 */
           END



         /* Find largest free space, and verify the golden tracks while we are at it */
         do
            BEGIN
             temp = u(0);                                               /* AC000 */

             /* Zip thru the table */
             for (i = c(0); i < c(5); i++)                              /* AC000 */
                BEGIN
                 /* Is this one bigger ? */
                 if (free_space[i].space > temp)
                    BEGIN
                     temp = free_space[i].space;
                     last_found_partition = i;

                    END
                END

             /* If there is any free space, go verify it */
             temp = u(0);
             if (free_space[last_found_partition].space != u(0))        /* AC000 */
               BEGIN

                /* Go verify the tracks */
                temp = verify_tracks(last_found_partition,c(PRIMARY));  /* AC000 */
               END
             /* Move up to next golden track */
             free_space[last_found_partition].start = free_space[last_found_partition].start+temp;
             free_space[last_found_partition].space = free_space[last_found_partition].space-temp;
             free_space[last_found_partition].mbytes_unused =
                  cylinders_to_mbytes(free_space[last_found_partition].space,cur_disk);    /* AN004 */
             free_space[last_found_partition].percent_unused = (unsigned)
                  cylinders_to_percent(free_space[last_found_partition].space,total_disk[cur_disk]);                      /* AN000 */
             END

            /* Repeat the loop if the start was moved due to bad tracks */
            /* Unless we're past the end of the free space */
            while ((temp != u(0)) && (free_space[last_found_partition].space != u(0)));    /* AC000 */

        /* Return with the pointer to the largest free space */
        return(last_found_partition);
END



/*  */
void sort_part_table(size)

char size;

BEGIN

char  changed;
char  temp;
char   i;

        /* Init the sorting parameters */

        for (i=c(0); i < size; i++)                                     /* AC000 */
           BEGIN
            sort[i] = i;
           END

        /* Do a bubble sort */
        changed = TRUE;

        /* Sort until we don't do a swap */
        while (changed)

           BEGIN
            changed = FALSE;
            for (i=c(1); i < size; i++)                                 /* AC000 */
               BEGIN

                /* Does the partition entry start before the previous one, or */
                /* is it empty (0 ENTRY). If empty, it automatically gets shoved */
                /* to the front, if the previous entry isn't also empty */

                if ((part_table[cur_disk][sort[i]].end_cyl < part_table[cur_disk][sort[i-1]].end_cyl)
                   || ((part_table[cur_disk][sort[i]].num_sec == ul(0))
                   &&  (part_table[cur_disk][sort[i-1]].num_sec != ul(0))))  /* AC000 */

                   BEGIN
                    /* Swap the order indicators */
                    temp = sort[i-1];
                    sort[i-1] = sort[i];
                    sort[i] = temp;

                 /* printf("\nI-1 =%d\n",part_table[cur_disk][sort[i-1]].start_cyl);*/
                 /* printf("I =%d\n",part_table[cur_disk][sort[i]].start_cyl);*/
                 /* printf("Sort[i-1] = %d\n",sort[i-1]);*/
                 /* printf("Sort[i] = %d\n",sort[i]); */
                 /* wait_for_ESC(); */


                    /* indicate we did a swap */
                    changed = TRUE;
                   END
               END
           END
        return;
END




/*  */
char find_ext_free_space()


BEGIN


char   i;
char   partition_count;
char   last_found_partition;
unsigned    temp;
char   freespace_count;
char   any_partition;
char   ext_location;

        /* Sort the partition table */
        sort_ext_table(c(23));                                          /* AC000 */


        /* Initialize free space to zero */
        for (i = c(0); i < c(24); i++)                                  /* AC000 */
           BEGIN
            free_space[i].space = u(0);                                 /* AC000 */
            free_space[i].start = u(0);
            free_space[i].end = u(0);                                   /* AC000 */
            free_space[i].mbytes_unused = f(0);                         /* AN000 */
            free_space[i].percent_unused = u(0);                        /* AN000 */
           END

        /* Find space between start of Extended partition and first volume */
        ext_location = find_partition_location(uc(EXTENDED));           /* AC000 */

        partition_count = c(0);                                         /* AC000 */

        any_partition = FALSE;
        for (i = c(0); i < c(23); i++)                                  /* AC000 */
           BEGIN
            if (ext_table[cur_disk][sort[i]].sys_id != uc(0))           /* AC000 */
               BEGIN
                /* Found a partition, get the space */
                free_space[0].space = ext_table[cur_disk][sort[i]].start_cyl - part_table[cur_disk][ext_location].start_cyl;
                free_space[0].start = part_table[cur_disk][ext_location].start_cyl;
                free_space[0].end = ext_table[cur_disk][sort[i]].start_cyl-1;
                free_space[0].mbytes_unused =
                     cylinders_to_mbytes(free_space[0].space,cur_disk); /* AN004 */
                free_space[0].percent_unused = (unsigned)cylinders_to_percent(free_space[0].space,total_disk[cur_disk]); /* AN000 */

                partition_count = i;
                last_found_partition = sort[i];
                any_partition = TRUE;
                break;
               END
           END
        /* See if any partitions were there */
        if (any_partition)
           BEGIN
            /* Look for space between the rest of the partitions */
            freespace_count = c(1);                                     /* AC000 */
            for (i = partition_count+1; i < c(23); i++)                 /* AC000 */
               BEGIN
                if (ext_table[cur_disk][sort[i]].sys_id != uc(0))       /* AC000 */
                   BEGIN

                    /* Get space between the end of the last one and the start of the next one */
                    temp = ext_table[cur_disk][sort[i]].start_cyl - (ext_table[cur_disk][last_found_partition].end_cyl+1);
                    free_space[freespace_count].space = temp;
                    free_space[freespace_count].start = ext_table[cur_disk][last_found_partition].end_cyl+1;
                    free_space[freespace_count].end = ext_table[cur_disk][sort[i]].start_cyl -1;
                    free_space[freespace_count].mbytes_unused =
                         cylinders_to_mbytes(free_space[freespace_count].space,cur_disk);       /* AN004 */
                    free_space[freespace_count].percent_unused = (unsigned)
                         cylinders_to_percent(free_space[freespace_count].space,total_disk[cur_disk]);                         /* AN000 */


                    /* update the last found partition */
                    last_found_partition = sort[i];
                    freespace_count++;
                   END
               END
            /* Find the space between the last partition and the end of the extended partition */
            temp = part_table[cur_disk][ext_location].end_cyl -  ext_table[cur_disk][last_found_partition].end_cyl;
            free_space[freespace_count].space = temp;
            free_space[freespace_count].start = ext_table[cur_disk][last_found_partition].end_cyl+1;
            free_space[freespace_count].end = part_table[cur_disk][ext_location].end_cyl;
            free_space[freespace_count].mbytes_unused =
                 cylinders_to_mbytes(free_space[freespace_count].space,cur_disk);    /* AN004 */
            free_space[freespace_count].percent_unused = (unsigned)
                 cylinders_to_percent(free_space[freespace_count].space,total_disk[cur_disk]);                      /* AN000 */

           END
        else
           BEGIN
            /* No partitions found, show entire space as free */
            free_space[0].space = (part_table[cur_disk][ext_location].end_cyl - part_table[cur_disk][ext_location].start_cyl) + 1;
            free_space[0].start = part_table[cur_disk][ext_location].start_cyl;
            free_space[0].end = part_table[cur_disk][ext_location].end_cyl;
            free_space[0].mbytes_unused =
                 cylinders_to_mbytes(free_space[0].space,cur_disk);  /* AN004 */
            free_space[0].percent_unused = (unsigned)cylinders_to_percent(free_space[0].space,total_disk[cur_disk]); /* AN000 */
           END

         /* Find largest free space */
         temp = u(0);                                                   /* AC000 */


         /* Find largest free space, and verify the golden tracks while we are at it */
         do
            BEGIN
             temp = u(0);                                               /* AC000 */

             /* Zip thru the table */
             for (i = c(0); i < c(24); i++)                             /* AC000 */
                BEGIN
                 /* Is this one bigger ? */
                 if (free_space[i].space > temp)
                    BEGIN
                     temp = free_space[i].space;
                     last_found_partition = i;
                    END
                END
             /* If there is any free space, go verify it */
             temp = u(0);
             if (free_space[last_found_partition].space != u(0))        /* AC000 */
                BEGIN

                 /* Go verify the tracks */
                 temp = verify_tracks(last_found_partition,c(EXTENDED)); /* AC000 */
                END
             /* Move up to next golden track */
             free_space[last_found_partition].start = free_space[last_found_partition].start+temp;
             free_space[last_found_partition].space = free_space[last_found_partition].space-temp;
             free_space[last_found_partition].mbytes_unused =
                  cylinders_to_mbytes(free_space[last_found_partition].space,cur_disk);    /* AN004 */
             free_space[last_found_partition].percent_unused =
                  cylinders_to_percent(free_space[last_found_partition].space,total_disk[cur_disk]);                       /* AN000 */
             END
             /* Repeat the loop if the start was moved due to bad tracks */
            /* Unless we're past the end of the free space */
            while ((temp !=u(0)) && (free_space[last_found_partition].space!= u(0)));  /* AC000 */

        /* Return with the pointer to the largest free space */
        return(last_found_partition);
END


/*  */
void sort_ext_table(size)

char size;

BEGIN

char  changed;
char  temp;
char i;

        /* Init the sorting parameters */

        for (i=c(0); i < size; i++)                                     /* AC000 */
           BEGIN
            sort[i] = i;
           END

        /* Do a bubble sort */
        changed = TRUE;

        /* Sort until we don't do a swap */
        while (changed)

           BEGIN
            changed = FALSE;
            for (i=c(1); i < size; i++)                                 /* AC000 */
               BEGIN

                if (ext_table[cur_disk][sort[i]].start_cyl < ext_table[cur_disk][sort[i-1]].start_cyl)
                   BEGIN

                    temp = sort[i-1];
                    sort[i-1] = sort[i];
                    sort[i] = temp;
                    /* indicate we did a swap */
                    changed = TRUE;
                   END
               END
           END
        return;
END
