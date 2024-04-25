
/*                                                                          */
/****************************************************************************/
/* Define statements                                                        */
/****************************************************************************/
/*                                                                          */

#define BEGIN    {
#define END      }
#define ESC     0x1B
#define NUL     0x00
#define NOT_FOUND 0xFF
#define DELETED   0xFF
#define INVALID   0xFF
#define FALSE   (1==0)
#define TRUE    !FALSE
#define CR      0x0D

/*                                                                          */
/****************************************************************************/
/* Declare Global variables                                                */
/****************************************************************************/
/*                                                                          */




unsigned       input_row;
unsigned       input_col;
char           insert[200];
char           *pinsert = insert;


/*                                                                          */
/****************************************************************************/
/* Subroutine Definitions                                                  */
/****************************************************************************/
/*                                                                          */

void             clear_screen(unsigned,unsigned,unsigned,unsigned);
void             display(char far *);
char             wait_for_ESC(void);

