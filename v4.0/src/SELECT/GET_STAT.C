    /************************************************************/
    /*                                                           */
    /*  Header: GET_STATUS                                       */
    /*  Purpose: To transfer information provided by FDISK       */
    /*           to the DOS SELECT utility. The information      */
    /*           provided will determine the status of the       */
    /*           specified fixed disk.  The information is       */
    /*           is pertinent to determine the parameters        */
    /*           displayed and utilized in SELECT panels         */
    /*           that will assume default values according       */
    /*           to option the user selected without viewing     */
    /*           or modifying FDISK.                             */
    /*                                                           */
    /*           The status info will be returned in the control */
    /*           block defined below:                            */
    /*                                                           */
    /*           DISK_STATUS    STRUC                            */
    /*           N_PART_NAME    DB      0  ;partition name       */
    /*           N_PART_SIZE    DW      0  ;size of the above    */
    /*                                     ;partition in (Mbytes)*/
    /*           N_PART_STATUS  DB      0  ;Partition status     */
    /*           P_PART_DRIVE   DB      ?  ;drive letter assigned*/
    /*                                     ;to the partition     */
    /*           DISK_STATUS    ENDS       ;(ASCII value)        */
    /*                                                           */
    /*************************************************************/

    /*************************************************************/
    /* First check to make the ax is specified correctly to make */
    /* the call to Get_STATUS; The value in AX should be 01      */
    /* IF compare is true then proceed with migration            */
    /* ELSE                                                      */
    /*     set AX to to one and report error wrong call value    */
    /* ENDIF                                                     */
    /*                                                           */
    /*                                                           */
    /*************************************************************/
/*****************************************************************************/

#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "dos.h"
#include "get_stat.h"
#include "extern.h"


void      get_status(union REGS *, union REGS *, struct SREGS *);
void      valid_stat(struct  DISK_STATUS far *, union   REGS *);
void      init_partition_tables(void);
char      read_boot_record(unsigned,unsigned char,unsigned char,unsigned char);     /* AC000 */
char      get_drive_parameters(unsigned char);
void      sort_part_table(char);
void      sort_ext_table(char);
unsigned  find_part_free_space(void);
unsigned  find_ext_free_space(void);
void      load_logical_drive(char, unsigned char);
char      find_logical_drive(void);
unsigned  cylinders_to_mbytes(unsigned,unsigned char,unsigned char);   /* AN000 */
char      find_partition_location(unsigned char);
char      find_free_partition(void);
char      find_partition_type(unsigned char);
char      get_disk_info(void);
unsigned  copy_fdisk2select(unsigned, DSE far * );
char      get_num_logical_dos_drives(void);
unsigned  get_partition_size(unsigned char);

void      DiskIo(union REGS *,union REGS *, struct SREGS *);
unsigned  char find_partition_system_type(void);

#define DptrOf(ti)       ( Dptr + (sizeof(DSE) * (ti)) )

void get_status(RinPtr, RoutPtr, SrPtr)
        union   REGS  *RinPtr;
        union   REGS  *RoutPtr;
        struct  SREGS *SrPtr;

BEGIN
      DSE (far * Dptr);

    /* -------------   drive = regs.x.ax;   */
    /*  Make drive zero based               */
    /* -------------   drive--;             */

    FP_SEG(Dptr) = SrPtr->es;
    FP_OFF(Dptr) = RinPtr->x.di;

    RoutPtr->x.bx = 0;
    RoutPtr->x.cx = 0;

    switch(RinPtr->x.ax)                   /* Check the value in AX */
     BEGIN

        case uc(FST_DRV):               /* Is it a query for the first drive? */
        case uc(SEC_DRV):               /* Is it a query for the 2nd drive? */
                 cur_disk = c(RinPtr ->x.ax - 1);
                 RoutPtr->x.ax = 0;
                 valid_stat(Dptr,RoutPtr); /* yes than go execute              */
                 break;

        default:                        /* otherwise - set AX to one & exit */
                 RoutPtr->x.ax = 1;
                 break;
      END

      return;

END

/*****************************************************************************/
/******************* START OF SPECIFICATIONS *******************/
/*                                                             */
/* SUBROUTINE NAME: VALID_STAT                                 */
/*                                                             */
/* DESCRIPTIVE NAME:                                           */
/*                                                             */
/* FUNCTION:                                                   */
/*      ENTRY:                                                 */
/*                                                             */
/* MOV     AX,?? ;    AX = 1 first fixed drive                 */
/*                                                             */
/*               ;       = 2 second fixed drive                */
/*               ; ES:DI - points to parameter block           */
/*               ;                                             */
/*     CALL    GET_DISK_STATUS         ; call to subroutine    */
/*                                     ;                       */
/*               ; EXIT:                                       */
/*               ;    AX = 1 drive is not valid                */
/*               ;       = 0 drive is valid                    */
/*               ;    CX = number of items in parameter block  */
/*               ;    BX = status of fixed drive               */
/*               ;         as defined below -                  */
/*               ;         more than 1 bit can be set          */
/*               ; ES:DI is filled with data                   */
/*                                                             */
/* EXIT-NORMAL: ERROR=FALSE                                    */
/*                                                             */
/* EXIT-ERROR: ERROR=TRUE                                      */
/*             GOTO internal_program_error if invalid num      */
/*             input is returned to this level                 */
/*                                                             */
/* EFFECTS:                                                    */
/*                                                             */
/*                                                             */
/*                                                             */
/* INTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*                                                             */
/*                                                             */
/* EXTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*                                                             */
/******************** END OF SPECIFICATIONS ********************/

void valid_stat(Dptr,RoutPtr)
        DSE     (far * Dptr);
        union   REGS *RoutPtr;

BEGIN

unsigned table_count;
char     i;
unsigned m;
unsigned temp;

/**********************************replacement***********************************************/
/*  Initialize the tables that will be used to store the data needed for                    */
/*  SELECT.   The disk_status tables will be initialized to 0 for all                       */
/*  values except the logical drive value, if exist in an extended partition                */
/*  other wise the field will remain undefined. This must be done for both                  */
/*  tables although it has not been established that two physical drives exist              */
/*  at this point. Additional tables needed are the tables 1) To store the                  */
/*  amount of free space between each partition 2) the amount of free space                 */
/*  between each logical drive (the tables are declared to integer                          */
/********************************************************************************************/


        /* Init variables */
        RoutPtr->x.bx = 0;
        RoutPtr->x.cx = 0;
        table_count = 0;

        /* Read drives to get disk information on size, etc..... */
        /* good_disk[] = FALSE if can't read disk                */
        good_disk[0] = TRUE;
        good_disk[1] = TRUE;
        if (!get_disk_info())
            BEGIN
            good_disk[0] = FALSE;
            good_disk[1] = FALSE;
            END

        /* See if we could read the selected drive */
        if  ( !good_disk[cur_disk] )
           RoutPtr->x.ax = 1; /* indicate disk read failed */
        else
            BEGIN
            init_partition_tables();

            /* Is there a primary ? */

            if (find_partition_system_type() != uc(NOT_FOUND))
                 BEGIN
                 RoutPtr->x.bx |= E_DISK_PRI;
                 (Dptr+table_count) -> n_part_name = E_PART_PRI_DOS;
                 (Dptr+table_count) -> n_part_size = get_partition_size(find_partition_system_type());

                 for (i = c(0); i < c(4);i++)                                           /* AC000 */
                     if ( (part_table[cur_disk][i].sys_id == DOS12) ||
                          (part_table[cur_disk][i].sys_id == DOS16) ||
                          (part_table[cur_disk][i].sys_id == DOSNEW)  )
                          break;

                 (Dptr+table_count) -> n_part_status = E_PART_UNFORMAT;
                 if (part_table[cur_disk][i].formatted)
                    (Dptr+table_count) -> n_part_status = E_PART_FORMAT;
                 (Dptr+table_count) -> p_part_drive = part_table[cur_disk][i].drive_letter;
                 for (m=u(0);m < u(4); m++)
                     (Dptr+table_count) -> n_part_level[m] = part_table[cur_disk][i].system_level[m];


                 table_count++;
                 END

            /* if there an extended? */

            if (find_partition_type(EXTENDED))
                BEGIN
                /* Found one, now fill in entry with vital stats */
                RoutPtr->x.bx |= E_DISK_EXT_DOS;
                (Dptr+table_count) ->n_part_name = E_PART_EXT_DOS;
                (Dptr+table_count) ->n_part_size = get_partition_size(EXTENDED);
                (Dptr+table_count) -> n_part_status = E_PART_UNFORMAT;
                (Dptr+table_count) -> p_part_drive = next_letter;
                 for (m=u(0);m < u(4); m++)
                     (Dptr+table_count) -> n_part_level[m] = NUL;
                table_count++;
                END

            /* Are there any logical drives */

            if ( (find_partition_type(EXTENDED)) && (find_logical_drive()) )
                RoutPtr->x.bx |= E_DISK_LOG_DRI;

            /* Is there free extended partition space, and are there free entries?*/

            if ( (temp = find_ext_free_space()) != u(0))
                BEGIN
                /* Indicate we have room in the extended, and build entry to show how much */
                RoutPtr->x.bx |= E_DISK_EDOS_MEM;
                (Dptr+table_count) ->n_part_name = uc(E_FREE_MEM_EDOS);
                (Dptr+table_count) ->n_part_size = temp;
                (Dptr+table_count) -> n_part_status = E_PART_UNFORMAT;
                (Dptr+table_count) -> p_part_drive = c(' ');
                 for (m=u(0);m < u(4); m++)
                     (Dptr+table_count) -> n_part_level[m] = NUL;
                table_count++;
                END

            /* Is there any free space in master boot record partitions, and free partitions? */

            if ( (temp = find_part_free_space()) != u(0))
                BEGIN
                /* Indicate we have free space in the MBR partition tables */
                RoutPtr->x.ax = 0;
                RoutPtr->x.bx |= E_DISK_FREE_MEM;
                (Dptr+table_count) ->n_part_name = uc(E_FREE_MEM_DISK);
                (Dptr+table_count) ->n_part_size = temp;
                 for (m=u(0);m < u(4); m++)
                     (Dptr+table_count) -> n_part_level[m] = NUL;
                table_count++;
                END

            /* If there is a logical drive get the drive letters and  the associated */
            /* size, and for the logical drive                                       */

            /* First check again to see if their is an extended partition */
            /* and see if there exist any logical drives --- sort the logical */
            /* drives and and get the drive and stuffit ine the table         */

            /********************************CNS******************************************/
            if ( (find_partition_type(EXTENDED)) && (find_logical_drive()) )
                table_count += copy_fdisk2select(table_count,Dptr);                             /* go fill the tables */
            /*****************************************************************************/
            /*      Now we should get the number of items that will be returned to select */
            /*      and stuff it in CX                                                    */
            /******************************************************************************/
            RoutPtr->x.cx = table_count;              /* number of items */
            regs.x.ax = u(0);

            END

        return;

END

void init_partition_tables()
BEGIN

unsigned i;
unsigned char j;
unsigned k;
unsigned l;
unsigned m;
unsigned n;
unsigned partition_location;
char temp;
char more_drives_exist;
char num_logical_drives;
unsigned insert;
unsigned index;
char     save_disk;

        save_disk = cur_disk;

        /* initialize first drive found to "C" */
        next_letter = c('C');                                              /* AC000 */

        /* Look at both disks */
        for (j = uc(0); j < number_of_drives; j++)                      /* AC000 */
           BEGIN

            /* Initialize the cur_disk field to the drive in question so */
            /* that the calls to the partition information routines will work */
            cur_disk = ((char)(j));

            /* Read in the master boot record and see if it was okay */
            if (read_boot_record(u(0),j,uc(0),uc(1)))                      /* AC000 */
               BEGIN

                /* See if there was a valid boot record there */
                if ((boot_record[510] == uc(0x55)) && (boot_record[511] == uc(0xAA)))  /* AC000 */
                   BEGIN

                    /* What was on the disk is a valid boot record, so save it */
                    for (i=u(0);i < u(BYTES_PER_SECTOR); i++)           /* AC000 */
                       BEGIN
                        master_boot_record[j][i] = boot_record[i];
                       END
                   END
                /* We've now got a copy of the master boot record saved. Now we need */
                /* to translate what in the boot record to the area that it's going
                /* to be worked on (part_table) */

                /* Read in the data from the master boot record partition entries*/
                for (i=u(0); i < u(4); i++)                             /* AC000 */
                   BEGIN
                    index = i*16;

                    /* Get boot ind */
                    part_table[j][i].boot_ind = master_boot_record[j][0x1BE+index];

                    /* Start head */
                    part_table[j][i].start_head = master_boot_record[j][0x1BF+index];

                    /* Start sector - unscramble it from INT 13 format*/
                    part_table[j][i].start_sector= (master_boot_record[j][0x1C0+index] & 0x3F);

                    /* Start cyl - unscramble it from INT 13 format*/
                    part_table[j][i].start_cyl= ((((unsigned)master_boot_record[j][0x1C0+index]) & 0x00C0) << 2)
                                                + ((unsigned)master_boot_record[j][0x1C1+index]);

                    /* System id */
                    part_table[j][i].sys_id = master_boot_record[j][0x1C2+index];

                    /* End head */
                    part_table[j][i].end_head = master_boot_record[j][0x1C3+index];

                    /* End sector - unscramble it from INT 13 format*/
                    part_table[j][i].end_sector= (master_boot_record[j][0x1C4+index] & 0x3F);

                    /* End cyl - unscramble it from INT 13 format*/
                    part_table[j][i].end_cyl= ((((unsigned)master_boot_record[j][0x1C4+index]) & 0x00C0) << 2)
                                                + ((unsigned)master_boot_record[j][0x1C5+index]);

                    /* Relative sectors */

                    part_table[j][i].rel_sec =
                       ((unsigned long)master_boot_record[j][0x1C9+index]) << 24;

                    part_table[j][i].rel_sec = part_table[j][i].rel_sec +
                       (((unsigned long)master_boot_record[j][0x1C8+index]) << 16);

                    part_table[j][i].rel_sec = part_table[j][i].rel_sec +
                       (((unsigned long)master_boot_record[j][0x1C7+index]) << 8);

                    part_table[j][i].rel_sec = part_table[j][i].rel_sec +
                       ((unsigned long)master_boot_record[j][0x1C6+index]);

                    /* Number of sectors */
                    part_table[j][i].num_sec =
                       ((unsigned long)master_boot_record[j][0x1CD+index]) << 24;

                    part_table[j][i].num_sec = part_table[j][i].num_sec +
                       (((unsigned long)master_boot_record[j][0x1CC+index]) << 16);

                    part_table[j][i].num_sec = part_table[j][i].num_sec +
                       (((unsigned long)master_boot_record[j][0x1CB+index]) << 8);

                    part_table[j][i].num_sec = part_table[j][i].num_sec +
                       ((unsigned long)master_boot_record[j][0x1CA+index]);

                    part_table[j][i].mbytes_used =
                       cylinders_to_mbytes(((part_table[j][i].end_cyl-part_table[j][i].start_cyl)+1),
                        max_sector[cur_disk], max_head[cur_disk]);                                              /* AN000 */

                    /* Set drive letter */
                    if ( (part_table[j][i].sys_id == DOS12) ||                                                  /* AN000 */
                         (part_table[j][i].sys_id == DOS16) ||                                                  /* AN000 */
                         (part_table[j][i].sys_id == DOSNEW)   )                                                /* AN000 */
                            part_table[j][i].drive_letter = next_letter++;                                      /* AN000 */

                    /* Clean out the boot_record */
                    for (m=u(0);m < u(BYTES_PER_SECTOR); m++)                       /* AC000 */
                       BEGIN
                        boot_record[m] = uc(0);                                     /* AC000 */
                       END

                    part_table[j][i].formatted = FALSE;
                    for (m=u(0);m < u(4); m++)
                        part_table[j][i].system_level[m] = NUL;
                    if (read_boot_record(part_table[j][i].start_cyl,                 /* AN000 */
                                         j,
                                         part_table[j][i].start_head,
                                         part_table[j][i].start_sector))
                         BEGIN                                                                   /* AN000 */
                         /* See if the disk has already been formated */
                          if ((boot_record[510] == uc(0x55)) && (boot_record[511] == uc(0xAA)))  /* AN000 */
                               BEGIN
                               part_table[j][i].formatted = TRUE;                                                 /* AN000 */
                               for (m=u(0);m < u(4); m++)
                                   BEGIN
                                   n = (m + u(7));
                                   part_table[j][i].system_level[m] = boot_record[n];
                                   END
                               END
                          read_boot_record(part_table[j][i].start_cyl,j,uc(0),uc(1));
                         END
                   END
               END
            else
               BEGIN
                 cur_disk = save_disk;
                 return;
               END
           END

        /* Look at both disks */
        for (j = uc(0); j < number_of_drives; j++)                      /* AC000 */
           BEGIN

            /* Initialize the cur_disk field to the drive in question so */
            /* that the calls to the partition information routines will work */
            cur_disk = ((char)(j));
               BEGIN
                /* Read in the master boot record and see if it was okay */
                if (read_boot_record(u(0),j,uc(0),uc(1)))                      /* AC000 */
                /* Now, go read in extended partition info */
                   BEGIN
                    if (find_partition_type(uc(EXTENDED)))                      /* AC000 */
                       BEGIN
                        /* Initialize the array to zero's - include one dummy entry */
                        for (i=u(0); i < u(24); i++)                            /* AC000 */
                           BEGIN
                            ext_table[j][i].boot_ind = uc(0);                   /* AC000 */
                            ext_table[j][i].start_head = uc(0);                 /* AC000 */
                            ext_table[j][i].start_sector = uc(0);               /* AC000 */
                            ext_table[j][i].start_cyl = u(0);                   /* AC000 */
                            ext_table[j][i].sys_id = uc(0);                     /* AC000 */
                            ext_table[j][i].end_head = uc(0);                   /* AC000 */
                            ext_table[j][i].end_sector = uc(0);                 /* AC000 */
                            ext_table[j][i].end_cyl = u(0);                     /* AC000 */
                            ext_table[j][i].rel_sec = ul(0);                    /* AC000 */
                            ext_table[j][i].num_sec = ul(0);                    /* AC000 */
                            ext_table[j][i].mbytes_used = f(0);                 /* AN000 */
                            ext_table[j][i].drive_letter = NUL;                 /* AN000 */

                            for (m=u(0);m < u(4); m++)
                                ext_table[j][i].system_level[m] = NUL;           /* AN000 */

                           END

                        /* Find where the first extended boot record is */
                        temp = find_partition_location(uc(EXTENDED));        /* AC000 */
                        partition_location = part_table[j][temp].start_cyl;

                        /* Go find extended boot records as long as there are more of them */
                        more_drives_exist = TRUE;

                        /* Init the number of logical drives, for a array index */
                        num_logical_drives = c(0);                           /* AC000 */

                        while (more_drives_exist)
                           BEGIN
                           /* Assume we won't find another logical drive */
                           more_drives_exist = FALSE;

                             /*Read in the extended boot record */
                             if (read_boot_record(partition_location,j,uc(0),uc(1)))   /* AC000 */
                                BEGIN
                                 load_logical_drive(num_logical_drives,j);


                                 /* find the next logical drive */
                                 for (i = u(0); i < u(4); i++)                      /* AC000 */
                                    BEGIN
                                     index = i*16;
                                     /* See if a sys id byte of exteneded exists */
                                     if (boot_record[0x1C2+index] == uc(EXTENDED))   /* AC000 */
                                        BEGIN
                                         /* Found another drive, now get its location */
                                         partition_location= (((((unsigned)(boot_record[0x1C0 + index])) & 0x00C0) << 2));
                                         partition_location = partition_location + ((unsigned)(boot_record[0x1C1+index]));

                                         /* Indicate we found another one */
                                         more_drives_exist = TRUE;

                                         /* Up the count of found ones */
                                         num_logical_drives++;
                                         break;
                                        END
                                    END
                                END
                           END
                       END
                   END
               END
           END
        cur_disk = save_disk;
        return;
END


/*  */
unsigned  find_part_free_space()

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
        for (i = c(0); i < c(24); i++)                                   /* AC000 */
            BEGIN
            free_space[i].space = u(0);                                 /* AC000 */
            free_space[i].start = u(0);                                 /* AC000 */
            free_space[i].end = u(0);                                   /* AC000 */
            free_space[i].mbytes_unused = u(0);                         /* AC000 */  /* AN000 */
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

                /* free space ends before start of next valid partition */
                if (part_table[cur_disk][sort[i]].start_cyl > u(0))     /* AC000 */
                    free_space[0].end = part_table[cur_disk][sort[i]].start_cyl-1;

                free_space[0].space = part_table[cur_disk][sort[i]].start_cyl;
                free_space[0].mbytes_unused =
                    cylinders_to_mbytes(free_space[0].space,max_sector[cur_disk],max_head[cur_disk]); /* AN000 */

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
                            free_space[freespace_count].space = temp_size - u(1);  /* AC000 */
                        END

                    free_space[freespace_count].start = part_table[cur_disk][last_found_partition].end_cyl+1;
                    free_space[freespace_count].end = part_table[cur_disk][sort[i]].start_cyl -1;
                    free_space[freespace_count].mbytes_unused =
                         cylinders_to_mbytes(free_space[freespace_count].space,max_sector[cur_disk],max_head[cur_disk]); /* AN000 */

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
                 cylinders_to_mbytes(free_space[freespace_count].space,max_sector[cur_disk],max_head[cur_disk]);    /* AN000 */
            END
         else
            BEGIN
            /* No partitions found, show entire space as free */
            free_space[0].start = u(0);                                 /* AC000 */
            free_space[0].end = total_disk[cur_disk]-1;
            free_space[0].space = (free_space[0].end - free_space[0].start)+1;
            free_space[0].mbytes_unused =
                 cylinders_to_mbytes(free_space[0].space,max_sector[cur_disk],max_head[cur_disk]);    /* AN000 */
            END

         /* Find largest free space */
             /* Zip thru the table */
             for (i = c(0); i < c(24); i++)                              /* AC000 */
                 BEGIN
                 /* Is this one bigger ? */
                 if (free_space[i].space > temp)
                     BEGIN
                     temp = free_space[i].space;
                     last_found_partition = i;
                     END
                 END

        return(free_space[last_found_partition].mbytes_unused);
END

/*  */
unsigned find_ext_free_space()
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
            free_space[i].mbytes_unused = u(0);                         /* AN000 */
            END

        /* Find space between start of Extended partition and first volume */
        partition_count = c(0);                                         /* AC000 */
        last_found_partition = c(0);
        ext_location = find_partition_location(uc(EXTENDED));           /* AC000 */

        if (ext_location != c(NOT_FOUND))
            BEGIN

            any_partition = FALSE;
            for (i = c(0); i < c(24); i++)                                  /* AC000 */
               BEGIN
                if (ext_table[cur_disk][sort[i]].sys_id != uc(0))           /* AC000 */
                   BEGIN
                    /* Found a partition, get the space */
                    free_space[0].space = ext_table[cur_disk][sort[i]].start_cyl - part_table[cur_disk][ext_location].start_cyl;
                    free_space[0].start = part_table[cur_disk][ext_location].start_cyl;
                    free_space[0].end = ext_table[cur_disk][sort[i]].start_cyl-1;
                    free_space[0].mbytes_unused =
                         cylinders_to_mbytes(free_space[0].space,max_sector[cur_disk],max_head[cur_disk]);                /* AN000 */

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
                for (i = partition_count+1; i < c(24); i++)                 /* AC000 */
                   BEGIN
                    if (ext_table[cur_disk][sort[i]].sys_id != uc(0))       /* AC000 */
                       BEGIN

                        /* Get space between the end of the last one and the start of the next one */
                        temp = ext_table[cur_disk][sort[i]].start_cyl - (ext_table[cur_disk][last_found_partition].end_cyl+1);
                        free_space[freespace_count].space = temp;
                        free_space[freespace_count].start = ext_table[cur_disk][last_found_partition].end_cyl+1;
                        free_space[freespace_count].end = ext_table[cur_disk][sort[i]].start_cyl -1;
                        free_space[freespace_count].mbytes_unused =
                             cylinders_to_mbytes(free_space[freespace_count].space,max_sector[cur_disk],max_head[cur_disk]);       /* AN000 */


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
                     cylinders_to_mbytes(free_space[freespace_count].space,max_sector[cur_disk],max_head[cur_disk]);    /* AN000 */

                END
            else
                BEGIN
                /* No partitions found, show entire space as free */
                free_space[0].space = (part_table[cur_disk][ext_location].end_cyl - part_table[cur_disk][ext_location].start_cyl) + 1;
                free_space[0].start = part_table[cur_disk][ext_location].start_cyl;
                free_space[0].end = part_table[cur_disk][ext_location].end_cyl;
                free_space[0].mbytes_unused =
                     cylinders_to_mbytes(free_space[0].space,max_sector[cur_disk],max_head[cur_disk]);  /* AN000 */
                END

             /* Find largest free space */
             temp = u(0);                                                   /* AC000 */

             /* Find largest free space */
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
            END
        /* Return with the largest free space */
        return(free_space[last_found_partition].mbytes_unused);
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
                   || ((part_table[cur_disk][sort[i]].sys_id == uc(0)) && (part_table[cur_disk][sort[i-1]].sys_id != uc(0))))  /* AC000 */

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

/*  */
void load_logical_drive(point,drive)

char   point;
unsigned char   drive;

BEGIN

char        volume_label[11];                                           /* AN000 */
unsigned    i;
unsigned    m;
unsigned    n;
unsigned    index;
unsigned    dx_pointer;                                                 /* AN000 */
unsigned    partition_location;                                         /* AN000 */

        /* Check to see if anything is there */
        if ((boot_record[510] == uc(0x55)) && (boot_record[511] == uc(0xAA)))  /* AC000 */
            BEGIN
            /* The boot record is there - read in the logical drive if it is there */
            for (i = u(0); i < u(4); i++)                               /* AC000 */
                BEGIN

                index = i*16;
                /* See if it is a defined extended drive*/
                if ((boot_record[0x1C2 + index] != uc(0)) && (boot_record[0x1C2 + index] != uc(EXTENDED)))  /* AC000 */
                    BEGIN
                    /* Get boot ind */
                    ext_table[drive][point].boot_ind = boot_record[0x1BE + index];

                    /* Start head */
                    ext_table[drive][point].start_head = boot_record[0x1BF + index];

                    /* Start sector - unscramble it from INT 13 format*/
                    ext_table[drive][point].start_sector= (boot_record[0x1C0 + index] & 0x3F);

                    /* Start cyl - unscramble it from INT 13 format*/
                    ext_table[drive][point].start_cyl= ((((unsigned)boot_record[0x1C0+index]) & 0x00C0) << 2)
                                                + ((unsigned)boot_record[0x1C1+index]);


                    /* System id */
                    ext_table[drive][point].sys_id = boot_record[0x1C2+index];

                    /* End head */
                    ext_table[drive][point].end_head = boot_record[0x1C3+index];

                    /* End sector - unscramble it from INT 13 format*/
                    ext_table[drive][point].end_sector= (boot_record[0x1C4+index] & 0x3F);


                    /* End cyl - unscramble it from INT 13 format*/
                    ext_table[drive][point].end_cyl= ((((unsigned)boot_record[0x1C4+index]) & 0x00C0) << 2)
                                                + ((unsigned)boot_record[0x1C5+index]);

                    /* Relative sectors */
                    ext_table[drive][point].rel_sec =
                        ((unsigned long)boot_record[0x1C9+index]) << 24;

                    ext_table[drive][point].rel_sec =
                        ext_table[drive][point].rel_sec+(((unsigned long)boot_record[0x1C8+index]) << 16);

                    ext_table[drive][point].rel_sec =
                        ext_table[drive][point].rel_sec + (((unsigned long)boot_record[0x1C7+index]) << 8);

                    ext_table[drive][point].rel_sec =
                        ext_table[drive][point].rel_sec + ((unsigned long)boot_record[0x1C6+index]);

                    /* Number of sectors */

                    ext_table[drive][point].num_sec =
                        ((unsigned long)boot_record[0x1CD+index]) << 24;

                    ext_table[drive][point].num_sec =
                        ext_table[drive][point].num_sec+(((unsigned long)boot_record[0x1CC+index]) << 16);

                    ext_table[drive][point].num_sec =
                        ext_table[drive][point].num_sec + (((unsigned long)boot_record[0x1CB+index]) << 8);

                    ext_table[drive][point].num_sec =
                        ext_table[drive][point].num_sec + ((unsigned long)boot_record[0x1CA+index]);

                    ext_table[drive][point].mbytes_used =
                        cylinders_to_mbytes(((ext_table[drive][point].end_cyl - ext_table[drive][point].start_cyl)+1),
                        max_sector[drive], max_head[drive]);                          /* AN000 */

                    if ( (ext_table[drive][point].sys_id == DOS12) ||                                                  /* AN000 */
                         (ext_table[drive][point].sys_id == DOS16) ||                                                  /* AN000 */
                         (ext_table[drive][point].sys_id == DOSNEW)   )                                                /* AN000 */
                            ext_table[drive][point].drive_letter = next_letter++;                                      /* AN000 */

                    partition_location = ext_table[drive][point].start_cyl;

                    ext_table[drive][point].formatted = FALSE;
                    for (m=u(0);m < u(4); m++)
                        ext_table[drive][point].system_level[m] = NUL;
                    if (read_boot_record(ext_table[drive][point].start_cyl,                 /* AN000 */
                                         drive,
                                         ext_table[drive][point].start_head,
                                         ext_table[drive][point].start_sector))
                         BEGIN                                                                   /* AN000 */
                         /* See if the disk has already been formated */
                          if ((boot_record[510] == uc(0x55)) && (boot_record[511] == uc(0xAA)))  /* AN000 */
                               BEGIN
                               ext_table[drive][point].formatted = TRUE;                                                 /* AN000 */
                               for (m=u(0);m < u(4); m++)
                                   BEGIN
                                   n = (m + u(7));
                                   ext_table[drive][point].system_level[m] = boot_record[n];
                                   END
                               END


                          read_boot_record(ext_table[drive][point].start_cyl,drive,uc(0),uc(1));
                         END
                    END
                END
            END

        return;

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
FLAG find_partition_type(type)
unsigned char type;

BEGIN
char  i;

/*  Look at all four partition entries for system id byte that matches */
 for (i = c(0); i < c(4);i++)                                           /* AC000 */
    BEGIN

     /* if we find a match, do a TRUE return */
     if (part_table[cur_disk][i].sys_id == type) return(TRUE);
    END
 /* Did not find one, return FALSE */
 return(FALSE);
END
/*  */
unsigned char   find_partition_system_type()

BEGIN
char  i;

/*  Look at all four partition entries for system id byte that matches */
 for (i = c(0); i < c(4);i++)                                           /* AC000 */
    BEGIN

     /* if we find a match, do a TRUE return */
     if ( (part_table[cur_disk][i].sys_id == DOS12) ||
          (part_table[cur_disk][i].sys_id == DOS16) ||
          (part_table[cur_disk][i].sys_id == DOSNEW)  )
         return(part_table[cur_disk][i].sys_id);
    END
 return(uc(NOT_FOUND));                                                  /* AC000 */
END
/*  */
char find_logical_drive()

BEGIN
char  i;

       /* See if there is a logical drive defined in Extended Partition */
 for (i = c(0); i < c(24); i++)                                  /* AC000 */
      BEGIN
      /* See if we find a sys id that is not 0 */
      if (ext_table[cur_disk][i].sys_id != uc(0)) return(TRUE);    /* AC000 */
      END
 return(FALSE);
END
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

unsigned  cylinders_to_mbytes(cylinders_in,sectors_per_track,number_of_heads)   /* AN000 */

unsigned        cylinders_in;                                           /* AN000 */
unsigned char   number_of_heads;                                        /* AN000 */
unsigned char   sectors_per_track;                                      /* AN000 */

BEGIN                                                                   /* AN000 */

unsigned         mbytes_out;                                            /* AN000 */
unsigned long    number_of_bytes;                                       /* AN000 */
unsigned long    number_of_sectors;                                     /* AN000 */
unsigned long    number_of_tracks;                                      /* AN000 */

     number_of_tracks = ul((cylinders_in * number_of_heads));           /* AN000 */
     number_of_sectors = ul((number_of_tracks * sectors_per_track));    /* AN000 */
     number_of_bytes = ul((number_of_sectors * BYTES_PER_SECTOR));      /* AN000 */
     mbytes_out = u((number_of_bytes / ONE_MEG));                       /* AN000 */
     return(mbytes_out);                                                /* AN000 */

END                                                                     /* AN000 */



/**********************************replacement********************************************/
/*   To find out how many logical drives there are, if an extended partition exist       */
/*   copy_fdisk2select. This procedure requires a check to see if any                      */
/*   logical drives exist if so, the drives must be sorted just as the                   */
/*   partitions to distinguish the amount of free space between the current logical      */
/*   drive and the next. The ASCII drive value for each should also be                   */
/*   determined at this point. The same calculation using the start & end                */
/*   cylinder must be used to determine the freespace.                                   */
/*****************************************************************************************/

unsigned copy_fdisk2select(table_count,Dptr)
        unsigned table_count;
        DSE      (far * Dptr);

BEGIN

unsigned    i;
unsigned    m;
unsigned    x;
FLAG        drive_found;
char        drive_num;
char        first_stuff;
char        num_logical_drives ;

        /* loop thru the partitions, only load stuff if it is there */
        drive_num = c(0);                                               /* Current drive */
        drive_found = FALSE;

        /* Find out how many logical drives are available for this hardfile */
        /* To get the number of maximum times to loop thru the table */

        num_logical_drives = get_num_logical_dos_drives();
        for ( i=u(0); i < u(num_logical_drives); i++)
            BEGIN
            /* See if entry exists */
            if ( (ext_table[cur_disk][i].sys_id == uc(DOS12)) ||
                 (ext_table[cur_disk][i].sys_id == uc(DOS16)) ||
                 (ext_table[cur_disk][i].sys_id == uc(DOSNEW)) )  /* AC000  */
                 BEGIN
                 drive_found = TRUE;
                 (Dptr+table_count) ->n_part_size = ext_table[cur_disk][i].mbytes_used;                              /* AC000 */
                 (Dptr+table_count) ->n_part_name = E_PART_LOG_DRI; /* SET the name field to logical drive */
                 (Dptr+table_count) -> n_part_status = E_PART_UNFORMAT;
                 if (ext_table[cur_disk][i].formatted)
                    (Dptr+table_count) -> n_part_status = E_PART_FORMAT;
                 (Dptr+table_count) ->p_part_drive = ext_table[cur_disk][i].drive_letter;
                 for (m=u(0);m < u(4); m++)
                     (Dptr+table_count) -> n_part_level[m] = ext_table[cur_disk][i].system_level[m];
                 drive_num++;                    /* Go to the next actual drive value */
                 table_count++;                  /* Go to the next disk status structure */
                 END                              /* End of check for logical drives        */
            END                                  /* End of loop to traverse thru ext_table */

        return(drive_num);

END

/*  */
char get_num_logical_dos_drives()
BEGIN

char   i;
char number;

       number = c(0);                                                   /* AC000 */
       /* See if there is a logical drive defined in Extended Partition */
       for (i = c(0); i < c(24);i++)                                    /* AC000 */
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
 return(f(0));
END
