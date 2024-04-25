static char *SCCSID = "@(#)rtt2.c       8.4 86/10/19";
/*  0 */
#include <direct.h>
#include "rt.h"
#include "rt1.h"
#include "rt2.h"
#include <comsub.h>			/* common subroutine def'n */
#include <doscalls.h>
#include <wrwdefs.h>		   /* wrw! */

extern unsigned char rtswitch;
extern unsigned char control_flag;
extern unsigned char control_flag2;
extern struct internat ctry;	       /* data area for country info*/

/*****************  START OF SPECIFICATION  *********************************/
/*									    */
/*  SUBROUTINE NAME :  valid_input_time 				    */
/*									    */
/*  DESCRIPTIVE NAME :	to validate and convert the time input from the     */
/*			command line.					    */
/*									    */
/*  FUNCTION: This subroutine validate the time input from the command lin  */
/*	      against the country dependent information, and convert	    */
/*	      the deta into three integers which are hour, minute, and	    */
/*	      second.							    */
/*  NOTES:								    */
/*									    */
/*  INPUT: (PARAMETERS) 						    */
/*	    in_string - the string from command line which contains date    */
/*		     information.					    */
/*  OUTPUT:								    */
/*	    inhour - the input hour after converted			    */
/*	    inminute - the input minute after converted 		    */
/*	    insecond - the input second after converted 		    */
/*									    */
/*  EXIT-NORMAL: returns TRUE if the time is valid			    */
/*									    */
/*  EXIT-ERROR:  returns FALSE if the time is invalid			    */
/*									    */
/*  EFFECTS:								    */
/*									    */
/*  INTERNAL REFERENCES:						    */
/*	   ROUTINES:							    */
/*		    usererror						    */
/*		    unexperror						    */
/*		    putmsg						    */
/*		    set_reset_test_flag 				    */
/*									    */
/*  EXTERNAL REFERENCES:						    */
/*	   ROUTINES:							    */
/*									    */
/********************** END OF SPECIFICATIONS *******************************/
int valid_input_time(in_string, inhour, inminute, insecond)
    unsigned char *in_string;  /*the input string			*/
    unsigned int  *inhour;     /*the input hour 			*/
    unsigned int  *inminute;   /*the input minute			*/
    unsigned int  *insecond;   /*the input second			*/
{
    unsigned char chour[10];
    unsigned char cminute[10];
    unsigned char csecond[10];
    unsigned int i,j,z;    /*working pointer*/
    unsigned int no_second = FALSE;
    unsigned char string[20];

    /*declaration for get country information*/
    unsigned int byte_len;
    unsigned buflen = sizeof( struct internat );    /* length of data area  */
    unsigned int retcode;
    long country = 0L;

   /************************************************/
   /* find the string for hour			   */
   /************************************************/
   #ifdef DEBUG
   printf("\ntime to be validate %s",in_string);
   #endif
   /*save the pointer of input string*/
   strcpy(string,in_string);

   /* search the first occurance of country->timesep */
   for (i = 0; (string[i] != NULLC) && (string[i] != ctry.timesep &&
   string[i] != ':' && string[i] != '.'); ++i);

   if (string[i] == NULLC) {  /*if not found*/
       #ifdef DEBUG
       printf("\nno time seperator");
       #endif
       return(FALSE);
   }

   string[i] = NULLC;	  /*replace it with NULLC*/

   /*get the string which represent hour*/
   strcpy(chour,string);
   /*put the rest of the string into cminute*/
   strcpy(cminute,string+i+1);

   /************************************************/
   /* validate hour				   */
   /************************************************/
   if (strlen(chour) > MAXHOURLEN || strlen(chour)<1 ) {
       #ifdef DEBUG
       printf("\ninvalid hour length");
       #endif
       return(FALSE);
   }

   /* convert the string into integer form*/
   *inhour = 0;
   for (j=0; chour[j] != NULLC ; ++j) {
       if (chour[j] < '0' || chour[j] > '9') {
	  #ifdef DEBUG
	  printf("\nhour value not 0-9");
	  #endif
	  return(FALSE);
       }
       *inhour = *inhour*10 + chour[j]-'0';
   }

   if (*inhour > 23 || *inhour < 0) {
	   #ifdef DEBUG
	   printf("\ninvalid hour value");
	   #endif
	   return(FALSE);
   }

   /************************************************/
   /* find the string for minute		   */
   /************************************************/
   /*search the next occurance of country->timesep*/
   for (i = 0; (cminute[i] != NULLC) && (cminute[i] != ctry.timesep &&
   cminute[i] != ':' && cminute[i] != '.'); ++i);

   if (cminute[i] == NULLC) {  /*if not found*/
      no_second = TRUE;
   }

   /*put NULLC at the end of string which represent minute*/
   cminute[i] = NULLC;	   /*replace it with NULLC*/
   strcpy(csecond,cminute+i+1);

   /************************************************/
   /* validate minute				   */
   /************************************************/
   if (strlen(cminute) > MAXMINUTELEN || strlen(cminute)<1 ) {
      #ifdef DEBUG
      printf("\ninvalid min length");
      #endif
      return(FALSE);
   }

   /*convert the string into integer*/
   *inminute = 0;
   for (j=0; cminute[j] != NULLC ; ++j) {
       if (cminute[j] < '0' || cminute[j] > '9')  {
	  #ifdef DEBUG
	  printf("\ninvalid min value, not 0-9");
	  #endif
	  return(FALSE);
       }
       *inminute = *inminute*10 + cminute[j]-'0';
   }

   if (*inminute > 59 || *inminute < 0) {
	   #ifdef DEBUG
	   printf("\ninvalid min value");
	   #endif
	   return(FALSE);
   }

   /***************************************************/
   /* if user input second, get the string for second */
   /***************************************************/
   if (no_second == TRUE)
       return(TRUE);
   else {

       /************************************************/
       /* validate second			       */
       /************************************************/
       if (strlen(csecond) > MAXSECONDLEN || strlen(csecond) < 1 ) {
	  #ifdef DEBUG
	  printf("\ninvalid second length");
	  #endif
	  return(FALSE);
       }

       /*convert the rest of the string into integer*/
       *insecond = 0;
       for (j=0; csecond[j] != NULLC; ++j)
       {
	   if (csecond[j] < '0' || csecond[j] > '9') {
	      #ifdef DEBUG
	      printf("\ninvalid second, 0-9");
	      #endif
	      return(FALSE);
	   }
	   *insecond = *insecond*10 + csecond[j]-'0';
       }

       if (*insecond > 59 || *insecond < 0) {
	       #ifdef DEBUG
	       printf("\ninvalid second value");
	       #endif
	       return(FALSE);
       }
   } /*end of if no_second is true */
   return(TRUE);

} /*end of subroutine*/
/*****************  START OF SPECIFICATION  *********************************/
/*									    */
/*  SUBROUTINE NAME :  valid_input_date 				    */
/*									    */
/*  DESCRIPTIVE NAME :	to validate and convert the date input from the     */
/*			command line.					    */
/*									    */
/*  FUNCTION: This subroutine validate the date input from the command lin  */
/*	      against the country dependent information, and convert	    */
/*	      the deta into three integers which are year, month, and day.  */
/*  NOTES:								    */
/*									    */
/*  INPUT: (PARAMETERS) 						    */
/*	    in_string - the string from command line which contains date    */
/*		     information.					    */
/*  OUTPUT:								    */
/*	    inyear - the input year after converted			    */
/*	    inmonth - the input month after converted			    */
/*	    inday - the input day after converted			    */
/*									    */
/*  EXIT-NORMAL: returns TRUE if the date is valid			    */
/*									    */
/*  EXIT-ERROR:  returns FALSE if the date is invalid			    */
/*									    */
/*  EFFECTS:								    */
/*									    */
/*  INTERNAL REFERENCES:						    */
/*	   ROUTINES:							    */
/*		    usererror						    */
/*		    unexperror						    */
/*		    putmsg						    */
/*		    set_reset_test_flag 				    */
/*									    */
/*  EXTERNAL REFERENCES:						    */
/*	   ROUTINES:							    */
/*									    */
/********************** END OF SPECIFICATIONS *******************************/
int valid_input_date(in_string,inyear,inmonth,inday)

    unsigned char *in_string;
    unsigned int  *inyear;
    unsigned int  *inmonth;
    unsigned int  *inday;
{
    unsigned char c1[10];
    unsigned char c2[10];
    unsigned char c3[10];
    unsigned char cyear[10];
    unsigned char cmonth[10];
    unsigned char cday[10];
    unsigned int  in1;
    unsigned int  in2;
    unsigned int  in3;
    unsigned int i,j,z;    /*working pointer*/
    unsigned char string[30];
    unsigned int  remainder;

   #ifdef DEBUG
   printf("\ndate to be validate %s",in_string);
   #endif
   /************************************************/
   /* separate the input date string into 3 parts  */
   /************************************************/
   /*save the pointer to the input string*/
   strcpy(string,in_string);

   /* search the first occurance of country->datesep */
   for (i = 0; (string[i] != NULLC) && (string[i] != ctry.datesep &&
   string[i] != '/' && string[i] != '-' && string[i] != '.'); ++i);

   if (string[i] == NULLC) {  /*if not found*/
      #ifdef DEBUG
      printf("\ninvalid date sep");
      #endif
      return(FALSE);
   }

   string[i] = NULLC;	  /*replace it with NULLC*/

   /*get the string which represent year*/
   strcpy(c1,string);
   /*put the rest of the string into c2*/
   strcpy(c2,string+i+1);

   /*search the next occurance of country->datesep*/
   for (i = 0; (c2[i] != NULLC) && (c2[i] != ctry.datesep &&
   c2[i] != '/' && c2[i] != '-' && c2[i] != '.'); ++i);

   if (c2[i] == NULLC) {  /*if not found*/
      #ifdef DEBUG
      printf("\nno 2nd date sep");
      #endif
      return(FALSE);
   }

   /*put NULLC at the end of string which represent month*/
   c2[i] = NULLC;     /*replace it with NULLC*/
   strcpy(c3,c2+i+1);

   /************************************************/
   /* convert all 3 strings to integers 	   */
   /************************************************/
   in1 = 0;
   for (j=0; c1[j] != NULLC ; ++j) {
       if (c1[j] < '0' || c1[j] > '9') {
	  #ifdef DEBUG
	  printf("\ninvalid 1st in date not 0-9");
	  #endif
	  return(FALSE);
       }
       in1 = in1*10 + c1[j]-'0';
   }

   in2 = 0;
   for (j=0; c2[j] != NULLC ; ++j) {
       if (c2[j] < '0' || c2[j] > '9') {
	  #ifdef DEBUG
	  printf("\ninvalid 2nd in date not 0-9");
	  #endif
	  return(FALSE);
       }
       in2 = in2*10 + c2[j]-'0';
   }

   in3 = 0;
   for (j=0; c3[j] != NULLC ; ++j) {
       if (c3[j] < '0' || c3[j] > '9') {
	  #ifdef DEBUG
	  printf("\ninvalid 3rd in date not 0-9");
	  #endif
	  return(FALSE);
       }
       in3 = in3*10 + c3[j]-'0';
   }
   /************************************************/
   /* identify what these 3 integers are stand for */
   /************************************************/
   switch (ctry.dtformat) {
	 case USA:
		   *inmonth = in1;
		   *inday   = in2;
		   *inyear  = in3;
		   strcpy(cmonth,c1);
		   strcpy(cday,c2);
		   strcpy(cyear,c3);
		   break;
	 case EUR:
		   *inday   = in1;
		   *inmonth = in2;
		   *inyear  = in3;
		   strcpy(cday,c1);
		   strcpy(cmonth,c2);
		   strcpy(cyear,c3);
		   break;
	 case JAP:
		   *inyear  = in1;
		   *inmonth = in2;
		   *inday   = in3;
		   strcpy(cyear,c1);
		   strcpy(cmonth,c2);
		   strcpy(cday,c3);
		   break;
	 default:
		   #ifdef DEBUG
		   printf("\ninvalid country code %d",ctry.dtformat);
		   #endif
		   unexperror(UNEXPECTED);
		   break;
   }
   /************************************************/
   /* validate the value of year		   */
   /************************************************/
   if (strlen(cyear) > MAXYEARLEN || strlen(cyear)<1 ) {
	  #ifdef DEBUG
	  printf("\ninvalid year len");
	  #endif
	  return(FALSE);
   }

   if (*inyear <= 99 && *inyear >= 80)
      *inyear = *inyear + 1900;
   if (*inyear <= 79 && *inyear >= 00)
      *inyear = *inyear + 2000;

   /*validate the value of year  */
   if (*inyear > MAXYEAR || *inyear < MINYEAR) {
	  #ifdef DEBUG
	  printf("\ninvalid year value");
	  #endif
	  return(FALSE);
   }

   /************************************************/
   /* validate the value of month		   */
   /************************************************/
   if (strlen(cmonth) > MAXMONTHLEN || strlen(cmonth)<1 ) {
	  #ifdef DEBUG
	  printf("\ninvalid month length");
	  #endif
	  return(FALSE);
    }

   /*validate the value of year  */
   if (*inmonth > MAXMONTH || *inmonth <= 0) {
	  #ifdef DEBUG
	  printf("\ninvalid month value");
	  #endif
	  return(FALSE);
   }

   /************************************************/
   /* validate the value of day 		   */
   /************************************************/
   if (strlen(cday) > MAXDAYLEN || strlen(cday)<1 ) {
	  #ifdef DEBUG
	  printf("\ninvalid day len");
	  #endif
	  return(FALSE);
   }

   /*validate the value of year  */
   if (*inday > MAXDAY || *inday <= 0 )  {
	   #ifdef DEBUG
	   printf("\ninvalid day value");
	   #endif
	   return(FALSE);
    }
   if ((*inmonth == 1 || *inmonth == 3 || *inmonth == 5 ||
	*inmonth == 7 || *inmonth == 8 || *inmonth == 10 ||
	*inmonth == 12 ) && (*inday > 31 || *inday < 1)) {
	   #ifdef DEBUG
	   printf("\ninvalid day value");
	   #endif
	   return(FALSE);
   }
   else  {
       if ((*inmonth == 4 || *inmonth == 6 || *inmonth == 9 ||
	    *inmonth == 11 ) && (*inday > 30 || *inday < 1)) {
	      #ifdef DEBUG
	      printf("\ninvalid day value");
	      #endif
	      return(FALSE);
       }
       else {
	if (*inmonth == 2) {
	  /*check for leap year */
	  remainder = *inyear % 4;
	  if (remainder == 0) {
	     if (*inday > 29 || *inday < 1) {
		#ifdef DEBUG
		printf("\ninvalid day value");
		#endif
		return(FALSE);
	     }
	  }
	  else {
	     if (*inday > 28 || *inday < 1) {
		#ifdef DEBUG
		printf("\ninvalid day value");
		#endif
		return(FALSE);
	     }
	  }
	}
       }
   }

   /************************************************/
   /* if there is no error found, return TRUE	   */
   /************************************************/
   return(TRUE);

} /*end of subroutine valid_input_date*/

/**************************/
