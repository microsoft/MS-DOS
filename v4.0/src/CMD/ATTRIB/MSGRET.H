/*  */
/*----------------------------------------------------------------------+
|									|
| This file contains the structures and defines that are needed to use	|
| the message retriever from a C program.				|
|									|
|									|
| Date: 	6-19-87 						|
|									|
+----------------------------------------------------------------------*/


#define utility_msg_class 0xff /*;AN000; Utility message type		     */
#define exterr_msg_class  0x01 /*;AN000;*/


/* Sublist Flag Values						       */

/* Alignment Indicator						       */
#define sf_left 	0x00	  /*;AN000; left align		       */
#define sf_right	0x80	  /*;AN000; right align 	       */

/* Field Type							       */
#define sf_char 	0x00	  /*;AN000; character		       */
#define sf_unsbin2d	0x01	  /*;AN000; unsigned binary to decimal */
#define sf_sbin 	0x02	  /*;AN000; signed binary to decimal   */
#define sf_unsbin2h	0x03	  /*;AN000; unsigned binary to hex     */
#define sf_date 	0x04	  /*;AN000; date		       */
#define sf_time12	0x05	  /*;AN000; time 12-hour	       */
#define sf_time24	0x06	  /*;AN000; time 24-hour	       */


/* Data Variable Size						       */

#define sf_ch		0x00	  /*;AN000; single character	       */
#define sf_asciiz	0x10	  /*;AN000; asciiz string	       */
#define sf_byte 	0x10	  /*;AN000; byte		       */
#define sf_word 	0x20	  /*;AN000; word		       */
#define sf_dword	0x30	  /*;AN000; double word 	       */

#define sf_mdy2 	0x20	  /*;AN000; month,day,year (2 digits)  */
#define sf_mdy4 	0x30	  /*;AN000; month,day,year (4 digits)  */

#define sf_hhmm 	0x00	  /*;AN000; hh:mm		       */
#define sf_hhmmss	0x10	  /*;AN000; hh:mm:ss		       */
#define sf_hhmmsshh	0x20	  /*;AN000; hh:mm:ss:hh 	       */


struct m_sublist		    /*;AN000;				 */
       {			    /*;AN000;				 */
       BYTE   sub_size; 	    /*;AN000;				 */
       BYTE   sub_res;		    /*;AN000;				 */
       WORD   sub_value;	    /*;AN000;				 */
       WORD   sub_value_seg;	    /*;AN000;				 */
       BYTE   sub_id;		    /*;AN000;				 */
       BYTE   sub_flags;	    /*;AN000;				 */
       BYTE   sub_max_width;	    /*;AN000;				 */
       BYTE   sub_min_width;	    /*;AN000;				 */
       BYTE   sub_pad_char;	    /*;AN000;				 */
       };			    /*;AN000;				 */
