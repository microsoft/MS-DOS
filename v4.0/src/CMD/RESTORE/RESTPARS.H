/* 0 */
/*-----------------------------------------------------------------------*/
/*-									-*/
/*-	FILE:	 PARSE.H						-*/
/*-									-*/
/*-	PURPOSE: Include file for RESTORE.C and other RESTORE source	-*/
/*-		 files. Defines structures and DEFINES for the DOS PARSE-*/
/*-		 service routines					-*/
/*-									-*/
/*-----------------------------------------------------------------------*/


/**********************************************************/
/* STRUCTURE TO DEFINE ADDITIONAL COMMAND LINE DELIMITERS */
/**********************************************************/
struct p_parms								/*;AN000;4*/
	{								/*;AN000;4*/
	 WORD	parmsx_ptr;		/* POINTER TO PARMS STRUCTURE *//*;AN000;4*/
	 BYTE	p_num_extra;		/* 1 SAYS THAT A DELIMITER LIST FOLLOWS */  /*;AN000;4*/
	 BYTE	p_len_extra_delim;	/* NUMBER OF ADDITIONAL DELIMITERS */	/*;AN000;4*/
	 BYTE	p_extra_delim[2];	/* ADDITIONAL DELIMITERS */	/*;AN000;4*/
	};								/*;AN000;4*/

/***************************************************/
/* STRUCTURE TO DEFINE RESTORE SYNTAX REQUIREMENTS */
/***************************************************/
struct	p_parmsx								/*;AN000;4*/
	{									/*;AN000;4*/
	 BYTE  p_minpos;       /* THERE ARE 2 REQUIRED POSITIONAL PARMS*/	/*;AN000;4*/
	 BYTE  p_maxpos;       /* THERE ARE 2 REQUIRED POSITIONAL PARMS*/	/*;AN000;4*/
	 WORD  pos1_ptr;       /* POINTER TO SOURCE FILESPEC DEF AREA*/ 	/*;AN000;4*/
	 WORD  pos2_ptr;       /* POINTER TO TARGET DRIVE DEF AREA*/		/*;AN000;4*/
	 BYTE  num_sw;	       /* THERE ARE 8 SWITCHES (/S, /P, /M, /N, /E:, /L:, /B:, /A:)  */ /*;AN000;4*/
	 WORD  sw1_ptr;        /* POINTER TO SWITCH DEFINITION AREA*/		/*;AN000;4*/
	 WORD  sw2_ptr;        /* POINTER TO SWITCH DEFINITION AREA*/		/*;AN000;4*/
	 WORD  sw3_ptr;        /* POINTER TO SWITCH DEFINITION AREA*/		/*;AN000;4*/
	 WORD  num_keywords;   /* NUMBER OF KEYWORDS IN RESTORE SYNTAX*/	/*;AN000;4*/
	};									/*;AN000;4*/

/****************************************/
/* STRUCTURE TO DEFINE POSITIONAL PARMS */
/****************************************/
struct p_pos_blk							/*;AN000;4*/
	{								/*;AN000;4*/
	 WORD	match_flag;		/* Controls type matched */	/*;AN000;4*/
	 WORD	function_flag;		/* Function to be included  */	/*;AN000;4*/
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
	 BYTE	switch1[3];		/* Save area for switches */	/*;AN000;4*/
	 BYTE	switch2[3];		/* Save area for switches */	/*;AN000;4*/
	 BYTE	switch3[3];		/* Save area for switches */	/*;AN000;4*/
	 BYTE	switch4[3];		/* Save area for switches */	/*;AN000;4*/
	};								/*;AN000;4*/
/**/
/*---------------------------------------------------------------------------*/

/**************************/
/* RETURN BUFFER FOR TIME */
/**************************/
struct timebuff 							/*;AN000;4*/
	{								/*;AN000;4*/
	 BYTE	tb_type;       /* TYPE RETURNED*/			/*;AN000;4*/
	 BYTE	tb_item_tag;   /* SPACE FOR ITEM TAG*/			/*;AN000;4*/
	 WORD	tb_synonym_ptr; 					/*;AN000;4*/
	 BYTE	hours;							/*;AN000;4*/
	 BYTE	minutes;						/*;AN000;4*/
	 BYTE	seconds;						/*;AN000;4*/
	 BYTE	hundreds;						/*;AN000;4*/
	};								/*;AN000;4*/

/**************************/
/* RETURN BUFFER FOR DATE */
/**************************/
struct datebuff 							/*;AN000;4*/
	{								/*;AN000;4*/
	 BYTE	db_type;       /* TYPE RETURNED*/			/*;AN000;4*/
	 BYTE	db_item_tag;   /* SPACE FOR ITEM TAG*/			/*;AN000;4*/
	 WORD	db_synonym_ptr; 					/*;AN000;4*/
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
	 DWORD	p_string_ptr;		/* Pointer to string */ 	/*;AN000;4*/
	};				/*  or drive number in 1st byte /*;AN000;4*/

/****************************************/
/* RETURN BUFFER FOR SWITCH INFORMATION */
/****************************************/
struct	switchbuff							/*;AN000;4*/
	{								/*;AN000;4*/
	 BYTE	sw_type;	 /* TYPE RETURNED*/			/*;AN000;4*/
	 BYTE	sw_item_tag;	 /* Matched item tag */ 		/*;AN000;4*/
	 WORD	sw_synonym_ptr;  /* pointer to switch entered */	/*;AN000;4*/
	 DWORD	sw_string_ptr;	 /* Pointer to string */		/*;AN000;4*/
	};								/*;AN000;4*/

