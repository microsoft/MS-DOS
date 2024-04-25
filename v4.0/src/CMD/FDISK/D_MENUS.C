
#include "dos.h"                                                        /* AN000 */
#include "fdisk.h"                                                      /* AN000 */
#include "extern.h"                                                     /* AN000 */
#include "subtype.h"                                                    /* AN000 */
#include "fdiskmsg.h"                                                   /* AN000 */
#include "string.h"                                                     /* AN000 */
#include "ctype.h"                                                      /* AN000 */
#include "stdio.h"                                                      /* AN000 */

/*  */
/******************* START OF SPECIFICATIONS *******************/
/*                                                             */
/* SUBROUTINE NAME: DELETE_PARTITION                           */
/*                                                             */
/* DESCRIPTIVE NAME: Delete partition selection menu           */
/*                                                             */
/* FUNCTION: User is prompted as to what type of DOS partition */
/*           he wishes to delete.                              */
/*                                                             */
/* NOTES: The delete volume option is only displayed if some   */
/*        disk volumes exist                                   */
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
/*   04³Delete DOS Partition                    ³              */
/*   05³                                        ³              */
/*   06³Current Fixed Disk Drive: #             ³              */
/*   07³                                        ³              */
/*   08³Enter the type of DOS partition you     ³              */
/*   09³wish to delete..............?           ³              */
/*   10³                                        ³              */
/*   11³    1.  Normal DOS partition            ³              */
/*   12³    2.  EXTENDED DOS Partition          ³              */
/*   13³    3.  Disk volume in the EXTENDED     ³              */
/*   14³        DOS Partition                   ³              */
/*   15³                                        ³              */
/*   16³                                        ³              */
/*   17³                                        ³              */
/*   18³Enter choice: [#]                       ³              */
/*   19³                                        ³              */
/*   20³                                        ³              */
/*   21³                                        ³              */
/*   22³                                        ³              */
/*   23³Press ESC to return to FDISK Options    ³              */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ              */
/*                                                             */
/* ENTRY POINTS: Delete_Partition                              */
/*      LINKAGE: delete_partition()                            */
/*           NEAR CALL                                         */
/*                                                             */
/* INPUT: None                                                 */
/*                                                             */
/* EXIT-NORMAL: ERROR=FALSE                                    */
/*                                                             */
/* EXIT-ERROR: ERROR=TRUE                                      */
/*             GOTO internal_program_error if case statement   */
/*             failure when branching to requested function    */
/*                                                             */
/* EFFECTS: No data directly modified by this routine, but     */
/*          child routines will modify data.                   */
/*                                                             */
/* INTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*      clear_screen                                           */
/*      wait_for_ESC                                           */
/*      get_num_input                                          */
/*      internal_program_error                                 */
/*      dos_delete                                             */
/*      ext_delete                                             */
/*      vol_delete                                             */
/*                                                             */
/* EXTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*                                                             */
/******************** END OF SPECIFICATIONS ********************/

/*  */
void delete_partition()

BEGIN

    unsigned i;
    char input;
    char temp;
    char        max_input;


    input = c(NUL);                                                     /* AC000 */
    /* clear_screen */
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */

    /* Display header */
    display(menu_25);

    /* Setup and print current disk */
    insert[0] = cur_disk+1+'0';
    display(menu_5);

    /* print ESC prompt */
    display(menu_11);

    /* check to see if there is an avail partition                 */
    temp = c(0);                                                        /* AC000 */
    for (i = u(0); i < u(4);i++)                                        /* AC000 */
       BEGIN

        /* See if any non - zero system id bytes */
        temp = temp | part_table[cur_disk][i].sys_id ;
       END
    /* Any entry that isn't zero means */
    if (temp != c(0))                                                   /* AC000 */
       BEGIN
        /* ############# ADD CODE HERE FOR THIS FUNCTION ############## */
        /* Do something about defaults and highlighting                */
        /*                                                              */
        /* ############################################################ */

        /* Display enter prompts */
    /* display dos delete menu without input prompt */
        display(menu_3);
        display(menu_25);
        display(menu_26);
        display(menu_7);

        display(menu_27);                                               /* AC000 */
        max_input = c(3);                                               /* AC000 */

        input = get_num_input(c(NUL),max_input,input_row,input_col);    /* AC000 */
        /* Go branch to the requested function */
        switch(input)
           BEGIN
            case '1':
                      if (find_partition_type(uc(DOS12)) ||             /* AN016 AC016 */
                          find_partition_type(uc(DOS16)) ||             /* AN016 AC016 */
                          find_partition_type(uc(DOSNEW)))              /* AN016 AC016 */
                           dos_delete();
                      else                                              /* AN000 */
                          BEGIN                                         /* AN000 */
                          /* No Pri partition to delete */
                          clear_screen(u(17),u(0),u(17),u(79));         /* AN000 */
                          display(error_6);                             /* AN000 */
                          wait_for_ESC();                               /* AN000 */
                          END                                           /* AN000 */
                      break;

            case '2':
                      if (find_partition_type(uc(EXTENDED)))            /* AN000 */
                          ext_delete();
                      else                                              /* AN000 */
                          BEGIN                                         /* AN000 */
                          /* No Ext partition to delete */
                          clear_screen(u(17),u(0),u(17),u(79));         /* AN000 */
                          display(error_7);                             /* AN000 */
                          wait_for_ESC();                               /* AN000 */
                          END                                           /* AN000 */
                      break;

            case '3':
                      if ((find_partition_type(uc(EXTENDED))) && (find_logical_drive()))  /* AC000 */
                          volume_delete();
                      else
                          BEGIN
                          clear_screen(u(17),u(0),u(17),u(79));         /* AN000 */
                          display(error_36);                            /* AN000 */
                          wait_for_ESC();                               /* AN000 */
                          END                                           /* AN000 */
                      break;

            case ESC: break;

            default : internal_program_error();
                      break;
           END
       END
    else
       BEGIN
        display(error_14);
        wait_for_ESC();
       END
    /* clear the screen before going back to main menu */
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */
    return;
END


/*  */
/******************* START OF SPECIFICATIONS *******************/
/*                                                             */
/* SUBROUTINE NAME: DOS_DELETE                                 */
/*                                                             */
/* DESCRIPTIVE NAME: Delete DOS partition                      */
/*                                                             */
/* FUNCTION: Delete the DOS partition. Prompt user with dire   */
/*           warning first. Default entry on prompt is (N)     */
/*                                                             */
/* NOTES: Screen can be exited via the ESC command before      */
/*        partition is deleted and nothing will change         */
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
/*   04³Delete DOS Partition                    ³              */
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
/*   18³Warning! Data in the DOS partition      ³              */
/*   19³will be lost. Do you wish to            ³              */
/*   20³continue..........................? [N] ³              */
/*   21³                                        ³              */
/*   22³                                        ³              */
/*   23³Press ESC to return to FDISK Options    ³              */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ              */
/*                                                             */
/* ENTRY POINTS: DOS_Delete                                    */
/*      LINKAGE: dos_delete                                    */
/*          NEAR CALL                                          */
/*                                                             */
/* INPUT: None                                                 */
/*                                                             */
/* EXIT-NORMAL: ERROR=FALSE                                    */
/*                                                             */
/* EXIT-ERROR: ERROR=TRUE                                      */
/*             GOTO internal_program_error if invalid input    */
/*             returned to this level                          */
/*                                                             */
/* EFFECTS: No data directly modified by this routine, but     */
/*          child routines will modify data.                   */
/*                                                             */
/* INTERNAL REFERENCES:                                        */
/*   ROUTINES                                                  */
/*      table_display                                          */
/*      clear_screen                                           */
/*      wait_for_ESC                                           */
/*      get_yn_input                                           */
/*      display                                                */
/*      Write_Boot_Record                                      */
/*      find_part_free_space                                   */
/*                                                             */
/* EXTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*                                                             */
/******************** END OF SPECIFICATIONS ********************/

/*  */
void dos_delete()

BEGIN

    char input;
    unsigned i;


    input = c(NUL);                                                     /* AC000 */
    /* clear screen */
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */

    /* Display header */
    display(menu_28);

    /* Setup and print current disk */
    insert[0] = cur_disk+1+'0';
    display(menu_5);

    /* print ESC prompt */
    display(menu_11);

    /* Display partition data and double check if partition exists*/
    if (table_display())
       BEGIN

        sprintf(insert,"%4.0d",total_mbytes[cur_disk]);
        display(menu_15);

        /* See if drive 1 and extended partition exists */

        if (!(find_partition_type(uc(EXTENDED)) && (cur_disk == c(0)))) /* AC000 */
           BEGIN

            /* Nope, we can keep going */
            /* Display Y/N prompt */
            display(menu_29);

            /* Get yes/no prompt */
            input = get_yn_input(c(No),input_row,input_col);        /* AC000 AC011 */
            switch(input)
               BEGIN
                case 1:                                             /* AC000 */
                          BEGIN
                           for (i=u(0); i < u(4); i++)              /* AC000 */
                              BEGIN

                               if ( (part_table[cur_disk][i].sys_id==uc(DOS12)) ||
                                    (part_table[cur_disk][i].sys_id==uc(DOS16)) ||
                                    (part_table[cur_disk][i].sys_id==uc(DOSNEW)) )  /* AC000 */

                                  BEGIN
                                   /* Set Partition entry to zero */
                                   part_table[cur_disk][i].boot_ind = uc(0);        /* AC000 */
                                   part_table[cur_disk][i].start_head = uc(0);      /* AC000 */
                                   part_table[cur_disk][i].start_sector = uc(0);    /* AC000 */
                                   part_table[cur_disk][i].start_cyl = u(0);        /* AC000 */
                                   part_table[cur_disk][i].sys_id = uc(0);          /* AC000 */
                                   part_table[cur_disk][i].end_head = uc(0);        /* AC000 */
                                   part_table[cur_disk][i].end_sector = uc(0);      /* AC000 */
                                   part_table[cur_disk][i].end_cyl = u(0);          /* AC000 */
                                   part_table[cur_disk][i].rel_sec = ul(0);         /* AC000 */
                                   part_table[cur_disk][i].num_sec = ul(0);         /* AC000 */
                                   part_table[cur_disk][i].changed = (FLAG)TRUE;    /* AC000 */
                                   part_table[cur_disk][i].mbytes_used = f(0);      /* AN000 */
                                   part_table[cur_disk][i].percent_used = u(0);     /* AN000 */

                                   strcpy(part_table[cur_disk][i].system,c(NUL));   /* AN000 */
                                   strcpy(part_table[cur_disk][i].vol_label,c(NUL)); /* AN000 */

                                   /* Redisplay the partition info */
                                   table_display();

                                   /* clear the prompt off */
                                   clear_screen(u(16),u(0),u(23),u(79));    /* AC000 */

                                   /* Set the reboot flag */
                                   reboot_flag = (FLAG)TRUE;                /* AC000 */

                                   /* Say that you deleted it */
                                   display(status_1);

                                   wait_for_ESC();
                                   break;
                                  END
                              END
                          END
                           break;

                case 0:    break;                                   /* AC000 */

                case ESC:  break;

                default:
                           BEGIN
                            internal_program_error();
                            break;
                           END
               END
           END
        else
           BEGIN
            /* Tell user he can't do it while extended exists on drive 1 */
            display(error_32);
            wait_for_ESC();
           END
       END

    else
       BEGIN
        internal_program_error();
       END
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */
    return;
END


/*  */
/******************* START OF SPECIFICATIONS *******************/
/*                                                             */
/* SUBROUTINE NAME: EXT_DELETE                                 */
/*                                                             */
/* DESCRIPTIVE NAME: Delete EXTENDED DOS partition             */
/*                                                             */
/* FUNCTION: Delete the EXTENDED DOS partition. Prompt with    */
/*           warning first. Default entry on prompt is (N)     */
/*                                                             */
/* NOTES: Screen can be exited via the ESC command before      */
/*        partition is deleted and nothing will change         */
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
/*   04³Delete EXTENDED DOS Partition           ³              */
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
/*   18³Warning! Data in the EXTENDED DOS       ³              */
/*   19³partition will be lost. Do you wish     ³              */
/*   20³to continue.......................? [N] ³              */
/*   21³                                        ³              */
/*   22³                                        ³              */
/*   23³Press ESC to return to FDISK Options    ³              */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ              */
/*                                                             */
/* ENTRY POINTS: Ext_Delete                                    */
/*      LINKAGE: ext_delete ()                                 */
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
/*      table_display                                          */
/*      clear_screen                                           */
/*      wait_for_ESC                                           */
/*      get_yn_input                                           */
/*      display                                                */
/*      Write_Boot_Record                                      */
/*      Internal_Program_Error                                 */
/*      Find_Free_Space                                        */
/*                                                             */
/* EXTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*                                                             */
/******************** END OF SPECIFICATIONS ********************/

/*  */
void ext_delete()


BEGIN

    char   input;
    unsigned i;
    unsigned j;                                                         /* AN000 */


    input = c(NUL);                                                     /* AC000 */
    /* Clear the screen */
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */

    /* Display header */
    display(menu_30);

    /* Setup and print current disk */
    insert[0] = cur_disk+1+'0';
    display(menu_5);

    /* print ESC prompt */
    display(menu_11);

    /* Display partition data and double check if partition exists*/
    table_display();                                                    /* AC000 */
    sprintf(insert,"%4.0d",total_mbytes[cur_disk]);
    display(menu_15);

       BEGIN
        /* See if there are still volumes */
        if (!find_logical_drive())
           BEGIN
            /* Display Y/N prompt */
            display(menu_31);

            /* Get yes/no prompt */
            input = get_yn_input(c(No),input_row,input_col);            /* AC000 AC011 */
            switch(input)
               BEGIN
                case 1:                                                 /* AC000 */
                      BEGIN
                       for (i=u(0); i < u(4); i++)                      /* AC000 */
                       /* Note: This will delete all occurances of EXTENDED DOS partitions found */
                          BEGIN
                           if (part_table[cur_disk][i].sys_id == uc(EXTENDED))  /* AC000 */
                              BEGIN
                               /* Set Partition entry to zero */
                               part_table[cur_disk][i].boot_ind = uc(0);        /* AC000 */
                               part_table[cur_disk][i].start_head = uc(0);      /* AC000 */
                               part_table[cur_disk][i].start_sector = uc(0);    /* AC000 */
                               part_table[cur_disk][i].start_cyl = u(0);        /* AC000 */
                               part_table[cur_disk][i].sys_id = uc(0);          /* AC000 */
                               part_table[cur_disk][i].end_head = uc(0);        /* AC000 */
                               part_table[cur_disk][i].end_sector = uc(0);      /* AC000 */
                               part_table[cur_disk][i].end_cyl = u(0);          /* AC000 */
                               part_table[cur_disk][i].rel_sec = ul(0);         /* AC000 */
                               part_table[cur_disk][i].num_sec = ul(0);         /* AC000 */
                               part_table[cur_disk][i].changed = (FLAG)TRUE;    /* AC000 */
                               part_table[cur_disk][i].mbytes_used = f(0);      /* AN000 */
                               part_table[cur_disk][i].percent_used = u(0);     /* AN000 */

                               strcpy(part_table[cur_disk][i].system,c(NUL));   /* AN000 */
                               strcpy(part_table[cur_disk][i].vol_label,c(NUL)); /* AN000 */

                               /* Redisplay the partition info */
                               table_display();

                               /* clear the prompt off */
                               clear_screen(u(17),u(0),u(23),u(79));    /* AC000 */

                               /* Say that you deleted it */
                               display(status_2);

                               /* Set the reboot flag */
                               reboot_flag = (FLAG)TRUE;                /* AC000 */
                              END
                          END
                       wait_for_ESC();
                       break;
                      END

                case 0:    break;                                       /* AC000 */

                case ESC:  break;

                default:   internal_program_error();
                           break;
               END
           END
        else
           BEGIN
            /* Logical drives still exist, can't delete partition */
            display(error_21);
            wait_for_ESC();
           END
       END
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */
    return;
END


/*  */
/******************* START OF SPECIFICATIONS *******************/
/*                                                             */
/* SUBROUTINE NAME: VOL_DELETE                                 */
/*                                                             */
/* DESCRIPTIVE NAME: Delete DOS disk Volume                    */
/*                                                             */
/* FUNCTION: Prompts user to delete a DOS disk volume          */
/*                                                             */
/* NOTES: Screen can be exited via the ESC command before      */
/*        partition is deleted and nothing will change         */
/*                                                             */
/*        The following screen is managed                      */
/*                                                             */
/*     ³0000000000111111111122222222223333333333³              */
/*     ³0123456789012345678901234567890123456789³              */
/*   ÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´              */
/*   00³Delete DOS Disk Volume                  ³              */
/*   01³                                        ³              */
/*   02³Vol Start End  Size                     ³              */
/*   03³ #  ####  #### ####                     ³              */
/*   04³                                        ³              */
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
/*   16³Total partition size is #### cylinders. ³              */
/*   17³                                        ³              */
/*   18³Warning! Data in the DOS disk volume    ³              */
/*   19³will be lost. What volume do you wish   ³              */
/*   20³to delete.........................? [#] ³              */
/*   21³                                        ³              */
/*   22³Are you sure......................? [N] ³              */
/*   23³Press ESC to return to FDISK Options    ³              */
/*   ÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ              */
/*                                                             */
/* ENTRY POINTS: Vol_Delete                                    */
/*      LINKAGE: vol_delete ()                                 */
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
/*      display                                                */
/*      volume_display                                         */
/*      get_num_input                                          */
/*      wait_for_ESC                                           */
/*      get_yn_input                                           */
/*      Write_Boot_Record                                      */
/*      Find_Free_Space                                        */
/*      Internal_Program_Error                                 */
/*                                                             */
/* EXTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*                                                             */
/******************** END OF SPECIFICATIONS ********************/

/*  */
void volume_delete()

BEGIN

    char   input;
    char   drive_input;
    char   high_drive;
    char   low_drive;
    char   error_low_drive;
    char   error_high_drive;
    char   drives_reassigned;
    int    list_index;
    int    i;
    int    j;                                                           /* AN011 */
    int    point;
    FLAG   delete_drive;
    unsigned char   drive_list[23][2];
    int    column;
    int    row;
    FLAG   drives_exist;
    FLAG   vol_matches;
    char   temp;
    unsigned char drive_temp;
    char far *s;
    unsigned char   string_input[12];                                   /* AN000 */

    input = c(NUL);
    string_input[0] = uc(NUL);                                          /* AN000 */

    /* Clear screen */
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */

    /* Display header */
    display(menu_32);

    /* print ESC prompt */
    display(menu_11);

    /* Display logical drives and get the highest drive letter assigned*/
    high_drive = volume_display();

    /* Get the first avail drive letter to be deleted */
    low_drive = (high_drive - get_num_logical_dos_drives()+1);
    temp = low_drive;

    /* Initialize array of drive letters that exist at this point */
    for (i=(int)0; i < (int)23; i++)                                    /* AC000 */
        BEGIN
        /* See if we've exceeded the drive letter range */
        if (temp <= high_drive)
            BEGIN
            /* Put in drive letter */
            drive_list[i][0] = ((unsigned char)(temp));
            /* Initialize the offsets into the array to something harmless */
            drive_list[i][1] = uc(INVALID);                             /* AC000 */
            END
        else
            BEGIN
            /* No drive there, put in NUL */
            drive_list[i][0] = uc(NUL);                                 /* AC000 */
            drive_list[i][1] = uc(INVALID);                             /* AC000 */
            END

        /* Check for next drive */
        temp++;
        END

    /* Set up partition size message */
    sprintf(insert,"%4.0d",get_partition_size( uc(EXTENDED) ) );
    display(menu_21);

    /* Assume no drives deleted */
    drives_reassigned = (FLAG)FALSE;                                    /* AC000 */

    /* Loop until ESC or all deleted */
    while (input != c(ESC))                                             /* AC000 */
        BEGIN

        /* Are there any drives left?*/
        drives_exist = (FLAG)FALSE;                                     /* AC000 */
        error_low_drive = ((char)(NUL));
        error_high_drive = ((char)(NUL));

        for (i=(int)0;i < (int)23; i++)                                 /* AC000 */
            BEGIN
            drive_temp = drive_list[i][0];
            if ((drive_temp != uc(NUL)) && (drive_list[i][1] != uc(DELETED))) /* AC011 */
                BEGIN
                drives_exist = (FLAG)TRUE;                              /* AC000 */

                /* Find last existing drive letter */
                error_high_drive = ((char)(drive_temp));

                /* See if we've found the first drive yet */
                if (error_low_drive == ((char)(NUL)))
                    error_low_drive = ((char)(drive_temp));
                END
            END

        /* If there are drives, go let user try to delete them */
        if (drives_exist)
            BEGIN

            /* Get input until given a correct drive */
            valid_input = (FLAG)FALSE;                                  /* AC000 */
            while ( (!valid_input) && (input != c(ESC)) )
                BEGIN

                /* Prompt for input */
                display(menu_33);

                /* Get input between first and highest drive letters */
                clear_screen( u(21), u(0), u(21), u(79) );
                input = get_alpha_input(low_drive,high_drive,input_row,input_col,error_low_drive,error_high_drive);
                drive_input = input;

                /* See if it has been deleted already or ESC pressed */
                drives_exist = FALSE;
                for (i=(int)0;i < (int)23; i++)                         /* AC000 */
                    BEGIN
                    if (drive_list[i][0] == ((unsigned char)(drive_input)) &&
                       (drive_list[i][1] != ((unsigned char) DELETED))) /* AC013 */
                        BEGIN
                        drives_exist = TRUE;
                        list_index = i;
                        END
                    if (ext_table[cur_disk][i].drive_letter == c(drive_input) )
                        point = i;
                    END
                END

            /* Input volume string to confirm delete */
            vol_matches = FALSE;
            if (input != c(ESC))
                BEGIN
                if (drives_exist)
                    BEGIN
                    /* delete privious volume mismatch message */
                    string_input[0] = uc(NUL);                          /* AN000 */
                    clear_screen( u(22), u(0), u(23), u(79) );
                    /* Get input volume label */
                    display(menu_41);                                       /* AN000 */
                    get_string_input(input_row,input_col,string_input);     /* AN000 */
                    if (string_input[0] == uc(ESC)) input = c(ESC);

                    /* See if the volume id matches the selected drive */            /* AN000 */
                    if (strcmp(ext_table[cur_disk][point].vol_label,string_input) == (int)ZERO)
                           vol_matches = TRUE;                          /* AN000 */
                      else if (input != c(ESC)) display(error_34);
                    END
                 else
                    BEGIN
                    /* Tell user the drive has already been deleted */
                    insert[0] = dos_upper(drive_input);                 /* AC000 */
                    insert[1] = c(DRIVE_INDICATOR);                     /* AC000 */
                    clear_screen( u(21), u(0), u(22), u(79) );          /* AN000 */
                    display(error_29);
                    END

                END

                /* If it is a valid drive indicate that the input was ok */
                if ( (input != c(ESC)) && (drives_exist) && (vol_matches) )                /* AC000 */
                    BEGIN
                    valid_input = TRUE;

                    /* At this point we have a valid drive letter to delete */

                    /* Get the offset into the array for the drive to be deleted */
                    delete_drive = find_ext_drive(drive_input - low_drive);

                    /* Got a drive letter - prompt are you sure */
                    display(menu_34);

                    /* Get Y/N input, default is NO */
                    input = get_yn_input(c(No),input_row,input_col);    /* AC000 AC011 */

                    /* Clear everything out on screen in prompt area */
                    clear_screen(u(23),u(0),u(23),u(79));               /* AC000 */

                    /* Go handle the delete */
                    switch(input)
                        BEGIN
                        case 1:                                         /* AC000 */
                            BEGIN
                             /* Go ahead and mark it deleted in list array */

                             /* Throw up a flag to indicate we need to delete this one for real later */
                             /* This is because if we change the ext_table array now, we lose the ability */
                             /* to match up drive letters with locations, or at least it become more */
                             /* complicated than I felt like figuring out, so mark it now and do it later */
                             drive_list[list_index][1] = (unsigned char)DELETED;     /* AC011 */

                             drives_reassigned = TRUE;

                             /* Put prompt up on screen */
                             for (i=(int)0; i < (int)23; i++)           /* AC000 */
                                 BEGIN
                                 /* See if drive deleted */
                                 if (drive_list[i][1] == uc(DELETED))   /* AC011 */
                                     BEGIN
                                     /* Wipe out the drive info and print deleted message */
                                     /* See what column it is in */
                                     if (i < (int)12)                   /* AC000 */
                                         BEGIN
                                         column = (int)4;               /* AC000 */
                                         row = (int)(4 + i - (int)0);
                                         clear_screen( (unsigned)row, (unsigned)column,
                                                       (unsigned)row, (unsigned)39 );
                                         END
                                     else
                                         BEGIN
                                         column = (int)45;              /* AC000 */
                                         row = (int)(4 + i - (int)12);
                                         clear_screen( (unsigned)row, (unsigned)column,
                                                       (unsigned)row, (unsigned)79 );
                                         END

                                     /* Put the start row,col of message in the message string */
                                     s=status_3;
                                     s++;
                                     *s++ = ((char)(row/10))+'0';
                                     *s++ = ((char)(row%10))+'0';
                                     *s++ = ((char)(column/10))+'0';
                                     *s = ((char)(column%10))+'0';
                                     display(status_3);
                                     END
                                 END
                             /* Set the reboot flag */
                             reboot_flag = TRUE;
                             clear_screen( u(21), u(0), u(23), u(79) ); /* AN000 */
                             break;
                             END

                        case ESC:
                        case 0:
                            clear_screen( u(21), u(0), u(23), u(79) );  /* AN000 */
                            break;                                      /* AC000 */

                        default:
                            internal_program_error();
                            break;
                        END
                    END

            END
         else     /* drives do not exist! */
            BEGIN
            /* No more logical drives to delete */
            clear_screen(u(16),u(0),u(21),u(79));                       /* AC000 */
            display(error_22);
            input = wait_for_ESC();
            END
        END /* while input != esc */

    if (drives_reassigned)
        BEGIN
        /* If anything got deleted, lets go do it for real */
        for (i=(int)0; i < (int)23;i++)                                 /* AC000 */
            BEGIN
            if (drive_list[i][1] == uc(DELETED))                        /* AC011 */
                BEGIN                                                   /* AN011 */
                for (j=(int)0; j < (int)23;j++)                         /* AN011 */
                    BEGIN                                               /* AN011 */
                    if (drive_list[i][0] == ext_table[cur_disk][j].drive_letter)  /* AN011 */
                        BEGIN
                        /* Zero sys id and show it changed */
                        ext_table[cur_disk][j].boot_ind = uc(0);        /* AC000 */
                        ext_table[cur_disk][j].start_head = uc(0);      /* AC000 */
                        ext_table[cur_disk][j].start_sector = uc(0);    /* AC000 */
                        ext_table[cur_disk][j].start_cyl = u(0);        /* AC000 */
                        ext_table[cur_disk][j].sys_id = uc(0);          /* AC000 */
                        ext_table[cur_disk][j].end_head = uc(0);        /* AC000 */
                        ext_table[cur_disk][j].end_sector = uc(0);      /* AC000 */
                        ext_table[cur_disk][j].end_cyl = u(0);          /* AC000 */
                        ext_table[cur_disk][j].rel_sec = ul(0);         /* AC000 */
                        ext_table[cur_disk][j].num_sec = ul(0);         /* AC000 */
                        ext_table[cur_disk][j].mbytes_used = f(0);      /* AN000 */
                        ext_table[cur_disk][j].percent_used = u(0);     /* AN000 */
                        ext_table[cur_disk][j].changed = TRUE;          /* AN000 */
                        ext_table[cur_disk][j].drive_letter = NUL;      /* AN000 */
                        strcpy(ext_table[cur_disk][j].system,c(NUL));   /* AN000 */
                        strcpy(ext_table[cur_disk][j].vol_label,c(NUL)); /* AN000 */
                        END                                             /* AN011 */
                    END                                                 /* AN011 */
                END
            END

        /* Show new drive letters */
        volume_display();

        /* Say that drive letters changed */
        clear_screen(u(16),u(0),u(23),u(79));                           /* AC000 */
        display(status_10);
        wait_for_ESC();
        END
    clear_screen(u(0),u(0),u(24),u(79));                                /* AC000 */

    return;

END

