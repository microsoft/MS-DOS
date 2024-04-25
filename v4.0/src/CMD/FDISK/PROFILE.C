
#include        <doscall.h>
#include        <profile.h>
#include        <fdiskc.msg>
#include        <subtype.h>
#include        <ctype.h>


void    main()

BEGIN

unsigned i;

        /* Main Menu */
        clear_screen(0,0,24,79);
        display(menu_1);
        display(menu_2);
        display(menu_3);
        display(menu_4);
        insert[0] = 'C';
        display(menu_5);
        display(menu_6);
        display(menu_7);

        wait_for_ESC();


        /* Type of DOS partition for create */
        clear_screen(0,0,24,39);
        display(menu_3);
        insert[0] = 'C';
        display(menu_5);
        display(menu_7);
        display(menu_8);
        display(menu_9);
        display(menu_10);
        display(menu_11);
        wait_for_ESC();

        /* Shortcut screen C:*/
        clear_screen(0,0,24,39);
        display(menu_12);
        insert[0] = 'C';
        display(menu_5);
        display(menu_11);
        display(menu_12);
        display(menu_13);
        wait_for_ESC();

        /* Shortcut screen D:*/
        clear_screen(0,0,24,39);
        display(menu_12);
        insert[0] = 'C';
        display(menu_5);
        display(menu_11);
        display(menu_12);
        display(menu_41);
        wait_for_ESC();


/* Create primary DOS partition screen */
        display(menu_12);
        insert[0] = 'C';
        display(menu_5);
        for (i=0;i < 92;i++)
           BEGIN
            insert[i] = 'x';
           END
        display(menu_14);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_15);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_16);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_39);
        display(menu_11);
        wait_for_ESC();

/* Create Extended Partition */
        clear_screen(0,0,24,39);
        display(menu_17);
        insert[0] = 'C';
        display(menu_5);
        for (i=0;i < 92;i++)
           BEGIN
            insert[i] = 'x';
           END
        display(menu_14);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_15);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_16);
        display(menu_39);
        display(menu_11);
        wait_for_ESC();


/* Create logical drive screen */
        clear_screen(0,0,24,39);
        display(menu_18);
        for (i=0;i < 168;i++)
           BEGIN
            insert[i]= 'x';
           END
        display(menu_19);
        for (i=0;i < 168;i++)
           BEGIN
            insert[i]= 'x';
           END
        display(menu_20);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_21);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_22);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_40);
        display(menu_11);
        wait_for_ESC();


/* Change active partition screen */
        clear_screen(0,0,24,39);
        display(menu_23);
        insert[0] = 'C';
        display(menu_5);
        for (i=0;i < 92;i++)
           BEGIN
            insert[i] = 'x';
           END
        display(menu_14);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_15);
        display(menu_24);
        display(menu_11);
        wait_for_ESC();


/* Delete Partition Screen */
        clear_screen(0,0,24,39);
        display(menu_25);
        insert[0] = 'C';
        display(menu_5);
        display(menu_3);
        display(menu_26);
        display(menu_27);
        display(menu_7);
        display(menu_11);
        wait_for_ESC();

/* Delete Primary Screen */
        clear_screen(0,0,24,39);
        display(menu_28);
        insert[0] = 'C';
        display(menu_5);
        for (i=0;i < 92;i++)
           BEGIN
            insert[i] = 'x';
           END
        display(menu_14);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_15);
        display(menu_29);
        display(menu_11);
        wait_for_ESC();


/* Delete Extended Screen */
        clear_screen(0,0,24,39);
        display(menu_30);
        insert[0] = 'C';
        display(menu_5);
        for (i=0;i<92;i++)
           BEGIN
            insert[i] = 'x';
           END
        display(menu_14);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_15);
        display(menu_31);
        display(menu_11);
        wait_for_ESC();


/* Delete Logical Drives */
        clear_screen(0,0,24,39);
        display(menu_32);
        display(menu_18);
        for (i=0;i<168;i++)
           BEGIN
            insert[i]='x';
           END
        display(menu_19);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_21);
        display(menu_33);
        display(menu_11);
        wait_for_ESC();

/* Display Partition Information */
        clear_screen(0,0,24,39);
        display(menu_35);
        insert[0] = 'C';
        display(menu_5);
        for (i=0;i<92;i++)
           BEGIN
            insert[i] = 'x';
           END
        display(menu_14);
        insert[0] = 'x';
        insert[1] = 'x';
        insert[2] = 'x';
        insert[3] = 'x';
        display(menu_15);
        display(menu_36);
        display(menu_11);
        wait_for_ESC();

/* Display Logical Drive Info */
        clear_screen(0,0,24,39);
        display(menu_37);
        for (i=0;i<168;i++)
           BEGIN
            insert[i]='x';
           END
        display(menu_19);
        for (i=0;i<168;i++)
           BEGIN
            insert[i]='x';
           END
        display(menu_20);
        display(menu_11);
        wait_for_ESC();

/* Reboot Screen */
        clear_screen(0,0,24,39);
        display(menu_38);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(status_1);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(status_2);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(status_3);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        insert[0] = 'x';
        display(status_4);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(status_5);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(status_6);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(status_7);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(status_8);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(status_9);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(status_10);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_1);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_2);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_3);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_4);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_5);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_6);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_7);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_8);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_9);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_10);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_12);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_13);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_14);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_15);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_16);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_17);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_19);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_20);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_21);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_22);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        insert[0]='x';
        insert[1]='y';
        insert[2]='-';
        insert[3]='z';
        display(error_23);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_24);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_25);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_26);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_27);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_28);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        insert[0]='X';
        insert[1]=':';
        display(error_29);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        insert[0]='X';
        display(error_30);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        insert[0]='x';
        insert[1]='-';
        insert[2]='y';
        display(error_31);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        display(error_32);
        wait_for_ESC();

        clear_screen(0,0,24,39);
        DOSEXIT(0,0);

END


/******************* START OF SPECIFICATIONS *******************/
/*                                                             */
/* SUBROUTINE NAME: DISPLAY                                    */
/*                                                             */
/* DESCRIPTIVE NAME: Display full screen interface messages    */
/*                                                             */
/* FUNCTION: Displays messages and handles control characters  */
/*                                                             */
/* NOTES:                                                      */
/*  FDISK MESSAGES                                             */
/* Portions of the screen that are handled in the msg are      */
/* indicated on the listing of the screen with the message     */
/* name given.  If the text message is defined in another      */
/* screen, then the name is followed by a "#" character        */
/*                                                             */
/* NOTE TO TRANSLATORS The characters inside the <> and the [] */
/* are control characters and should not be translated.  The   */
/* Control characters are defined as follows:                  */
/*                                                             */
/* <H> - Highlight the following text                          */
/* <R> - Regular text                                          */
/* <B> - Blink the following text                              */
/* <O> - Turn blinking off                                     */
/* <Y> - Print YES character, as set by define                 */
/* <N> - Print NO character, as set by define                  */
/* <W> - Sound the beep                                        */
/* <S> - Save cursor position for later use                    */
/* <I> - Insert character from insert[] string. This string    */
/*       must be set up prior to displaying the message. The   */
/*       first <I> will insert Insert[0], the second           */
/*       insert[1], etc....This will move the cursor one       */
/*       postition. The insert[] string will be initialized    */
/*                                                             */
/* Multiple control characters can be between the <>.          */
/*                                                             */
/* The %####%indicates Row and column for the text and has the */
/* format of [rrcc] where the numbers are decimal and zero     */
/* based (first row/col is 00.  The numbers are in decimal,    */
/* and must be 2 characters, which means rows/cols 0-9 should  */
/* be listed as 00-09.  For example, the 5th row, 3rd column   */
/* on the screen would be listed as %0402%.                    */
/*                                                             */
/* The column number is always the column desired.  The row    */
/* number is an offset from the previous row.  For example, if */
/* the text just printed is on row 6, and the next text should */
/* be printed 2 rows down in column 0, then the control strin  */
/* would be %0201%.  The first row specified in the message is */
/* assumed to be based off of row 0, it would actually specify */
/* the actual row for the start of the msg to be printed.      */
/*                                                             */
/* ENTRY POINTS: display(*message_name);                       */
/*      LINKAGE: Near call                                     */
/*                                                             */
/* INPUT: char *message_name                                   */
/*                                                             */
/* EXIT-NORMAL:                                                */
/*                                                             */
/* EXIT-ERROR:                                                 */
/*                                                             */
/* EFFECTS:                                                    */
/* input_row changed if <S> control character in message       */
/* input_col changed if <S> control character in message       */
/*                                                             */
/* INTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*                                                             */
/* EXTERNAL REFERENCES:                                        */
/*   ROUTINES:                                                 */
/*                                                             */
/* viowrtcharstratt();                                         */
/******************** END OF SPECIFICATIONS ********************/
void display(s)

char far *s;

BEGIN
        unsigned      row;
        unsigned      col;
        char          attribute;
        char far      *attribute_ptr = &attribute;
        unsigned      insert_count;


        /* Initialize row and col, and index into array */
        row = 0;
        col = 0;
        insert_count = 0;
        /* check for a request to display a null string */
        if (*s == '\0')
           BEGIN
            /* Message string error */
            insert[0] = '1';
            display(debug_msg);
           END
        else
           BEGIN
            /* There is data there, lets go handle it */

            attribute = 0x00;
            /* Go until end of string */
            while (*s != '\0')
               BEGIN

                /* Check for any imbedded control strings */
                switch (*s)
                   BEGIN
                    /* Check for control characters */
                    case '<':
                              BEGIN
                               s++;
                               while ( (*s != '>') && (*s != '\0') )
                                  BEGIN
                                   switch (*s++)
                                      BEGIN
                                       case 'H': attribute = (attribute & 0x80) | 0x0F;
                                                 break;


                                       case 'R': attribute = (attribute & 0x80) | 0x07;
                                                 break;

                                       case 'B': attribute |= 0x80;
                                                 break;

                                       case 'O': attribute &= 0x7F;
                                                 break;

                                       case 'W': DOSBEEP(900,400);
                                                 break;

                                       case 'I':
                                                 BEGIN
                                                   /* display next element in the array */
                                                  if (attribute == 0x00)
                                                      attribute = 0x07;
                                                  VIOWRTCHARSTRATT(pinsert+insert_count++,1,row,col++,attribute_ptr,0);
                                                  break;
                                                 END


                                       case 'Y':
                                                 BEGIN
                                                  /* display YES character in next location */
                                                  *--s = YES;
                                                  if (attribute == 0x00)
                                                      attribute = 0x07;
                                                  VIOWRTCHARSTRATT(s++,1,row,col++,attribute_ptr,0);
                                                  break;
                                                 END

                                       case 'N':
                                                 BEGIN
                                                  /* display NO character in next location */
                                                  *--s = NO;
                                                  if (attribute == 0x00)
                                                      attribute = 0x07;
                                                  VIOWRTCHARSTRATT(s++,1,row,col++,attribute_ptr,0);
                                                  break;
                                                 END


                                       case 'S':
                                                 BEGIN
                                                  input_row = row;
                                                  input_col = col;
                                                  break;
                                                 END

                                       case 'C':
                                                 BEGIN
                                                  /* Clear from current position to end of line */
                                                  clear_screen(row,col,row,39);
                                                  break;
                                                 END

                                       case '\0':
                                                 BEGIN
                                                  /* Message string error - string ended in the middle of control string*/
                                                  insert[0] = '7';
                                                  display(debug_msg);
                                                  break;
                                                 END

                                       default:
                                                 BEGIN
                                                  /* Message string error - no valid control char found */
                                                  insert[0] = '6';
                                                  display(debug_msg);
                                                  break;
                                                 END
                                      END /* Switch */
                                  END /* While */
                               /* Get the pointer past the '>' */
                               s++;
                               break;
                              END /* control characters */

                    /* Check for row,col */
                    case '%':
                              BEGIN
                               s++;
                               /* determine the row to put the message on */
                               if ( !isdigit(*s) )
                                  BEGIN
                                   /* Message string error */
                                   insert[0] = '2';
                                   display(debug_msg);
                                  END
                               else
                                  BEGIN
                                   row = row+((unsigned)(((*s++ - '0')*10)));
                                   if ( !isdigit(*s) )
                                     BEGIN
                                      /* Message string error */
                                      insert[0] = '2';
                                      display(debug_msg);
                                     END
                                   else
                                      BEGIN
                                       row = row+((unsigned)(*s++ - '0'));
                                       /* determine the col to put the message on */
                                       if ( !isdigit(*s) )
                                          BEGIN
                                           /* Message string error */
                                           insert[0] = '3';
                                           display(debug_msg);
                                          END
                                       else
                                          BEGIN
                                           col = ((unsigned)(*s++ - '0'));
                                           if ( !isdigit(*s) )
                                              BEGIN
                                               /* Message string error */
                                               insert[0] = '3';
                                               display(debug_msg);
                                              END
                                           else
                                              BEGIN
                                               col = ((unsigned)((col* 10) + (*s++ - '0')));
                                               if (*s++ != '%')
                                                  BEGIN
                                                   /* Message string error */
                                                   insert[0] = '4';
                                                   display(debug_msg);
                                                  END /* 2nd sq bracket */
                                              END /* 2nd digit col */
                                          END /* 1st digit col */
                                      END /* 2nd digit row */
                                  END /* 1st digit row */
                               break;
                              END
                    /* Handle anything else */


                    default:
                            BEGIN
                             /* See if attribute set to anything */
                             if (attribute == 0x00)
                                  attribute = 0x07;
                             VIOWRTCHARSTRATT(s++,1,row,col++,attribute_ptr,0);
                             break;
                            END
                   END
               END /* End of string check */
           END /* No characters in string check */
        return;

END

void number_in_msg(number,start)

unsigned    number;
unsigned    start;

BEGIN

unsigned     i;

        /* init the four spots to zero's */
        for (i = 0; i < 4;i++)
            BEGIN
             insert[start+i] = ' ';
            END
        /* Divide the space down and get it into decimal */
        if (number > 999)
           BEGIN
            insert[start] = ((char)(number/1000))+'0';
            insert[start+1] = '0';
            insert[start+2] = '0';
            insert[start+3] = '0';
            number = number%1000;
           END
        if (number > 99)
           BEGIN
            insert[start+1] = ((char)(number/100))+'0';
            insert[start+2] = '0';
            insert[start+3] = '0';
            number = number%100;
           END
        if (number > 9)
           BEGIN
            insert[start+2] = ((char)(number/10))+'0';
            insert[start+3] = '0';
            number = number%10;
           END
        insert[start+3] = ((char)(number +'0'));
        return;
END



void clear_screen(TopRow,LeftCol,BotRow,RightCol)

unsigned     TopRow;
unsigned     LeftCol;
unsigned     BotRow;
unsigned     RightCol;

BEGIN

char    attribute;
char    *attribute_ptr = &attribute;

   attribute = 0x07;
   VIOSCROLLUP(TopRow,LeftCol,BotRow,RightCol,0,attribute_ptr,0);
   return;
END



char wait_for_ESC()

BEGIN
     char  input;

    while (input != ESC)
       BEGIN
        /* position the cursor at the end of the ESC prompt */
        VIOSETCURPOS(24,39,0);

        /* Get input */
        KBDFLUSHBUFFER(0);
      /*KBDCHARIN(input_data,0,0);*/
      /*input = input_data->char_code;*/
          input = ((char)(getch()));
       END
    return(ESC);
END

