
/*  */

/******************* START OF SPECIFICATIONS *******************/
/*                                                             */
/* SOURCE FILE NAME: FDISK                                     */
/*                                                             */
/* DESCRIPTIVE NAME: FIXED DISK PARTITIONING UTILITY           */
/*                                                             */
/* FUNCTION:                                                   */
/*     Allows creation and deletion of DOS related partitions  */
/*     on fixed disk devices 80-81h (int 13h BIOS defined,     */
/*     DOS). Also allows display of all partitions, and will   */
/*     allow a partition to be marked active (bootable). The   */
/*     user will be prompted for action thru a full screen     */
/*     interface. The user can also create, delete and display */
/*     logical DOS drives within a EXTENDED DOS Partition. If a*/
/*     regular DOS partition is created, the beginning of the  */
/*     partition will be scanned to insure a contiguous area of*/
/*     good sectors on the disk large enough to satisfy the    */
/*     DOS system requirements. If a bad spot is found, the    */
/*     start of the partition will be moved out until a good   */
/*     area is located                                         */
/*                                                             */
/* NOTES: The program will work by setting up a logical image  */
/*        of all relevant disk information at initilization    */
/*        time. All operations will be performed on this       */
/*        logical image, thus reducing disk accesses to only   */
/*        those required to initially set up the logical image,*/
/*        and to write the changed information at the end. The */
/*        user will be informed if there is a problem writing  */
/*        the logical image back to the disk.                  */
/*                                                             */
/*        FDISK will interface with the partition table in the */
/*        master boot record as defined in the PC-DOS technical*/
/*        reference manual. It will also create and manage the */
/*        EXTENDED DOS partition architecture as defined in the*/
/*        PC-DOS 3.30 functional spec (CP/DOS spec dcr pending)*/
/*                                                             */
/* ENTRY POINTS: MAIN                                          */
/*    LINKAGE: [d:] [path] FDISK                               */
/*                                                             */
/* EXTERNAL REFERENCES:                                        */
/*              Fixed Disk Master Boot Record                  */
/*              EXTENDED Partition Volume Boot Records         */
/*   Note: Both of the above are physical data structures on   */
/*         the surface of the disk                             */
/*                                                             */
/* P.S. - To whoever winds up maintaining this, I will         */
/*        apoligize in advance. I had just learned 'C' when    */
/*        writing this, so out of ignorance of the finer points*/
/*        of the langauge I did a lot of things by brute force.*/
/*        Hope this doesn't mess you up too much - MT 5/20/86  */
/******************** END OF SPECIFICATIONS ********************/

#include <dos.h>                                                        /* AN000 */
#include <fdisk.h>                                                      /* AN000 */
#include <subtype.h>                                                    /* AN000 */
#include <doscall.h>                                                    /* AN000 */
#include <ctype.h>                                                      /* AN000 */
#include <extern.h>                                                     /* AN000 */
#include <signal.h>                                                     /* AN000 */
#include <string.h>                                                     /* AN000 */
#include <fdiskmsg.h>                                                   /* AN000 */
#include <msgret.h>                                                     /* AN000 */
#include <process.h>                                                    /* AN001 */
#include <stdio.h>                                                      /* AN000 */

/*  */
/******************* START OF SPECIFICATIONS *******************/
/*                                                             */
/* SUBROUTINE NAME: MAIN                                       */
/*                                                             */
/* DESCRIPTIVE NAME: Main control routine                      */
/*                                                             */
/* FUNCTION: Main will handle call routines to handle the      */
/*           setup of the video for the full screen interface, */
/*           get physical data on the drive characteristics,   */
/*           initilize all data fields with the current status */
/*           of the disk partitioning information. Before the  */
/*           program is terminated, the video is reset to the  */
/*           mode it was in previous to the routine entry. It  */
/*           will also handle the case of an improper setup    */
/*                                                             */
/* NOTES: FDISK requires at least 1 hardfile to operate        */
/*                                                             */
/* ENTRY POINTS: main();                                       */
/*      LINKAGE:                                               */
/*                                                             */
/* INPUT: None                                                 */
/*                                                             */
/* EXIT-NORMAL: Return Code = 0                                */
/*                                                             */
/* EXIT-ERROR: Return Code =  1                                */
/*                                                             */
/* EFFECTS: Sets up status variables, sets up video for full   */
/*          screen interface, and then restores the video mode */
/*          before exiting program                             */
/*                                                             */
/* INTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*      init_video_information                                 */
/*      get_disk_information                                   */
/*      check_valid_environment                                */
/*      do_main_menu                                           */
/*      init_partition_tables                                  */
/*      reset_video_information                                */
/*                                                             */
/* EXTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*       DosExit                                               */
/*                                                             */
/******************** END OF SPECIFICATIONS ********************/


/*  */
/**************************************************************************/
/*                                                                        */
/*   UTILITY NAME:         FDISK.com                                      */
/*   SOURCE FILE NAME:     FDISK.c                                        */
/*   STATUS:               FDISK utility, DOS 3.3			  */
/*   CHANGE HISTORY:       UPDATED        5-29-87     DOS4.0       DRM    */
/*   SYNTAX (Command line)                                                */
/*                                                                        */
/*         [d:][path]FDISK                                                */
/*                                                                        */
/*         or                                                             */
/*                                                                        */
/*         [d:][path]FDISK  d  [/PRI:m  |  /EXT:n  |  /LOG:o |  /Q ...]   */
/*                                                                        */
/*         d:      Drive to load FDISK utility from                       */
/*                                                                        */
/*         path    path to the directory on specified drive to            */
/*                 load FDISK from                                        */
/*                                                                        */
/*         d       Drive (1 or 2) that FDISK should operate on            */
/*                                                                        */
/*         /PRI:m  Size of Primary DOS partition to create in K           */
/*                                                                        */
/*         /EXT:n  Size of Extended DOS partition to create in K          */
/*                                                                        */
/*         /LOG:o  Size of Logical drive to create in K in the            */
/*                 extended partition                                     */
/*                                                                        */
/*         /Q      This suppresses the reboot screen and returns          */
/*                 FDISK to DOS even if partitons have changed.           */
/*                                                                        */
/*   UTILITY FUNCTION:                                                    */
/*     Allows you to create, set up, display, and delete the              */
/*     DOS partitions on a fixed disk.                                    */
/*                                                                        */
/**************************************************************************/
/*  */
void main(argc,argv)                                                    /* AC000 */

int     argc;                                                           /* AN000 */
char    *argv[];                                                        /* AN000 */

BEGIN

    char       temp;                                                    /* AN000 */
    unsigned   input;

    /* DISABLE CNTL-BREAK HERE */
    /* Gets defines from signal.h */
    signal( (int) SIGINT, SIG_IGN );                                    /* AN000 */

    no_fatal_error = TRUE;                                              /* AN000 */

    /* Preload messages and return */
    if ( preload_messages() &&
         get_yes_no_values() )                                          /* AN000 AC012 */
    BEGIN                                                               /* AN000 */

        /* Parse the command line for syntax and switches */
        if(parse_command_line(argc,argv))                               /* AN000 */

        BEGIN                                                           /* AN000 */
        /* check to see if switches were set */
        if ((primary_flag == FALSE)  &&
            (extended_flag == FALSE) &&
            (logical_flag == FALSE)  &&
            (disk_flag == FALSE))                                       /* AN000 */

            BEGIN                                                       /* AN000 */
            reboot_flag = FALSE;
            /* See if running evironment is ok (Got hardfile, no network */
            if (check_valid_environment())
                BEGIN                                                   /* AN000 */
                /* Get and save screen mode information */
                init_video_information();
                clear_screen(u(0),u(0),u(24),u(79));                    /* AC006 */

                /* Get disk size information */
                good_disk[0] = TRUE;
                good_disk[1] = TRUE;

                if (get_disk_info())
                    BEGIN
                    /* build memory model of partitions */
                    init_partition_tables();

                    /* Go do main screen */
                    do_main_menu();
                    write_info_to_disk();
                    END

                if (reboot_flag)
                    BEGIN                                               /* AN000 */
                    reboot_system();
                    DOSEXIT((unsigned) 0,(unsigned) 0);                 /* AC000 */
                    END                                                 /* AN000 */

                /* Nearly done, go reset screen mode */
                if (no_fatal_error)
                    BEGIN
                    reset_video_information();
                    END                                                 /* AN000 */
                /* this is end of check valid environment */
                END                                                     /* AN000 */
            /* This is end for no switches set */
            END                                                         /* AN000 */

        else                                                            /* AN000 */

            BEGIN                                                       /* AN000 */
            if ( ((primary_flag == FALSE)  &&
                  (extended_flag == FALSE) &&
                  (logical_flag == FALSE)) ||
                  (disk_flag == FALSE)  )                                 /* AN000 */
                display_msg((int)8,(int)DosStdEr,(int)nosubcnt,(int)nosubptr,c(noinput),c(Utility_Msg_Class)); /*;AN000; AC014 AC015 */

            else
                BEGIN
                reboot_flag = FALSE;                                        /* AN000 */
                /* Get disk size information */                             /* AN000 */
                good_disk[0] = TRUE;                                        /* AN000 */
                good_disk[1] = TRUE;                                        /* AN000 */
                if (get_disk_info())                                        /* AN000 */
                    BEGIN
                    if (number_of_drives < (cur_disk_buff+1))
                        display_msg((int)8,(int)DosStdEr,(int)nosubcnt,(int)nosubptr,c(noinput),c(Utility_Msg_Class)); /*;AN000; AC014 AC015*/
                    else
                        BEGIN                                                   /* AN000 */
                        /* build memory model of partitions */
                        init_partition_tables();                                /* AN000 */

                        /* set cur_disk to current disk */
                        cur_disk = cur_disk_buff;                               /* AN000 */

                        /* If /PRI: was specified, create primary partition */
                        /* check to see if a primary partition already exists */
                        if ( (primary_flag == TRUE)            &&                               /* AN000 */
                           ( (!find_partition_type(uc(DOS12))) &&
                             (!find_partition_type(uc(DOS16))) &&
                             (!find_partition_type(uc(DOSNEW))) ) )  /* AC000 */
                            BEGIN
                            temp = find_part_free_space((char) PRIMARY);        /* AN000 */
                            if (primary_buff >= free_space[temp].mbytes_unused) /* AN000 */
                                input = free_space[temp].space;                 /* AN000 */
                            else                                                /* AN000 */
                                input = (unsigned)mbytes_to_cylinders(primary_buff,
                                                                      cur_disk_buff);   /* AN004 */
                            make_partition(input,temp,uc(ACTIVE),(char)PRIMARY);        /* AN000 */
                            END

                        /* If /EXT: was specified, create extended partition */
                        /* Check and see if there is a primary partition before you create an extended */
                        if ( (extended_flag == TRUE)        &&                             /* AN000 */
                           ( (cur_disk == c(1))             ||
                           (find_partition_type(uc(DOS12))) ||
                           (find_partition_type(uc(DOS16))) ||
                           (find_partition_type(uc(DOSNEW))) ) )        /* AC000 */
                           BEGIN
                           /* Make sure there isn't an extended already there */
                           if (!find_partition_type(uc(EXTENDED)))                         /* AC000 */
                               BEGIN
                               temp = find_part_free_space((char) EXTENDED);       /* AN000 */
                               if (extended_buff >= free_space[temp].mbytes_unused) /* AN000 */
                                   input = free_space[temp].space;                 /* AN000 */
                               else                                                /* AN000 */
                                   input = (unsigned)mbytes_to_cylinders(extended_buff,
                                                                         cur_disk_buff);    /* AN004 */
                               make_partition(input,temp,(unsigned char) NUL,(char) EXTENDED);      /* AN000 */
                               END
                            END

                        /* If /LOG: was specified, create logical partition */
                        if ( (logical_flag == TRUE) &&
                             (find_partition_type(uc(EXTENDED))) )                               /* AN000 */
                            BEGIN                                               /* AN000 */
                            temp = find_ext_free_space();                       /* AN000 */
                            if (logical_buff >= free_space[temp].mbytes_unused) /* AN000 */
                                input = free_space[temp].space;                 /* AN000 */
                            else                                                /* AN000 */
                                input = (unsigned)mbytes_to_cylinders(logical_buff,
                                                                      cur_disk_buff);    /* AN004 */
                            make_volume(input,temp);                            /* AN000 */
                            END

                        /* This is end of switch execution */
                        write_info_to_disk();                                   /* AN000 */
                        END                                                     /* AN000 */
                    /* This is the end of compare cur_disk_buff for valid drive */
                    END
                /* This is the end of just disk_flag set */
                END
            /* This is end of if switch is present */
            END
        /* This is end of Parse command line */
        END                                                             /* AN000 */
    /* This end of Preload_messages function */
    END                                                                 /* AN000 */
    cur_disk = c(0);                                                    /* AN001 */
    if ( (quiet_flag == TRUE) &&
         (!find_partition_type(uc(DOS12))) &&
         (!find_partition_type(uc(DOS16))) &&
         (!find_partition_type(uc(DOSNEW))) )                           /* AN001 */
        exit(ERR_LEVEL_1);                                              /* AN001 */
    else
        BEGIN                                                           /* AN005 */
        if ((quiet_flag == TRUE)     &&                                 /* AN005 */
            (primary_flag == FALSE)  &&                                 /* AN008 */
            (extended_flag == FALSE) &&                                 /* AN008 */
            (logical_flag == FALSE))                                    /* AN008 */
            exit(ERR_LEVEL_2);                                          /* AN005 */
        else                                                            /* AN005 */
            exit(ERR_LEVEL_0);                                          /* AN001 */
        END                                                             /* AN005 */
END


