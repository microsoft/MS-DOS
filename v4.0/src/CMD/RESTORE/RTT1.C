
/*----------------------------
/* SOURCE FILE NAME:  RTT1.C
/*----------------------------
/*  0 */

#include "rt.h"
#include "rt1.h"
#include "rt2.h"
#include "restpars.h"                                                 /*;AN000;4*/
#include "dos.h"                                                      /*;AN000;2*/
#include "comsub.h"             /* common subroutine def'n */
#include "doscalls.h"
#include "error.h"

extern BYTE destddir[MAXPATH+3];
extern BYTE srcddir[MAXPATH+3];
extern BYTE rtswitch;
extern BYTE control_flag;
extern BYTE control_flag2;
extern BYTE filename[12];
extern unsigned control_file_handle;				     /* !wrw */
extern BYTE append_indicator;					      /*;AN000;2*/
extern WORD original_append_func;				      /*;AN000;2*/

/*************************************************/
/*
/* SUBROUTINE NAME:	check_appendX
/*
/* FUNCTION:
/*	Check APPEND /X status.  If it is not active,
/*	do nothing. If it is active, then turn it off
/*	and set flag indicating that we must reset it later.
/*
/***************************************************/
void check_appendX()				/*;AN000;2*/
{						/*;AN000;2*/
	union REGS gregs;			/*;AN000;2 Register set */

	gregs.x.ax = INSTALL_CHECK;		/*;AN000;2 Get installed state*/
	int86(0x2f,&gregs,&gregs);		/*;AN000;2*/

		/*****************************************************/
		/*  1) See if append is active
		/*  2) If so, figure out if PCDOS or PCNET version
		/*****************************************************/
	if (gregs.h.al == 0)			/*;AN000;2 Zero if not installed*/
	  append_indicator = NOT_INSTALLED;	/*;AN000;2 */
	 else					/*;AN000;2 See which APPEND it is*/
	   {					/*;AN000;2*/
	    gregs.x.ax = GET_APPEND_VER;	/*;AN000;2*/
	    int86(0x2f,&gregs,&gregs);		/*;AN000;2*/

	    if (gregs.h.al == (BYTE)-1) 	/*;AN000;2 -1 if PCDOS version*/
	     append_indicator = DOS_APPEND;	/*;AN000;2*/
	    else				/*;AN000;2*/
	     append_indicator = NET_APPEND;	/*;AN000;2*/
	   }					/*;AN000;2*/

		/*****************************************************/
		/*  If it is the PCDOS append
		/*    1) Get the current append functions (returned in BX)
		/*    2) Reset append with /X support off
		/*****************************************************/
	if (append_indicator == DOS_APPEND)	/*;AN000;2*/
	 {					/*;AN000;2*/
	    gregs.x.ax = GET_STATE;		/*;AN000;2 Get active APPEND functions*/
	    int86(0x2f,&gregs,&gregs);		/*;AN000;2*/
	    original_append_func = gregs.x.bx;	/*;AN000;2*/

	    gregs.x.ax = SET_STATE;		/*;AN000;2*/
	    gregs.x.bx = gregs.x.bx & (!APPEND_X_BIT);	/*;AN000;2*/
	    int86(0x2f,&gregs,&gregs);		/*;AN000;2*/

	 }					/*;AN000;2*/

	return; 				/*;AN000;2*/
}						/*;AN000;2*/
