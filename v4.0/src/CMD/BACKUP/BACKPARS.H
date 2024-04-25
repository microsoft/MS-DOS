/* 0 */
/*-----------------------------------------------------------------------*/
/*-									-*/
/*-	FILE:	 BACKPARS.H						-*/
/*-									-*/
/*-	PURPOSE: Defines structures and DEFINES for the DOS PARSE	-*/
/*-		 service routines.					-*/
/*-									-*/
/*-	DATE:  	 6/5/87							-*/
/*-									-*/
/*-----------------------------------------------------------------------*/


/**********************************************************/
/* STRUCTURE TO DEFINE ADDITIONAL COMMAND LINE DELIMITERS */
/**********************************************************/
struct p_parms								/*;AN000;4*/
	{								/*;AN000;4*/
	 WORD	parmsx_ptr;		/* POINTER TO PARMS STRUCTURE *//*;AN000;4*/
	 BYTE	p_num_extra;		/* 1 SAYS THAT A DELIMITER LIST FOLLOWS */ /*;AN000;4*/
	 BYTE	p_len_extra_delim;	/* NUMBER OF ADDITIONAL DELIMITERS *//*;AN000;4*/
	 BYTE	p_extra_delim[2];	/* ADDITIONAL DELIMITERS */	/*;AN000;4*/
	};								/*;AN000;4*/

/**************************************************/
/* STRUCTURE TO DEFINE BACKUP SYNTAX REQUIREMENTS */
/**************************************************/
struct	p_parmsx							    /*;AN000;4*/
	{								    /*;AN000;4*/
	 BYTE  p_minpos;       /* THERE ARE 2 REQUIRED POSITIONAL PARMS*/   /*;AN000;4*/
	 BYTE  p_maxpos;       /* THERE ARE 2 REQUIRED POSITIONAL PARMS*/   /*;AN000;4*/
	 WORD  pos1_ptr;       /* POINTER TO SOURCE FILESPEC DEF AREA*/     /*;AN000;4*/
	 WORD  pos2_ptr;       /* POINTER TO TARGET DRIVE DEF AREA*/	    /*;AN000;4*/
	 BYTE  num_sw;	       /* THERE ARE 7 SWITCHES (/S, /F, /M, /A, /L:, /T:, /D:)	*/ /*;AN000;4*/
	 WORD  sw1_ptr;        /* POINTER TO FIRST  SWITCH DEFINITION AREA*//*;AN000;4*/
	 WORD  sw2_ptr;        /* POINTER TO SECOND SWITCH DEFINITION AREA*//*;AN000;4*/
	 WORD  sw3_ptr;        /* POINTER TO THIRD  SWITCH DEFINITION AREA*//*;AN000;4*/
	 WORD  sw4_ptr;        /* POINTER TO FOURTH SWITCH DEFINITION AREA*//*;AN000;4*/
	 WORD  sw5_ptr;        /* POINTER TO FIFTH  SWITCH DEFINITION AREA*//*;AN000;4*/
	 WORD  num_keywords;   /* NUMBER OF KEYWORDS IN BACKUP SYNTAX*/     /*;AN000;4*/
	};								    /*;AN000;4*/

/****************************************/
/* STRUCTURE TO DEFINE POSITIONAL PARMS */
/****************************************/
struct p_pos_blk							/*;AN000;4*/
	{								/*;AN000;4*/
	 WORD	match_flag;		/* Controls type matched */	/*;AN000;4*/
	 WORD	function_flag;		/* Function should be taken */	/*;AN000;4*/
	 WORD	result_buf;		/* Result buffer address */	/*;AN000;4*/
	 WORD	value_list;		/* Value list address */	/*;AN000;4*/
	 BYTE	nid;			/* # of keyword/SW synonyms (0) *//*;AN000;4*/
	};								/*;AN000;4*/

/********************************/
/* STRUCTURE TO DEFINE SWITCHES */
/********************************/
struct p_sw_blk 							/*;AN000;4*/
	{								/*;AN000;4*/
	 WORD	p_match_flag;		/* Controls type matched */	/*;AN000;4*/
	 WORD	p_function_flag;	/* Function should be taken */	/*;AN000;4*/
	 WORD	p_result_buf;		/* Result buffer address */	/*;AN000;4*/
	 WORD	p_value_list;		/* Value list address */	/*;AN000;4*/
	 BYTE	p_nid;			/* # of switches */		/*;AN000;4*/
	 BYTE	switch1[3];		/* Save area for switch */	/*;AN000;4*/
	 BYTE	switch2[3];		/* Save area for switch */	/*;AN000;4*/
	 BYTE	switch3[3];		/* Save area for switch */	/*;AN000;4*/
	 BYTE	switch4[3];		/* Save area for switch */	/*;AN000;4*/
	};								/*;AN000;4*/
/**/
/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

/**************************/
/* RETURN BUFFER FOR TIME */
/**************************/
struct timebuff 							/*;AN000;4*/
	{								/*;AN000;4*/
	 BYTE	t_type;        /* TYPE RETURNED*/			/*;AN000;4*/
	 BYTE	t_item_tag;    /* SPACE FOR ITEM TAG*/			/*;AN000;4*/
	 WORD	t_synonym_ptr; /* pointer to Synonym list returned */	/*;AN000;4*/
	 BYTE	hours;							/*;AN000;4*/
	 BYTE	minutes;						/*;AN000;4*/
	 BYTE	seconds;						/*;AN000;4*/
	 BYTE	hundreds;						/*;AN000;4*/
	};								/*;AN000;4*/

/**************************/
/* RETURN BUFFER FOR DATE */
/**************************/
struct datebuff
	{								/*;AN000;4*/
	 BYTE	d_type;        /* TYPE RETURNED*/			/*;AN000;4*/
	 BYTE	d_item_tag;    /* SPACE FOR ITEM TAG*/			/*;AN000;4*/
	 WORD	d_synonym_ptr; /* pointer to Synonym list returned */	/*;AN000;4*/
	 WORD	year;							/*;AN000;4*/
	 BYTE	month;							/*;AN000;4*/
	 BYTE	day;							/*;AN000;4*/
	};								/*;AN000;4*/


/*******************************************/
/* RETURN BUFFER FOR POSITIONAL PARAMETERS */
/*******************************************/
struct p_result_blk							/*;AN000;4*/
	{								/*;AN000;4*/
	 BYTE	p_type; 		/* Type returned */		/*;AN000;4*/
	 BYTE	p_item_tag;		/* Matched item tag */		/*;AN000;4*/
	 WORD	p_synonym_ptr;		/* pointer to Synonym list returned *//*;AN000;4*/
	 DWORD	p_string_ptr;		/* Pointer to string		/*;AN000;4*/
	};								/*;AN000;4*/

/****************************************/
/* RETURN BUFFER FOR SWITCH INFORMATION */
/****************************************/
struct	switchbuff							/*;AN000;4*/
	{								/*;AN000;4*/
	 BYTE	sw_type;	 /* TYPE RETURNED*/			/*;AN000;4*/
	 BYTE	sw_item_tag;	 /* Matched item tag */ 		/*;AN000;4*/
	 WORD	sw_synonym_ptr;  /* pointer to synonym */		/*;AN000;4*/
	 DWORD	sw_string_ptr;	 /* Pointer to string */		/*;AN000;4*/
	};								/*;AN000;4*/


/********************************/
/* VALUE LIST FOR /F: PARAMETER */
/********************************/
struct	val_list_struct 					     /*;AN000;pxxxx*/
	{							     /*;AN000;pxxxx*/
	 BYTE	nval;						     /*;AN000;pxxxx*/
	 BYTE	num_ranges;					     /*;AN000;pxxxx*/
	 BYTE	num_choices;					     /*;AN000;pxxxx*/
	 BYTE	num_strings;					     /*;AN000;pxxxx*/
	 BYTE	item_tag01;					     /*;AN000;pxxxx*/
	 WORD	val01;						     /*;AN000;pxxxx*/
	 BYTE	item_tag02;					     /*;AN000;pxxxx*/
	 WORD	val02;						     /*;AN000;pxxxx*/
	 BYTE	item_tag03;					     /*;AN000;pxxxx*/
	 WORD	val03;						     /*;AN000;pxxxx*/
	 BYTE	item_tag04;					     /*;AN000;pxxxx*/
	 WORD	val04;						     /*;AN000;pxxxx*/
	 BYTE	item_tag05;					     /*;AN000;pxxxx*/
	 WORD	val05;						     /*;AN000;pxxxx*/
	 BYTE	item_tag06;					     /*;AN000;pxxxx*/
	 WORD	val06;						     /*;AN000;pxxxx*/
	 BYTE	item_tag07;					     /*;AN000;pxxxx*/
	 WORD	val07;						     /*;AN000;pxxxx*/
	 BYTE	item_tag08;					     /*;AN000;pxxxx*/
	 WORD	val08;						     /*;AN000;pxxxx*/
	 BYTE	item_tag09;					     /*;AN000;pxxxx*/
	 WORD	val09;						     /*;AN000;pxxxx*/
	 BYTE	item_tag10;					     /*;AN000;pxxxx*/
	 WORD	val10;						     /*;AN000;pxxxx*/
	 BYTE	item_tag11;					     /*;AN000;pxxxx*/
	 WORD	val11;						     /*;AN000;pxxxx*/
	 BYTE	item_tag12;					     /*;AN000;pxxxx*/
	 WORD	val12;						     /*;AN000;pxxxx*/
	 BYTE	item_tag13;					     /*;AN000;pxxxx*/
	 WORD	val13;						     /*;AN000;pxxxx*/
	 BYTE	item_tag14;					     /*;AN000;pxxxx*/
	 WORD	val14;						     /*;AN000;pxxxx*/
	 BYTE	item_tag15;					     /*;AN000;pxxxx*/
	 WORD	val15;						     /*;AN000;pxxxx*/
	 BYTE	item_tag16;					     /*;AN000;pxxxx*/
	 WORD	val16;						     /*;AN000;pxxxx*/
	 BYTE	item_tag17;					     /*;AN000;pxxxx*/
	 WORD	val17;						     /*;AN000;pxxxx*/
	 BYTE	item_tag18;					     /*;AN000;pxxxx*/
	 WORD	val18;						     /*;AN000;pxxxx*/
	 BYTE	item_tag19;					     /*;AN000;pxxxx*/
	 WORD	val19;						     /*;AN000;pxxxx*/
	 BYTE	item_tag20;					     /*;AN000;pxxxx*/
	 WORD	val20;						     /*;AN000;pxxxx*/
	 BYTE	item_tag21;					     /*;AN000;pxxxx*/
	 WORD	val21;						     /*;AN000;pxxxx*/
	 BYTE	item_tag22;					     /*;AN000;pxxxx*/
	 WORD	val22;						     /*;AN000;pxxxx*/
	 BYTE	item_tag23;					     /*;AN000;pxxxx*/
	 WORD	val23;						     /*;AN000;pxxxx*/
	 BYTE	item_tag24;					     /*;AN000;pxxxx*/
	 WORD	val24;						     /*;AN000;pxxxx*/
	 BYTE	item_tag25;					     /*;AN000;pxxxx*/
	 WORD	val25;						     /*;AN000;pxxxx*/
	 BYTE	item_tag26;					     /*;AN000;pxxxx*/
	 WORD	val26;						     /*;AN000;pxxxx*/
	 BYTE	item_tag27;					     /*;AN000;pxxxx*/
	 WORD	val27;						     /*;AN000;pxxxx*/

	};							     /*;AN000;pxxxx*/

/*********************************/
/* VALUE TABLE FOR /F: PARAMETER */
/*********************************/
struct	val_table_struct					     /*;AN000;pxxxx*/
	{							     /*;AN000;pxxxx*/
	 BYTE	val01[7];					     /*;AN000;pxxxx*/
	 BYTE	val02[7];					     /*;AN000;pxxxx*/
	 BYTE	val03[7];					     /*;AN000;pxxxx*/
	 BYTE	val04[7];					     /*;AN000;pxxxx*/
	 BYTE	val05[7];					     /*;AN000;pxxxx*/
	 BYTE	val06[7];					     /*;AN000;pxxxx*/
	 BYTE	val07[7];					     /*;AN000;pxxxx*/
	 BYTE	val08[7];					     /*;AN000;pxxxx*/
	 BYTE	val09[7];					     /*;AN000;pxxxx*/
	 BYTE	val10[7];					     /*;AN000;pxxxx*/
	 BYTE	val11[7];					     /*;AN000;pxxxx*/
	 BYTE	val12[7];					     /*;AN000;pxxxx*/
	 BYTE	val13[7];					     /*;AN000;pxxxx*/
	 BYTE	val14[7];					     /*;AN000;pxxxx*/
	 BYTE	val15[7];					     /*;AN000;pxxxx*/
	 BYTE	val16[7];					     /*;AN000;pxxxx*/
	 BYTE	val17[7];					     /*;AN000;pxxxx*/
	 BYTE	val18[7];					     /*;AN000;pxxxx*/
	 BYTE	val19[7];					     /*;AN000;pxxxx*/
	 BYTE	val20[7];					     /*;AN000;pxxxx*/
	 BYTE	val21[7];					     /*;AN000;pxxxx*/
	 BYTE	val22[7];					     /*;AN000;pxxxx*/
	 BYTE	val23[7];					     /*;AN000;pxxxx*/
	 BYTE	val24[7];					     /*;AN000;pxxxx*/
	 BYTE	val25[7];					     /*;AN000;pxxxx*/
	 BYTE	val26[7];					     /*;AN000;pxxxx*/
	 BYTE	val27[7];					     /*;AN000;pxxxx*/
	};							     /*;AN000;pxxxx*/
