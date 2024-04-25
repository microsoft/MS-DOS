
/*  */
/*----------------------------------------------------------------------+
|                                                                       |
| This file contains the structures and defines that are needed to use  |
| the parser from a C program.                                          |
|                                                                       |
|                                                                       |
| Date:         6-15-87                                                 |
|                                                                       |
+----------------------------------------------------------------------*/


#define p_len_parms             4               /* AN000 - length of p_parms  */
#define p_i_use_default         0               /* AN000 - no extra stuff specified */
#define p_i_have_delim          1               /* AN000 - extra delimiter specified  */
#define p_i_have_eol            2               /* AN000 - extra EOL specified */
#define PRI                     "/PRI"          /* AN000 */
#define EXT                     "/EXT"          /* AN000 */
#define LOG                     "/LOG"          /* AN000 */
#define QUIET                   "/Q"            /* AN000 */

struct p_parms                                  /* AN000 */
       BEGIN                                    /* AN000 */
        unsigned        p_parmsx_ptr;           /* AN000 - address of p_parmsx */
        unsigned char   p_num_extra;            /* AN000 - number of extra stuff */
        unsigned char   p_len_extra_delim;      /* AN000 - length of extra delimiter */
        char            p_extra_delim;          /* AN000 - extra delimiters */
       END;                                     /* AN000 */

struct p_parmsx                                 /* AN000 */
       BEGIN                                    /* AN000 */
        unsigned char   p_minp;                 /* AN000 - Minimum positional number */
        unsigned char   p_maxp;                 /* AN000 - Maximum positional number  */
        unsigned        p_con1_ptr;             /* AN000 - Address of the 1st CONTROL block */
        unsigned char   p_maxs;                 /* AN000 - Maximum number of switches */
        unsigned        p_swi1_ptr;             /* AN000 - Address of the 1st CONTROL block */
        unsigned        p_swi2_ptr;             /* AN000 - Address of the 2nd CONTROL block */
        unsigned char   p_maxk;                 /* AN000 - Any keyworks?? */
       END;                                     /* AN000 */


struct p_control_blk                            /* AN000 */
       BEGIN                                    /* AN000 */
        unsigned        p_match_flag;           /* AN000 - Controls type matched */
        unsigned        p_function_flag;        /* AN000 - Function should be taken */
        unsigned        p_buff1_ptr;            /* AN000 - Result buffer address */
        unsigned        p_val1_ptr;             /* AN000 - Value list address */
        unsigned char   p_nid;                  /* AN000 - # of keyword/SW synonyms */
       END;                                     /* AN000 */

struct p_switch_blk                             /* AN000 */
       BEGIN                                    /* AN000 */
        unsigned        sp_match_flag;          /* AN000 - Controls type matched */
        unsigned        sp_function_flag;       /* AN000 - Function should be taken */
        unsigned        sp_buff1_ptr;           /* AN000 - Result buffer address */
        unsigned        sp_val1_ptr;            /* AN000 - Value list address */
        unsigned char   sp_nid;                 /* AN000 - # of keyword/SW synonyms */
        unsigned char   sp_switch1[5];          /* AN000 - keyword or sw */
        unsigned char   sp_switch2[5];          /* AN000 - keyword or sw */
        unsigned char   sp_switch3[5];          /* AN000 - keyword or sw */
       END;                                     /* AN000 */

struct p_switch1_blk                             /* AN000 */
       BEGIN                                    /* AN000 */
        unsigned        sp_match_flag;          /* AN000 - Controls type matched */
        unsigned        sp_function_flag;       /* AN000 - Function should be taken */
        unsigned        sp_buff1_ptr;           /* AN000 - Result buffer address */
        unsigned        sp_val1_ptr;            /* AN000 - Value list address */
        unsigned char   sp_nid;                 /* AN000 - # of keyword/SW synonyms */
        unsigned char   sp_switch4[3];          /* AN000 - keyword or sw */
       END;                                     /* AN000 */

struct p_result_buff                            /* AN000 */
       BEGIN                                    /* AN000 */
        unsigned char   p_type;                 /* AN000 - type returned */
        unsigned char   p_item_tag;             /* AN000 - Matched item tag */
        unsigned        p_synonym;              /* AN000 - Synonym list */
        unsigned long   p_value;                /* AN000 - result value */
       END;                                     /* AN000 */

struct p_value_list                             /* AN000 */
       BEGIN                                    /* AN000 */
        unsigned char   p_values;               /* AN000 - number of values */
        unsigned char   p_range;                /* AN000 - number of ranges */
        unsigned char   p_range_one;            /* AN000 - range one */
        unsigned long   p_low_range;            /* AN000 - low value of range */
        unsigned long   p_high_range;           /* AN000 - high value of range */
       END;                                     /* AN000 */

/* Match_Flags */

#define p_num_val               0x8000          /* AN000 - Numeric Value */
#define p_snum_val              0x4000          /* AN000 - Signed numeric value */
#define p_simple_s              0x2000          /* AN000 - Simple string */
#define p_date_s                0x1000          /* AN000 - Date string */
#define p_time_s                0x0800          /* AN000 - Time string */
#define p_cmpx_s                0x0400          /* AN000 - Complex string */
#define p_file_spc              0x0200          /* AN000 - File Spec */
#define p_drv_only              0x0100          /* AN000 - Drive Only */
#define p_qu_string             0x0080          /* AN000 - Quoted string */
#define p_ig_colon              0x0010          /* AN000 - Ignore colon at end in match */
#define p_repeat                0x0002          /* AN000 - Repeat allowed */
#define p_optional              0x0001          /* AN000 - Optional */

/*----------------------------------------------------------------------+
|                                                                       |
|  Function flags                                                       |
|                                                                       |
+----------------------------------------------------------------------*/

#define p_cap_file              0x0001          /* AN000 - CAP result by file table */
#define p_cap_char              0x0002          /* AN000 - CAP result by character table */
#define p_rm_colon              0x0010          /* AN000 - Remove ":" at the end */
#define STDERR                  0x0002          /* AN010 */
#define Parse_err_class         0x0002          /* AN010 */
#define Sublist_Length          0x000b          /* AN010 */
#define Reserved                0x0000          /* AN010 */
#define Char_Field_ASCIIZ       0x0010          /* AN010 */
#define Left_Align              0x0000          /* AN010 */
#define Blank                   0x0020          /* AN010 */
#define SubCnt1                 0x0001          /* AN010 */
#define No_Input                0x0000          /* AN010 */



#define p_nval_none             0               /* AN000 - no value list ID */
#define p_nval_range            1               /* AN000 - range list ID */
#define p_nval_value            2               /* AN000 - value list ID */
#define p_nval_string           3               /* AN000 - string list ID */
#define p_len_range             9               /* AN000 - Length of a range choice(two DD plus one DB) */
#define p_len_value             5               /* AN000 - Length of a value choice(one DD plus one DB) */
#define p_len_string            3               /* AN000 - Length of a string choice(one DW plus one DB) */


/*----------------------------------------------------------------------+
|                                                                       |
|  type                                                                 |
|                                                                       |
+----------------------------------------------------------------------*/

#define p_eol                   0               /* AN000 - End of line */
#define p_number                1               /* AN000 - Number */
#define p_list_idx              2               /* AN000 - List Index */
#define p_string                3               /* AN000 - String */
#define p_complex               4               /* AN000 - Complex */
#define p_file_spec             5               /* AN000 - File Spec */
#define p_drive                 6               /* AN000 - Drive */
#define p_date_f                7               /* AN000 - Date */
#define p_time_f                8               /* AN000 - Time */
#define p_quoted_string         9               /* AN000 - Quoted String */

#define p_no_tag                0x0FF           /* AN000 - No ITEM_TAG found */

/*----------------------------------------------------------------------+
|                                                                       |
|  following return code will be returned in the AX register.           |
|                                                                       |
+----------------------------------------------------------------------*/

#define p_no_error              0               /* AN000 - No error */
#define p_too_many              1               /* AN000 - Too many operands */
#define p_op_missing            2               /* AN000 - Required operand missing */
#define p_not_in_sw             3               /* AN000 - Not in switch list provided */
#define p_not_in_key            4               /* AN000 - Not in keyword list provided */
#define p_out_of_range          6               /* AN000 - Out of range specified */
#define p_not_in_val            7               /* AN000 - Not in value list provided */
#define p_not_in_str            8               /* AN000 - Not in string list provided */
#define p_syntax                9               /* AN000 - Syntax error */
#define p_rc_eol                0x0ffff         /* AN000 - End of command line */


/*----------------------------------------------------------------------+
|                                                                       |
|  following are the structure intializations                           |
|                                                                       |
+----------------------------------------------------------------------*/

struct p_parms  p_p;                                                    /* AN000 */
struct p_parmsx  p_px;                                                  /* AN000 */
struct p_control_blk  p_con;                                            /* AN000 */
struct p_switch_blk   p_swi1;                                           /* AN000 */
struct p_switch1_blk  p_swi2;                                           /* AN000 */
struct p_result_buff  p_buff;                                           /* AN000 */
struct p_value_list   p_val;                                            /* AN000 */
struct p_result_buff  sp_buff;                                          /* AN000 */
struct p_value_list   sp_val;                                           /* AN000 */

