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

#define BYTE       unsigned char                                                     /*;AN000;*/
#define WORD       unsigned short                                                    /*;AN000;*/
#define DWORD      unsigned long                                                     /*;AN000;*/

#define p_len_parms             4               /* length of p_parms  */             /*;AN000;*/
#define p_i_use_default         0               /* no extra stuff specified */       /*;AN000;*/
#define p_i_have_delim          1               /* extra delimiter specified  */     /*;AN000;*/
#define p_i_have_eol            2               /* extra EOL specified */            /*;AN000;*/

struct p_parms                                                                       /*;AN000;*/
        {                                                                            /*;AN000;*/
        struct p_parmsx *p_parmsx_address;      /* address of p_parmsx */            /*;AN000;*/
        BYTE            p_num_extra;            /* number of extra stuff */          /*;AN000;*/
        BYTE            p_len_extra_delim;      /* length of extra delimiter */      /*;AN000;*/
        char            p_extra_delim[30];      /* extra delimiters */               /*;AN000;*/
        };                                                                           /*;AN000;*/

struct p_parmsx                                                                      /*;AN000;*/
        {                                                                            /*;AN000;*/
        BYTE            p_minp;                 /* Minimum positional number */      /*;AN000;*/
        BYTE            p_maxp;                 /* Maximum positional number  */     /*;AN000;*/
        struct p_control_blk *p_control1;       /* Address of the 1st CONTROL block */ /*;AN000;*/
        struct p_control_blk *p_control2;       /* Address of the 2nd CONTROL block */ /*;AN000;*/
        struct p_control_blk *p_control3;       /* Address of the 3nd CONTROL block */ /*;AN000;*/
        struct p_control_blk *p_control4;       /* Address of the 4th CONTROL block */ /*;AN000;*/
        struct p_control_blk *p_control5;       /* Address of the 3nd CONTROL block */ /*;AN000;*/
        struct p_control_blk *p_control6;       /* Address of the 4th CONTROL block */ /*;AN000;*/
        BYTE            p_maxs;                                                      /*;AN000;*/
        struct p_control_blk *p_switch;                                              /*;AN000;*/
        BYTE            p_maxk;                                                      /*;AN000;*/
        struct p_control_blk *p_keyword1;                                            /*;AN000;*/
        struct p_control_blk *p_keyword2;                                            /*;AN000;*/
        struct p_control_blk *p_keyword3;                                            /*;AN000;*/
        };                                                                           /*;AN000;*/

struct p_control_blk                                                                 /*;AN000;*/
        {                                                                            /*;AN000;*/
        WORD    p_match_flag;           /* Controls type matched */                  /*;AN000;*/
        WORD    p_function_flag;        /* Function should be taken */               /*;AN000;*/
        WORD    p_result_buf;           /* Result buffer address */                  /*;AN000;*/
        WORD    p_value_list;           /* Value list address */                     /*;AN000;*/
        BYTE    p_nid;                  /* # of keyword/SW synonyms */               /*;AN000;*/
        char    p_keyorsw[20];          /* keyword or sw */                          /*;AN000;*/
        };                                                                           /*;AN000;*/

/* Match_Flags */                                                                    /*;AN000;*/
#define p_num_val               0x8000          /* Numeric Value */                  /*;AN000;*/
#define p_snum_val              0x4000          /* Signed numeric value */           /*;AN000;*/
#define p_simple_s              0x2000          /* Simple string */                  /*;AN000;*/
#define p_date_s                0x1000          /* Date string */                    /*;AN000;*/
#define p_time_s                0x0800          /* Time string */                    /*;AN000;*/
#define p_cmpx_s                0x0400          /* Complex string */                 /*;AN000;*/
#define p_file_spc              0x0200          /* File Spec */                      /*;AN000;*/
#define p_drv_only              0x0100          /* Drive Only */                     /*;AN000;*/
#define p_qu_string             0x0080          /* Quoted string */                  /*;AN000;*/
#define p_ig_colon              0x0010          /* Ignore colon at end in match */   /*;AN000;*/
#define p_repeat                0x0002          /* Repeat allowed */                 /*;AN000;*/
#define p_optional              0x0001          /* Optional */                       /*;AN000;*/

/*----------------------------------------------------------------------+
|                                                                       |
|  Function flags                                                       |
|                                                                       |
+----------------------------------------------------------------------*/

#define p_cap_file              0x0001          /* CAP result by file table */       /*;AN000;*/
#define p_cap_char              0x0002          /* CAP result by character table */  /*;AN000;*/
#define p_rm_colon              0x0010          /* Remove ":" at the end */          /*;AN000;*/

#define p_nval_none             0               /* no value list ID */               /*;AN000;*/
#define p_nval_range            1               /* range list ID */                  /*;AN000;*/
#define p_nval_value            2               /* value list ID */                  /*;AN000;*/
#define p_nval_string           3               /* string list ID */                 /*;AN000;*/
#define p_len_range             9               /* Length of a range choice(two DD plus one DB) */  /*;AN000;*/
#define p_len_value             5               /* Length of a value choice(one DD plus one DB) */  /*;AN000;*/
#define p_len_string            3               /* Length of a string choice(one DW plus one DB) */ /*;AN000;*/

/*----------------------------------------------------------------------+
|                                                                       |
|  Result block structure                                               |
|                                                                       |
+----------------------------------------------------------------------*/

struct p_result_blk                                                                  /*;AN000;*/
        {                                                                            /*;AN000;*/
        BYTE  p_type;                 /* Type returned */                            /*;AN000;*/
        BYTE  p_item_tag;             /* Matched item tag */                         /*;AN000;*/
        WORD  p_synonym_ptr;          /* pointer to Synonym list returned */         /*;AN000;*/
        WORD  p_result_buff[2];       /* result value */                             /*;AN000;*/
        };                                                                           /*;AN000;*/

/*----------------------------------------------------------------------+
|                                                                       |
|  type                                                                 |
|                                                                       |
+----------------------------------------------------------------------*/

#define p_eol                   0               /* End of line */                    /*;AN000;*/
#define p_number                1               /* Number */                         /*;AN000;*/
#define p_list_idx              2               /* List Index */                     /*;AN000;*/
#define p_string                3               /* String */                         /*;AN000;*/
#define p_complex               4               /* Complex */                        /*;AN000;*/
#define p_file_spec             5               /* File Spec */                      /*;AN000;*/
#define p_drive                 6               /* Drive */                          /*;AN000;*/
#define p_date_f                7               /* Date */                           /*;AN000;*/
#define p_time_f                8               /* Time */                           /*;AN000;*/
#define p_quoted_string         9               /* Quoted String */                  /*;AN000;*/

#define p_no_tag                0x0FF           /* No ITEM_TAG found */              /*;AN000;*/

/*----------------------------------------------------------------------+
|                                                                       |
|  following return code will be returned in the AX register.           |
|                                                                       |
+----------------------------------------------------------------------*/

#define p_no_error              0               /* No error */                       /*;AN000;*/
#define p_too_many              1               /* Too many operands */              /*;AN000;*/
#define p_op_missing            2               /* Required operand missing */       /*;AN000;*/
#define p_not_in_sw             3               /* Not in switch list provided */    /*;AN000;*/
#define p_not_in_key            4               /* Not in keyword list provided */   /*;AN000;*/
#define p_out_of_range          6               /* Out of range specified */         /*;AN000;*/
#define p_not_in_val            7               /* Not in value list provided */     /*;AN000;*/
#define p_not_in_str            8               /* Not in string list provided */    /*;AN000;*/
#define p_syntax                9               /* Syntax error */                   /*;AN000;*/
#define p_rc_eol                0x0ffff         /* End of command line */            /*;AN000;*/

/*----------------------------------------------------------------------+
|                                                                       |
|  String Value List Block Structure                                    |
|                                                                       |
+----------------------------------------------------------------------*/

struct ps_valist_blk                                                                 /*;AN000;*/
        {                                                                            /*;AN000;*/
        BYTE   ps_val;                /* Value type */                               /*;AN000;*/
        BYTE   ps_nrng;               /* Number of ranges  */                        /*;AN000;*/
        BYTE   ps_nnval;              /* Number of numbers */                        /*;AN000;*/
        BYTE   ps_nstrval;            /* Number of strings */                        /*;AN000;*/
        BYTE   ps_item_tag1;             /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings1;           /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag2;             /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings2;           /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag3;             /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings3;           /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag4;             /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings4;           /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag5;             /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings5;           /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag6;             /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings6;           /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag7;             /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings7;           /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag8;             /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings8;           /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag9;             /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings9;           /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag10;            /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings10;          /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag11;            /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings11;          /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag12;            /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings12;          /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag13;            /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings13;          /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag14;            /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings14;          /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag15;            /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings15;          /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag16;            /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings16;          /* Address of strings */                       /*;AN000;*/
        BYTE   ps_item_tag17;            /* Matched item tag */                      /*;AN000;*/
        WORD   ps_strings17;          /* Address of strings */                       /*;AN000;*/
        };                                                                           /*;AN000;*/
