/*  */
/*----------------------------------------------------------------------+
|									|
| This file contains the structures and defines that are needed to use	|
| the parser from a C program.						|
|									|
|									|
| Date: 	5-21-87 						|
|									|
+----------------------------------------------------------------------*/


#define p_len_parms		4		/* length of p_parms  */
#define p_i_use_default 	0		/* no extra stuff specified */
#define p_i_have_delim		1		/* extra delimiter specified  */
#define p_i_have_eol		2		/* extra EOL specified */

struct p_parms
	{
	struct p_parmsx *p_parmsx_address;	/* address of p_parmsx */
	unsigned char	p_num_extra;		/* number of extra stuff */
	unsigned char	p_len_extra_delim;	/* length of extra delimiter */
	char		p_extra_delim[30];	/* extra delimiters */
	};

struct p_parmsx
	{
	unsigned char	p_minp; 		/* Minimum positional number */
	unsigned char	p_maxp; 		/* Maximum positional number  */
	unsigned char	p_maxswitch;		/* Maximum switches	*/
	struct p_control_blk *p_control[2];	/* Address of the 1st CONTROL block */
	unsigned char	p_keyword;		/* Keyword count */
	};


struct p_control_blk
	{
	unsigned int	p_match_flag;		/* Controls type matched */
	unsigned int	p_function_flag;	/* Function should be taken */
	unsigned int	p_result_buf;		/* Result buffer address */
	unsigned int	p_value_list;		/* Value list address */
	unsigned char	p_nid;			/* # of keyword/SW synonyms */
	char		p_keyorsw[64];		/* keyword or sw */
	};

/* Match_Flags */

#define p_num_val		0x8000		/* Numeric Value */
#define p_snum_val		0x4000		/* Signed numeric value */
#define p_simple_s		0x2000		/* Simple string */
#define p_date_s		0x1000		/* Date string */
#define p_time_s		0x0800		/* Time string */
#define p_cmpx_s		0x0400		/* Complex string */
#define p_file_spc		0x0200		/* File Spec */
#define p_drv_only		0x0100		/* Drive Only */
#define p_qu_string		0x0080		/* Quoted string */
#define p_ig_colon		0x0010		/* Ignore colon at end in match */
#define p_repeat		0x0002		/* Repeat allowed */
#define p_optional		0x0001		/* Optional */
#define p_none			0x0000

/*----------------------------------------------------------------------+
|									|
|  Function flags							|
|									|
+----------------------------------------------------------------------*/

#define p_cap_file		0x0001		/* CAP result by file table */
#define p_cap_char		0x0002		/* CAP result by character table */
#define p_rm_colon		0x0010		/* Remove ":" at the end */



#define p_nval_none		0		/* no value list ID */
#define p_nval_range		1		/* range list ID */
#define p_nval_value		2		/* value list ID */
#define p_nval_string		3		/* string list ID */
#define p_len_range		9		/* Length of a range choice(two DD plus one DB) */
#define p_len_value		5		/* Length of a value choice(one DD plus one DB) */
#define p_len_string		3		/* Length of a string choice(one DW plus one DB) */

/*----------------------------------------------------------------------+
|									|
|  Value block structure						|
|									|
+----------------------------------------------------------------------*/

struct p_value_blk
	{
	unsigned char p_val_num;
	};


/*----------------------------------------------------------------------+
|									|
|  Result block structure						|
|									|
+----------------------------------------------------------------------*/

struct p_result_blk
	{
	unsigned char	P_Type; 		/* Type returned */
	unsigned char	P_Item_Tag;		/* Matched item tag */
	unsigned int	P_SYNONYM_Ptr;		/* pointer to Synonym list returned */
	unsigned long int p_result_buff;	/* result value */
	};

/*----------------------------------------------------------------------+
|									|
|  type 								|
|									|
+----------------------------------------------------------------------*/

#define p_eol			0		/* End of line */
#define p_number		1		/* Number */
#define p_list_idx		2		/* List Index */
#define p_string		3		/* String */
#define p_complex		4		/* Complex */
#define p_file_spec		5		/* File Spec */
#define p_drive 		6		/* Drive */
#define p_date_f		7		/* Date */
#define p_time_f		8		/* Time */
#define p_quoted_string 	9		/* Quoted String */

#define p_no_tag		0x0FF		/* No ITEM_TAG found */

/*----------------------------------------------------------------------+
|									|
|  following return code will be returned in the AX register.		|
|									|
+----------------------------------------------------------------------*/

#define p_no_error		0		/* No error */
#define p_too_many		1		/* Too many operands */
#define p_op_missing		2		/* Required operand missing */
#define p_not_in_sw		3		/* Not in switch list provided */
#define p_not_in_key		4		/* Not in keyword list provided */
#define p_out_of_range		6		/* Out of range specified */
#define p_not_in_val		7		/* Not in value list provided */
#define p_not_in_str		8		/* Not in string list provided */
#define p_syntax		9		/* Syntax error */
#define p_rc_eol		0x0ffff 	/* End of command line */


