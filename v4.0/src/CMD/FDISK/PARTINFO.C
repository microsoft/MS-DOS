
#include "dos.h"                                                        /* AN000 */
#include "fdisk.h"                                                      /* AN000 */
#include "subtype.h"                                                    /* AN000 */
#include "extern.h"                                                     /* AN000 */

/*  */
char find_free_partition()

BEGIN
 char  i;

    /* Look at all four partition entries for empty partition */
    for (i = c(0); i < c(4);i++)                                        /* AC000 */
       BEGIN

        /* if we find an empty one, return which one */
        if (part_table[cur_disk][i].num_sec == ul(0))                   /* AC000 */
           BEGIN
            return(i);
            break;
           END
       END
    /* Did not find one, return NOT_FOUND */
    return(c(NOT_FOUND));                                               /* AC000 */
END

/*  */
char find_partition_type(type)

unsigned char type;

BEGIN
 char  i;

/*  Look at all four partition entries for system id byte that matches */
 for (i = c(0); i < c(4);i++)                                           /* AC000 */
    BEGIN

     /* if we find a match, do a TRUE return */
     if (part_table[cur_disk][i].sys_id == type)
        BEGIN
         return(TRUE);
         break;
        END
    END
 /* Did not find one, return FALSE */
 return(FALSE);
END



/*  */
XFLOAT get_partition_size(type)                                   /* AC000 */

unsigned char type;                                                     /* AC000 */

BEGIN
 char  i;

 /*  Look at all four partition entries for system id byte that matches */
 for (i = c(0); i < c(4);i++)                                           /* AC000 */
    BEGIN

     /* if we find a match, get the size */
     if (part_table[cur_disk][i].sys_id == type)
        BEGIN
         /* Get the size of the partition from the array */
         return(part_table[cur_disk][i].mbytes_used);         /* AC000 */
        END
    END
 /* Did not find one, something bad wrong happened */
 internal_program_error();
END

/*  */
char find_active_partition()

BEGIN

unsigned  char   i;

       /* See if there is an active partition */
       for (i = uc(0); i < uc(4);i++)                                   /* AC000 */
          BEGIN

           /* if we find an active one, TRUE return */
           if (part_table[cur_disk][i].boot_ind == uc(ACTIVE))          /* AC000 */
              BEGIN
               return(TRUE);
               break;
              END
          END
        /* Did not find one, return FALSE */
        return(FALSE);
END


/*  */
char find_partition_location(type)

unsigned char type;

BEGIN
 char  i;

/*  Look at all four partition entries for system id byte that matches */
 for (i = c(0); i < c(4);i++)                                           /* AC000 */
    BEGIN

     /* if we find a match, do a TRUE return */
     if (part_table[cur_disk][i].sys_id == type)
        BEGIN
         return(i);
         break;
        END
    END
 /* Did not find one, return */
 return(c(NOT_FOUND));                                                  /* AC000 */
END

/*  */
char find_free_ext()

BEGIN

 char   i;

    /* Look at all 23 extended entries for empty partition */
    for (i = c(0); i < c(23);i++)                                       /* AC000 */
       BEGIN

        /* if we find an empty one, return which one */
        if (ext_table[cur_disk][i].sys_id == uc(0))                     /* AC000 */
           BEGIN
            return(i);
            break;
           END
       END
    return(c(NOT_FOUND));                                               /* AC000 */
END

/*  */
char find_logical_drive()

BEGIN

unsigned  char  i;

       /* See if there is a logical drive defined in Extended Partition */
       for (i = uc(0); i < uc(23);i++)                                  /* AC000 */
          BEGIN

           /* See if we find a sys id that is not 0 */
           if (ext_table[cur_disk][i].sys_id != uc(0))                  /* AC000 */
              BEGIN
               return(TRUE);
               break;
              END
          END
        return(FALSE);
END

/*  */
char get_num_logical_dos_drives()
BEGIN

char   i;
char number;

       number = c(0);                                                   /* AC000 */
       /* See if there is a logical drive defined in Extended Partition */
       for (i = c(0); i < c(23);i++)                                    /* AC000 */
          BEGIN

           /* See if we find a sys id that is DOS */
           if ((ext_table[cur_disk][i].sys_id == uc(DOS12)) || (ext_table[cur_disk][i].sys_id == uc(DOS16)) ||
              (ext_table[cur_disk][i].sys_id == uc(DOSNEW)))                                                     /* AC000 */
              BEGIN
               number++;
              END
          END
        return(number);
END

/*  */
char find_ext_drive(offset)

char   offset;

BEGIN

char   number_found;
char   i;

        number_found = c(0);                                            /* AC000 */

        /* Go look for the nth extended drive */
        for (i=c(0); i < c(23); i++)                                    /* AC000 */
           BEGIN

            /* See if there is a drive we know about */
            if ((ext_table[cur_disk][i].sys_id == uc(DOS12)) || (ext_table[cur_disk][i].sys_id == uc(DOS16)) ||
               (ext_table[cur_disk][i].sys_id == uc(DOSNEW)))                                   /* AC000 */
               BEGIN
                /* Is this the one we were looking for ? */
                if (number_found == offset)
                   BEGIN
                    /* Yes it is, return where we found it */
                    return(i);
                    break;
                   END
                /* Show we found one and go look for the next */
                number_found++;
               END
           END
        /* We should never get here */
        internal_program_error();
        return(c(INVALID));                                             /* AC000 */
END


/*  */
char find_previous_drive(offset)

char   offset;

BEGIN

char   number_found;
char   last_found;
char   i;

        number_found = c(0);                                            /* AC000 */
        last_found = c(0);                                              /* AC000 */

        /* Go look for the nth extended drive */
        for (i=c(0); i < c(23); i++)                                    /* AC000 */
           BEGIN

            /* See if there is a drive */
            if (ext_table[cur_disk][i].sys_id != uc(0))                 /* AC000 */
               BEGIN
                /* Is this the one we were looking for ? */
                if (number_found == offset)
                   BEGIN
                    /* Yes it is, return where we found the previous one */
                    return(last_found);
                   END
                /* This is the latest one we found, but not the limit, so save it */
                last_found = i;

                /* Show we found one and go look for the next */
                number_found++;
               END
           END
        /* We should never get here */
        internal_program_error();
        return(c(INVALID));                                             /* AC000 */
END

