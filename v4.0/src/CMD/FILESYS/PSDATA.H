/*  */
/*----------------------------------------------------------------------+
|                                                                       |
| This file contains the structures and defines that are needed to use  |
| the parser from a C program.                                          |
|                                                                       |
|                                                                       |
| Date:         5-21-87                                                 |
|                                                                       |
+----------------------------------------------------------------------*/


#define P_Len_PARMS             4               /* length of p_parms  */
#define P_I_Use_Default         0               /* no extra stuff specified */
#define P_I_Have_Delim          1               /* extra delimiter specified  */
#define P_I_Have_EOL            2               /* extra EOL specified */

struct p_parms
        {
        struct p_parmsx *p_parmsx_address;      /* address of p_parmsx */
        unsigned char   p_num_extra;            /* number of extra stuff */
        unsigned char   p_len_extra_delim;      /* length of extra delimiter */
        };

struct p_parmsx
        {
        unsigned char   p_minp;                 /* Minimum positional number */
        unsigned char   p_maxp;                 /* Maximum positional number  */
        unsigned int    p_1st_control;          /* Address of the 1st CONTROL block */
        };


struct p_control_blk
        {
        unsigned int    p_match_flag;           /* Controls type matched */
        unsigned int    p_function_flag;        /* Function should be taken */
        unsigned int    p_result_buf;           /* Result buffer address */
        unsigned int    p_value_list;           /* Value list address */
        unsigned char   p_nid;                  /* # of keyword/SW synonyms */
        unsigned char   p_keyorsw;              /* keyword or sw */
        };

/* Match_Flags */

#define P_Num_Val               0x8000          /* Numeric Value */
#define P_SNum_Val              0x4000          /* Signed numeric value */
#define P_Simple_S              0x2000          /* Simple string */
#define P_Date_S                0x1000          /* Date string */
#define P_Time_S                0x0800          /* Time string */
#define P_Cmpx_S                0x0400          /* Complex string */
#define P_File_Spc              0x0200          /* File Spec */
#define P_Drv_Only              0x0100          /* Drive Only */
#define P_Qu_String             0x0080          /* Quoted string */
#define P_Ig_Colon              0x0010          /* Ignore colon at end in match */
#define P_Repeat                0x0002          /* Repeat allowed */
#define P_Optional              0x0001          /* Optional */

/*----------------------------------------------------------------------+
|                                                                       |
|  Function flags                                                       |
|                                                                       |
+----------------------------------------------------------------------*/

#define P_CAP_File              0x0001          /* CAP result by file table */
#define P_CAP_Char              0x0002          /* CAP result by character table */
#define P_Rm_Colon              0x0010          /* Remove ":" at the end */





#define P_nval_None             0               /* no value list ID */
#define P_nval_Range            1               /* range list ID */
#define P_nval_Value            2               /* value list ID */
#define P_nval_String           3               /* string list ID */
#define P_Len_Range             9               /* Length of a range choice(two DD plus one DB) */
#define P_Len_Value             5               /* Length of a value choice(one DD plus one DB) */
#define P_Len_String            3               /* Length of a string choice(one DW plus one DB) */


/*----------------------------------------------------------------------+
|                                                                       |
|       problem with doing this in C                                    |
|                                                                       |
+----------------------------------------------------------------------*/
struct p_val_list
        {
        unsigned char   P_NumofList;            /* number of following choice */
        unsigned int    P_Val_XL;               /* lower word of value */
        unsigned int    P_Val_XH;               /* higher word of value */
        unsigned int    P_Val_YL;               /* lower word of another value */
        unsigned int    P_Val_YH;               /* higher word of another value */
        };


/*----------------------------------------------------------------------+
|                                                                       |
|  Result block structure                                               |
|                                                                       |
+----------------------------------------------------------------------*/

struct p_result_blk
        {
        unsigned char   P_Type;                 /* Type returned */
        unsigned char   P_Item_Tag;             /* Matched item tag */
        unsigned int    P_SYNONYM_Ptr;          /* pointer to Synonym list returned */
        unsigned char   P_Picked_Val[4];        /* value */
        };

/*----------------------------------------------------------------------+
|                                                                       |
|  type                                                                 |
|                                                                       |
+----------------------------------------------------------------------*/

#define P_EOL                   0               /* End of line */
#define P_Number                1               /* Number */
#define P_List_Idx              2               /* List Index */
#define P_String                3               /* String */
#define P_Complex               4               /* Complex */
#define P_File_Spec             5               /* File Spec */
#define P_Drive                 6               /* Drive */
#define P_Date_F                7               /* Date */
#define P_Time_F                8               /* Time */
#define P_Quoted_String         9               /* Quoted String */

#define P_No_Tag                0x0FF           /* No ITEM_TAG found */

/*----------------------------------------------------------------------+
|                                                                       |
|  following return code will be returned in the AX register.           |
|                                                                       |
+----------------------------------------------------------------------*/

#define P_No_Error              0               /* No error */
#define P_Too_Many              1               /* Too many operands */
#define P_Op_Missing            2               /* Required operand missing */
#define P_Not_In_SW             3               /* Not in switch list provided */
#define P_Not_In_Key            4               /* Not in keyword list provided */
#define P_Out_Of_Range          6               /* Out of range specified */
#define P_Not_In_Val            7               /* Not in value list provided */
#define P_Not_In_Str            8               /* Not in string list provided */
#define P_Syntax                9               /* Syntax error */
#define P_RC_EOL                0x0ffff         /* End of command line */


