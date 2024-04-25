
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

#include <dos.h>
#include <fdisk.h>
#include <subtype.h>
#include <extern.h>
#include <doscall.h>
#include <ctype.h>
#include <string.h>                                                     /* AN000 */
#include <fdiskmsg.h>                                                   /* AN000 */
#include <msgret.h>                                                     /* AN000 */
#include <process.h>                                                    /* AN000 */
#include <stdio.h>                                                      /* AN000 */

/*  */
/**************************************************************************/
/*                                                                        */
/*   UTILITY NAME:         FDISK.com                                      */
/*   SOURCE FILE NAME:     FDISK.c                                        */
/*   STATUS:               FDISK utility, DOS 3.3	                  */
/*   CHANGE HISTORY:       UPDATED        5-29-87     DOS4.0       DRM    */
/*   SYNTAX (Command line)                                                */
/*                                                                        */
/*         [d:][path]FDISK                                                */
/*                                                                        */
/*         or                                                             */
/*                                                                        */
/*         [d:][path]FDISK  d  [/PRI:m  |  /EXT:n  |  /LOG:o ...]         */
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
/*   UTILITY FUNCTION:                                                    */
/*     Allows you to create, set up, display, and delete the              */
/*     DOS partitions on a fixed disk.                                    */
/*                                                                        */
/**************************************************************************/

/*  */
/******************* START OF SPECIFICATIONS *******************/
/*                                                             */
/* SUBROUTINE NAME: CHANGE_ACTIVE_PARTITION                    */
/*                                                             */
/* DESCRIPTIVE NAME: Change bootable partition                 */
/*                                                             */
/* FUNCTION: Will allow user to select the partition that will */
/*           recieve control when system is IPL'd. This is     */
/*           only for the first hardfile as far as booting is  */
/*           concerned, although partitions can be set active  */
/*           the second. There are reserved partitions that may*/
/*           not be set active and this routine will enforce   */
/*           that.                                             */
/*                                                             */
/* NOTES: If no valid partition is specified, then the active  */
/*        partition setting is left unchanged. Screen can be   */
/*        exited via the ESC command before active partition   */
/*        is changed and no action will take place             */
/*                                                             */
/*        The following screen is managed                      */
/*                                                             */
/*     ³0000000000111111111122222222223333333333³              */
/*     ³0123456789012345678901234567890123456789³              */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´              */
/*   00³                                        ³              */
/*   01³                                        ³              */
/*   02³                                        ³              */
/*   03³                                        ³              */
/*   04³Change Active Partition                 ³              */
/*   05³                                        ³              */
/*   06³Current Fixed Disk Drive: #             ³              */
/*   07³                                        ³              */
/*   08³Partition Status   Type  Start  End Size³              */
/*   09³    #        #   #######  #### #### ####³              */
/*   10³                                        ³              */
/*   11³                                        ³              */
/*   12³                                        ³              */
/*   13³                                        ³              */
/*   14³Total disk space is #### cylinders.     ³              */
/*   15³                                        ³              */
/*   16³                                        ³              */
/*   17³                                        ³              */
/*   18³Enter the number of the partition you   ³              */
/*   19³want to make active...............: [#] ³              */
/*   20³                                        ³              */
/*   21³                                        ³              */
/*   22³                                        ³              */
/*   23³Press ESC to return to FDISK Options    ³              */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ              */
/*                                                             */
/* ENTRY POINTS: Change_Active_Partition                       */
/*      LINKAGE: change_active_partition ()                    */
/*           NEAR CALL                                         */
/*                                                             */
/* INPUT: None                                                 */
/*                                                             */
/* EXIT-NORMAL: ERROR=FALSE                                    */
/*                                                             */
/* EXIT-ERROR: ERROR=TRUE                                      */
/*             GOTO internal_program_error if invalid num      */
/*             input is returned to this level                 */
/*                                                             */
/* EFFECTS: Display prompts needed to guide user input, and    */
/*          gets input from user.                              */
/*                                                             */
/*                                                             */
/* INTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*      clear_screen                                           */
/*      display                                                */
/*      get_num_input                                          */
/*      table_display                                          */
/*      wait_for_ESC                                           */
/*      internal_program_error                                 */
/*                                                             */
/* EXTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*                                                             */
/******************** END OF SPECIFICATIONS ********************/

/*  */
void change_active_partition()

BEGIN

    char   temp;
    char   default_value;
    char   input;
    unsigned        i;
    unsigned        x;
    char   num_partitions;
    char   valid_partitions;
    char   num_of_bootable_partitions;
    char   valid_input;
    char   input_default;



    input = c(NUL);
    /* Clear screen */
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */

    /* Display header */
    display(menu_23);

    /* Setup and print current disk */
    insert[0] = cur_disk+1+'0';
    display(menu_5);

    /* print ESC prompt */
    display(menu_11);

    /* Only allow active partitions on the first (and bootable) disk */
    if (cur_disk == c(0))                                               /* AC000 */

       BEGIN
        /* Display partition info and see if any partitions exist*/
        if (table_display())

           BEGIN
            /* See if active partition is bootable */
            for (i=u(0); i < u(4); i++)                                 /* AC000 */
               BEGIN
                if (part_table[0][i].sys_id != uc(0) &&
                    part_table[0][i].boot_ind == uc(0x80))  /* AC000 */
                   BEGIN
                    if ((part_table[0][i].sys_id == uc(BAD_BLOCK)) ||
                        (part_table[0][i].sys_id==uc(EXTENDED)))  /* AC000 */
                       BEGIN
                        /* The active partition is not bootable, so warn user */
                        display(error_24);
                       END
                   END
               END

            /* Check to see if only one partition */
            num_partitions = c(0) ;                                     /* AC000 */
            num_of_bootable_partitions = c(0);                          /* AC000 */
            for (i=u(0); i < u(4); i++)                                 /* AC000 */

               BEGIN
                if (part_table[0][i].sys_id != uc(0))                   /* AC000 */
                   BEGIN
                    /* Get a count of partitions */
                    num_partitions++;

                    /* Get a count of the number of defined partitions but don't*/
                    /* count those we know aren't bootable */
                    if ((part_table[0][i].sys_id != uc(BAD_BLOCK)) &&
                        (part_table[0][i].sys_id != uc(EXTENDED)))  /* AC000 */
                       BEGIN
                        num_of_bootable_partitions++;
                       END
                   END
               END
            /* If only one partition found, see if it is active already */
            if (num_of_bootable_partitions == c(1))                     /* AC000 */
               BEGIN

                /* Find the partition and see if it is already active */
                for (i=u(0); i < u(4); i++)                             /* AC000 */

                   BEGIN
                    if (part_table[0][i].sys_id !=uc(0) &&
                        part_table[0][i].boot_ind == uc(0x80))  /* AC000 */

                       BEGIN
                        /* Make sure it is not unbootable partition again*/
                        if ((part_table[0][i].sys_id != uc(BAD_BLOCK)) &&
                            (part_table[0][i].sys_id!=uc(EXTENDED)))  /* AC000 */

                           BEGIN
                            /* Once it is found, put out the message */
                            display(error_15);

                            /* Wait for ESC, then get out */
                            wait_for_ESC();

                            /* clear the screen before going back to main menu*/
                            clear_screen(u(0),u(0),u(24),u(79));        /* AC000 */
                            return;
                           END
                       END
                   END
               END
            /* See if any bootable partitions exist */
            if (num_of_bootable_partitions == c(0))                     /* AC000 */
               BEGIN
                /* At this point, we know at least one partition does exist due to*/
                /* getting past the table_display call, so the only ones around   */
                /* must be unbootable  */

                /* Display this fact then get out of here */
                display(error_25);
               END
            else
               BEGIN
                  /* All is okay to go and set one, do display prompts */
                   number_in_msg((XFLOAT)total_mbytes[cur_disk],u(0));          /* AC000 */
                   display(menu_15);

                  /* Put up input prompt*/
                  display(menu_24);

                  /* Assume bad input until proven otherwise */
                  valid_input = FALSE;
                  valid_partitions = num_partitions;
                  input_default = c(NUL);                               /* AC000 */

                  while (!valid_input)
                     BEGIN
                      /* Go get partition to make active */
                      input = get_num_input(input_default,num_partitions,input_row,input_col);

                      /* Save the input for next time in case CR pressed */
                      input_default = input-'0';

                      clear_screen(u(18),u(0),u(23),u(79));             /* AC000 */

                      if (input != c(ESC))                              /* AC000 */
                         BEGIN
                          /* See if known unbootable partition */
                          /* Set the new one */
                          valid_partitions = c(0);                      /* AC000 */

                          /* Make sure the partitions are in physical order*/
                          sort_part_table(c(4));                        /* AC000 */

                          /* Go find existing partitiona */
                          for (i=u(0);i < u(4); i++)                    /* AC000 */
                             BEGIN
                              /* First we have to find it */
                              if (part_table[0][sort[i]].sys_id != uc(0))   /* AC000 */
                                 BEGIN
                                  /* If this is the 'input'th one, then we got it */
                                  if (valid_partitions == (input-'1'))
                                     BEGIN
                                      /* See if it is an unbootable partition */
                                      if ((part_table[0][sort[i]].sys_id != uc(BAD_BLOCK)) &&
                                       (part_table[0][sort[i]].sys_id !=  uc(EXTENDED)))        /* AC000 */

                                         BEGIN
                                          /* Its bootable, so we have good input */
                                          valid_input = c(TRUE);        /* AC000 */

                                          /* Remove the active indicator from the old partition */
                                          for (x=u(0); x < u(4); x++)   /* AC000 */
                                             BEGIN

                                              if (part_table[0][x].boot_ind == uc(0x80))  /* AC000 */
                                                 BEGIN
                                                  part_table[0][x].changed = TRUE;
                                                  part_table[0][x].boot_ind = uc(0);      /* AC000 */
                                                 END
                                             END

                                          /* Put in new active indicator */
                                          part_table[0][sort[i]].boot_ind = uc(0x80);     /* AC000 */

                                          /* Indicate that it is changed */
                                          part_table[0][sort[i]].changed = TRUE;

                                          /* Update the partition info display */
                                          table_display();

                                          /* Clear off the old prompts */
                                          clear_screen(u(16),u(0),u(21),u(79));     /* AC000 */

                                          /* Say you did it */
                                          insert[0] = input;
                                          display(status_4);
                                          break;
                                         END
                                      else
                                         BEGIN
                                          /* It is, so setup message and tell user */
                                          insert[0] = input;
                                          display(error_17);
                                          break;
                                         END
                                     END
                                  else
                                     BEGIN
                                      /* Indicate we found one but keep going */
                                      valid_partitions++;
                                     END
                                 END
                             END
                         END
                      else
                         BEGIN
                          /* Mark ESC as ok input so we can get out of here */
                          valid_input = c(TRUE);                        /* AC000 */
                         END
                     END /* While loop */
               END
           END /* table display test endif */
        else
           BEGIN
            /* No partitions to make active */
            display(error_16);
           END
       END
    else
       BEGIN
        display(error_26);
       END
    /* clear the screen before going back to main menu */
    if (input != c(ESC))                                                /* AC000 */
       BEGIN
        wait_for_ESC();
       END
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */
    return;
END


/*  */
/******************* START OF SPECIFICATIONS *******************/
/*                                                             */
/* SUBROUTINE NAME: DISPLAY_PARTITION_INFORMATION              */
/*                                                             */
/* DESCRIPTIVE NAME: Display partition information             */
/*                                                             */
/* FUNCTION: Displays defined partition information and prompt */
/*           user to display disk volumes if they exist        */
/*                                                             */
/* NOTES:                                                      */
/*                                                             */
/*        The following screen is managed                      */
/*                                                             */
/*     ³0000000000111111111122222222223333333333³              */
/*     ³0123456789012345678901234567890123456789³              */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´              */
/*   00³                                        ³              */
/*   01³                                        ³              */
/*   02³                                        ³              */
/*   03³                                        ³              */
/*   04³Display Partition Information           ³              */
/*   05³                                        ³              */
/*   06³Current Fixed Disk Drive: #             ³              */
/*   07³                                        ³              */
/*   08³Partition Status   Type  Start  End Size³              */
/*   09³    #        #   #######  #### #### ####³              */
/*   10³                                        ³              */
/*   11³                                        ³              */
/*   12³                                        ³              */
/*   13³                                        ³              */
/*   14³Total disk space is #### cylinders.     ³              */
/*   15³                                        ³              */
/*   16³                                        ³              */
/*   17³                                        ³              */
/*   18³The EXTENDED DOS partition contains DOS ³              */
/*   19³disk volumes. Do you want to display    ³              */
/*   20³the volume information............? [Y] ³              */
/*   21³                                        ³              */
/*   22³                                        ³              */
/*   23³Press ESC to return to FDISK Options    ³              */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ              */
/*                                                             */
/* ENTRY POINTS: Display_Partition_Information                 */
/*      LINKAGE: display_partition_information ()              */
/*          NEAR CALL                                          */
/*                                                             */
/* INPUT: None                                                 */
/*                                                             */
/* EXIT-NORMAL: ERROR=FALSE                                    */
/*                                                             */
/* EXIT-ERROR: ERROR=TRUE                                      */
/*             GOTO internal_program_error if invalid input    */
/*             returned to this routine                        */
/*                                                             */
/* EFFECTS: No data directly modified by this routine, but     */
/*          child routines will modify data.                   */
/*                                                             */
/* INTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*      clear_screen                                           */
/*      wait_for_ESC                                           */
/*      display                                                */
/*      table_display                                          */
/*      get_yn_input                                           */
/*     find_partition_type                                    */
/*      display_volume_information                             */
/*      internal_program_error                                 */
/*                                                             */
/* EXTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*                                                             */
/******************** END OF SPECIFICATIONS ********************/

/*  */
void display_partition_information()

BEGIN

    char   input;
    char    temp;

    input = c(NUL);                                                     /* AC000 */
    /* Clear_screen */
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */

    /* Display Header */
    display(menu_35);

    /* Setup and print current disk */
    insert[0] = cur_disk+1+'0';
    display(menu_5);

    /* print ESC prompt */
    display(menu_11);

    /* Display information */
    if (table_display())
       BEGIN

        /* Setup and print disk space msg */
        number_in_msg((XFLOAT)total_mbytes[cur_disk],u(0));                     /* AC000 */
        display(menu_15);

        /* See if any logical drive stuff to display */
        if (find_partition_type(uc(EXTENDED)))                          /* AC000 */
           BEGIN
            /* See if any logical drives exist */
            if (find_logical_drive())
               BEGIN

                /* Prompt to see if they want to see EXTENDED info */
                display(menu_36);

                /* Get Y/N input, default is YES */
                input = get_yn_input(c(Yes),input_row,input_col);       /* AC000 AC011 */
                switch(input)
                   BEGIN

                    case 1:    display_volume_information();            /* AC000 */
                               break;

                    case 0:    break;                                   /* AC000 */

                    case ESC:  break;

                    default:   internal_program_error();
                               break;
                   END
               END
             else
                input = wait_for_ESC();
           END
        else
           input = wait_for_ESC();
       END
    else
       input = wait_for_ESC();
    /* clear the screen before going back to main menu */
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */
    return;
END



/*  */
/******************* START OF SPECIFICATIONS *******************/
/*                                                             */
/* SUBROUTINE NAME: DISPLAY_VOLUME_INFORMATION                 */
/*                                                             */
/* DESCRIPTIVE NAME: Display DOS disk Volume Information       */
/*                                                             */
/* FUNCTION: Displays disk volume size and existence           */
/*                                                             */
/* NOTES:                                                      */
/*                                                             */
/*        The following screen is managed                      */
/*                                                             */
/*     ³0000000000111111111122222222223333333333³              */
/*     ³0123456789012345678901234567890123456789³              */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´              */
/*   01³Display DOS Disk Volume Information     ³              */
/*   02³                                        ³              */
/*   03³Vol Start End  Size  Vol Start End  Size³              */
/*   04³ #  ####  #### ####   #  ####  #### ####³              */
/*   05³                                        ³              */
/*   06³                                        ³              */
/*   07³                                        ³              */
/*   08³                                        ³              */
/*   09³                                        ³              */
/*   10³                                        ³              */
/*   11³                                        ³              */
/*   12³                                        ³              */
/*   13³                                        ³              */
/*   14³                                        ³              */
/*   15³                                        ³              */
/*   16³                                        ³              */
/*   17³                                        ³              */
/*   18³                                        ³              */
/*   19³                                        ³              */
/*   20³                                        ³              */
/*   21³                                        ³              */
/*   22³                                        ³              */
/*   23³Press ESC to return to FDISK Options    ³              */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ              */
/*                                                             */
/* ENTRY POINTS: Display_Volume_Information                    */
/*      LINKAGE: display_volume_information ()                 */
/*          NEAR CALL                                          */
/*                                                             */
/* INPUT: None                                                 */
/*                                                             */
/* EXIT-NORMAL: ERROR=FALSE                                    */
/*                                                             */
/* EXIT-ERROR: ERROR=TRUE                                      */
/*                                                             */
/* EFFECTS: No data directly modified by this routine, but     */
/*          child routines will modify data.                   */
/*                                                             */
/* INTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*      clear_screen                                           */
/*      wait_for_ESC                                           */
/*      display                                                */
/*      volume_display                                         */
/*                                                             */
/* EXTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*                                                             */
/******************** END OF SPECIFICATIONS ********************/

/*  */
void display_volume_information()

BEGIN

    char   input;
    char    temp;

    input = c(NUL);                                                     /* AC000 */
    /* clear the screen */
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */

    /* Display Header */
    display(menu_37);

    /* Display information */
    temp = volume_display();

    /* Set up partition size message */
    sprintf(insert,"%4.0d",get_partition_size( uc(EXTENDED) ) );
    display(menu_21);

    /* print ESC prompt */
    display(menu_11);

    /* Wait to exit */
    input = wait_for_ESC();
    return;
END

/*  */
char check_valid_environment()
BEGIN

        /* See if the net is there */
        regs.x.ax = u(INSTALLATION_CHECK);                              /* AC000 */
        int86((int)NETWORK,&regs,&regs);                                /* AC000 */

#ifdef DEBUG                                                            /* AN006 */
        regs.h.al = uc(0);                                              /* AN006 */
#endif                                                                  /* AN006 */

        /* Is it ? */
        if (regs.h.al != uc(0))                                         /* AC000 */
           BEGIN

            /* See if server is loaded, otherwise okay */
            if ((regs.x.bx & SERVER_CHECK) != u(0))                     /* AC000 */
               BEGIN
                no_fatal_error = FALSE;
                display_msg((int)4,(int)DosStdEr,(int)nosubcnt,(int)nosubptr,c(noinput),c(Utility_Msg_Class)); /* AN000 AC014*/
                return(FALSE);
               END
           END
        return(TRUE);
END



/*  */
void init_partition_tables()
BEGIN

unsigned i;
unsigned char j;
unsigned k;
unsigned l;
unsigned partition_location;
char temp;
char more_drives_exist;
char num_logical_drives;
unsigned insert;
unsigned index;

        /* initialize first drive found to "C" */
        next_letter = c(SEA);                                              /* AC000 */

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
                /* to translate what in the boot record to the area that it's going  */
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
                                             cur_disk);                 /* AN004 */

                    part_table[j][i].percent_used =
                       cylinders_to_percent(((part_table[j][i].end_cyl-part_table[j][i].start_cyl)+1),
                        total_disk[cur_disk]);                                                                  /* AN000 */

                    /* Set drive letter */
                    if ( (part_table[j][i].sys_id == DOS12) ||                                                  /* AN000 */
                         (part_table[j][i].sys_id == DOS16) ||                                                  /* AN000 */
                         (part_table[j][i].sys_id == DOSNEW)   )                                                /* AN000 */
                            part_table[j][i].drive_letter = next_letter++;                                      /* AN000 */

                    /* Set changed flag */
                    part_table[j][i].changed = FALSE;
                   END
               END
            else
               BEGIN
                 return;
               END
           END

        /* Look at both disks */
        for (j = uc(0); j < number_of_drives; j++)                      /* AC000 */
           BEGIN

            /* Initialize the cur_disk field to the drive in question so */
            /* that the calls to the partition information routines will work */
            cur_disk = ((char)(j));

            /* Read in the master boot record and see if it was okay */
            if (read_boot_record(u(0),j,uc(0),uc(1)))                      /* AC000 */
               BEGIN
                /* Now, go read in extended partition info */
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
                        ext_table[j][i].percent_used = u(0);                /* AN000 */
                        ext_table[j][i].changed = FALSE;
                        ext_table[j][i].drive_letter = NUL;                 /* AN000 */

                        strcpy(ext_table[cur_disk][i].system,NUL);          /* AN000 */
                        strcpy(ext_table[cur_disk][i].vol_label,NUL);       /* AN000 */

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
                         if (read_boot_record(partition_location,
                                              j,
                                              uc(0),
                                              uc(1)))   /* AC000 */
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
        return;
END


/*  */
void load_logical_drive(point,drive)

char   point;
unsigned char   drive;

BEGIN

char        volume_label[13];                                           /* AC000 *//*Used be 11*/
unsigned    ext_part_num;                                               /* AN000 */
unsigned    i;
unsigned    j;                                                          /* AN000 */
unsigned    k;                                                          /* AN000 */
unsigned    length;                                                     /* AN000 */
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
                                              cur_disk);                /* AN004 */

                    ext_part_num = find_partition_location(uc(EXTENDED));

                    ext_table[drive][point].percent_used =
                        cylinders_to_percent(((ext_table[drive][point].end_cyl-ext_table[drive][point].start_cyl)+1),
                        ((part_table[drive][ext_part_num].end_cyl-part_table[drive][ext_part_num].start_cyl)+1));      /* AN000 */

                    ext_table[drive][point].drive_letter = next_letter++;                                      /* AN000 */

                    partition_location = ext_table[drive][point].start_cyl;

                    if (read_boot_record(ext_table[drive][point].start_cyl,
                                         drive,
                                         ext_table[drive][point].start_head,
                                         ext_table[drive][point].start_sector));
                         BEGIN                                                                  /* AN000 */
                         /* See if the disk has already been formated */
                         if (check_format(ext_table[drive][point].drive_letter) == TRUE )       /* AN002 */
                             BEGIN                                                              /* AN000 */
                             /* get volume and system info */

                             /* AC000 Just for cleaning up purposes */

                             for (k = u(0); k < u(12); k++)                                     /* AC000 */
                                 BEGIN                                                          /* AC000 */
                                     ext_table[drive][point].vol_label[k]=u(0);                 /* AC000 */
                                 END                                                            /* AC000 */

                             for (k = u(0); k < u(9); k++)                                      /* AC000 */
                                 BEGIN                                                          /* AC000 */
                                     ext_table[drive][point].system[k]=u(0);                    /* AC000 */
                                 END                                                            /* AC000 */

                             get_volume_string(ext_table[drive][point].drive_letter,&volume_label[0]);   /* AN000 AC015 */

                              for (k = u(0); k < strlen(volume_label); k++)                     /* AC000 AC015 */
                                   BEGIN                                                        /* AC000 AC015 */
                                     ext_table[drive][point].vol_label[k]=volume_label[k];      /* AC000 AC015 */
                                   END                                                          /* AC000 AC015 */

                             /* Now try to get it using GET MEDIA ID function */
                             if (get_fs_and_vol(ext_table[drive][point].drive_letter))          /* AN000 */

                                BEGIN                                                           /* AN000 */
                                /* AC000 Just use more conceptually simple logic */
                                for (k=u(0); k < u(8); k++)                                     /* AC000 */

                                    BEGIN                                                       /* AC000 */
                                      if (dx_buff.file_system[k] != ' ')                        /* AC000 */
                                                length = k+1;                                   /* AC000 */
                                    END                                                         /* AC000 */

                                strncpy(ext_table[drive][point].system,&dx_buff.file_system[0],u(length)); /* AN000 */
                                END                                                             /* AN000 */

                              else                                                              /* AN000 */

                                BEGIN                                                           /* AN000 */
                                if (ext_table[drive][point].num_sec > (unsigned long)FAT16_SIZE) /* AN000 */
                                    strcpy(ext_table[drive][point].system,FAT16);               /* AN000 */
                                else
                                    strcpy(ext_table[drive][point].system,FAT12);               /* AN000 */
                                END                                                             /* AN000 */
                             END                                                                /* AN000 */
                         else                                                                   /* AN000 */
                             BEGIN                                                              /* AN000 */
                             /* set up array to say no file system or volume label */
                             strcpy(ext_table[drive][point].vol_label,NOVOLUME);                /* AN000 */
                             strcpy(ext_table[drive][point].system,NOFORMAT);                   /* AN000 */
                             END                                                                /* AN000 */

                         regs.x.dx = u(0);
                         regs.x.ax = NETWORK_IOCTL;
                         regs.h.bl = ((ext_table[drive][point].drive_letter - 'A') + 1);
                         intdos(&regs,&regs);
                         if (regs.x.dx & 0x1000) strcpy(ext_table[drive][point].vol_label,"* Remote * ");
                         END
                    read_boot_record(ext_table[drive][point].start_cyl,
                                     drive,
                                     uc(0),
                                     uc(1));                                                    /* AN000 */
                    END
                END
            END

        return;

END



/*  */
void reboot_system()
BEGIN


        clear_screen(u(0),u(0),u(24),u(79));                            /* AC000 */
        if (quiet_flag == FALSE)
            BEGIN
            display(menu_38);
            getch();
            reboot();
            END
        else
            BEGIN
            cur_disk = c(0);                                            /* AN001 */
            reset_video_information();                                  /* AN006 */
            if ( (find_partition_type(uc(DOS12))) ||
                 (find_partition_type(uc(DOS16))) ||
                 (find_partition_type(uc(DOSNEW))) )                    /* AN001 */
                exit(ERR_LEVEL_0);                                      /* AN001 */
            else                                                        /* AN001 */
                exit(ERR_LEVEL_1);                                      /* AN001 */
            END
END


/*  */
void internal_program_error()

BEGIN
   display(internal_error);
   DOSEXIT(u(0),u(0));                                                  /* AC000 */
   return;
END


